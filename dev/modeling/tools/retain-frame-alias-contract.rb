require 'json';require 'digest';require 'fileutils'
b=ARGV.fetch(0);out=ARGV.fetch(1);e='evidence/research/frame-alias-contract'
raise 'fresh archive required' if File.exist?(e)
sha=->p { Digest::SHA256.file(p).hexdigest }
m=JSON.parse(File.read(b+'/native-projection.json'));a=JSON.parse(File.read(out+'/receipt.json'))
raise 'incomplete controls' unless a['complete']&&a['scenarios'].size==8
raise 'model/policy drift' unless sha.call(b+'/native-projection.json')==a['projectionSha256']&&sha.call('dev/modeling/ascent/frame-alias-contract.rules.scm')==a['policySha256']
current=a['scenarios']['current']['relations']
raise 'source/native overclaim' unless current['aliasLocated'].size==10&&current['aliasPremiseSupplied'].empty?&&current['aliasNativeSupplied'].empty?&&current['aliasModernSmpReady'].empty?&&current['verificationMissing'].size==12
raise 'formal receipt drift' unless sha.call(a['formalReceipt'])==a['formalReceiptSha256']
f=JSON.parse(File.read(a['formalReceipt']))
f['artifacts'].each { |p,h| raise 'formal input drift' unless sha.call(p)==h }
f['rows'].each { |r| raise 'formal log drift' unless sha.call(File.dirname(a['formalReceipt'])+'/'+r['id']+'.log')==r['logSha256'] }
audit=JSON.parse(File.read(out+'/source-witnesses.json'))
audit['files'].each { |p,h| raise 'source drift' unless sha.call(p)==h }
audit['witnesses'].each { |w| raise 'source excerpt drift' unless sha.call(w['excerpt'])==w['excerptSha256'] }
paths=File.readlines(b+'/native-model-inputs.txt',chomp:true)+audit['files'].keys
paths+=Dir.glob(b+'/**/*').select { |p| File.file?(p) }
[out,'.cache/tasks/modern-c-frame-contract/cohort/frame-alias-contract-controls','.cache/tasks/modern-c-frame-contract/cohort/frame-alias-contract-remaining'].each do |p|
 paths+=Dir.glob(p+'/**/*').select { |q| File.file?(q) }
end
paths+=f['artifacts'].keys+[a['formalReceipt'],m['predecessor'],m['profile']]
paths+=f['rows'].map { |r| File.dirname(a['formalReceipt'])+'/'+r['id']+'.log' }
paths+=%w[
 dev/architecture/runtime/control/frame-alias-contract.org
 dev/architecture/runtime/control/index.org
 dev/architecture/runtime/control/control-refinement.org
 dev/architecture/runtime/control/continuation-segments.org
 dev/refactoring/modern-c/index.org
 dev/architecture/runtime/control/diagrams/frame-alias-contract.d2
 dev/architecture/runtime/control/diagrams/frame-alias-contract.svg
 dev/modeling/ascent/obligation-ownership.rules.scm
 dev/modeling/ascent/frame-alias-contract.rules.scm
 dev/modeling/tools/project-frame-alias-contract.rb
 dev/modeling/tools/check-frame-alias-contract.rb
 dev/modeling/tools/render-frame-alias-contract.rb
 dev/modeling/tools/retain-frame-alias-contract.rb
 evidence/research/modern-c-bootstrap/request-custody-source.lock.json
]
raise 'missing retained input' unless paths.all? { |p| File.file?(p) }
FileUtils.mkdir_p(e+'/records')
records=paths.uniq.sort.to_h do |p|
 h=sha.call(p);target=e+'/records/'+p.gsub('/','__');FileUtils.cp(p,target)
 raise 'copy drift' unless sha.call(p)==h&&sha.call(target)==h
 [p,{path:target,sha256:h}]
end
File.write(e+'/validation.json',JSON.pretty_generate({
 authority:'GambitFrameAliasContract',scope:'Source-linked adapter premises for two existing obligations; not source proof, runtime implementation, or native SMP acceptance',
 sourceDigest:a['sourceDigest'],sourceScope:'Selected source witnesses plus existing 18-file candidate lock; not complete build closure',
 profileSha256:a['profileSha256'],sourceFiles:audit['files'].size,sourceWitnesses:audit['witnesses'].size,
 clauses:10,sourceLinks:m['uses'].size,smpCriteria:6,criterionLinks:m['criterionUses'].size,benefits:m['benefits'].size,
 formal:{reexecuted:false,receipt:a['formalReceipt'],sha256:a['formalReceiptSha256'],quintObligations:1,leanObligations:1},
 current:current,scenarios:a['scenarios'],
 conclusions:['Wrapper copy shares frame/denv; aliases need domain identity beyond wrapper identity',
  'Logical payload revisions and physical relocation epochs have distinct source meanings',
  'Restore coherence is scoped to actual fragment consumption; eager whole-invocation snapshot is not justified',
  'Ghost writer history is not an implemented global VM serial counter',
  'Per-domain ownership is necessary but insufficient for same-VM multicore execution and independent GC workers',
  'Unknown writes into shared movable arenas can still obstruct that VM; another healthy VM pass is not same-VM progress proof'],
 normativeReference:{url:'https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf',section:'5.1.2.4 paragraph 25',scope:'Primary committee draft read on web; not a byte-pinned local PDF'},
 history:['Initial Ruby checker rejected missing whitespace before equality after a question-mark method; rejected source retained',
  'Eight ASCENT controls split into bounded stages; exact earlier requests/results reused; no QNT/Lean rerun'],
 runtimeSourceChanged:false,nativeTestsRun:false,modernSmpAdmitted:false,commitAdmitted:false,records:records
})+"\n")
puts JSON.generate(records:records.size,sourceFiles:audit['files'].size,witnesses:audit['witnesses'].size,sourceClauses:10,smpCriteria:6,scenarios:8,formalReexecuted:false,commitAdmitted:false)
