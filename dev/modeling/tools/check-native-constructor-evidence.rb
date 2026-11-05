require 'json'; require 'digest'; require 'fileutils'; require 'open3'
projection, out = ARGV
raise 'native projection and fresh output required' unless out && !File.exist?(out)
m = JSON.parse(File.read(projection)); law = m.fetch('constructors').fetch(0)
path = 'evidence/research/darwin-native-policy/producer-receipt-controls.json'
control = JSON.parse(File.read(path)); run = control.fetch('taskReceipt')
sha = ->p { Digest::SHA256.file(p).hexdigest }
raise 'control receipt changed' unless sha.call(run['path']) == run['sha256']
receipt = JSON.parse(File.read(run['path']))
raise 'successful declared control class required' unless receipt['state'] == 'returned' && receipt['exit'] == 0 && receipt.fetch('argv').include?('tests.test_bootstrap_artifacts.ProducerActivationTests')
sources = %w[src/gambit_smp/bootstrap_artifacts.py src/gambit_smp/workspace.py tests/test_bootstrap_artifacts.py]
hashes = sources.to_h { |p| [p, sha.call(p)] }
raise 'tested source differs' unless hashes.all? { |p, h| control.fetch('sourceHashesObservedAfterRun')[p] == h }
identity = Digest::SHA256.hexdigest(JSON.generate(hashes))
aspects = %w[artifactIdentity instanceIdentity mutationLaw admission]
methods = {
  'artifactIdentity' => %w[test_only_mutable_work_roles_accept_a_producer_activation],
  'instanceIdentity' => %w[test_actual_receipt_nests_engine_and_flat_id_cannot_override_it test_constructor_identity_is_producer_and_endpoint_not_content_identity test_changed_header_and_foreign_endpoint_cannot_create_activation],
  'mutationLaw' => %w[test_mutation_stays_with_its_producer_and_cannot_change_the_input_or_successor]
}
text = File.read('tests/test_bootstrap_artifacts.py')
raise 'control method absent' unless methods.values.flatten.all? { |n| text.include?('def ' + n + '(') }
FileUtils.mkdir_p(out)
data = ->name, cols, rows { '(relation ' + name + ' (' + cols + ') (' + rows.map { |r| '(' + r.map(&:to_json).join(' ') + ')' }.join(' ') + '))' }
results = {}
%w[current-source stale-code missing-evidence].each do |id|
  body = File.read('dev/modeling/ascent/darwin-cost.rules.scm')
  witness = id == 'missing-evidence' ? [] : methods.keys.map { |a| [a, id == 'stale-code' ? 'stale' : identity] }
  {'dxCtorLaw' => ['aspect text', aspects.map { |a| [a, law.fetch(a)] }],
   'dxCtorSource' => ['digest', [[identity]]],
   'dxCtorWitness' => ['aspect digest', witness]}.each do |name, (cols, rows)|
    raise 'missing law input' unless body.sub!('(relation ' + name + ' (' + cols + '))', data.call(name, cols, rows))
  end
  selector = '(define-evidence (query) (sources clue factor binding) (outputs question dxCtorSourceCovered dxCtorOpen dxActualReusePermit dxM8Retired) (include clue-selection-schema)' + "\n" + body + "\n(relation question (claim))\n((question A) <-- (dxCtorLaw A _))\n)"
  req = '((displayBytes 65536) (selector ' + selector.to_json + '))'
  File.write(out + '/' + id + '.request.scm', req + "\n")
  stdout, stderr, status = Open3.capture3('.venv/bin/gambit-smp', '--task', 'modern-c-frame-contract', 'trajectory', 'clues', req)
  File.write(out + '/' + id + '.result.scm', stdout); File.write(out + '/' + id + '.stderr', stderr)
  raise 'incomplete ASCENT' unless status.success? && stdout.include?('("evaluationComplete" #t)')
  covered = stdout[/\("dxCtorSourceCovered" \(((?:\("[^"]*"\)\s*)*)\)\)/m, 1] || raise('missing coverage')
  actual = covered.scan(/\("([^"]+)"\)/).flatten.sort
  expected = id == 'current-source' ? methods.keys.sort : []
  raise 'unearned source coverage' unless actual == expected
  opened = stdout[/\("dxCtorOpen" \(((?:\("[^"]*"\)\s*)*)\)\)/m, 1] || raise('missing open obligations')
  raise 'open admission obligation lost' unless opened.scan(/\("([^"]+)"\)/).flatten.sort == (aspects - expected).sort
  %w[dxActualReusePermit dxM8Retired].each { |r| raise 'native admission manufactured' unless stdout.include?('("' + r + '" ())') }
  results[id] = {synthetic: id != 'current-source', sourceTestCovered: actual,
    nativeAdmissionClosed: false, sameCaseHistoryStillRequired: true}
end
File.write(out + '/receipt.json', JSON.pretty_generate({nativeProjectionSha256: sha.call(projection),
  controlSource: {path: path, sha256: sha.call(path)}, sourceSetDigest: identity, methodRefinement: methods,
  scenarios: results, admissionProofOpen: true, nativeRuntimeAccepted: false, commitAdmitted: false}) + "\n")
puts JSON.generate(controls: results.size, sourceAspectsCovered: 3, nativeAdmission: false)
