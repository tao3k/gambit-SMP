from pathlib import Path
p=Path('dev/modeling/tools/sync-views.py');s=p.read_text()
s=s.replace("if not dep.startswith('V-'):lines.append", "if dep.startswith('D-'):lines.append")
s=s.replace('relation association (id claim owner binding source)', 'relation association (id claim owner binding source component premise)')
s=s.replace('relation fidelityDuty (binding identity gap failure runtime)', 'relation fidelityDuty (binding identity gap failure runtime status)')
s=s.replace("[ident,claim,v['ownerPath'],v['bindingId'],str(assurance_model.relative_to(ROOT))]", "[ident,claim,v['ownerPath'],v['bindingId'],str(assurance_model.relative_to(ROOT)),component_id,v['openPremises']]")
s=s.replace("for name,value in [('component-id',component_id),('open-premise',v['openPremises'])]+report_factors+", "for name,value in report_factors+")
s=s.replace("duty['fidelityId']+':'+duty.get('runtimeContractRefs','')]", "duty['fidelityId']+':'+duty.get('runtimeContractRefs',''),duty['fidelityId']+':'+duty.get('researchStatus','not-reclassified')]")
s=s.replace('(association I C _ _ S)', '(association I C _ _ S _ _)').replace('(association I _ _ M _)', '(association I _ _ M _ _ _)').replace('(association I _ _ _ S)', '(association I _ _ _ S _ _)')
s=s.replace('(fidelityDuty M X _ _ _)','(fidelityDuty M X _ _ _ _)').replace('(fidelityDuty M _ G _ _)','(fidelityDuty M _ G _ _ _)').replace('(fidelityDuty M _ _ F _)','(fidelityDuty M _ _ F _ _)').replace('(fidelityDuty M _ _ _ R)','(fidelityDuty M _ _ _ R _)')
anchor="    program += [' ((clue I C"
assert anchor in s
s=s.replace(anchor,"""    program += [' ((factor I (lit "component-id") C) <-- (association I _ _ _ _ C _))',
        ' ((factor I (lit "open-premise") P) <-- (association I _ _ _ _ _ P))',
        ' ((factor I (lit "fidelity-research-status") T) <-- (association I _ _ M _ _ _) (fidelityDuty M _ _ _ _ T))']
"""+anchor)
anchor="    f='dev/modeling/component-model-map.org'"
new='''    script_duties=[v for _,v in chain_groups['fidelityObligations'] if v['fidelityId'].startswith('S-')]
    f='dev/architecture/toolchain/script-line-reflection-map.org'
    columns=[('fidelityId','Duty'),('researchStatus','Bounded disposition'),('sourcePath','Source'),('sourceRanges','Ranges'),('concreteBoundary','Source fact'),('encodingRule','Contract'),('cleanControl','Stable / clean view'),('failureMapping','Failure custody'),('reflectionDuty','Remaining proof'),('benefitBoundary','Net benefit'),('leanSupport','Lean'),('quintSupport','QNT')]
    body='#+NAME: script-line-reflection-duty-matrix\\n| '+' | '.join(label for _,label in columns)+' |\\n|'+ '+'.join('---' for _ in columns)+'|\\n'
    for v in script_duties:body+='| '+' | '.join(file_link(f,v[key],v[key]) if key=='sourcePath' else v[key] for key,_ in columns)+' |\\n'
    outputs[f]='#+TITLE: Script-line Writers, Stable Capture and Trace Reflection\\n#+SETUPFILE: ../../modeling/org/setup.org\\n\\n* Bounded closure and cost projection\\n:PROPERTIES:\\n:CUSTOM_ID: gsc-script-line-reflection-map\\n:AUTHORITY: GambitToolchain\\n:EVIDENCE_CLASS: source-slice-and-conditional-kernel\\n:END:\\n\\nNamed source sites and mathematical implications do not establish a complete dynamic writer universe or native readback/effect refinement. ROOT-HANDOFF is reused; global obligations remain unchanged.\\n\\n'+generated(chain_model,'gsc-script-line-reflection',body)
    lines=['# Derived script-line prerequisites; edges are proof dependencies, not an observed execution trace.','direction: down'];boundary_nodes=set()
    duty_by_id={v['fidelityId']:v for _,v in chain_groups['fidelityObligations']}
    for v in script_duties:
        ident=v['fidelityId'].replace('-','_');lines.append(ident+': '+json.dumps(v['fidelityId']+'\\n'+textwrap.fill(v['diagramLabel'],36)+'\\n'+v['researchStatus']))
        for dep in split(v['dependsOn']):
            if not dep.startswith('S-') and dep not in boundary_nodes:
                lines.append(dep.replace('-','_')+': '+json.dumps(dep+'\\n'+textwrap.fill(duty_by_id[dep]['diagramLabel'],34)));boundary_nodes.add(dep)
            lines.append(dep.replace('-','_')+' -> '+ident)
        for ref in split(v.get('runtimeContractRefs','')):
            external='runtime_'+ref.replace('-','_')
            if ref not in boundary_nodes:lines.append(external+': '+json.dumps(ref+'\\nExisting runtime contract; native closure OPEN'));boundary_nodes.add(ref)
            lines.append(external+' -> '+ident)
    for _,v in chain_groups['fidelityObligations']:
        if v['fidelityId'].startswith('S-'):continue
        deps=[dep for dep in split(v['dependsOn']) if dep.startswith('S-')]
        if deps:
            ident=v['fidelityId'].replace('-','_');lines.append(ident+': '+json.dumps(v['fidelityId']+'\\n'+textwrap.fill(v['diagramLabel'],34)))
            for dep in deps:lines.append(dep.replace('-','_')+' -> '+ident)
    outputs['dev/architecture/toolchain/diagrams/script-line-reflection.d2']='\\n'.join(lines)+'\\n'
'''
assert anchor in s;s=s.replace(anchor,new+anchor)
p.write_text(s);print('Prepared 64 derived views and factored ASCENT association metadata')
