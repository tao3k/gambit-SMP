# SysML CLI evaluates the architecture. This adapter only enumerates queries.
require 'fileutils'
r='.cache/tasks/modern-c-frame-contract/cohort/copy-custody-model';FileUtils.mkdir_p(r)
sys='dev/refactoring/modern-c/models/sysml/copy-custody.sysml';ns='GambitCopyCustody';queries=[]
File.read(sys).scan(/part\s+(\w+)\s*:\s*Contract\s*\{/).flatten.each_with_index do |n,i|
 %w[id cSource invariant quint lean open sourceScope quintArtifact leanArtifact nativeMethod nativeArtifact nativeClass nativeScope].each{|a|queries<<["contracts.#{i}.#{a}","#{ns}::#{n}.#{a}"]}
end
File.read(sys).scan(/part\s+(\w+)\s*:\s*Handoff\s*\{/).flatten.each_with_index do |n,i|
 %w[producer consumer].each{|a|queries<<["edges.#{i}.#{a}","#{ns}::#{n}.#{a}.id"]}
 queries<<["edges.#{i}.obligation","#{ns}::#{n}.obligation"]
end
%w[sourceLock runtimeAdmitted commitAdmitted physicalPackingClosed capacityRule].each{|a|queries<<[a,"#{ns}::#{a}"]}
File.read(sys).scan(/part\s+(\w+)\s*:\s*Benefit\s*\{/).flatten.each_with_index do |n,i|
 %w[id eliminated added bound gate].each{|a|queries<<["benefits.#{i}.#{a}","#{ns}::#{n}.#{a}"]}
end
File.write(r+'/native-queries.tsv',queries.map{|x|x.join("\t")}.join("\n")+"\n")
inputs=File.readlines('evidence/research/modern-c-bootstrap/resize-sysml-inputs.txt',chomp:true)+[sys]
File.write(r+'/native-model-inputs.txt',inputs.uniq.join("\n")+"\n")
File.write(r+'/read-native.sh',File.read('dev/modeling/tools/read-vm-resize-native.sh').sub('r=.cache/tasks/modern-c-frame-contract/cohort/resize-model',"r=#{r}"))
