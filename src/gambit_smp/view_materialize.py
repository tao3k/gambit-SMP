"""Materialize reviewed Evidence declarations; never bless changed source hashes."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import uuid

from gambit_smp.framework import ROOT, digest, relative
from gambit_smp.recipes import source_path
from gambit_smp.task_processes import run
from gambit_smp.workspace import lease, write


def git(repository,*args,**kwargs):
    return run(['git','--no-optional-locks','-C',str(repository),*args],
               check=True,capture_output=True,timeout=30,**kwargs).stdout


def review_sources(root,record_name):
    """Bind reviewed immutable source identities to authored declarations only."""
    root=Path(root).resolve();review_path=source_path(root,record_name)
    review_sha=digest(review_path);review=json.loads(review_path.read_text())
    if review.get('schema')!='ascent.source-binding-review.v2':raise ValueError('source binding review required')
    declaration=source_path(root,review['declaration']);original=declaration.read_bytes()
    if hashlib.sha256(original).hexdigest()!=review['declarationSha256']:raise ValueError('review declaration changed')
    spec=json.loads(original);references={row['id']:row for row in spec['references']};changes=[];seen=set()
    for change in review['changes']:
        name=change['reference']
        if name in seen or not change.get('reason') or not change.get('retainedScope'):raise ValueError('explicit scoped source review required')
        seen.add(name);row=references[name];locator=row['source']
        if set(locator) not in ({'path','sha256'},{'path','sha256','identity'}):raise ValueError('review requires repository or immutable sources')
        from gambit_smp.source_identity import read_source
        if 'baseline' in change or 'patch' in change:raise ValueError('source copies and replay patches are forbidden')
        before=read_source(root,change['before']);reproduced=read_source(root,change['after'])
        actual=source_path(root,locator['path'])
        if hashlib.sha256(before).hexdigest()!=locator['sha256']:raise ValueError('review baseline does not match original binding')
        citations=spec['view']['facts'].get('citation',[])
        expected=sorted(item[0] for item in citations if len(item)>1 and item[1]==name)
        if sorted(change['citationIds'])!=expected:raise ValueError('source review omitted affected citations')
        if actual.read_bytes()!=reproduced:raise ValueError('review delta does not reproduce current source')
        after=hashlib.sha256(reproduced).hexdigest()
        changes.append(dict(reference=name,path=locator['path'],oldSha256=locator['sha256'],newSha256=after,
                            before=change['before'],after=change['after'],
                            reason=change['reason'],retainedScope=change['retainedScope'],citationIds=expected))
        locator['sha256']=after
        locator['identity']=change['after']
    with lease(root,'evidence-view-publication'):
        if declaration.read_bytes()!=original or digest(review_path)!=review_sha:raise ValueError('source review inputs changed')
        for change in changes:
            if (digest(source_path(root,change['path']))!=change['newSha256'] or
                    hashlib.sha256(read_source(root,change['before'])).hexdigest()!=change['oldSha256'] or
                    hashlib.sha256(read_source(root,change['after'])).hexdigest()!=change['newSha256']):
                raise ValueError('source changed after review reproduction')
        archive=root/'.state/evidence-views/source-declarations'/hashlib.sha256(original).hexdigest()
        archive.parent.mkdir(parents=True,exist_ok=True)
        if not archive.exists():archive.write_bytes(original)
        elif archive.read_bytes()!=original:raise ValueError('declaration custody collision')
        write(declaration,spec)
        receipt=dict(schema='ascent.source-binding-review-result.v1',review=record_name,reviewSha256=review_sha,
                     declaration=review['declaration'],beforeSha256=review['declarationSha256'],afterSha256=digest(declaration),
                     changes=changes,runtimeAdmitted=False,executionAuthorized=False)
        write(root/'.state/evidence-views/source-reviews'/(review_sha+'.json'),receipt)
    return receipt


def adopt_reviewed_view(root,declaration,review_name):
    """Import a source-bound semantic update without losing concurrent authorship."""
    root=Path(root).resolve();source=source_path(root,declaration);original=source.read_bytes();spec=json.loads(original)
    review_file=source_path(root,review_name);review_sha=digest(review_file);review=json.loads(review_file.read_text())
    output=source_path(root,spec['output']);raw=output.read_bytes();output_sha=hashlib.sha256(raw).hexdigest();view=json.loads(raw)
    if (review.get('declarationUpdateOnly') is not True or review.get('runtimeAdmitted') is not False or
            review.get('executionAuthorized') is not False or review.get('inputs',{}).get(str(output))!=output_sha):
        raise ValueError('exact non-admitting semantic update required')
    for key in ('schema','id','manifest','entry','constructor','queries'):
        if view[key]!=spec['view'][key]:raise ValueError('semantic update changed component/query authority')
    frozen=lambda rows:{json.dumps(row,sort_keys=True) for row in rows}
    for relation,rows in spec['view']['facts'].items():
        if not isinstance(rows,list):
            if rows!=view['facts'].get(relation):raise ValueError('reference metadata binding changed')
            continue
        missing=frozen(rows)-frozen(view['facts'].get(relation,[]))
        if relation=='value_review':
            for item in review.get('valueReviewChanges',[]):
                if item['previous'] not in rows or item['current'] not in view['facts'][relation] or not item.get('reason'):
                    raise ValueError('unbound value review change')
                missing.discard(json.dumps(item['previous'],sort_keys=True))
        if missing:raise ValueError('semantic update silently removed or changed existing facts: '+relation)
    old_claims={row[0] for row in spec['view']['facts']['claim']};new_claims={row[0] for row in view['facts']['claim']}
    if new_claims-old_claims!=set(review.get('newClaimIds',[])) or review.get('newClaims')!=len(new_claims-old_claims):
        raise ValueError('semantic update claim inventory mismatch')
    for key,count in review['factCounts'].items():
        if len(view['facts'][key])!=count:raise ValueError('semantic update fact inventory mismatch')
    old_refs={row['id']:row for row in spec['references']};refs=[]
    if {row['id'] for row in view['references']}-set(old_refs)!=set(review['newReferences']):raise ValueError('semantic update reference inventory mismatch')
    changes={row['id']:row for row in review.get('reviewedReferenceChanges',[])}
    for row in view['references']:
        from gambit_smp.source_identity import reference_bytes
        actual_bytes=reference_bytes(root,row)
        if hashlib.sha256(actual_bytes).hexdigest()!=row['sha256']:raise ValueError('semantic update source drift: '+row['path'])
        previous=old_refs.get(row['id'])
        if previous:
            locator=previous['source']
            if locator['sha256']!=row['sha256']:
                change=changes.get(row['id'],{})
                if change.get('oldSha256')!=locator['sha256'] or change.get('newSha256')!=row['sha256'] or not change.get('reason'):
                    raise ValueError('unreviewed existing reference change')
                locator=dict(locator,sha256=row['sha256'])
            if 'repository' in locator:
                imported=(root/locator['repository']/locator['path']).resolve()
                expected=(str(imported.relative_to(root)) if imported.is_relative_to(root) else 'git-source/'+locator['sha256']+Path(locator['path']).suffix)
                if row['path']!=expected:raise ValueError('import snapshot identity changed')
            elif locator['path']!=row['path']:raise ValueError('unexpected existing reference relocation')
            if previous['pointer']!=row['pointer']:raise ValueError('existing reference pointer changed')
        else:locator=dict(path=row['path'],sha256=row['sha256'])
        if 'identity' in row:locator=dict(path=row['path'],sha256=row['sha256'],identity=row['identity'])
        refs.append(dict(id=row['id'],source=locator,pointer=row['pointer']))
    updated=dict(schema=spec['schema'],output=spec['output'],view={key:value for key,value in view.items() if key!='references'},references=refs)
    with lease(root,'evidence-view-publication'):
        if source.read_bytes()!=original or output.read_bytes()!=raw or digest(review_file)!=review_sha:raise ValueError('semantic update changed during import')
        archive=root/'.state/evidence-views/source-declarations'/hashlib.sha256(original).hexdigest();archive.parent.mkdir(parents=True,exist_ok=True)
        if not archive.exists():archive.write_bytes(original)
        elif archive.read_bytes()!=original:raise ValueError('declaration custody collision')
        write(source,updated)
        result=dict(schema='ascent.semantic-declaration-import.v1',review=review_name,reviewSha256=review_sha,
                    declaration=declaration,beforeSha256=hashlib.sha256(original).hexdigest(),afterSha256=digest(source),
                    reviewedViewSha256=output_sha,newClaims=len(new_claims-old_claims),newReferences=len(set(row['id'] for row in refs)-set(old_refs)),runtimeAdmitted=False)
        write(root/'.state/evidence-views/semantic-imports'/(review_sha+'.json'),result)
    return result


def generator_sources():
    return {str(Path('src/gambit_smp')/name):digest(Path(__file__).with_name(name))
            for name in ('source_identity.py','evidence_views.py')}


def materialize(root,declaration,*,expected_view_sha):
    """Reviewed facts are inputs; file bytes, imports and bindings are produced."""
    root=Path(root).resolve(strict=True);source=source_path(root,declaration)
    source_sha=digest(source);spec=json.loads(source.read_text())
    if set(spec)!={'schema','output','view','references'} or spec['schema']!='ascent.evidence-view-source.v1':
        raise ValueError('reviewed Evidence source declaration required')
    output=relative(root,spec['output'])
    if not output.is_relative_to(root/'evidence'):raise ValueError('Evidence output must be maintained evidence')
    previous=output.read_bytes() if output.exists() else None
    previous_sha=hashlib.sha256(previous).hexdigest() if previous is not None else None
    if previous_sha!=expected_view_sha:raise ValueError('view publication identity changed')
    view=dict(spec['view']);references=[];inputs={declaration:source_sha};imports=[];seen=set()
    for row in spec['references']:
        if set(row)!={'id','source','pointer'} or row['id'] in seen:raise ValueError('unique declared reference required')
        seen.add(row['id']);locator=row['source'];expected=locator['sha256']
        if set(locator)=={'path','sha256','identity'}:
            from gambit_smp.source_identity import read_source
            if hashlib.sha256(read_source(root,locator['identity'])).hexdigest()!=expected:raise ValueError('reviewed identity changed')
            path=locator['path']
        elif set(locator)=={'path','sha256'}:
            original=source_path(root,locator['path'])
            if digest(original)!=expected:raise ValueError('reviewed source changed: '+locator['path'])
            path=locator['path'];inputs[path]=expected
        elif set(locator)=={'repository','revision','path','sha256','patchSha256'}:
            repository=(root/locator['repository']).resolve(strict=True)
            actual=git(repository,'rev-parse','--show-toplevel').decode().strip()
            if Path(actual).resolve()!=repository:raise ValueError('exact imported repository required')
            revision=git(repository,'rev-parse','HEAD').decode().strip()
            if revision!=locator['revision']:raise ValueError('imported source revision changed')
            name=Path(locator['path'])
            if name.is_absolute() or '..' in name.parts:raise ValueError('canonical imported file required')
            original=(repository/name).resolve(strict=True)
            if not original.is_relative_to(repository):raise ValueError('import alias escapes repository')
            raw=original.read_bytes();base=git(repository,'show',revision+':'+name.as_posix())
            patch=git(repository,'diff','--binary','--no-ext-diff','--no-renames',revision,'--',name.as_posix())
            if hashlib.sha256(raw).hexdigest()!=expected or hashlib.sha256(patch).hexdigest()!=locator['patchSha256']:
                raise ValueError('imported working source or patch changed')
            if (digest(original)!=expected or git(repository,'rev-parse','HEAD').decode().strip()!=revision or
                    git(repository,'diff','--binary','--no-ext-diff','--no-renames',revision,'--',name.as_posix())!=patch):
                raise ValueError('import changed during capture')
            from gambit_smp.source_identity import retain_sources, git_source
            retained=(git_source(root,locator['repository'],revision,name.as_posix())
                      if raw==base else retain_sources(root,{'source':raw})['source'])
            imported=repository/name
            path=(str(imported.relative_to(root)) if imported.is_relative_to(root) else 'git-source/'+expected+name.suffix)
            imports.append(dict(reference=row['id'],repository=locator['repository'],revision=revision,
                                originalPath=name.as_posix(),sha256=expected,identity=retained))
        else:raise ValueError('explicit repository or Git import source required')
        reference=dict(id=row['id'],path=path,sha256=expected,pointer=row['pointer'])
        if 'identity' in locator:
            reference['identity']=locator['identity']
        elif 'repository' in locator:
            reference['identity']=retained
        references.append(reference)
    view['references']=references
    if digest(source)!=source_sha:raise ValueError('Evidence declaration changed during generation')
    stage=output.with_name('.'+output.name+'.'+uuid.uuid4().hex+'.json')
    write(stage,view)
    try:
        from gambit_smp.evidence_views import load,evaluate
        from gambit_smp.ascent_program import engine_api
        load(root,str(stage.relative_to(root)))
        with engine_api() as (engine,identity):packet=evaluate(root,str(stage.relative_to(root)),engine)
        # Recheck every bound input and the old output immediately before CAS.
        if digest(source)!=source_sha or any(digest(Path(p))!=sha for p,sha in packet['inputs'].items()):
            raise ValueError('Evidence inputs changed during generation')
        with lease(root,'evidence-view-publication'):
            from gambit_smp.source_identity import reference_bytes
            for reference in references:
                if 'identity' in reference and hashlib.sha256(reference_bytes(root,reference)).hexdigest()!=reference['sha256']:raise ValueError('immutable source changed during publication')
            current=digest(output) if output.exists() else None
            if current!=expected_view_sha:raise ValueError('concurrent Evidence publication')
            changed=stage.read_bytes()!=previous
            if changed:
                archive=root/'.state/evidence-views/archive'/previous_sha if previous_sha else None
                if archive is not None:
                    archive.parent.mkdir(parents=True,exist_ok=True)
                    if archive.exists() and archive.read_bytes()!=previous:raise ValueError('prior view custody changed')
                    if not archive.exists():
                        with archive.open('xb') as stream:
                            stream.write(previous);stream.flush();os.fsync(stream.fileno())
                stage.replace(output)
            binding=output.with_name(output.name.replace('.view.json','.view.binding.json'))
            if binding==output:binding=output.with_name(output.name+'.binding.json')
            write(binding,dict(schema='ascent.generated-view-binding.v1',declaration=declaration,
                  declarationSha256=source_sha,output=spec['output'],outputSha256=digest(output),
                  generator='src/gambit_smp/view_materialize.py',generatorSha256=digest(Path(__file__)),generatorSources=generator_sources(),
                  imports=imports,engineIdentitySha256=hashlib.sha256(json.dumps(identity,sort_keys=True,default=str).encode()).hexdigest(),
                  engineEvaluated=True,runtimeAdmitted=False))
        bound=dict(packet['inputs']);bound.pop(str(stage),None);bound[str(output)]=digest(output)
        return dict(schema='ascent.evidence-view-generation.v1',declaration=declaration,
                    declarationSha256=source_sha,output=spec['output'],previousSha256=previous_sha,
                    outputSha256=digest(output),changed=changed,imports=imports,inputs=bound,
                    queryRows={name:len(rows) for name,rows in packet['answers'].items()},
                    queryAnswersSha256=hashlib.sha256(json.dumps(packet['answers'],sort_keys=True).encode()).hexdigest(),
                    engineEvaluated=True,executionAuthorized=False,runtimeAdmitted=False)
    finally:stage.unlink(missing_ok=True)


def check_binding(root,name):
    """Full-graph collection seals the authored source and real producer receipt."""
    root=Path(root).resolve();output=source_path(root,name)
    authored=output.with_name(output.name.replace('.view.json','.view.source.json'))
    if authored==output or not authored.exists():return {}
    binding=output.with_name(output.name.replace('.view.json','.view.binding.json'))
    if not binding.is_file():raise ValueError('generated Evidence binding missing; run its producer')
    record=json.loads(binding.read_text());generator=Path(__file__)
    if (record.get('schema')!='ascent.generated-view-binding.v1' or
            record.get('declaration')!=str(authored.relative_to(root)) or
            record.get('declarationSha256')!=digest(authored) or
            record.get('output')!=name or record.get('outputSha256')!=digest(output) or
            record.get('generatorSha256')!=digest(generator) or record.get('generatorSources')!=generator_sources()):
        raise ValueError('generated Evidence binding stale; rerun the reviewed producer')
    return {str(file):digest(file) for file in (authored,binding,generator,
            generator.with_name('source_identity.py'),generator.with_name('evidence_views.py'))}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source')
    parser.add_argument('--migrate-source-storage',action='store_true',help='migrate all legacy source copies into Git/task checkpoint identities')
    parser.add_argument('--adopt-reviewed-view',help='import an exact reviewed declaration update before generation')
    parser.add_argument('--review-source',help='explicit Git/checkpoint identity and citation review; never a blanket hash refresh')
    parser.add_argument('--expected-view-sha')
    parser.add_argument('--out',required=True)
    args=parser.parse_args()
    from gambit_smp.artifact_storage import runtime_output
    target=runtime_output(ROOT,args.out);target.mkdir(parents=True,exist_ok=True)
    if args.migrate_source_storage:
        if args.source or args.review_source or args.adopt_reviewed_view or args.expected_view_sha:parser.error('migration is a separate maintenance action')
        from gambit_smp.source_identity import migrate_source_storage
        result=migrate_source_storage(ROOT)
        write(target/'receipt.json',result)
        print(json.dumps(result))
        return 0
    if not args.source or args.expected_view_sha is None:parser.error('--source and --expected-view-sha are required for generation')
    if args.review_source and args.adopt_reviewed_view:parser.error('choose a source delta or a semantic declaration update')
    semantic=adopt_reviewed_view(ROOT,args.source,args.adopt_reviewed_view) if args.adopt_reviewed_view else None
    review=None
    if args.review_source:
        review=review_sources(ROOT,args.review_source)
        if review['declaration']!=args.source:raise ValueError('review belongs to another declaration')
    result=materialize(ROOT,args.source,expected_view_sha=args.expected_view_sha)
    if review:result['sourceReview']=review
    if semantic:result['semanticImport']=semantic
    write(target/'receipt.json',result)
    print(json.dumps(dict(output=result['output'],sha256=result['outputSha256'],queryRows=result['queryRows'])))
    return 0


from gambit_smp.task_entry import managed_tool
main=managed_tool('view-materialize')(main)
if __name__=='__main__':
    from gambit_smp.task_entry import tool_main
    raise SystemExit(tool_main('view-materialize',main))
