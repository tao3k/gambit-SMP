require 'json'; require 'digest'; require 'fileutils'; require 'open3'
# Native SysML supplies the inventory. This adapter checks concrete observations;
# ASCENT decides delivery and scope. It is not a second temporal/algebraic model.
model, bindings_path, out = ARGV
raise 'model, bindings, fresh output required' unless out && !File.exist?(out)
FileUtils.mkdir_p(out)
sha=->p { Digest::SHA256.file(p).hexdigest }
read=->p { JSON.parse(File.read(p)) }
m=read.call(model); b=read.call(bindings_path)
s=sha.call(m.fetch('sourceLock')); p=sha.call(m.fetch('profile')); r=sha.call(m.fetch('recipe'))
lock=read.call(m['sourceLock'])
lock['files'].each { |f,v| raise 'candidate drift '+f unless sha.call('vendor/gambit/'+f)==v['candidateSha256'] }
sources=m['components'].to_h do |c|
  raise 'source anchor absent '+c['id'] unless File.read(c['source']).include?(c['anchor'])
  [c['source'],sha.call(c['source'])]
end
outer=read.call(b.fetch('bootstrap')+'/receipt.json')
child=read.call(b['bootstrap']+'/run/receipt.json')
raise 'bootstrap envelope' unless outer['outcome']=='PASS' && outer['timeout']==false && outer['parentReaped'] && outer['processGroupQuiescent'] && outer['childReceiptSha256']==sha.call(b['bootstrap']+'/run/receipt.json') && child['inputsStable']
raise 'input identity' unless child['inputs'][File.expand_path(m['sourceLock'])]==s && child['inputs'][File.expand_path(m['profile'])]==p && outer['budgetSeconds']==m['wholeBudget'] && outer['wholeSeconds']<=m['wholeBudget']
boot=child['steps'].find{|x|x['id']=='bootstrap'}
raise 'two passes' unless boot['outcome']=='PASS' && boot['fullTwoPassBootstrapEstablished'] && boot['phaseCounts']==%w[phase1 phase2 phase3 phase4].to_h{|x|[x,2]}
copy=boot.fetch('preservation')
raise 'snapshot incomplete' unless copy['sourceUnchanged'] && copy['exactIdentity'] && copy['hardlinks']==false
%w[map wide-map wide-map-host].each{|id|raise 'map '+id unless child['steps'].any?{|x|x['id']==id && x['outcome']=='PASS'}}
suite=read.call(b.fetch('suite')+'/receipt.json')
raise 'named suite not qualified' unless suite['complete'] && suite['sourceLockSha256']==s && suite['profileSha256']==p && suite['evidence'].size==13 && suite['evidence'].values.all?{|x|x['outcome']=='PASS'} && suite['scenarios']['current']['supplied'].size==13
reuse=read.call(b.fetch('reuse')+'/receipt.json'); rc=read.call(b['reuse']+'/run/receipt.json')
raise 'reuse envelope' unless reuse['outcome']=='PASS' && !reuse['timeout'] && reuse['parentReaped'] && reuse['processGroupQuiescent'] && reuse['childReceiptSha256']==sha.call(b['reuse']+'/run/receipt.json') && rc['inputsStable']
rs=rc['steps'].find{|x|x['capability']=='gambit.completed-runtime'}
raise 'not original producer' unless rs && rs['outcome']=='PASS' && rs['storageTransfer']=={'mode'=>'same-workspace','copiedFiles'=>0} && rs['producerExpenditure']['receiptSha256']==sha.call(b['bootstrap']+'/receipt.json') && rs['producerExpenditure']['wholeSeconds']==outer['wholeSeconds']
raise 'reuse rebuilt target' if rc['steps'].any?{|x|%w[gambit.bootstrap gambit.seed-core gambit.source-core].include?(x['capability'])}
raise 'reuse not executed' unless rc['steps'].any?{|x|x['capability']=='gambit.executable-test' && x['outcome']=='PASS'}
b.fetch('tests').each do |f|
  t=File.read(f); raise 'tests incomplete '+f unless t.match?(/Ran \d+ tests? in/) && t.match?(/^OK$/) && !t.match?(/^FAILED/)
end
history=File.read(b.fetch('regressionHistory'))
raise 'regression history missing' unless history.include?('Ran 303 tests') && history.include?('FAILED (errors=1)') && history.include?('ERROR: test_real_executor_reuse_keeps_prior_state_and_checks_final_bytes')
raise 'identified regression not rerun' unless b['tests'].any?{|f|File.read(f).include?('test_real_executor_reuse_keeps_prior_state_and_checks_final_bytes')}
old=read.call(b.fetch('oldRecipe')); current=read.call(m['recipe'])
raise 'budget changed' unless old['budgetSeconds']==current['budgetSeconds'] && current['budgetSeconds']==600
%w[bootstrap map wide-map wide-map-host].each do |id|
  a=old['steps'].find{|x|x['id']==id}; z=current['steps'].find{|x|x['id']==id}
  raise 'surviving limits differ '+id unless a && z && a['budgetSeconds']==z['budgetSeconds'] && a['arguments']['executionBudgetSeconds']==z['arguments']['executionBudgetSeconds']
end
raise 'redundant seed remains' if current['steps'].any?{|x|x['capability']=='gambit.seed-core'}
formal={
 'dev/architecture/runtime/control/models/quint/continuation_segments.qnt'=>'3bc4a09c11a27436ab9bbeca2ec2361b540a1dbc55c52aecd69d72128586934e',
 'dev/architecture/runtime/control/models/lean/ContinuationSegments.lean'=>'79d000bc9d7fc8bac110c66f1707e338bd89194d0401a5f7dca11e7cb7e9e4b6'}
formal.each{|f,h|raise 'formal owner drift' unless sha.call(f)==h}
needs=m['obligations'].map{|x|[x['id'],x['method']]}; gates=m['gates'].map{|x|[x['id']]}
delivered={ 'source-contract'=>'source-refinement', 'artifact-custody'=>'filesystem-and-typing-tests',
 'unchanged-limits'=>'declaration-comparison', 'complete-bootstrap'=>'native-two-pass',
 'gc-mailbox-stop'=>'native-scheme', 'map-multishot'=>'native-scheme',
 'named-suite'=>'native-thirteen-lanes', 'exact-reuse'=>'native-producer-consumption' }
raise 'model needs a new evidence adapter' unless needs.sort==delivered.to_a.sort
raise 'five stage gates changed' unless gates.flatten.sort==%w[architecture models process questions tests]
data=->name,cols,rows {'(relation '+name+' ('+cols+') ('+rows.map{|q|'('+q.map{|v|JSON.generate(v)}.join(' ')+')'}.join(' ')+'))'}
policy='dev/modeling/ascent/bootstrap-artifact-custody.rules.scm'; results={}
implementation=b.fetch('implementationFiles').sort.to_h{|f|[f,sha.call(f)]}
implementation_id=Digest::SHA256.hexdigest(JSON.generate(implementation))
scope='smp-build-artifact-custody'
%w[wrong-source wrong-method unknown-result partial-bootstrap gate-conflict wrong-scope current].each do |name|
  rows=needs.map{|id,method|[id,method,s,p,r,'pass']}; gs=gates.map{|q|[q[0],s,p,r,'pass']}; request=scope
  case name
  when 'wrong-source' then rows.each{|q|q[2]='stale'}
  when 'wrong-method' then rows.find{|q|q[0]=='complete-bootstrap'}[1]='source-refinement'
  when 'unknown-result' then rows << rows.find{|q|q[0]=='exact-reuse'}[0..4]+['unknown']
  when 'partial-bootstrap' then rows.find{|q|q[0]=='complete-bootstrap'}[5]='unknown'
  when 'gate-conflict' then gs << ['tests',s,p,r,'unknown']
  when 'wrong-scope' then request='vendor-modern-c-runtime'
  end
  body=File.read(policy)
  {'bcIdentity'=>['source profile recipe',[[s,p,r]]], 'bcNeed'=>['id method',needs],
   'bcObservation'=>['id method source profile recipe outcome',rows],
   'bcGate'=>['id',gates], 'bcGateEvidence'=>['id source profile recipe outcome',gs],
   'bcStageRequest'=>['scope',[[request]]], 'bcScope'=>['scope',[[scope]]],
   'bcImplementation'=>['identity',[[implementation_id]]]}.each do |rel,(cols,v)|
    body.sub!('(relation '+rel+' ('+cols+'))',data.call(rel,cols,v)) || raise('missing relation '+rel)
  end
  d="(define-evidence (query) (sources clue factor binding) (outputs question bcSupplied bcMissing bcRejected bcGateMissing bcStageCommit bcRuntimeAdmission) (include clue-selection-schema)\n"+body+"\n(relation question (claim))\n((question I) <-- (bcNeed I _))\n)\n"
  req='((displayBytes 65536) (selector '+JSON.generate(d)+'))'
  File.write(out+'/'+name+'.request.scm',req+"\n")
  stdout,stderr,status=Open3.capture3('.venv/bin/gambit-smp','--task','modern-c-frame-contract','trajectory','clues',req)
  File.write(out+'/'+name+'.result.scm',stdout); File.write(out+'/'+name+'.stderr',stderr)
  raise 'incomplete ASCENT '+name unless status.success? && stdout.include?('("evaluationComplete" #t)') && stdout.include?('("bcRuntimeAdmission" ())')
  admitted=!stdout.include?('("bcStageCommit" ())')
  raise 'scope/control failure '+name unless admitted==(name=='current')
  raise 'missing current proof' if name=='current' && (!stdout.include?('("bcMissing" ())') || !stdout.include?('("bcGateMissing" ())'))
  results[name]={synthetic:name!='current',stageCommit:admitted,requestSha256:sha.call(out+'/'+name+'.request.scm'),resultSha256:sha.call(out+'/'+name+'.result.scm')}
end
files=[model,bindings_path,m['sourceLock'],m['profile'],m['recipe'],policy,*b['tests'],b['regressionHistory'],b['oldRecipe'],b['bootstrap']+'/receipt.json',b['bootstrap']+'/run/receipt.json',b['suite']+'/receipt.json',b['reuse']+'/receipt.json',b['reuse']+'/run/receipt.json']
File.write(out+'/receipt.json',JSON.pretty_generate({scope:scope,implementationSha256:implementation_id,implementationFiles:implementation,sourceLockSha256:s,profileSha256:p,recipeSha256:r,modelSha256:sha.call(model),sources:sources,evidence:files.to_h{|f|[f,sha.call(f)]},scenarios:results,obligations:needs.size,gates:gates.size,formalOwners:formal,formalReexecuted:false,stageCommitAdmitted:true,vendorRuntimeCommitAdmitted:false,releaseAdmitted:false})+"\n")
puts JSON.generate(controls:results.size,obligations:needs.size,gates:gates.size,scope:scope,stageCommit:true,vendorRuntimeCommit:false)
