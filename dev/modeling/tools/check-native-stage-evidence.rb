require 'json'; require 'digest'; require 'fileutils'; require 'open3'; require 'zlib'

# Receipt adaptation only. SysML owns the boundary; ASCENT owns guard inference.
def evaluate_local_rules(body, out, incremental: false, admitted: false, check_reuse: nil, shared: false)
  names=%w[dxNativeReady dxActualReusePermit dxM8Retired dxFullBuildGain]
  names << 'dxIncrementalReady' if incremental
  names << 'dxCheckReusable' unless check_reuse.nil?
  names << 'dxSharedCompiledReady' if shared
  program=out+'/pending.program.ss'
  File.write(program,"(define-evidence (query) (sources) (outputs #{names.join(' ')})\n"+body+"\n)\n")
  sha=->p{Digest::SHA256.file(p).hexdigest}
  entry={schema:'ascent.evidence-dsl-entry.v1',trusted:true,constructor:'query',arguments:[],
         sources:[{path:program,sha256:sha.call(program)}]}
  file=out+'/pending.entry.json';File.write(file,JSON.pretty_generate(entry)+"\n")
  native=out+'/native';FileUtils.mkdir_p(native)
  request={rules:[],dsl:entry,dslInput:File.expand_path(file),dslInputSha256:sha.call(file),
           dslRoot:Dir.pwd,facts:{},queries:names.to_h{|n|[n,n]},output:File.expand_path(native)}
  file=out+'/pending.evaluation.json';File.write(file,JSON.pretty_generate(request)+"\n")
  code='import json,sys; from gambit_smp.evidence_capabilities import native_evaluate; native_evaluate(json.load(open(sys.argv[1])))'
  stdout,stderr,status=Open3.capture3('.venv/bin/python','-c',code,file)
  File.write(out+'/pending.native.log',stdout+stderr)
  raise 'local source-bound ASCENT evaluation failed' unless status.success?
  answers=JSON.parse(File.read(native+'/answers.json'))
  expected=names.to_h{|n|[n, admitted && n=='dxIncrementalReady' ? [['selected']] : []]}
  expected['dxCheckReusable']=check_reuse unless check_reuse.nil?
  expected['dxSharedCompiledReady']=admitted ? [['selected']] : [] if shared
  raise 'evidence gate differs from exact expected authority' unless answers==expected
  answers
end

if ARGV.first == '--shared'
  _, projection, control, candidate, out = ARGV
  raise 'projection, control, candidate and fresh output required' unless out && !File.exist?(out)
  sha=->p{Digest::SHA256.file(p).hexdigest}
  model=JSON.parse(File.read(projection));contract=model.fetch('sharedFixtures').fetch(0)
  pairs=contract.fetch('producerConsumers').split(';').map{|s|s.split('->').map(&:strip)}
  guards=%w[direct-live-producer source-and-artifact-match toolchain-match original-cwd-match runtime-match successful-compile three-compiles-five-executions same-workspace-budgets]
  raise 'shared guards missing from SysML' unless guards.all?{|g|contract['qualification'].include?(g)}
  controls='evidence/research/darwin-native-stage/shared-fixture-controls.json'
  unit=JSON.parse(File.read(controls))
  raise 'current source-bound control certificate required' unless unit['tests']==113 && unit['exit']==0 && unit['nativeAccepted']==false
  unit.fetch('sourceHashes').each{|f,h|raise 'unit control source changed' unless sha.call(f)==h}
  %w[python stderr].each{|k|v=unit.fetch(k);raise 'unit interpreter/log changed' unless sha.call(v.fetch('path'))==v.fetch('sha256')}
  model_dir='.cache/tasks/modern-c-frame-contract/cohort/native-stage-model'
  metadata=JSON.parse(File.read(model_dir+'/native-metadata.json'))
  raise 'successful native SysML validation required' unless metadata['exit']==0 && (metadata['errors'] || []).empty?
  files=[projection,'dev/modeling/ascent/darwin-cost.rules.scm',controls,unit['stderr']['path'],
         __FILE__,'dev/modeling/tools/render-native-artifact-boundaries.rb',
         'src/gambit_smp/native_capabilities.py','src/gambit_smp/recipes.py',
         'src/gambit_smp/bootstrap_artifacts.py','tests/test_native_executable.py',
         'dev/architecture/toolchain/native-stage-design.org','dev/architecture/toolchain/index.org',
         'dev/architecture/toolchain/macos-development-map.org',
         'dev/architecture/toolchain/diagrams/macos-development.d2',
         'dev/architecture/toolchain/diagrams/macos-development.svg']
  files += File.readlines(model_dir+'/native-model-inputs.txt',chomp:true)
  files += %w[read-native.sh native-model-inputs.txt native-queries.tsv native-metadata.json sysml.log].map{|f|model_dir+'/'+f}
  read=->path,native_id,expected_compiles do
    op=path+'/receipt.json';cp=path+'/run/receipt.json';o=JSON.parse(File.read(op));c=JSON.parse(File.read(cp))
    raise 'completed bounded observation required' unless o['outcome']=='PASS' && o['exit']==0 && o['timeout']==false && o['parentReaped'] && o['processGroupQuiescent'] && o['budgetSeconds']==600 && o['wholeSeconds']<=600 && o['childReceiptSha256']==sha.call(cp) && c['inputsStable']
    n=c['steps'].find{|s|s['id']==native_id}
    raise 'fixed native workspace not reused' unless n && n['outcome']=='PASS' && !n.key?('reused') && n['configurationReused'] && n['workspace']['sourceCopies']==0 && n['observedNativeRecipeLines']==[] && n['observedGenerationRecipeLines']==[]
    t=c['steps'].select{|s|s['capability']=='gambit.executable-test'}
    raise 'five fresh test steps required' unless t.size==5 && t.all?{|s|s['outcome']=='PASS' && !s.key?('reused') && s['budgetSeconds']==90}
    compiles=t.flat_map{|s|s['commands'].select{|v|v['stage']=='compile-executable'}}
    executions=t.map{|s|s['commands'].select{|v|v['stage']=='run-executable'}}
    raise 'wrong actual compilation/execution count' unless compiles.size==expected_compiles && executions.all?{|v|v.size==1} && executions.flatten.map{|v|v['pid']}.uniq.size==5
    (compiles+executions.flatten).each do |v|
      raise 'failed, unknown or over-budget process' unless v['exit']==0 && v['timeout']==false && v['parentReaped'] && v['processGroupQuiescent'] && v['seconds']<=v['effectiveBudgetSeconds']
    end
    c['steps'].each do |s|
      s.fetch('artifacts',{}).each do |name,h|
        file=path+'/run/'+name;raise 'retained artifact drift' unless sha.call(file)==h
        files << file if file.match?(/\.(?:json|log|stdout|stderr)$/)
      end
    end
    files += [op,cp,path+'/run-header.json']
    {path:path,engine:o['engineId'],inputs:o['inputs'].reject{|k,_|k.end_with?('.recipe.json')},
     native:n,tests:t,wholeSeconds:o['wholeSeconds'],compiles:compiles.size,executions:5,
     compileSeconds:compiles.sum{|v|v['seconds']},executionSeconds:executions.flatten.sum{|v|v['seconds']},fixtureSeconds:t.sum{|s|s['stageSeconds']}}
  end
  baseline=read.call(control,'native-stage-shared-control',5)
  selected=read.call(candidate,'native-stage-shared',3)
  raise 'different control inputs or engine' unless baseline[:engine]==selected[:engine] && baseline[:inputs]==selected[:inputs]
  raise 'native runs did not bind current unit certificate' unless selected[:inputs][controls]==sha.call(controls)
  selected[:inputs].each{|f,h|raise 'native input changed before source archiving' unless sha.call(f)==h}
  files += selected[:inputs].keys
  files += [control,candidate].map{|p|JSON.parse(File.read(p+'/receipt.json'))['inputs'].keys.find{|k|k.end_with?('.recipe.json')}}
  %w[workspace identity].each{|k|raise 'runtime workspace or content differs' unless baseline[:native]['outputs']['runtime'][k]==selected[:native]['outputs']['runtime'][k]}
  workspace=selected[:native]['workspace']['delta']['source'];state=File.stat(workspace)
  raise 'source workspace is an alias' unless File.realpath(workspace)==workspace
  fixed_workspace={path:workspace,device:state.dev,inode:state.ino}
  ids=selected[:tests].to_h{|s|[s['id'],s]};old=baseline[:tests].to_h{|s|[s['id'],s]}
  raise 'program or executable identity changed' unless ids.all?{|id,s|s['programSha256']==old[id]['programSha256'] && s['executableSha256']==old[id]['executableSha256']}
  manifests=[]
  pairs.each do |producer,consumer|
    p,t=ids.fetch(producer),ids.fetch(consumer)
    raise 'producer/consumer sharing absent' unless p['arguments']['publishCompilation'] && p['compilationLaunched'] && !p['compilationReused'] && t['compilationReused'] && !t['compilationLaunched'] && t['arguments']['compilation']=={'step'=>producer,'output'=>'compilation'} && t['dependsOn'].include?(producer)
    path=candidate+'/run/'+p['outputs']['compilation']['path'];m=JSON.parse(File.read(path));manifests<<sha.call(path)
    actual=p['commands'].find{|v|v['stage']=='compile-executable'};run=t['commands'].find{|v|v['stage']=='run-executable'}
    cwd=File.expand_path(candidate+'/run/'+producer)
    raise 'original context not retained' unless m['scope']=='same-recipe-compiled-fixture' && m['run']==File.expand_path(candidate+'/run') && m['step']==producer && m['cwd']==cwd && run['cwd']==cwd && run['argv']==[cwd+'/fixture'] && m['command']==actual && t['compilationOrigin']['processReceiptSha256']==m['processReceiptSha256']
    raise 'source or output binding differs' unless sha.call(cwd+'/fixture.scm')==m['source']['sha256'] && sha.call(cwd+'/fixture')==m['executable']['sha256'] && m['program']['sha256']==t['programSha256'] && m['executable']['sha256']==t['executableSha256']
    raise 'runtime binding differs' unless m['runtime']['tree']==selected[:native]['outputs']['runtime']['identity'] && m['runtime']['candidateSha256']==t['candidateReceiptSha256']
    raise 'compile receipt drift' unless sha.call(cwd+'/compile-executable.process.json')==m['processReceiptSha256']
    m['tools'].each_value{|v|raise 'tool bytes changed' unless sha.call(v['path'])==v['sha256']}
    m['compilerInputs'].each{|name,h|raise 'frontend/source bytes changed' unless sha.call(name)==h}
    raw=JSON.parse(File.read(cwd+'/compile-executable.process.json'))
    raise 'successful original compile not independently observed' unless raw['state']=='OBSERVED' && raw['exit']==0 && raw['timeout']==false && raw['parentReaped'] && raw['processGroupQuiescent'] && actual.all?{|k,v|raw[k]==v}
    raise 'consumer did not bind producer observations' unless t['observedInputs'][File.expand_path(path)]==sha.call(path) && t['observedInputs'][cwd+'/compile-executable.process.json']==m['processReceiptSha256']
    files << path
  end
  FileUtils.mkdir_p(out);base=File.read('dev/modeling/ascent/darwin-cost.rules.scm')
  policy=model.fetch('validationReuse').map{|v|'('+[v['checkId'],v['lifetime'],v['reuseStatus']].map(&:to_json).join(' ')+')'}.join(' ')
  base.sub!('(relation dxCheckPolicy (check lifetime status))','(relation dxCheckPolicy (check lifetime status) ('+policy+'))') || raise('missing reuse DSL policy')
  key=Digest::SHA256.hexdigest(JSON.generate(manifests))
  %w[Prior Current].each do |name|
    base.sub!('(relation dxCheck'+name+' (case check key))','(relation dxCheck'+name+' (case check key) (("selected" "fixture-compilation" '+key.to_json+')))') || raise('missing artifact DSL identity')
  end
  base.sub!('(relation dxCheckLiveScope (case check lifetime))','(relation dxCheckLiveScope (case check lifetime) (("selected" "fixture-compilation" "same-recipe-compiled-artifact")))') || raise('missing live scope DSL input')
  results={}
  (['all-guards']+guards).each do |scenario|
    active=scenario=='all-guards' ? guards : guards-[scenario]
    body=base.dup;facts=active.map{|g|'("selected" '+g.to_json+')'}.join(' ')
    body.sub!('(relation dxSharedGuard (id guard))','(relation dxSharedGuard (id guard) ('+facts+'))') || raise('missing shared DSL input')
    directory=out+'/'+scenario;FileUtils.mkdir_p(directory)
    results[scenario]=evaluate_local_rules(body,directory,shared:true,admitted:scenario=='all-guards',check_reuse:scenario=='all-guards' ? [['selected','fixture-compilation']] : [])
  end
  records={};files.uniq.each do |file|
    h=sha.call(file);target=out+'/'+h+'.gz'
    Zlib::GzipWriter.open(target){|z|z.write(File.binread(file))} unless File.exist?(target)
    records[file]={sha256:h,archive:target}
  end
  rows=[baseline,selected].map{|r|r.reject{|k,_|%i[native tests inputs].include?(k)}}
  File.write(out+'/receipt.json',JSON.pretty_generate({modelContract:contract,matrix:rows,fixedWorkspace:fixed_workspace,unitControls:{tests:unit['tests'],sourceCount:unit['sourceHashes'].size,certificateSha256:sha.call(controls)},sharedManifestSha256:manifests,guards:guards,answers:results,records:records,sameRecipeSharingQualified:true,genericCompilationCacheAdmitted:false,runtimeArchitectureAdmitted:false,commitAdmitted:false})+"\n")
  puts JSON.generate(matrix:rows,negativeControls:guards.size,sameRecipeSharingQualified:true,commitAdmitted:false)
  exit
end

if ARGV.first == '--cost'
  _, projection, historical, current, out = ARGV
  raise 'projection, two actual runs and fresh output required' unless out && !File.exist?(out)
  sha=->p{Digest::SHA256.file(p).hexdigest}
  model=JSON.parse(File.read(projection)).fetch('validationReuse')
  raise 'six SysML reuse boundaries required' unless model.size==6
  files=[projection,'dev/modeling/ascent/darwin-cost.rules.scm']
  summarize=->path,id do
    outer_path=path+'/receipt.json';child_path=path+'/run/receipt.json'
    outer=JSON.parse(File.read(outer_path));child=JSON.parse(File.read(child_path))
    raise 'completed stable bounded observation required' unless outer['outcome']=='PASS' && outer['exit']==0 && outer['timeout']==false && outer['parentReaped'] && outer['processGroupQuiescent'] && outer['budgetSeconds']==600 && outer['wholeSeconds']<=600 && outer['childReceiptSha256']==sha.call(child_path) && child['inputsStable']
    steps=child.fetch('steps');native=steps.find{|s|s['id']==id}
    raise 'actual native Make required' unless native && !native.key?('origin') && native['outcome']=='PASS' && native['observedNativeRecipeLines']==[] && native['observedGenerationRecipeLines']==[] && native['configurationReused'] && native['workspace']['sourceCopies']==0
    raise 'both Make phases must execute' unless %w[phase3 phase4].all?{|n|native['commands'].any?{|c|c['stage']==n}}
    tests=steps.select{|s|s['capability']=='gambit.executable-test'}
    raise 'five fresh compiled tests required' unless tests.size==5 && tests.all?{|s|s['outcome']=='PASS' && s['compilationLaunched'] && !s.key?('origin')}
    seconds=->rows,names{rows.sum{|s|s.fetch('commands',[]).select{|c|names.include?(c['stage'])}.sum{|c|c['seconds']}}}
    partitions={
      nativeMake:seconds.call([native],%w[phase3 phase4]),
      nativeToolProbes:seconds.call([native],%w[compiler-version compiler-backend]),
      nativeOutsideProcesses:native['stageSeconds']-seconds.call([native],native['commands'].map{|c|c['stage']}),
      fixtureCompilations:seconds.call(tests,%w[compile-executable]),
      fixtureExecutions:seconds.call(tests,%w[run-executable]),
      fixtureToolProbes:seconds.call(tests,%w[compiler-version compiler-backend]),
      fixtureOutsideProcesses:tests.sum{|s|s['stageSeconds']}-seconds.call(tests,tests.flat_map{|s|s['commands'].map{|c|c['stage']}}),
      producer:steps.find{|s|s['id']=='producer'}['stageSeconds'],
      ascentVerdict:steps.find{|s|s['id']=='verdict'}['stageSeconds'],
      finalizationChecks:child.fetch('finalizationCheckSeconds',0),
      evaluationOwnerClose:child.fetch('evaluationOwnerFinalizationSeconds',0),
      orchestrationResidual:child['wholeSeconds']-steps.sum{|s|s['stageSeconds']}-child.fetch('finalizationCheckSeconds',0)-child.fetch('evaluationOwnerFinalizationSeconds',0),
      outerSupervisor:outer['wholeSeconds']-child['wholeSeconds']}
    raise 'nonconserving time attribution' unless partitions.values.all?{|v|v.finite? && v>=0} && (partitions.values.sum-outer['wholeSeconds']).abs<0.00001
    steps.each do |s|
      s.fetch('artifacts',{}).each do |name,h|
        file=path+'/run/'+name;raise 'observed bytes drifted' unless sha.call(file)==h
        files << file if file.match?(/\.(?:json|log|stdout|stderr)$/)
      end
    end
    files += [outer_path,child_path,path+'/run-header.json']
    {path:path,wholeSeconds:outer['wholeSeconds'],partitionSeconds:partitions,
     checkpointSteps:child.fetch('checkpointConsumption',{}).fetch('reusedSteps',[]),
     native:native,tests:tests}
  end
  old=summarize.call(historical,'native-stage-no-change');now=summarize.call(current,'native-stage-cost')
  raise 'different workspace' unless old[:native]['outputs']['runtime']['workspace']==now[:native]['outputs']['runtime']['workspace']
  timings=now[:native].fetch('costBreakdownSeconds');checks=now[:native].fetch('treeValidationCost')
  raise 'missing or double-charged native phases' unless timings.size==8 && timings.values.all?{|v|v>=0} && timings.values.sum<=now[:native]['stageSeconds']
  raise 'lease checks not measured' unless checks['reused']>0 && checks['full_reads']>0 && checks['final_reads']>0
  proof=->run{run[:native].fetch('observedInputs').select{|name,_|name.end_with?('/configure-proof.json')}}
  raise 'configuration proof identity changed' unless proof.call(old).size==1 && proof.call(old)==proof.call(now)
  proof.call(now).each_key{|p|files << p}
  FileUtils.mkdir_p(out)
  base=File.read('dev/modeling/ascent/darwin-cost.rules.scm')
  policy=model.map{|v|'('+[v['checkId'],v['lifetime'],v['reuseStatus']].map(&:to_json).join(' ')+')'}.join(' ')
  base.sub!('(relation dxCheckPolicy (check lifetime status))','(relation dxCheckPolicy (check lifetime status) ('+policy+'))') || raise('missing policy DSL input')
  keys={'configuration-proof'=>proof.call(now).values[0],
        'leased-tree-identity'=>Digest::SHA256.hexdigest(JSON.generate(now[:native]['outputs']['runtime']['identity']))}
  expected=keys.keys.sort.map{|k|['selected',k]}
  results={}
  %w[exact key-mismatch scope-closed open-components].each do |scenario|
    selected=keys.dup
    if scenario=='open-components'
      model.each{|v|selected[v['checkId']]||='counterfactual-equal-key'}
    end
    body=base.dup
    %w[Prior Current].each do |which|
      facts=selected.map do |k,h|
        h='different-key' if scenario=='key-mismatch' && which=='Current' && k=='configuration-proof'
        '('+['selected',k,h].map(&:to_json).join(' ')+')'
      end.join(' ')
      name='dxCheck'+which
      body.sub!('(relation '+name+' (case check key))','(relation '+name+' (case check key) ('+facts+'))') || raise('missing identity DSL input')
    end
    scopes=scenario=='scope-closed' ? [] : model.select{|v|selected.key?(v['checkId'])}
    facts=scopes.map{|v|'('+['selected',v['checkId'],v['lifetime']].map(&:to_json).join(' ')+')'}.join(' ')
    body.sub!('(relation dxCheckLiveScope (case check lifetime))','(relation dxCheckLiveScope (case check lifetime) ('+facts+'))') || raise('missing scope DSL input')
    want=case scenario;when 'scope-closed' then [];when 'key-mismatch' then [['selected','leased-tree-identity']];else expected;end
    directory=out+'/'+scenario;FileUtils.mkdir_p(directory)
    results[scenario]={synthetic:scenario!='exact',answers:evaluate_local_rules(body,directory,check_reuse:want)}
  end
  records={}
  files.uniq.each do |file|
    h=sha.call(file);target=out+'/'+h+'.gz'
    Zlib::GzipWriter.open(target){|z|z.write(File.binread(file))} unless File.exist?(target)
    records[file]={sha256:h,archive:target}
  end
  matrix=[old,now].map{|r|r.reject{|k,_|%i[native tests].include?(k)}}
  duplicate_pairs=[old,now].map do |r|
    by_id=r[:tests].to_h{|s|[s['id'],s]}
    pairs=[%w[wide-map wide-map-host],%w[worker-roles worker-roles-host]].map do |a,b|
      x,y=by_id.fetch(a),by_id.fetch(b)
      compile=->s{s['commands'].find{|c|c['stage']=='compile-executable'}}
      {pair:[a,b],sameProgramBytes:x['programSha256']==y['programSha256'],
       sameExecutableBytes:x['executableSha256']==y['executableSha256'],
       sameCompileEnvironment:compile.call(x)['environment']==compile.call(y)['environment'],
       sameCwd:compile.call(x)['cwd']==compile.call(y)['cwd'],
       secondCompileSeconds:compile.call(y)['seconds']}
    end
    {path:r[:path],pairs:pairs,secondCompileSeconds:pairs.sum{|p|p[:secondCompileSeconds]}}
  end
  current_child=JSON.parse(File.read(current+'/run/receipt.json'))
  tree_costs=current_child['steps'].select{|s|s.key?('treeValidationCost')}.to_h{|s|[s['id'],s['treeValidationCost']]}
  File.write(out+'/receipt.json',JSON.pretty_generate({matrix:matrix,nativePhaseSeconds:timings,treeValidationByStage:tree_costs,duplicateCompilationPairs:duplicate_pairs,reusePolicies:model,answers:results,records:records,optimizationImplemented:false,fixtureCacheAdmitted:false,freshExecutions:5,runtimeArchitectureAdmitted:false,commitAdmitted:false})+"\n")
  puts JSON.generate(matrix:matrix,nativePhaseSeconds:timings,reuseCases:results.size,fixtureCacheAdmitted:false,commitAdmitted:false)
  exit
end

if ARGV.first == '--incremental'
  _, projection, first, unchanged, leaf, out = ARGV
  raise 'projection, three runs and fresh output required' unless out && !File.exist?(out)
  sha=->p{Digest::SHA256.file(p).hexdigest}
  model=JSON.parse(File.read(projection)).fetch('nativeStages').fetch(0)
  guards=%w[same-workspace authenticated-generation same-config-no-processes zero-core-generation nochange-zero-native cleaf-only-consumers fixtures-pass budgets-preserved]
  raise 'incremental guards missing from SysML' unless guards.all?{|g|model.fetch('qualification').include?(g)}
  files=[projection,'dev/modeling/ascent/darwin-cost.rules.scm']
  runs=[first,unchanged,leaf].zip(%w[native-stage native-stage-no-change native-stage-c-leaf]).map do |path,id|
    outer_path=path+'/receipt.json'; child_path=path+'/run/receipt.json'
    outer=JSON.parse(File.read(outer_path));child=JSON.parse(File.read(child_path))
    raise 'completed bounded run required' unless outer['outcome']=='PASS' && outer['exit']==0 && outer['timeout']==false && outer['parentReaped'] && outer['processGroupQuiescent'] && outer['budgetSeconds']==600 && outer['wholeSeconds']<=600 && outer['childReceiptSha256']==sha.call(child_path) && child['inputsStable']==true
    stage=child.fetch('steps').find{|s|s['id']==id} || raise('native stage absent')
    raise 'native step was replayed or failed' unless stage['outcome']=='PASS' && !stage.key?('origin') && stage['budgetSeconds']==400
    producer=child['steps'].find{|s|s['id']=='producer'}
    raise 'producer not authenticated' unless producer['outcome']=='PASS' && producer['fullProducerValidations']==1
    raise 'workspace was copied' unless stage['workspace']['stableWorkspace'] && stage['workspace']['sourceCopies']==0
    raise 'generation changed' unless stage['generatedArtifactsStable'] && stage['originalProducerUnchanged'] && stage['generationEntryDisabledDuringNative'] && stage['observedGenerationRecipeLines']==[]
    commands=stage.fetch('commands')
    raise 'Make was not actually invoked' unless %w[phase3 phase4].all?{|n|commands.any?{|c|c['stage']==n}}
    process=%w[aclocal autoconf configure phase3 phase4].map do |name|
      file=path+'/run/'+id+'/'+name+'.process.json'
      next unless File.file?(file)
      p=JSON.parse(File.read(file))
      raise 'uncompleted/over-budget process' unless p['state']=='OBSERVED' && p['exit']==0 && p['timeout']==false && p['seconds']<=p['effectiveBudgetSeconds']
      files << file
      [name,p['seconds']]
    end.compact.to_h
    fixtures=child['steps'].select{|s|%w[map wide-map wide-map-host worker-roles worker-roles-host].include?(s['id'])}
    raise 'five real fixture compilations required' unless fixtures.size==5 && fixtures.all?{|s|s['outcome']=='PASS' && s['compilationLaunched'] && !s.key?('origin')}
    child['steps'].each do |s|
      s.fetch('artifacts',{}).each do |name,digest|
        file=path+'/run/'+name
        raise 'retained step artifact changed' unless sha.call(file)==digest
        files << file if file.match?(/\.(?:json|log|stdout|stderr)$/)
      end
    end
    files += [outer_path,child_path,path+'/run-header.json']
    {path:path,engine:outer['engineId'],wholeSeconds:outer['wholeSeconds'],stage:stage,
     processSeconds:process,fixtureSeconds:fixtures.sum{|s|s['stageSeconds']},fixtures:fixtures.size}
  end
  raise 'different execution implementation' unless runs.map{|r|r[:engine]}.uniq.size==1
  stages=runs.map{|r|r[:stage]}
  raise 'workspace changed' unless stages.map{|s|s['outputs']['runtime']['workspace']}.uniq.size==1
  %w[generationInputs generatedArtifacts].each{|key|raise 'generation identity changed' unless stages.map{|s|s[key]}.uniq.size==1}
  raise 'first configuration was not exercised' unless stages[0]['configurationReused']==false && %w[aclocal autoconf configure].all?{|n|runs[0][:processSeconds].key?(n)}
  runs.drop(1).each do |r|
    raise 'configuration repeated' unless r[:stage]['configurationReused'] && %w[aclocal autoconf configure].none?{|n|r[:processSeconds].key?(n)}
    raise 'native parameters changed' unless r[:stage]['nativeParametersChanged']==false && r[:stage]['nativeOutputsInvalidated']==[]
  end
  raise 'no-change native work repeated' unless stages[1]['observedNativeRecipeLines']==[] && stages[1]['objectBytesChanged']==[]
  delta=stages[2]['nativeDelta'];raise 'not a real single C edit' unless delta.keys==['lib/_mem/configuration.inc'] && delta.values[0]['before']!=delta.values[0]['after']
  lines=stages[2]['observedNativeRecipeLines']
  raise 'C edit rebuilt unrelated consumers' unless lines.size==3 && lines.count{|s|s.include?(' -c -o mem.o ')}==1 && lines.count{|s|s.include?(' -o gsi ')}==1 && lines.count{|s|s.include?(' -o gsc ')}==1
  FileUtils.mkdir_p(out)
  results={}
  (['all-guards']+guards).each do |scenario|
    active=scenario=='all-guards' ? guards : guards-[scenario]
    body=File.read('dev/modeling/ascent/darwin-cost.rules.scm')
    body.sub!('(relation dxNativeStage (id demand))','(relation dxNativeStage (id demand) (("selected" "reuse-explicit-artifact")))') || raise('missing stage DSL input')
    facts=active.map{|g|'("selected" '+g.to_json+')'}.join(' ')
    body.sub!('(relation dxNativeGuard (id guard))','(relation dxNativeGuard (id guard) ('+facts+'))') || raise('missing guard DSL input')
    directory=out+'/'+scenario;FileUtils.mkdir_p(directory)
    results[scenario]=evaluate_local_rules(body,directory,incremental:true,admitted:scenario=='all-guards')
  end
  records={}
  files.uniq.each do |file|
    h=sha.call(file);target=out+'/'+h+'.gz'
    Zlib::GzipWriter.open(target){|z|z.write(File.binread(file))} unless File.exist?(target)
    records[file]={sha256:h,archive:target}
  end
  matrix=runs.map do |r|
    s=r[:stage]
    {run:r[:path],wholeSeconds:r[:wholeSeconds],nativeStageSeconds:s['stageSeconds'],processSeconds:r[:processSeconds],configurationReused:s['configurationReused'],coreGenerationRecipes:s['observedGenerationRecipeLines'].size,nativeRecipes:s['observedNativeRecipeLines'].size,sourceCopies:s['workspace']['sourceCopies'],fixtures:r[:fixtures],fixtureSeconds:r[:fixtureSeconds]}
  end
  File.write(out+'/receipt.json',JSON.pretty_generate({modelContract:model,matrix:matrix,guards:guards,answers:results,records:records,selectedIncrementalWorkQualified:true,historicalAutoconfCause:'unresolved; timeout not reproduced',runtimeArchitectureAdmitted:false,m8Retired:false,commitAdmitted:false})+"\n")
  puts JSON.generate(matrix:matrix,negativeControls:guards.size,m8Retired:false,commitAdmitted:false)
  exit
end

if ARGV.first == '--pending'
  _, projection, failure, out = ARGV
  raise 'projection, failed run and fresh output required' unless out && !File.exist?(out)
  model = JSON.parse(File.read(projection)).fetch('nativeStages').fetch(0)
  outer_path = failure + '/receipt.json'; child_path = failure + '/run/receipt.json'
  outer = JSON.parse(File.read(outer_path)); child = JSON.parse(File.read(child_path))
  sha = ->p { Digest::SHA256.file(p).hexdigest }
  raise 'not a bound failed native case' unless outer['outcome'] != 'PASS' && outer['childReceiptSha256'] == sha.call(child_path)
  producer = child.fetch('steps').find { |s| s['id'] == 'producer' }
  guards = producer['outcome'] == 'PASS' && producer['fullProducerValidations'] == 1 ? ['authenticated-producer'] : []
  FileUtils.mkdir_p(out)
  body = File.read('dev/modeling/ascent/darwin-cost.rules.scm')
  body.sub!('(relation dxNativeStage (id demand))', '(relation dxNativeStage (id demand) (("pending" "reuse-explicit-artifact")))') || raise('missing DSL stage input')
  facts = guards.map { |g| '("pending" ' + g.to_json + ')' }.join(' ')
  body.sub!('(relation dxNativeGuard (id guard))', '(relation dxNativeGuard (id guard) (' + facts + '))') || raise('missing DSL guard input')
  selector = '(define-evidence (query) (sources clue factor binding) (outputs question dxNativeReady dxActualReusePermit dxM8Retired dxFullBuildGain) (include clue-selection-schema)' + "\n" + body + "\n(relation question (claim) ((\"pending-native-stage\")))\n)"
  request = '((displayBytes 65536) (selector ' + selector.to_json + '))'
  File.write(out + '/pending.request.scm', request + "\n")
  answers=evaluate_local_rules(body,out)
  records = {}
  files=[outer_path, child_path, failure + '/run-header.json',
         '.cache/tasks/modern-c-frame-contract/cohort/native-stage-host-load.json']
  %w[producer native-stage].each do |stage|
    files += Dir.glob(failure+'/run/'+stage+'/*').select{|p|File.file?(p) && p.match?(/\.(?:json|stdout|stderr|log)$/)}
  end
  route='.cache/tasks/modern-c-frame-contract/cohort/native-development-workspace.json'
  if File.file?(route)
    files << route
    workspace=JSON.parse(File.read(route)).fetch('workspace')
    files << File.join(File.dirname(workspace),'source-state.json')
  end
  files.uniq.each do |file|
    digest = sha.call(file); target = out + '/' + digest + '.gz'
    Zlib::GzipWriter.open(target) { |z| z.write(File.binread(file)) }
    records[file] = {sha256: digest, archive: target}
  end
  File.write(out + '/receipt.json', JSON.pretty_generate({model: {path: projection, sha256: sha.call(projection)},
    modelContract: model, nativeCaseOutcome: outer['outcome'], authenticatedGuards: guards,
    records: records, answers: answers, selectedReady: false, synthetic: false, regenerationControl: 'unresolved',
    ordinaryMakeControl: 'unresolved', m8Retired: false, commitAdmitted: false}) + "\n")
  puts JSON.generate(nativeCaseOutcome: outer['outcome'], authenticatedGuards: guards, selectedReady: false)
  exit
end
projection, reuse_path, regenerate_path, ordinary_path, out = ARGV
raise 'projection, three native runs and fresh output required' unless out && !File.exist?(out)
sha = ->p { Digest::SHA256.file(p).hexdigest }
model = JSON.parse(File.read(projection)).fetch('nativeStages').fetch(0)
raise 'missing modeled qualification' unless model.fetch('qualification').include?('ordinary incremental Make')
FileUtils.mkdir_p(out)
records = {}
read_run = lambda do |name, path|
  outer_path = path + '/receipt.json'; child_path = path + '/run/receipt.json'
  outer = JSON.parse(File.read(outer_path)); child = JSON.parse(File.read(child_path))
  raise 'native run not successful' unless outer['outcome'] == 'PASS' && outer['exit'] == 0 && !outer['timeout'] && child['outcome'] == 'PASS'
  raise 'child receipt drift' unless outer.fetch('childReceiptSha256') == sha.call(child_path)
  step = child.fetch('steps').find { |s| s['id'] == 'native-stage' }
  producer = child.fetch('steps').find { |s| s['id'] == 'producer' }
  raise 'incomplete native steps' unless child['steps'].size == 8 && child['steps'].all? { |s| s['outcome'] == 'PASS' }
  raise 'producer custody lost' unless producer['fullProducerValidations'] == 1 && producer['originalProducerUnchanged'] && step['originalProducerUnchanged']
  raise 'generated bytes not stable' unless step['generatedArtifactsStable']
  %w[native_development generation_artifacts].each do |component|
    raise 'source refinement differs from sealed executor' unless sha.call(outer.fetch('engine') + '/python/gambit_smp/' + component + '.py') == sha.call('src/gambit_smp/' + component + '.py')
  end
  # Bind every retained subprocess stream, not a caller-supplied PASS string.
  child['steps'].each do |s|
    s.fetch('artifacts', {}).each do |relative, digest|
      next unless relative.match?(/\.(?:json|stdout|stderr|log)$/)
      file = path + '/run/' + relative
      raise 'retained stream missing' unless File.file?(file)
      raise 'retained artifact drift' unless sha.call(file) == digest
      target = out + '/records/' + digest + '.gz'
      FileUtils.mkdir_p(File.dirname(target))
      Zlib::GzipWriter.open(target) { |z| z.write(File.binread(file)) } unless File.exist?(target)
      records[file] = {sha256: digest, archive: target}
    end
  end
  [outer_path, child_path].each do |file|
    digest = sha.call(file); target = out + '/records/' + digest + '.gz'
    FileUtils.mkdir_p(File.dirname(target))
    Zlib::GzipWriter.open(target) { |z| z.write(File.binread(file)) } unless File.exist?(target)
    records[file] = {sha256: digest, archive: target}
  end
  controls = File.read(path + '/run/native-stage/typed-argv-controls.stdout')
  %w[NATIVE-ARGV-CONTROLS-PASS NATIVE-ARGV-LEGACY-L1-PASS NATIVE-ARGV-MAKE-L1-PASS NATIVE-ARGV-REAL-COMPILER-PASS].each do |marker|
    raise 'independent mode qualification absent' unless controls.include?(marker)
  end
  fixtures = child['steps'].select { |s| %w[map wide-map wide-map-host worker-roles worker-roles-host].include?(s['id']) }
  raise 'rebuilt fixture compilation absent' unless fixtures.size == 5 && fixtures.all? { |s| s['compilationLaunched'] }
  {name: name, outer: outer, child: child, stage: step, fixtures: fixtures,
   bindings: outer.fetch('inputs'), outerReceipt: {path: outer_path, sha256: sha.call(outer_path)},
   childReceipt: {path: child_path, sha256: sha.call(child_path)}, modeControls: controls}
end
runs = [read_run.call('reuse', reuse_path), read_run.call('regenerate', regenerate_path), read_run.call('ordinary-make', ordinary_path)]
reuse = runs[0][:stage]
raise 'wrong demand controls' unless runs.map { |r| r[:stage]['generationDemand'] } == %w[reuse-explicit-artifact regenerate-control native-make-control]
raise 'different execution engine' unless runs.map { |r| r[:outer]['engineId'] }.uniq.size == 1
# Recipe demand files differ deliberately; all other declared inputs must agree.
input_sets = runs.map { |r| r[:bindings].reject { |p, _| p.end_with?('.recipe.json') } }
raise 'different selected input identities' unless input_sets.uniq.size == 1
raise 'current declared source differs' unless input_sets[0].all? { |path, digest| sha.call(path) == digest }
raise 'different native leaf delta' unless runs.map { |r| r[:stage]['nativeDelta'] }.uniq.size == 1
raise 'different generation inputs or artifacts' unless %w[generationInputs generatedArtifacts].all? { |key| runs.map { |r| r[:stage].fetch(key) }.uniq.size == 1 }
raise 'reuse generated core work' unless reuse['generationGate'] == 'directory-denial' && reuse['generationEntryDisabledDuringNative'] && reuse['observedGenerationRecipeLines'].empty?
raise 'regeneration control did not regenerate' unless runs[1][:stage]['generationPhasesRequested'] == %w[phase1 phase2] && !runs[1][:stage]['observedGenerationRecipeLines'].empty?
guards = %w[authenticated-producer current-scheme-equal generation-entry-disabled generated-bytes-stable rebuilt-consumer-tested independent-regeneration-equal]
results = {}
(['all-guards'] + guards).each do |scenario|
  active = scenario == 'all-guards' ? guards : guards - [scenario]
  body = File.read('dev/modeling/ascent/darwin-cost.rules.scm')
  body.sub!('(relation dxNativeStage (id demand))', '(relation dxNativeStage (id demand) (("selected" "reuse-explicit-artifact")))') || raise('missing stage DSL input')
  rows = active.map { |g| '("selected" ' + g.to_json + ')' }.join(' ')
  body.sub!('(relation dxNativeGuard (id guard))', '(relation dxNativeGuard (id guard) (' + rows + '))') || raise('missing guard DSL input')
  selector = '(define-evidence (query) (sources clue factor binding) (outputs question dxNativeReady dxActualReusePermit dxM8Retired dxFullBuildGain) (include clue-selection-schema)' + "\n" + body + "\n(relation question (claim) ((\"native-stage\")))\n)"
  request = '((displayBytes 65536) (selector ' + selector.to_json + '))'
  File.write(out + '/' + scenario + '.request.scm', request + "\n")
  stdout, stderr, status = Open3.capture3('.venv/bin/gambit-smp', '--task', 'modern-c-frame-contract', 'trajectory', 'clues', request)
  File.write(out + '/' + scenario + '.result.scm', stdout); File.write(out + '/' + scenario + '.stderr', stderr)
  raise 'incomplete ASCENT evaluation' unless status.success? && stdout.include?('("evaluationComplete" #t)')
  expected = scenario == 'all-guards' ? '("dxNativeReady" (("selected")))' : '("dxNativeReady" ())'
  raise 'unearned selected readiness' unless stdout.include?(expected)
  %w[dxActualReusePermit dxM8Retired dxFullBuildGain].each { |n| raise 'scope expanded' unless stdout.include?('("' + n + '" ())') }
  results[scenario] = {syntheticOmission: scenario != 'all-guards', selectedReady: scenario == 'all-guards'}
end
costs = runs.map do |r|
  s = r[:stage]
  {name: r[:name], wholeSeconds: r[:outer]['wholeSeconds'], nativeStageSeconds: s['stageSeconds'],
   commands: s['commands'].to_h { |c| [c['stage'], c['seconds']] },
   generatedArtifacts: s['generatedArtifacts'].size, generationRecipeLines: s['observedGenerationRecipeLines'].size,
   nativeRecipeLines: s['observedNativeRecipeLines'].size, nativeOutputsInvalidated: s['nativeOutputsInvalidated'].size,
   fixtureCompilations: 5, modeControls: r[:modeControls], outerReceipt: r[:outerReceipt], childReceipt: r[:childReceipt]}
end
File.write(out + '/receipt.json', JSON.pretty_generate({model: {path: projection, sha256: sha.call(projection)},
  modelContract: model, runs: costs, records: records, scenarios: results,
  genericSchemeFreshnessIssued: false, m8Retired: false, runtimeAdmitted: false, commitAdmitted: false}) + "\n")
puts JSON.generate(runs: costs.map { |c| c.reject { |k, _| %i[commands modeControls].include?(k) } }, scenarios: results.size)
