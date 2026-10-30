from pathlib import Path
p=Path('dev/modeling/tools/sync-views.py');s=p.read_text()
s=s.replace("' (relation fidelityDuty (binding identity gap failure))',", "' (relation fidelityDuty (binding identity gap failure))',\n        ' (relation associationDigest (source digest bundle))',")
s=s.replace("    artifact_facts=set();contract_facts=set()", "    program.append(' (fact (associationDigest '+' '.join(json.dumps(x) for x in [str(assurance_model.relative_to(ROOT)),sha(assurance_model),association_bundle])+'))')\n    artifact_facts=set();contract_facts=set()")
s=s.replace("('component-id',component_id),('association-source-sha256',sha(assurance_model)),('association-bundle-sha256',association_bundle),", "('component-id',component_id),")
a="        ' ((factor I N V) <-- (association I _ _ M _) (contractFactor M N V))',"
s=s.replace(a,a+"\n        ' ((factor I (lit \"association-source-sha256\") H) <-- (association I _ _ _ S) (associationDigest S H _))',\n        ' ((factor I (lit \"association-bundle-sha256\") B) <-- (association I _ _ _ S) (associationDigest S _ B))',")
a="    f='dev/modeling/component-model-map.org'"
extra="""    recursive_duties=[v for _,v in chain_groups['fidelityObligations'] if v['fidelityId'].startswith('D-')]
    f='dev/architecture/toolchain/recursive-codec-map.org'
    columns=[('fidelityId','Duty'),('sourcePath','Source'),('sourceRanges','Ranges'),('concreteBoundary','Actual boundary'),('encodingRule','Admission / syntax'),('cleanControl','Clean-context obligation'),('failureMapping','Failure / refusal'),('reflectionDuty','Proof boundary'),('benefitBoundary','Benefit / cost'),('leanSupport','Lean'),('quintSupport','QNT')]
    body='#+NAME: recursive-datum-duty-matrix\\n| '+' | '.join(label for _,label in columns)+' |\\n|'+ '+'.join('---' for _ in columns)+'|\\n'
    for v in recursive_duties:body+='| '+' | '.join(file_link(f,v[key],v[key]) if key=='sourcePath' else v[key] for key,_ in columns)+' |\\n'
    outputs[f]='#+TITLE: Recursive Datum Wire and Actual Scheme Domain Matrix\\n#+SETUPFILE: ../../modeling/org/setup.org\\n\\n* Source and proof boundary\\n:PROPERTIES:\\n:CUSTOM_ID: gsc-recursive-codec-map\\n:AUTHORITY: GambitToolchain\\n:EVIDENCE_CLASS: mathematical-wire-closed-actual-domain-open\\n:END:\\n\\nThe recursive framing theorem concerns a mathematical tree. Scheme value identity, scalar semantics, reader/writer fidelity, real consumers and resource costs remain separate duties.\\n\\n'+generated(chain_model,'gsc-recursive-datum-domain',body)
    lines=['# Derived focused proof-prerequisite graph; no runtime parser qualification.','direction: down']
    for v in recursive_duties:
        ident=v['fidelityId'].replace('-','_');lines.append(ident+': '+json.dumps(v['fidelityId']+'\\n'+textwrap.fill(v['diagramLabel'],34)))
        for dep in split(v['dependsOn']):lines.append(dep.replace('-','_')+' -> '+ident)
    for _,v in chain_groups['fidelityObligations']:
        deps=[dep for dep in split(v['dependsOn']) if dep.startswith('D-')]
        if v['fidelityId'].startswith('L-') and deps:
            ident=v['fidelityId'].replace('-','_');lines.append(ident+': '+json.dumps(v['fidelityId']+'\\n'+textwrap.fill(v['diagramLabel'],34)))
            for dep in deps:lines.append(dep.replace('-','_')+' -> '+ident)
    outputs['dev/architecture/toolchain/diagrams/recursive-codec.d2']='\\n'.join(lines)+'\\n'
"""
assert a in s;s=s.replace(a,extra+a);p.write_text(s)
print('Derived focused codec views and shared association identity')
