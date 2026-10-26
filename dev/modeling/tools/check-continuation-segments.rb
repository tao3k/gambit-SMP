require 'json';require 'digest';require 'fileutils';require 'open3'
b=ARGV.fetch(0);raise 'fresh output required' if File.exist?(b);FileUtils.mkdir_p(b)
q='dev/architecture/runtime/control/models/quint/continuation_segments.qnt'
l='dev/architecture/runtime/control/models/lean/ContinuationSegments.lean'
artifacts=[q,l].to_h { |p| [p,Digest::SHA256.file(p).hexdigest] };rows=[]
run=lambda do |id,argv,expected|
  out,err,status=Open3.capture3(*argv);File.write(b+'/'+id+'.log',out+err)
  matched=status.exitstatus==expected && (expected==0 || (out+err).include?('Invariant violated'))
  rows<<{id:id,argv:argv,exit:status.exitstatus,expected:expected,matched:matched,logSha256:Digest::SHA256.hexdigest(out+err)}
  File.write(b+'/receipt.json',JSON.pretty_generate({scope:'Quint interleavings; Lean issued-view coherence for arbitrary writer histories; no duplicated per-component proof requirement',artifacts:artifacts,rows:rows,runtimeAdmitted:false,commitAdmitted:false})+"\n")
  raise 'formal check '+id unless matched
end
prior=ARGV[1] && JSON.parse(File.read(ARGV[1]+'/receipt.json'))
if prior && prior['artifacts'][q]==artifacts[q] && prior['rows'].first(11).all? { |r| r['matched'] }
  raise 'missing prior Quint controls' unless prior['rows'].first(11).map { |r| r['id'] }==%w[quint-typecheck quint-histories quint-safety badConsume badRootGap badStalePermit badDeadOrigin badRememberedEdge badLateHook badGcBorrow badEscapeImage]
  prior['rows'].first(11).each do |r|
    p=ARGV[1]+'/'+r['id']+'.log';raise 'prior log drift' unless Digest::SHA256.file(p).hexdigest==r['logSha256']
    FileUtils.cp(p,b+'/'+r['id']+'.log');rows<<r.merge('reusedReceipt'=>ARGV[1]+'/receipt.json','reusedReceiptSha256'=>Digest::SHA256.file(ARGV[1]+'/receipt.json').hexdigest)
  end
else
  run.call('quint-typecheck',['quint','typecheck',q],0)
  run.call('quint-histories',['quint','test',q,'--max-samples=1000','--seed=23'],0)
  run.call('quint-safety',['quint','run',q,'--invariant=safe','--max-samples=1000','--max-steps=60','--seed=23'],0)
  %w[badConsume badRootGap badStalePermit badDeadOrigin badRememberedEdge badLateHook badGcBorrow badEscapeImage].each do |n|
    run.call(n,['quint','run',q,'--step='+n,'--invariant=safe','--max-samples=1','--max-steps=1','--seed=23'],1)
  end
end
laws=File.read(l).scan(/^theorem\s+(\w+)/).flatten
if prior && prior['artifacts'][l]==artifacts[l] && %w[lean-coherence lean-axioms].all? { |id| prior['rows'].any? { |r| r['id']==id && r['matched'] } }
  %w[lean-coherence lean-axioms].each do |id|
    r=prior['rows'].find { |x| x['id']==id };p=ARGV[1]+'/'+id+'.log'
    raise 'prior Lean log drift' unless Digest::SHA256.file(p).hexdigest==r['logSha256']
    FileUtils.cp(p,b+'/'+id+'.log');rows<<r.merge('reusedReceipt'=>ARGV[1]+'/receipt.json','reusedReceiptSha256'=>Digest::SHA256.file(ARGV[1]+'/receipt.json').hexdigest)
  end
  FileUtils.cp(ARGV[1]+'/axioms.lean',b+'/axioms.lean')
else
  run.call('lean-coherence',['lean',l],0)
  File.write(b+'/axioms.lean',File.read(l)+"\n"+laws.map { |n| '#print axioms Gambit.ContinuationSegments.'+n }.join("\n")+"\n")
  run.call('lean-axioms',['lean',b+'/axioms.lean'],0)
end
raise 'unproved theorem' if File.read(b+'/lean-axioms.log').include?('sorryAx')
raise 'input drift' unless artifacts.all? { |p,h| Digest::SHA256.file(p).hexdigest==h }
File.write(b+'/receipt.json',JSON.pretty_generate({scope:'Quint schedules and ticket lifetimes only; Lean unbounded issued-view algebra only; source refinement open',artifacts:artifacts,rows:rows,runtimeAdmitted:false,commitAdmitted:false})+"\n")
puts JSON.generate(checks:rows.size,matched:rows.count { |r| r[:matched] || r['matched'] },histories:File.read(q).scan(/^  run /).size,conditionalLaws:laws.size)
