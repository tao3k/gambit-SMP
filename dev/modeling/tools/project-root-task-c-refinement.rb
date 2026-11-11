require 'fileutils'
b=ARGV.fetch(0); raise 'fresh projection required' if File.exist?(b); FileUtils.mkdir_p(b)
p='dev/refactoring/modern-c/models/sysml/root-task-c-refinement.sysml'; ns='GambitRootTaskCRefinement'; q=[]
{'Operation'=>['operations',%w[id symbol guard linearization custody gap parent.id]],'NativeCase'=>['cases',%w[id purpose]]}.each do |kind,(group,fields)|
 File.read(p).scan(/part\s+(\w+):#{kind}\s*\{/).flatten.each_with_index do |name,i|
  fields.each { |f| q<<["#{group}.#{i}.#{f.tr('.','_')}","#{ns}::#{name}.#{f}"] }
 end
end
%w[upstreamCommit header consumer setup test scope].each { |f| q<<[f,"#{ns}::#{f}"] }
File.write(b+'/native-queries.tsv',q.map { |x| x.join("\t") }.join("\n")+"\n")
inputs=File.readlines('.cache/tasks/modern-c-frame-contract/cohort/root-worker-exit-qualified/native-model-inputs.txt',chomp:true)+[p]
File.write(b+'/native-model-inputs.txt',inputs.uniq.join("\n")+"\n")
File.write(b+'/read-native.sh',File.read('dev/modeling/tools/read-vm-resize-native.sh').sub('r=.cache/tasks/modern-c-frame-contract/cohort/resize-model',"r=#{b}"))
