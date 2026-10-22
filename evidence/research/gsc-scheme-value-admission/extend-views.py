from pathlib import Path
import re
p=Path('dev/architecture/toolchain/models/sysml/architecture.sysml');s=p.read_text()
for m in list(re.finditer(r'    part gscFidelity\d+ : GscFidelityObligation \{.*?\n    }',s,re.S))[::-1]:
 block=m.group(0);id=re.search(r'fidelityId = "([^"]+)"',block).group(1)
 if id.startswith('V-') and id not in ['V-ROOTS','V-RELOC','V-ADMIT']:block=block.replace('runtimeContractRefs = "ROOT-HANDOFF"','runtimeContractRefs = ""')
 s=s[:m.start()]+block+s[m.end():]
p.write_text(s)
p=Path('dev/modeling/tools/sync-views.py');s=p.read_text()
a="    closed_dag(chain_groups['fidelityObligations'],'fidelityId')"
s=s.replace(a,a+"\n    for _,v in chain_groups['fidelityObligations']:\n        if not set(split(v.get('runtimeContractRefs','')))<=contract_ids:raise ValueError('Unbound fidelity/runtime contract')")
s=s.replace('relation associationDigest (source digest bundle)','relation associationDigest (source digest bundle classification)').replace('relation fidelityDuty (binding identity gap failure)','relation fidelityDuty (binding identity gap failure runtime)')
s=s.replace('[str(assurance_model.relative_to(ROOT)),sha(assurance_model),association_bundle]', "[str(assurance_model.relative_to(ROOT)),sha(assurance_model),association_bundle,'design-association-not-refinement']")
s=s.replace("('evidence-class','design-association-not-refinement'),",'')
s=s.replace("(associationDigest S H _))", "(associationDigest S H _ _))").replace("(associationDigest S _ B))", "(associationDigest S _ B _))")
a="        ' ((factor I (lit \"association-bundle-sha256\") B) <-- (association I _ _ _ S) (associationDigest S _ B _))',"
s=s.replace(a,a+"\n        ' ((factor I (lit \"evidence-class\") C) <-- (association I _ _ _ S) (associationDigest S _ _ C))',")
s=s.replace("duty['fidelityId']+':'+duty['failureMapping']]", "duty['fidelityId']+':'+duty['failureMapping'],duty['fidelityId']+':'+duty.get('runtimeContractRefs','')]")
s=s.replace('(fidelityDuty M X _ _))','(fidelityDuty M X _ _ _))').replace('(fidelityDuty M _ G _))','(fidelityDuty M _ G _ _))').replace('(fidelityDuty M _ _ F))','(fidelityDuty M _ _ F _))')
a="        ' ((factor I (lit \"fidelity-failure-map\") F) <-- (association I _ _ M _) (fidelityDuty M _ _ F _))',"
s=s.replace(a,a+"\n        ' ((factor I (lit \"fidelity-runtime-contract\") R) <-- (association I _ _ M _) (fidelityDuty M _ _ _ R))',")
a="    f='dev/modeling/component-model-map.org'"
extra="""    value_duties=[v for _,v in chain_groups['fidelityObligations'] if v['fidelityId'].startswith('V-')]
    f='dev/architecture/toolchain/scheme-value-admission-map.org'
    columns=[('fidelityId','Duty'),('sourcePath','Source'),('sourceRanges','Ranges'),('concreteBoundary','Actual boundary'),('encodingRule','Admission'),('cleanControl','Stable observation'),('failureMapping','Refusal'),('reflectionDuty','Remaining proof'),('runtimeContractRefs','Runtime contract'),('benefitBoundary','Benefit / cost'),('leanSupport','Lean'),('quintSupport','QNT')]
    body='#+NAME: scheme-value-admission-duty-matrix\\n| '+' | '.join(label for _,label in columns)+' |\\n|'+ '+'.join('---' for _ in columns)+'|\\n'
    for v in value_duties:body+='| '+' | '.join(file_link(f,v[key],v[key]) if key=='sourcePath' else v.get(key,'') for key,_ in columns)+' |\\n'
    outputs[f]='#+TITLE: Actual Scheme Value Admission, Roots and Consumer Reflection\\n#+SETUPFILE: ../../modeling/org/setup.org\\n\\n* Source and proof boundary\\n:PROPERTIES:\\n:CUSTOM_ID: gsc-scheme-value-admission-map\\n:AUTHORITY: GambitToolchain\\n:EVIDENCE_CLASS: logical-heap-specified-native-bridge-open\\n:END:\\n\\nStable payloads, canonical symbol identity and GC root participation are separate. ROOT-HANDOFF is reused by reference; no duplicate runtime root state machine is introduced.\\n\\n'+generated(chain_model,'gsc-scheme-value-admission',body)
    lines=['# Derived V-duty view; ROOT-HANDOFF is an existing external runtime contract.','direction: down']
    for v in value_duties:
        ident=v['fidelityId'].replace('-','_');lines.append(ident+': '+json.dumps(v['fidelityId']+'\\n'+textwrap.fill(v['diagramLabel'],34)))
        for dep in split(v['dependsOn']):
            if dep.startswith('V-'):lines.append(dep.replace('-','_')+' -> '+ident)
        for root in split(v.get('runtimeContractRefs','')):
            external='runtime_'+root.replace('-','_');lines.append(external+': '+json.dumps(root+'\\nExisting execution / GC / FFI contract\\nNative closure remains OPEN'));lines.append(external+' -> '+ident)
    for _,v in chain_groups['fidelityObligations']:
        if v['fidelityId'].startswith('D-'):
            deps=[d for d in split(v['dependsOn']) if d.startswith('V-')]
            if deps:
                ident=v['fidelityId'].replace('-','_');lines.append(ident+': '+json.dumps(v['fidelityId']+'\\n'+textwrap.fill(v['diagramLabel'],34)))
                for dep in deps:lines.append(dep.replace('-','_')+' -> '+ident)
    outputs['dev/architecture/toolchain/diagrams/scheme-value-admission.d2']='\\n'.join(lines)+'\\n'
"""
assert a in s;s=s.replace(a,extra+a);p.write_text(s);print('Root contract references and value-admission views derived')
