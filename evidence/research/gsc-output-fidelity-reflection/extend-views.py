from pathlib import Path
p=Path('dev/architecture/toolchain/models/sysml/architecture.sysml');s=p.read_text();s=s.replace('    part def GscFidelityObligation {','    part def GscFidelityObligation {\n        attribute diagramLabel : String;\n        attribute dependsOn : String;')
labels={'L-CHAIN':('Real _host generation / library composition',''),'L-WRITE':('Gambit datum writer and port codec','L-CHAIN'),'L-READ':('Target / extension resolution and parser','L-WRITE'),'L-HEADER':('Shallow acceptance is insufficient','L-READ'),'L-FIELDS':('Full typed record / framed domain codec','L-HEADER'),'L-ORDER':('Ordered siblings / base / flags / metadata','L-FIELDS'),'L-ARTIFACT':('Stored bytes: layout only; origin unknown','L-CHAIN'),'L-CLEAN':('Independent qualified clean-origin relation','L-CHAIN'),'L-FAIL':('Eight outcomes; failure custody retained','L-READ'),'L-REFLECT':('Encoding facts + conditional safety reflection','L-ARTIFACT'),'L-ISSUE':('Success / complete / current / settled issuer','L-ORDER; L-CLEAN; L-FAIL; L-REFLECT'),'L-WORK':('Cut only proven consumer; charge other work','L-ISSUE')}
import json
for ident,(label,deps) in labels.items():
 a='        attribute :>> fidelityId = '+json.dumps(ident)+';'
 s=s.replace(a,a+'\n        attribute :>> diagramLabel = '+json.dumps(label)+';\n        attribute :>> dependsOn = '+json.dumps(deps)+';')
p.write_text(s)
p=Path('dev/modeling/tools/sync-views.py');s=p.read_text()
s=s.replace("'outputObservations':'GambitToolchain::GscOutputObservation',", "'outputObservations':'GambitToolchain::GscOutputObservation',\n        'fidelityObligations':'GambitToolchain::GscFidelityObligation',")
s=s.replace("'capabilityGates','outputObservations']", "'capabilityGates','outputObservations','fidelityObligations']")
s=s.replace("('outputObservations','observationId')]", "('outputObservations','observationId'),('fidelityObligations','fidelityId')]")
anchor="    correctness_order=closed_dag(chain_groups['correctness'],'contractId')"
s=s.replace(anchor,"    closed_dag(chain_groups['fidelityObligations'],'fidelityId')\n    for _,v in chain_groups['fidelityObligations']:\n        for method,kind in [('lean','theorem'),('quint',r'(?:def|val)')]:\n            body=(ROOT/('models/build/IncrementalBuild.lean' if method=='lean' else 'models/build/incremental_build.qnt')).read_text()\n            for symbol in split(v[method+'Support']):\n                if not re.search(r'\\b'+kind+r'\\s+'+re.escape(symbol)+r'\\b',body):raise ValueError('Unbound fidelity support '+symbol)\n"+anchor)
anchor="    f='dev/modeling/component-model-map.org'"
extra="""    f='dev/architecture/toolchain/output-fidelity-map.org'
    body=chain_table(f,'fidelityObligations',[(k,l) for k,l in [('fidelityId','Obligation'),('sourcePath','Source'),('sourceRanges','Ranges'),('concreteBoundary','Real boundary'),('encodingRule','Encoding / domain'),('cleanControl','Clean control'),('failureMapping','Failure mapping'),('reflectionDuty','Remaining proof'),('benefitBoundary','Benefit / cost'),('leanSupport','Lean support'),('quintSupport','QNT support'),('dependsOn','Depends on')]],'gsc-fidelity-reflection-obligations',chain_model)
    outputs[f]='#+TITLE: GSC Output Fidelity, Clean-Origin and Failure Reflection Matrix\\n#+SETUPFILE: ../../modeling/org/setup.org\\n\\n* Source-bound obligations\\n:PROPERTIES:\\n:CUSTOM_ID: gsc-output-fidelity-map\\n:AUTHORITY: GambitToolchain\\n:EVIDENCE_CLASS: source-and-conditional-theory\\n:END:\\n\\nThe dependency graph orders research/proof prerequisites, not an observed execution trace. Existing distribution artifacts do not establish a current clean origin. No real parser, runtime adapter or producer qualification is claimed.\\n\\n'+body
    lines=['# Derived proof-prerequisite graph from GscFidelityObligation; no observed build trace.','direction: down']
    for _,v in chain_groups['fidelityObligations']:
        ident=v['fidelityId'].replace('-','_')
        lines.append(ident+': '+json.dumps(v['fidelityId']+'\\n'+textwrap.fill(v['diagramLabel'],32)))
        for dependency in split(v['dependsOn']):lines.append(dependency.replace('-','_')+' -> '+ident)
    outputs['dev/architecture/toolchain/diagrams/output-fidelity.d2']='\\n'.join(lines)+'\\n'
"""
assert anchor in s;s=s.replace(anchor,extra+anchor)
anchor="            for _,contract in chain_groups['correctness']:"
extra="""            for _,duty in chain_groups['fidelityObligations']:
                report_factors += [('fidelity-obligation',duty['fidelityId']),('fidelity-proof-gap',duty['fidelityId']+':'+duty['reflectionDuty']),('fidelity-failure-map',duty['fidelityId']+':'+duty['failureMapping'])]
"""
assert anchor in s;s=s.replace(anchor,extra+anchor);p.write_text(s)
print('Extended document derivation; two new derived outputs')
