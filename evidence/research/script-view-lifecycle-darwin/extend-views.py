from pathlib import Path
import json
p=Path('dev/architecture/toolchain/models/sysml/stable-view.sysml');s=p.read_text().rstrip()[:-1]
s+='''    part def ViewTransition {
        attribute transitionId : String;
        attribute fromState : String;
        attribute toState : String;
        attribute guard : String;
        attribute effect : String;
        attribute failureCustody : String;
        attribute quintAction : String;
        attribute leanSupport : String;
    }
'''
rows=[('ISSUE','Acquiring','Borrowed','sealed writer/alias/provider set; serialized ingress; qualified roots; no pending cleanup','Pin source read and bind generation/entry/acquisition/content identity','Failure retains acquisition owner; no borrowed token','issue','issuedReceiptReadable'),('REVOKE','Borrowed','Draining','invalidate read permission before authorizing any conflicting write','Advance generation; keep pins, roots and acquisition cleanup owner','Revocation is not source-memory reclamation','revoke','revokeRejectsOldReceipt; revokePreservesCustody'),('RETURN-PIN','Draining','Draining','one active read finishes; no further raw source read','Return one pin without clearing pending cleanup','All remaining pins and cleanup debt stay owned','returnPin','livePinBlocksWriter; returnPinKeepsCleanupDebt'),('CLEANUP-ACK','Draining','Suspended','all pins returned and actual cleanup/root handoff acknowledged','Settle acquisition before root release and entry reuse','Unknown/error completion remains Draining; stale acquisition cannot settle a newer one','cleanupAck','cleanupDebtBlocksDelivery; staleCleanupCannotClear; cleanupAckIdempotent'),('RESUME','Suspended','Acquiring','old acquisition settled; no live pins; Scheme control entry qualified','Fresh generation/entry/acquisition; fresh roots still required','Before-hook failure retains pending owner; old token never revived','resume','freshEntryRejectsOldReceipt; freshEntryHasDistinctToken'),('ROOT-GRANT','Acquiring','Acquiring','actual ROOT-HANDOFF coverage established for this entry','Make source roots available; no implicit writer requalification','Missing root/provider evidence denies issue','rootGrant','issuedReceiptReadable'),('UNKNOWN-WRITER','Acquiring; Borrowed; Suspended','Draining','new unqualified alias/eval/FFI capability reached before conflicting read/write','Revoke and invalidate writer-set authority; keep physical obligations','Unmediated native bypass excludes the profile; legal Scheme execution remains available','unknownWriter','unknownWriterRejectsRead'),('PAYLOAD-WRITE','Acquiring; Draining; Suspended','same','no live read pin and no Borrowed phase; actual writer gate/ordering qualified','Advance content epoch; old read token cannot match','Same-owner callback must first end borrow or refuse observation; no lock self-deadlock','payloadWrite','sameExtentMutationRejects; livePinBlocksWriter')]
fields=['transitionId','fromState','toState','guard','effect','failureCustody','quintAction','leanSupport']
for i,row in enumerate(rows):s+='    part transition'+str(i)+' : ViewTransition {\n'+''.join('        attribute :>> '+k+' = '+json.dumps(v)+';\n' for k,v in zip(fields,row))+'    }\n'
p.write_text(s+'}\n')
p=Path('dev/modeling/tools/sync-views.py');s=p.read_text()
s=s.replace("    chain_groups={key:", "    view_transitions=[(x,attrs(x)) for x in elements if typed(x,'GambitStableView::ViewTransition')]\n    chain_groups={key:")
# Materialize one capability tuple rather than three independent facts; public factors stay unchanged.
s=s.replace("        ' (relation contractFactor (binding name value))',", "        ' (relation contractFactor (binding name value))',\n        ' (relation capabilityDuty (binding identity admission refusal))',")
old="""            for _,cap in chain_groups['capabilityGates']:
                report_factors += [('capability-gate',cap['capabilityId']),('capability-admission',cap['capabilityId']+':'+cap['admitCondition']),('capability-refusal',cap['capabilityId']+':'+cap['refuseCondition'])]
"""
assert old in s;s=s.replace(old,'')
anchor="    for row in sorted(contract_facts):"
extra="""    for _,cap in chain_groups['capabilityGates']:
        row=[duty_binding,cap['capabilityId'],cap['capabilityId']+':'+cap['admitCondition'],cap['capabilityId']+':'+cap['refuseCondition']]
        program.append(' (fact (capabilityDuty '+' '.join(json.dumps(x) for x in row)+'))')
    program += [' ((factor I (lit "capability-gate") X) <-- (association I _ _ M _ _ _) (capabilityDuty M X _ _))',
        ' ((factor I (lit "capability-admission") A) <-- (association I _ _ M _ _ _) (capabilityDuty M _ A _))',
        ' ((factor I (lit "capability-refusal") R) <-- (association I _ _ M _ _ _) (capabilityDuty M _ _ R))']
"""
assert anchor in s;s=s.replace(anchor,extra+anchor)
anchor="    f='dev/modeling/component-model-map.org'"
extra='''    for prefix,stem,title,owner in [('SV-','stable-view','Stable View Issuance, Revocation and Continuation Entry','stable-view.sysml'),('DX-','macos-development','Darwin Development Work and Modern Generated C','macos-development.sysml')]:
        duties=[v for _,v in chain_groups['fidelityObligations'] if v['fidelityId'].startswith(prefix)]
        model=ROOT/'dev/architecture/toolchain/models/sysml'/owner
        f='dev/architecture/toolchain/'+stem+'-map.org'
        columns=[('fidelityId','Duty'),('researchStatus','Status'),('sourcePath','Evidence'),('sourceRanges','Ranges'),('concreteBoundary','Boundary'),('encodingRule','Contract'),('cleanControl','Issue / preserve'),('failureMapping','Refusal / custody'),('reflectionDuty','Open refinement'),('runtimeContractRefs','Shared runtime'),('benefitBoundary','Benefit / cost'),('leanSupport','Lean'),('quintSupport','QNT')]
        body='| '+' | '.join(label for _,label in columns)+' |\\n|'+ '+'.join('---' for _ in columns)+'|\\n'
        for v in duties:body+='| '+' | '.join(file_link(f,v[k],v[k]) if k=='sourcePath' else v.get(k,'') for k,_ in columns)+' |\\n'
        if prefix=='SV-':
            body+='\\n** SysML-owned lifecycle transition mapping\\n| Transition | From | To | Guard | Effect | Failure custody | QNT | Lean |\\n|---+---+---+---+---+---+---+---|\\n'
            for _,v in view_transitions:
                for symbol in split(v['leanSupport']):
                    if not re.search(r'\\btheorem\\s+'+re.escape(symbol)+r'\\b',lean_body):raise ValueError('Unbound lifecycle Lean '+symbol)
                if not re.search(r'\\baction\\s+'+re.escape(v['quintAction'])+r'\\b',(ROOT/'models/build/incremental_build.qnt').read_text()):raise ValueError('Unbound lifecycle QNT')
                body+='| '+' | '.join(v[k] for k in ['transitionId','fromState','toState','guard','effect','failureCustody','quintAction','leanSupport'])+' |\\n'
        outputs[f]='#+TITLE: '+title+'\\n#+SETUPFILE: ../../modeling/org/setup.org\\n\\n* Owned evidence and model projection\\n:PROPERTIES:\\n:CUSTOM_ID: '+stem+'-map\\n:AUTHORITY: '+('GambitStableView' if prefix=='SV-' else 'GambitDarwinDevelopment')+'\\n:EVIDENCE_CLASS: conditional-design-and-source-evidence\\n:END:\\n\\nConcrete writer/FFI, C memory, continuation, I/O and native development-work qualification remain open. Historical component receipts are not current performance results.\\n\\n'+generated(model,stem,body)
        lines=['# SysML-derived conditional design; no native admission.','direction: down']
        if prefix=='SV-':
            for _,v in view_transitions:
                for state in split(v['fromState']):
                    target=state if v['toState']=='same' else v['toState']
                    lines.append(state+' -> '+target+': '+json.dumps(v['transitionId']+' / '+v['quintAction']))
            lines+=['runtime: "ROOT-HANDOFF / CONTROL-ORIGIN / RETIRE-WINDOW\\\\nConcrete refinement remains OPEN"','runtime -> Acquiring: "qualified coverage / fresh entry"','Draining -> runtime: "owned cleanup, no early release"']
        else:
            ids={v['fidelityId'] for v in duties};labels={v['fidelityId']:v for _,v in chain_groups['fidelityObligations']};seen=set()
            for v in duties:
                ident=v['fidelityId'].replace('-','_');lines.append(ident+': '+json.dumps(v['fidelityId']+'\\n'+textwrap.fill(v['diagramLabel'],35)))
                for dep in split(v['dependsOn']):
                    if dep not in ids and dep not in seen:
                        lines.append(dep.replace('-','_')+': '+json.dumps(dep+'\\n'+textwrap.fill(labels[dep]['diagramLabel'],32)));seen.add(dep)
                    lines.append(dep.replace('-','_')+' -> '+ident)
        outputs['dev/architecture/toolchain/diagrams/'+stem+'.d2']='\\n'.join(lines)+'\\n'
'''
assert anchor in s;s=s.replace(anchor,extra+anchor)
p.write_text(s);print('Prepared lifecycle/modern-C Darwin views and shared capability tuples')
