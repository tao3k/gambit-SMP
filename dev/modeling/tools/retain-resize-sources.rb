require 'json'; require 'digest'; require 'fileutils'; require 'open3'
e='evidence/research/modern-c-bootstrap';b='.cache/tasks/modern-c-frame-contract/cohort';r='.cache/tasks/modern-c-frame-contract/runs/bazel-request-custody';sha=->p{Digest::SHA256.file(p).hexdigest};read=->p{JSON.parse(File.read(p))}
lock=e+'/request-custody-source.lock.json';profile='evidence/fixtures/gerbil-bazel-build-profile/profile.json';identity=sha.call(lock)
read.call(lock)['files'].each{|p,h|raise 'source drift '+p unless sha.call('vendor/gambit/'+p)==h['candidateSha256']}
outer=read.call(r+'/receipt.json');raise 'aggregate timeout not preserved' unless outer['outcome']=='DENY'&&outer['timeout']&&outer['parentReaped']&&outer['processGroupQuiescent']&&outer['inputs'][lock]==identity&&outer['inputs'][profile]==sha.call(profile)
boot=read.call(r+'/run/bootstrap/step-receipt.json');raise 'bootstrap' unless boot['outcome']=='PASS'&&boot['fullTwoPassBootstrapEstablished']&&boot['phaseCounts'].values.all?{|n|n==2}
raise 'map' unless read.call(r+'/run/map/step-receipt.json')['outcome']=='PASS'
names=%w[request-custody-concurrent request-custody-exception-payload request-custody-managed-controls request-custody-handoffs request-custody-map-host request-custody-native-controls]
native=names.to_h{|n|j=read.call(b+'/'+n+'/receipt.json');raise n+' identity' unless j['sourceLockSha256']==identity;raise n+' instability' if j['inputsStable']==false;raise n+' failed oracle' if j['rows']&.any?{|x|x['oracleMatched']==false};[n,j]}
raise 'request controls' unless native['request-custody-concurrent']['rows'].count{|x|x['oracleMatched']}==3
raise 'retained payload control' unless native['request-custody-exception-payload']['rows'].count{|x|x['oracleMatched']}==1
raise 'managed controls' unless native['request-custody-managed-controls']['allControlOraclesMatched']
raise 'handoff controls' unless native['request-custody-handoffs']['allOraclesMatched']
raise 'root controls' unless native['request-custody-native-controls']['checks']==12
formal=read.call(b+'/request-formal-retained/receipt.json');raise 'formal' unless formal['rows'].size==44&&formal['rows'].all?{|x|x['matched']};formal['artifacts'].each{|p,h|raise 'model drift '+p unless sha.call(p)==h}
admission=read.call(e+'/request-custody-admission.json');raise 'admission' unless admission['sourceLockSha256']==identity&&admission['scenarios'].size==9&&admission['cAnchorControls'].size==2&&admission['scenarios']['current']['checked']==28&&admission['scenarios'].values.none?{|x|x['allReady']}
abi=read.call(e+'/request-custody-layout.json');raise 'layout identity' unless abi['sourceLockSha256']==identity&&abi['requestRootBytes']==24&&abi['registryBytes']==1536&&abi['vmBytes']==98216
model=read.call(b+'/copy-custody-model/native-projection.json');raise 'model cardinality' unless model['contracts'].size==11&&model['edges'].size==13
# Independently bind every accepted native declaration to the actual fixture
# bytes observed by its runner. A current model path alone cannot issue this.
model['contracts'].each do |c|
  path=c.fetch('nativeArtifact');method=c.fetch('nativeMethod')
  observed=case method
  when 'native-bootstrap' then outer['inputs'][path]
  when 'native-fault','native-startup' then native['request-custody-managed-controls'].fetch('inputSnapshot')[path]
  when 'native-collision' then native['request-custody-handoffs'].fetch('inputs')[File.expand_path(path)]
  when 'native-request' then native['request-custody-concurrent'].fetch('inputs')[File.expand_path(path)]
  else next # Wide-native and C capacity/refinement remain unqualified.
  end
  raise 'native artifact drift '+path unless observed==sha.call(path)
end
head,err,ok=Open3.capture3('git','-C','vendor/gambit','rev-parse','HEAD');raise err unless ok.success?;raise 'commit changed' unless head.strip=='8d2b40341a80083ba90e3f8e77d256d49b3e257a'
records={};out=e+'/request-custody-records';FileUtils.mkdir_p(out)
paths=Dir.glob(r+'/**/*')+Dir.glob(b+'/request-*/**/*')+Dir.glob(b+'/request-*.log')+[b+'/request-resume.json']+Dir.glob(b+'/copy-custody-model/*')+Dir.glob(e+'/request-custody-history/**/*')
paths.uniq.sort.each do |p|
 next unless File.file?(p)&&!File.executable?(p)&&p.match?(/\.(?:json|stdout|stderr|log|txt|tsv|lean|scm|c|h|svg)$/)
 t=out+'/'+p.sub('.cache/tasks/modern-c-frame-contract/','').gsub('/','__');FileUtils.cp(p,t);records[t]=sha.call(t)
end
inputs=File.readlines(b+'/copy-custody-model/native-model-inputs.txt',chomp:true)+formal['artifacts'].keys+read.call(lock)['files'].keys.map{|p|'vendor/gambit/'+p}+[lock,read.call(lock)['patch'],profile,e+'/request-custody-model-input.sysml',e+'/request-custody-hosted-bootstrap.recipe.json',e+'/request-custody-intent.json',e+'/request-custody-causal-review.json',e+'/entry-custody-host.json']+Dir.glob(e+'/request-custody*.scm')+Dir.glob(e+'/request-custody*.h')+Dir.glob(e+'/entry-custody*.scm')+Dir.glob(e+'/entry-custody*.h')+Dir.glob(b+'/*request*.rb')+%w[dev/modeling/ascent/copy-custody.rules.scm dev/modeling/tools/project-copy-custody.rb dev/modeling/tools/render-copy-custody.rb dev/modeling/tools/check-resize-sources.rb dev/modeling/tools/qualify-resize-sources.rb dev/modeling/tools/retain-resize-sources.rb dev/modeling/tools/complete-resize-admission.rb dev/refactoring/modern-c/resize-source-custody.org dev/refactoring/modern-c/diagrams/copy-custody.d2 dev/refactoring/modern-c/diagrams/copy-custody.svg]+[b+'/copy-custody-model/evidence-catalog.json']
snapshot=inputs.uniq.sort.to_h{|p|t=out+'/model__'+p.gsub('/','__');FileUtils.cp(p,t);records[t]=sha.call(t);[p,{sha256:sha.call(p),retained:t}]}
File.write(e+'/request-custody-model-snapshot.json',JSON.pretty_generate({scope:'immutable source/model/tool/test bytes; original native SysML snapshot retained separately',files:snapshot})+"\n")
laws=formal['artifacts'].keys.grep(/\.lean$/).sum{|p|File.read(p).scan(/^theorem\s/).size};histories=formal['artifacts'].keys.grep(/\.qnt$/).sum{|p|File.read(p).scan(/^  run\s/).size}
history=%w[entry-custody-validation.json frame-custody-validation.json].to_h{|n|p=e+'/'+n;[p,sha.call(p)]}
summary={overallOutcome:'BLOCKED',source:{branch:'modern-c',head:head.strip,lock:lock,sha256:identity},profile:{path:profile,sha256:sha.call(profile)},native:{campaign:'DENY',aggregateTimeoutSeconds:outer['wholeSeconds'],bootstrap:'PASS',phaseCounts:boot['phaseCounts'],map:'PASS',wideMap:'completion unobserved at aggregate kill',wideMapHost:'not executed',independentHost11Map:'PASS',requestControls:3,retainedPayloadControl:1,realMovedSourceCells:2,managedControls:5,handoffControls:3,rootProducerChecks:12,testWatchdogSeconds:25,heapIncrease:false},formal:{sysmlContracts:11,handoffs:13,checks:44,qntHistories:histories,negativeControls:24,samplesPerModel:1000,steps:40,conditionalLeanLaws:laws,ascentControls:11,scopedJoins:28,needs:44,CRefinementsClosed:0,preflipPlannerImplemented:false},cost:{vmBytes:abi['vmBytes'],previousVmBytes:96680,vmDelta:1536,requestRootBytes:24,registryBytes:1536,rootCellVisitsPerGCAtMost:64,sectionMetadataDelta:0,retainedGraphBound:'unbounded without a separate heap/resource bound',peakRSSMeasured:false,speedClaim:false},historicalFailures:history,modelSnapshot:{path:e+'/request-custody-model-snapshot.json',sha256:sha.call(e+'/request-custody-model-snapshot.json')},records:records,runtimeAdmitted:false,commitAdmitted:false}
File.write(e+'/request-custody-validation.json',JSON.pretty_generate(summary)+"\n")
org=<<~ORG
#+TITLE: Concurrent Resize Source Custody Results
#+SETUPFILE: ../../modeling/org/setup.org
#+LANGUAGE: en
#+PROPERTY: header-args :eval never :tangle no

* Source-bound outcome
:PROPERTIES:
:AUTHORITY: GambitCopyCustody::resizeSources
:SOURCE_BRANCH: modern-c
:SOURCE_LOCK_SHA256: #{identity}
:COMMIT_ADMITTED: false
:END:
[[file:resize-source-custody.org][The implemented responsibility replacement]] has no new commit.
[[file:../../../evidence/research/modern-c-bootstrap/request-custody-validation.json][The evidence manifest]] preserves exact source/profile, native, formal and failure
identities. The aggregate campaign is DENY at #{outer['wholeSeconds'].round(3)} seconds,
within the original 600-second policy; no timeout or heap was enlarged. Official
bootstrap passed all four phases twice (from-scratch #{boot['commands'].find{|c|c['stage']=='from-scratch'}['seconds'].round(3)} seconds).
Ordinary map passed. Wide-map completion was not observed before aggregate kill;
wide-map-host did not run. Duration cannot establish a deadlock, a root bug, an
external-load cause or a speedup. Independent controls do not erase this failure.

#+NAME: resize-source-native-matrix
| Lane | Result | Scope limit |
|------+--------+-------------|
| Full bootstrap | PASS; four phases twice | build completion is not aggregate acceptance |
| Aggregate Bazel-profile campaign | DENY; 600-second timeout | retain wide-map unknown completion and missing wide-map-host |
| Independent map with explicit host p11 | PASS; natural exit and multi-shot continuation | not the failed wide-root/eleven-GC lane |
| Competing resize and actual GC | PASS; two source cells moved; both payloads entered | separate setup.o scheduling hooks; no race-frequency claim |
| Pending-origin shrink | PASS; explicit rejection then retirement after ACK | self-removal is refused while request is active |
| Gambit exception before transport | PASS; identity reuse refused; supplementary control checks cell relocation and invokes retained closure payload after GC | intentional safety exits, not clean shutdown or arbitrary native death |
| Existing managed fault controls | 5/5 PASS | unknown-join cases are safety exits |
| Existing publication/reuse/CAS handoffs | 3/3 PASS | actual CAS loss/refund, no whole-round capacity claim |
| Producer and independent root regressions | 12 checks PASS; 2387 producer assertions, 306 root cases | recorded 64-bit configurations and sanitizers |

#+NAME: resize-source-benefit-peak-matrix
| Responsibility | Retired work or risk | Added work | Quantified bound | Open condition |
|----------------+----------------------+------------+------------------+----------------|
| Sync transport | movable pointers copied through tree | token validation and selection reload | two real moved cells verified | complete C refinement |
| Source custody | caller/member lifetime as implicit root owner | fixed VM registry | VM 96680 -> 98216 bytes; +1536 | no measured RSS reduction |
| Root scan | omitted pending/retained roots | scan all cells | at most 64 additional cells per GC | frozen writer inventory |
| Completion | root loss on return/error | CONSUMED plus drained ACK or retain | fixed metadata; retained graph may be unbounded | unknown native writes remain unresolved |
| Retirement | abandon active request origin | busy result and caller retry | no added heap reserve | caller API migration and fairness |
| Capacity | confuse successful handoff with physical space | closed inventory and interval planning | section metadata delta zero | pre-flip planner unimplemented |

* Five conjunctive gates
:PROPERTIES:
:STATUS: COMMIT-BLOCKED
:END:
#+NAME: resize-source-closure-matrix
| Gate | Established | Still required |
|------+-------------+----------------|
| Tests | Bootstrap, ordinary/host-p11 map, concurrent/retire/exception and inherited controls | aggregate timeout, wide-root completion, full SMP suite, 32-bit and actual deferred-error races |
| Architecture | Source -> ledger -> context ownership; stable token and drained ACK | whole-round physical plan and C memory-order refinement |
| Process | Actual modern-c changes; exact source/profile and retained failures | conjunctive closure before commit |
| Models | 11 SysML components, 13 handoffs, #{histories} QNT histories, 24 negative controls, #{laws} conditional Lean laws, 11 ASCENT controls | 28/44 joins; eleven C refinements, one planner and four wide-native obligations missing |
| Gambit/paper questions | Exact roots, participation, tail calls and multi-shot continuation kept central | arbitrary native crossing, stop authority, performance and peak qualification |

The all-scopes ASCENT negative control supplies synthetic missing obligations
but remains vetoed by this source's actual aggregate timeout. Those synthetic
facts are not C proof or native observations. Historical exit-70 failures remain
bound to their original source locks. All copyAllReady results are empty.
ORG
File.write('dev/refactoring/modern-c/resize-source-custody-results.org',org)
raise 'retained bytes drift' unless records.all?{|p,h|sha.call(p)==h}
puts JSON.generate(records:records.size,checks:44,joins:28,needs:44,vmDelta:1536,commitAdmitted:false)
