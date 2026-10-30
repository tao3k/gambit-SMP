from pathlib import Path
import json,hashlib
r=Path.cwd();t=r/'.cache/tasks/frame-t0-foundation';f=json.loads((r/'dev/modeling/formal-bindings.json').read_text())['frameFoundation'];bundle=f['associationBundle'];model='dev/architecture/runtime/interfaces/models/sysml/frame-contract.sysml';h=f['sourceBindings'][model]
def split(s):return [x.strip() for x in s.split(';') if x.strip()]
lanes={v['laneId']:v for v in f['targetArchitecture']['lanes']};cases={v['caseId']:v for v in f['counterexamples']};baselines={v['bindingId']:v for v in f['resolvedBaselines']}
expected=[]
for v in f['laws']:
 key=v['lawId'];pairs=[('frame-law',key),('association-source-sha256',h),('association-bundle-sha256',bundle)]
 for name,value in [('field-contract',v['fieldRefs']),('parent-duty',v['parentDuties']),('migration-cut',v['migrationCuts']),('qnt-obligation',v['quintInvariant']+' / steps: '+v['quintActions']),('lean-obligation',v['leanObligation']),('open-premise',v['requiredPremises']),('retirement-gate',v['retireRoles'])]:pairs.append((name,key+':'+value))
 for ref in split(v['sourceRefs']):pairs.append(('code-source',key+':'+ref+':'+f['sourceBindings'][ref.rsplit(':',1)[0]]))
 for lane in split(v['foundationLanes']):
  d=lanes[lane];pairs.append(('target-lane',lane))
  for name,value in [('target-redesign',d['targetDesign']),('shared-contract',d['sharedContracts']),('target-migration',d['migrationStages']),('target-gap',d['openArchitecture'])]:pairs.append((name,lane+':'+value))
  for contract in split(d['sharedContracts']):
   b=baselines[contract];value=contract+':QNT='+b['quintSource']+'@'+f['sourceBindings'][b['quintSource']]+'; symbols='+b['quintSymbols']+'; Lean='+b['leanSource']+'@'+f['sourceBindings'][b['leanSource']]+'; symbols='+b['leanSymbols']+'; scope='+b['existingEvidenceClass']+' / '+b['existingComposition'];pairs.append(('existing-root-binding',value))
 for case in split(v['counterexampleIds']):
  d=cases[case];pairs.append(('counterexample-id',case))
  for name,value in [('counterexample',d['trace']),('case-condition',d['condition']),('case-status',d['status'])]:pairs.append((name,case+':'+value))
 for name,value in sorted(set(pairs)):expected.append([key,name,value])
# Bounded independent cohorts; no source/proof domain or parser limit is raised.
keys=[v['lawId'] for v in f['laws']];groups=[keys[:3],keys[3:6],keys[6:8],keys[8:]];manifest=[]
for index,selected in enumerate(groups):
 rows=[row for row in expected if row[0] in selected]
 s='''(define-evidence (query)
 (sources clue factor binding) (outputs question witness edge)
 (include clue-selection-schema)
 (relation question (claim))
 (relation witness (claim law digest bundle))
 (relation edge (claim law kind value))
 (relation expected (law kind value))
 (relation selected (law))
'''
 for key in selected:s+=' (fact (selected '+json.dumps(key)+'))\n'
 for row in rows:s+=' (fact (expected '+' '.join(json.dumps(x) for x in row)+'))\n'
 s+=''' ((witness C K H B) <-- (clue I D C _ _ _) (factor I D (lit "frame-law") K) (selected K)
   (factor I D (lit "association-source-sha256") H) (binding (lit "association-source-sha256") H)
   (factor I D (lit "association-bundle-sha256") B) (binding (lit "association-bundle-sha256") B))
 ((edge C K N V) <-- (witness C K _ _) (clue I D C _ _ _) (expected K N V) (factor I D N V))
 ((question C) <-- (witness C _ _ _)))'''
 bindings=[['association-source-sha256',h],['association-bundle-sha256',bundle]]
 req='((selector '+json.dumps(s)+') (constructor "query") (displayBytes 65536) (bindings ('+' '.join('('+json.dumps(k)+' '+json.dumps(v)+')' for k,v in bindings)+')))\n'
 name='ascent-read-'+str(index+1);(t/(name+'.request.scm')).write_text(req);manifest.append({'stem':name,'laws':selected,'expectedEdges':len(rows),'selectorBytes':len(s.encode())})
(t/'expected-ascent-rows.json').write_text(json.dumps(expected,indent=2)+'\n');(t/'read-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps({'laws':len(keys),'exactExpectedEdges':len(expected),'queries':len(manifest),'largestSelectorBytes':max(v['selectorBytes'] for v in manifest),'largestExpectedEdges':max(v['expectedEdges'] for v in manifest)}))
