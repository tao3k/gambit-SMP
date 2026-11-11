require 'json'; require 'digest'; require 'fileutils'
run, out = ARGV
raise 'completed run and fresh output required' unless out && !File.exist?(out)
child = run + '/run'
sha = ->p { Digest::SHA256.file(p).hexdigest }
processes = Dir.glob(child + '/*/*.process.json').sort.map do |p|
  r = JSON.parse(File.read(p))
  {path: p, sha256: sha.call(p), state: r['state'], stage: r['stage'], exit: r['exit'],
   timeout: r['timeout'], seconds: r['seconds'],
   parentReaped: r['parentReaped'], processGroupQuiescent: r['processGroupQuiescent']}
end
bootstrap = processes.find { |p| p[:stage] == 'from-scratch' }
phases_path = child + '/bootstrap/phase-observations.json'
phases = File.file?(phases_path) ? JSON.parse(File.read(phases_path)) : nil
envelopes = []
if bootstrap && phases
  points = phases.fetch('boundaries')
  points.each_with_index do |point, i|
    finish = i + 1 < points.size ? points[i + 1]['firstObservedSeconds'] : bootstrap[:seconds]
    envelopes << point.merge('untilNextObservationSeconds' => finish && finish - point['firstObservedSeconds'])
  end
end
receipt_path = File.file?(child + '/receipt.json') ? child + '/receipt.json' : run + '/receipt.json'
receipt = JSON.parse(File.read(receipt_path))
outer = JSON.parse(File.read(run + '/receipt.json'))
FileUtils.mkdir_p(out)
record = {scope: 'current-source stage observations, not matched performance qualification',
  terminalReceipt: {path: receipt_path, sha256: sha.call(receipt_path)},
  childTerminalReceiptPresent: File.file?(child + '/receipt.json'),
  sourceLock: {path: 'evidence/research/darwin-native-policy/source.lock.json',
               sha256: sha.call('evidence/research/darwin-native-policy/source.lock.json')},
  processes: processes, phaseObserver: phases, phaseObservationEnvelopes: envelopes,
  fromScratchSeconds: bootstrap && bootstrap[:seconds],
  topLevelProcessSeconds: processes.sum { |r| r[:seconds] || 0 },
  wholeOutcome: receipt['decision'] || receipt['verdict'] || receipt['outcome'],
  unknownNativeStages: processes.select { |p| p[:state] != 'OBSERVED' }.map { |p| p[:stage] },
  nativeTargetRequested: !bootstrap.nil?,
  stageOutcomes: receipt.fetch('steps', []).map { |r| {id: r['id'], outcome: r['outcome'], reason: r['reason'], seconds: r['stageSeconds']} },
  outerWholeSeconds: outer['wholeSeconds'], outerTimeout: outer['timeout'],
  matchedWholeBuildSpeedupMeasured: false, perTranslationUnitCostsMeasured: false,
  peakRssMeasured: false, commitAdmitted: false}
File.write(out + '/cost.json', JSON.pretty_generate(record) + "\n")
puts JSON.generate(processes: processes.size, fromScratchSeconds: record[:fromScratchSeconds],
  phaseBoundaries: envelopes.size, matchedSpeedupMeasured: false)
