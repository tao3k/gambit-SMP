"""Git publication admission; rules are compiled from the native SysML model.

This is a path/type boundary, not an assertion that arbitrary bytes are a proof.
Review must still establish source identity and documentary meaning.
"""
from fnmatch import fnmatchcase
from pathlib import Path, PurePosixPath
import hashlib
import json
import pprint
from gambit_smp.task_processes import run, check_output

from gambit_smp import research_storage_rules as _rules
POLICY = _rules.POLICY


def _items(key):
    return tuple(value for value in POLICY[key].split(';') if value)


def classify(path, size=0, mode='100644'):
    """Return a fail-closed publication role for a repository-relative path."""
    def decision(kind, allowed, reason):
        return dict(kind=kind, disposition='allow' if allowed else 'deny', reason=reason)
    name = str(path)
    parts = PurePosixPath(name).parts
    if not parts or name.startswith('/') or '..' in parts or '\\' in name or str(PurePosixPath(name)) != name:
        return decision('unclassified', False, 'noncanonical path')
    if mode == '160000':
        return decision('maintained-source', name.startswith('vendor/'), 'pinned vendor Git link')
    if mode not in ('100644', '100755'):
        return decision('unclassified', False, 'aliases and special storage require explicit review')
    if name.startswith(_items('forbiddenPrefixes')):
        return decision('state-and-workspace', False, 'cache/state/workspace is not publication')
    if name in _items('preservedFixtureFiles'):
        return decision('maintained-input', True, 'exact immutable regression fixture; new run logs are forbidden')
    if any(part in _items('forbiddenSegments') for part in parts):
        return decision('execution-output', False, 'run snapshot/container')
    if name.casefold().endswith(tuple(s.casefold() for s in _items('generatedSuffixes'))):
        return decision('execution-output', False, 'generated stream, IR or binary')
    if name.startswith('evidence/') and parts[-1] in _items('generatedNames'):
        return decision('execution-output', False, 'generated observation/projection')
    if parts[-1].casefold() in _items('metadataNames') and size > POLICY['maxMetadataBytes']:
        return decision('execution-output', False, 'metadata exceeds documentary size bound')
    if name in _items('configFiles'):
        return decision('maintained-source', True, 'declared root configuration')
    if name.startswith(_items('curatedReferencePrefixes')):
        return decision('curated-reference', True, 'reviewed pinned primary source')
    if name.startswith(_items('curatedDocumentPrefixes')) or any(
            fnmatchcase(name, pattern) for pattern in _items('explicitCuratedFiles')):
        if name.casefold().endswith('.json') and size > POLICY['maxMetadataBytes']:
            return decision('execution-output', False, 'curated JSON exceeds documentary size bound')
        return decision('curated-publication', True, 'reviewed publication boundary')
    if 'explicitInputFiles' in POLICY and name in _items('explicitInputFiles'):
        return decision('maintained-input', True, 'declared maintained input')
    if name.startswith(_items('sourcePrefixes')) and name.endswith(_items('sourceSuffixes')):
        return decision('maintained-source', True, 'declared maintained source/design view')
    if name.startswith(_items('inputPrefixes')) and name.endswith(_items('inputSuffixes')):
        return decision('maintained-input', True, 'declared static scenario/schema input')
    return decision('unclassified', False, POLICY['defaultGitDecision'])


def audit_index(root, *, staged=False, deadline=None):
    """Inspect index bytes, including force-added ignored files, in one batch."""
    root = Path(root)
    import time
    deadline = time.monotonic()+60 if deadline is None else deadline
    def remaining():
        value = deadline-time.monotonic()
        if value <= 0:
            raise TimeoutError('publication index audit exhausted its original budget')
        return value
    selected = None
    if staged:
        selected = set(check_output(
            ['git', 'diff', '--cached', '--name-only', '--diff-filter=ACMRTU', '-z'], cwd=root, timeout=remaining()).split(b'\0'))
    entries = []
    for entry in check_output(['git', 'ls-files', '--stage', '-z'], cwd=root, timeout=remaining()).split(b'\0'):
        if not entry:
            continue
        meta, name = entry.split(b'\t', 1)
        mode, oid, stage = meta.decode().split()
        if selected is None or name in selected:
            entries.append((name.decode(), mode, oid, stage))
    objects = sorted({oid for _, mode, oid, _ in entries if mode != '160000'})
    sizes = {}
    if objects:
        result = run(['git', 'cat-file', '--batch-check=%(objectname) %(objectsize)'],
                                input='\n'.join(objects)+'\n', text=True, capture_output=True, cwd=root, check=True, timeout=remaining())
        sizes = {oid: int(size) for oid, size in (line.split() for line in result.stdout.splitlines() if line)}
    violations = []
    for name, mode, oid, stage in entries:
        verdict = classify(name, sizes.get(oid, 0), mode)
        if stage != '0':
            verdict = dict(kind='unclassified', disposition='deny', reason='unmerged index entry')
        if verdict['disposition'] != 'allow':
            violations.append(dict(path=name, **verdict))
    return dict(gitCandidatesChecked=len(entries), violations=violations)


def publication_views(policy, categories, model_sha, current_ignore):
    """Pure SysML-to-source views; publication is an explicit author review."""
    generated='# Generated from dev/modeling/models/sysml/research-storage.sysml.\n# Regenerate with shared research.audit view preview.\nPOLICY_SHA256 = '+repr(model_sha)+'\nPOLICY = '+pprint.pformat(policy,sort_dicts=True,width=100)+'\n'
    diagram='# Generated from research-storage.sysml; do not edit.\ndirection: right\npolicy: Native SysML policy\nclassifier: Python path / mode / size classifier\njoin: ASCENT declared-class check\nindex: Git index gate\ncache: Task cache / state / workspace\npolicy -> classifier\nclassifier -> join\njoin -> index\n'
    for i,category in enumerate(categories):
     diagram+=f'category{i}: '+json.dumps(category['category'])+'\n'+f'policy -> category{i}\ncategory{i} -> '+('index' if category['gitAllowed'] else 'cache')+'\n'
    diagram+='maintainedInputs: '+json.dumps(policy['authorInputRoot'])+'\nrunCache: '+json.dumps(policy['studyRunRoot'])+'\nmissingEvidence: '+json.dumps(policy['missingEvidenceDecision'])+'\nmaintainedInputs -> classifier\nclassifier -> runCache: fresh execution\nrunCache -> missingEvidence: absent or changed prerequisite\nmissingEvidence -> join: no admission\n'
    ignores=['# BEGIN SYSML RESEARCH PUBLICATION POLICY',*policy['uncuratedTrees'].split(';')]
    for prefix in (policy['curatedReferencePrefixes']+';'+policy['curatedDocumentPrefixes']).split(';'):
     if prefix.startswith('evidence/research/'):ignores+=['!'+prefix,'!'+prefix+'**']
    for pattern in policy['explicitCuratedFiles'].split(';'):
     parts=Path(pattern).parts
     for i in range(3,len(parts)):ignores.append('!'+('/'.join(parts[:i])+'/'))
     ignores.append('!'+pattern)
    ignores+=['evidence/**/*.command.json','evidence/**/*.status.json','evidence/**/*-ir.json','evidence/**/input-cut/','evidence/**/input-snapshot/','evidence/**/source-snapshots/','# END SYSML RESEARCH PUBLICATION POLICY']
    ignore_block='\n'.join(dict.fromkeys(ignores))+'\n'
    gitignore=current_ignore;gitignore=gitignore.split('# Research publication policy:')[0].split('# BEGIN SYSML RESEARCH PUBLICATION POLICY')[0].rstrip()+'\n\n'+ignore_block
    return {'src/gambit_smp/research_storage_rules.py':generated,
            '.gitignore':gitignore, 'dev/modeling/diagrams/research-storage.d2':diagram}


def publication_facts(cases, categories):
    """The classifier owns path semantics; ASCENT independently checks roles."""
    facts = dict(candidate=[], classified=[], classPolicy=[
        [row['category'], 'yes' if row['gitAllowed'] else 'no'] for row in categories])
    for case in cases:
        verdict=classify(case['path'], case['size'])
        facts['candidate'].append([case['id'],case['path'],case['declared']])
        facts['classified'].append([case['id'],verdict['kind'],verdict['disposition']])
    return facts


def main():
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--staged', action='store_true', help='Check staged additions/modifications only')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    model = root/'dev/modeling/models/sysml/research-storage.sysml'
    if hashlib.sha256(model.read_bytes()).hexdigest() != _rules.POLICY_SHA256:
        raise SystemExit('SysML policy changed; regenerate and validate its views first')
    report = audit_index(root, staged=args.staged)
    print(json.dumps(report, indent=2))
    raise SystemExit(bool(report['violations']))


if __name__ == '__main__':
    main()
