require 'json'; require 'digest'; require 'fileutils'; require 'open3'
if ARGV.first == '--protocols'
  require 'zlib'
  _,model_dir,run,out,native_run=ARGV
  raise 'model, completed run and fresh output required' unless out && !File.exist?(out)
  sha=->p{Digest::SHA256.file(p).hexdigest}
  m=JSON.parse(File.read(model_dir+'/native-projection.json'))
  raw=JSON.parse(File.read(model_dir+'/native-metadata.json'))
  raise 'native SysML failure' unless raw['exit']==0 && (raw['errors']||[]).empty?
  JSON.parse(File.read(model_dir+'/native-inputs.json')).each{|p,h|raise 'SysML input drift' unless sha.call(p)==h}
  outer=JSON.parse(File.read(run+'/receipt.json')); child=JSON.parse(File.read(run+'/run/receipt.json'))
  raise 'incomplete checker custody' unless outer['parentReaped'] && outer['processGroupQuiescent'] && !outer['timeout'] && sha.call(run+'/run/receipt.json')==outer['childReceiptSha256'] && child['inputsStable']
  steps=child.fetch('steps').to_h{|s|[s.fetch('id'),s]}
  files=[__FILE__,run+'/receipt.json',run+'/run/receipt.json'];watched={}
    outer.fetch('inputs').each{|p,h|raise 'run input drift' unless sha.call(p)==h;files<<p;watched[p]=h}
  tool_record='evidence/research/capacity-admission/protocol-tools.json'
  JSON.parse(File.read(tool_record)).fetch('tools').each do |name,t|
    raise 'model tool not observed' unless child.fetch('tools').fetch(name)==t.fetch('path') && sha.call(t.fetch('path'))==t.fetch('sha256')
  end
  # A failed checker is retained as a gap, never converted into positive facts.
  # Artifact bytes and process completion are checked independently of status.
  steps.each_value do |s|
    s.fetch('artifacts',{}).each{|name,h|p=run+'/run/'+name;raise 'checker artifact drift' unless sha.call(p)==h;files<<p}
    if s['outcome']=='PASS'
      s.fetch('commands',[]).each{|c|raise 'checker not quiescent' unless c['parentReaped'] && c['processGroupQuiescent'] && !c['timeout'] && c['seconds']<=c['effectiveBudgetSeconds']}
    end
  end
  model_rows=[];tests=[];safety=[];controls=[];actions=[];maps=[];rows=[]
  m.fetch('protocolBindings').each do |b|
    id=b.fetch('id');source=b.fetch('model');h=sha.call(source)
    raise 'model not bound to run' unless outer.fetch('inputs')[source]==h
    model_rows<<[id,source,h,b.fetch('status')];files<<source
    expected=File.read(source).scan(/^\s*action\s+(\w+)/).flatten
    declared=b.fetch('actions').split(';').map(&:strip)
    raise 'unknown QNT action' unless (declared-expected).empty?
    declared.each{|action|actions<<[id,action]}
    m.fetch('protocolSteps').select{|s|s.fetch('protocol_id')==id}.each do |s|
      p=s.fetch('source');raise 'source anchor missing' unless File.read(p).include?(s.fetch('anchor'))
      files<<p;watched[p]=sha.call(p)
      s.fetch('actions').split(';').map(&:strip).each{|a|maps<<[id,a,sha.call(p),Digest::SHA256.hexdigest(JSON.generate(s)),s.fetch('progress')]}
    end
    results={}
    {'tests'=>tests,'safety'=>safety,'control'=>controls}.each do |suffix,facts|
      s=steps[id+'-'+suffix];status='missing';digest='absent'
      if s
        status=s.fetch('outcome').downcase
        if status=='pass'
          name=suffix=='tests' ? 'result.json' : 'verdict.json'
          p=run+'/run/'+s.fetch('id')+'/'+name
          raise 'unbound checker result' unless s.fetch('artifacts')[s.fetch('id')+'/'+name]==sha.call(p)
          v=JSON.parse(File.read(p));digest=sha.call(p)
          if suffix=='tests'
            names=File.read(source).scan(/^\s*run\s+(\w+)/).flatten.sort
            raise 'test inventory mismatch' unless v['errors']==[] && v['failed']==[] && v['ignored']==[] && v['passed'].sort==names
          else
            raise 'wrong verifier claim' unless v['accepted'] && v['negative']==(suffix=='control') && !v['runtimeAdmitted'] && !v['sourceRefinementAdmitted']
          end
        end
      end
      facts<<[id,h,digest,status];results[suffix]=status
    end
    rows<<{id:id,model:source,sha256:h,results:results,qntDuty:b.fetch('qntDuty'),leanDuty:b.fetch('leanDuty'),premise:b.fetch('premise'),cRefinement:false}
  end
  native_facts=[];native_observation=nil
  if native_run
    proof=m.fetch('hashProofs').find{|p|p['method']=='native'}
    metadata_path=proof.fetch('artifact');native_observation=JSON.parse(File.read(metadata_path))
    packet=native_observation.fetch('retainedPacket')
    raise 'native retained packet drift' unless sha.call(packet)==native_observation.fetch('retainedPacketSha256')
    id=native_observation.fetch('protocolId')
    raise 'native protocol not selected by SysML' unless rows.any?{|r|r[:id]==id}
    no=JSON.parse(File.read(native_run+'/receipt.json'));nc=JSON.parse(File.read(native_run+'/run/receipt.json'))
    raise 'native process or result incomplete' unless no['outcome']=='PASS' && no['exit']==0 && no['timeout']==false && no['parentReaped'] && no['processGroupQuiescent'] && no['budgetSeconds']==600 && no['wholeSeconds']<=600 && sha.call(native_run+'/run/receipt.json')==no['childReceiptSha256'] && nc['inputsStable'] && nc.fetch('steps').all?{|s|s['outcome']=='PASS'}
    ns=nc.fetch('steps').find{|s|s['capability']=='gambit.native-development'}
    lock=ns.fetch('arguments').fetch('nativeDelta');profile=ns.fetch('arguments').fetch('buildProfile')
    raise 'native metadata identity mismatch' unless native_observation.fetch('sourceLockSha256')==sha.call(lock) && native_observation.fetch('profileSha256')==sha.call(profile) && native_observation.fetch('childReceiptSha256')==no['childReceiptSha256']
    JSON.parse(File.read(lock)).fetch('files').each{|p,h|raise 'native source drift' unless sha.call('vendor/gambit/'+p)==h.fetch('candidateSha256')}
    expected=native_observation.fetch('requiredCases')
    raise 'native regression cases omitted' unless %w[index-traversal index-traversal-compiled map worker-root-domains unknown-join-gc].all?{|i|expected.include?(i)} && expected.all?{|i|nc['steps'].any?{|s|s['id']==i && s['outcome']=='PASS'}}
    code='import json,sys; from pathlib import Path; from gambit_smp.recipes import inspect_run; r=inspect_run(Path(sys.argv[1])); print(json.dumps({k:r[k] for k in ("outcome","identityStatus","evidenceBindingStatus","artifactAvailability")}))'
    stdout,stderr,status=Open3.capture3('.venv/bin/python','-c',code,native_run+'/run')
    raise 'native framework inspection failed' unless status.success?
    view=JSON.parse(stdout)
    raise 'native framework evidence stale' unless view['outcome']=='PASS' && view['identityStatus']=='CURRENT' && view['evidenceBindingStatus']=='CURRENT' && %w[AVAILABLE RETAINED].include?(view.fetch('artifactAvailability').fetch('status'))
    native_facts<<[id,sha.call(lock),sha.call(profile),no['childReceiptSha256'],'pass']
    files+=[metadata_path,packet,lock,profile,native_run+'/receipt.json',native_run+'/run/receipt.json']
  end
  rules='dev/modeling/ascent/root-worker-exit.rules.scm';base=File.read(rules);files<<rules
  FileUtils.mkdir_p(out);answers={}
  scenarios=['current','stale-source','missing-test','missing-safety','missing-counterexample','missing-mapping']
  scenarios<<'missing-native' if native_run
  scenarios.each do |scenario|
    body=base.dup
    data={'rweProtocol'=>['id model digest status',model_rows],
      'rweProtocolTest'=>['id modelDigest resultDigest outcome',tests],
      'rweProtocolSafety'=>['id modelDigest resultDigest outcome',safety],
      'rweProtocolControl'=>['id modelDigest resultDigest outcome',controls],
      'rweProtocolAction'=>['id action',actions],
      'rweProtocolStep'=>['id action sourceDigest boundaryDigest progress',maps],
      'rweProtocolNative'=>['id sourceDigest profileDigest resultDigest outcome',native_facts]}
    data.each do |name,(columns,original)|
      values=original.map(&:dup)
      values=[] if {'missing-test'=>'rweProtocolTest','missing-safety'=>'rweProtocolSafety','missing-counterexample'=>'rweProtocolControl','missing-mapping'=>'rweProtocolStep'}[scenario]==name
      values=[] if scenario=='missing-native' && name=='rweProtocolNative'
      values.each{|v|v[1]='different-source'} if scenario=='stale-source' && name=='rweProtocolTest'
      encoded=values.map{|v|'('+v.map(&:to_json).join(' ')+')'}.join(' ')
      old='(relation '+name+' ('+columns+'))'
      raise 'DSL schema mismatch' unless body.include?(old)
      body.sub!(old,'(relation '+name+' ('+columns+') ('+encoded+'))')
    end
    queries=%w[rweProtocolTested rweProtocolScheduleChecked rweProtocolUnmapped rweProtocolNativeObserved rweProtocolSliceObserved rweProtocolCGap rweRetirementReady].to_h{|n|[n,n]}
    dir=out+'/'+scenario;FileUtils.mkdir_p(dir)
    program=dir+'/query.ss';File.write(program,"(define-evidence (query) (sources) (outputs #{queries.keys.join(' ')})\n(relation smpModernReady (id))\n"+body+"\n)\n")
    entry={schema:'ascent.evidence-dsl-entry.v1',trusted:true,constructor:'query',arguments:[],sources:[{path:program,sha256:sha.call(program)}]}
    path=dir+'/entry.json';File.write(path,JSON.pretty_generate(entry)+"\n")
    output=File.expand_path(dir+'/native');FileUtils.mkdir_p(output)
    request={rules:[],dsl:entry,dslInput:File.expand_path(path),dslInputSha256:sha.call(path),dslRoot:Dir.pwd,facts:{},queries:queries,output:output}
    file=dir+'/evaluation.json';File.write(file,JSON.pretty_generate(request)+"\n")
    code='import json,sys; from gambit_smp.evidence_capabilities import native_evaluate; native_evaluate(json.load(open(sys.argv[1])))'
    stdout,stderr,status=Open3.capture3('.venv/bin/python','-c',code,file)
    File.write(dir+'/adapter.log',stdout+stderr);raise 'ASCENT protocol evaluation failed' unless status.success?
    result=JSON.parse(File.read(output+'/answers.json'))
    expected=%w[current missing-native].include?(scenario) ? rows.select{|r|r[:results].values.all?{|v|v=='pass'}}.map{|r|[r[:id]]}.sort : []
    raise 'model checking overclaim' unless result.fetch('rweProtocolScheduleChecked').sort==expected
    observed=scenario=='missing-native' ? [] : native_facts.map{|r|[r[0]]}.sort
    raise 'native observation overclaim' unless result.fetch('rweProtocolNativeObserved').sort==observed
    slice=scenario=='current' ? observed.select{|r|expected.include?(r)} : []
    raise 'model/native composition overclaim' unless result.fetch('rweProtocolSliceObserved').sort==slice
    raise 'C or retirement overclaim' unless result.fetch('rweProtocolCGap').sort==rows.map{|r|[r[:id]]}.sort && result.fetch('rweRetirementReady')==[]
    answers[scenario]=result
  end
  files+=%w[native-projection.json native-metadata.json native-inputs.json native-queries.tsv native-model-inputs.txt sysml.log].map{|p|model_dir+'/'+p}
  files+=JSON.parse(File.read(model_dir+'/native-inputs.json')).keys
  files+=Dir.glob(out+'/**/*').select{|p|File.file?(p)}
  records={};files.uniq.each{|p|h=sha.call(p);raise 'qualification source changed' if watched.key?(p) && watched[p]!=h;a=out+'/'+h+'.gz';Zlib::GzipWriter.open(a){|z|z.write(File.binread(p))} unless File.exist?(a);records[p]={sha256:h,archive:a}}
  receipt={scope:'SysML-selected finite QNT histories, C boundary mapping and independent algebra duties; not C refinement',modelRunOutcome:outer['outcome'],protocols:rows,nativeObservation:native_observation,scenarios:answers,records:records,runtimeAdmitted:false,commitAdmitted:false}
  File.write(out+'/receipt.json',JSON.pretty_generate(receipt)+"\n")
  puts JSON.generate(protocols:rows.size,scenarios:answers.size,modelRun:outer['outcome'],sourceRefined:0,runtimeAdmitted:false)
  exit
end
if ARGV.first == '--verify-records'
  require 'zlib'
  _,path=ARGV
  raise 'one retained receipt required' unless path && ARGV.length==2
  receipt=JSON.parse(File.read(path)); records=receipt.fetch('records')
  raise 'nonempty retained record inventory required' unless records.is_a?(Hash) && !records.empty?
  directory=File.realpath(File.dirname(path))+'/'
  records.each_value do |record|
    digest=record.fetch('sha256'); archive=record.fetch('archive')
    raise 'invalid retained digest' unless digest.match?(/\A[0-9a-f]{64}\z/)
    raise 'archive escapes receipt directory' unless !File.symlink?(archive) && File.realpath(archive).start_with?(directory) && File.basename(archive)==digest+'.gz'
    # Original observation paths are labels. Never open a local build path,
    # execute retained code, or infer native/current-source admission here.
    actual=Digest::SHA256.new
    Zlib::GzipReader.open(archive) do |stream|
      while (chunk=stream.read(65536)) && !chunk.empty?
        actual.update(chunk)
      end
    end
    raise 'retained bytes differ' unless actual.hexdigest==digest
  end
  puts JSON.generate(recordsVerified:records.size,localOriginPathsOpened:0,
                     nativeExecuted:false,runtimeAdmitted:false,commitAdmitted:false)
  exit
end
if %w[--native-phase --native-arena --native-domains --native-owner].include?(ARGV.first)
  owner_mode = ARGV.first == '--native-owner'
  domains_mode = owner_mode || ARGV.first == '--native-domains'
  arena_mode = ARGV.first != '--native-phase'
  require 'zlib'
  _, model_dir, run, out = ARGV
  raise 'model, native run and fresh output required' unless out && !File.exist?(out)
  sha=->p{Digest::SHA256.file(p).hexdigest}
  model=JSON.parse(File.read(model_dir+'/native-projection.json'))
  native_model=JSON.parse(File.read(model_dir+'/native-metadata.json'))
  raise 'native SysML failure' unless native_model['exit']==0 && (native_model['errors']||[]).empty?
  if owner_mode
    JSON.parse(File.read(model_dir+'/native-inputs.json')).each{|p,h|raise 'SysML projection source drift' unless sha.call(p)==h}
  end
  contract=model.fetch('realizations').find{|r|r['id']==(owner_mode ? 'owner-cleanup-effects' : domains_mode ? 'worker-root-domains' : arena_mode ? 'worker-arena-handoff' : 'root-phase-custody')}
  guards=%w[exact-source original-profile same-workspace phase-kernel topology-and-map calibrated-unknown-join fresh-processes bounded-budgets]
  if arena_mode
    guards[guards.index('phase-kernel')]='arena-kernel'
    guards<<'refill-exercised'
    guards[guards.index('fresh-processes')]='authenticated-executions'
  end
  if domains_mode
    guards[guards.index('arena-kernel')]='domain-kernel'
    guards<<'owner-domain-service'
  end
  guards+=%w[fresh-still-generation refusal-before-effects native-run-abi write-authority copy-before-reserve source-bounded-request closed-root-domain] if owner_mode
  relation = owner_mode ? 'rweOwner' : domains_mode ? 'rweDomains' : arena_mode ? 'rweArena' : 'rwePhase'
  compiles = domains_mode ? 6 : arena_mode ? 5 : 3
  executions = domains_mode ? 13 : arena_mode ? 11 : 8
  raise 'guards not owned by SysML' unless contract && guards.all?{|g|contract['qualification'].include?(g)}
  outer=JSON.parse(File.read(run+'/receipt.json'));child=JSON.parse(File.read(run+'/run/receipt.json'))
  raise 'native run not complete' unless outer['outcome']=='PASS' && outer['exit']==0 && outer['timeout']==false && outer['parentReaped'] && outer['processGroupQuiescent'] && outer['budgetSeconds']==600 && outer['wholeSeconds']<=600 && sha.call(run+'/run/receipt.json')==outer['childReceiptSha256'] && child['inputsStable']
  steps=child['steps'].to_h{|s|[s['id'],s]}
  raise 'missing PASS' unless steps.values.all?{|s|s['outcome']=='PASS'}
  origins={}; retained=[]; prior_runs=[]
  if arena_mode
    # Follow the framework checkpoint contract to the actual process birth.
    # Every outer/child link and canonical row is authenticated, including
    # nested reuse. Replaying a row never creates a new execution observation.
    loaded={}
    load_run=->dir do
      loaded[dir] ||= begin
        o=JSON.parse(File.read(dir+'/receipt.json'))
        c=JSON.parse(File.read(dir+'/run/receipt.json'))
        raise 'unauthenticated child receipt' unless o['childReceiptSha256']==sha.call(dir+'/run/receipt.json') && o['engineId']==outer['engineId'] && o['parentReaped'] && o['processGroupQuiescent'] && c['inputsStable']
        [o,c]
      end
    end
    resolved={}
    resolve=nil
    resolve=->dir,id,seen do
      key=[dir,id]
      raise 'cyclic or excessive checkpoint lineage' if seen.include?(key) || seen.size>=32
      resolved[key] ||= begin
        o,c=load_run.call(dir)
        s=c['steps'].find{|r|r['id']==id}
        raise 'missing successful checkpoint row' unless s && s['outcome']=='PASS'
        if (ref=s['reused'])
          prior=ref.fetch('run')
          raise 'checkpoint path escapes fixed task' unless prior.start_with?('.cache/tasks/modern-c-frame-contract/runs/') && File.realpath(prior)==File.expand_path(prior)
          po,pc=load_run.call(prior)
          raise 'prior receipt link differs' unless o['prior']['receiptSha256']==sha.call(prior+'/receipt.json')
          original=pc['steps'].find{|r|r['id']==ref['step']}
          raise 'checkpoint contract differs' unless original && %w[id capability arguments dependsOn budgetSeconds].all?{|k|original[k]==s[k]}
          code='import json,sys; from gambit_smp.step_checkpoint import content_id; row=next(s for s in json.load(open(sys.argv[1]))["steps"] if s["id"]==sys.argv[2]); print(content_id({k:v for k,v in row.items() if k!="journal"}))'
          stdout,stderr,status=Open3.capture3('.venv/bin/python','-c',code,prior+'/run/receipt.json',s['id'])
          raise 'checkpoint row identity differs' unless status.success? && stdout.strip==ref['receipt'] && s['originCommands']==original.fetch('commands',[]) && s['originArtifacts']==original.fetch('artifacts',{})
          raise 'replay claimed a new process' unless s['executionLaunched']==false && !s.key?('commands')
          prior_runs<<prior
          resolve.call(prior,id,seen+[key])
        else
          [s,dir]
        end
      end
    end
    child['steps'].each do |s|
      row,dir=resolve.call(run,s['id'],[])
      steps[s['id']]=row; origins[s['id']]=dir
      retained<<s['id'] if dir!=run
    end
  else
    raise 'fresh phase observations required' unless steps.values.none?{|s|s.key?('reused')}
  end
  n=steps.fetch('native-stage-root-phases');w=n['workspace']['delta']['source']
  build_run=ARGV[4]
  if build_run
    raise 'incremental composition is an owner-source qualification' unless owner_mode
    build_outer=JSON.parse(File.read(build_run+'/receipt.json'))
    build_child=JSON.parse(File.read(build_run+'/run/receipt.json'))
    raise 'incomplete incremental observation' unless build_outer['outcome']=='PASS' && build_outer['exit']==0 && !build_outer['timeout'] && build_outer['parentReaped'] && build_outer['processGroupQuiescent'] && build_child['inputsStable'] && build_outer['childReceiptSha256']==sha.call(build_run+'/run/receipt.json')
    build=build_child['steps'].find{|s|s['id']=='native-stage-root-phases'}
    raise 'incremental source/runtime differs' unless build && build['outcome']=='PASS' && build['outputs']['runtime']['identity']==n['outputs']['runtime']['identity'] && build['arguments']['nativeDelta']==n['arguments']['nativeDelta'] && build['workspace']['sourceCopies']==0
    raise 'no-change work was replayed' unless build['nativeParametersChanged']==false && build['nativeOutputsInvalidated']==[] && build['observedNativeRecipeLines']==[] && build['observedGenerationRecipeLines']==[] && build['configurationAction']=='reuse'
    raise 'incremental budget changed' unless build_outer['budgetSeconds']==600 && build_outer['wholeSeconds']<=600 && build['budgetSeconds']==400
  end
  fixed=File.expand_path('.cache/tasks/modern-c-frame-contract/build/gambit-core/16a8e0b205a5a975c3ac653b3533112191011eba983fc7145f197a1e4920b880/source')
  raise 'changed workspace or budget' unless w==fixed && File.realpath(w)==w && n['workspace']['sourceCopies']==0 && n['budgetSeconds']==400 && n['observedGenerationRecipeLines']==[] && n['generatedArtifacts'].size==51
  lock=domains_mode ? n['arguments']['nativeDelta'] : 'evidence/research/worker-role-handoff/'+(arena_mode ? 'worker-arena' : 'root-phase')+'.lock.json'
  owned_delta=lock.start_with?('evidence/research/worker-role-handoff/') || %w[evidence/research/section-copy-authority/source.lock.json evidence/research/copy-root-admission/source.lock.json evidence/research/copy-root-admission/settled-source.lock.json].include?(lock)
  raise 'noncanonical source delta' unless owned_delta && lock.end_with?('.lock.json') && File.realpath(lock)==File.expand_path(lock)
  profile='evidence/research/worker-role-handoff/profile.json'
  l=JSON.parse(File.read(lock))
  raise 'source lock not bound' unless outer['inputs'][lock]==sha.call(lock)
  l['files'].each do |name,h|
    raise 'source not applied or changed' unless sha.call('vendor/gambit/'+name)==h['candidateSha256'] && sha.call(w+'/'+name)==h['candidateSha256'] && n['nativeDelta'][name]['after']==h['candidateSha256']
  end
  raise 'original profile changed' unless sha.call(profile)=='884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69' && outer['inputs'][profile]==sha.call(profile)
  names=%w[map wide-map wide-map-host worker-roles worker-roles-host]
  names+=%w[worker-arena-refill worker-arena-refill-host worker-arena-loan] if arena_mode
  names+=%w[map-host worker-root-domains] if domains_mode
  tests=names.map{|name|steps.fetch(name)}
  raise 'topology execution/compilation count differs' unless tests.sum{|s|s['commands'].count{|c|c['stage']=='compile-executable'}}==compiles && tests.all?{|s|s['commands'].count{|c|c['stage']=='run-executable'}==1 && s['budgetSeconds']==90}
  shared=%w[wide-map-host worker-roles-host]
  shared<<'worker-arena-refill-host' if arena_mode
  shared<<'map-host' if domains_mode
  shared.each do |name|
    s=steps.fetch(name);raise 'topology artifact sharing missing' unless s['compilationReused'] && !s['compilationLaunched']
  end
  %w[root-phase-kernel-test fault-calibration-test].each do |name|
    raise 'native kernel/calibration cases incomplete' unless steps.fetch(name)['passedCases'].size==1
  end
  expected_programs={'map'=>'vendor/gambit/tests/frame-continuation.scm',
    'wide-map'=>'vendor/gambit/tests/frame-continuation-roots.scm',
    'wide-map-host'=>'vendor/gambit/tests/frame-continuation-roots.scm',
    'worker-roles'=>'vendor/gambit/tests/smp/gc/worker-role-handoff.scm',
    'worker-roles-host'=>'vendor/gambit/tests/smp/gc/worker-role-handoff.scm',
    'unknown-join-gc'=>'evidence/research/modern-c-bootstrap/entry-custody-isolation-multi.scm'}
  if arena_mode
    %w[worker-arena-refill worker-arena-refill-host].each do |name|
      expected_programs[name]='vendor/gambit/tests/smp/gc/worker-arena-refill.scm'
      raise 'physical refill not exercised' unless steps.fetch(name)['arguments']['stdout']=="WORKER-ARENA-REFILL-PASS epochs=3\n"
    end
    expected_programs['worker-arena-loan']='vendor/gambit/tests/smp/gc/worker-arena-loan.scm'
    loan=steps.fetch('worker-arena-loan')
    raise 'bounded stack loan not exercised' unless loan['arguments']['stdout']=="WORKER-ARENA-LOAN-PASS epochs=2\n" && loan['executionProcessors']==1
    raise 'handoff kernel absent'  unless steps.fetch('root-phase-kernel-test')['arguments']['cases'].first['stdout'].include?("ARENA-HANDOFF-PASS\n")
  end
  if domains_mode
    expected_programs['map-host']='vendor/gambit/tests/frame-continuation.scm'
    expected_programs['worker-root-domains']='vendor/gambit/tests/smp/gc/worker-root-domains.scm'
    expected_programs['unknown-join-gc']='vendor/gambit/tests/smp/gc/unknown-join-worker-domains.scm'
    domain=steps.fetch('worker-root-domains')
    raise 'owner/root/worker matrix not observed' unless domain['arguments']['stdout']=="WORKER-ROOT-DOMAINS-PASS roots=3 workers=1,2,3,1 cleanup=3\n" && domain['executionProcessors']==1
    raise 'host topology not exercised' unless steps.fetch('map-host')['executionProcessors']>1 && steps.fetch('wide-map-host')['executionProcessors']>1
    raise 'noncollector resume kernel absent' unless steps.fetch('root-phase-kernel-test')['arguments']['cases'].first['stdout'].include?("ROOT-DOMAIN-RESUME-PASS\n")
  end
  if owner_mode
    raise 'native run ABI kernel not observed' unless steps.fetch('root-phase-kernel-test')['arguments']['cases'].first['stdout'].include?("NATIVE-RUN-ABI-PASS\n")
    signature=File.read('vendor/gambit/include/_gambit/runtime_forwards.h.in')
    raise 'native run signature not canonical' unless signature.include?('typedef ___SCMOBJ ___run_function') && signature.include?('___P((___PSD ___SCMOBJ thunk), ());')
    {'include/_gambit/runtime_protocols.h.in'=>'___IMP_FUNC(___run_function,___run);',
     'include/_gambit/global_state.h.in'=>'___run_function *___run;',
     'lib/setup.c'=>'___run_function ___run;'}.each do |name,needle|
      raise 'native consumer bypasses canonical signature' unless l['files'].key?(name) && File.read('vendor/gambit/'+name).include?(needle)
    end
    raise 'ABI consumer mirrors shared type' if File.read('vendor/gambit/tests/gc-root-task.c').include?('___run_function')
    raise 'write authority component controls absent' unless steps.fetch('root-phase-kernel-test')['arguments']['cases'].first['stdout'].include?("write-authority controls passed\n")
    raise 'copy gate controls absent' unless steps.fetch('root-phase-kernel-test')['arguments']['cases'].first['stdout'].include?("COPY-AUTHORITY-PASS\n")
    copy=File.read('vendor/gambit/lib/_mem/copy-reservations.inc')
    raise 'object header load must not be RMW' unless copy.include?('head = load_copy_source_header(work,body);') && copy.include?('return ___WORD_LOAD_ACQUIRE(&body[-1]);') && copy.include?('head = body[-1];') && copy.include?('if (___WORD_LOAD_ACQUIRE(&body[-1]) != head)')
    acquire=copy.index('___gc_copy_acquire (copy_gate)')
    reserve=copy.index('grant = reserve_copy',acquire || 0)
    forward=copy.index('___COMPARE_AND_SWAP_WORD(&body[-1],',reserve || 0)
    # The final release precedes payload work; a retry release is not the
    # successful publication boundary. This is source evidence, not C proof.
    release=copy.index("___gc_copy_release (copy_gate);\n                work->copied_words")
    raise 'copy authorization order changed' unless acquire && reserve && forward && release && acquire < reserve && reserve < forward && forward < release
    lookup=copy.index('require_fromspace_copy_source (work, cell, body)')
    raise 'copy gate not owned by validated source section' unless lookup && lookup < acquire && copy.include?('&source_section->copy_gate;')
    roles=File.read('vendor/gambit/include/_gambit/runtime_roles.h.in')
    section=File.read('vendor/gambit/include/_gambit/memory_state.h.in')
    allocation=File.read('vendor/gambit/lib/_mem/movable-sections.inc')
    initialized=allocation.index('s->copy_gate = 0;')
    published=allocation.index('ms->sections[i] = s;')
    raise 'fixed copy stripe family retained' if roles.include?('___GC_COPY_GATE_COUNT') || roles.include?('copy_gates[')
    raise 'source section lifetime lacks gate initialization' unless section.include?('___VOLATILE ___WORD copy_gate;') && initialized && published && initialized < published
    # These ordered source adapters are prerequisites of the native slice;
    # they do not replace interval algebra or C memory-model validation.
    request=copy.index('prepare_copy_request(work,source_section',acquire || 0)
    raise 'source request not prepared under copy claim' unless request && acquire < request && request < reserve
    raise 'request not consumed before refill' unless copy.index('work->copy_request.destination_words != required') < copy.index('refill_worker_arena(work);')
    raise 'source interval or epoch not checked' unless %w[source_words destination_words source_section epoch].all?{|v|roles.include?(v)} && copy.include?('first-base > (half-source_words)*___WS') && copy.include?('work->copy_request.epoch != work->vm->gc_round.epoch')
    frame=File.read('vendor/gambit/lib/_mem/continuation-roots.inc')
    raise 'frame copy bypasses bounded request' unless frame.include?('prepare_copy_request(work,section,source,___FRAME_SPACE(fs),') && frame.index('prepare_copy_request(') < frame.index('grant = reserve_copy(')
    rc=File.read('vendor/gambit/lib/_mem/rc-allocation.inc')
    scan=File.read('vendor/gambit/lib/_mem/rc-roots.inc')
    round=File.read('vendor/gambit/lib/_mem/collection-round.inc')
    sfun=File.read('vendor/gambit/lib/c_intf.c')
    close=round.index('close_rc_roots (___ps);')
    freeze=round.index('participant->phase = ___GC_ROOTS_FROZEN;',close || 0)
    thaw=round.index('BARRIER(); /* no worker may retain a stopped root view past this cut */')
    reopen=round.index('reopen_rc_roots (___ps);')
    raise 'RC close/scan/reopen order absent' unless close && freeze && thaw && reopen && close < freeze && thaw < reopen && scan.include?('___SPINLOCK_LOCK(context->mem.rc_gate_)') && scan.include?('!context->mem.rc_closed_')
    raise 'RC writers or borrow custody not mediated' unless rc.include?('h->domain != &ps->context->mem') && rc.include?('if (h->domain->rc_closed_)') && rc.include?('___ps->context->mem.rc_root_borrows_ != 0') && rc.include?('___EXP_FUNC(void*,___register_rc)') && rc.include?('___EXP_FUNC(___WORD,___refcount_rc)')
    raise 'SFUN raw-local root remains' if sfun.include?('marker, &proc_or_false)')
    raise 'SFUN borrow does not cover marker allocation' unless sfun.include?('root = ___borrow_rc_root(___ps, held);') && sfun.include?('result = ___make_sfun_stack_marker_from_root(___ps, marker, root);') && sfun.include?('___return_rc_root (held);')
    fixture=File.read('vendor/gambit/tests/smp/gc/worker-root-domains.scm')
    raise 'RC native negative/scan controls missing' unless fixture.include?('atomic_load(&domain_rc_rejected)!=3') && fixture.include?('w->copy_request.state') && fixture.include?('___release_rc(domain_rc[id]); /* borrow owns the only native reference */') && fixture.include?('RC borrowed roots lost or closure admitted writer')
    %w[lib/_mem/rc-allocation.inc lib/_mem/rc-roots.inc lib/_mem/continuation-roots.inc lib/c_intf.c lib/mem.h lib/os_dyn.c].each{|name|raise 'root/request source not bound' unless l['files'].key?(name)}
    %w[include/_gambit/runtime_roles.h.in include/_gambit/vm_state.h.in lib/_mem/heap-sections.inc lib/_mem/copy-reservations.inc tests/gc-root-task.c].each do |name|
      raise 'copy protocol input not bound' unless l['files'].key?(name) && sha.call(w+'/'+name)==l['files'][name]['candidateSha256']
    end
    moves=l.fetch('relocations')
    expected_moves={'lib/native_scope.c'=>'lib/write_authority.c','lib/native_scope.h'=>'lib/write_authority.h','include/_gambit/native_activation.h.in'=>'include/_gambit/write_authority.h.in','tests/native-scope.c'=>'tests/write-authority.c'}
    raise 'incomplete authority relocation' unless moves.transform_values{|r|r['target']}==expected_moves
    expected_moves.each do |old,fresh|
      raise 'parallel authority path retained' if File.exist?('vendor/gambit/'+old) || File.exist?(w+'/'+old)
      raise 'moved authority bytes differ' unless sha.call(w+'/'+fresh)==l['files'][fresh]['candidateSha256']
    end
    l['files'].each_key do |name|
      raise 'old runtime authority API retained' if File.read('vendor/gambit/'+name).match?(/___native_scope|___NATIVE_SCOPE|native_scopes\[/)
    end
  end
  expected_programs.each{|name,p|s=steps.fetch(name);raise 'native semantic fixture changed' unless s['arguments']['program']==p && s['programSha256']==sha.call(p) && outer['inputs'][p]==sha.call(p)}
  unknown=steps.fetch('unknown-join-gc')
  raise 'unknown-join control not calibrated' unless unknown['arguments']['executionBudgetSeconds']==25 && unknown['dependsOn'].include?('fault-calibration-test') && unknown['arguments']['stdout']=="RESIZE-UNKNOWN-MULTI-GC-PASS\n"
  library=steps.fetch('fault-adapter')['outputs'].fetch('library')
  library_path=File.expand_path(origins.fetch('fault-adapter',run)+'/run/'+library['path'])
  runs=tests.flat_map{|s|s['commands'].select{|c|c['stage']=='run-executable'}}
  %w[root-phase-kernel-test fault-calibration-test unknown-join-gc].each do |name|
    observed=steps.fetch(name)['commands'].select{|c|c['stage'].start_with?('case-') || c['stage']=='run-executable'}
    raise 'exact one fresh native execution required' unless observed.size==1
    runs+=observed
    if name!='root-phase-kernel-test'
      raise 'actual interposition context missing' unless observed[0]['environment']['DYLD_INSERT_LIBRARIES']==library_path && steps.fetch(name)['observedInputs'][library_path]==sha.call(library_path)
    end
  end
  raise 'fresh process identity duplicated' unless runs.map{|c|c['pid']}.uniq.size==executions
  steps.values.flat_map{|s|s['commands']||[]}.each do |c|
    raise 'failed or unknown actual command' unless c['exit']==0 && c['timeout']==false && c['parentReaped'] && c['processGroupQuiescent'] && c['seconds']<=c['effectiveBudgetSeconds']
  end
  bound_controls=(build_run ? build_outer : outer).fetch('inputs')
  candidates=(owner_mode ? %w[write-authority-object-controls.json write-authority-configure-controls.json] : %w[root-phase-controls.json]).map{|f|'evidence/research/worker-role-handoff/'+f}.select{|p|bound_controls.key?(p)}
  raise 'one source-bound framework certificate required' unless candidates.size==1
  cert=candidates.first;u=JSON.parse(File.read(cert))
  control_shape=owner_mode ? u['testModules']==%w[tests.test_native_development tests.test_bootstrap_artifacts tests.test_completed_producer tests.test_native_executable] : u['tests']==189
  raise 'framework controls not bound' unless u['exit']==0 && control_shape && u['tests']>0 && !u['nativeAccepted'] && (build_run ? build_outer : outer)['inputs'][cert]==sha.call(cert)
  u['sourceHashes'].each{|p,h|raise 'unit source drift' unless sha.call(p)==h}
  %w[python stderr].each{|k|v=u.fetch(k);raise 'unit tool/log drift' unless sha.call(v['path'])==v['sha256']}
  FileUtils.mkdir_p(out)
  rules='dev/modeling/ascent/root-worker-exit.rules.scm';base=File.read(rules)
  keys=[sha.call(lock),sha.call(profile),Digest::SHA256.hexdigest(JSON.generate(contract))]
  requirements=[]
  if arena_mode
    requirements=model.fetch('workerAdmission')
    expected=%w[independent-refill resume-coverage affine-cleanup collective-split descendant-termination physical-packing native-writer-closure]
    raise 'incomplete SysML worker admission inventory' unless requirements.map{|r|r['id']}.sort==expected.sort
    raise 'unexpected source closure' unless requirements.select{|r|r['progress']=='source-refined'}.map{|r|r['id']}.sort==(domains_mode ? %w[independent-refill resume-coverage affine-cleanup collective-split descendant-termination] : ['independent-refill']).sort && requirements.count{|r|r['progress']=='open'}==(domains_mode ? 2 : 6)
  end
  fact=->row{'('+row.map(&:to_json).join(' ')+')'}
  answers={}
  (['all-guards']+guards).each do |scenario|
    active=scenario=='all-guards' ? guards : guards-[scenario]
    body=base.sub('(relation '+relation+'Identity (source profile contract))','(relation '+relation+'Identity (source profile contract) ('+fact.call(keys)+'))')
    body.sub!('(relation '+relation+'Guard (source profile contract guard))','(relation '+relation+'Guard (source profile contract guard) ('+active.map{|g|fact.call(keys+[g])}.join(' ')+'))')
    queries={relation+'Ready'=>relation+'Ready','rweRetirementReady'=>'rweRetirementReady'}
    if owner_mode
      bounds=model.fetch('nativeBoundaries')
      raise 'native-boundary inventory incomplete' unless bounds.map{|b|b['id']}.sort==%w[owner-new-still nested-gc managed-entry raw-rc-and-payload nonlocal-native-exit teardown-producer native-run-abi write-authority].sort
      rows=bounds.map{|b|[b['id'],Digest::SHA256.hexdigest(JSON.generate(b)),b['admission']]}
      body.sub!('(relation rweNativeBoundary (id contract admission))','(relation rweNativeBoundary (id contract admission) ('+rows.map{|r|fact.call(r)}.join(' ')+'))')
      queries['rweNativeUnresolved']='rweNativeUnresolved'
      writers=model.fetch('nativeWriters')
      raise 'writer family inventory incomplete' unless writers.map{|b|b['id']}.sort==%w[rc-chain rc-payload generated-entry callback-client-data still-release copy-forwarding].sort
      rows=writers.map do |b|
        raise 'writer source anchor absent' unless File.read(b['source']).include?(b['anchor'])
        [b['id'],sha.call(b['source']),Digest::SHA256.hexdigest(JSON.generate(b)),b['status']]
      end
      body.sub!('(relation rweWriterBoundary (id source contract status))','(relation rweWriterBoundary (id source contract status) ('+rows.map{|r|fact.call(r)}.join(' ')+'))')
      queries['rweWriterUnresolved']='rweWriterUnresolved'
      capacity=model.fetch('capacityBoundaries')
      raise 'capacity premise inventory incomplete' unless capacity.map{|b|b['id']}.sort==%w[copy-charge request-envelope attempt-fragmentation physical-source-pool restore-fudge known-refusal].sort
      rows=capacity.map{|b|[b['id'],Digest::SHA256.hexdigest(JSON.generate(b)),b['outcome']]}
      body.sub!('(relation rweCapacityBoundary (id contract outcome))','(relation rweCapacityBoundary (id contract outcome) ('+rows.map{|r|fact.call(r)}.join(' ')+'))')
      queries['rweCapacityUnresolved']='rweCapacityUnresolved'

    end
    if arena_mode
      rows=requirements.map{|r|[r['id'],Digest::SHA256.hexdigest(JSON.generate(r))]}
      body.sub!('(relation rweWorkerRequirement (id contract))','(relation rweWorkerRequirement (id contract) ('+rows.map{|r|fact.call(r)}.join(' ')+'))')
      body.sub!('(relation rweWorkerCandidate (source profile contract))','(relation rweWorkerCandidate (source profile contract) ('+fact.call(keys)+'))')
      queries.merge!('rweUnequalReady'=>'rweUnequalReady','rweWorkerMissing'=>'rweWorkerMissing')
    end
    d=out+'/'+scenario;FileUtils.mkdir_p(d)
    program=d+'/query.ss'
    File.write(program,"(define-evidence (query) (sources) (outputs #{queries.keys.join(" ")})\n(relation smpModernReady (id))\n"+body+"\n)\n")
    entry={schema:'ascent.evidence-dsl-entry.v1',trusted:true,constructor:'query',arguments:[],sources:[{path:program,sha256:sha.call(program)}]}
    path=d+'/entry.json';File.write(path,JSON.pretty_generate(entry)+"\n")
    output=File.expand_path(d+'/native')
    FileUtils.mkdir_p(output)
    request={rules:[],dsl:entry,dslInput:File.expand_path(path),dslInputSha256:sha.call(path),dslRoot:Dir.pwd,facts:{},queries:queries,output:output}
    file=d+'/evaluation.json';File.write(file,JSON.pretty_generate(request)+"\n")
    code='import json,sys; from gambit_smp.evidence_capabilities import native_evaluate; native_evaluate(json.load(open(sys.argv[1])))'
    stdout,stderr,status=Open3.capture3('.venv/bin/python','-c',code,file)
    File.write(d+'/adapter.log',stdout+stderr);raise 'ASCENT evaluation failed' unless status.success?
    result=JSON.parse(File.read(output+'/answers.json'))
    reduced=result.dup
    if owner_mode
      unresolved=reduced.delete('rweNativeUnresolved')
      raise 'raw native writer closure overclaimed' unless unresolved.map(&:first).sort==%w[raw-rc-and-payload nonlocal-native-exit teardown-producer].sort
      writer_missing=reduced.delete('rweWriterUnresolved')
      raise 'writer source inventory promoted to enforcement' unless writer_missing.map(&:first).sort==model.fetch('nativeWriters').map{|b|b['id']}.sort
      missing_capacity=reduced.delete('rweCapacityUnresolved')
      raise 'full physical capacity overclaimed' unless missing_capacity.map(&:first).sort==%w[copy-charge request-envelope attempt-fragmentation physical-source-pool known-refusal].sort

    end
    if arena_mode
      raise 'unequal counts admitted' unless reduced.delete('rweUnequalReady')==[]
      missing=reduced.delete('rweWorkerMissing')
      expected=requirements.map{|r|r['id']}
      expected-= (domains_mode ? %w[independent-refill resume-coverage affine-cleanup collective-split descendant-termination] : ['independent-refill']) if scenario=='all-guards'
      raise 'worker admission blocker hidden' unless missing.all?{|r|r[0,3]==keys} && missing.map(&:last).sort==expected.sort
    end
    raise 'source slice or whole-retirement overclaim' unless reduced=={relation+'Ready'=>scenario=='all-guards' ? [keys] : [],'rweRetirementReady'=>[]}
    answers[scenario]=result
  end
  files=[__FILE__,rules,lock,profile,cert,u['stderr']['path'],run+'/receipt.json',run+'/run/receipt.json',run+'/run-header.json']
  files+=%w[native_capabilities native_development source_capabilities historical_inputs].map{|name|'src/gambit_smp/'+name+'.py'}
  files+=%w[native_recipes native_development projected_source_overlay historical_inputs].map{|name|'tests/test_'+name+'.py'}
  files+=%w[project-root-worker-exit render-root-worker-exit].map{|name|'dev/modeling/tools/'+name+'.rb'}
  producer_reference=steps.fetch('producer')['arguments']['producer']
  history=JSON.parse(File.read(producer_reference)).fetch('inputArchive').fetch('path')
  files+=JSON.parse(File.read(history))['inputs'].map{|row|row['archive']}
  (origins.values+prior_runs).uniq.each do |prior|
    files+=[prior+'/receipt.json',prior+'/run/receipt.json',prior+'/run-header.json']
  end
  if owner_mode
    layout='evidence/research/worker-role-handoff/owner-still-layout-move.json'
    move=JSON.parse(File.read(layout))
    header=move.fetch('destination')
    header_key=header.delete_prefix('vendor/gambit/')
    # Historical whole-file identity belongs to the predecessor. Current
    # native input identity is independently locked; the STILL ABI subject is
    # the exact definition span, not unrelated msection metadata in this file.
    raise 'still layout move is not source-bound' unless move['exactBytesPreserved'] && l.fetch('files').fetch(header_key).fetch('candidateSha256')==sha.call(header)
    if lock=='evidence/research/section-copy-authority/source.lock.json'
      predecessor='evidence/research/section-copy-authority/memory_state.h.in'
      raise 'historical header predecessor differs' unless sha.call(predecessor)==move.fetch('destinationSha256')
      files+=%w[predecessor.json memory_state.h.in runtime_roles.h.in vm_state.h.in configured-header.gz header-review.json].map{|name|'evidence/research/section-copy-authority/'+name}
    end
    old=Zlib::GzipReader.open(move['originalArchive'], &:read)
    first=old.index('#define ___STILL_LINK 0');last=old.index("\n\n\n/* End internal memory fragment.",first)
    block=old[first...last]
    raise 'still prefix coordinates changed' unless Digest::SHA256.hexdigest(old)==move['originalSha256'] && Digest::SHA256.hexdigest(block)==move['definitionBlockSha256'] && block.bytesize==308 && File.read(header).scan(Regexp.new(Regexp.escape(block))).size==1
    files+=[layout,move['originalArchive'],'evidence/research/worker-role-handoff/native-run-abi-lineage.json','evidence/research/worker-role-handoff/native-run-abi-failure.json']
    files+=JSON.parse(File.read('evidence/research/worker-role-handoff/native-run-abi-lineage.json'))['records'].map{|r|raise 'baseline ABI excerpt drift' unless sha.call(r['archive'])==r['sha256'];r['archive']}
    JSON.parse(File.read('evidence/research/worker-role-handoff/native-run-abi-failure.json'))['records'].each{|p,h|raise 'retained ABI crash/source drift' unless sha.call(p)==h;files<<p}
  end
  files+=outer['inputs'].keys
  if lock=='evidence/research/copy-root-admission/settled-source.lock.json'
    files+=%w[runtime_roles.h.in memory_state.h.in global_state.h.in runtime_protocols.h.in configured-header.gz header-review.json qualification.recipe.json source.lock.json source.patch].map{|name|'evidence/research/copy-root-admission/'+name}
    failed='evidence/research/copy-root-admission/failed-campaign/receipt.json'
    files<<failed
    # Failure payloads have their own independently replayable repository
    # packet. Bind its receipt without nesting another copy of every gzip.
  end
  if build_run
    files+=build_outer['inputs'].keys+[build_run+'/receipt.json',build_run+'/run/receipt.json',build_run+'/run-header.json']
    build_child['steps'].each do |s|
      s.fetch('artifacts',{}).each do |name,h|
        file=build_run+'/run/'+name;raise 'incremental artifact drift' unless sha.call(file)==h
        files<<file if file.match?(/\.(?:json|stdout|stderr|log)$/)
      end
    end
  end
  files+=l['files'].keys.map{|name|'vendor/gambit/'+name}
  files+=%w[native-model-inputs.txt native-queries.tsv native-metadata.json native-projection.json sysml.log].map{|f|model_dir+'/'+f}
  files<<model_dir+'/native-inputs.json' if owner_mode
  files+=File.readlines(model_dir+'/native-model-inputs.txt',chomp:true)
  steps.each_value do |s|
    s.fetch('artifacts',{}).each do |name,h|
      file=origins.fetch(s['id'],run)+'/run/'+name;raise 'native artifact drift' unless sha.call(file)==h
      files<<file if file.match?(/\.(?:json|stdout|stderr|log)$/)
    end
  end
  records={};files.uniq.each do |p|
    h=sha.call(p);archive=out+'/'+h+'.gz'
    Zlib::GzipWriter.open(archive){|z|z.write(File.binread(p))} unless File.exist?(archive)
    records[p]={sha256:h,archive:archive}
  end
  matrix={wholeSeconds:outer['wholeSeconds'],retainedSteps:retained,freshNativeExecutions:arena_mode ? (names+%w[root-phase-kernel-test fault-calibration-test unknown-join-gc]).count{|id|origins.fetch(id)==run} : 8,retainedNativeExecutions:arena_mode ? (names+%w[root-phase-kernel-test fault-calibration-test unknown-join-gc]).count{|id|origins.fetch(id)!=run} : 0,nativeStageSeconds:n['stageSeconds'],configurationReused:n['configurationReused'],sourceCopies:0,generatedCReused:51,topologyCompiles:compiles,topologyExecutions:names.size,actualExecutions:executions,unitControls:u.fetch('tests'),configurationAction:n['configurationAction'],configurationProbesReused:n['configurationProbesReused'],unknownJoinHealthyMembers:3,unknownJoinGCs:3,unknownJoinSafetyExit:true,phaseClaimFinishPairsPerOrigin:4,oldPairsPerOrigin:1,addedCollectiveBarriers:domains_mode ? 5 : 4,heapIncrease:false,wholeRuntimeAdmitted:false,workerSourceConditions:domains_mode ? 5 : arena_mode ? 1 : 0,workerConditions:arena_mode ? 7 : 0}
  if owner_mode
    matrix[:heapIncreaseScope]='managed heap/profile limits only; native metadata accounted separately'
    matrix[:copyArbitrationCost]=model.fetch('realizations').find{|r|r['id']=='copy-before-reservation'}.fetch('overheads')
    matrix[:copyArbitrationOptimalityQualified]=false
    if lock=='evidence/research/copy-root-admission/settled-source.lock.json'
      matrix[:copyRequestCost]=model.fetch('realizations').find{|r|r['id']=='source-bounded-request'}.fetch('overheads')
      matrix[:rootAdmissionCost]=model.fetch('realizations').find{|r|r['id']=='closed-root-domain'}.fetch('overheads')
      matrix[:wholeRoundCapacityAdmitted]=false
      matrix[:arbitrarySfunWritersAdmitted]=false
      matrix[:rcDomainsExercised]=3
      matrix[:retainedFailedCampaigns]=1
    end
  end
  File.write(out+'/receipt.json',JSON.pretty_generate({scope:contract,matrix:matrix,fixedWorkspace:{path:w,device:File.stat(w).dev,inode:File.stat(w).ino},answers:answers,records:records,rootPhaseSliceQualified:!arena_mode,workerRefillSliceQualified:arena_mode,workerRootDomainSliceQualified:domains_mode,selectedWLessRVerified:domains_mode,ownerCleanupEffectsQualified:owner_mode,unequalWorkerCountsAdmitted:false,independentWorkerAllocatorAdmitted:false,retirementAdmitted:false,commitAdmitted:false})+"\n")
  puts JSON.generate(matrix:matrix,negativeGuards:guards.size,rootPhaseSliceQualified:!arena_mode,workerRefillSliceQualified:arena_mode,workerRootDomainSliceQualified:domains_mode,commitAdmitted:false)
  exit
end
b=ARGV.fetch(0); out=ARGV.fetch(1); prior_dir=ARGV[2]; limit=Integer(ARGV.fetch(3,'3')); calls=0
raise 'fresh output required' if File.exist?(out); FileUtils.mkdir_p(out+'/sources')
sha=->p { Digest::SHA256.file(p).hexdigest }
m=JSON.parse(File.read(b+'/native-projection.json'))
raise 'SysML failed' unless JSON.parse(File.read(b+'/native-metadata.json'))['exit']==0
raise 'wrong contract counts' unless m['clauses'].size==9 && m['witnesses'].size==26 && m['nativeCases'].size==5
git=->*args { s,e,x=Open3.capture3('git',*args); raise e unless x.success?; s.strip }
raise 'OTP pin drift' unless git.call('-C','vendor/erlang-otp','rev-parse','HEAD')==m['upstreamCommit'] && git.call('-C','vendor/erlang-otp','status','--porcelain').empty?
raise 'OTP gitlink drift' unless git.call('ls-files','--stage','vendor/erlang-otp').start_with?('160000 '+m['upstreamCommit']+' ')
base='evidence/research/smp-factor-conditions/validation.json'; base_receipt=JSON.parse(File.read(base))
base_receipt['records'].each do |p,r|
 raise 'retained predecessor drift '+p unless sha.call(r['path'])==r['sha256']
 # Successor Org/index views may evolve; archived observations remain immutable.
 if p.start_with?('vendor/') || p.end_with?('.sysml','.qnt','.lean','.scm')
  raise 'semantic predecessor drift '+p unless sha.call(p)==r['sha256']
 end
end
fpath=base_receipt['formal']['receipt']; f=JSON.parse(File.read(fpath)); raise 'formal receipt drift' unless sha.call(fpath)==base_receipt['formal']['sha256']
f['artifacts'].each { |p,h| raise 'formal artifact drift' unless sha.call(p)==h }
f['rows'].each { |r| raise 'formal log drift' unless r['matched'] && sha.call(File.dirname(fpath)+'/'+r['id']+'.log')==r['logSha256'] }
candidate='evidence/research/modern-c-bootstrap/request-custody-source.lock.json'
JSON.parse(File.read(candidate))['files'].each { |p,h| raise 'candidate drift' unless sha.call('vendor/gambit/'+p)==h['candidateSha256'] }
files={}; witnesses=m['witnesses'].map do |w|
 p=w['file']; h=sha.call(p); lines=File.readlines(p); lo=w['firstLine']; hi=w['lastLine']
 raise 'bad interval '+w['id'] unless lo>0 && hi>=lo && hi<=lines.size
 excerpt=out+'/sources/'+w['id']+'.txt'; File.write(excerpt,lines[(lo-1)..(hi-1)].join)
 raise 'source changed' unless sha.call(p)==h
 files[p]=h; w.merge('sha256'=>h,'excerpt'=>excerpt,'excerptSha256'=>sha.call(excerpt))
end
source=Digest::SHA256.hexdigest(JSON.generate(files.sort.to_h.merge('candidateLock'=>sha.call(candidate),'upstream'=>m['upstreamCommit'])))
profile=base_receipt['profileSha256']; raise 'profile drift' unless sha.call('evidence/fixtures/gerbil-bazel-build-profile/profile.json')==profile
lock={scope:'Selected source/caller witnesses plus existing candidate lock; not complete build closure or refinement proof',sourceDigest:source,profileSha256:profile,files:files.sort.to_h,
 upstream:{url:m['upstreamUrl'],tag:'OTP-28.0',commit:m['upstreamCommit'],tagObject:git.call('-C','vendor/erlang-otp','rev-parse','refs/tags/OTP-28.0'),tree:git.call('-C','vendor/erlang-otp','rev-parse','HEAD^{tree}'),
  checkout:'vendor/erlang-otp',sparse:true,patterns:File.read('vendor/erlang-otp/.git/info/sparse-checkout'),license:sha.call('vendor/erlang-otp/LICENSE.txt')},
 candidateLockSha256:sha.call(candidate),nativeTestsRun:false,runtimeSourceChanged:false}
FileUtils.mkdir_p(File.dirname(m['sourceLock'])); encoded=JSON.pretty_generate(lock)+"\n"
raise 'lock drift' if File.exist?(m['sourceLock']) && File.read(m['sourceLock'])!=encoded
File.write(m['sourceLock'],encoded)
File.write(out+'/source-witnesses.json',JSON.pretty_generate(witnesses)+"\n")
seed_dir='.cache/tasks/modern-c-frame-contract/cohort/smp-factor-conditions-complete'
seed=JSON.parse(File.read(seed_dir+'/receipt.json')); request_path=seed_dir+'/current.request.scm'
raise 'seed request drift' unless sha.call(request_path)==seed['scenarios']['current']['requestSha256']
envelope=File.read(request_path); selector=JSON.parse(envelope.split('(selector ',2).fetch(1).sub(/\)\)\s*\z/,''))
selector.gsub!('"smp-factor-conditions"','"root-worker-exit"')
new_outputs=%w[rweLocated rweRejected rweSupplied rweGap rweBlocked rweLocalCovered rweNativeSupplied rweNativeMissing rweRetirementReady]
selector.sub!('(outputs ','(outputs '+new_outputs.join(' ')+' ')
selector.sub!(/\)\s*\z/,File.read('dev/modeling/ascent/root-worker-exit.rules.scm')+"\n)\n")
clauses=m['clauses'].map { |c| [c['id'],c['factor_id'],Digest::SHA256.hexdigest(JSON.generate(c))] }
native=m['nativeCases'].map { |c| [c['id'],Digest::SHA256.hexdigest(JSON.generate(c))] }
data=->name,cols,rows { '(relation '+name+' ('+cols+') ('+rows.map { |r| '('+r.map { |x| JSON.generate(x.to_s) }.join(' ')+')' }.join(' ')+'))' }
parse=lambda do |text,name|
 i=text.index('("'+name+'" '); raise 'missing relation '+name unless i
 part=text[(i+name.size+4)..]; depth=0; quoted=false; escaped=false; past=nil
 part.each_char.with_index do |ch,n|
  if quoted
   if escaped then escaped=false elsif ch=='\\' then escaped=true elsif ch=='"' then quoted=false end
  elsif ch=='"' then quoted=true
  elsif ch=='(' then depth+=1
  elsif ch==')' then depth-=1; if depth==0 then past=n; break end
  end
 end
 raise 'truncated relation '+name unless past
 part[0..past].scan(/"(?:\\.|[^"\\])*"/).map { |x| JSON.parse(x) }
end
prior=prior_dir && JSON.parse(File.read(prior_dir+'/receipt.json')); results={}
names=%w[current roots-only carrier-renamed upstream-as-proof conflicting-outcome local-complete]
names.each do |name|
 evidence=name=='current' ? [] : clauses.map { |c| [c[0],'source',source,c[2],'pass'] }
 ne=name=='local-complete' ? native.map { |c| [c[0],'native',source,profile,c[1],'pass'] } : []
 case name
 when 'roots-only' then evidence.select! { |c| %w[root-before-collect frozen-root-publication].include?(c[0]) }
 when 'carrier-renamed' then evidence.reject! { |c| c[0]=='independent-copy-arena' }
 when 'upstream-as-proof' then evidence.each { |c| c[1]='upstream' }
 when 'conflicting-outcome' then row=evidence.find { |c| c[0]=='withdrawal-custody' }.dup; row[-1]='unknown'; evidence<<row
 end
 s=selector.dup
 rows={
  'rweIdentity'=>['source profile upstream',[[source,profile,m['upstreamCommit']]]],
  'rweClause'=>['id factor contract',clauses],
  'rweWitness'=>['id file digest',witnesses.map { |w| [w['id'],w['file'],w['sha256']] }],
  'rweUse'=>['clause witness',m['uses'].map { |u| [u['clause_id'],u['witness_id']] }],
  'rweDependency'=>['dependent prerequisite',m['dependencies'].map { |d| [d['dependent_id'],d['prior_id']] }],
  'rweEvidence'=>['id method source contract outcome',evidence],
  'rweNativeCase'=>['id contract',native],
  'rweNativeEvidence'=>['id method source profile contract outcome',ne],
  'rweCandidate'=>['id',[['root-worker-exit']]]
 }
 rows.each do |key,(cols,values)|
  decl='(relation '+key+' ('+cols+'))'; raise 'missing declaration '+key unless s.include?(decl); s.sub!(decl,data.call(key,cols,values))
 end
 request='((displayBytes 65536) (selector '+JSON.generate(s)+'))'+"\n"
 prev=prior && prior['scenarios'][name]; reuse=prev && prev['requestSha256']==Digest::SHA256.hexdigest(request)
 break if !reuse && calls>=limit
 File.write(out+'/'+name+'.request.scm',request)
 if reuse
  raise 'prior identity drift' unless prior['sourceDigest']==source && prior['projectionSha256']==sha.call(b+'/native-projection.json')
  raise 'prior control drift' unless sha.call(prior_dir+'/'+name+'.request.scm')==prev['requestSha256'] && sha.call(prior_dir+'/'+name+'.result.scm')==prev['resultSha256']
  stdout=File.read(prior_dir+'/'+name+'.result.scm'); stderr=File.read(prior_dir+'/'+name+'.stderr'); success=true
 else
  stdout,stderr,status=Open3.capture3('.venv/bin/gambit-smp','--task','modern-c-frame-contract','trajectory','clues',request.chomp); success=status.success?; calls+=1
 end
 File.write(out+'/'+name+'.result.scm',stdout); File.write(out+'/'+name+'.stderr',stderr)
 raise 'incomplete ASCENT '+name unless success && stdout.include?('("evaluationComplete" #t)')
 outputs=new_outputs+%w[verificationChecked verificationMissing verificationReady verificationOwnerConflict verificationSemanticOverlap verificationRoleMismatch smpBlocked smpGateMissing smpModernReady]
 v=outputs.to_h { |k| [k,parse.call(stdout,k)] }
 expected={'current'=>0,'roots-only'=>2,'carrier-renamed'=>8,'upstream-as-proof'=>0,'conflicting-outcome'=>8,'local-complete'=>9}.fetch(name)
 raise 'source routing failure' unless v['rweLocated'].size==9 && v['rweSupplied'].size==expected
 expected_covered=case name
 when 'roots-only' then %w[root-before-collect frozen-root-publication]
 when 'carrier-renamed' then %w[root-before-collect frozen-root-publication origin-task-claim]
 when 'conflicting-outcome' then clauses.map(&:first)-%w[withdrawal-custody teardown-reclamation]
 when 'local-complete' then clauses.map(&:first)
 else [] end
 raise 'dependency propagation failure' unless v['rweLocalCovered'].sort==expected_covered.sort
 raise 'missing unknown rejection' if name=='conflicting-outcome' && v['rweRejected']!=['withdrawal-custody']
 raise 'native routing failure' unless v['rweNativeSupplied'].size==(name=='local-complete' ? 5 : 0)
 raise 'original proof promotion' unless v['verificationChecked'].sort==%w[CS-COHERENCE CS-SCHEDULE] && v['verificationMissing'].size==12 && v['verificationReady'].empty?
 raise 'ownership conflict' unless %w[verificationOwnerConflict verificationSemanticOverlap verificationRoleMismatch].all? { |k| v[k].empty? }
 raise 'retirement overclaim' unless v['smpBlocked'].size==8 && v['smpGateMissing'].size==5 && v['smpModernReady'].empty? && v['rweRetirementReady'].empty?
 results[name]={synthetic:name!='current',relations:v,requestSha256:sha.call(out+'/'+name+'.request.scm'),resultSha256:sha.call(out+'/'+name+'.result.scm')}
 results[name][:reusedFrom]=prior_dir+'/receipt.json' if reuse
 File.write(out+'/receipt.json',JSON.pretty_generate({projectionSha256:sha.call(b+'/native-projection.json'),policySha256:sha.call('dev/modeling/ascent/root-worker-exit.rules.scm'),
  sourceDigest:source,profileSha256:profile,sourceLock:m['sourceLock'],sourceLockSha256:sha.call(m['sourceLock']),predecessor:base,predecessorSha256:sha.call(base),
  formalReceipt:fpath,formalReceiptSha256:sha.call(fpath),formalReexecuted:false,upstreamCommit:m['upstreamCommit'],scenarios:results,complete:results.size==names.size,
  runtimeSourceChanged:false,nativeTestsRun:false,retirementAdmitted:false,commitAdmitted:false})+"\n")
end
puts JSON.generate(completed:results.size,total:6,newCalls:calls,reused:results.size-calls,clauses:9,witnesses:witnesses.size,formalReexecuted:false,commitAdmitted:false)
