require 'fileutils'; require 'json'; require 'digest'
if ARGV.first=='--protocols'
 _,b=ARGV
 m=JSON.parse(File.read(b+'/native-projection.json'))
 JSON.parse(File.read(b+'/native-inputs.json')).each{|p,h|raise 'model source drift' unless Digest::SHA256.file(p).hexdigest==h}
 inputs=%w[evidence/research/execution/entry.json evidence/dsl/execution.ss evidence/research/capacity-admission/protocol-tools.json dev/refactoring/modern-c/models/sysml/root-worker-exit.sysml dev/refactoring/modern-c/models/sysml/root-task-c-refinement.sysml]
 JSON.parse(File.read(inputs[2])).fetch('tools').each_value{|t|raise 'model tool drift' unless Digest::SHA256.file(t.fetch('path')).hexdigest==t.fetch('sha256')}
 inputs.concat(File.readlines(b+'/native-model-inputs.txt',chomp:true))
 steps=[]
 m.fetch('protocolBindings').each do |binding|
  source=binding.fetch('model');id=binding.fetch('id');inputs<<source
  actions=File.read(source).scan(/^\s*action\s+(\w+)/).flatten
  expected=binding.fetch('actions').split(';').map(&:strip)
  raise 'SysML protocol names absent QNT actions' unless (expected-actions).empty?
  mapped=m.fetch('protocolSteps').select{|row|row.fetch('protocol_id')==id}
  covered=mapped.flat_map{|row|row.fetch('actions').split(';').map(&:strip)}
  raise 'QNT actions missing C-boundary disposition' unless (expected-covered).empty?
  mapped.each{|row|raise 'C boundary anchor absent' unless File.read(row.fetch('source')).include?(row.fetch('anchor'))}
  parse=id+'-parse';check=id+'-type';test=id+'-tests'
  steps<<{id:parse,capability:'quint.parse',dependsOn:[],budgetSeconds:5,arguments:{source:source}}
  steps<<{id:check,capability:'quint.typecheck',dependsOn:[parse],budgetSeconds:5,arguments:{source:source,parsed:parse}}
  names=File.read(source).scan(/^\s*run\s+(\w+)/).flatten.sort
  steps<<{id:test,capability:'quint.test',dependsOn:[check,parse],budgetSeconds:10,arguments:{source:source,parsed:parse,main:binding.fetch('main'),seed:'0x101',maxSamples:100,expectedTests:names}}
  [[false,binding.fetch('step')],[true,binding.fetch('negativeStep')]].each do |negative,transition|
   steps<<{id:id+(negative ? '-control' : '-safety'),capability:'quint.verify',dependsOn:[test,parse],budgetSeconds:negative ? 15 : 25,arguments:{source:source,parsed:parse,initializer:binding.fetch('initializer'),step:transition,invariant:binding.fetch('invariant'),negative:negative}}
  end
 end
 steps<<{id:'verdict',capability:'evidence.evaluate',dependsOn:steps.map{|s|s[:id]},budgetSeconds:10,arguments:{dsl:'evidence/research/execution/entry.json',queries:{checked:'checked_step',missing:'missing_step'},expected:{missing:[]},recordedQueries:['checked']}}
 recipe={schema:'evidence-recipe.v2',id:'modern-c-capacity-host-protocols',scope:'SysML-selected existing QNT tests and finite-state safety/counterexamples; no C refinement or runtime admission',budgetSeconds:90,inputs:inputs.uniq,steps:steps}
 path=b+'/protocol.recipe.json';raise 'fresh protocol recipe required' if File.exist?(path)
 File.write(path,JSON.pretty_generate(recipe)+"\n");puts JSON.generate(protocols:m.fetch('protocolBindings').size,steps:steps.size,runtimeAdmitted:false)
 exit
end
b=ARGV.fetch(0); raise 'fresh projection required' if File.exist?(b); FileUtils.mkdir_p(b)
p='dev/refactoring/modern-c/models/sysml/root-worker-exit.sysml'; ns='GambitRootWorkerExit'; q=[]
{
 'Replacement'=>['clauses',%w[id factor.id oldAuthority replacement condition retirement custody memoryOrder savedWork addedCost]],
 'Prerequisite'=>['dependencies',%w[dependent.id prior.id]],
 'Witness'=>['witnesses',%w[id file firstLine lastLine finding]],
 'SourceUse'=>['uses',%w[clause.id witness.id]],
 'Learning'=>['learning',%w[id witnesses fact mismatch inference counterexample]],
 'NativeCase'=>['nativeCases',%w[id observation]],
 'BuildBoundary'=>['buildBoundaries',%w[id source guard reusable failure benefit]],
 'CapacityBoundary'=>['capacityBoundaries',%w[id source premise modelOwner outcome]],
 'NativeBoundary'=>['nativeBoundaries',%w[id source contract admission remaining]],
 'NativeWriter'=>['nativeWriters',%w[id source anchor writes consumer required status]],
 'ProtocolBinding'=>['protocolBindings',%w[id component.id model result actions cMap qntDuty leanDuty premise status main initializer step invariant negativeStep]],
 'ProtocolStep'=>['protocolSteps',%w[id protocol.id actions source anchor boundary progress]],
 'WorkerAdmission'=>['workerAdmission',%w[id progress condition source proofOwner]],
 'Realization'=>['realizations',%w[id phaseOrder sourceRefs publication affinity custody retired overheads qualification remaining modelOwnership]]
}.each do |kind,(group,fields)|
 File.read(p).scan(/part\s+(\w+):#{kind}\s*\{/).flatten.each_with_index do |name,i|
  fields.each { |f| q<<["#{group}.#{i}.#{f.tr('.','_')}","#{ns}::#{name}.#{f}"] }
 end
end
%w[sourceLock upstreamCommit upstreamUrl].each { |f| q<<[f,"#{ns}::#{f}"] }
refinement='dev/refactoring/modern-c/models/sysml/root-task-c-refinement.sysml'
File.read(refinement).scan(/part\s+(\w+):Operation\s*\{/).flatten.each_with_index do |name,i|
 %w[id symbol guard linearization custody gap].each do |f|
  q<<["operations.#{i}.#{f}","GambitRootTaskCRefinement::#{name}.#{f}"]
 end
end
hash_model='dev/refactoring/modern-c/models/sysml/hash-index-ownership.sysml'
{'Contract'=>['hashContracts',%w[id route invariant benefit cost]],
 'Edge'=>['hashEdges',%w[producer.id consumer.id]],
 'Proof'=>['hashProofs',%w[component.id id method artifact premise]]}.each do |kind,(group,fields)|
 File.read(hash_model).scan(/part\s+(\w+):#{kind}\s*\{/).flatten.each_with_index do |name,i|
  fields.each{|field|q<<["#{group}.#{i}.#{field.tr('.','_')}","GambitHashIndexOwnership::#{name}.#{field}"]}
 end
end
File.write(b+'/native-queries.tsv',q.map { |x| x.join("\t") }.join("\n")+"\n")
# Select the queried packages' syntactic namespace closure, not unrelated
# work-in-progress modules. Native strict validation remains authoritative for
# resolution/type correctness; an omitted dependency fails that validation.
sources=Dir.glob('dev/**/*.sysml').sort.to_h do |file|
 text=File.read(file).gsub(/"(?:\\.|[^"\\])*"/m,'').gsub(%r{/\*.*?\*/}m,'').gsub(%r{//[^\n]*},'')
 [file,text]
end
packages=Hash.new{|h,k|h[k]=[]}
sources.each{|file,text|text.scan(/\bpackage\s+(\w+)/).flatten.each{|name|packages[name]<<file}}
pending=[p,refinement,'dev/organization.sysml'];inputs=[]
until pending.empty?
 file=pending.shift;next if inputs.include?(file)
 inputs<<file
 sources.fetch(file).scan(/\b[A-Za-z_]\w*\b/).uniq.each{|name|pending.concat(packages[name]) if packages.key?(name)}
end
inputs.sort!
File.write(b+'/native-model-inputs.txt',inputs.join("\n")+"\n")
guard=%q{ruby -rjson -rdigest -e 'JSON.parse(File.read(ARGV.fetch(0))).each{|p,h|abort("SysML input drift: "+p) unless Digest::SHA256.file(p).hexdigest==h}' "$r/native-inputs.json"}
script=File.read('dev/modeling/tools/read-vm-resize-native.sh').sub('r=.cache/tasks/modern-c-frame-contract/cohort/resize-model',"r=#{b}")
script.sub!('args=(-strict',guard+"\nargs=(-strict")
File.write(b+'/read-native.sh',script+"\n"+guard+"\n")
bound=inputs+[__FILE__,b+'/native-model-inputs.txt',b+'/native-queries.tsv',b+'/read-native.sh']
File.write(b+'/native-inputs.json',JSON.pretty_generate(bound.to_h{|f|[f,Digest::SHA256.file(f).hexdigest]})+"\n")
