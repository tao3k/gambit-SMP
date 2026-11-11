from pathlib import Path
import hashlib,json
r=Path.cwd();t=r/'.cache/tasks/module-frame-contract';f=json.loads((r/'dev/modeling/formal-bindings.json').read_text())['nativeDescriptors'];model=f['reasoning'][0]['modelSource'];bundle=f['associationBundle'];h=f['sourceBindings'][model]
proof={v['dutyId']:v for v in f['proofDuties']};fields={v['fieldId']:v for v in f['fields']}
def split(s):return [x.strip() for x in s.split(';') if x.strip()]
expected=[]
for v in f['consumers']:
 pairs=[('route-id',v['routeId']),('actual-consumer',v['consumer']),('contract-fields',v['fieldRefs']),('migration-cuts',v['migrationRefs']),('association-source-sha256',h),('association-bundle-sha256',bundle)]
 for ref in split(v['sourceRefs']):pairs += [('code-source',ref),('code-source-sha256',ref+':'+f['sourceBindings'][ref.rsplit(':',1)[0]])]
 for key in split(v['fieldRefs']):
  pairs.append(('contract-field',key))
  for ref in split(fields[key]['sourceRefs']):pairs += [('field-source',key+':'+ref),('field-source-sha256',key+':'+ref+':'+f['sourceBindings'][ref.rsplit(':',1)[0]])]
 for key in split(v['proofRefs']):
  d=proof[key];pairs += [('proof-obligation',key),('proof-owner',key+':'+d['ownerPath']),('proof-law',key+':'+d['leanLaw']+' / QNT: '+d['quintSafety']),('proof-status',key+':'+d['status']),('shared-contracts',key+':'+d['sharedContracts'])]
 for name,value in sorted(set(pairs)):expected.append([v['routeId'],name,value])
s='''(define-evidence (query)
 (sources clue factor binding) (outputs question witness edge)
 (include clue-selection-schema)
 (relation question (claim))
 (relation witness (claim route digest bundle))
 (relation edge (claim route kind value))
 (relation expected (route kind value))
'''
for row in expected:s+=' (fact (expected '+' '.join(json.dumps(x) for x in row)+'))\n'
s+=''' ((witness C R H B) <-- (clue I D C _ _ _)
   (factor I D (lit "route-id") R)
   (factor I D (lit "association-source-sha256") H) (binding (lit "association-source-sha256") H)
   (factor I D (lit "association-bundle-sha256") B) (binding (lit "association-bundle-sha256") B))
 ((edge C R K V) <-- (witness C R _ _) (clue I D C _ _ _)
   (expected R K V) (factor I D K V))
 ((question C) <-- (witness C _ _ _)))'''
# Keep each read below the existing top-level form budget; one route per query
# also yields independently bounded presentation and exact route counts.
manifest=[]
for v in f['consumers']:
 route=v['routeId'];rows=[row for row in expected if row[0]==route]
 per='''(define-evidence (query)
 (sources clue factor binding) (outputs question witness edge)
 (include clue-selection-schema)
 (relation question (claim))
 (relation witness (claim route digest bundle))
 (relation edge (claim route kind value))
 (relation expected (route kind value))
'''
 for row in rows:per+=' (fact (expected '+' '.join(json.dumps(x) for x in row)+'))\n'
 per+=''' ((witness C R H B) <-- (clue I D C _ _ _)
   (factor I D (lit "route-id") R) (binding (lit "route-id") R)
   (factor I D (lit "association-source-sha256") H) (binding (lit "association-source-sha256") H)
   (factor I D (lit "association-bundle-sha256") B) (binding (lit "association-bundle-sha256") B))
 ((edge C R K V) <-- (witness C R _ _) (clue I D C _ _ _)
   (expected R K V) (factor I D K V))
 ((question C) <-- (witness C _ _ _)))'''
 bindings=[['route-id',route],['association-source-sha256',h],['association-bundle-sha256',bundle]]
 request='((selector '+json.dumps(per)+') (constructor "query") (displayBytes 65536) (bindings ('+' '.join('('+json.dumps(k)+' '+json.dumps(v)+')' for k,v in bindings)+')))\n'
 filename='native-read-'+route+'.request.scm';(t/filename).write_text(request);manifest.append({'route':route,'request':filename,'expectedRows':len(rows),'selectorBytes':len(per.encode())})
(t/'expected-native-rows.json').write_text(json.dumps(expected,indent=2)+'\n');(t/'native-read-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps({'routes':len(manifest),'exactExpectedEdges':len(expected),'largestRead':max(x['selectorBytes'] for x in manifest),'largestRows':max(x['expectedRows'] for x in manifest)}))
