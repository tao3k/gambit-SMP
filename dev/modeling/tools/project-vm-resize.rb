require 'json';require 'fileutils'
r='.cache/tasks/modern-c-frame-contract/cohort/resize-model';FileUtils.mkdir_p(r)
p='dev/refactoring/modern-c/models/sysml/vm-resize-transaction.sysml';s=File.read(p);ns='GambitVMResizeTransaction';qs=[]
{contracts:['Contract',%w[id source invariant retired cost]],proofs:['Obligation',%w[id method artifact premise]],edges:['Edge',[]]}.each do |key,(type,attrs)|
 s.scan(/part\s+(\w+)\s*:\s*#{type}\s*\{/).flatten.each_with_index do |name,i|
  attrs.each{|a|qs<<["#{key}.#{i}.#{a}","#{ns}::#{name}.#{a}"]}
  qs<<["#{key}.#{i}.component","#{ns}::#{name}.component.id"] if key==:proofs
  {'from'=>'producer','to'=>'consumer'}.each{|a,b|qs<<["#{key}.#{i}.#{a}","#{ns}::#{name}.#{b}.id"]} if key==:edges
 end
end
qs<<['runtimeAdmitted',ns+'::runtimeAdmitted']
rp='dev/refactoring/modern-c/models/sysml/vm-resume-reservation.sysml'
%w[id source invariant retirement cost open quint lean native runtimeAdmitted].each{|a|qs<<['resume.'+a,'GambitVMResumeReservation::'+a]}
fp='dev/refactoring/modern-c/models/sysml/vm-resize-refinement.sysml'
File.read(fp).scan(/part\s+(\w+)\s*:\s*Step\s*\{/).flatten.each_with_index do |name,i|
 %w[quintAction cFunction representation guard leanLaw unresolved].each{|a|qs<<["refinements.#{i}.#{a}","GambitVMResizeRefinement::#{name}.#{a}"]}
 qs<<["refinements.#{i}.component","GambitVMResizeRefinement::#{name}.component.id"]
end
pq='dev/refactoring/modern-c/models/sysml/vm-resize-qualification.sysml'
File.read(pq).scan(/part\s+(\w+)\s*:\s*Need\s*\{/).flatten.each_with_index do |name,i|
 %w[id method artifact scope evidenceClass check].each{|a|qs<<["needs.#{i}.#{a}","GambitVMResizeQualification::#{name}.#{a}"]}
 qs<<["needs.#{i}.component","GambitVMResizeQualification::#{name}.component.id"]
end
File.read(pq).scan(/part\s+(\w+)\s*:\s*Benefit\s*\{/).flatten.each_with_index do |name,i|
 %w[id eliminated added bound gate].each{|a|qs<<["benefits.#{i}.#{a}","GambitVMResizeQualification::#{name}.#{a}"]}
end
File.read(pq).scan(/part\s+(\w+)\s*:\s*Question\s*\{/).flatten.each_with_index do |name,i|
 %w[id source condition counterexample].each{|a|qs<<["questions.#{i}.#{a}","GambitVMResizeQualification::#{name}.#{a}"]}
end
%w[sourceLock profile].each{|a|qs<<["identity.#{a}","GambitVMResizeQualification::#{a}"]}
File.write(r+'/native-queries.tsv',qs.map{|x|x.join("\t")}.join("\n")+"\n")
inputs=File.readlines('evidence/research/modern-c-bootstrap/resize-sysml-inputs.txt',chomp:true)+[p,rp,fp,pq]
File.write(r+'/native-model-inputs.txt',inputs.uniq.join("\n")+"\n")
File.write(r+'/read-native.sh',File.read('dev/modeling/tools/read-vm-resize-native.sh').sub('r=.cache/tasks/modern-c-frame-contract/cohort/model',"r=#{r}"))
