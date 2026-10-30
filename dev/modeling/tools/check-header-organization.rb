require 'json'
require 'digest'
require 'fileutils'
require 'open3'

# Source/configuration refinement only. Neither this adapter nor a successful
# bootstrap supplies the outstanding worker-lifetime and unknown-owner proofs.
model_path, partition_path, runtime, gcc, out, source_root, source_lock = ARGV
source_root ||= 'vendor/gambit'
source_lock ||= 'evidence/research/header-organization/source.lock.json'
make_tool=ENV.fetch('GAMBIT_SMP_MAKE',ENV.fetch('MAKE','make'))
raise 'model, partition, runtime, compiler, fresh output required' unless out && !File.exist?(out)
read = ->p { JSON.parse(File.read(p)) }
sha = ->p { Digest::SHA256.file(p).hexdigest }
m = read.call(model_path)
partition = read.call(partition_path)
parts = m.fetch('fragments')
root = File.expand_path(source_root+'/include')
runtime = File.expand_path(runtime)
out = File.expand_path(out)
FileUtils.mkdir_p(out)
records = []
run = lambda do |name, argv, cwd, env = {}|
  stdout, stderr, status = Open3.capture3(env, *argv, chdir: cwd)
  File.binwrite(out + '/' + name + '.stdout', stdout)
  File.binwrite(out + '/' + name + '.stderr', stderr)
  records << {name: name, argv: argv, cwd: cwd, exit: status.exitstatus,
              stdoutSha256: Digest::SHA256.hexdigest(stdout),
              stderrSha256: Digest::SHA256.hexdigest(stderr)}
  File.write(out + '/commands.json', JSON.pretty_generate(records) + "\n")
  raise name + ' failed: ' + stderr unless status.success?
  stdout
end

raise 'model/partition identity' unless m['baselineSha256'] == partition['baselineSha256']
raise 'partition inventory' unless parts.map { |p| p['file'] } == partition['fragments'].map { |p| p['file'] }
raise 'case-fold collision' unless parts.map { |p| p['file'].downcase }.uniq.size == parts.size
bytes = parts.zip(partition['fragments']).map do |p, receipt|
  name = p.fetch('file')
  raise 'private namespace' unless name.match?(%r{\A_gambit/[a-z_]+\.h\.in\z})
  path = root + '/' + name
  raise 'fragment drift ' + name unless sha.call(path) == receipt['sha256']
  File.binread(path)
end.join
raise 'lossy concatenation' unless Digest::SHA256.hexdigest(bytes) == m['baselineSha256']
raise 'driver drift' unless sha.call(m['source'].sub(/\Avendor\/gambit\//,source_root+'/')) == partition['driverSha256']
File.binwrite(out + '/before.h.in', bytes)

# Reuse the target's actual substitution program with an absolute, isolated
# output; do not rewrite the configured or completed producer tree.
run.call('configure-before', ['/bin/sh', runtime + '/config.status',
         '--file=' + out + '/before.h:' + out + '/before.h.in'], out,
         {'CONFIG_HEADERS' => '', 'CONFIG_COMMANDS' => ''})
configured = runtime + '/include/gambit.h'
raise 'configured output differs' unless File.binread(out + '/before.h') == File.binread(configured)
raise 'public header depends on private templates' if File.read(configured).include?('#include "_gambit/')

consumer = <<~C
  #include "gambit.h"
  #include <stddef.h>
  static_assert(__STDC_VERSION__ >= 202311L, "C23 required");
  static_assert(sizeof(___SCMOBJ) == sizeof(___WORD), "public object word width");
  int header_contract(void) {
    return sizeof(___processor_state_struct) + sizeof(___virtual_machine_state_struct);
  }
C
File.write(out + '/consumer.c', consumer)
run.call('c23-consumer', [gcc, '-std=c23', '-Werror', '-I', runtime + '/include',
                        '-c', out + '/consumer.c', '-o', out + '/consumer.o'], out)

run.call('unchanged-header', [make_tool, '--no-print-directory', '-q', 'gambit.h'], runtime + '/include')

# Every fragment is a direct prerequisite of the flat header. -W does not
# touch it; make's dry run must select config.status for each independent edit.
parts.each_with_index do |p, i|
  dry = run.call('dependency-' + i.to_s,
    [make_tool, '--no-print-directory', '-n', '-W', p['file'], 'gambit.h'], runtime + '/include')
  raise 'missing invalidation edge ' + p['file'] unless dry.include?('CONFIG_FILES=') && dry.include?('config.status')
end

# Exercise the actual distribution rule into isolated storage. Original source
# bytes and relative module paths must both survive; no flattened-name copy.
FileUtils.mkdir_p(out + '/distribution/pkg')
run.call('distribution', [make_tool, '--no-print-directory', '-f', runtime + '/include/makefile',
  'dist-pre', 'rootfromhere=' + out + '/distribution', 'herefromroot=include',
  'PACKAGE_TARNAME=pkg', 'srcdirpfx=' + runtime + '/include/'], out)
parts.each do |p|
  name = p['file']
  raise 'distribution drift ' + name unless sha.call(out + '/distribution/pkg/include/' + name) == sha.call(runtime + '/include/' + name)
end

File.write(out + '/receipt.json', JSON.pretty_generate({
  sourceLockSha256: sha.call(source_lock),
  modelProjectionSha256: sha.call(model_path), partitionSha256: sha.call(partition_path),
  baselineSha256: m['baselineSha256'], configuredSha256: sha.call(configured),
  compilerSha256: sha.call(gcc), fragments: parts.size,
  exactByteReconstruction: true, configuredOutputEqual: true,
  c23Consumer: true, dependencyEdges: parts.size, distributionPaths: parts.size,
  installQualified: false, runtimeRetirementAdmitted: false, commitAdmitted: false
}) + "\n")
puts JSON.generate(fragments: parts.size, configuredOutputEqual: true,
                   c23Consumer: true, dependencyEdges: parts.size, distributionPaths: parts.size)
