require 'json'; require 'digest'; require 'fileutils'; require 'open3'
model,out,bindings_path=ARGV
raise 'fresh output required' if File.exist?(out); FileUtils.mkdir_p(out)
sha=->p { Digest::SHA256.file(p).hexdigest }
m=JSON.parse(File.read(model)); b=JSON.parse(File.read(bindings_path))
s=sha.call(m['sourceLock']); p=sha.call(m['profile'])
lock=JSON.parse(File.read(m['sourceLock']))
lock['files'].each { |f,r| raise 'source drift '+f unless sha.call('vendor/gambit/'+f)==r['candidateSha256'] }
m['responsibilities'].each { |r| raise 'anchor missing '+r['id'] unless File.read(r['source']).include?(r['anchor']) }
h=File.read('vendor/gambit/include/gambit.h.in'); setup=File.read('vendor/gambit/lib/setup.c')
raise 'legacy split fields remain' if h.match?(/\bsync_(?:id|op)[012]\b/) || setup.match?(/\b(?:SYNC_GET_MSG|SYNC_SEND_MSG|SYNC_INIT_MSG|___sync_wait)\b/)
raise 'copy acknowledgement order lost' unless setup.match?(/___SYNC_SLOT_READ\(___slot,op,id\);\s*\\\n\s*___SYNC_SLOT_ACK/)
raise 'exclusive initialization lost' unless h.include?('#define ___SYNC_SLOT_INIT(s) ((s)->stamp = ___SYNC_SLOT_EMPTY)')
raise 'ordered backend lost' unless h.include?('__atomic_load_n(p,__ATOMIC_ACQUIRE)') && h.include?('__atomic_fetch_add(p,v,__ATOMIC_RELEASE)')
source_files=m['responsibilities'].map{|r|r['source']}.uniq
proof=source_files.to_h{|f|[f,sha.call(f)]}
outer_path=b.fetch('bootstrap')+'/receipt.json'; outer=JSON.parse(File.read(outer_path))
child_path=b['bootstrap']+'/run/receipt.json'
raise 'prior attempt not quiescent' unless outer['parentReaped'] && outer['processGroupQuiescent']
raise 'source/profile binding differs' unless outer['inputs'][m['sourceLock']]==s && outer['inputs'][m['profile']]==p
bootstrap_pass=false
if outer['childReceiptSha256']
 raise 'child drift' unless sha.call(child_path)==outer['childReceiptSha256']
 child=JSON.parse(File.read(child_path)); boot=child['steps'].find{|q|q['id']=='bootstrap'}
 bootstrap_pass=outer['outcome']=='PASS' && !outer['timeout'] && child['inputsStable'] && boot && boot['fullTwoPassBootstrapEstablished'] && boot['phaseCounts']==%w[phase1 phase2 phase3 phase4].to_h{|q|[q,2]}
elsif File.exist?(child_path)
 raise 'unbound child receipt'
end
kernel_path=b.fetch('primaryKernel'); kernel=JSON.parse(File.read(kernel_path))
raise 'kernel not passed' unless kernel['outcome']=='PASS' && kernel['programSha256']==sha.call('vendor/gambit/tests/ordered-sync.c') && kernel['runnerSha256']==sha.call('vendor/gambit/tests/smp/suite.scm') && kernel['planSha256']==sha.call('vendor/gambit/tests/smp/catalog.scm')
kernel['runtimeSource'].each{|f,h|raise 'kernel source drift' unless sha.call('vendor/gambit/'+f)==h && sha.call(b['runtime']+'/'+f)==h}
kernel['commands'].each{|r|raise 'kernel custody or output drift' unless r['exit']==0 && !r['timeout'] && r['parentReaped'] && r['processGroupQuiescent'] && r['outputSha256']==sha.call(File.dirname(kernel_path)+'/'+r['output'])}
# Historical partial qualification remains negative. A new current-source suite
# can discharge the two native gaps only after its independent adapter checks.
if bootstrap_pass
 suite=JSON.parse(File.read(b.fetch('qualifiedSuite')+'/receipt.json'))
 raise 'current suite incomplete or unbound' unless suite['complete'] && suite['sourceLockSha256']==s && suite['profileSha256']==p && suite['evidence'].size==13 && suite['evidence'].values.all?{|x|x['outcome']=='PASS'} && suite['scenarios']['current']['supplied'].size==13
 raise 'suite belongs to another bootstrap' unless suite['bootstrap']['sha256']==sha.call(outer_path)
else
 raise 'partial qualification expects explicit bootstrap failure' unless outer['outcome']=='DENY' && outer['timeout']
end
obs=b.fetch('backend'); text=File.read(obs+'/observations.scm')
raise 'backend incomplete' unless text.scan(/\("(?:native-macros|legacy-macros|legacy-compile|legacy-run|native-assembly|clang-ir)".*?\s0 #t /).size==6
raise 'backend process groups not absent' unless text.scan(/\s\d+ #t\)/).size==6
raise 'native backend not selected' unless File.read(obs+'/native-macros.output').include?('#define ___ORDERED_WORD_NATIVE 1')
raise 'legacy backend not selected' unless File.read(obs+'/legacy-macros.output').include?('#define ___ORDERED_WORD_NATIVE 0')
expected="ORDERED-SYNC-PASS locks=16384 slots=16384 trylock=2 wrap=1\nORDERED-SYNC-LAYOUT word=64 slot=32 prior-pair=32\n"
raise 'legacy result mismatch' unless File.read(obs+'/legacy-run.output')==expected
raise 'native result mismatch' unless File.read(File.dirname(kernel_path)+'/run.output')==expected
ir=File.read(obs+'/native.ll'); asm=File.read(obs+'/native.s')
raise 'IR orders missing' unless ir.match?(/load atomic.*acquire/) && ir.match?(/atomicrmw.*release/) && ir.match?(/atomicrmw.*monotonic/) && ir.match?(/store atomic.*release/)
# GCC documents RCpc LDAPR as its acquire-load mapping on supported AArch64
# targets. Requiring LDAR alone would reject this actual armv8.5-a profile.
raise 'assembly acquire missing' unless asm.match?(/\b(?:ldar|ldapr)\b/) && asm.match?(/\bstlr\b/) && asm.match?(/\bldaddl\b/)
# Bind the observer's input receipts back to this exact compiler/header/fixture.
inputs=File.read(obs+'/inputs.scm')
[b.fetch('compiler'),'vendor/gambit/tests/ordered-sync.c',b.fetch('runtime')+'/include/gambit.h',b['runtime']+'/lib/setup.c','/usr/bin/clang'].each do |f|
 raise 'backend input drift '+f unless inputs.include?(sha.call(f))
end
formal={
 'CS-SCHEDULE'=>['dev/architecture/runtime/control/models/quint/continuation_segments.qnt','3bc4a09c11a27436ab9bbeca2ec2361b540a1dbc55c52aecd69d72128586934e'],
 'CS-COHERENCE'=>['dev/architecture/runtime/control/models/lean/ContinuationSegments.lean','79d000bc9d7fc8bac110c66f1707e338bd89194d0401a5f7dca11e7cb7e9e4b6']}
formal.each{|id,(f,h)|raise 'formal owner changed '+id unless sha.call(f)==h}
needs=m['obligations'].map{|r|[r['id'],r['method']]};policy='dev/modeling/ascent/ordered-synchronization.rules.scm'
data=->name,cols,rows {'(relation '+name+' ('+cols+') ('+rows.map{|r|'('+r.map{|v|JSON.generate(v)}.join(' ')+')'}.join(' ')+'))'}
observed=needs.to_h{|id,_|[id,!bootstrap_pass && %w[mailbox-stop semantic-regression].include?(id) ? 'unknown' : 'pass']}
results={}
%w[current wrong-source wrong-method unknown-result all-scoped-only].each do |name|
 rows=needs.map{|id,method|[id,method,s,p,name=='all-scoped-only' ? 'pass' : observed[id]]}
 case name
 when 'wrong-source' then rows.each{|r|r[2]='stale'}
 when 'wrong-method' then rows.find{|r|r[0]=='emitted-orders'}[1]='native-kernel'
 when 'unknown-result' then rows<<['kernel-native','native-kernel',s,p,'unknown']
 end
 body=File.read(policy)
 {'osIdentity'=>['source profile',[[s,p]]],'osNeed'=>['id method',needs],'osObservation'=>['id method source profile outcome',rows],
 'osOpenBoundary'=>['id',m['openBoundaries'].map{|r|[r['id']]}]}.each{|rel,(cols,v)|body.sub!('(relation '+rel+' ('+cols+'))',data.call(rel,cols,v))||raise('relation missing '+rel)}
 d="(define-evidence (query) (sources clue factor binding) (outputs question osSupplied osMissing osRejected osScopedClosure osBoundaryMissing osCommitReady) (include clue-selection-schema)\n"+body+"\n(relation question (claim))\n((question I) <-- (osNeed I _))\n)\n"
 req='((displayBytes 65536) (selector '+JSON.generate(d)+'))'+"\n"
 File.write(out+'/'+name+'.request.scm',req)
 stdout,stderr,status=Open3.capture3('.venv/bin/gambit-smp','--task','modern-c-frame-contract','trajectory','clues',req.chomp)
 File.write(out+'/'+name+'.result.scm',stdout); File.write(out+'/'+name+'.stderr',stderr)
 raise 'ASCENT incomplete '+name unless status.success? && stdout.include?('("evaluationComplete" #t)') && stdout.include?('("osCommitReady" ())')
 supplied=stdout[/\("osSupplied" (\(.*?\))\) (?=\(")/,1];raise 'supplied absent' unless supplied
 actual=supplied.scan(/"([a-z0-9.-]+)"/).flatten.sort
 passed=observed.select{|_,v|v=='pass'}.keys
 expected_ids=case name;when 'wrong-source' then [];when 'wrong-method' then passed-['emitted-orders'];when 'unknown-result' then passed-['kernel-native'];when 'all-scoped-only' then needs.map(&:first);else passed;end
 raise 'classification mismatch '+name unless actual==expected_ids.sort
 m['openBoundaries'].each{|r|raise 'boundary erased' unless stdout.include?('("'+r['id']+'")')}
 if name=='current'
  raise 'native closure classification mismatch' unless stdout.include?('("osScopedClosure" ())') == !bootstrap_pass
 end
 results[name]={synthetic:name!='current',supplied:actual,requestSha256:sha.call(out+'/'+name+'.request.scm'),resultSha256:sha.call(out+'/'+name+'.result.scm'),commitAdmitted:false}
end
retained=[model,m['sourceLock'],m['profile'],policy,bindings_path,outer_path,kernel_path,'dev/modeling/tools/observe-ordered-backend.scm',*Dir[obs+'/*'].select{|f|File.file?(f)}]
retained << b['qualifiedSuite']+'/receipt.json' if bootstrap_pass
File.write(out+'/receipt.json',JSON.pretty_generate({sourceLockSha256:s,profileSha256:p,modelSha256:sha.call(model),sources:proof,evidence:retained.to_h{|f|[f,sha.call(f)]},formalOwners:formal,formalReexecuted:false,controls:results,slotBytes:32,priorPairBytes:32,slotCount:3,extraReceiverMutexPairsPerRound:'2*(P-1)',heapOverride:false,waitExtended:false,observations:observed,bootstrapEstablished:bootstrap_pass,scopedClosed:bootstrap_pass,commitAdmitted:false})+"\n")
puts JSON.generate(controls:results.size,obligations:needs.size,observations:observed,bootstrapEstablished:bootstrap_pass,scopedClosed:bootstrap_pass,commitAdmitted:false)
