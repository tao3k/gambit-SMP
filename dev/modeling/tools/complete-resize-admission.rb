# Complete the catalogue-bound negative control by lowering static ground facts
# to native relation data. No framework bound, inference rule or tuple changes.
require 'json';require 'digest';require 'open3'
e='evidence/research/modern-c-bootstrap';path=e+'/request-custody-admission.json';j=JSON.parse(File.read(path));raise 'eight prior scenarios required' unless j['scenarios'].size==8
history=e+'/request-custody-history/'+j.fetch('claim').split(':').last;old=history+'/all-scopes-with-failure.request.scm';raw=File.read(old);encoded=raw[/\(selector ("(?:\\.|[^"\\])*")\)/m,1];raise 'selector carrier' unless encoded
body=JSON.parse(encoded);rows=body.lines.select{|l|l.start_with?('(copyObservedFact ')};raise '44 exact observation tuples required' unless rows.size==44
kept=body.lines.reject{|l|l.start_with?('(copyObservedFact ')}.join
oldDecl='(relation copyObservedFact (scenario source profile component method artifact digest scope class evidence status))'
data=rows.map{|l|l.sub('(copyObservedFact ','(')}.join
newDecl='(relation copyObservedFact (scenario source profile component method artifact digest scope class evidence status) ('+"\n"+data+'))'
raise 'unique observation declaration' unless kept.scan(oldDecl).size==1
lowered=kept.sub(oldDecl,newDecl)
# Reconstructing the original body must recover every byte. Thus all inference
# rules, bindings, tokens and the multiset of ground observations are unchanged.
raise 'lowering changed unrelated bytes' unless lowered.sub(newDecl,oldDecl)==kept
request=raw.sub(encoded,JSON.generate(lowered));q=history+'/all-scopes-data.request.scm';result=history+'/all-scopes-data.result.scm';File.write(q,request)
o,err,status=Open3.capture3('.venv/bin/gambit-smp','--task','modern-c-frame-contract','trajectory','clues',request);File.write(result,o);File.write(history+'/all-scopes-data.stderr',err)
raise 'lowered control evaluation' unless status.success?&&o.include?('("evaluationComplete" #t)')&&o.include?('("copyAllReady" ())')
section=o[/\("copyChecked" (.*?) \("copyDependencyGap"/m,1];raise 'checked output' unless section
raise 'exact scoped joins' unless section.scan(/\("all-scopes-with-failure" "[^"]+" "[^"]+"\)/).size==44
sha=->p{Digest::SHA256.file(p).hexdigest};lowering={originalRequest:old,originalRequestSha256:sha.call(old),actualRequest:q,actualRequestSha256:sha.call(q),actualResult:result,actualResultSha256:sha.call(result),groundTupleCount:44,inferenceRulesChanged:false,boundsIncreased:false,adapterSha256:sha.call(__FILE__),scope:'static ground observation facts converted to native relation data; synthetic proof/native rows remain vetoed by actual aggregate timeout'}
j['scenarios']['all-scopes-with-failure']={checked:44,allReady:false,requestSha256:sha.call(q),resultSha256:sha.call(result),groundDataLowering:lowering};j['toolingHistory']={aggregateScriptTimeoutRetained:true,catalogueBoundFailureRetained:true,groundDataLowering:lowering};File.write(path,JSON.pretty_generate(j)+"\n");puts JSON.generate(scenarios:9,anchorControls:2,allReady:false,groundTuples:44,boundsIncreased:false)
