# Only enumerate paths; SysML evaluates values, references and inherited fields.
require 'fileutils'
out = '.cache/tasks/modern-c-frame-contract/cohort/causal-architecture-model'
FileUtils.mkdir_p(out)
source = 'dev/refactoring/modern-c/models/sysml/causal-architecture.sysml'
ns = 'GambitCausalArchitecture'
queries = []
fields = %w[id gates evidence evidenceClass badHistory rule proofRoute premise refutation present gain cost next]
File.read(source).scan(/part\s+(\w+):Argument\s*\{/).flatten.each_with_index do |name,i|
  fields.each { |f| queries << ["arguments.#{i}.#{f}", "#{ns}::#{name}.#{f}"] }
  %w[painId responsibleModule retirement].each do |f|
    queries << ["arguments.#{i}.#{f}", "#{ns}::#{name}.pressure.#{f}"]
  end
end
File.read(source).scan(/part\s+(\w+):Dependency\s*\{/).flatten.each_with_index do |name,i|
  %w[dependent prerequisite].each { |f| queries << ["dependencies.#{i}.#{f}", "#{ns}::#{name}.#{f}.id"] }
  queries << ["dependencies.#{i}.why", "#{ns}::#{name}.why"]
end
%w[sourceLock gateLedger controlReferences controlSelection runtimeAdmitted commitAdmitted].each { |f| queries << [f,"#{ns}::#{f}"] }
File.write(out+'/native-queries.tsv',queries.map { |x| x.join("\t") }.join("\n")+"\n")
inputs = File.readlines('evidence/research/modern-c-bootstrap/resize-sysml-inputs.txt',chomp:true)
inputs += ['dev/refactoring/models/sysml/adoption.sysml',source]
File.write(out+'/native-model-inputs.txt',inputs.uniq.join("\n")+"\n")
File.write(out+'/read-native.sh',File.read('dev/modeling/tools/read-vm-resize-native.sh').sub(
  'r=.cache/tasks/modern-c-frame-contract/cohort/resize-model',"r=#{out}"))
