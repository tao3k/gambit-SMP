require 'json';require 'digest';require 'fileutils'
b=ARGV.fetch(0);out=ARGV.fetch(1);e='evidence/research/control-refinement'
raise 'fresh archive required' if File.exist?(e)
sha=->p { Digest::SHA256.file(p).hexdigest }
m=JSON.parse(File.read(b+'/native-projection.json'));a=JSON.parse(File.read(out+'/receipt.json'))
raise 'SysML drift' unless sha.call(b+'/native-projection.json')==a['sysmlProjectionSha256']
raise 'incomplete controls' unless a['scenarios'].size==9
current=a['scenarios']['current']['relations']
raise 'incorrect current closure' unless current['controlMapped'].size==6&&current['controlSourceClosed'].empty?&&current['controlOpen'].size==12&&current['controlCaseMissing'].size==7&&current['controlCommitCandidate'].empty?
a['policies'].each { |p,h| raise 'policy drift' unless sha.call(p)==h }
raise 'formal receipt drift' unless sha.call(a['formalReceipt'])==a['formalReceiptSha256']
formal=JSON.parse(File.read(a['formalReceipt']))
formal['artifacts'].each { |p,h| raise 'formal input changed' unless sha.call(p)==h }
audit=JSON.parse(File.read(out+'/source-witnesses.json'))
audit['files'].each { |p,h| raise 'source changed' unless sha.call(p)==h }
audit['witnesses'].each { |w| raise 'excerpt changed' unless sha.call(w['excerpt'])==w['excerptSha256'] }
thread=File.readlines('vendor/gambit/lib/_thread.scm')
smp=thread[4915...4991].join;nonSmp=thread[8425...8501].join
duplicate={sameBytes:smp==nonSmp,linesPerBody:76,smpLines:[4916,4991],nonSmpLines:[8426,8501],
 sha256:Digest::SHA256.hexdigest(smp),scope:'Literal source duplication; branch-binding equivalence and native behavior remain open'}
paths=File.readlines(b+'/native-model-inputs.txt',chomp:true)+audit['files'].keys
paths+=Dir.glob(b+'/*').select { |p| File.file?(p) }
paths+=Dir.glob(out+'/**/*').select { |p| File.file?(p) }
%w[control-refinement-model control-refinement-native control-refinement-resolved control-refinement-admission control-refinement-closure control-refinement-remaining].each do |name|
 paths+=Dir.glob('.cache/tasks/modern-c-frame-contract/cohort/'+name+'/**/*').select { |p| File.file?(p) }
end
paths+=formal['artifacts'].keys+[a['formalReceipt'],m['predecessor'],m['profile']]
paths+=formal['rows'].map { |r| File.dirname(a['formalReceipt'])+'/'+r['id']+'.log' }
paths+=%w[
 dev/architecture/runtime/control/control-refinement.org
 dev/architecture/runtime/control/continuation-segments.org
 dev/architecture/runtime/control/index.org
 dev/refactoring/modern-c/index.org
 dev/modeling/index.org
 dev/architecture/runtime/control/diagrams/control-refinement.d2
 dev/architecture/runtime/control/diagrams/control-refinement.svg
 dev/modeling/ascent/obligation-ownership.rules.scm
 dev/modeling/ascent/control-refinement.rules.scm
 dev/modeling/tools/project-control-refinement.rb
 dev/modeling/tools/render-control-refinement.rb
 dev/modeling/tools/check-control-refinement.rb
 dev/modeling/tools/retain-control-refinement.rb
 evidence/research/modern-c-bootstrap/request-custody-source.lock.json
]
raise 'missing archive input' unless paths.all? { |p| File.file?(p) }
FileUtils.mkdir_p(e+'/records')
records=paths.uniq.sort.to_h do |p|
 h=sha.call(p);target=e+'/records/'+p.gsub('/','__');FileUtils.cp(p,target)
 raise 'copy drift' unless h==sha.call(p)&&h==sha.call(target)
 [p,{path:target,sha256:h}]
end
File.write(e+'/validation.json',JSON.pretty_generate({
 scope:'Six existing obligations traced to actual source; source mapping is not source refinement or native execution',
 authority:'GambitControlRefinement',target:m['target'],sourceWitnesses:audit['witnesses'].size,sourceFiles:audit['files'].size,
 auditSourceDigest:a['sourceDigest'],auditSourceScope:'Selected witness files plus existing 18-file candidate lock; not complete generated/build/link closure',
 profileSha256:a['profileSha256'],routes:m['routes'].map { |r| {obligation:r['obligation_id'],owner:r['obligation_owner'],sourceMapped:true,closed:false} },
 formal:{reexecuted:false,receipt:a['formalReceipt'],sha256:a['formalReceiptSha256'],quintObligations:1,leanObligations:1},
 nativeCases:{fullControl:7,promptExtension:1,newlyExecuted:0},literalDuplication:duplicate,current:current,scenarios:a['scenarios'],
 history:['Native SysML rejected reserved first/requirement identifiers; failed input and diagnostics retained',
 'Declaration rename initially missed specialization names; failed input and diagnostics retained',
 'Source witness audit rejected an interval beyond setup.c EOF; failed checker/partial excerpts and native input preserved; endpoint corrected to actual EOF',
 'Combined SysML/ASCENT stage reached its 120-second supervisor deadline after five completed controls; exact request/result hashes reused in bounded continuation stages; timeout retained',
 'Corrected native projection resolves the original obligation references; no QNT/Lean changes'],
 runtimeSourceChanged:false,nativeTestsRun:false,runtimeAdmitted:false,commitAdmitted:false,records:records
})+"\n")
puts JSON.generate(records:records.size,witnesses:audit['witnesses'].size,sourceFiles:audit['files'].size,sourceMapped:6,remaining:6,scenarios:9,formalReexecuted:false,commitAdmitted:false)
