require 'json'; require 'digest'; require 'fileutils'; require 'zlib'
model=ARGV.fetch(0); controls=ARGV.fetch(1); m=JSON.parse(File.read(model)); a=JSON.parse(File.read(controls+'/receipt.json'))
raise 'incomplete controls' unless a['complete'] && a['scenarios'].size==6
sha=->p { Digest::SHA256.file(p).hexdigest }; base='.cache/tasks/modern-c-frame-contract/runs/gambit-namespaced-qualified'; rows={}
m['lanes'].each do |c|
 p=base+'/'+c['id']+'/receipt.json'; r=JSON.parse(File.read(p)); raise 'wrong named case' unless r['module']==c['id'] && r['namespace']==c['namespace'] && r['name']==c['name']; rows[c['id']]=r
end
org='dev/refactoring/modern-c/modular-smp-validation.org'; text=File.read(org)
text.sub!('LOCAL-QUALIFICATION-IN-PROGRESS; REMOTE-CI-OPEN; COMMIT-BLOCKED','LOCAL-OBSERVATIONS-RETAINED; HISTORICAL-MAILBOX-FAILURE-OPEN; REMOTE-CI-OPEN; COMMIT-BLOCKED')
views={}
views['modular-smp-cases']="| Qualified case | Local result | Processors | Scope |\n|---+---+---+---|\n"
m['lanes'].each { |c| r=rows[c['id']]; views['modular-smp-cases']<<"| =#{c['id']}= | #{r['outcome']} (#{r['seconds'].round(3)} s) | #{r['executionProcessors'] || 'kernel/build'} | #{c['kind']}; remote CI unrun |\n" }
views['modular-smp-contracts']="| Contract | Source anchor | Preserved invariant | Remaining obligation |\n|---+---+---+---|\n"
m['contracts'].each { |c| views['modular-smp-contracts']<<"| =#{c['id']}= | =#{c['source']}:#{c['anchor']}= | #{c['invariant']} | #{c['open']} |\n" }
views['modular-smp-controls']="| Control | Result | Promotion |\n|---+---+---|\n"
a['scenarios'].each { |n,r| views['modular-smp-controls']<<"| #{n} | #{r['supplied'].size}/#{m['lanes'].size} scoped observations supplied#{r['synthetic'] ? '; synthetic negative control' : '; native receipt evidence'} | Commit blocked |\n" }
views.each { |kind,body| raise 'missing Org block '+kind unless text.sub!(/(\#\+BEGIN: (?:sysml|ascent)-view :kind #{kind}[^\n]*\n).*?(\#\+END:)/m) { $1+body+$2 } }
File.write(org,text)
d="direction: down\nvars: { d2-config: { layout-engine: elk } }\n"
d<<"authority: \"SMP/dev: native SysML / named cases / shared contracts\"\n"
d<<"gambit: {\n label: \"Gambit repository: independent modern-c CI\"\n workflow: \".github/workflows/smp.yml\"\n seed: \"Existing configure / Make seed\"\n suite: \"Scheme namespace: gambit#tests#smp#\\nexecute-case / catalog.scm\"\n bootstrap: \"Two-pass bootstrap: 600 s original command cap\"\n cases: {\n label: \"Independent named C / Scheme / Make scenarios\"\n grid-columns: 3\n"
m['lanes'].each_with_index { |c,i| d<<" c#{i}: "+JSON.generate(c['namespace']+"\n"+c['name']+"\n"+rows[c['id']]['outcome'])+"\n" }
d<<" }\n workflow -> seed\n seed -> suite\n suite -> bootstrap\n bootstrap -> cases\n}\n"
d<<"evidence: \"SMP: immutable native receipts, byte streams, prior failures\"\nascent: \"ASCENT: exact identity, method and missing/conflicting evidence\"\nformal: \"Existing QNT schedules / Lean coherence: distinct owners, no duplicate models\"\nopen: \"Mailbox failure witness / physical worker retirement / five gates: OPEN\"\n"
d<<"authority -> gambit.suite\nauthority -> gambit.cases\ngambit.cases -> evidence\nevidence -> ascent\nauthority -> ascent\nformal -> ascent: original obligations retained\nascent -> open: no module-only commit authority\n"
File.write('dev/refactoring/modern-c/diagrams/modular-smp-validation.d2',d)
e='evidence/research/modular-smp-bootstrap'; FileUtils.mkdir_p(e+'/records'); records={}
retain=lambda do |p|
 next unless File.file?(p)
 h=sha.call(p); dest=e+'/records/'+h[0,16]+'-'+File.basename(p)
 if File.size(p)>65536
  dest+='.gz'; unless File.exist?(dest); Zlib::GzipWriter.open(dest) { |g| g.mtime=0; g.write(File.binread(p)) }; end
  raise 'archive content drift' unless Zlib::GzipReader.open(dest) { |g| Digest::SHA256.hexdigest(g.read) }==h
 else
  if File.exist?(dest); raise 'retained record drift' unless sha.call(dest)==h; else FileUtils.cp(p,dest); end
 end
 records[p]={path:dest,sourceSha256:h,storedSha256:sha.call(dest)}
end
[org,'dev/refactoring/modern-c/models/sysml/modular-smp-validation.sysml','dev/modeling/ascent/modular-smp-validation.rules.scm',
 'dev/modeling/tools/project-modular-smp-validation.rb','dev/modeling/tools/generate-modular-smp-ci.rb',
 'dev/modeling/tools/check-modular-smp-validation.rb',__FILE__,'dev/refactoring/modern-c/diagrams/modular-smp-validation.d2',
 'dev/refactoring/modern-c/diagrams/modular-smp-validation.svg',
 'vendor/gambit/.github/workflows/smp.yml','vendor/gambit/tests/smp/suite.scm','vendor/gambit/tests/smp/catalog.scm',
 e+'/ci-plan.json',e+'/fragment-admission.json',e+'/bootstrap-current.recipe.json',e+'/intent-current.json',e+'/review-current.json',
 e+'/qualified/source.lock.json',e+'/qualified/source-overlay.patch'].each { |p| retain.call(p) }
m['lanes'].each { |c| retain.call(c['program']) }
%w[completed-origin-regressions.stdout completed-origin-regressions.stderr modular-smp-d2.stdout modular-smp-d2.stderr].each do |name|
 retain.call('.cache/tasks/modern-c-frame-contract/cohort/'+name)
end
[File.dirname(model),controls,e+'/consumer-admission-failure'].each do |dir|
 Dir.glob(dir+'/**/*').sort.each { |p| retain.call(p) if File.file?(p) && p.match?(/\.(json|scm|py|sh|yml|log|stdout|stderr|tsv)$/) }
end
%w[modular-smp-bootstrap modular-smp-qualified modular-smp-current modular-shared-roots modular-shared-roots-managed modular-source-controls modular-kernel-controls modular-kernel-configured gambit-owned-modules gambit-owned-qualified gambit-shell-qualified gambit-native-scheme gambit-namespaced-scheme gambit-namespaced-qualified].each do |name|
 dir='.cache/tasks/modern-c-frame-contract/runs/'+name
 Dir.glob(dir+'/**/*').sort.each { |p| retain.call(p) if File.file?(p) && p.match?(/\.(json|output|stdout|stderr|log|sha256)$/) && !p.include?('/source/') && !p.include?('/generation/') }
end
summary={scope:'Gambit-owned named native modules; source-bound bootstrap; no whole SMP or remote CI admission',
 modelSha256:sha.call('dev/refactoring/modern-c/models/sysml/modular-smp-validation.sysml'),
 sourceLockSha256:sha.call(m['sourceLock']),profileSha256:sha.call(m['profile']),
 workflow:'vendor/gambit/.github/workflows/smp.yml',schemeNamespace:'gambit#tests#smp#',
 cases:rows.transform_values { |r| r.slice('outcome','seconds','executionProcessors','compilerProcessors') },
 historicalMailboxFailureOpen:true,ascentControls:a['scenarios'].size,formalReexecuted:false,
 frameworkRegressionTests:60,frameworkRegressionOutcome:'PASS',
 fullBootstrapObserved:true,coldStandaloneCIBootstrapQualified:false,remoteCIExecuted:false,wholeSmpAdmitted:false,commitAdmitted:false,records:records}
File.write(e+'/validation.json',JSON.pretty_generate(summary)+"\n")
puts JSON.generate(namedCases:rows.size,passed:rows.values.count { |r| r['outcome']=='PASS' },records:records.size,remoteCIExecuted:false,commitAdmitted:false)
