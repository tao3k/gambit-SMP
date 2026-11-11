from pathlib import Path
import json,hashlib
r=Path.cwd();t=r/'.cache/tasks/gsc-read-snapshot-refinement'
for name in ['ascent-submit.scm','ascent-submit.stderr.txt']:
 p=t/name
 if p.exists():p.rename(t/name.replace('ascent-submit','ascent-submit-attempt-1'))
for name in ['component-models.ss','component-models.request.scm']:
 p=r/'dev/modeling/ascent'/name;(t/('oversized-'+name)).write_bytes(p.read_bytes())
p=r/'dev/modeling/tools/sync-views.py';s=p.read_text()
s=s.replace("' (relation artifact (binding language path digest))',","' (relation artifact (binding language path digest))',\n        ' (relation contractFactor (binding name value))',")
s=s.replace('    artifact_facts=set()','    artifact_facts=set();contract_facts=set()')
anchor="        for name,value in [('component-id',component_id)"
insert="""        if v['bindingKind']=='model-set':\n            # Shared design factors are materialized once per canonical binding;\n            # the existing Scheme relation joins them to component hypotheses.\n            contract_facts.update((v['bindingId'],name,value) for name,value in report_factors)\n            report_factors=[]\n"""
assert s.count(anchor)==1;s=s.replace(anchor,insert+anchor)
anchor="    for row in sorted(artifact_facts):program.append("
insert="    for row in sorted(contract_facts):program.append(' (fact (contractFactor '+' '.join(json.dumps(x) for x in row)+'))')\n"
assert s.count(anchor)==1;s=s.replace(anchor,insert+anchor)
anchor="    program += [' ((clue I C (lit \"support\") S) <-- (association I C _ _ S))',"
replace=anchor+"\n        ' ((factor I N V) <-- (association I _ _ M _) (contractFactor M N V))',"
assert s.count(anchor)==1;s=s.replace(anchor,replace);p.write_text(s)
p=r/'dev/modeling/models/sysml/assurance.sysml';s=p.read_text().replace('Internal association/artifact joins; output','Internal association/artifact/contractFactor joins; output');p.write_text(s)
(t/'ascent-factorization-correction.json').write_text(json.dumps({'firstSubmissionStatus':'rejected-before-inference: rule source byte bound','oversizedSelectorBytes':len((t/'oversized-component-models.ss').read_bytes()),'correction':'Store shared model-set design factors once in contractFactor(binding,name,value); derive existing component factor relation by join','raisedParserOrExecutionLimit':False,'nativeAuthorityAdded':False,'earlierFailedSubmissionRetained':True},indent=2)+'\n')
