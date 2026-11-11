# SysML evaluates values; this adapter enumerates declarations and query paths.
require 'fileutils'
b='.cache/tasks/modern-c-frame-contract/cohort/continuation-segments-model';FileUtils.mkdir_p(b)
p='dev/architecture/runtime/control/models/sysml/continuation-segments.sysml';ns='GambitContinuationSegments';q=[]
{'Facet'=>%w[id contract anchors replacement retirement benefit cost refutation],
 'Obligation'=>%w[id semanticKey owner artifact declaration scope limitation],
 'Use'=>%w[facet obligation], 'Handoff'=>%w[producer consumer contract]}.each do |kind,fields|
 group={'Facet'=>'facets','Obligation'=>'obligations','Use'=>'uses','Handoff'=>'edges'}.fetch(kind)
 File.read(p).scan(/part\s+(\w+):#{kind}\s*\{/).flatten.each_with_index do |name,i|
  fields.each do |f|
   suffix=(kind=='Use'||(kind=='Handoff'&&f!='contract')) ? '.id' : ''
   q<<["#{group}.#{i}.#{f}","#{ns}::#{name}.#{f}#{suffix}"]
  end
  q<<["#{group}.#{i}.ownerPath","#{ns}::#{name}.owner.ownerPath"] if kind=='Facet'
 end
end
%w[sourceLock runtimeAdmitted commitAdmitted].each { |f| q<<[f,"#{ns}::#{f}"] }
roles='dev/modeling/models/sysml/verification-responsibilities.sysml'
File.read(roles).scan(/part\s+(\w+):Responsibility\s*\{/).flatten.each_with_index do |name,i|
 %w[id domains owns excludes].each { |f| q<<["responsibilities.#{i}.#{f}","GambitVerificationResponsibilities::#{name}.#{f}"] }
end
File.write(b+'/native-queries.tsv',q.map { |x| x.join("\t") }.join("\n")+"\n")
inputs=File.readlines('evidence/research/modern-c-bootstrap/resize-sysml-inputs.txt',chomp:true)+[p,roles]
File.write(b+'/native-model-inputs.txt',inputs.uniq.join("\n")+"\n")
File.write(b+'/read-native.sh',File.read('dev/modeling/tools/read-vm-resize-native.sh').sub('r=.cache/tasks/modern-c-frame-contract/cohort/resize-model',"r=#{b}"))
