require 'json'; require 'digest'; require 'fileutils'; require 'open3'
projection, out, source_root = ARGV
source_root ||= 'vendor/gambit'
make_tool=ENV.fetch('GAMBIT_SMP_MAKE',ENV.fetch('MAKE','make'))
raise 'native projection and fresh output required' unless out && !File.exist?(out)
out = File.expand_path(out); FileUtils.mkdir_p(out)
m = JSON.parse(File.read(projection))
path = source_root+'/lib/makefile.in'; text = File.read(path)
decl = text[/^MEMORY_SOURCES = .*?(?=^NORMAL_CPP)/m] || raise('source inventory absent')
names = decl.sub('MEMORY_SOURCES = ', '').gsub(/\\\n/, ' ').split
raise 'model/source inventory mismatch' unless names == m['fragments'].map { |p| p['file'] }
raise 'private directory required' unless names.all? { |p| p.start_with?('_mem/') }
dep = text[/^mem@obj@:.*$/] || raise('object dependencies absent')
target = out + '/mem.o'; File.write(target, 'dependency fixture, not a native object')
make = out + '/dependencies.mk'
File.write(make, decl + "\nVPATH := #{File.expand_path(source_root+'/lib')}\n" + dep.sub('mem@obj@', target) + "\n\t@false\n")
rows = []
run = lambda do |id, argv, expected|
  stdout, stderr, status = Open3.capture3(*argv)
  File.write(out + '/' + id + '.stdout', stdout); File.write(out + '/' + id + '.stderr', stderr)
  rows << {id: id, argv: argv, exit: status.exitstatus, expected: expected}
  File.write(out + '/commands.json', JSON.pretty_generate(rows) + "\n")
  raise 'unexpected make outcome ' + id unless status.exitstatus == expected
end
run.call('unchanged', [make_tool, '-f', make, '-q', target], 0)
names.each_with_index { |p, i| run.call('fragment-' + i.to_s, [make_tool, '-f', make, '-q', '-W', p, target], 1) }
dist = text[/^dist-pre dist-devel-pre:.*?(?=^dist-post)/m] || raise('distribution rule absent')
FileUtils.mkdir_p(out + '/pkg')
distmake = out + '/distribution.mk'
File.write(distmake, decl + "\nDISTFILES = $(MEMORY_SOURCES)\n" + dist)
run.call('private-distribution', [make_tool, '-f', distmake, 'dist-pre',
  'rootfromhere=' + out, 'PACKAGE_TARNAME=pkg', 'herefromroot=lib',
  'srcdirpfx=' + File.expand_path(source_root+'/lib') + '/'], 0)
sha = ->p { Digest::SHA256.file(p).hexdigest }
names.each { |p| raise 'distribution byte/path mismatch' unless sha.call(out + '/pkg/lib/' + p) == sha.call(source_root+'/lib/' + p) }
File.write(out + '/receipt.json', JSON.pretty_generate({modelProjectionSha256: sha.call(projection),
  makefileTemplateSha256: sha.call(path), sourceInventory: names.to_h { |p| [p, sha.call(source_root+'/lib/' + p)] },
  dependencyCases: names.size + 1, privateDistributionPaths: names.size,
  nativeObjectCompiled: false, fullDistributionQualified: false, commitAdmitted: false}) + "\n")
puts JSON.generate(dependencyCases: names.size + 1, privateDistributionPaths: names.size, fullBootstrap: false)
