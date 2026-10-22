from pathlib import Path
import json,hashlib
r=Path.cwd();t=r/'.cache/tasks/gsc-scheme-value-admission';f=json.loads((r/'dev/modeling/formal-bindings.json').read_text());model='dev/modeling/models/sysml/assurance.sysml'
h=hashlib.sha256((r/model).read_bytes()).hexdigest();bundle=f['componentModels']['associationBundle']
s='''(define-evidence (query)
 (sources clue factor binding) (outputs question witness obligation receipt)
 (include clue-selection-schema)
 (relation question (claim))
 (relation witness (claim component quint lean modelDigest bundle))
 (relation obligation (claim kind identity premise))
 (relation expected (kind idFactor valueFactor identity premise))
 (relation receipt (claim path digest))
'''
rows=[]
for group,kind,idfield,valuefield,idfactor,valuefactor in [('fidelityObligations','fidelity','fidelityId','reflectionDuty','fidelity-obligation','fidelity-proof-gap')]:
 for v in f['sourceChain'][group]:
  row=[kind,idfactor,valuefactor,v[idfield],v[idfield]+':'+v[valuefield]];rows.append(row)
  s+=' (fact (expected '+' '.join(json.dumps(x) for x in row)+'))\n'
for v in f['sourceChain']['fidelityObligations']:
 if v.get('runtimeContractRefs'):
  row=['runtime','fidelity-obligation','fidelity-runtime-contract',v['fidelityId'],v['fidelityId']+':'+v['runtimeContractRefs']];rows.append(row)
  s+=' (fact (expected '+' '.join(json.dumps(x) for x in row)+'))\n'
s+=''' ((witness C K Q L H B) <-- (clue I D C _ _ _)
   (factor I D (lit "component-id") K) (binding (lit "component-id") K)
   (factor I D (lit "association-source-sha256") H) (binding (lit "association-source-sha256") H)
   (factor I D (lit "association-bundle-sha256") B) (binding (lit "association-bundle-sha256") B)
   (factor I D (lit "quint-model") Q) (factor I D (lit "lean-model") L))
 ((obligation C K X P) <-- (witness C _ _ _ _ _) (clue I D C _ _ _)
   (expected K N V X P) (factor I D N X) (factor I D V P))
 ((receipt C P H) <-- (witness C _ _ _ _ _) (clue I D C _ _ _)
   (factor I D (lit "formal-receipt") P) (factor I D (lit "formal-receipt-sha256") H))
 ((question C) <-- (witness C _ _ _ _ _)))'''
bindings=[['component-id','build-planner'],['association-source-sha256',h],['association-bundle-sha256',bundle]]
request='((selector '+json.dumps(s)+') (constructor "query") (displayBytes 65536) (bindings ('+' '.join('('+json.dumps(k)+' '+json.dumps(v)+')' for k,v in bindings)+')))\n'
(t/'ascent-read.request.scm').write_text(request);(t/'expected-ascent-rows.json').write_text(json.dumps(rows,indent=2)+'\n')
print(json.dumps({'bundle':bundle,'expectedRows':len(rows),'selectorBytes':len(s.encode())}))
