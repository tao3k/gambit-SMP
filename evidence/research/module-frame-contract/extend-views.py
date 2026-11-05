from pathlib import Path
import json
r=Path.cwd();t=r/'.cache/tasks/module-frame-contract'
p=r/'dev/architecture/toolchain/models/sysml/native-descriptor.sysml';s=p.read_text()
needle='    part def DescriptorConsumer {\n';s=s.replace(needle,needle+'        attribute fieldRefs : String;\n        attribute migrationRefs : String;\n')
fields=['MS-IDENTITY; MS-TABLES; MS-INSTANCE','MS-IDENTITY; FS-PHYSICAL; FS-CUSTODY','MS-TABLES; MS-INSTANCE','FS-SEMANTIC; FS-PHYSICAL; FS-CUSTODY','FS-SEMANTIC; FS-PHYSICAL; FS-CUSTODY','FS-SEMANTIC; FS-PHYSICAL; FS-CUSTODY','FS-SEMANTIC; FS-PHYSICAL; FS-CUSTODY']
cuts=['DM-INSTANCE; DM-BIND','DM-FRAME','DM-BIND','DM-FRAME','DM-FRAME','DM-FRAME','DM-FRAME; DM-RETIRE']
for i in range(7):
 needle='    part descriptorConsumer'+str(i)+' : DescriptorConsumer {\n'
 s=s.replace(needle,needle+'        attribute :>> fieldRefs = '+json.dumps(fields[i])+';\n        attribute :>> migrationRefs = '+json.dumps(cuts[i])+';\n')
addition='''
    part def DescriptorProjection {
        attribute modelSource : String;
        attribute selectorPath : String;
        attribute requestPath : String;
        attribute relation : String;
        attribute scope : String;
    }
    part reasoning : DescriptorProjection {
        attribute :>> modelSource = "dev/architecture/toolchain/models/sysml/native-descriptor.sysml";
        attribute :>> selectorPath = "dev/modeling/ascent/native-descriptor.ss";
        attribute :>> requestPath = "dev/modeling/ascent/native-descriptor.request.scm";
        attribute :>> relation = "Actual source uses -> consumer routes -> contract fields -> migration cuts -> owner-specific proof duties and shared contracts";
        attribute :>> scope = "Source-bound research hypotheses; QNT/Lean duties are proposed, no source refinement or execution authority";
    }
'''
p.write_text(s.rsplit('}',1)[0]+addition+'}\n')
p=r/'dev/modeling/tools/sync-views.py';s=p.read_text()
needle="    chain_groups={key:"
insert="""    descriptor_groups={key:[(x,attrs(x)) for x in elements if typed(x,'GambitNativeDescriptor::'+typ)] for key,typ in {
        'fields':'DescriptorField','consumers':'DescriptorConsumer','proofDuties':'DescriptorProofDuty',
        'migration':'DescriptorMigration','gains':'DescriptorGainCase','bindingOptions':'DescriptorBindingOption',
        'pipeline':'DescriptorPipelineNode','reasoning':'DescriptorProjection'}.items()}
    descriptor_model=ROOT/'dev/architecture/toolchain/models/sysml/native-descriptor.sysml'
    descriptor_sources={}
    for group in ['fields','consumers']:
        for _,v in descriptor_groups[group]:
            for ref in split(v['sourceRefs']):
                path,extent=ref.rsplit(':',1);p=ROOT/path
                lo,hi=map(int,extent.split('-'))
                if not p.is_file() or not 1<=lo<=hi<=len(p.read_text().splitlines()):raise ValueError('Invalid descriptor source '+ref)
                descriptor_sources[path]=sha(p)
"""
assert needle in s;s=s.replace(needle,insert+needle)
needle="    f='dev/modeling/component-model-map.org'"
insert="""    # Native descriptor structure and code-to-contract joins are a separate owned
    # projection, not additions to the existing runtime or build proof models.
    descriptor_ids={key:{v[field] for _,v in descriptor_groups[key]} for key,field in [('fields','fieldId'),('consumers','routeId'),('proofDuties','dutyId'),('migration','cutId'),('pipeline','nodeId')]}
    for key,ids in descriptor_ids.items():
        if len(ids)!=len(descriptor_groups[key]):raise ValueError('Duplicate descriptor identity '+key)
    for _,v in descriptor_groups['consumers']:
        for refs,key in [('fieldRefs','fields'),('migrationRefs','migration'),('proofRefs','proofDuties')]:
            if not set(split(v[refs]))<=descriptor_ids[key]:raise ValueError('Unresolved descriptor route '+refs)
    for _,v in descriptor_groups['proofDuties']:
        if v['ownerPath'] not in area_by_path:raise ValueError('Unowned descriptor proof duty')
        if not set(split(v['sharedContracts'])) <= contract_ids|obligation_ids:raise ValueError('Unknown descriptor shared contract')
        if v['status']!='open-design-only':raise ValueError('Descriptor native proof has no acceptance receipt')
    for key,idfield in [('migration','cutId'),('pipeline','nodeId')]:
        pending={v[idfield]:set(split(v['dependsOn'])) for _,v in descriptor_groups[key]};done=set()
        while pending:
            ready={k for k,deps in pending.items() if deps<=done}
            if not ready:raise ValueError('Descriptor dependency cycle or unknown edge '+key)
            done|=ready
            for k in ready:del pending[k]
    f='dev/architecture/toolchain/native-descriptor-map.org';body=''
    for group,title,columns in [
        ('fields','Records and source ownership',[('fieldId','Record ID'),('record','Record'),('fields','Required contents'),('semanticOwner','Scheme owner'),('nativeOwner','Native owner'),('invariant','Contract'),('sourceRefs','Actual sources')]),
        ('consumers','Actual consumer migration closure',[('routeId','Route'),('producer','Producer'),('consumer','Actual consumer'),('sourceRefs','Actual sources'),('fieldRefs','Fields'),('migrationRefs','Cuts'),('observation','Current observation'),('requiredChange','Required replacement'),('retirementGate','Retirement gate'),('proofRefs','Proof duties')]),
        ('proofDuties','QNT and Lean proof obligations, all open',[('dutyId','Duty'),('ownerPath','Owner'),('sharedContracts','Existing shared contracts'),('quintState','Proposed QNT state'),('quintSteps','Proposed QNT actions'),('quintSafety','Required invariant'),('leanRelation','Required Lean relation'),('leanLaw','Required theorem'),('premises','Missing premises'),('counterexample','Counterexample'),('status','Status')]),
        ('migration','Migration and actual retirement',[('cutId','Cut'),('dependsOn','Requires'),('change','Change'),('retiringRole','Old role'),('gate','Acceptance'),('cost','Added cost')]),
        ('gains','Benefit and added overhead',[('gainId','Gain case'),('removedWork','Removed work'),('addedWork','Added work'),('metric','Metric'),('positiveCondition','Positive condition'),('refutation','Refutation')]),
        ('bindingOptions','Binding generation alternatives',[('optionId','Option'),('mechanism','Mechanism'),('canReplace','Can replace'),('cannotSupply','Cannot supply'),('admission','Admission'),('decision','Design decision')])]:
        body+='\\n** '+title+'\\n| '+' | '.join(label for _,label in columns)+' |\\n|'+ '+'.join('---' for _ in columns)+'|\\n'
        for _,v in descriptor_groups[group]:
            values=[]
            for key,_ in columns:
                value=v[key]
                if key=='sourceRefs':value='; '.join(file_link(f,ref.rsplit(':',1)[0],ref) for ref in split(value))
                if key=='ownerPath':value=file_link(f,value+'/index.org',value)
                values.append(value.replace('|','/'))
            body+='| '+' | '.join(values)+' |\\n'
    outputs[f]='#+TITLE: ModuleSpec and FrameSpec Source, Proof and Benefit Matrix\\n#+SETUPFILE: ../../modeling/org/setup.org\\n\\n* SysML-owned native descriptor refactoring\\n:PROPERTIES:\\n:CUSTOM_ID: native-descriptor-map\\n:AUTHORITY: GambitNativeDescriptor\\n:STATUS: design-only-native-refinement-open\\n:END:\\n\\nProposed QNT actions and Lean laws below are obligations, not new source symbols or checked proofs. Actual source anchors are selected consumers, not a complete external FFI census.\\n\\n'+generated(descriptor_model,'native-descriptors',body)
    lines=['# SysML-owned producer/consumer architecture; all native refinement remains OPEN.','direction: down']
    for _,v in descriptor_groups['pipeline']:
        lines.append(v['nodeId']+': '+json.dumps(v['diagramLabel']))
        for dep in split(v['dependsOn']):lines.append(dep+' -> '+v['nodeId'])
    lines+=['Ascent: "ASCENT code-contract-proof joins\\\\nSource-bound hypotheses, no admission"','SysML: "SysML owns fields / source uses / cuts / duties"','SysML -> Ascent','Semantic -> Ascent: "producer identity"','Instance -> Ascent: "actual consumers"','Proofs: "QNT interleavings + Lean refinement duties\\\\nPlanned, no new formal execution"','Ascent -> Proofs','Proofs -> Retirement: "requires discharged obligations"']
    outputs['dev/architecture/toolchain/diagrams/native-descriptor.d2']='\\n'.join(lines)+'\\n'
    descriptor_projection=descriptor_groups['reasoning']
    if len(descriptor_projection)!=1:raise ValueError('Expected one descriptor reasoning projection')
    descriptor_projection=descriptor_projection[0][1]
    descriptor_inputs={str(descriptor_model.relative_to(ROOT)):sha(descriptor_model),**descriptor_sources}
    descriptor_bundle=hashlib.sha256(json.dumps(descriptor_inputs,sort_keys=True).encode()).hexdigest()
    native=['(define-evidence (query)',' (sources) (outputs clue factor)',
        ' (relation route (id claim key consumer fields cuts))',
        ' (relation sourceUse (route ref digest))',
        ' (relation usesProof (route duty))',
        ' (relation proof (duty owner law status shared))',
        ' (relation authority (path digest bundle))',
        ' (relation clue (id claim polarity source))',' (relation factor (id name value))']
    def native_fact(name,values):native.append(' (fact ('+name+' '+' '.join(json.dumps(x) for x in values)+'))')
    native_fact('authority',[str(descriptor_model.relative_to(ROOT)),sha(descriptor_model),descriptor_bundle])
    for _,v in descriptor_groups['consumers']:
        native_fact('route',[v['routeId']+':'+descriptor_bundle,'native-descriptor:'+v['routeId']+':'+descriptor_bundle,v['routeId'],v['consumer'],v['fieldRefs'],v['migrationRefs']])
        for ref in split(v['sourceRefs']):native_fact('sourceUse',[v['routeId'],ref,descriptor_sources[ref.rsplit(':',1)[0]]])
        for duty in split(v['proofRefs']):native_fact('usesProof',[v['routeId'],duty])
    for _,v in descriptor_groups['proofDuties']:native_fact('proof',[v['dutyId'],v['ownerPath'],v['leanLaw']+' / QNT: '+v['quintSafety'],v['status'],v['sharedContracts']])
    native += [
        ' ((clue I C (lit "support") S) <-- (route I C _ _ _ _) (authority S _ _))',
        ' ((factor I (lit "route-id") R) <-- (route I _ R _ _ _))',
        ' ((factor I (lit "actual-consumer") C) <-- (route I _ _ C _ _))',
        ' ((factor I (lit "contract-fields") F) <-- (route I _ _ _ F _))',
        ' ((factor I (lit "migration-cuts") M) <-- (route I _ _ _ _ M))',
        ' ((factor I (lit "code-source") S) <-- (route I _ R _ _ _) (sourceUse R S _))',
        ' ((factor I (lit "code-source-sha256") H) <-- (route I _ R _ _ _) (sourceUse R _ H))',
        ' ((factor I (lit "proof-obligation") D) <-- (route I _ R _ _ _) (usesProof R D))',
        ' ((factor I (lit "proof-owner") O) <-- (route I _ R _ _ _) (usesProof R D) (proof D O _ _ _))',
        ' ((factor I (lit "proof-law") L) <-- (route I _ R _ _ _) (usesProof R D) (proof D _ L _ _))',
        ' ((factor I (lit "proof-status") T) <-- (route I _ R _ _ _) (usesProof R D) (proof D _ _ T _))',
        ' ((factor I (lit "shared-contracts") S) <-- (route I _ R _ _ _) (usesProof R D) (proof D _ _ _ S))',
        ' ((factor I (lit "association-source-sha256") H) <-- (route I _ _ _ _ _) (authority _ H _))',
        ' ((factor I (lit "association-bundle-sha256") B) <-- (route I _ _ _ _ _) (authority _ _ B)))']
    outputs[descriptor_projection['selectorPath']]='\\n'.join(native)+'\\n'
    outputs[descriptor_projection['requestPath']]='((selector '+json.dumps(outputs[descriptor_projection['selectorPath']])+') (constructor "query"))\\n'
"""
assert needle in s;s=s.replace(needle,insert+needle)
needle="    association_inputs.update(role_sources)";s=s.replace(needle,needle+'\n    association_inputs.update(descriptor_inputs)')
needle="    result['cRefactorRoles']=";idx=s.index(needle)
s=s[:idx]+"    result['nativeDescriptors']={key:[v for _,v in group] for key,group in descriptor_groups.items()}\n    result['nativeDescriptors'].update({'sourceBindings':descriptor_inputs,'associationBundle':descriptor_bundle,'formalStatus':'planned obligations only; no new QNT/Lean source or proof execution','runtimePathsRetired':0})\n"+s[idx:]
p.write_text(s)
print('Added SysML-derived records, consumers, migration/proof/cost tables, D2 and independent ASCENT source-contract joins')
