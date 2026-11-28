require 'json'; require 'digest'; require 'fileutils'; require 'open3'
base = ARGV.fetch(0)
priors = ARGV.drop(1).map { |p| [p, JSON.parse(File.read(p+'/receipt.json'))] }
raise 'fresh output required' if File.exist?(base)
FileUtils.mkdir_p(base)
models = {
  'resize_sources' => ['ResizeSources', %w[badDrop badStaleCopy badRetire badEarlyAck badWrap]],
  'copy_custody' => ['CopyCustody', %w[recopyTospace duplicateScan isolateUnknownCreate reuseUnknownNative publishHeldAgain duplicateChunkTake scanUnfinishedFrame ordinaryWritesLink refundUnknown doubleRefund]],
  'startup_custody' => ['StartupCustody', %w[badPublishMeansReady badReuseWithoutJoin badStaleReceipt badGCWhileLocked badRootDrop]],
  'round_capacity' => ['RoundCapacity', %w[badFlipPending badRefundSection badOverlap badUnknownFlip]]
}
rows = []; artifacts = {}
run = lambda do |id, argv, expected|
  out, err, status = Open3.capture3(*argv)
  File.write(base+'/'+id+'.log', out+err)
  matched = status.exitstatus == expected && (expected == 0 || (out+err).include?('Invariant violated'))
  rows << {id:id, argv:argv, exit:status.exitstatus, expected:expected, matched:matched, logSha256:Digest::SHA256.hexdigest(out+err)}
  File.write(base+'/receipt.json', JSON.pretty_generate({scope:'finite contracts and conditional laws; C simulation and liveness remain open', artifacts:artifacts, rows:rows, runtimeAdmitted:false, commitAdmitted:false})+"\n")
  raise id unless matched
end
models.each do |name, (namespace, negatives)|
  q = 'dev/refactoring/modern-c/models/quint/'+name+'.qnt'
  l = 'dev/refactoring/modern-c/models/lean/'+namespace+'.lean'
  [q,l].each { |p| artifacts[p] = Digest::SHA256.file(p).hexdigest }
  selected = priors.find { |_, j| [q,l].all? { |p| j.fetch('artifacts')[p] == artifacts[p] } }
  if selected
    priorPath, prior = selected
    old = prior.fetch('rows').select { |r| r.fetch('id').start_with?(name+'-') }
    if old.size == negatives.size+5 && old.all? { |r| r.fetch('matched') }
      old.each do |r|
        path=priorPath+'/'+r.fetch('id')+'.log'
        raise 'prior log drift' unless Digest::SHA256.file(path).hexdigest==r.fetch('logSha256')
        FileUtils.cp(path,base+'/'+r.fetch('id')+'.log')
        rows << r.merge('reusedExactArtifactReceipt'=>priorPath+'/receipt.json','priorReceiptSha256'=>Digest::SHA256.file(priorPath+'/receipt.json').hexdigest)
      end
      next
    end
  end
  run.call(name+'-typecheck', ['quint','typecheck',q], 0)
  run.call(name+'-histories', ['quint','test',q,'--max-samples=1000','--seed=23'], 0)
  run.call(name+'-safety', ['quint','run',q,'--invariant=safe','--max-samples=1000','--max-steps=40','--seed=23'], 0)
  negatives.each { |n| run.call(name+'-'+n, ['quint','run',q,'--step='+n,'--invariant=safe','--max-samples=1','--max-steps=1','--seed=23'], 1) }
  run.call(name+'-lean', ['lean',l], 0)
  laws = File.read(l).scan(/^theorem\s+(\w+)/).flatten
  audit = base+'/'+namespace+'-axioms.lean'
  File.write(audit, File.read(l)+"\n"+laws.map { |n| '#print axioms Gambit.'+namespace+'.'+n }.join("\n")+"\n")
  run.call(name+'-axioms', ['lean',audit], 0)
  raise 'sorry axiom' if File.read(base+'/'+name+'-axioms.log').include?('sorryAx')
end
File.write(base+'/receipt.json', JSON.pretty_generate({scope:'finite contracts and conditional laws; C simulation and liveness remain open', artifacts:artifacts, rows:rows, runtimeAdmitted:false, commitAdmitted:false})+"\n")
puts JSON.generate(checks:rows.size, matched:rows.count { |r| r[:matched] || r["matched"] }, artifacts:artifacts.size)
