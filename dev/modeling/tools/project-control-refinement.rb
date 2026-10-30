# Enumerate query paths only. The native SysML tool resolves all values/refs.
require 'fileutils'
b=ARGV.fetch(0);raise 'fresh projection required' if File.exist?(b);FileUtils.mkdir_p(b)
p='dev/architecture/runtime/control/models/sysml/control-refinement.sysml'
ns='GambitControlRefinement';q=[]
{
 'Route'=>['routes',%w[id method claim sourceClosure gap cut obligation.id obligation.owner]],
 'Witness'=>['witnesses',%w[id file firstLine lastLine finding route.id]],
 'NativeCase'=>['cases',%w[id target observation baseline missing obligation.id]],
 'Gate'=>['gates',%w[id criterion]]
}.each do |kind,(group,fields)|
 File.read(p).scan(/part\s+(\w+):#{kind}\s*\{/).flatten.each_with_index do |name,i|
  fields.each { |f| q<<["#{group}.#{i}.#{f.split('.').join('_')}","#{ns}::#{name}.#{f}"] }
 end
end
%w[target predecessor profile].each { |f| q<<[f,"#{ns}::#{f}"] }
File.write(b+'/native-queries.tsv',q.map { |x| x.join("\t") }.join("\n")+"\n")
inputs=File.readlines('.cache/tasks/modern-c-frame-contract/cohort/continuation-segments-model/native-model-inputs.txt',chomp:true)+[p]
File.write(b+'/native-model-inputs.txt',inputs.uniq.join("\n")+"\n")
File.write(b+'/read-native.sh',File.read('dev/modeling/tools/read-vm-resize-native.sh').sub('r=.cache/tasks/modern-c-frame-contract/cohort/resize-model',"r=#{b}"))
