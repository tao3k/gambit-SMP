from pathlib import Path
import json,shutil
r=Path.cwd();t=r/'.cache/tasks/script-view-lifecycle-darwin'
for name in ['ascent-read.scm','ascent-submit.scm','ascent-checks.json']:
 shutil.copy2(t/name,t/('pre-refactor-'+name))
roles=[
('C-MODULE','Module data and invariant runtime ABI','vendor/gambit/gsc/_t-c-1.scm:1189-1205; vendor/gambit/include/gambit.h.in:1244-1265; vendor/gambit/include/gambit.h.in:9328-9355','Symbol/global identity, supplied bindings and semantic module graph','ModuleSpec plus one explicit native layout encoder and invariant ABI declarations','Per-module count definitions controlling general header layout and repeated macro-generated tables','All emitters, module setup, bind-late modes and runtime consumers use the same accepted descriptor ABI; no shadow macro producer remains','Less repeated preprocessing; descriptor loads, relocations and changed inline policy remain charged','DX-LOWERING',''),
('C-FRAME','Frame, root and return-point descriptors','vendor/gambit/gsc/_t-c-1.scm:1938-1970; vendor/gambit/include/gambit.h.in:9294-9324','Liveness, frame slots, continuation kind and semantic return points','FrameSpec and PointId encoded once under explicit layout and root-location laws','DEF_LBL_RET / IFD / OFD string expansion as the cross-component representation contract','GC scanners, continuation capture/restore, stack walkers and all backends agree on frame/root maps and return identity; tail-call and mixed-edge obligations accepted','Less repeated descriptor expression expansion; possible decoding, table and source-map costs','DX-LOWERING','C-MODULE'),
('C-LITERAL','Object and literal data lowering','vendor/gambit/gsc/_t-c-1.scm:1634-1759','Literal value, interning/identity and constant graph decisions','Typed object-data plan, relocations and target representation encoder','Repeated textual CNS/SUB object-construction expansion where replaced completely','Every subtype, cyclic/shared identity, alignment, endian/word-size and module initialization consumer covered; generated data accepted by actual GC/object ABI','Fewer tokens and duplicate data preparation; relocation and initialization overhead may erase benefit','DX-LOWERING','C-MODULE'),
('C-EMISSION','Request-owned emitter and publication lifecycle','vendor/gambit/gsc/_t-c-1.scm:1286-1308; vendor/gambit/gsc/_t-c-1.scm:1393-1397; vendor/gambit/gsc/_utils.scm:426-437; vendor/gambit/gsc/_utils.scm:506-508','Diagnostics, source identity, observable writes and continuation/exception semantics','Explicit EmissionContext with acquisition-owned port, source map and output-group completion','Ambient targ-port and related mutable emission state as implicit request ownership; normal-close-only delivery assumption','All dynamic writers, recursive/reentrant emissions, exceptional exits and continuation reentry governed; unqualified extension paths refused rather than silently shared','Independent job contexts permit safe scheduling; guards, roots, cleanup and output staging are added work','SV-ISSUE; SV-RESUME; SV-CLEANUP',''),
('C-LINK','Link observation and consumer protocol','vendor/gambit/gsc/_t-c-1.scm:880-897; vendor/gambit/gsc/_t-c-1.scm:1086-1125; vendor/gambit/gsc/_t-c-1.scm:1310-1391','Supplied/demanded modules, resource conflicts, metadata and script-line semantics','One complete typed LinkObservation consumed by the semantic linker; governed serialization only where needed','Embedded Scheme record as compulsory transport and repeated reader reconstruction at migrated consumers','Actual write/read roundtrip, aliases/FFI, ordered result/exception/effect traces and every consumer migrated; old artifact compatibility is an explicit acceptance question','Less redundant metadata reconstruction; encoding, validation and optional sidecar I/O charged; no mandatory double format','SV-ROUNDTRIP; SV-REFINE; DX-REUSE','C-EMISSION; C-MODULE')]
keys=['roleId','diagramLabel','sourceRefs','schemeOwner','nativeContract','retiringRole','retirementCondition','gainAndCost','obligationRefs','dependsOn']
p=r/'dev/architecture/toolchain/models/sysml/macos-development.sysml';s=p.read_text();assert 'part def CRefactorRole' not in s
addition='''
    /* Required architecture replacement roles, not compiler flag profiles. */
    part def CRefactorRole {
'''+''.join('        attribute '+k+' : String;\n' for k in keys)+'''    }
    part def CRefactorQualification {
        attribute retired : Boolean;
        attribute producersMigrated : Boolean;
        attribute consumersMigrated : Boolean;
        attribute runtimeSemanticsAccepted : Boolean;
        attribute failureAndControlAccepted : Boolean;
        attribute singleRepresentationOwner : Boolean;
    }
    requirement def CRefactorRetirementLaw {
        subject witness : CRefactorQualification;
        require constraint { not witness.retired or
            (witness.producersMigrated and witness.consumersMigrated and
             witness.runtimeSemanticsAccepted and witness.failureAndControlAccepted and
             witness.singleRepresentationOwner) }
    }
'''
for i,row in enumerate(roles):
 addition+='    part replacement'+str(i)+' : CRefactorRole {\n'+''.join('        attribute :>> '+k+' = '+json.dumps(v)+';\n' for k,v in zip(keys,row))+'    }\n'
p.write_text(s.rsplit('}',1)[0]+addition+'}\n')
p=r/'dev/modeling/tools/sync-views.py';s=p.read_text();needle="    view_transitions=[(x,attrs(x)) for x in elements if typed(x,'GambitStableView::ViewTransition')]"
s=s.replace(needle,needle+"\n    c_refactor_roles=[(x,attrs(x)) for x in elements if typed(x,'GambitDarwinDevelopment::CRefactorRole')]\n    role_sources={}\n    for _,v in c_refactor_roles:\n        for ref in split(v['sourceRefs']):\n            path,ranges=ref.rsplit(':',1)\n            if not (ROOT/path).is_file() or not re.fullmatch(r'[0-9]+-[0-9]+',ranges):raise ValueError('Invalid C role source '+ref)\n            if int(ranges.split('-')[1])>len((ROOT/path).read_text().splitlines()):raise ValueError('Invalid C role range '+ref)\n            role_sources[path]=sha(ROOT/path)")
needle="        outputs[f]='#+TITLE: '+title"
insert="""        if prefix=='DX-':
            body+='\\n** SysML-owned C responsibility and retirement matrix\\n| Role | Current source | Scheme semantic owner | Native replacement | Old responsibility to retire | Retirement condition | Gain / added cost | Duties | Dependencies |\\n|---+---+---+---+---+---+---+---+---|\\n'
            role_ids={v['roleId'] for _,v in c_refactor_roles}
            for _,v in c_refactor_roles:
                for dep in split(v['dependsOn']):
                    if dep not in role_ids:raise ValueError('Unknown C role dependency '+dep)
                for duty in split(v['obligationRefs']):
                    if duty not in {row['fidelityId'] for _,row in chain_groups['fidelityObligations']}:raise ValueError('Unknown C role duty '+duty)
                refs='; '.join(file_link(f,ref.rsplit(':',1)[0],ref) for ref in split(v['sourceRefs']))
                body+='| '+' | '.join([v['roleId'],refs]+[v[k] for k in ['schemeOwner','nativeContract','retiringRole','retirementCondition','gainAndCost','obligationRefs','dependsOn']])+' |\\n'
"""
assert needle in s;s=s.replace(needle,insert+needle)
needle="        outputs['dev/architecture/toolchain/diagrams/'+stem+'.d2']"
insert="""        if prefix=='DX-':
            lines+=['roles: {','  label: "Required C architecture replacement roles / native qualification OPEN"','  direction: right','  Scheme: "Scheme semantic decisions"']
            for _,v in c_refactor_roles:
                ident=v['roleId'].replace('-','_')
                lines.append('  '+ident+': '+json.dumps(v['roleId']+'\\n'+textwrap.fill(v['diagramLabel'],26)))
                lines.append('  Scheme -> '+ident+': "explicit contract"')
                for dep in split(v['dependsOn']):lines.append('  '+dep.replace('-','_')+' -> '+ident+': "requires"')
            lines+=['  Accepted: "Producer + consumer + failure/control parity\\\\nNo native role retired yet"']
            for _,v in c_refactor_roles:lines.append('  '+v['roleId'].replace('-','_')+' -> Accepted')
            lines+=['}','roles -> DX_ADMISSION: "whole-request gain and runtime acceptance"']
"""
assert needle in s;s=s.replace(needle,insert+needle)
needle="    association_bundle=hashlib.sha256"
s=s.replace(needle,"    association_inputs.update(role_sources)\n"+needle)
needle="    result['stableViewTransitions']=[v for _,v in view_transitions]"
s=s.replace(needle,needle+"\n    result['cRefactorRoles']=[dict(v,sourceHashes={ref.rsplit(':',1)[0]:role_sources[ref.rsplit(':',1)[0]] for ref in split(v['sourceRefs'])}) for _,v in c_refactor_roles]")
p.write_text(s)
p=r/'dev/architecture/toolchain/macos-development-design.org';s=p.read_text();needle='Modern C means generated typed contracts'
insert='''** RESEARCH Replace source responsibilities, not configuration profiles
:PROPERTIES:
:CUSTOM_ID: macos-c-responsibility-retirement
:END:

The canonical SysML now names five required replacement roles; the generated
[[file:macos-development-map.org][responsibility/retirement matrix]] binds every role to current source ranges,
Scheme ownership, native contracts, dependencies and acceptance conditions.
None is a toolchain flag profile. They extend the existing
[[file:../../../vendor/gambit/gsc/_back.scm][target begin/end/dump/link boundary]] (lines 199-213), while requiring explicit
producer/consumer changes inside that boundary.

The concrete module problem is at _t-c-1.scm:1189-1205: GSC writes SYMCOUNT,
GLOCOUNT, LBLCOUNT and other per-module definitions before including gambit.h.
The header uses GLOCOUNT for table construction at gambit.h.in:9328-9355 and
LBLCOUNT for host/layout policy at 1244-1265. A different compiler flag cannot
separate these responsibilities. C-MODULE must move module-specific data into
an explicit plan, with one native representation owner and a stable invariant
runtime interface. A descriptor must not become an extra copy of the old macros.

Likewise _t-c-1.scm:1938-1970 writes frame kind, size, link and GC map as
DEF_LBL_RET plus IFD/OFD expressions; gambit.h.in:9294-9324 decodes them.
C-FRAME keeps liveness and continuation meaning in Scheme, but makes the native
encoding, runtime decoding and their agreement an explicit contract. Changing
the emitter alone cannot retire the old ABI. GC, continuation capture/restore
and stack consumers must migrate together; tail-call behavior remains a gate.

C-LITERAL isolates semantic constant graphs from target data representation.
C-EMISSION gives every request an owned emitter state instead of relying on
ambient targ-port/source-position globals and the normal close path.
C-LINK separates semantic link observations from compulsory embedded text
transport. The observed reader only reads the header record; no whole-C-file
scan is presumed. All three require actual identity, cleanup, control and
consumer refinement, beyond the bounded stable-view ledger.

C-MODULE precedes native layout acceptance for C-FRAME and C-LITERAL;
C-EMISSION and C-MODULE precede complete C-LINK publication. A dependency arrow
means an acceptance dependency, not a claim that current code is broken or
that every port must become C-owned. Scheme still chooses semantic values,
conditions, diagnostics and observable effects. A future LLVM/MLIR encoder
must consume these same completed contracts; it must not rediscover semantics
from C macro text. Zig, if later justified, replaces an accepted native role
rather than requiring Scheme to maintain duplicate semantic implementations.

The retirement law requires producer coverage, consumer coverage, runtime
semantics, failure/control parity and one representation owner. Its SysML
constraint is an unsatisfied requirement; it is not an executed ABI proof.
No old source responsibility has retired in this design-only study.

'''
assert needle in s;s=s.replace(needle,insert+needle);p.write_text(s)
p=t/'check-ascent-wire.py';s=p.read_text().replace("'(\"submissions\" 2)'","'(\"submissions\" 3)'").replace("'(\"retainedClues\" 14)'","'(\"retainedClues\" 21)'").replace("'successfulTaskSubmissions':2","'successfulTaskSubmissions':3").replace("'taskRetainedHypotheses':14","'taskRetainedHypotheses':21");p.write_text(s)
p=t/'seal.py';s=p.read_text().replace("assert len(f['stableViewTransitions'])==9","assert len(f['stableViewTransitions'])==9\nassert len(f['cRefactorRoles'])==5\nfor role in f['cRefactorRoles']:\n for path,h in role['sourceHashes'].items():assert sha(r/path)==h")
s=s.replace("'stableViewTransitions':f['stableViewTransitions']","'stableViewTransitions':f['stableViewTransitions'],'cRefactorRoles':f['cRefactorRoles'],'configurationSelectionIsRefactoring':False")
p.write_text(s)
print(json.dumps({'roles':len(roles),'canonicalSource':'macos-development.sysml','nativeChanges':False}))
