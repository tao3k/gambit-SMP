require 'json'; require 'digest'; require 'fileutils'; require 'open3'
b=ARGV.fetch(0); raise 'fresh output required' if File.exist?(b); FileUtils.mkdir_p(b+'/include')
root=Dir.pwd; sha=->p { Digest::SHA256.file(p).hexdigest }
prior='.cache/tasks/modern-c-frame-contract/runs/bazel-request-custody/run/bootstrap/step-receipt.json'
boot=JSON.parse(File.read(prior)); raise 'old bootstrap not complete' unless boot['outcome']=='PASS' && boot['fullTwoPassBootstrapEstablished']
src=boot['outputs']['runtime']['workspace']; src=File.expand_path(src)
before=File.read('.cache/tasks/modern-c-frame-contract/cohort/root-task-c-before/include/gambit.h.in')
after=File.read('vendor/gambit/include/gambit.h.in')
first='/* Execution roots, GC membership and collector work have distinct owners.'
last='/* Setup parameters structure */'
slice=->s { s[s.index(first)...s.index(last)] }
old=slice.call(before); fresh=slice.call(after)
raise 'template interpolation in changed slice' if old.include?('@') || fresh.include?('@')
h=File.read(src+'/include/gambit.h'); raise 'configured ancestor mismatch' unless h.scan(old).size==1
File.write(b+'/include/gambit.h',h.sub(old,fresh)); FileUtils.cp(src+'/include/config.h',b+'/include/config.h')
gcc='/opt/homebrew/Cellar/gcc/16.2.0/bin/gcc-16'
cc='/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang'
sdk,err,status=Open3.capture3('/usr/bin/xcrun','--show-sdk-path'); raise err unless status.success?
rows=[]; expected="PUBLICATION-PASS\nCLAIM-RACE-PASS\nARENA-PASS\n"
run=lambda do |id,argv,oracle=nil|
 stdout,stderr,s=Open3.capture3({'PATH'=>'/usr/bin:/bin'},*argv)
 File.write(b+'/'+id+'.stdout',stdout); File.write(b+'/'+id+'.stderr',stderr)
 rows<<{id:id,argv:argv,exit:s.exitstatus,signal:s.termsig,stdoutSha256:Digest::SHA256.hexdigest(stdout),stderrSha256:Digest::SHA256.hexdigest(stderr),oracleMatched:oracle.nil? || stdout==oracle}
 File.write(b+'/progress.json',JSON.pretty_generate(rows)+"\n")
 raise 'failed '+id unless s.success? && (oracle.nil? || stdout==oracle)
end
include_args=['-DHAVE_CONFIG_H','-I',File.expand_path(b+'/include')]
run.call('gcc-build',[gcc,'-O1','-pthread',*include_args,root+'/vendor/gambit/tests/gc-root-task.c','-o',b+'/kernel'])
run.call('gcc-run',[File.expand_path(b+'/kernel')],expected)
run.call('sanitizer-build',[cc,'-std=c2x','-isysroot',sdk.strip,'-O1','-g','-pthread','-fsanitize=address,undefined','-fno-omit-frame-pointer',*include_args,root+'/vendor/gambit/tests/gc-root-task.c','-o',b+'/kernel-sanitized'])
run.call('sanitizer-run',[File.expand_path(b+'/kernel-sanitized')],expected)
run.call('mem-syntax',[gcc,'-fsyntax-only','-O1',*include_args,'-I',src+'/include','-I',root+'/vendor/gambit/lib',root+'/vendor/gambit/lib/mem.c'])
run.call('setup-syntax',[gcc,'-fsyntax-only','-O1',*include_args,'-I',src+'/include','-I',root+'/vendor/gambit/lib',root+'/vendor/gambit/lib/setup.c'])
files=%w[include/gambit.h.in lib/mem.c lib/setup.c tests/gc-root-task.c].to_h { |p| [p,sha.call('vendor/gambit/'+p)] }
File.write(b+'/receipt.json',JSON.pretty_generate({scope:'Actual header C kernel, pthread claim race and syntax of current mem/setup with exact changed header slice; not linked new-runtime bootstrap or complete GC acceptance',
 source:files,profileSha256:sha.call('evidence/fixtures/gerbil-bazel-build-profile/profile.json'),configuredHeaderSha256:sha.call(b+'/include/gambit.h'),
 configuredAncestor:prior,configuredAncestorSha256:sha.call(prior),sliceHasTemplateParameters:false,rows:rows,fullBootstrap:false,retirementAdmitted:false,commitAdmitted:false})+"\n")
puts JSON.generate(checks:rows.size,tests:3,sanitizers:true,fullBootstrap:false,retirementAdmitted:false)
