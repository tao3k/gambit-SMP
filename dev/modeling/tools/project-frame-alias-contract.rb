require 'fileutils'
b=ARGV.fetch(0);raise 'fresh projection required' if File.exist?(b);FileUtils.mkdir_p(b)
p='dev/architecture/runtime/control/models/sysml/frame-alias-contract.sysml';ns='GambitFrameAliasContract';q=[]
{
 'AdapterClause'=>['clauses',%w[id operation premise realization failure sourceGap obligation.id obligation.owner]],
 'SmpCriterion'=>['criteria',%w[id necessary observation limitation acceptance.id acceptance.obligation.id]],
 'Benefit'=>['benefits',%w[id avoided added condition]],
 'Witness'=>['witnesses',%w[id file firstLine lastLine finding]],
 'EvidenceUse'=>['uses',%w[clause.id witness.id]],
 'CriterionUse'=>['criterionUses',%w[criterion.id witness.id]]
}.each do |kind,(group,fields)|
 File.read(p).scan(/part\s+(\w+):#{kind}\s*\{/).flatten.each_with_index do |name,i|
  fields.each { |f| q<<["#{group}.#{i}.#{f.split('.').join('_')}","#{ns}::#{name}.#{f}"] }
 end
end
%w[predecessor profile].each { |f| q<<[f,"#{ns}::#{f}"] }
File.write(b+'/native-queries.tsv',q.map { |x| x.join("\t") }.join("\n")+"\n")
inputs=File.readlines('.cache/tasks/modern-c-frame-contract/cohort/control-refinement-qualified/native-model-inputs.txt',chomp:true)+[p]
File.write(b+'/native-model-inputs.txt',inputs.uniq.join("\n")+"\n")
File.write(b+'/read-native.sh',File.read('dev/modeling/tools/read-vm-resize-native.sh').sub('r=.cache/tasks/modern-c-frame-contract/cohort/resize-model',"r=#{b}"))
