require 'fileutils'
b=ARGV.fetch(0);FileUtils.mkdir_p(b)
p='dev/refactoring/modern-c/models/sysml/header-organization.sysml';ns='GambitHeaderOrganization';q=[]
File.read(p).scan(/part\s+(\w+):Fragment\s*\{/).flatten.each_with_index{|n,i|%w[file firstLine pastLine driverInline].each{|f|q<<["fragments.#{i}.#{f}","#{ns}::#{n}.#{f}"]}}
%w[source baselineSha256 publication].each{|f|q<<[f,"#{ns}::#{f}"]}
File.write(b+'/native-queries.tsv',q.map{|r|r.join("\t")}.join("\n")+"\n")
File.write(b+'/native-model-inputs.txt',p+"\n")
File.write(b+'/read-native.sh',File.read('dev/modeling/tools/read-vm-resize-native.sh').sub('r=.cache/tasks/modern-c-frame-contract/cohort/resize-model',"r=#{b}"))
