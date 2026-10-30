require 'json';require 'digest';require 'fileutils';require 'open3'
sha=->p { Digest::SHA256.file(p).hexdigest }
cache='.cache/tasks/modern-c-frame-contract/cohort'
e='evidence/research/modern-c-bootstrap'
target=e+'/architecture-causal-records'
manifest=e+'/architecture-causal-validation.json'
raise 'fresh publication required' if File.exist?(target) || File.exist?(manifest)
model=cache+'/causal-architecture-model'
admission=cache+'/causal-architecture-admission-qualified'
reuse=cache+'/reused-wide'
m=JSON.parse(File.read(model+'/native-projection.json'))
a=JSON.parse(File.read(admission+'/receipt.json'))
w=JSON.parse(File.read(reuse+'/receipt.json'))
raise 'incomplete policy controls' unless a['scenarios'].size==5 && a['scenarios'].values.all? { |s| s['ready'].empty? }
raise 'model/source identity' unless a['sourceLockSha256']==w['sourceLockSha256'] && a['sysmlSha256']==sha.call('dev/refactoring/modern-c/models/sysml/causal-architecture.sysml') && a['projectionSha256']==sha.call(model+'/native-projection.json')
raise 'DSL drift' unless a['dslSha256']==sha.call('dev/modeling/ascent/causal-architecture.rules.scm')
leasePath='.state/task-runs/modern-c-frame-contract/737c5cccff5741f6ae15e5d867f979b1.json'
lease=JSON.parse(File.read(leasePath))
raise 'reuse supervisor receipt' unless lease['exit']==0 && lease['state']=='returned' && lease['parentReaped'] && lease['argv']==['.venv/bin/python',cache+'/lease-completed-bootstrap.py']
stepPath='.cache/tasks/modern-c-frame-contract/runs/bazel-request-custody/run/bootstrap/step-receipt.json'
raise 'bootstrap step drift' unless w['bootstrapStepSha256']==sha.call(stepPath)
paths=File.readlines(model+'/native-model-inputs.txt',chomp:true)
paths+=Dir.glob(model+'/**/*').select { |p| File.file?(p) }
paths+=Dir.glob(admission+'/*').select { |p| File.file?(p) }
paths+=Dir.glob(cache+'/causal-architecture-admission/*').select { |p| File.file?(p) }
paths+=Dir.glob(reuse+'/*').select { |p| File.file?(p) && p.match?(/\.(?:json|stdout|stderr|log)\z/) }
paths+=Dir.glob(cache+'/request-formal-retained/*').select { |p| File.file?(p) }
paths+=%w[
 dev/refactoring/modern-c/causal-architecture.org
 dev/refactoring/modern-c/diagrams/causal-architecture.d2
 dev/refactoring/modern-c/diagrams/causal-architecture.svg
 dev/refactoring/modern-c/index.org
 dev/refactoring/modern-c/resize-source-custody-results.org
 dev/modeling/tools/project-causal-architecture.rb
 dev/modeling/tools/render-causal-architecture.rb
 dev/modeling/tools/qualify-causal-architecture.rb
 dev/modeling/tools/retain-causal-architecture.rb
 dev/modeling/ascent/causal-architecture.rules.scm
 dev/refactoring/pressure-map.org
 docs/smp-twelve-gate-research-map.md
 docs/smp-repair9-accepted-hard-failure.md
 docs/shutdown-error-handoff.md
 vendor/chez/c/schsig.c vendor/chez/c/alloc.c vendor/chez/s/mkgc.ss
 vendor/chez/csug/control.stex
 vendor/gambit/tests/frame-continuation-roots.scm
 evidence/fixtures/gerbil-bazel-build-profile/profile.json
]
paths += [m.fetch('sourceLock'),leasePath,stepPath,e+'/request-custody-validation.json',
 cache+'/lease-completed-bootstrap.py',cache+'/check-reused-wide.rb',cache+'/reused-wide.log',
 cache+'/request-custody-managed-controls/receipt.json',cache+'/request-custody-concurrent/receipt.json',
 '.cache/tasks/modern-c-frame-contract/runs/bazel-request-custody/receipt.json']
JSON.parse(File.read(cache+'/request-formal-retained/receipt.json'))['artifacts'].keys.each { |p| paths<<p }
FileUtils.mkdir_p(target)
records=paths.uniq.sort.to_h do |p|
  raise 'missing retained input '+p unless File.file?(p)
  name=p.gsub('/','__');dest=target+'/'+name;before=sha.call(p)
  FileUtils.cp(p,dest)
  raise 'publication drift '+p unless sha.call(dest)==before && sha.call(p)==before
  [p,{path:dest,sha256:before}]
end
chez,status=Open3.capture2('git','-C','vendor/chez','rev-parse','HEAD');raise 'Chez identity' unless status.success?
File.write(manifest,JSON.pretty_generate({
 scope:'conditional causal architecture and exact completed-bootstrap reuse; not twelve-gate acceptance',
 sourceLockSha256:a['sourceLockSha256'],profileSha256:a['profileSha256'],
 authority:'GambitCausalArchitecture',arguments:m['arguments'].size,dependencies:m['dependencies'].size,
 gateAssociations:m['arguments'].sum { |x| x['gates'].split(';').size },
 canonicalOwners:'GambitRuntimeComposition and GambitRefactoring; no new runtime layout',
 controlReferences:{chezHead:chez.strip,chez:'pinned local representation and GC-generator sources',
   guile:'official manual/instruction contracts only; source browser unavailable; no pinned source audit',
   paper:'PLDI 1996 call1cc indexed abstract; full PDF not fetched',ocaml:'selected coordination mechanisms, not control semantics'},
 scopedNative:{bootstrap:'original completed phase under existing exclusive lease',productEntries:2505,
   wideLanes:2,compilerProcessors:11,runtimeProcessors:[1,11],rootsPerLane:80,forcedGCsPerLane:11,
   naturalExit:true,bootstrapRerun:false,heapIncrease:false,sourceChanged:false,
   originalAggregateOutcome:'DENY retained',supervisorReceipt:records.fetch(leasePath)},
 formal:{artifacts:8,checks:44,reuse:'exact artifact and log hashes; no new C proof'},
 causalPolicy:a.slice('needs','scenarios'),
 toolFailures:['SysML reserved name exit; corrected to exitCase, failed model and metadata retained',
   'Initial ASCENT selector lacked mandatory question output; rejected query and original DSL/tool retained',
   'Premature concurrent diagram invocation refused by existing task lease; serialized render required'],
 nextArchitectureCut:'Same frozen root/source identity -> actual whole-round contiguous reserve-or-retain -> parity flip; complete writer and C-memory-order refinement',
 records:records,runtimeAdmitted:false,commitAdmitted:false
})+"\n")
puts JSON.generate(records:records.size,arguments:m['arguments'].size,wideLanes:2,policyControls:a['scenarios'].size,commitAdmitted:false)
