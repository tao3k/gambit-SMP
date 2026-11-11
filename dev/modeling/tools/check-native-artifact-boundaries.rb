require 'json'; require 'digest'; require 'fileutils'; require 'open3'
projection, out = ARGV
raise 'native projection and fresh output required' unless out && !File.exist?(out)
m = JSON.parse(File.read(projection))
raise 'incomplete native projection' unless m.fetch('boundaries').size == 3 && m.fetch('duties').size == 9
FileUtils.mkdir_p(out)
data = ->name, cols, rows { '(relation ' + name + ' (' + cols + ') (' + rows.map { |r| '(' + r.map(&:to_json).join(' ') + ')' }.join(' ') + '))' }
scenarios = {
  'native-policy' => [%w[native-policy], ['Native compilation', 'Native linking'], []],
  'scheme-source' => [%w[scheme-source], m['boundaries'].map { |b| b['role'] }, []],
  'native-object' => [%w[native-object], ['Native linking'], []],
  'no-change' => [[], [], []],
  'unknown-read' => [%w[unclassified-native-effect], [], %w[unclassified-native-effect]]
}
results = {}
scenarios.each do |id, (changed, expected, unmapped)|
  body = File.read('dev/modeling/ascent/darwin-cost.rules.scm')
  facts = {
    'dxQuestion' => ['id status', m['duties'].map { |d| [d['fidelityId'], d['researchStatus']] }],
    'dxArtifactInput' => ['role input', m['boundaries'].flat_map { |b| b['invalidators'].split(';').map { |i| [b['role'], i.strip] } }],
    'dxArtifactEdge' => ['upstream downstream', m['boundaries'].map { |b| [b['role'], b['downstream']] unless b['downstream'].empty? }.compact],
    'dxChangedInput' => ['input', changed.map { |i| [i] }]
  }
  facts.each do |name, (cols, rows)|
    raise 'missing DSL input' unless body.sub!('(relation ' + name + ' (' + cols + '))', data.call(name, cols, rows))
  end
  selector = '(define-evidence (query) (sources clue factor binding) (outputs question dxProjectedInvalidation dxUnmappedInput dxActualReusePermit dxM8Retired dxFullBuildGain) (include clue-selection-schema)' + "\n" + body + "\n(relation question (claim))\n((question I) <-- (dxQuestion I _))\n)"
  req = '((displayBytes 65536) (selector ' + selector.to_json + '))'
  File.write(out + '/' + id + '.request.scm', req + "\n")
  stdout, stderr, status = Open3.capture3('.venv/bin/gambit-smp', '--task', 'modern-c-frame-contract', 'trajectory', 'clues', req)
  File.write(out + '/' + id + '.result.scm', stdout)
  File.write(out + '/' + id + '.stderr', stderr)
  raise 'incomplete ASCENT' unless status.success? && stdout.include?('("evaluationComplete" #t)')
  %w[dxActualReusePermit dxM8Retired dxFullBuildGain].each { |r| raise 'unearned authority' unless stdout.include?('("' + r + '" ())') }
  # These result columns contain only inert, fixed model labels.
  invalidation = stdout[/\("dxProjectedInvalidation" \(((?:\("[^"]*"\)\s*)*)\)\)/m, 1] || raise('missing projected result')
  actual = invalidation.scan(/\("([^"]+)"\)/).flatten.sort
  raise 'incorrect invalidation closure' unless actual == expected.sort
  unknown = stdout[/\("dxUnmappedInput" \(((?:\("[^"]*"\)\s*)*)\)\)/m, 1] || raise('missing unknown result')
  raise 'unknown input lost' unless unknown.scan(/\("([^"]+)"\)/).flatten.sort == unmapped.sort
  results[id] = {synthetic: true, projectedInvalidation: actual, unresolved: unmapped, reuseAuthorized: false}
end
File.write(out + '/receipt.json', JSON.pretty_generate({nativeProjectionSha256: Digest::SHA256.file(projection).hexdigest,
  questions: m['duties'].size, scenarios: results, modelsReproved: false,
  fullBuildGainMeasured: false, runtimeAdmitted: false, commitAdmitted: false}) + "\n")
puts JSON.generate(questions: m['duties'].size, scenarios: results.size, reuseAuthorized: false)
