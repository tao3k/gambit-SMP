from pathlib import Path
import json,hashlib
r=Path.cwd();t=r/'.cache/tasks/build-cut-snapshot-refinement';f=json.loads((r/'dev/modeling/formal-bindings.json').read_text());model='dev/modeling/models/sysml/assurance.sysml'
h=hashlib.sha256((r/model).read_bytes()).hexdigest();bundle=f['componentModels']['associationBundle']
s='''(define-evidence (query)
 (sources clue factor binding) (outputs question witness contract receipt)
 (include clue-selection-schema)
 (relation question (claim))
 (relation witness (claim component quint lean modelDigest bundle))
 (relation contract (claim contractId status premise))
 (relation required (contractId status premise))
 (relation receipt (claim path digest))
'''
for c in f['sourceChain']['correctness']:
 s+=' (fact (required '+ ' '.join(json.dumps(x) for x in [c['contractId'],c['contractId']+':'+c['status'],c['contractId']+':'+c['openPremise']])+'))\n'
s+=''' ((witness C K Q L H B) <-- (clue I D C _ _ _)
   (factor I D (lit "component-id") K) (binding (lit "component-id") K)
   (factor I D (lit "association-source-sha256") H) (binding (lit "association-source-sha256") H)
   (factor I D (lit "association-bundle-sha256") B) (binding (lit "association-bundle-sha256") B)
   (factor I D (lit "quint-model") Q) (factor I D (lit "lean-model") L))
 ((contract C K S P) <-- (witness C _ _ _ _ _) (clue I D C _ _ _)
   (factor I D (lit "correctness-contract") K)
   (factor I D (lit "correctness-status") S)
   (factor I D (lit "correctness-open-premise") P) (required K S P))
 ((receipt C P H) <-- (witness C _ _ _ _ _) (clue I D C _ _ _)
   (factor I D (lit "formal-receipt") P) (factor I D (lit "formal-receipt-sha256") H))
 ((question C) <-- (witness C _ _ _ _ _)))'''
bindings=[['component-id','build-planner'],['association-source-sha256',h],['association-bundle-sha256',bundle]]
request='((selector '+json.dumps(s)+') (constructor "query") (bindings ('+' '.join('('+json.dumps(k)+' '+json.dumps(v)+')' for k,v in bindings)+')))\n'
(t/'ascent-read.request.scm').write_text(request)
print(json.dumps({'bundle':bundle,'expectedContracts':6}))
