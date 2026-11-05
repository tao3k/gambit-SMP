require 'json'; require 'digest'; require 'fileutils'; require 'open3'
b=ARGV.fetch(0); out=ARGV.fetch(1); e='evidence/research/root-worker-exit'
raise 'fresh records required' if File.exist?(e+'/validation.json') || File.exist?(e+'/records')
sha=->p { Digest::SHA256.file(p).hexdigest }
m=JSON.parse(File.read(b+'/native-projection.json')); a=JSON.parse(File.read(out+'/receipt.json'))
raise 'incomplete control set' unless a['complete'] && a['scenarios'].size==6
raise 'policy/projection drift' unless a['policySha256']==sha.call('dev/modeling/ascent/root-worker-exit.rules.scm') && a['projectionSha256']==sha.call(b+'/native-projection.json')
raise 'source lock drift' unless sha.call(a['sourceLock'])==a['sourceLockSha256']
lock=JSON.parse(File.read(a['sourceLock'])); lock['files'].each { |p,h| raise 'source drift '+p unless sha.call(p)==h }
raise 'global promotion' unless a['scenarios'].values.all? { |s| s['relations']['rweRetirementReady'].empty? && s['relations']['smpGateMissing'].size==5 }
raise 'actual closure mismatch' unless a['scenarios']['current']['relations']['rweLocated'].size==9 && a['scenarios']['current']['relations']['rweSupplied'].empty?
raise 'formal/predecessor drift' unless sha.call(a['formalReceipt'])==a['formalReceiptSha256'] && sha.call(a['predecessor'])==a['predecessorSha256']
stdout,stderr,status=Open3.capture3('git','ls-files','--stage','vendor/erlang-otp'); raise stderr unless status.success? && stdout.start_with?('160000 '+m['upstreamCommit']+' ')
paths=File.readlines(b+'/native-model-inputs.txt',chomp:true)+lock['files'].keys
paths+=Dir.glob(b+'/**/*').select { |p| File.file?(p) }
[out,'.cache/tasks/modern-c-frame-contract/cohort/root-worker-exit-calibrated','.cache/tasks/modern-c-frame-contract/cohort/root-worker-exit-controls','.cache/tasks/modern-c-frame-contract/cohort/root-worker-exit-model'].each { |dir| paths+=Dir.glob(dir+'/**/*').select { |p| File.file?(p) } }
paths+=%w[
 .gitmodules
 dev/refactoring/modern-c/root-worker-exit.org
 dev/refactoring/modern-c/index.org
 dev/knowledge/erlang/index.org
 dev/knowledge/index.org
 dev/refactoring/modern-c/diagrams/root-worker-exit.d2
 dev/refactoring/modern-c/diagrams/root-worker-exit.svg
 dev/modeling/ascent/root-worker-exit.rules.scm
 dev/modeling/tools/project-root-worker-exit.rb
 dev/modeling/tools/check-root-worker-exit.rb
 dev/modeling/tools/render-root-worker-exit.rb
 dev/modeling/tools/retain-root-worker-exit.rb
 evidence/fixtures/gerbil-bazel-build-profile/profile.json
 evidence/research/modern-c-bootstrap/request-custody-source.lock.json
 vendor/erlang-otp/LICENSE.txt
 .state/task-runs/modern-c-frame-contract/a44e8e74c1554414a4c4e00646a9d79a.json
]
paths+=[a['sourceLock'],a['predecessor'],a['formalReceipt']]
raise 'missing input '+paths.reject { |p| File.file?(p) }.join(', ') unless paths.all? { |p| File.file?(p) }
FileUtils.mkdir_p(e+'/records')
records=paths.uniq.sort.to_h do |p|
 h=sha.call(p); dst=e+'/records/'+p.gsub('/','__'); FileUtils.cp(p,dst)
 raise 'copy drift' unless sha.call(p)==h && sha.call(dst)==h
 [p,{path:dst,sha256:h}]
end
File.write(e+'/validation.json',JSON.pretty_generate({authority:'GambitRootWorkerExit',
 scope:'Source-located complete root/worker/exit replacement criteria and primary OTP learning; not C refinement, runtime implementation or native acceptance',
 sourceLock:a['sourceLock'],sourceLockSha256:a['sourceLockSha256'],sourceDigest:a['sourceDigest'],profileSha256:a['profileSha256'],
 upstream:lock['upstream'],vendorGitlink:stdout.strip,clauses:9,witnesses:26,sourceLinks:m['uses'].size,dependencies:m['dependencies'].size,learning:4,nativeCases:5,
 scenarios:a['scenarios'],formal:{reexecuted:false,receipt:a['formalReceipt'],sha256:a['formalReceiptSha256'],quintObligations:1,leanObligations:1},
 actualSourceRefinements:0,actualNativeCases:0,retirementAdmitted:false,runtimeSourceChanged:false,nativeTestsRun:false,commitAdmitted:false,
 history:['Full shallow OTP clone timed out at unchanged 60-second limit; interrupted repository preserved in task cohort; explicit workspace resume reconciled custody',
  'Metadata-only partial clone and separate sparse source materialization completed; requested vendor gitlink and .gitmodules staged, no commit',
  'Initial source audit rejected marker interval beyond end of file; rejected model/outputs preserved; corrected native SysML revalidated'],
 records:records})+"\n")
puts JSON.generate(records:records.size,clauses:9,witnesses:26,controls:6,otpCommit:m['upstreamCommit'],formalReexecuted:false,retirementAdmitted:false,commitAdmitted:false)
