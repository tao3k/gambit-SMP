require 'json'; require 'digest'; require 'fileutils'; require 'open3'
model_path, out = ARGV
raise 'native projection and fresh output required' unless out && !File.exist?(out)
FileUtils.mkdir_p(out)
sha = ->p { Digest::SHA256.file(p).hexdigest }
m = JSON.parse(File.read(model_path))
raise 'question closure changed; re-evaluate this adapter' if m['duties'].any? { |d| d['researchStatus'] == 'closed' }
path = 'evidence/research/bootstrap-cost/configuration-lineage.json'
lineage = JSON.parse(File.read(path)); identity = sha.call(path)
lineage['sources'].each { |r| raise 'configuration drift' unless sha.call(r['path']) == r['sha256'] }
data = ->name, cols, rows { '(relation ' + name + ' (' + cols + ') (' + rows.map { |r| '(' + r.map(&:to_json).join(' ') + ')' }.join(' ') + '))' }
results = {}
%w[wrong-identity same-policy unknown-policy current].each do |name|
  current = lineage['sources'].reject { |r| r['id'] == 'retained-patched-darwin' }.map { |r| [identity, r['id'], r['macroTrackingZeroPresent'] ? 'enabled' : 'absent'] }
  retained = lineage['sources'].select { |r| r['id'] == 'retained-patched-darwin' }.map { |r| [identity, r['id'], r['macroTrackingZeroPresent'] ? 'enabled' : 'absent'] }
  raise 'retained Darwin evidence absent' unless retained.size == 1
  current.each { |r| r[0] = 'stale' } if name == 'wrong-identity'
  current.each { |r| r[2] = 'enabled' } if name == 'same-policy'
  current.each { |r| r[2] = 'unknown' } if name == 'unknown-policy'
  body = File.read('dev/modeling/ascent/darwin-cost.rules.scm')
  {'dxQuestion' => ['id status', m['duties'].map { |d| [d['fidelityId'], d['researchStatus']] }],
   'dxEvidenceIdentity' => ['digest', [[identity]]],
   'dxConfigured' => ['digest id macroPolicy', current],
   'dxRetained' => ['digest id macroPolicy', retained]}.each do |rel, (cols, rows)|
    raise 'missing rule input' unless body.sub!('(relation ' + rel + ' (' + cols + '))', data.call(rel, cols, rows))
  end
  d = '(define-evidence (query) (sources clue factor binding) (outputs question dxOpen dxMacroPolicyDifference dxFullBuildGain) (include clue-selection-schema)' + "\n" + body + "\n(relation question (claim))\n((question I) <-- (dxQuestion I _))\n)\n"
  req = '((displayBytes 65536) (selector ' + d.to_json + '))'
  File.write(out + '/' + name + '.request.scm', req + "\n")
  stdout, stderr, status = Open3.capture3('.venv/bin/gambit-smp', '--task', 'modern-c-frame-contract', 'trajectory', 'clues', req)
  File.write(out + '/' + name + '.result.scm', stdout); File.write(out + '/' + name + '.stderr', stderr)
  raise 'incomplete ASCENT' unless status.success? && stdout.include?('("evaluationComplete" #t)') && stdout.include?('("dxFullBuildGain" ())')
  difference = !stdout.include?('("dxMacroPolicyDifference" ())')
  raise 'wrong configuration inference' unless difference == (name == 'current')
  raise 'lost open obligation' unless m['duties'].all? { |d| stdout.include?('("' + d['fidelityId'] + '")') }
  results[name] = {synthetic: name != 'current', macroPolicyDifference: difference, fullBuildGain: false}
end
File.write(out + '/receipt.json', JSON.pretty_generate({nativeProjectionSha256: sha.call(model_path),
  configurationLineageSha256: identity, questions: m['duties'].size, allQuestionsOpen: true,
  scenarios: results, fullBuildGainMeasured: false, runtimeAdmitted: false, commitAdmitted: false}) + "\n")
puts JSON.generate(questions: m['duties'].size, controls: results.size, fullBuildGain: false)
