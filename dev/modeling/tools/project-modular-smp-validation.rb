require 'fileutils'
b=ARGV.fetch(0); raise 'fresh output required' if File.exist?(b); FileUtils.mkdir_p(b)
p='dev/refactoring/modern-c/models/sysml/modular-smp-validation.sysml'; ns='GambitModularSmpValidation'; q=[]
File.read(p).scan(/part\s+(\w+):Lane\s*\{/).flatten.each_with_index { |n,i| %w[id namespace name kind program stdout topology budget].each { |f| q<<["lanes.#{i}.#{f}","#{ns}::#{n}.#{f}"] } }
{'SharedContract'=>['contracts',%w[id source anchor invariant open]], 'Coverage'=>['coverage',%w[lane.id contract.id scope]], 'ToolDependency'=>['tools',%w[id variable command]]}.each do |kind,(group,fields)|
 File.read(p).scan(/part\s+(\w+):#{kind}\s*\{/).flatten.each_with_index { |n,i| fields.each { |f| q<<["#{group}.#{i}.#{f.tr('.','_')}","#{ns}::#{n}.#{f}"] } }
end
%w[sourceLock profile runner hashToolVariable hashToolContract workflow ownership proofOwnership bootstrapContract failureCustody].each { |f| q<<[f,"#{ns}::#{f}"] }
File.write(b+'/native-queries.tsv',q.map { |x| x.join("\t") }.join("\n")+"\n")
File.write(b+'/native-model-inputs.txt',p+"\n"+'dev/refactoring/modern-c/models/sysml/mailbox-publication.sysml'+"\n"+'dev/refactoring/modern-c/models/sysml/ordered-synchronization.sysml'+"\n")
File.write(b+'/read-native.sh',File.read('dev/modeling/tools/read-vm-resize-native.sh').sub('r=.cache/tasks/modern-c-frame-contract/cohort/resize-model',"r=#{b}"))
