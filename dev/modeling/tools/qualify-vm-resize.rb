require 'json';require 'digest';require 'open3';require 'fileutils'
b='.cache/tasks/modern-c-frame-contract/cohort';e='evidence/research/modern-c-bootstrap';sha=->p{Digest::SHA256.file(p).hexdigest};q=->x{JSON.generate(x)}
fact=->name,*xs{"(fact (#{name} #{xs.map{|x|q.call(x)}.join(' ')}))\n"}
m=JSON.parse(File.read(b+'/resize-model/native-projection.json'));lock_path=m['identity']['sourceLock'];profile=m['identity']['profile'];lock=JSON.parse(File.read(lock_path))
lock['files'].each{|p,h|raise 'current source drift: '+p unless sha.call('vendor/gambit/'+p)==h['candidateSha256']}
identity=[sha.call(lock_path),sha.call(profile)];rules='dev/modeling/ascent/vm-resize-qualification.rules.scm'
inputs=File.readlines(b+'/resize-model/native-model-inputs.txt',chomp:true)
bindings={'target-model-bundle-sha256'=>Digest::SHA256.hexdigest(inputs.sort.map{|p|p+"\0"+sha.call(p)}.join("\n")),'native-output-sha256'=>sha.call(b+'/resize-model/native-metadata.json'),'planner-dsl-sha256'=>sha.call(rules)}
formal={scope:'finite and conditional proof only; no C simulation or native admission',sourceLockSha256:identity[0],quintSha256:sha.call(m['needs'].find{|n|n['id']=='VQ-TRANSITION'}['artifact']),leanSha256:sha.call(m['needs'].find{|n|n['id']=='VQ-ARITHMETIC'}['artifact']),receipts:{},runtimeAdmitted:false,commitAdmitted:false}
%w[ownership-qnt-typecheck.log ownership-qnt-tests.log ownership-qnt-run.log ownership-lean.log ownership-lean-axioms.log].each{|p|formal[:receipts][p]=sha.call(b+'/'+p)}
raise 'QNT histories' unless File.read(b+'/ownership-qnt-tests.log').include?('4 passing')
raise 'QNT safety' unless File.read(b+'/ownership-qnt-run.log').include?('No violation found')
audit=File.read(b+'/ownership-lean-axioms.log');raise 'axiom audit' unless audit.scan(/Gambit.VMResizeTransaction\./).size==12&&!audit.include?('sorryAx')&&!audit.include?('error:')
negative=JSON.parse(File.read(b+'/resize-negative.json'));raise 'negative controls' unless negative.size==5&&negative.all?{|x|x['exit']==1}
negative.each{|x|raise 'missing actual violation' unless File.read(b+'/resize-negative-'+x['step']+'.log').include?('[violation]')}
formal[:negativeControls]=negative.map{|x|{step:x['step'],exit:x['exit'],argv:x['argv']}}
formal_path=e+'/resize-ownership-formal.json';File.write(formal_path,JSON.pretty_generate(formal)+"\n")
policy=e+'/resize-qualification-policy-control.json';File.write(policy,JSON.pretty_generate({scope:'synthetic conjunction controls only; never native evidence',runtimeAdmitted:false,commitAdmitted:false})+"\n")
claim='modern-c-resize-qualification:'+Digest::SHA256.hexdigest(JSON.generate([bindings,identity,sha.call(formal_path)]))
history=e+'/resize-qualification-history/'+claim.split(':').last;FileUtils.mkdir_p(history)
reg="(define-evidence (register) (sources binding) (outputs clue factor) (relation binding (name value)) (relation clue (id claim polarity source)) (relation factor (id name value))\n"+fact.call('clue',claim,claim,'support','dev/refactoring/modern-c/models/sysml/vm-resize-qualification.sysml')
bindings.each{|k,v|reg<<fact.call('factor',claim,k,v)};reg<<")\n"
request="((selector #{q.call(reg)}) (constructor \"register\"))\n"
o,err,s=Open3.capture3('.venv/bin/gambit-smp','--task','modern-c-frame-contract','trajectory','submit',request);File.write(b+'/resize-qualification-submit.log',o+err);raise 'register' unless s.success?||err.include?('already retained')
base="(define-evidence (query) (sources clue factor binding) (outputs question resizeRequired resizeChecked resizeMissing resizeFailed resizeRouteMissing resizeDepends resizeDependencyGap resizeComponentReady resizeAllReady resizeQuestion) (include clue-selection-schema)\n"+File.read(rules)
base<<fact.call('resizeStudyFact',claim)<<fact.call('resizeSourceFact',*identity)
m['needs'].each{|n|base<<fact.call('resizeNeedFact',*%w[component id method artifact].map{|k|n[k]},sha.call(n['artifact']),n['scope'],n['evidenceClass'],n['check'])}
m['edges'].each{|x|base<<fact.call('resizeDependencyFact',x['to'],x['from'])}
m['questions'].each{|x|base<<fact.call('resizeQuestionFact',*%w[id source condition counterexample].map{|k|x[k]})}
tokens={};m['refinements'].each_with_index do |x,i|
 {'quintAction'=>'quint-action','leanLaw'=>'lean-law','cFunction'=>'c-token'}.each do |field,kind|
  x[field].split(';').map(&:strip).each{|t|base<<fact.call('resizeRouteFact',i.to_s,t,kind);tokens[[t,kind]]=true}
 end
end
qnt=File.read('dev/refactoring/modern-c/models/quint/vm_resize_transaction.qnt');lean=File.read('dev/refactoring/modern-c/models/lean/VMResizeTransaction.lean');c=%w[setup mem os_thread c_intf].map{|u|File.read('vendor/gambit/lib/'+u+'.c')}.join("\n")
tokens.keys.each do |t,kind|
 present=case kind;when 'quint-action';qnt.match?(/\baction\s+#{Regexp.escape(t)}\b/);when 'lean-law';lean.match?(/\btheorem\s+#{Regexp.escape(t)}\b/);else;c.match?(/\b#{Regexp.escape(t)}\b/);end
 raise "missing structural route #{t}" unless present
end
observed={'VQ-TRANSITION'=>[formal_path,'finite-model'],'VQ-ARITHMETIC'=>[formal_path,'conditional-proof']}
boot='.cache/tasks/modern-c-frame-contract/runs/bazel-resize-ownership-current/run/bootstrap/step-receipt.json'
if File.exist?(boot)
 j=JSON.parse(File.read(boot));observed['VQ-BOOTSTRAP']=[boot,'native-bootstrap'] if j['outcome']=='PASS'&&j['fullTwoPassBootstrapEstablished']&&j['phaseCounts'].values.all?{|x|x==2}
end
control=b+'/resize-ownership-controls/receipt.json'
if File.exist?(control)
 j=JSON.parse(File.read(control));raise 'control source mismatch' unless j['sourceLockSha256']==identity[0] && j['fixtureSha256']==sha.call('evidence/research/modern-c-bootstrap/resize-fixture.scm') && j['adapterSha256']==sha.call('evidence/research/modern-c-bootstrap/resize-faults.c') && j['calibrationSourceSha256']==sha.call('evidence/research/modern-c-bootstrap/resize-fault-calibration.c')
 observed['VQ-BODY']=[control,'native-caller'] if j['rows'].any?{|r|r['id']=='none'&&r['oracleMatched']}
 observed['VQ-FAULT']=[control,'native-fault-control'] if j['adapterCalibrated']&&%w[allocation create unknown].all?{|id|j['rows'].any?{|r|r['id']==id&&r['oracleMatched']}}
end
policy_check=e+'/resize-qualification-policy.json'
if File.exist?(policy_check)
 pc=JSON.parse(File.read(policy_check))
 if pc['rulesSha256']==sha.call(rules)&&pc['modelBundleSha256']==bindings['target-model-bundle-sha256']&&pc['controls']==7&&pc['passed']==true
  observed['VQ-ROUTING']=[policy_check,'policy-control']
 end
end
FileUtils.mkdir_p(e+'/resize-qualification-requests');FileUtils.mkdir_p(e+'/resize-qualification-results');results={}
%w[current stale-source wrong-artifact forged-diagnostic missing-law failed-native synthetic-complete].each do |scenario|
 part=base.dup;ids=identity.dup;ids[0]='0'*64 if scenario=='stale-source';mode=%w[failed-native synthetic-complete].include?(scenario) ? 'policy-control' : 'actual'
 part<<fact.call('resizeCandidateFact',scenario,*ids)<<fact.call('resizeScenarioClassFact',scenario,mode)
 tokens.keys.each{|t,k|part<<fact.call('resizeTokenFact',t,k) unless scenario=='missing-law'&&t=='grantFloor'}
 m['needs'].each do |n|
  path,klass=observed[n['id']];status='pass';d=sha.call(n['artifact'])
  if mode=='policy-control';path=policy;klass=n['evidenceClass'];status='fail' if scenario=='failed-native'&&n['id']=='VQ-P11';end
  if scenario=='forged-diagnostic'&&n['id']=='VQ-P11';path=policy;klass='native-diagnostic';end
  next unless path
  d='0'*64 if scenario=='wrong-artifact'&&n['id']=='VQ-TRANSITION'
  part<<fact.call('resizeEvidenceFact',path,sha.call(path),mode,klass)
  part<<fact.call('resizeObservedFact',scenario,*ids,n['id'],n['method'],n['artifact'],d,n['scope'],n['evidenceClass'],n['check'],status,path,sha.call(path))
 end
 part<<")\n";req="((displayBytes 32768) (selector #{q.call(part)}) (bindings (#{bindings.map{|k,v|"(#{q.call(k)} #{q.call(v)})"}.join(' ')})))\n"
 File.write(e+'/resize-qualification-requests/'+scenario+'.scm',req);File.write(history+'/'+scenario+'.request.scm',req)
 o,err,s=Open3.capture3('.venv/bin/gambit-smp','--task','modern-c-frame-contract','trajectory','clues',req);File.write(e+'/resize-qualification-results/'+scenario+'.scm',o);File.write(history+'/'+scenario+'.result.scm',o);File.write(b+'/resize-qualification-'+scenario+'.log',err)
 raise "incomplete #{scenario}: #{err}" unless s.success?&&o.include?('("evaluationComplete" #t)')
 ready=o.include?('(\"resizeAllReady\" ((\"synthetic-complete\")))'.gsub('\\"','"'));empty=o.include?('("resizeAllReady" ())')
 raise 'policy complete rejected' if scenario=='synthetic-complete'&&!ready
 raise 'false component closure' if scenario!='synthetic-complete'&&!empty
 raise 'missing law not detected' if scenario=='missing-law'&&!o.include?('"grantFloor" "lean-law"')
 raise 'failed native not preserved' if scenario=='failed-native'&&!o.include?('("resizeFailed" (("failed-native" "roots" "VQ-P11")))')
 results[scenario]={policyControl:mode=='policy-control',allReady:ready,resultSha256:Digest::SHA256.hexdigest(o)}
 File.write('dev/modeling/ascent/vm-resize-qualification.request.scm',req) if scenario=='current'
end
File.write(e+'/resize-qualification-admission.json',JSON.pretty_generate({scope:'source-bound research coverage and policy controls; not commit authority',claim:claim,bindings:bindings,identity:identity,observed:observed.keys,needCount:m['needs'].size,refinementRoutes:m['refinements'].size,structuralTokens:tokens.size,scenarios:results,runtimeAdmitted:false,commitAdmitted:false})+"\n")
FileUtils.cp(e+'/resize-qualification-admission.json',history+'/admission.json')
puts JSON.generate(needs:m['needs'].size,observed:observed.keys,routes:m['refinements'].size,scenarios:results.size,commitAdmitted:false)
