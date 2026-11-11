from pathlib import Path
import json
r=Path.cwd();p=r/'dev/architecture/runtime/interfaces/models/sysml/frame-contract.sysml';s=p.read_text()
costs=[
('FG-ENCODE','FL-ENCODE; FL-BIND; FL-MAP','Descriptor decode, root-map reads and target facts already exist','Manual policy duplication and independent packed-field/bitmap interpretations','Schema/bounds validation and target qualification; no mandatory added call per slot if generated inline','Authored policy owners, generated token work, descriptor bytes and delta decode cost','If new schema merely duplicates old emitters/decoders, support grows and no retirement gain follows'),
('FG-COORD','FL-COORD; FL-INTERNAL; FL-UPDATE','Current copying of F words, return-address storage, link/forwarding rewrites and necessary restore remain','Repeated independently maintained origin/offset/size transforms','Generated coordinate checks and origin/copy custody metadata where not already represented','Offset-policy owners removed; copy volume and per-copy metadata delta measured separately','Correct coordinate law alone saves zero copy words; extra dispatch/metadata can regress runtime'),
('FG-ROOTS','FL-COVERAGE; FL-HANDOFF','Materialize/scan/update/reload roots and W_ALL/R_ALL are baseline correctness work','Independent root interpretation and avoidable duplicate publication/scans only where actually established','Root-view registry, epoch/grant validation and cross-owner synchronization deltas','Complete root coverage; signed delta root visits, handoff operations, bytes and pause components','Do not count existing root protection as newly introduced cost or claim bitmap generation skips old-generation scans'),
('FG-SMP','FL-HANDOFF; FL-T0','Required rendezvous, synchronization, task scan work and resource retention do not disappear','PSTATE ownership coupling and provably avoidable imbalance/duplicate coordination','Worker/task contexts, epoch membership, claims, handoff and cache-line traffic','Same-VM parallel useful work, wait/imbalance distribution, contention and peak retained memory under equal semantics','More worker threads, fixed full barriers or forced one processor cannot establish the new architecture or net gain'),
('FG-GENERATION','FL-WRITERS; FL-COVERAGE','Sound scanning remains for classes with incomplete writer/alias closure','Repeated mature continuation traversal only for separately admitted writer-complete classes','New remembered-set barriers/logs, promotion capacity and failure handling plus actual fallback cost','Avoided old-frame root/graph visits versus barrier/log/promotion work; no guessed percentage','An untracked frame/denv/FFI store invalidates scan exclusion; copying another collector algorithm does not close it'),
('FG-LIFETIME','FL-UPDATE; FL-T0','Existing live continuation/code/root custody and cleanup remain necessary','Separate incompatible lifetime interpretations and duplicate support only after real users migrate','Explicit descriptor/image/context leases, close/drain accounting and possible longer retention','Old semantic owners retired, live lease population, last-user latency and retained bytes','No active call does not imply no saved continuation; safety without bounded retained users is not positive gain')]
keys=['gainId','lawRefs','baselineRetained','removedDuplication','incrementalCost','measure','refutation']
extra='\n    part def FrameCostCase {\n'+''.join('        attribute '+k+' : String;\n' for k in keys)+'    }\n'
for i,row in enumerate(costs):extra+='    part costCase'+str(i)+' : FrameCostCase {\n'+''.join('        attribute :>> '+k+' = '+json.dumps(v)+';\n' for k,v in zip(keys,row))+'    }\n'
p.write_text(s.rsplit('}',1)[0]+extra+'}\n')
p=r/'dev/architecture/runtime/models/sysml/composition.sysml';s=p.read_text()
edges=[('T0-EXECUTION','T0-ROOTS','Final roots and stopped mutation under an epoch-bound context grant'),('T0-ROOTS','T0-WORK','Admitted FrameSpec root view and metadata lease, independent of worker ID'),('T0-WORK','T0-HEAP','Phase closure and one accepted capacity/promotion grant'),('T0-HEAP','T0-CONTROL','Relocated roots and governed write/barrier policy'),('T0-CONTROL','T0-ROOTS','Current/saved/captured origins and all controlled mutations'),('T0-FOREIGN','T0-EXECUTION','Legal host ownership, park/reentry and acquired-effect disposition'),('T0-FOREIGN','T0-ROOTS','External roots and alias/borrow closure'),('T0-WORK','T0-PROGRESS','Complete producer/task/descendant census'),('T0-PROGRESS','T0-EXECUTION','Common completion/reload or retained-failure outcome, never local-empty alone')]
extra='\n    part def T0FoundationLink {\n        attribute producerLane : String;\n        attribute consumerLane : String;\n        attribute contract : String;\n    }\n'
for i,row in enumerate(edges):extra+='    part foundationLink'+str(i)+' : T0FoundationLink {\n'+''.join('        attribute :>> '+k+' = '+json.dumps(v)+';\n' for k,v in zip(['producerLane','consumerLane','contract'],row))+'    }\n'
p.write_text(s.rsplit('}',1)[0]+extra+'}\n')
p=r/'dev/modeling/tools/sync-views.py';s=p.read_text();needle="    chain_groups={key:"
insert="""    frame_groups={key:[(x,attrs(x)) for x in elements if typed(x,'GambitFrameContract::'+typ)] for key,typ in {
        'coordinates':'CoordinateLaw','laws':'FrameRefinementLaw','counterexamples':'FrameCounterexample',
        'gains':'FrameCostCase','reasoning':'FrameProjection'}.items()}
    t0_groups={key:[(x,attrs(x)) for x in elements if typed(x,'GambitRuntimeComposition::'+typ)] for key,typ in {
        'lanes':'T0FoundationLane','baselines':'T0BaselineReuse','links':'T0FoundationLink'}.items()}
    frame_model=ROOT/'dev/architecture/runtime/interfaces/models/sysml/frame-contract.sysml'
    t0_model=ROOT/'dev/architecture/runtime/models/sysml/composition.sysml'
    frame_sources={}
    for group in [*frame_groups.values(),*t0_groups.values()]:
        for _,v in group:
            for ref in split(v.get('sourceRefs','')):
                path,extent=ref.rsplit(':',1);lo,hi=map(int,extent.split('-'));p=ROOT/path
                if not p.is_file() or not 1<=lo<=hi<=len(p.read_text().splitlines()):raise ValueError('Invalid frame/T0 source '+ref)
                frame_sources[path]=sha(p)
"""
assert needle in s;s=s.replace(needle,insert+needle)
needle="    f='dev/modeling/component-model-map.org'"
insert="""    # DEV target refactoring models reuse the existing root model registry.
    frame_laws={v['lawId']:v for _,v in frame_groups['laws']};t0_lanes={v['laneId']:v for _,v in t0_groups['lanes']}
    frame_cases={v['caseId']:v for _,v in frame_groups['counterexamples']}
    if len(frame_laws)!=len(frame_groups['laws']) or len(frame_cases)!=len(frame_groups['counterexamples']) or len(t0_lanes)!=len(t0_groups['lanes']):raise ValueError('Duplicate frame/T0 identity')
    parent_duties={v['dutyId'] for _,v in descriptor_groups['proofDuties']};field_ids=descriptor_ids['fields'];cuts=descriptor_ids['migration']
    migrations={v['stageId'] for _,v in blueprint_groups['migrationStages']};blueprint_ids={v['moduleId'] for _,v in blueprint_groups['modules']}
    for v in frame_laws.values():
        for key,ids in [('fieldRefs',field_ids),('parentDuties',parent_duties),('migrationCuts',cuts),('foundationLanes',set(t0_lanes)),('counterexampleIds',set(frame_cases))]:
            if not set(split(v[key]))<=ids:raise ValueError('Unknown frame reference '+key)
    for v in frame_cases.values():
        if not set(split(v['lawRefs']))<=set(frame_laws):raise ValueError('Unknown counterexample law')
    for _,v in frame_groups['gains']:
        if not set(split(v['lawRefs']))<=set(frame_laws):raise ValueError('Unknown gain law')
    for v in t0_lanes.values():
        for key,ids in [('blueprintModules',blueprint_ids),('migrationStages',migrations),('sharedContracts',contract_ids),('frameLawRefs',set(frame_laws))]:
            if not set(split(v[key]))<=ids:raise ValueError('Unknown T0 reference '+key)
    for _,v in t0_groups['links']:
        if v['producerLane'] not in t0_lanes or v['consumerLane'] not in t0_lanes:raise ValueError('Unbound T0 interface edge')
    resolved_baselines=[];baseline_inputs={}
    for _,v in t0_groups['baselines']:
        candidates=[c for _,c in contracts if c['contractId']==v['bindingId']]
        if len(candidates)!=1:raise ValueError('T0 baseline not uniquely bound')
        binding=candidates[0];resolved_baselines.append(dict(v,quintSource=binding['quintSource'],leanSource=binding['leanSource'],quintSymbols=binding['quintSymbols'],leanSymbols=binding['leanSymbols'],existingEvidenceClass=binding['resultClass'],existingComposition=binding['compositionStatus']))
        for key in ['quintSource','leanSource']:baseline_inputs[binding[key]]=sha(ROOT/binding[key])
    f='dev/architecture/runtime/interfaces/frame-contract-map.org';body=''
    for group,title,columns in [
        ('coordinates','Source-derived coordinate laws',[('coordinateId','ID'),('domain','Domain'),('equation','Equation'),('premises','Meaning / premises'),('sourceRefs','Sources')]),
        ('laws','Target refactoring proof duties, not implemented symbols',[('lawId','Duty'),('fieldRefs','FrameSpec fields'),('parentDuties','Parent duties'),('foundationLanes','T0 targets'),('migrationCuts','Migration cuts'),('quintState','Proposed QNT state'),('quintActions','Proposed QNT steps'),('quintInvariant','Required invariant'),('leanObligation','Required Lean relation/law'),('requiredPremises','Open premises'),('retireRoles','Role retirement'),('counterexampleIds','Counterexamples'),('sourceRefs','Sources')]),
        ('counterexamples','Counterexample classification and conditional reachability',[('caseId','Case'),('lawRefs','Laws'),('trace','Trace / discrepancy'),('condition','Required condition'),('status','Evidence status')]),
        ('gains','Baseline work versus actual incremental overhead',[('gainId','Case'),('lawRefs','Laws'),('baselineRetained','Required baseline'),('removedDuplication','Potential removal'),('incrementalCost','Added delta'),('measure','Quantification'),('refutation','Refutation')])]:
        body+='\\n** '+title+'\\n| '+' | '.join(label for _,label in columns)+' |\\n|'+ '+'.join('---' for _ in columns)+'|\\n'
        for _,v in frame_groups[group]:
            values=[]
            for key,_ in columns:
                value=v[key]
                if key=='sourceRefs':value='; '.join(file_link(f,ref.rsplit(':',1)[0],ref) for ref in split(value))
                values.append(value.replace('|','/'))
            body+='| '+' | '.join(values)+' |\\n'
    outputs[f]='#+TITLE: FrameSpec Coordinate, Root and T0 Refactoring Matrix\\n#+SETUPFILE: ../../../modeling/org/setup.org\\n\\n* Target interface and open proof obligations\\n:PROPERTIES:\\n:CUSTOM_ID: frame-contract-map\\n:AUTHORITY: GambitFrameContract\\n:STATUS: to-be-refactoring-native-refinement-open\\n:END:\\n\\nExisting root model files are referenced by their own scoped bindings, not copied or relabeled as new GC/SMP proofs. Arithmetic sketches and conditional source discrepancies are not native test results.\\n\\n'+generated(frame_model,'frame-contract',body)
    f='dev/refactoring/modern-c/t0-foundation-map.org';body='** T0 target architecture lanes\\n| Lane | Target | Blueprint modules | Replacement | Retiring responsibility | FrameSpec relation | Migration | Shared contracts | Frame duties | Required / added cost | Open architecture | Source |\\n|---+---+---+---+---+---+---+---+---+---+---+---|\\n'
    keys=['laneId','label','blueprintModules','targetDesign','retiringResponsibility','frameContract','migrationStages','sharedContracts','frameLawRefs','necessaryAndAddedCost','openArchitecture','sourceRefs']
    for _,v in t0_groups['lanes']:body+='| '+' | '.join('; '.join(file_link(f,ref.rsplit(':',1)[0],ref) for ref in split(v[k])) if k=='sourceRefs' else v[k] for k in keys)+' |\\n'
    body+='\\n** Existing root model reuse and remaining target gap\\n| Binding | Existing QNT | Existing Lean | Exact scoped status | Reuse | Target gap |\\n|---+---+---+---+---+---|\\n'
    for v in resolved_baselines:body+='| '+' | '.join([v['bindingId'],file_link(f,v['quintSource'],v['quintSymbols']),file_link(f,v['leanSource'],v['leanSymbols']),v['existingEvidenceClass']+'; '+v['existingComposition'],v['role'],v['targetGap']])+' |\\n'
    outputs[f]='#+TITLE: T0 GC and SMP Target Refactoring Foundation\\n#+SETUPFILE: ../../modeling/org/setup.org\\n\\n* DEV target architecture, separate from existing root evidence\\n:PROPERTIES:\\n:CUSTOM_ID: t0-foundation-map\\n:AUTHORITY: GambitRuntimeComposition\\n:STATUS: target-design-refinement-open\\n:END:\\n\\nGC and same-VM SMP are T0 modernization work. FrameSpec is one shared interface, not the whole collector or scheduler. Existing root artifacts retain their exact scope and limitations.\\n\\n'+generated(t0_model,'t0-foundation',body)
    lines=['# DEV target architecture only; cycles are rely/guarantee dependencies, not proofs.','direction: right']
    for v in t0_lanes.values():lines.append(v['laneId'].replace('-','_')+': '+json.dumps(v['laneId']+'\\n'+textwrap.fill(v['label'],28)))
    for _,v in t0_groups['links']:lines.append(v['producerLane'].replace('-','_')+' -> '+v['consumerLane'].replace('-','_')+': '+json.dumps(textwrap.fill(v['contract'],32)))
    outputs['dev/refactoring/modern-c/diagrams/t0-foundation.d2']='\\n'.join(lines)+'\\n'
    lines=['# DEV FrameSpec target interface; algebra and native refinement remain distinct.','direction: down','Scheme: "Scheme semantic liveness + saved registers"','Encode: "FL-ENCODE / FL-INTERNAL\\\\nBounded kind, cfs, F and root-map encoding"','Bind: "FL-BIND / FL-MAP\\\\nResolved OFD + streaming/random bit contract"','Coords: "FL-COORD / FL-UPDATE\\\\nStack B[-i] <-> Heap H[F+1-i]\\\\nControl rewrites and copy custody explicit"','Roots: "FL-COVERAGE / FL-WRITERS\\\\nData + return + control + foreign roots"','T0: "FL-HANDOFF / FL-T0\\\\nTarget execution / participant / GC worker split"','Existing: "Existing models/ QNT + Lean bindings\\\\nScoped support, unchanged"','Ascent: "ASCENT source-law-target-cut-counterexample joins\\\\nHypotheses, no native admission"','Scheme -> Encode','Encode -> Bind','Bind -> Coords','Coords -> Roots','Roots -> T0','Existing -> T0: "reuse by contract ID"','Encode -> Ascent','Roots -> Ascent','T0 -> Ascent']
    outputs['dev/architecture/runtime/interfaces/diagrams/frame-contract.d2']='\\n'.join(lines)+'\\n'
    projection=frame_groups['reasoning']
    if len(projection)!=1:raise ValueError('Expected one frame reasoning owner')
    projection=projection[0][1]
    frame_inputs={str(frame_model.relative_to(ROOT)):sha(frame_model),str(t0_model.relative_to(ROOT)):sha(t0_model),str(RELATIONS.relative_to(ROOT)):sha(RELATIONS),**frame_sources,**baseline_inputs,**descriptor_inputs}
    frame_bundle=hashlib.sha256(json.dumps(frame_inputs,sort_keys=True).encode()).hexdigest()
    fp=['(define-evidence (query)',' (sources) (outputs clue factor)',
        ' (relation frameLaw (id claim key))',' (relation lawFactor (law kind value))',
        ' (relation laneFactor (lane kind value))',' (relation lawLane (law lane))',
        ' (relation lawCase (law caseId))',' (relation caseFactor (caseId kind value))',
        ' (relation authority (path digest bundle))',' (relation clue (id claim polarity source))',' (relation factor (id name value))']
    def ff(name,row):fp.append(' (fact ('+name+' '+' '.join(json.dumps(x) for x in row)+'))')
    ff('authority',[str(frame_model.relative_to(ROOT)),sha(frame_model),frame_bundle])
    for v in frame_laws.values():
        key=v['lawId'];ff('frameLaw',[key+':'+frame_bundle,'frame-foundation:'+key+':'+frame_bundle,key])
        for name,value in [('field-contract',v['fieldRefs']),('parent-duty',v['parentDuties']),('migration-cut',v['migrationCuts']),('qnt-obligation',v['quintInvariant']+' / steps: '+v['quintActions']),('lean-obligation',v['leanObligation']),('open-premise',v['requiredPremises']),('retirement-gate',v['retireRoles'])]:ff('lawFactor',[key,name,key+':'+value])
        for ref in split(v['sourceRefs']):ff('lawFactor',[key,'code-source',key+':'+ref+':'+frame_sources[ref.rsplit(':',1)[0]]])
        for lane in split(v['foundationLanes']):ff('lawLane',[key,lane])
        for case in split(v['counterexampleIds']):ff('lawCase',[key,case])
    for v in t0_lanes.values():
        for name,value in [('target-redesign',v['targetDesign']),('shared-contract',v['sharedContracts']),('target-migration',v['migrationStages']),('target-gap',v['openArchitecture'])]:ff('laneFactor',[v['laneId'],name,v['laneId']+':'+value])
    for v in frame_cases.values():
        for name,value in [('counterexample',v['trace']),('case-condition',v['condition']),('case-status',v['status'])]:ff('caseFactor',[v['caseId'],name,v['caseId']+':'+value])
    fp += [
        ' ((clue I C (lit "support") S) <-- (frameLaw I C _) (authority S _ _))',
        ' ((factor I (lit "frame-law") K) <-- (frameLaw I _ K))',
        ' ((factor I N V) <-- (frameLaw I _ K) (lawFactor K N V))',
        ' ((factor I (lit "target-lane") L) <-- (frameLaw I _ K) (lawLane K L))',
        ' ((factor I N V) <-- (frameLaw I _ K) (lawLane K L) (laneFactor L N V))',
        ' ((factor I (lit "counterexample-id") X) <-- (frameLaw I _ K) (lawCase K X))',
        ' ((factor I N V) <-- (frameLaw I _ K) (lawCase K X) (caseFactor X N V))',
        ' ((factor I (lit "association-source-sha256") H) <-- (frameLaw I _ _) (authority _ H _))',
        ' ((factor I (lit "association-bundle-sha256") B) <-- (frameLaw I _ _) (authority _ _ B)))']
    outputs[projection['selectorPath']]='\\n'.join(fp)+'\\n'
    outputs[projection['requestPath']]='((selector '+json.dumps(outputs[projection['selectorPath']])+') (constructor "query"))\\n'
"""
assert needle in s;s=s.replace(needle,insert+needle)
needle="    result['nativeDescriptors']=";idx=s.index(needle)
s=s[:idx]+"    result['frameFoundation']={key:[v for _,v in group] for key,group in frame_groups.items()}\n    result['frameFoundation'].update({'targetArchitecture':{key:[v for _,v in group] for key,group in t0_groups.items()},'resolvedBaselines':resolved_baselines,'sourceBindings':frame_inputs,'associationBundle':frame_bundle,'status':'DEV target refactoring and open proof duties; existing root model sources unchanged','newFormalExecution':False})\n"+s[idx:]
p.write_text(s)
print('FrameSpec target laws/counterexamples/costs and T0 redesign map derive from SysML; ASCENT exposes exact associations')
