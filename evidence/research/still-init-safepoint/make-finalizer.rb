s=File.read('.cache/tasks/structure-poll-still-envelope/finalize.sh')
s=s.gsub('structure-poll-still-envelope','still-init-safepoint').gsub('structure_poll_still_envelope','still_init_safepoint').gsub('StructurePollStillEnvelope','StillInitSafepoint').gsub('"SP-"','"SI-"')
s=s.gsub("'18 passing'","'21 passing'").gsub('namedHistories:18','namedHistories:21').gsub('namedStatements:17','namedStatements:13')
s=s.sub('One constructor a255 batch, abstract section100/still21/effect4 units; unknown potential backing fully charged, no GC ack before init; not source peak measurements','One initializer/two activation roots, req0..2 and abstract held block8; body complete and result-rooted before frozen participation; no remembered-set state or partial unknown readback')
s=s.sub('modern-c-structure-slow-poll-frame-and-still-joint-peak','modern-c-still-initialization-safepoint-root-custody').sub('conditional-kernels-checked-effects-layout-and-source-open','conditional-kernels-checked-source-memory-and-generational-coverage-open')
s=s.gsub('needs:96','needs:100').gsub('edges:272','edges:288').gsub('nodes:96','nodes:100').gsub('directPrerequisites:272','directPrerequisites:288').gsub('sourceRoutes:44','sourceRoutes:46').gsub('concreteCallerFamilies:6','concreteCallerFamilies:8')
s=s.gsub('currentQualifiedLocalSlices:36','currentQualifiedLocalSlices:38').gsub('inheritedUnchangedSlices:34','inheritedUnchangedSlices:36').gsub('currentSourceSimulationOpen:47','currentSourceSimulationOpen:49').gsub('scenarioCases:16','scenarioCases:14').gsub('needs:80,edges:249','needs:84,edges:265')
s=s.gsub('nativeNodes:12,nativeEdges:18','nativeNodes:10,nativeEdges:14')
s=s.sub(/benefit:\{.*?\n views:/m,<<~JQ.strip+"\n views:")
benefit:{modernCMandatory:true,zigIncrementalBenefitEstablished:false,nativeRows:$p[0].initCosts,
selectedCase:"##make-structure still allocation/initialization/result root; sync-op and resize entry; interrupt posting/delivery; marker/native and foreign cleanup boundaries",
sourceImplicitOrdering:"Selected native fill has no ordinary GC/POLL/callback between allocation and initialized rooted handoff; not a newly demonstrated native bug",
mandatoryFill:"a body words once",sentinelAlternativeExtraWrites:"a additional words; optional alternative, not a saving",
existingScratchRootWords:3,targetRootRecords:"O(K)",targetScanSlots:"sum R_i; actual byte layout unqualified",
normalAlignedStillRequest:"8a+63 bytes under predecessor conditional WS8/pointer8 ordinary malloc assumptions",maximumNormalStillRequestBytes:65599,
mandatoryPayloadAllocationsEliminated:0,unknownStorage:"Full possible backing plus live root/init/operation metadata, no timeout refund",
publication:"Body completion AND current result root; remembered coverage additionally required in generational mode",
participation:"Fresh exact request/context/owner/root receipt freezes mutator until completion or withdrawal",
unknownModelBoundary:"QNT models preallocation uncertainty only; partial and complete-undelivered authoritative progress readback remain open",
QgCondition:"Actual omitted acquisition exceeds added root/init/unknown/remembered costs at every dominant phase; later refund never erases an earlier peak",
sourceWriteCensusComplete:false,cMemoryModelRefined:false,generationalCoverageProved:false,
nativeRssOrOomBoundEstablished:false,peakReductionMeasured:false,nativeSpeedupMeasured:false},
JQ
s=s.sub(/ primaryEvidence:\[.*?\nretainedFailures:/m,<<~JQ.strip+"\nretainedFailures:")
primaryEvidence:[{url:"https://ocaml.org/manual/5.3/intfc.html",scope:"5.1-5.2 roots and initialized fields; 7 and9 callback/exception/finalizer boundaries; mechanism learning, not imported Gambit proof"},{url:"https://anil.recoil.org/papers/2020-icfp-retropar.pdf",scope:"4.4 and5 coordinated collection and FFI/runtime integration; no imported benchmark or fiber layout"}],
JQ
s=s.sub(/retainedFailures:\[.*?\],\nnativeQualification:/m,<<~JQ.strip+"\nnativeQualification:")
retainedFailures:[{path:"evidence/research/still-init-safepoint/quint-initial-protocol-failure.log",cause:"Initial model over-scoped an earlier delivery into a later initializer; scoped event corrected, not a native bug"},{path:"evidence/research/still-init-safepoint/lean-initial-failure.log",cause:"Reserved identifier and redundant proof tactic; corrected and kernel/scope checked"}],
JQ
s=s.sub('Predecessor50 native inputs plus new model','Predecessor51 native inputs plus new model')
s=s.gsub('.componentModels.needs=96','.componentModels.needs=100').gsub('.componentModels.directPrerequisites=272','.componentModels.directPrerequisites=288').gsub('.componentModels.currentQualifiedLocalSlices=36','.componentModels.currentQualifiedLocalSlices=38')
s=s.gsub('.assurancePlanner.scenarioCases=16','.assurancePlanner.scenarioCases=14').gsub('.assurancePlanner.sourceRoutes=44','.assurancePlanner.sourceRoutes=46').gsub('.assurancePlanner.currentQualifiedSlices=36','.assurancePlanner.currentQualifiedSlices=38').gsub('.assurancePlanner.currentOpenSourceNeeds=47','.assurancePlanner.currentOpenSourceNeeds=49')
s=s.gsub('needs:96,routes:44','needs:100,routes:46').gsub('.structurePollStillEnvelope={','.stillInitSafepoint={')
s=s.gsub('.nodes=96|.typedConnections=272','.nodes=100|.typedConnections=288').gsub('nodes:12,typedConnections:18','nodes:10,typedConnections:14')
s=s.sub("printf 'Sealed structure/POLL/still receipt %s\\n'", "printf 'Sealed still initialization safe-point receipt %s\\n'")
# Preserve prior detail-view entry; append this study without discarding prior evidence.
s=s.sub('.nativeSysmlViews|=map(select(.source!="dev/architecture/runtime/gc/diagrams/still-init-safepoint.d2"))|','.nativeSysmlViews|=map(select(.source!="dev/architecture/runtime/gc/diagrams/still-init-safepoint.d2"))|')
File.write('.cache/tasks/still-init-safepoint/finalize.sh',s)
