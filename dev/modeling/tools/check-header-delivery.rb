require 'json'; require 'digest'; require 'fileutils'; require 'open3'
model_path, partition_path, native_path, out = ARGV
raise 'model, partition, optional native receipt or -, fresh output required' unless out && !File.exist?(out)
FileUtils.mkdir_p(out)
sha = ->p { Digest::SHA256.file(p).hexdigest }
m = JSON.parse(File.read(model_path)); part = JSON.parse(File.read(partition_path))
source = sha.call('evidence/research/header-organization/source.lock.json')
profile = sha.call('evidence/research/worker-role-handoff/profile.json')
baseline = m.fetch('baselineSha256')
raise 'model/partition' unless baseline == part['baselineSha256'] && m['fragments'].map { |p| p['file'] } == part['fragments'].map { |p| p['file'] }
payload = part['fragments'].map do |p|
  path = 'vendor/gambit/include/' + p['file']
  raise 'actual source drift ' + path unless sha.call(path) == p['sha256']
  File.binread(path)
end.join
raise 'not exact reconstruction' unless Digest::SHA256.hexdigest(payload) == baseline
raise 'driver drift' unless sha.call(m['source']) == part['driverSha256']
native = native_path == '-' ? nil : JSON.parse(File.read(native_path))
if native
  raise 'native evidence identity' unless native['sourceLockSha256'] == source && native['modelProjectionSha256'] == sha.call(model_path) && native['partitionSha256'] == sha.call(partition_path)
  raise 'native observations incomplete' unless native['configuredOutputEqual'] && native['c23Consumer'] && native['dependencyEdges'] == m['fragments'].size && native['distributionPaths'] == m['fragments'].size
end
data = ->name, cols, rows { '(relation ' + name + ' (' + cols + ') (' + rows.map { |r| '(' + r.map { |v| v.to_json }.join(' ') + ')' }.join(' ') + '))' }
scenarios = {}
cases = %w[wrong-source wrong-fragment missing-fragment unknown-fragment wrong-partition current]
cases += %w[wrong-native-profile unknown-native-result] if native
cases.each do |name|
  needs = part['fragments'].map { |p| [p['file'], p['sha256']] }
  evidence = needs.map { |id, h| [id, h, baseline, source, 'pass'] }
  partition_rows = [[baseline, source, 'pass']]
  case name
  when 'wrong-source' then evidence.each { |r| r[3] = 'stale' }
  when 'wrong-fragment' then evidence[0][1] = 'stale'
  when 'missing-fragment' then evidence.pop
  when 'unknown-fragment' then evidence << evidence[0][0..3] + ['unknown']
  when 'wrong-partition' then partition_rows[0][2] = 'unknown'
  end
  native_rows = native ? %w[configured-output c23-consumer all-dependencies distribution-paths].map { |x| [source, profile, x, 'pass'] } : []
  native_rows.each { |r| r[1] = 'stale' } if name == 'wrong-native-profile'
  native_rows << [source, profile, 'c23-consumer', 'unknown'] if name == 'unknown-native-result'
  body = File.read('dev/modeling/ascent/header-organization.rules.scm')
  {'hoIdentity' => ['baseline source profile', [[baseline, source, profile]]],
   'hoPart' => ['id digest', needs],
   'hoPartEvidence' => ['id digest baseline source outcome', evidence],
   'hoPartition' => ['baseline source exact', partition_rows],
   'hoNative' => ['source profile check outcome', native_rows]}.each do |rel, (cols, rows)|
    raise 'missing rule input ' + rel unless body.sub!('(relation ' + rel + ' (' + cols + '))', data.call(rel, cols, rows))
  end
  d = '(define-evidence (query) (sources clue factor binding) (outputs question hoPartMissing hoByteQualified hoConsumerQualified hoRuntimeAdmission) (include clue-selection-schema)' + "\n" + body + "\n(relation question (claim))\n((question I) <-- (hoPart I _))\n)\n"
  req = '((displayBytes 65536) (selector ' + d.to_json + '))'
  File.write(out + '/' + name + '.request.scm', req + "\n")
  stdout, stderr, status = Open3.capture3('.venv/bin/gambit-smp', '--task', 'modern-c-frame-contract', 'trajectory', 'clues', req)
  File.write(out + '/' + name + '.result.scm', stdout); File.write(out + '/' + name + '.stderr', stderr)
  raise 'incomplete ASCENT ' + name unless status.success? && stdout.include?('("evaluationComplete" #t)') && stdout.include?('("hoRuntimeAdmission" ())')
  byte = !stdout.include?('("hoByteQualified" ())')
  consumer = !stdout.include?('("hoConsumerQualified" ())')
  raise 'source control failure ' + name unless byte == %w[current wrong-native-profile unknown-native-result].include?(name)
  raise 'consumer control failure ' + name unless consumer == (name == 'current' && !native.nil?)
  scenarios[name] = {synthetic: name != 'current', byteQualified: byte, consumerQualified: consumer}
end
File.write(out + '/receipt.json', JSON.pretty_generate({sourceLockSha256: source, profileSha256: profile,
  modelProjectionSha256: sha.call(model_path), partitionSha256: sha.call(partition_path),
  nativeReceiptSha256: native && sha.call(native_path), fragments: m['fragments'].size,
  scenarios: scenarios, runtimeAdmitted: false, commitAdmitted: false}) + "\n")
puts JSON.generate(fragments: m['fragments'].size, controls: scenarios.size,
                   byteQualified: true, consumerQualified: !native.nil?, runtimeAdmitted: false)
