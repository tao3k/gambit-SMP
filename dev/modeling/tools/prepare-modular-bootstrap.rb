require 'json'; require 'digest'; require 'fileutils'; require 'open3'
e=ARGV.fetch(0,'evidence/research/modular-smp-bootstrap'); raise 'fresh declaration required' if File.exist?(e); FileUtils.mkdir_p(e)
sha=->p { Digest::SHA256.file(p).hexdigest }
base='evidence/research/modern-c-bootstrap/request-custody-source.lock.json'
lock=JSON.parse(File.read(base)); paths=(lock['files'].keys+['lib/makefile.in','tests/gc-root-task.c']+Dir.glob('vendor/gambit/lib/_mem/*.inc').map { |p| p.sub('vendor/gambit/','') }).uniq.sort
run=->*a { s,err,status=Open3.capture3(*a); raise err unless status.success?; s }
raise 'head drift' unless run.call('git','-C','vendor/gambit','rev-parse','HEAD').strip==lock['revision']
patch=e+'/source-overlay.patch'; File.write(patch,run.call('git','-C','vendor/gambit','diff','--binary','HEAD','--',*paths))
lock['files']=paths.to_h do |p|
 entry=run.call('git','-C','vendor/gambit','ls-tree','HEAD','--',p)
 [p,{baseSha256:entry.empty? ? nil : Digest::SHA256.hexdigest(run.call('git','-C','vendor/gambit','show','HEAD:'+p)), candidateSha256:sha.call('vendor/gambit/'+p)}]
end
lock['patch']=patch; lock['patchSha256']=sha.call(patch)
lock['scope']='Current modern-C candidate, complete 25-fragment memory organization and root-task kernel; source provenance only'
lockpath=e+'/source.lock.json'; File.write(lockpath,JSON.pretty_generate(lock)+"\n")
review=JSON.parse(File.read('evidence/research/root-task-c/causal-review.json'))
review['claims'].each do |c|
 c['references'].each { |r| if r['path']=='evidence/research/root-task-c/source.lock.json'; r['path']=lockpath; r['sha256']=sha.call(lockpath); end }
 %w[dev/refactoring/modern-c/models/sysml/memory-organization.sysml evidence/research/memory-organization/validation.json].each { |p| c['references']<<{path:p,sha256:sha.call(p)} }
 c['reasoning']+=' The complete mem source partition has exact reconstruction, eight preprocessing controls and release object equality. Every fragment is now an explicit locked source, absent from the base revision, with source-delta create/remove custody. These facts establish source inclusion and structural equivalence only. They do not solve the historical budget failure or establish full root/worker retirement. The unchanged Bazel configure/profile and original stage/semantic watchdogs must observe this current candidate.'
end
reviewpath=e+'/causal-review.json'; File.write(reviewpath,JSON.pretty_generate(review)+"\n")
intent=JSON.parse(File.read('evidence/research/root-task-c/intent.json'))
intent['failures'].each do |f|
 f['changes'].each { |c| c['after']=sha.call('vendor/gambit/'+c['path']) }
 f['claims'].each { |c| c['evidence']={path:reviewpath,sha256:sha.call(reviewpath)} }
end
intentpath=e+'/intent.json'; File.write(intentpath,JSON.pretty_generate(intent)+"\n")
recipe=JSON.parse(File.read('evidence/research/modern-c-bootstrap/request-custody-hosted-bootstrap.recipe.json'))
recipe['scope']='Complete modular memory source, current root-task/private-arena candidate, unchanged Bazel profile; full native acceptance still required'
oldintent='evidence/research/modern-c-bootstrap/request-custody-intent.json'
oldreview='evidence/research/modern-c-bootstrap/request-custody-causal-review.json'
map={base=>lockpath,'evidence/research/modern-c-bootstrap/request-custody-source-overlay.patch'=>patch,oldintent=>intentpath,oldreview=>reviewpath}
recipe['inputs'].map! { |p| map.fetch(p,p) }
recipe['inputs']+=[reviewpath,'dev/refactoring/modern-c/models/sysml/memory-organization.sysml','evidence/research/memory-organization/validation.json']; recipe['inputs'].uniq!
recipe['steps'].each { |s| a=s['arguments']; a['sourceLock']=lockpath if a['sourceLock']==base; a['intent']=intentpath if a['intent']==oldintent }
File.write(e+'/bootstrap.recipe.json',JSON.pretty_generate(recipe)+"\n")
puts JSON.generate(files:paths.size,newFiles:lock['files'].count { |p,r| r[:baseSha256].nil? },profileUnchanged:true,budgetSeconds:recipe['budgetSeconds'],recipe:e+'/bootstrap.recipe.json')
