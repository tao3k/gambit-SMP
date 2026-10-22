r='.cache/tasks/structure-poll-still-envelope'
s=File.read('.cache/tasks/rest-gc-resume-envelope/finalize.sh').gsub('rest-gc-resume-envelope','structure-poll-still-envelope').gsub('rest_gc_resume_envelope','structure_poll_still_envelope').gsub('RestGcResumeEnvelope','StructurePollStillEnvelope')
s=s.gsub('16 passing','18 passing').gsub('namedHistories:16','namedHistories:18').gsub('namedStatements:13','namedStatements:17').gsub('startswith("RG-")','startswith("SP-")')
s=s.gsub('needs:90','needs:96').gsub('directPrerequisites:248','directPrerequisites:272').gsub('sourceRoutes:40','sourceRoutes:44').gsub('routes:40','routes:44').gsub('edges:248','edges:272').gsub('needs:74','needs:80').gsub('edges:225','edges:249').gsub('currentQualifiedLocalSlices:34','currentQualifiedLocalSlices:36').gsub('inheritedUnchangedSlices:32','inheritedUnchangedSlices:34').gsub('currentSourceSimulationOpen:43','currentSourceSimulationOpen:47').gsub('scenarioCases:13','scenarioCases:16')
s=s.gsub('nativeNodes:11,nativeEdges:14','nativeNodes:12,nativeEdges:18').gsub('nodes:90','nodes:96')
s=s.gsub('.componentModels.needs=90','.componentModels.needs=96').gsub('.componentModels.directPrerequisites=248','.componentModels.directPrerequisites=272').gsub('.componentModels.currentQualifiedLocalSlices=34','.componentModels.currentQualifiedLocalSlices=36').gsub('.assurancePlanner.scenarioCases=13','.assurancePlanner.scenarioCases=16').gsub('.assurancePlanner.sourceRoutes=40','.assurancePlanner.sourceRoutes=44').gsub('.assurancePlanner.currentQualifiedSlices=34','.assurancePlanner.currentQualifiedSlices=36').gsub('.assurancePlanner.currentOpenSourceNeeds=43','.assurancePlanner.currentOpenSourceNeeds=47').gsub('.nodes=90','.nodes=96').gsub('.typedConnections=248','.typedConnections=272').gsub('nodes:11,typedConnections:14','nodes:12,typedConnections:18')
s=s.sub(%q{rg --files dev -g '*.sysml' -0 | xargs -0 openssl dgst -sha256 | LC_ALL=C sort > "$r/models-after.sha256"},%q{while IFS= read -r f; do openssl dgst -sha256 "$f"; done < "$r/native-model-inputs.txt" | LC_ALL=C sort > "$r/models-after.sha256"})
s=s.sub('p2 a5, exact constructor extent15, abstract destination20/future grant4, framed GC, known resume, carrier alias and historical peak; not actual first-span Qg','One constructor a255 batch, abstract section100/still21/effect4 units; unknown potential backing fully charged, no GC ack before init; not source peak measurements')
s=s.sub('modern-c-real-rest-construction-gc-resume-joint-envelope','modern-c-structure-slow-poll-frame-and-still-joint-peak').sub('conditional-kernel-checked-source-and-physical-lifetime-open','conditional-kernels-checked-effects-layout-and-source-open')
a=s.index(' benefit:{modernCMandatory:');b=s.index('\n views:',a) || s.index("\n views:",a)
raise 'benefit range' unless a && b
s=s[0...a]+<<~JQ.strip+s[b..]
 benefit:{modernCMandatory:true,zigIncrementalBenefitEstablished:false,nativeRows:$p[0].structureCosts,
 selectedCase:"Existing ##structure POLL1, recursive POLL2, RETN fs5 and make-structure still path",
 countOnlyCapEstablished:false,reason:"Arbitrary live graph, installed interrupts, exceptions, retry/capture versions and other VM participants require explicit bounded inputs",
 representation:"Conditional no-handles WS8, pointer8; header defaults, not a qualified rebuilt native profile",
 stackFrameWords:8,heapFrameWords:7,maximumSingleTraversalStackWords:65528,maximumSingleCanonicalHeapFrameCohortWords:57337,
 defaultFirstPollInternalStackWords:12,defaultFirstPollInternalHeapWords:11,defaultRecursivePollInternalStackWords:20,defaultRecursivePollInternalHeapWords:19,
 restrictedTransferWords:52,firstBreakWords:4,mixedCallerTransferCapEstablished:false,
 stillCharge:"a+6 words",normalAlignedStillRequest:"8a+63 bytes",maximumNormalStillRequestBytes:65599,
 zeroDeferredThresholdActuals:1018,conditionalLp64MsectionRequestBytes:1048615,
 allocationMetric:"Distinct requested backing containers; allocator overhead/low-level-exec/custom routes need their own bindings; not RSS",
 poolReturnDeltaAcquiredBytes:0,pendingSettlementDeltaAcquiredBytes:0,
 QgCondition:"Role-compatible preaccepted tail omits an actual acquisition through all dominant phases; later still/callback/error/unknown holds cannot erase net credit",
 stillCanBePaidByMovableTail:false,lateRefundErasesPastPeak:false,nativeRssOrOomBoundEstablished:false,peakReductionMeasured:false,nativeSpeedupMeasured:false},
JQ
s=s.sub('retainedFailures:[{path:', 'retainedFailures:[{path:') # Replace retained failure list separately below.
a=s.index(' retainedFailures:');b=s.index('\n execution:',a) || s.index("\n execution:",a)
s=s[0...a]+<<~JQ.strip+s[b..]
 retainedFailures:[{path:"evidence/research/structure-poll-still-envelope/whole-dev-native-failure.json",cause:"Concurrent unselected foundation-binding model syntax; no whole-DEV native pass claim"},{path:"evidence/research/structure-poll-still-envelope/whole-dev-org-links-open.json",cause:"Concurrent unselected foundation documents have open links; Org checked for8 owned artifacts only"},{path:"evidence/research/structure-poll-still-envelope/ascent-form-bound-failure.log",cause:"Unpacked receipts exceed unchanged form limit; exact paired transport"},{path:"evidence/research/structure-poll-still-envelope/ascent-column-bound-failure.log",cause:"Initial pair17 columns exceeds unchanged bound; equal-status pair16 with unequal-status fallback"},{path:"evidence/research/structure-poll-still-envelope/ascent-route-byte-bound-failure.log",cause:"Full metadata selector exceeds unchanged source bound; two exact-union projection cuts"},{path:"evidence/research/structure-poll-still-envelope/lean-library-name-failure.log",cause:"Unavailable library theorem name; proof rewritten by induction/omega"}],
 nativeQualification:{scope:"Predecessor50 native inputs plus new model",manifest:"evidence/research/structure-poll-still-envelope/native-model-inputs.txt",wholeDevPassed:false,missingSelectedDependencyIgnored:false},
JQ
s=s.sub('org:{parseAndLocalLinksChecked:true,babelExecuted:false}','org:{scope:"8 owned Org artifacts and their referenced targets",parseAndLocalLinksChecked:true,wholeDevLinkClosureClaimed:false,babelExecuted:false}')
# Summarize both metadata-only cuts.
s=s.sub(%q{jq '{scope:"all-source-routes",scenario:"routes-only",needs:(.modelRequired|length),routes:(.sourceRoute|length),qualified:(.qualifiedSlice|length),ready:(.assuranceReady|length),runtimeAdmitted}' "$r/source-routes.json"},%q{for suffix in '' '-tail'; do
 jq --arg suffix "$suffix" '{scope:("source-routes"+$suffix),scenario:"routes-only",needs:(.modelRequired|length),routes:(.sourceRoute|length),contracts:(.sharedContract|length),qualified:(.qualifiedSlice|length),ready:(.assuranceReady|length),runtimeAdmitted}' "$r/source-routes$suffix.json"
 done})
s=s.sub('routesProjectionQualifications:0','routesProjectionQualifications:0,metadataProjectionCuts:2,sharedContractProjectionCount:8,pairedReceiptIdentityControls:2')
s=s.sub('sourceRoutes:{needs:96,routes:44,proofReceipts:0}','sourceRoutes:{needs:96,routes:44,projectionCuts:2,contracts:8,proofReceipts:0}')
s=s.gsub('"dev/modeling/ascent/component-assurance-routes.request.scm"]','"dev/modeling/ascent/component-assurance-routes.request.scm","dev/modeling/ascent/component-assurance-routes-tail.request.scm"]')
s=s.sub('.restGcResumeEnvelope=', '.structurePollStillEnvelope=')
# Changed global property after the initial general substitution is restGcResumeEnvelope unchanged.
s=s.sub('spatialSeparationProved:false','spatialSeparationProved:false,configuredAbiProved:false')
# New emitted source field metadata also remains conditional.
s=s.sub('Sealed rest/GC/resume receipt','Sealed structure/POLL/still receipt')
File.write("#{r}/finalize.sh",s)
