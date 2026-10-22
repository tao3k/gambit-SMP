r='.cache/tasks/still-init-recovery'
s=File.read('.cache/tasks/still-init-safepoint/finalize.sh').gsub('still-init-safepoint','still-init-recovery').gsub('still_init_safepoint','still_init_recovery').gsub('StillInitSafepoint','StillInitRecovery').gsub('"SI-"','"IR-"')
s=s.sub("'21 passing'","'31 passing'").sub('namedHistories:21','namedHistories:31').sub('maxSteps:80','maxSteps:100').sub('namedStatements:13','namedStatements:16')
s=s.sub('One initializer/two activation roots, req0..2 and abstract held block8; body complete and result-rooted before frozen participation; no remembered-set state or partial unknown readback','One operation/three fields/two owner generations/one recipient slot; distinct reserved, physical and committed progress, partial/completed/accepted lost replies; abstract backing8; native memory/source refinement open')
s=s.sub('modern-c-still-initialization-safepoint-root-custody','modern-c-partial-initialization-and-undelivered-result-recovery').sub('conditional-kernels-checked-source-memory-and-generational-coverage-open','conditional-progress-and-admission-kernels-checked-native-refinement-open')
s=s.gsub('needs:100','needs:106').gsub('edges:288','edges:314').gsub('nodes:100','nodes:106').gsub('directPrerequisites:288','directPrerequisites:314').gsub('sourceRoutes:46','sourceRoutes:50')
s=s.gsub('currentQualifiedLocalSlices:38','currentQualifiedLocalSlices:40').gsub('inheritedUnchangedSlices:36','inheritedUnchangedSlices:38').gsub('currentSourceSimulationOpen:49','currentSourceSimulationOpen:53').gsub('scenarioCases:14','scenarioCases:16').gsub('needs:84,edges:265,completeOwnerComponents:4','needs:94,edges:297,completeOwnerComponents:5')
s=s.gsub('nativeNodes:10,nativeEdges:14','nativeNodes:10,nativeEdges:17')
s=s.sub(/benefit:\{.*?\n views:/m,<<~JQ.strip+"\n views:")
benefit:{modernCMandatory:true,zigIncrementalBenefitEstablished:false,nativeRows:$p[0].recoveryCosts,
selectedCase:"STRUCTURE result/R3/R1; native pair/vector; UTF8 partial error and output slot; directory/error-text/string-list and SFUN release consumers",
sourceBoundary:"Selected source endpoints are synchronous, not an existing lost-reply API; proposed service readback/admission remains a target contract",
mandatoryFill:"a body writes; remaining suffix a-p only after authoritative idle cursor",mandatoryPayloadAllocationsEliminated:0,
checkpointCount:"ceil(a/q) only for admitted batch q; synchronous fast path may use a final cut only",
inputStorage:"E owned snapshot bytes unless a stable borrow and lifetime are proved",recordStorage:"O(L+T) live operations plus retained receipts; actual layout unqualified",
rootStorage:"Registered source/receiver overlap; one backing object, actual slots sum R_i",
normalAlignedStillRequest:"8a+63 bytes under predecessor conditional WS8/pointer8 ordinary malloc assumptions",maximumNormalStillRequestBytes:65599,
unknownStorage:"Full possible B + input E + root/init/dedup records; no timeout refund or second allocation",
unknownModelBoundary:"Partial and complete/accepted lost replies modeled; delayed stale transport, native memcpy/decoder/callbacks, root scanning and receipt retirement open",
publication:"Written fields are not a result-root receipt; recipient root and acceptance receipt must linearize together",
externalEffectExactlyOnceEstablished:false,crashRecoveryEstablished:false,livenessEstablished:false,
QgCondition:"max_t(P_t-Q_t+A_t) below max_t(P_t); actual omitted acquisition must survive input/root/unknown/receipt overlaps; unsafe replay is not a valid performance baseline",
cMemoryModelRefined:false,generationalCoverageProved:false,nativeRssOrOomBoundEstablished:false,peakReductionMeasured:false,nativeSpeedupMeasured:false},
JQ
s=s.sub(/ primaryEvidence:\[.*?\nretainedFailures:/m,<<~JQ.strip+"\nretainedFailures:")
primaryEvidence:[{url:"https://www.cs.cmu.edu/~wing/publications/HerlihyWing90.pdf",scope:"2 and4 invocation/response, pending histories and representation obligations; not C linearizability proof"},{url:"https://web.stanford.edu/~ouster/cgi-bin/papers/rifl.pdf",scope:"2-3 identity/completion/retry/metadata lifetime and overwrite counterexample; no imported RPC, crash or benchmark claims"},{url:"https://ocaml.org/manual/5.3/intfc.html",scope:"5.1-5.2 roots/valid fields and7 callback boundary; mechanism learning, not Gambit source proof"}],
JQ
# Previous finalizer has primaryEvidence at column zero.
s=s.sub(/primaryEvidence:\[.*?\nretainedFailures:/m,<<~JQ.strip+"\nretainedFailures:")
primaryEvidence:[{url:"https://www.cs.cmu.edu/~wing/publications/HerlihyWing90.pdf",scope:"2 and4 invocation/response and representation relation; not source linearizability"},{url:"https://web.stanford.edu/~ouster/cgi-bin/papers/rifl.pdf",scope:"2-3 identity/completion/retry/lifetime; no imported RPC, crash or performance claims"},{url:"https://ocaml.org/manual/5.3/intfc.html",scope:"5.1-5.2 roots/valid fields and7 callback boundary"}],
JQ
s=s.sub(/retainedFailures:\[.*?\],\nnativeQualification:/m,<<~JQ.strip+"\nnativeQualification:")
retainedFailures:[{path:"evidence/research/still-init-recovery/quint-initial-control-gap.log",cause:"Idle physical/committed equality missing from initial invariant; prefix-reset control failed; corrected model, not native bug"},{path:"evidence/research/still-init-recovery/lean-initial-failure.log",cause:"Constructor case binder, reserved identifier and unavailable tactic; corrected and kernel/scope checked"},{path:"evidence/research/still-init-recovery/ascent-source-byte-bound-failure.log",cause:"Uncompressed larger ancestor cut exceeds unchanged source byte bound"},{path:"evidence/research/still-init-recovery/ascent-form-bound-failure.log",cause:"First dictionary transport exceeds unchanged form bound; final exact owner-edge/subject transport verified independently"},{path:"evidence/research/still-init-recovery/transport-initial-failure.log",cause:"Initial Emacs checker binding syntax; corrected independent inverse passes"}],
JQ
s=s.sub('Predecessor51 native inputs plus new model','Predecessor52 native inputs plus new model')
s=s.gsub('.componentModels.needs=100','.componentModels.needs=106').gsub('.componentModels.directPrerequisites=288','.componentModels.directPrerequisites=314').gsub('.componentModels.currentQualifiedLocalSlices=38','.componentModels.currentQualifiedLocalSlices=40')
s=s.gsub('.assurancePlanner.scenarioCases=14','.assurancePlanner.scenarioCases=16').gsub('.assurancePlanner.sourceRoutes=46','.assurancePlanner.sourceRoutes=50').gsub('.assurancePlanner.currentQualifiedSlices=38','.assurancePlanner.currentQualifiedSlices=40').gsub('.assurancePlanner.currentOpenSourceNeeds=49','.assurancePlanner.currentOpenSourceNeeds=53')
s=s.gsub('needs:84,edges:265,completeOwners:4','needs:94,edges:297,completeOwners:5').gsub('needs:106,routes:46','needs:106,routes:50').gsub('.stillInitSafepoint={','.stillInitRecovery={')
s=s.gsub('.nodes=100|.typedConnections=288','.nodes=106|.typedConnections=314').gsub('nodes:10,typedConnections:14','nodes:10,typedConnections:17')
s=s.sub('Sealed still initialization safe-point receipt','Sealed partial initializer and result recovery receipt')
# Carry the verified DSL transport boundary as evidence, not a new assurance rule.
s=s.sub('parserLimitsRaised:false,','parserLimitsRaised:false,subjectReferenceIdentityInverseChecked:true,qualificationPolicyAstUnchanged:true,addedLosslessTransportForms:11,emptyInputSpecializationForms:17,')
File.write("#{r}/finalize.sh",s)
p="#{r}/verify-final.sh";s=File.read('.cache/tasks/still-init-safepoint/verify-final.sh').gsub('still-init-safepoint','still-init-recovery').gsub('SI-H','IR-H').gsub('SI-I','IR-I').gsub('==52','==53').gsub('==14','==16').gsub('==38','==40').sub('check-receipt-transport.el','check-transport.el');File.write(p,s)
