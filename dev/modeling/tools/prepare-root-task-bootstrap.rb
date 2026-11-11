require 'json'; require 'digest'; require 'fileutils'; require 'open3'
e='evidence/research/root-task-c'; FileUtils.mkdir_p(e)
sha=->p { Digest::SHA256.file(p).hexdigest }
base='evidence/research/modern-c-bootstrap/request-custody-source.lock.json'
lock=JSON.parse(File.read(base)); paths=lock['files'].keys
head,err,status=Open3.capture3('git','-C','vendor/gambit','rev-parse','HEAD'); raise err unless status.success? && head.strip==lock['revision']
patch,err,status=Open3.capture3('git','-C','vendor/gambit','diff','--binary','HEAD','--',*paths); raise err unless status.success?
patch_path=e+'/source-overlay.patch'; File.write(patch_path,patch)
lock['patch']=patch_path; lock['patchSha256']=sha.call(patch_path)
lock['scope']='Existing modern-c candidate plus root-task/private-cursor C refinement slice; full carrier retirement and independent scheduling not admitted'
lock['files'].each { |p,r| r['candidateSha256']=sha.call('vendor/gambit/'+p) }
lock_path=e+'/source.lock.json'; File.write(lock_path,JSON.pretty_generate(lock)+"\n")
old_review='evidence/research/modern-c-bootstrap/request-custody-causal-review.json'
review=JSON.parse(File.read(old_review))
review['claims'].each do |c|
 c['references'].each do |r|
  if r['path']==base then r['path']=lock_path; r['sha256']=sha.call(lock_path) end
 end
 c['references']<<{path:'dev/refactoring/modern-c/models/sysml/root-task-c-refinement.sysml',sha256:sha.call('dev/refactoring/modern-c/models/sysml/root-task-c-refinement.sysml')}
 c['reasoning']+=" Current source successor adds explicit frozen root origins, owner-bearing root task CAS, remote-first root dispatch, private worker-arena copy cursors and exact refund/commit checks. GCC kernel/pthread and ASan/UBSan checks pass; current mem/setup syntax passes. The old collective still supplies physical writer stop, phase scheduling, refill and descriptor grace. Do not remove its synchronous guard or infer unknown-writer recovery. Existing Bazel profile, bootstrap and semantic budgets remain unchanged. Old bootstrap budget failures are not relabeled as fixed by these GC mechanisms; run this new source to determine the result."
end
review_path=e+'/causal-review.json'; File.write(review_path,JSON.pretty_generate(review)+"\n")
intent=JSON.parse(File.read('evidence/research/modern-c-bootstrap/request-custody-intent.json'))
intent['failures'].each do |f|
 f['changes'].each { |c| c['after']=sha.call('vendor/gambit/'+c['path']) }
 f['claims'].each { |c| c['evidence']={path:review_path,sha256:sha.call(review_path)} }
end
intent_path=e+'/intent.json'; File.write(intent_path,JSON.pretty_generate(intent)+"\n")
recipe=JSON.parse(File.read('evidence/research/modern-c-bootstrap/request-custody-hosted-bootstrap.recipe.json'))
recipe['id']='modern-c-root-task-bootstrap'; recipe['scope']='Exact current root-task/arena C slice with existing Bazel profile; partial integration, not whole modern SMP admission'
mapping={base=>lock_path,'evidence/research/modern-c-bootstrap/request-custody-source-overlay.patch'=>patch_path,'evidence/research/modern-c-bootstrap/request-custody-intent.json'=>intent_path,'evidence/research/modern-c-bootstrap/request-custody-causal-review.json'=>review_path}
recipe['inputs'].map! { |p| mapping.fetch(p,p) }
recipe['inputs']+=[review_path,'dev/refactoring/modern-c/models/sysml/root-task-c-refinement.sysml']
recipe['inputs'].uniq!
recipe['steps'].each do |s|
 a=s['arguments']; a['sourceLock']=lock_path if a['sourceLock']==base
 a['intent']=intent_path if a['intent']==mapping.keys[2]
end
File.write(e+'/bootstrap.recipe.json',JSON.pretty_generate(recipe)+"\n")
puts JSON.generate(sourceLock:lock_path,files:paths.size,recipe:e+'/bootstrap.recipe.json',budgetSeconds:recipe['budgetSeconds'],profileUnchanged:true,commitAdmitted:false)
