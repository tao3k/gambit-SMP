require 'json'; require 'digest'; require 'fileutils'; require 'zlib'
model=ARGV.fetch(0); split=ARGV.fetch(1); verified=ARGV.fetch(2); controls=ARGV.fetch(3)
m=JSON.parse(File.read(model)); r=JSON.parse(File.read(split+'/split.json'))
v=JSON.parse(File.read(verified+'/receipt.json')); a=JSON.parse(File.read(controls+'/receipt.json'))
raise 'controls incomplete' unless a['complete'] && a['scenarios'].size==5
sha=->p { Digest::SHA256.file(p).hexdigest }
raise 'receipt drift' unless a['verificationReceiptSha256']==sha.call(verified+'/receipt.json') && a['modelSha256']==sha.call(model)
v['files'].each { |p,h| raise 'current source drift '+p unless sha.call(p)==h }
kernel='.cache/tasks/modern-c-frame-contract/cohort/root-task-c-native-profile/receipt.json'
k=JSON.parse(File.read(kernel))
raise 'header projection lineage drift' unless k['source']['include/gambit.h.in']==v['files']['vendor/gambit/include/gambit.h.in'] && k['configuredHeaderSha256']==v['configuredHeaderSha256']
org='dev/refactoring/modern-c/memory-organization.org'; text=File.read(org)
text.sub!('STRUCTURAL-VALIDATION-IN-PROGRESS; RUNTIME-ACCEPTANCE-OPEN','STRUCTURAL-CHECKS-PASS; RUNTIME-ACCEPTANCE-OPEN; COMMIT-BLOCKED')
views={}
views['memory-partition']="| Internal source module | Original logical interval | Current physical payload | Responsibility |\n|---+---+---+---|\n"
r['fragments'].each do |f|
  n=f['pastLine']-f['firstLine']
  views['memory-partition']<<"| =#{f['file']}= | #{f['firstLine']}–#{f['pastLine']-1} | 2–#{n+1} | #{f['responsibility']} |\n"
end
views['memory-closure']="| Evidence or control | Result | Boundary |\n|---+---+---|\n"
views['memory-closure']<<"| Source reconstruction | Exact #{r['sourceBytes']} bytes / #{r['sourceLines']} lines | Includes all preceding candidate changes |\n"
views['memory-closure']<<"| Native SysML | PASS; 25 evaluated module records | Source organization authority |\n"
views['memory-closure']<<"| Preprocessing | 8 pairs equal after terminal-newline normalization | GCC/Clang × 4 macro configurations |\n"
views['memory-closure']<<"| GCC release object | Byte-identical at -O3 | Same configured ancestor and current header slice |\n"
views['memory-closure']<<"| Make prerequisites | 26 cases PASS | Unchanged + each of 25 fragments forces rebuild |\n"
views['memory-closure']<<"| Debug overrides | 3 paired failures retained | Same error locations/messages; diagnostic excerpts/include stacks differ |\n"
a['scenarios'].each { |name,c| views['memory-closure']<<"| ASCENT #{name} | #{c['structuralReady'] ? 'Structural admission' : 'Rejected'} | #{c['synthetic'] ? 'Synthetic policy control' : 'Current observed source'}; runtime admission false |\n" }
views['memory-benefits']=<<'ORG'
| Concern | Before | After | Benefit | Added cost / remaining boundary |
|---+---+---+---+---|
| Editing and ownership | 8,252-line implementation file | 59-line driver + 25 named modules | Allocation, roots, copy/Tail, continuation, phases and resize have distinct source surfaces | 25 internal includes; macro order remains coupled |
| Source coverage | One original body | Exact byte reconstruction | No deleted or duplicated original implementation bytes | Immutable hash/interval receipt; no second maintained runtime body |
| Runtime overhead | Existing candidate | Release object identical | No added instructions or object storage for the split | No new claim about prior behavioral changes |
| Incremental compilation | One mem object | One mem object with complete dependencies | Changes cannot silently leave mem object stale | No parallel compile or speedup claimed; include processing adds unmeasured build work |
| Distribution | Flat runtime sources | Explicit fragment inventory + nested directory | New implementation pieces included in existing source/distribution lists | Full source distribution build remains unqualified |
| GC/SMP modernization | Carrier-coupled consumers mixed in one file | Responsibilities visible in separate modules | Supports later complete interface replacement and source refinement | Shared macro state, physical refill and collective authority remain |
| Verification | Informal source movement | Source identity + native compiler comparisons + ASCENT controls | Missing parts, wrong order and stale receipts reject structural admission | Whole bootstrap, real Scheme GC/control and five commit gates remain open |
ORG
views.each do |kind,body|
  pattern=/(\#\+BEGIN: (?:sysml|ascent)-view :kind #{kind}[^\n]*\n).*?(\#\+END:)/m
  raise 'missing Org block '+kind unless text.sub!(pattern) { $1+body+$2 }
end
File.write(org,text)
d="direction: down\nvars: { d2-config: { layout-engine: elk } }\n"
d<<"model: \"SysML: ordered responsibilities\"\ndriver: \"mem.c: unchanged preamble + 25 ordered includes\"\n"
d<<"modules: {\n  label: \"Private memory-runtime source modules; one translation unit\"\n  grid-columns: 4\n"
m['fragments'].each_with_index { |f,i| d<<"  m#{i}: "+JSON.generate(f['file'].sub('_mem/','')+"\n"+f['responsibility'])+"\n" }
d<<"}\nproof: \"Byte reconstruction / 8 preprocessing pairs / release object identity\"\n"
d<<"ascent: \"ASCENT: exact source, order, contracts and negative controls\"\n"
d<<"formal: \"Existing QNT schedules + Lean coherence: reused; no duplicated model\"\n"
d<<"open: \"Bootstrap / Scheme GC + multi-shot control / five commit gates: OPEN\"\n"
d<<"model -> driver\ndriver -> modules: inclusion order preserved\nmodules -> proof\nmodel -> ascent\nproof -> ascent\nformal -> open\nascent -> open: structural acceptance cannot supply runtime acceptance\n"
File.write('dev/refactoring/modern-c/diagrams/memory-organization.d2',d)
e='evidence/research/memory-organization'; FileUtils.mkdir_p(e+'/records')
Zlib::GzipWriter.open(e+'/records/mem-before.c.gz') { |g| g.mtime=0; g.write(File.binread(split+'/mem-before.c')) }
records={}
copy=lambda do |p|
  dest=e+'/records/'+Digest::SHA256.hexdigest(p)[0,12]+'-'+File.basename(p)
  FileUtils.cp(p,dest); records[p]={path:dest,sha256:sha.call(dest)}
end
[model,split+'/split.json',verified+'/receipt.json',verified+'/progress.json',kernel,
 'dev/refactoring/modern-c/models/sysml/memory-organization.sysml',
 'dev/modeling/ascent/memory-organization.rules.scm',
 'dev/modeling/tools/project-memory-organization.rb','dev/modeling/tools/split-memory.rb',
 'dev/modeling/tools/verify-memory-organization.rb','dev/modeling/tools/check-memory-organization.rb',
 'dev/modeling/tools/render-memory-organization.rb',org,
 'dev/refactoring/modern-c/diagrams/memory-organization.d2'].each { |p| copy.call(p) }
# Preserve initial failed comparisons and complete raw compiler diagnostics.
dirs=[File.dirname(model),controls,verified]+%w[controls controls-first controls-second].map { |suffix| '.cache/tasks/modern-c-frame-contract/cohort/memory-organization-'+suffix }+%w[check qualified accepted complete].map { |suffix| '.cache/tasks/modern-c-frame-contract/cohort/memory-organization-'+suffix }
dirs.each do |dir|
  Dir.glob(dir+'/*').sort.each do |p|
    copy.call(p) if File.file?(p) && p.match?(/\.(json|scm|stdout|stderr|log|tsv|sh)$/)
  end
end
validation={scope:'Complete source partition and bounded compiler/build equivalence; no linked-runtime admission',
 sourceBeforeSha256:r['sourceSha256'],baselineArchive:{path:e+'/records/mem-before.c.gz',sha256:sha.call(e+'/records/mem-before.c.gz')},
 sourceFiles:v['files'],sourceLines:r['sourceLines'],driverLines:r['driverLines'],fragments:25,
 profileSha256:v['profileSha256'],preprocessPairs:v['preprocessEqual'].size,releaseObjectPairs:v['objectEqual'].size,
 makeCases:v['makeDependencyCases'],debugFailurePairs:v['baselineFailures'].size,ascentControls:a['scenarios'].size,
 records:records,formalReexecuted:false,fullBootstrap:false,retirementAdmitted:false,commitAdmitted:false}
File.write(e+'/validation.json',JSON.pretty_generate(validation)+"\n")
puts JSON.generate(fragments:25,records:records.size,preprocessPairs:8,releaseObjectPairs:1,ascentControls:5,commitAdmitted:false)
