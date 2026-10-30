require 'fileutils'
b=ARGV.fetch(0);raise 'fresh output required' if File.exist?(b);FileUtils.mkdir_p(b)
p='dev/refactoring/modern-c/models/sysml/bootstrap-artifact-custody.sysml';ns='GambitBootstrapArtifactCustody';q=[]
{'Component'=>['components',%w[id source anchor invariant retirement cost]],'Transfer'=>['transfers',%w[origin.id destination.id condition]],'Obligation'=>['obligations',%w[id method criterion]],'Gate'=>['gates',%w[id criterion]]}.each do |kind,(group,fields)|
 File.read(p).scan(/part\s+(\w+):#{kind}\s*\{/).flatten.each_with_index{|n,i|fields.each{|f|q<<["#{group}.#{i}.#{f.tr('.','_')}","#{ns}::#{n}.#{f}"]}}
end
%w[sourceLock profile recipe scope formalBoundary wholeBudget targetPasses].each{|f|q<<[f,"#{ns}::#{f}"]}
File.write(b+'/native-queries.tsv',q.map{|r|r.join("\t")}.join("\n")+"\n")
File.write(b+'/native-model-inputs.txt',p+"\n"+'dev/refactoring/modern-c/models/sysml/ordered-synchronization.sysml'+"\n"+'dev/refactoring/modern-c/models/sysml/mailbox-publication.sysml'+"\n")
File.write(b+'/read-native.sh',File.read('dev/modeling/tools/read-vm-resize-native.sh').sub('r=.cache/tasks/modern-c-frame-contract/cohort/resize-model',"r=#{b}"))
