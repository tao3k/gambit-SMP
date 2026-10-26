require 'fileutils'
b=ARGV.fetch(0); raise 'fresh projection required' if File.exist?(b); FileUtils.mkdir_p(b)
p='dev/refactoring/modern-c/models/sysml/memory-organization.sysml'
ns='GambitMemoryOrganization'; q=[]
File.read(p).scan(/part\s+(\w+):Fragment\s*\{/).flatten.each_with_index do |name,i|
  %w[file firstLine responsibility].each { |f| q<<["fragments.#{i}.#{f}","#{ns}::#{name}.#{f}"] }
end
%w[source baselineSha256 preambleLines fragmentSuffix scope formalOwner].each { |f| q<<[f,"#{ns}::#{f}"] }
File.write(b+'/native-queries.tsv',q.map { |x| x.join("\t") }.join("\n")+"\n")
File.write(b+'/native-model-inputs.txt',p+"\n")
File.write(b+'/read-native.sh',File.read('dev/modeling/tools/read-vm-resize-native.sh').sub('r=.cache/tasks/modern-c-frame-contract/cohort/resize-model',"r=#{b}"))
