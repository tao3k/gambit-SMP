require 'json';require 'digest';require 'fileutils';require 'open3'
e='evidence/research/modern-c-bootstrap';b='.cache/tasks/modern-c-frame-contract/cohort';r='.cache/tasks/modern-c-frame-contract/runs/bazel-entry-custody-reviewed/run'
sha=->p{Digest::SHA256.file(p).hexdigest};read=->p{JSON.parse(File.read(p))};lock=e+'/entry-custody-source.lock.json';profile='evidence/fixtures/gerbil-bazel-build-profile/profile.json'
read.call(lock)['files'].each{|p,h|raise 'source drift '+p unless sha.call('vendor/gambit/'+p)==h['candidateSha256']}
campaign=read.call(r+'/receipt.json');raise 'campaign' unless campaign['outcome']=='PASS'&&campaign['inputsStable']&&campaign['inputs'][File.expand_path(lock)]==sha.call(lock)&&campaign['inputs'][File.expand_path(profile)]==sha.call(profile)
boot=read.call(r+'/bootstrap/step-receipt.json');raise 'bootstrap' unless boot['fullTwoPassBootstrapEstablished']&&boot['phaseCounts'].values.all?{|n|n==2}
ctrl=read.call(b+'/entry-custody-managed-controls/receipt.json');handoffs=read.call(b+'/entry-custody-handoffs/receipt.json')
[ctrl,handoffs].each{|j|raise 'controls' unless j['inputsStable']&&j['sourceLockSha256']==sha.call(lock)}
raise 'native oracle' unless ctrl['allControlOraclesMatched']&&handoffs['allOraclesMatched']
host=read.call(b+'/entry-custody-map-host/receipt.json');native=read.call(b+'/entry-custody-native-controls/receipt.json')
raise 'map identity' unless host['sourceLockSha256']==sha.call(lock)&&host['rows'].all?{|x|x['oracleMatched']}
raise 'root oracle' unless native['sourceLockSha256']==sha.call(lock)&&native['checks']==12
formal=read.call(b+'/entry-custody-formal-checked/receipt.json');raise 'formal' unless formal['rows'].size==34&&formal['rows'].all?{|x|x['matched']}
formal['artifacts'].each{|p,h|raise 'formal drift '+p unless sha.call(p)==h}
admission=read.call(e+'/entry-custody-admission.json');raise 'admission' unless admission['sourceLockSha256']==sha.call(lock)&&admission['scenarios'].size==9&&admission['cAnchorControls'].size==2&&admission['scenarios']['current']['checked']==29&&admission['scenarios'].values.none?{|x|x['allReady']}
abi=read.call(e+'/entry-custody-layout.json');raise 'ABI identity' unless abi['sourceLockSha256']==sha.call(lock)
model=read.call(b+'/copy-custody-model/native-projection.json');raise 'model cardinality' unless model['contracts'].size==10&&model['edges'].size==10
head,_,status=Open3.capture3('git','-C','vendor/gambit','rev-parse','HEAD');raise 'head' unless status.success?
records={};out=e+'/entry-custody-records';FileUtils.mkdir_p(out)
paths=Dir.glob(r+'/**/*')+%w[entry-custody-controls entry-custody-managed-controls entry-custody-handoffs entry-custody-handoffs-preinclude-failure entry-custody-map-host entry-custody-native-controls entry-custody-formal-initial entry-custody-formal-round entry-custody-formal-checked entry-custody-baseline entry-review-before entry-host-incomplete-sdk entry-host-driver-link-failure copy-custody-model].flat_map{|n|Dir.glob(b+'/'+n+'/**/*')}
paths+=Dir.glob(b+'/entry-host-*.json')+Dir.glob(b+'/entry-host-*.stderr')+Dir.glob(b+'/entry-custody-*campaign.log')+Dir.glob('.cache/tasks/modern-c-frame-contract/runs/bazel-entry-custody*/receipt.json')+Dir.glob('.cache/tasks/modern-c-frame-contract/runs/bazel-entry-custody*/run/receipt.json')
paths+=Dir.glob(b+'/entry-sysml-default-failure/*')+Dir.glob(b+'/entry-model-*.log')
paths<<b+'/entry-retention.log'
paths.uniq.each do |p|
 next unless File.file?(p)&&!File.executable?(p)&&p.match?(/\.(?:json|stdout|stderr|log|txt|tsv|lean|scm|c|h|svg)$/)
 target=out+'/'+p.sub('.cache/tasks/modern-c-frame-contract/','').gsub('/','__');FileUtils.cp(p,target);records[target]=sha.call(target)
end
sourceInputs=read.call(lock)['files'].keys.map{|p|'vendor/gambit/'+p}+[lock,read.call(lock)['patch'],profile]+Dir.glob(e+'/entry-custody*.scm')+[e+'/entry-custody-collision.h',e+'/entry-custody-hosted-bootstrap.recipe.json',e+'/entry-custody-host.json',e+'/entry-custody-intent.json',e+'/entry-custody-causal-review.json']+Dir.glob(b+'/*entry*.rb')
modelInputs=File.readlines(b+'/copy-custody-model/native-model-inputs.txt',chomp:true)+formal['artifacts'].keys+%w[dev/modeling/ascent/copy-custody.rules.scm dev/modeling/tools/project-copy-custody.rb dev/modeling/tools/render-copy-custody.rb dev/modeling/tools/check-startup-custody.rb dev/modeling/tools/qualify-startup-custody.rb dev/modeling/tools/retain-startup-custody.rb]+[b+'/copy-custody-model/evidence-catalog.json']+sourceInputs
modelSnapshot=modelInputs.uniq.sort.to_h do |p|
 target=out+'/model__'+p.gsub('/','__');FileUtils.cp(p,target);records[target]=sha.call(target)
 [p,{sha256:sha.call(p),retained:target}]
end
File.write(e+'/entry-custody-model-snapshot.json',JSON.pretty_generate({scope:'immutable model/tool/test/source bytes and exact native SysML snapshot remain separate',nativeSnapshot:e+'/entry-custody-model-input.sysml',nativeSnapshotSha256:sha.call(e+'/entry-custody-model-input.sysml'),files:modelSnapshot})+"\n")
lanes=%w[map wide-map wide-map-host].map do |id|
 step=read.call(r+'/'+id+'/step-receipt.json');process=read.call(r+'/'+id+'/run-executable.process.json');raise 'lane '+id unless step['outcome']=='PASS'&&process['exit']==0
 {id:id,compilerProcessors:11,runtimeProcessors:process['environment']['GAMBIT_SMP_EXPECTED_PROCESSORS'],naturalExit:true}
end
summary={overallOutcome:'BLOCKED',source:{branch:'modern-c',head:head.strip,lock:lock,sha256:sha.call(lock)},profile:{path:profile,sha256:sha.call(profile)},native:{campaign:'PASS',wholeSeconds:campaign['wholeSeconds'],fromScratchSeconds:boot['commands'].find{|x|x['stage']=='from-scratch'}['seconds'],phaseCounts:boot['phaseCounts'],lanes:lanes,mapHost11:true,managedFaultControls:5,knownAllocationRollback:true,readyBeforeReturnGC:true,publicationYields:10000,publicationImpliesReadiness:false,reuseIterations:40,growthRetirementPairs:80,newSchemeEntries:160,watchdogSeconds:25,casLoss:{class:'native-collision-control',workers:2,realForwardingCAS:true,injectedOutcome:false,cancelledWords:4,committedWords:4,loserCursorRestored:true,rootCellsAgree:true},healthyParticipants:3,gcsWhileUnknownActorHeld:3,safetyExits:2,naturalUnknownShutdown:false,producerChecks:2387,ordinaryRootCases:306,wordBits:64},formal:{sysmlContracts:10,handoffs:10,qntHistories:21,negativeControls:19,safetySamplesPerModel:1000,safetySteps:40,conditionalLeanLaws:28,ascentControls:8,scopedJoins:29,needs:40,sourceSimulationsClosed:0,cPreFlipPlanner:false},cost:{vmBytes:abi['vmBytes'],vmDeltaFromFrame:abi['vmBytes']-95144,contextBytes:abi['contextBytes'],contextDelta:abi['contextBytes']-528,slotBytes:abi['slotBytes'],slotDelta:abi['slotBytes']-24,ledgerBytes:abi['ledgerBytes'],workerBytes:abi['workerBytes'],workerDelta:abi['workerBytes']-248,sectionMetadataBytes:abi['scanMetadataBytes'],additionalSectionMetadataBytes:0,nativeSectionBytes:abi['nativeSectionBytes'],heapParameterIncrease:false,peakRSSMeasured:false,speedClaim:false,conditionalPacking:{L:65536,A:16395,K:255,G:48879,H:'W+floor(U/G)',P:'Q+S+H+R',implemented:false}},historicalFailure:{path:e+'/frame-custody-validation.json',sha256:sha.call(e+'/frame-custody-validation.json'),allocationStartupExit:70,exactScheduleReconstructed:false},modelSnapshot:{path:e+'/entry-custody-model-snapshot.json',sha256:sha.call(e+'/entry-custody-model-snapshot.json')},open:['Ten C memory/root/exception simulations','Actual pre-flip closed inventory U/A/S/R/Q, physical placement and common grant/retention','Source header plain reads versus forwarding CAS and arbitrary foreign writers','32-bit, arbitrary interruption, published retiree unknown join/reaper and complete SMP acceptance','Unbounded OS scheduling fairness and polling CPU cost'],records:records,runtimeAdmitted:false,commitAdmitted:false}
summary[:native][:legacyAsyncYieldControl]={receipt:b+'/entry-custody-controls/receipt.json',sha256:sha.call(b+'/entry-custody-controls/receipt.json'),case:'unknown-multi',exit:70,phase:'healthy startup before unknown join',reinterpretedAsPass:false}
summary[:formal][:ascentControls]=admission['scenarios'].size+admission['cAnchorControls'].size
summary[:open]<<'Pending non-combining resize requests: origin-owned movable thunk root and reload across another request GC'
File.write(e+'/entry-custody-validation.json',JSON.pretty_generate(summary)+"\n")
org=<<~ORG
#+TITLE: Startup Custody Results and Benefit / Peak Matrix
#+SETUPFILE: ../../modeling/org/setup.org
#+LANGUAGE: en
#+PROPERTY: header-args :eval never :tangle no

* Source-bound outcome
:PROPERTIES:
:AUTHORITY: GambitCopyCustody
:SOURCE_BRANCH: modern-c
:SOURCE_LOCK_SHA256: #{sha.call(lock)}
:COMMIT_ADMITTED: false
:END:

[[file:startup-custody.org][The source handoff analysis]] separates member publication, Scheme initialization
and known native close. [[file:round-capacity.org][The pre-flip capacity contract]] is still a target, not an
implemented planner. [[file:../../../evidence/research/modern-c-bootstrap/entry-custody-validation.json][The validation manifest]] binds retained native, formal and failure history.
The unchanged Bazel profile completes the campaign in #{campaign['wholeSeconds'].round(3)} seconds,
with official from-scratch #{summary[:native][:fromScratchSeconds].round(3)} seconds and four phases twice.
These are durations, not a matched speedup result. No heap increase or repair
patch import is credited. The historical exit-70 allocation/startup failure
remains tied to its original source; its exact failed wait/schedule is unknown.

#+NAME: startup-native-evidence
| Lane | Result | Limit of claim |
|------+--------+----------------|
| Full bootstrap | PASS; all four phases twice; existing make -j12 / compiler-VM p1 build action | Build parallelism and compiler VM population are different |
| Map / wide roots | PASS; p11 compiler, explicit host-p11 runtime, multi-shot continuation, eleven GCs | Scoped fixtures, not complete SMP acceptance |
| Managed allocation/create/unknown controls | 5/5; GC before READY, immediate completion assertions | Two unknown controls use intentional safety exits; unchanged legacy async/yield caller separately fails exit 70 before isolation |
| Publication counterexample | 10000 original yields while native ACK is withheld; no READY; release then managed completion | Demonstrates the invalid implication, not reconstruction of the old schedule |
| Fixed-slot reuse after allocation failure | 40 iterations, 80 growth/retirement pairs, 160 actual Scheme entries | Same 25-second external watchdog; no OS fairness proof |
| Actual forwarding CAS collision | Two real workers; one four-word commit, one four-word refund; loser cursor restored; root cells equal and payload intact | Separately linked production mem.c with scheduling/root controls; no injected CAS result, race-frequency or 32-bit claim |
| Scheme producer and independent roots | 2387 checks; 306 fixtures; 306 ordinary/link cases under ASan/UBSan | Selected 64-bit regs 3/5/25 only |

* Benefit and added work

#+NAME: startup-benefit-matrix
| Boundary | Retired responsibility | Added work | Quantitative evidence / boundary |
|----------+------------------------+------------+----------------------------------|
| Ordinary startup completion | Member count and arbitrary yield count as inferred entry evidence | Explicit Scheme ACK; managed caller services GC without holding a lock | No polling after managed return; forced pre-READY GC passes; CPU polling cost remains |
| Slot reuse | Treating a slot/member number as activation completion | Fixed generation, startup state and known-close admission | 80 growth/retirement pairs; no identity table; unknown join cannot reuse |
| Known CAS loss | Incomplete private copy refund / unobserved branch | Full begin/past reservation; real loser cancels the whole unpublished grant | Four words restored in controlled actual CAS; no earlier section waste is refunded |
| Whole GC capacity | Aggregate words or per-copy success as a whole-round guarantee | Closed inventory and physical interval plan before flip | Target H<=W+floor(U/48879), P>=Q+S+H+R, conditional on proved premises; C planner OPEN |
| Model routing | Tokens borrowed by spelling from unrelated model files | Artifact-qualified intern catalog, exact hashes and dependency joins | 29/40 scoped joins; ten C simulations and one native planner obligation missing |

#+NAME: startup-fixed-storage
| Storage | Frame predecessor | Current | Delta |
|---------+-------------------+---------+-------|
| VM embedded bytes | 95144 | #{abi['vmBytes']} | #{abi['vmBytes']-95144} |
| Context bytes | 528 | #{abi['contextBytes']} | #{abi['contextBytes']-528} |
| Resize slot bytes | 24 | #{abi['slotBytes']} | #{abi['slotBytes']-24} |
| Collector worker bytes | 248 | #{abi['workerBytes']} | #{abi['workerBytes']-248} |
| Section scan trailer bytes | 16384 | #{abi['scanMetadataBytes']} | 0 |

The VM includes all 64 contexts and slots; do not add overlapping table rows.
The global runtime service table also gains one native function pointer. Default
collision hooks compile to no code/storage. No added section trailer, heap setting,
peak RSS reduction or throughput improvement is claimed. Whole-round reservations,
destination-half marker/slack, restored stacks and retained domains must be counted
separately; cancellation totals are not distinct peak bytes.

* Five conjunctive gates

#+NAME: startup-closure-matrix
| Gate | Established scope | Still required |
|------+-------------------+----------------|
| Tests | Full current-source bootstrap, p11 multi-shot/GC, managed fault/reuse/publication and actual CAS-loss controls | Retained legacy async/yield exit 70 and full caller-contract migration; complete SMP/failure suite, 32-bit, arbitrary interruption and published-retiree recovery |
| Architecture | Explicit startup identity, rooted Scheme entry, ready/close separation and real private refund | Implement the common pre-flip physical plan; characterize polling and serialization costs |
| Process | Actual vendor modern-c changes, fixed source/profile, failure history and existing supervisor | No new commit while any conjunctive gate is open |
| Models / refinement | Ten SysML contracts and ten handoffs; 21 QNT histories, 19 negatives, 1000x40 sampled safety per model; 28 conditional Lean laws; eleven ASCENT controls and D2 | Ten source/C simulations and one pre-flip native obligation remain missing |
| Gambit / paper questions | Keep Scheme-owned frames, portable C, tail calls and multi-shot continuation; separate scheduling, roots and copying authorities | Pending resize C copies need origin-owned roots/reload across another request GC; complete FFI/writer/root inventory, source identity, memory order, metadata lifetime, whole-round packing and fairness |

The synthetic all-scopes ASCENT control checks 40/40 evidence joins but remains
vetoed by this source's real legacy async/yield failure; synthetic refinement
facts are not C evidence. The older frame-custody native failure remains bound
to its original source and is not rebound to this source.
Every control leaves copyAllReady empty. A finite model or conditional arithmetic
law cannot issue native runtime admission.
ORG
File.write('dev/refactoring/modern-c/startup-custody-results.org',org)
puts JSON.generate(retainedRecords:records.size,scopedJoins:29,needs:40,vmDelta:abi['vmBytes']-95144,commitAdmitted:false)
