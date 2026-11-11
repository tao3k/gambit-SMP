require 'json'
if ARGV.first == '--realizations'
  _,dir=ARGV; m=JSON.parse(File.read(dir+'/native-projection.json'))
  raw=JSON.parse(File.read(dir+'/native-metadata.json'))
  raise 'native SysML validation required' unless raw['exit']==0 && (raw['errors']||[]).empty?
  clean=->s{s.to_s.gsub('|','/').gsub("\n",' ')}
  text="* Current C root-phase realization\n:PROPERTIES:\n:AUTHORITY: GambitRootWorkerExit::rootPhases\n:CUSTOM_ID: root-phase-realization\n:END:\n\n"
  text<<"The tables below are native SysML projections. Current layout ownership,\nmodel/native observations and remaining C refinement gaps are recorded in\n[[file:hash-layout-results.org][the layout result matrix]]. The earlier two-model checkpoint\nis retained in [[file:concurrent-protocols.org][the concurrent-protocol matrix]], and earlier copy\nauthority in [[file:copy-authority-results.org][the source-bound baseline matrix]].\nHistorical mem.c line coordinates below refer to the predecessor source.\n\n"
  text<<"#+BEGIN: sysml-view :kind root-phase-realization :source refactoring/modern-c/models/sysml/root-worker-exit.sysml\n| Property | Contract |\n|---+---|\n"
  m.fetch('realizations').each do |r|
    r.each{|k,v|text<<'| '+clean.call(k)+' | '+clean.call(v)+" |\n"}
    text<<"|---+---|\n"
  end
  text<<"#+END:\n\n#+BEGIN: sysml-view :kind root-phase-operations :source refactoring/modern-c/models/sysml/root-task-c-refinement.sysml\n| Operation | Actual C symbol | Guard | Linearization | Failure custody | Remaining premise |\n|---+---+---+---+---+---|\n"
  m.fetch('operations').each{|v|text<<'| '+%w[id symbol guard linearization custody gap].map{|k|clean.call(v[k])}.join(' | ')+" |\n"}
  text<<"#+END:\n\n"
  if m['protocolBindings']
    text<<"#+BEGIN: sysml-view :kind concurrent-protocol-ownership :source refactoring/modern-c/models/sysml/root-worker-exit.sysml\n| Component | Protocol / model | QNT responsibility | Lean responsibility | Scope / refinement premise | Recorded component checkpoint |\n|---+---+---+---+---+---|\n"
    m['protocolBindings'].each{|r|text<<'| '+[r['component_id'],r['id']+' / '+r['model'],r['qntDuty'],r['leanDuty'],r['premise'],r['result']+' / '+r['status']].map{|v|clean.call(v)}.join(' | ')+" |\n"}
    text<<"#+END:\n\n#+BEGIN: sysml-view :kind concurrent-protocol-c-steps :source refactoring/modern-c/models/sysml/root-worker-exit.sysml\n| Protocol | C boundary | QNT atomic actions | Actual source / anchor | Refinement responsibility | Status |\n|---+---+---+---+---+---|\n"
    m.fetch('protocolSteps').each{|r|text<<'| '+[r['protocol_id'],r['id'],r['actions'],r['source']+' / '+r['anchor'],r['boundary'],r['progress']].map{|v|clean.call(v)}.join(' | ')+" |\n"}
    text<<"#+END:\n\n"
  end
  if m['workerAdmission']
    text<<"#+BEGIN: sysml-view :kind unequal-worker-admission :source refactoring/modern-c/models/sysml/root-worker-exit.sysml\n| Condition | Source progress | Required contract | C consumer | Existing model owner |\n|---+---+---+---+---|\n"
    m['workerAdmission'].each{|r|text<<'| '+%w[id progress condition source proofOwner].map{|k|clean.call(r[k])}.join(' | ')+" |\n"}
    text<<"#+END:\n\n"
  end
  if m['capacityBoundaries']
    text<<"#+BEGIN: sysml-view :kind full-copy-capacity-boundaries :source refactoring/modern-c/models/sysml/root-worker-exit.sysml\n| Premise | Actual C producer | Required contract | Existing proof owner | Disposition |\n|---+---+---+---+---|\n"
    m['capacityBoundaries'].each{|r|text<<'| '+%w[id source premise modelOwner outcome].map{|k|clean.call(r[k])}.join(' | ')+" |\n"}
    text<<"#+END:\n\n"
  end
  if m['nativeBoundaries']
    text<<"#+BEGIN: sysml-view :kind owner-native-boundaries :source refactoring/modern-c/models/sysml/root-worker-exit.sysml\n| Boundary | Actual producer | Contract | Admission | Remaining debt |\n|---+---+---+---+---|\n"
    m['nativeBoundaries'].each{|r|text<<'| '+%w[id source contract admission remaining].map{|k|clean.call(r[k])}.join(' | ')+" |\n"}
    text<<"#+END:\n\n"
  end
  if m['buildBoundaries']
    if m['nativeWriters']
      text<<"#+BEGIN: sysml-view :kind native-writer-responsibilities :source refactoring/modern-c/models/sysml/root-worker-exit.sysml\n| Family | Source | Anchor | Mutations | Consumer | Required replacement | Status |\n|---+---+---+---+---+---+---|\n"
      m['nativeWriters'].each{|r|text<<'| '+%w[id source anchor writes consumer required status].map{|k|clean.call(r[k])}.join(' | ')+" |\n"}
      text<<"#+END:\n\n"
    end
    text<<"#+BEGIN: sysml-view :kind configuration-and-generation-boundaries :source refactoring/modern-c/models/sysml/root-worker-exit.sysml\n| Boundary | Actual source | Admission guard | Reusable work | Failure custody | Benefit boundary |\n|---+---+---+---+---+---|\n"
    m['buildBoundaries'].each{|r|text<<'| '+%w[id source guard reusable failure benefit].map{|k|clean.call(r[k])}.join(' | ')+" |\n"}
    text<<"#+END:\n\n"
  end
  p='dev/refactoring/modern-c/root-worker-exit.org';old=File.read(p)
  pattern=/\* Current C root-phase realization\n.*?(?=^\* [^*]|\z)/m
  if old.match?(pattern) then old.sub!(pattern,text) else old.sub!('* Concrete callers and evidence',text+'* Concrete callers and evidence') end
  File.write(p,old)
  path='dev/refactoring/modern-c/diagrams/root-worker-exit.d2'
  d=File.read(path).split('# Current SysML root phases').first
  d<<"# Current SysML root phases\nroot_phases: {\n  label: \"Root domain phase tasks / collective drain retained\"\n"
  phases=m['realizations'].find{|r|r['id']=='root-phase-custody'}.fetch('phaseOrder').split(';').first.split(' -> ')
  phases.each{|phase|d<<'  '+phase.downcase+': '+phase.to_json+"\n"}
  phases.each_cons(2){|a,b|d<<'  '+a.downcase+' -> '+b.downcase+": exact predecessor DONE + drained users\n"}
  d<<"}\norigin_task_claim -> root_phases: explicit frozen domain\nroot_phases -> context_resume: cleanup DONE + whole-round seal\nroot_phases -> teardown_reclamation: join unknown does not reclaim native state\n"
  if (arena=m['realizations'].find{|r|r['id']=='worker-arena-handoff'})
    d<<"worker_arena: {\n  label: \"SysML worker-arena-handoff / guarded restore intervals\"\n"
    d<<"  reserve: \"R restoration stacks + W copy sections\"\n  copy: \"VM section ledger / private copy grants\"\n  drain: \"Weak descendants + actual writer exclusion\"\n  handoff: \"Final interval + retired words, exactly once\"\n"
    d<<"  reserve -> copy: bounded optional stack loan\n  copy -> drain: no pending copy or Tail\n  drain -> handoff: epoch + exclusive recipient\n}\nindependent_copy_arena -> worker_arena\nworker_arena -> context_resume: active stack restored separately\n"
  end
  if m['workerAdmission']
    missing=m['workerAdmission'].count{|r|r['progress']=='open'}
    d<<"unequal_admission: {\n label: \"Unequal counts / #{missing} obligations remain open\"\n"
    m['workerAdmission'].each do |r|
      d<<' w_'+r['id'].tr('-','_')+': '+(r['id']+' / '+r['progress']).to_json+"\n"
    end
    d<<"}\nworker_arena -> unequal_admission: scoped source evidence only\n"
  end
  if (domain=m['realizations'].find{|r|r['id']=='worker-root-domains'})
    d<<"worker_domains: {\n label: \"W collectors / R owner services\"\n"
    domain['phaseOrder'].split(';').first.split(' -> ').each{|p|d<<' '+p.downcase+': '+p.to_json+"\n"}
    d<<" freeze -> prepare: actual W + frozen R grants\n prepare -> strong: R tasks claimed by W workers\n strong -> weak: W descendant drain\n weak -> restore: no pending copy or Tail\n restore -> owner_cleanup: all R stacks restored\n owner_cleanup -> resume: R host-token completions\n}\nworker_arena -> worker_domains\nworker_domains -> unequal_admission: selected native cases only\n"
  end
  if m['nativeBoundaries']
    d<<"owner_effects: {\n label: \"Native effects / explicit custody boundaries\"\n"
    m['nativeBoundaries'].each{|r|d<<' b_'+r['id'].tr('-','_')+': '+(r['id']+' / '+r['admission']).to_json+"\n"}
    d<<" b_owner_new_still -> b_nested_gc: collecting request fails before publication\n b_managed_entry -> b_raw_rc_and_payload: low-level refusal is not writer closure\n b_nonlocal_native_exit -> b_teardown_producer: escrow/lifetime proof still required\n}\nworker_domains -> owner_effects: actual native owner services\n"
  end
  if (copy=m['realizations'].find{|r|r['id']=='copy-before-reservation'})
    d<<"copy_authority: {\n label: #{copy['id'].to_json}\n"
    copy['phaseOrder'].split(' -> ').each{|p|d<<' '+p.downcase+': '+p.to_json+"\n"}
    order=copy['phaseOrder'].split(' -> ').map(&:downcase)
    order.each_cons(2){|a,b|d<<" #{a} -> #{b}\n"}
    d<<"}\nworker_arena -> copy_authority: claim before any physical mutation\n"
    d<<'copy_cost: '+copy['overheads'].to_json+"\ncopy_authority -> copy_cost\n"
  end
  %w[source-bounded-request closed-root-domain].each do |id|
    next unless (r=m['realizations'].find{|row|row['id']==id})
    key=id.tr('-','_')
    d<<key+": {\n label: "+id.to_json+"\n"
    order=r['phaseOrder'].split(' -> ')
    order.each{|phase|d<<' '+phase.downcase+': '+phase.to_json+"\n"}
    order.each_cons(2){|a,b|d<<' '+a.downcase+' -> '+b.downcase+"\n"}
    d<<"}\n"+key+" -> unequal_admission: selected source replacement; global obligations remain\n"
  end
  d<<"copy_authority -> source_bounded_request: ownership before space request\nclosed_root_domain -> source_bounded_request: frozen and scannable inputs\n"
  if m['nativeWriters']
    d<<"writer_coverage: {\n label: \"Source families / enforcement still required\"\n"
    m['nativeWriters'].each{|r|d<<' '+r['id'].tr('-','_')+': '+(r['id']+' / '+r['status']).to_json+"\n"}
    d<<"}\nwriter_coverage -> owner_effects: inventory is not admission\n"
  end
  if m['buildBoundaries']
    d<<"build_custody: {\n label: \"Existing configure / Make / one owned workspace\"\n"
    m['buildBoundaries'].each{|r|d<<' '+r['id'].tr('-','_')+': '+r['id'].to_json+"\n"}
    d<<" configure_probes -> configuration_templates: completed probes plus authenticated substitutions\n source_relocation -> configuration_templates: policy change requires configure\n configuration_templates -> native_object_context: compare last successful object context\n}\nbuild_custody -> owner_effects: current source compiled and executed independently\n"
  end
  if m['protocolBindings']
    d<<"protocols: {\n label: \"SysML-selected concurrent contracts / finite safety only\"\n"
    m['protocolBindings'].each do |r|
      key=r['id'].tr('-','_')
      d<<' '+key+': '+(r['id']+' / '+r['component_id']).to_json+"\n"
      steps=m.fetch('protocolSteps').select{|s|s['protocol_id']==r['id']}
      steps.each do |s|
        node=s['id'].tr('-','_')
        d<<' '+node+': '+(s['actions']+' / '+s['progress']).to_json+"\n"
        d<<' '+key+' -> '+node+": atomic C-boundary obligation\n"
      end
    end
    d<<"}\nprotocols -> qnt: tests plus exhaustive finite safety and counterexamples\nprotocols -> lean: interval and root encoding obligations only\nprotocols -> ascent: source digests plus action coverage plus observed verdicts\n"
    d<<"ascent -> retire: model checking never supplies missing C refinement\n"
  end
  File.write(path,d)
  if m['hashContracts']
    h="#+TITLE: Hash index ownership: projected contracts and obligations\n#+SETUPFILE: ../../modeling/org/setup.org\n#+LANGUAGE: en\n#+PROPERTY: header-args :eval never-export\n\n* Native SysML contract projection\n:PROPERTIES:\n:AUTHORITY: GambitHashIndexOwnership\n:STATUS: CONDITIONAL-SOURCE-REPLACEMENT\n:END:\n\nCurrent execution and net-work evidence is recorded in [[file:hash-layout-results.org][the result matrix]].\nThe following tables are derived from the native SysML projection. They are not another contract source.\n\n#+BEGIN: sysml-view :kind hash-contracts :source models/sysml/hash-index-ownership.sysml\n| Component | Actual route | Required invariant | Benefit mechanism | Added cost / boundary |\n|---+---+---+---+---|\n"
    m['hashContracts'].each{|r|h<<'| '+%w[id route invariant benefit cost].map{|k|clean.call(r[k])}.join(' | ')+" |\n"}
    h<<"#+END:\n\n* Distinct assurance duties\n#+BEGIN: sysml-view :kind hash-proof-routing :source models/sysml/hash-index-ownership.sysml\n| Component | Obligation | Method | Existing artifact | Premise / remaining work |\n|---+---+---+---+---|\n"
    m.fetch('hashProofs').each{|r|h<<'| '+%w[component_id id method artifact premise].map{|k|clean.call(r[k])}.join(' | ')+" |\n"}
    h<<"#+END:\n"
    File.write('dev/refactoring/modern-c/hash-index-ownership-matrix.org',h)
    diagram="direction: down\nvars: { d2-config: { layout-engine: elk } }\n"
    m['hashContracts'].each{|r|diagram<<r['id'].tr('-','_')+': '+(r['id']+"\n"+r['route']).to_json+"\n"}
    m.fetch('hashEdges').each{|r|diagram<<r['producer_id'].tr('-','_')+' -> '+r['consumer_id'].tr('-','_')+": responsibility contract\n"}
    m['hashProofs'].each{|r|key='proof_'+r['id'].tr('-','_');diagram<<key+': '+(r['id']+' / '+r['method']+"\n"+r['artifact']).to_json+"\n";diagram<<r['component_id'].tr('-','_')+' -> '+key+": separate obligation\n"}
    File.write('dev/refactoring/modern-c/diagrams/hash-index-ownership.d2',diagram)
  end
  puts JSON.generate(realizations:m['realizations'].size,operations:m['operations'].size,phaseTasks:phases.size,wholeRetirement:false)
  exit
end
b=ARGV.fetch(0); out=ARGV.fetch(1); m=JSON.parse(File.read(b+'/native-projection.json'))
a=JSON.parse(File.read(out+'/receipt.json')); raise 'incomplete controls' unless a['complete']
clean=->s { s.to_s.gsub('|','/').gsub("\n",' ') }
tables={
 'rwe-witnesses'=>[%w[Witness Source Lines Finding],m['witnesses'].map { |w| [w['id'],w['file'],"#{w['firstLine']}-#{w['lastLine']}",w['finding']] }],
 'rwe-replacements'=>[%w[Clause Factor Old-authority Replacement Necessary-condition Retirement-condition Failure-custody C-publication-order],m['clauses'].map { |c| %w[id factor_id oldAuthority replacement condition retirement custody memoryOrder].map { |k| c[k] } }],
 'rwe-dependencies'=>[%w[Dependent Prerequisite],m['dependencies'].map { |d| [d['dependent_id'],d['prior_id']] }],
 'rwe-learning'=>[%w[Mechanism Pinned-witnesses Upstream-fact Gambit-mismatch Inference Refutation],m['learning'].map { |l| %w[id witnesses fact mismatch inference counterexample].map { |k| l[k] } }],
 'rwe-benefits'=>[%w[Clause Avoided-work Added-cost],m['clauses'].map { |c| %w[id savedWork addedCost].map { |k| c[k] } }],
 'rwe-native-cases'=>[%w[Case Required-observation Execution],m['nativeCases'].map { |n| [n['id'],n['observation'],'NOT EXECUTED'] }],
 'rwe-closure'=>[%w[Control Synthetic Supplied-clauses Dependency-covered-clauses Native-case-records Retirement-admitted],a['scenarios'].map do |name,s|
  v=s['relations']; [name,s['synthetic'],v['rweSupplied'].size.to_s+'/9',v['rweLocalCovered'].size.to_s+'/9',v['rweNativeSupplied'].size.to_s+'/5',v['rweRetirementReady'].empty? ? 'NO' : 'ERROR']
 end]
}
p='dev/refactoring/modern-c/root-worker-exit.org'; text=File.read(p)
tables.each do |kind,(heads,rows)|
 table='| '+heads.join(' | ')+" |\n|"+(['---']*heads.size).join('+')+"|\n"+rows.map { |r| '| '+r.map { |s| clean.call(s) }.join(' | ')+" |\n" }.join
 pattern=/(\#\+BEGIN: (?:sysml|ascent)-view :kind #{kind}[^\n]*\n).*?(\#\+END:)/m
 raise 'missing Org view '+kind unless text.match?(pattern); text.sub!(pattern,"\\1"+table+"\\2")
end
File.write(p,text)
d="direction: right\nvars: { d2-config: { layout-engine: elk } }\n"
m['clauses'].each do |c|
 id=c['id'].tr('-','_'); d<<id+': '+JSON.generate(c['id']+' / '+c['factor_id']+' / refinement OPEN')+"\n"
end
m['dependencies'].each { |x| d<<x['prior_id'].tr('-','_')+' -> '+x['dependent_id'].tr('-','_')+": prerequisite, not a runtime wait\n" }
m['learning'].each { |l| d<<'otp_'+l['id'].tr('-','_')+': '+JSON.generate('OTP learning: '+l['id']+' / '+l['mismatch'])+"\n" }
d<<"otp_scheduler_process -> origin_task_claim: separation lesson\notp_reader_grace -> teardown_reclamation: unmanaged readers excluded\notp_native_exit -> withdrawal_custody: logical exit differs from native stop\notp_actor_memory -> frozen_root_publication: shared Scheme semantics require own proof\n"
d<<"qnt: \"Existing QNT scheduling/permit evidence: reused\"\nlean: \"Existing Lean data/mapping evidence: reused\"\nascent: \"ASCENT: source, dependency, identity and gate checks\"\nretire: \"Old GC authority retirement: BLOCKED\"\n"
m['nativeCases'].each { |n| d<<'native_'+n['id'].tr('-','_')+': '+JSON.generate(n['id']+' / native evidence OPEN')+"\n"; d<<'native_'+n['id'].tr('-','_')+" -> ascent\n" }
d<<"qnt -> ascent\nlean -> ascent\ncontext_resume -> ascent\nteardown_reclamation -> ascent\nascent -> retire: five gates and original obligations remain open\n"
File.write('dev/refactoring/modern-c/diagrams/root-worker-exit.d2',d)
puts JSON.generate(clauses:m['clauses'].size,witnesses:m['witnesses'].size,sourceLinks:m['uses'].size,learning:m['learning'].size,nativeCases:m['nativeCases'].size,controls:a['scenarios'].size)
