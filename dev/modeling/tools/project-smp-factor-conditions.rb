require 'fileutils'
b=ARGV.fetch(0);raise 'fresh projection required' if File.exist?(b);FileUtils.mkdir_p(b)
p='dev/refactoring/modern-c/models/sysml/smp-factor-conditions.sysml';ns='GambitSmpFactorConditions';q=[]
fields=%w[id scope mechanism sourceCondition nativeCondition workMetric memoryMetric boundary argument.id argument.evidence argument.evidenceClass argument.badHistory argument.rule argument.premise argument.refutation argument.gates argument.pressure.painId argument.pressure.responsibleModule]
File.read(p).scan(/part\s+(\w+):Factor\s*\{/).flatten.each_with_index do |name,i|
 fields.each { |f| q<<["factors.#{i}.#{f.split('.').join('_')}","#{ns}::#{name}.#{f}"] }
end
File.read(p).scan(/part\s+(\w+):Effect\s*\{/).flatten.each_with_index do |name,i|
 %w[factor.id criterion.id].each { |f| q<<["effects.#{i}.#{f.split('.').join('_')}","#{ns}::#{name}.#{f}"] }
end
causal='dev/refactoring/modern-c/models/sysml/causal-architecture.sysml'
File.read(causal).scan(/part\s+(\w+):Dependency\s*\{/).flatten.each_with_index do |name,i|
 %w[dependent.id prerequisite.id why].each { |f| q<<["dependencies.#{i}.#{f.split('.').join('_')}","GambitCausalArchitecture::#{name}.#{f}"] }
end
%w[gateLedger priorEvidence].each { |f| q<<[f,"#{ns}::#{f}"] }
File.write(b+'/native-queries.tsv',q.map { |x| x.join("\t") }.join("\n")+"\n")
inputs=File.readlines('.cache/tasks/modern-c-frame-contract/cohort/frame-alias-contract-model/native-model-inputs.txt',chomp:true)+[causal,p]
File.write(b+'/native-model-inputs.txt',inputs.uniq.join("\n")+"\n")
File.write(b+'/read-native.sh',File.read('dev/modeling/tools/read-vm-resize-native.sh').sub('r=.cache/tasks/modern-c-frame-contract/cohort/resize-model',"r=#{b}"))
