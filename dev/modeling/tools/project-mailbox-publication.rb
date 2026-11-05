require 'fileutils'
b=ARGV.fetch(0); raise 'fresh output required' if File.exist?(b); FileUtils.mkdir_p(b)
p='dev/refactoring/modern-c/models/sysml/mailbox-publication.sysml'; ns='GambitMailboxPublication'; q=[]
{'FormalBoundary'=>['formalBoundaries',%w[id owner artifact declaration scope]],'Responsibility'=>['responsibilities',%w[id source anchor invariant retires added]],'Obligation'=>['obligations',%w[id method program criterion]],'Transfer'=>['transfers',%w[origin.id destination.id condition]]}.each do |kind,(group,fields)|
 File.read(p).scan(/part\s+(\w+):#{kind}\s*\{/).flatten.each_with_index{|n,i|fields.each{|f|q<<["#{group}.#{i}.#{f.tr('.','_')}","#{ns}::#{n}.#{f}"]}}
end
%w[sourceLock profile purpose formalOwnership historicalBoundary budgets commitAllowed].each{|f|q<<[f,"#{ns}::#{f}"]}
File.write(b+'/native-queries.tsv',q.map{|x|x.join("\t")}.join("\n")+"\n")
File.write(b+'/native-model-inputs.txt',p+"\n")
File.write(b+'/read-native.sh',File.read('dev/modeling/tools/read-vm-resize-native.sh').sub('r=.cache/tasks/modern-c-frame-contract/cohort/resize-model',"r=#{b}"))
