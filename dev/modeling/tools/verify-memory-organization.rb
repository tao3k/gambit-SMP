require 'json'; require 'digest'; require 'fileutils'; require 'open3'
model=ARGV.fetch(0); split=ARGV.fetch(1); out=ARGV.fetch(2); runtime=ARGV[3]
root=runtime || 'vendor/gambit'
profile=ARGV[5] || 'evidence/fixtures/gerbil-bazel-build-profile/profile.json'
make_tool=ENV.fetch('GAMBIT_SMP_MAKE',ENV.fetch('MAKE','make'))
raise 'fresh output required' if File.exist?(out); FileUtils.mkdir_p(out)
sha=->p { Digest::SHA256.file(p).hexdigest }
m=JSON.parse(File.read(model)); r=JSON.parse(File.read(split+'/split.json'))
raise 'projection drift' unless r['modelSha256']==sha.call(model)
driver=m.fetch('source').sub(/\Avendor\/gambit\//,root+'/'); source=File.binread(split+'/mem-before.c')
raise 'baseline drift' unless sha.call(split+'/mem-before.c')==m['baselineSha256']
includes=File.read(driver).scan(/^#include "(_mem\/[^\"]+)"$/).flatten
raise 'fragment order or coverage drift' unless includes==m['fragments'].map { |f| f['file'] }
reconstructed=File.readlines(driver).take(m['preambleLines']).join
r['fragments'].each do |f|
  p=File.join(File.dirname(driver),f['file']); body=File.binread(p)
  raise 'fragment drift '+p unless sha.call(p)==f['fragmentSha256']
  prefix="#line #{f['firstLine']} ___MEM_SOURCE_FILE\n"
  raise 'diagnostic coordinate drift' unless body.start_with?(prefix)
  suffix=m.fetch('fragmentSuffix')
  raise 'fragment end marker missing' unless body.end_with?(suffix)
  payload=body[prefix.bytesize...(body.bytesize-suffix.bytesize)]
  raise 'payload drift' unless Digest::SHA256.hexdigest(payload)==f['payloadSha256']
  reconstructed<<payload
end
raise 'lossless reconstruction failed' unless reconstructed==source
mk=File.read(root+'/lib/makefile.in')
decl=mk[/^MEMORY_SOURCES = .*?(?=^NORMAL_CPP)/m] || raise('missing fragment dependencies')
listed=decl.sub('MEMORY_SOURCES = ','').gsub(/\\\n/,' ').split
raise 'distribution inventory mismatch' unless listed==includes && mk.include?('NORMAL_SOURCES = $(NORMAL_C) $(NORMAL_CPP) $(NORMAL_H) $(MEMORY_SOURCES)')
raise 'missing distribution subdirectory' unless mk.include?('$(herefromroot)/_mem')
dep=mk[/^mem@obj@:.*/]; raise 'missing rebuild dependencies' unless dep.include?('$(MEMORY_SOURCES)')
rows=[]
run=lambda do |id,argv,expected=0|
  stdout,stderr,s=Open3.capture3(*argv)
  File.binwrite(out+'/'+id+'.stdout',stdout); File.binwrite(out+'/'+id+'.stderr',stderr)
  rows<<{id:id,argv:argv,exit:s.exitstatus,signal:s.termsig,stdoutSha256:Digest::SHA256.hexdigest(stdout),stderrSha256:Digest::SHA256.hexdigest(stderr)}
  File.write(out+'/progress.json',JSON.pretty_generate(rows)+"\n")
  raise 'failed '+id unless expected.nil? || s.exitstatus==expected
  s.exitstatus
end
# Use the actual make prerequisite expansion and -W; never touch source mtimes.
target=File.expand_path(out+'/mem.o'); File.write(target,'dependency fixture, not a native object')
make=File.expand_path(out+'/dependencies.mk')
File.write(make,decl+"\nVPATH := #{File.expand_path(root+'/lib')}\n"+dep.sub('mem@obj@',target)+"\n\t@false\n")
run.call('make-unchanged',[make_tool,'-f',make,'-q',target])
includes.each_with_index { |p,i| run.call('make-fragment-'+i.to_s,[make_tool,'-f',make,'-q','-W',p,target],1) }
header=runtime ? runtime+'/include' : '.cache/tasks/modern-c-frame-contract/cohort/root-task-c-native-profile/include'
prior=runtime || '.cache/tasks/modern-c-frame-contract/runs/bazel-request-custody/run/bootstrap/step-receipt.json'
ancestor=runtime || JSON.parse(File.read(prior))['outputs']['runtime']['workspace']
include_args=['-DHAVE_CONFIG_H','-D___LIBRARY','-I',File.expand_path(header),'-I',File.expand_path(ancestor+'/include'),'-I',File.expand_path(root+'/lib')]
gcc=ARGV[4] || ENV.fetch('GAMBIT_SMP_CC',ENV.fetch('CC','cc'))
xcrun=ENV.fetch('GAMBIT_SMP_XCRUN','xcrun')
clang,err,s=Open3.capture3(xcrun,'--find','clang');raise err unless s.success?;clang=clang.strip
sdk,err,s=Open3.capture3(xcrun,'--show-sdk-path');raise err unless s.success?
before=File.expand_path(split+'/mem-before.c'); after=File.expand_path(driver)
mapping='-ffile-prefix-map='+before+'='+after
cases={'release'=>[], 'gc-debug'=>['-D___DEBUG_GARBAGE_COLLECT'],
       'limits-debug'=>['-D___DEBUG_STACK_LIMIT','-D___DEBUG_HEAP_LIMIT'],
       'combined-debug'=>['-D___DEBUG_GARBAGE_COLLECT','-D___DEBUG_STACK_LIMIT','-D___DEBUG_HEAP_LIMIT']}
equal=[]
{'gcc'=>[gcc,'-std=c23'], 'clang'=>[clang,'-std=c2x','-isysroot',sdk.strip]}.each do |cc,command|
  cases.each do |name,defines|
    %w[before after].each do |side|
      input=side=='before' ? before : after
      run.call(cc+'-'+name+'-'+side,[*command,*include_args,mapping,*defines,'-E','-P',input,'-o',File.expand_path(out+'/'+cc+'-'+name+'-'+side+'.i')])
    end
    stem=out+'/'+cc+'-'+name
    normalize=->p { File.binread(p).sub(/\n+\z/,"\n") }
    raise 'preprocessed tokens differ '+stem unless normalize.call(stem+'-before.i')==normalize.call(stem+'-after.i')
    equal<<{compiler:cc,configuration:name,sha256:sha.call(stem+'-after.i'),beforeSha256:sha.call(stem+'-before.i'),trailingNewlinesIgnored:true}
  end
end
objects=[]
%w[release].each do |name|
  %w[before after].each do |side|
    input=side=='before' ? before : after
    run.call('object-'+name+'-'+side,[gcc,'-std=c23',*include_args,mapping,*cases[name],'-O3','-fno-common','-c',input,'-o',File.expand_path(out+'/'+name+'-'+side+'.o')])
  end
  raise 'object bytes differ '+name unless File.binread(out+'/'+name+'-before.o')==File.binread(out+'/'+name+'-after.o')
  objects<<{configuration:name,sha256:sha.call(out+'/'+name+'-after.o')}
end
baseline_failures=[]
%w[gc-debug limits-debug combined-debug].each do |name|
  statuses=%w[before after].map do |side|
    input=side=='before' ? before : after
    run.call('baseline-failure-'+name+'-'+side,[gcc,'-std=c23',*include_args,mapping,*cases[name],'-O3','-fno-common','-c',input,'-o',File.expand_path(out+'/'+name+'-'+side+'.o')],nil)
  end
  raise 'override outcome differs '+name unless statuses[0]==statuses[1] && [0,1].include?(statuses[0])
  if statuses[0]==0
    raise 'debug object differs '+name unless File.binread(out+'/'+name+'-before.o')==File.binread(out+'/'+name+'-after.o')
    baseline_failures<<{configuration:name,exit:0,matchingObjectBytes:true,reason:'Macro override pair, not separately configured debug runtime'}
    next
  end
  first=File.read(out+'/baseline-failure-'+name+'-before.stderr').gsub(before,after)
  second=File.read(out+'/baseline-failure-'+name+'-after.stderr')
  errors=->text { text.lines.select { |line| line.match?(/:\d+:\d+: (?:fatal )?error:/) } }
  raise 'baseline errors differ '+name unless !errors.call(first).empty? && errors.call(first)==errors.call(second)
  baseline_failures<<{configuration:name,exit:1,matchingErrorLocationsAndMessages:true,diagnosticsByteIdentical:first==second,reason:'Debug overrides fail with this release-configured header on both sides; matched debug configuration remains unqualified'}
end
files=([driver,root+'/lib/makefile.in',root+'/include/gambit.h.in']+includes.map { |p| root+'/lib/'+p }).to_h { |p| [p,sha.call(p)] }
receipt={scope:'Lossless structural split of current candidate, not proof of the preceding runtime changes or complete bootstrap',
  sourceSha256:m['baselineSha256'],modelSha256:sha.call(model),splitReceiptSha256:sha.call(split+'/split.json'),
  fragments:includes.size,byteReconstruction:true,sourceLines:r['sourceLines'],driverLines:r['driverLines'],
  fragmentLines:r['fragments'].map { |f| f['pastLine']-f['firstLine'] },
  preprocessEqual:equal,objectEqual:objects,baselineFailures:baseline_failures,makeDependencyCases:includes.size+1,files:files,
  profileSha256:sha.call(profile),configuredHeaderSha256:sha.call(header+'/gambit.h'),
  configuredAncestor:prior,libraryCompilation:true,rows:rows,fullBootstrap:false,retirementAdmitted:false,commitAdmitted:false}
File.write(out+'/receipt.json',JSON.pretty_generate(receipt)+"\n")
puts JSON.generate(fragments:includes.size,reconstruction:true,preprocessPairs:equal.size,objectPairs:objects.size,makeCases:includes.size+1,commitAdmitted:false)
