require 'json'; require 'digest'; require 'fileutils'; require 'open3'
model=ARGV.fetch(0); split=ARGV.fetch(1); verified=ARGV.fetch(2); out=ARGV.fetch(3)
raise 'fresh output required' if File.exist?(out); FileUtils.mkdir_p(out)
sha=->p { Digest::SHA256.file(p).hexdigest }
m=JSON.parse(File.read(model)); r=JSON.parse(File.read(split+'/split.json')); v=JSON.parse(File.read(verified+'/receipt.json'))
raise 'model drift' unless r['modelSha256']==sha.call(model) && v['modelSha256']==sha.call(model)
raise 'verification incomplete' unless v['byteReconstruction'] && v['preprocessEqual'].size==8 && v['objectEqual'].size==1 && v['baselineFailures'].size==3 && v['makeDependencyCases']==26
v['files'].each { |p,h| raise 'current source drift '+p unless sha.call(p)==h }
source=Digest::SHA256.hexdigest(JSON.generate(v['files'].sort.to_h))
parts=m['fragments'].each_with_index.map { |f,i| [i.to_s,i.to_s,f['file'],v['files'].fetch('vendor/gambit/lib/'+f['file'])] }
checks=%w[byte-reconstruction preprocess objects make-and-distribution sysml].map { |id| [id,Digest::SHA256.hexdigest(id+sha.call(verified+'/receipt.json')+sha.call(model))] }
data=->name,cols,rows { '(relation '+name+' ('+cols+') ('+rows.map { |a| '('+a.map { |x| JSON.generate(x.to_s) }.join(' ')+')' }.join(' ')+'))' }
policy='dev/modeling/ascent/memory-organization.rules.scm'; results={}; calls=0
prior=ARGV[4]; limit=Integer(ARGV.fetch(5,'2')); previous=prior && JSON.parse(File.read(prior+'/receipt.json'))
raise 'prior drift' if previous && (previous['modelSha256']!=sha.call(model) || previous['sourceDigest']!=source || previous['policySha256']!=sha.call(policy))
%w[current missing-fragment wrong-order wrong-source unresolved-check].each do |name|
  observed=parts.map(&:dup); observed.pop if name=='missing-fragment'
  observed[0][1]='1' if name=='wrong-order'
  obs=checks.map { |id,h| [id,source,h,'pass'] }
  obs.each { |a| a[1]='stale' } if name=='wrong-source'
  obs<<obs.first[0..2]+['unknown'] if name=='unresolved-check'
  s='(define-evidence (query) (sources clue factor binding) (outputs question moCoveredPart moMissingPart moRejectedPart moCoveredCheck moMissingCheck moRejectedCheck moReady moRuntimeReady) (include clue-selection-schema)'+"\n"+File.read(policy)+"\n(relation question (claim))\n((question C) <-- (moCandidate C))\n)\n"
  {'moIdentity'=>['source',[[source]]],'moPart'=>['id ordinal path digest',parts],
   'moObservedPart'=>['id ordinal path digest',observed],'moRequired'=>['id contract',checks],
   'moObservation'=>['id source contract outcome',obs],'moCandidate'=>['id',[['memory-organization']]]}.each do |rel,(cols,rows)|
    s.sub!('(relation '+rel+' ('+cols+'))',data.call(rel,cols,rows)) || raise('missing relation '+rel)
  end
  request='((displayBytes 65536) (selector '+JSON.generate(s)+'))'
  prior_row=previous && previous['scenarios'][name]
  reuse=prior_row && prior_row['requestSha256']==Digest::SHA256.hexdigest(request+"\n")
  break if !reuse && calls>=limit
  File.write(out+'/'+name+'.request.scm',request+"\n")
  if reuse
    raise 'prior request/result drift' unless sha.call(prior+'/'+name+'.request.scm')==prior_row['requestSha256'] && sha.call(prior+'/'+name+'.result.scm')==prior_row['resultSha256']
    stdout=File.read(prior+'/'+name+'.result.scm'); stderr=File.read(prior+'/'+name+'.stderr'); success=true
  else
    stdout,stderr,status=Open3.capture3('.venv/bin/gambit-smp','--task','modern-c-frame-contract','trajectory','clues',request)
    success=status.success?; calls+=1
  end
  File.write(out+'/'+name+'.result.scm',stdout); File.write(out+'/'+name+'.stderr',stderr)
  raise 'incomplete ASCENT '+name unless success && stdout.include?('("evaluationComplete" #t)')
  ready=stdout.include?('("moReady" (("memory-organization")))')
  raise 'wrong closure '+name unless ready==(name=='current')
  raise 'runtime overclaim' unless stdout.include?('("moRuntimeReady" ())')
  results[name]={synthetic:name!='current',requestSha256:sha.call(out+'/'+name+'.request.scm'),resultSha256:sha.call(out+'/'+name+'.result.scm'),structuralReady:ready,runtimeReady:false}
  File.write(out+'/receipt.json',JSON.pretty_generate({sourceDigest:source,modelSha256:sha.call(model),policySha256:sha.call(policy),verificationReceiptSha256:sha.call(verified+'/receipt.json'),scenarios:results,complete:results.size==5,formalReexecuted:false,commitAdmitted:false})+"\n")
end
puts JSON.generate(controls:results.size,complete:results.size==5,structuralReady:results.key?('current'),runtimeReady:false,formalReexecuted:false)
