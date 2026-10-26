require 'json'; require 'yaml'; require 'digest'; require 'fileutils'
model=ARGV.fetch(0); m=JSON.parse(File.read(model)); sha=->p { Digest::SHA256.file(p).hexdigest }
catalog_only=ARGV[1]=='--catalog-only'
cases_only=ARGV[1]=='--cases-only'
unless catalog_only
e='evidence/research/modular-smp-bootstrap'; FileUtils.mkdir_p(e+'/model')
FileUtils.cp(model,e+'/model/native-projection.json'); FileUtils.cp(File.dirname(model)+'/native-metadata.json',e+'/model/native-metadata.json')
plan=m.merge('modelSha256'=>sha.call('dev/refactoring/modern-c/models/sysml/modular-smp-validation.sysml'),'nativeProjectionSha256'=>sha.call(model))
File.write(e+'/ci-plan.json',JSON.pretty_generate(plan)+"\n")
end
configure=%w[--enable-march= --enable-single-host=0 --enable-multiple-vms --enable-smp --enable-c-opt=-O1 --enable-c-opt-rts=yes --enable-gcc-opts --enable-inline-jumps --enable-dynamic-clib --enable-trust-c-tco --enable-multiple-threaded-vms]
m['lanes'].each { |c| raise 'inconsistent qualified case name' unless c['id']==c['namespace']+'.'+c['name'] }; modules=m['lanes'].map { |c| c.merge('program'=>c['program'].delete_prefix('vendor/gambit/')) }
File.write('vendor/gambit/tests/smp/catalog.scm', ";;; Derived from native SysML in the separate SMP/dev repository.\n(##namespace (\"gambit#tests#smp#\" cases))\n(define cases (quote (\n"+modules.map { |c| '  ('+%w[id kind program stdout topology budget namespace name].map { |k| JSON.generate(c[k]) }.join(' ')+')' }.join("\n")+"\n)))\n")
if cases_only
  # Native cases are a SysML projection. Preserve the qualified tool install,
  # configure/bootstrap commands and watchdogs already maintained in this CI.
  workflow=YAML.safe_load(File.read(m.fetch('workflow')),aliases:false)
  steps=workflow.fetch('jobs').fetch('smp').fetch('steps')
  is_case=->s { id=s.fetch('env',{}).fetch('GAMBIT_SMP_CASE',''); id.start_with?('gambit.smp.') && id!='gambit.smp.bootstrap.two-pass' }
  first=steps.index { |s| is_case.call(s) }
  raise 'existing native case boundary missing' unless first
  preserved=steps.reject { |s| is_case.call(s) }
  native='gsi/gsi -:p1,~~lib=lib,~~bin=bin,~~include=include tests/smp/suite.scm'
  generated=modules.map { |c| {'id'=>c['id'].tr('.-','__'),'name'=>'SMP: '+c['id'],
    'if'=>"${{ !cancelled() && steps.bootstrap.outcome == 'success' }}",
    'env'=>{'GAMBIT_SMP_CASE'=>c['id'],'GAMBIT_SMP_OUT'=>'.smp-ci/'+c['id']},'run'=>native} }
  workflow['jobs']['smp']['steps']=preserved.dup.insert(first,*generated)
  raise 'non-case steps changed' unless workflow['jobs']['smp']['steps'].reject { |s| is_case.call(s) }==preserved
  File.write(m.fetch('workflow'),YAML.dump(workflow))
  puts JSON.generate(workflow:m['workflow'],modules:modules.size,onlyNativeCasesChanged:true,remoteExecuted:false)
  exit
end
if catalog_only
  puts JSON.generate(catalog:'vendor/gambit/tests/smp/catalog.scm',modules:modules.size,workflowChanged:false)
  exit
end
hash_variable=m.fetch('hashToolVariable')
raise 'typed hash-tool variable required' unless hash_variable.match?(/\A[A-Z][A-Z0-9_]*\z/) && File.read('vendor/gambit/tests/smp/suite.scm').include?('environment-tool "'+hash_variable+'"')
tool_environment=m.fetch('tools').map do |tool|
  variable=tool.fetch('variable'); command=tool.fetch('command')
  raise 'invalid environment tool' unless variable.match?(/\AGAMBIT_SMP_[A-Z_]+\z/) && command.match?(/\A[a-z][a-z0-9-]*\z/)
  "program=\"${#{variable}:-$(type -P #{command})}\"\ntest -f \"$program\" && test -x \"$program\"\nprintf '#{variable}=%s\\n' \"$program\" >> \"$GITHUB_ENV\"\n"
end.join
seed=<<SEED
mkdir -p .smp-ci/seed
export CC="$(greadlink -f "$GAMBIT_SMP_CC")"
export PATH="$(dirname "$CC"):$PATH"
unset SDKROOT LIBRARY_PATH CPATH GAMBOPT
export CFLAGS=-pipe
workers=$("$GAMBIT_SMP_SYSCTL" -n hw.logicalcpu)
workers=$((workers > 1 ? workers - 1 : 1))
"$GAMBIT_SMP_TIMEOUT" 150s ./configure #{configure.join(' ')} > .smp-ci/seed/configure.output 2>&1
"$GAMBIT_SMP_TIMEOUT" 10s "$GAMBIT_SMP_MAKE" dummy-gsc-boot > .smp-ci/seed/seed-compiler.output 2>&1
"$GAMBIT_SMP_TIMEOUT" --kill-after=2s 600s "$GAMBIT_SMP_MAKE" -j"$workers" GAMBOPT="p$workers" core > .smp-ci/seed/build.output 2>&1
SEED
native='gsi/gsi -:p1,~~lib=lib,~~bin=bin,~~include=include tests/smp/suite.scm'
steps=[{'uses'=>'actions/checkout@v4','with'=>{'fetch-depth'=>0}},
 {'name'=>'Install the declared native tools','run'=>"brew install gcc autoconf automake texinfo coreutils\n"+tool_environment},
 {'id'=>'seed','name'=>'Build the initial Gambit interpreter using existing Make targets','run'=>seed},
 {'id'=>'bootstrap','name'=>'Gambit owns complete two-pass bootstrap validation','env'=>{'GAMBIT_SMP_CASE'=>'gambit.smp.bootstrap.two-pass','GAMBIT_SMP_OUT'=>'.smp-ci/bootstrap'},'run'=>native}]
modules.each do |c|
 steps<<{'id'=>c['id'].tr('.-','__'),'name'=>'SMP: '+c['id'],'if'=>"${{ !cancelled() && steps.bootstrap.outcome == 'success' }}",'env'=>{'GAMBIT_SMP_CASE'=>c['id'],'GAMBIT_SMP_OUT'=>'.smp-ci/'+c['id']},'run'=>native}
end
steps<<{'uses'=>'actions/upload-artifact@v4','if'=>'${{ always() }}','with'=>{'name'=>'gambit-smp-${{ runner.os }}-${{ runner.arch }}-${{ github.run_attempt }}','path'=>".smp-ci/**/*.json\n.smp-ci/**/*.output\n",'include-hidden-files'=>true,'if-no-files-found'=>'warn'}}
workflow={'name'=>'Gambit Modern C SMP','on'=>{'pull_request'=>{'paths'=>['include/**','lib/**','gsc/**','gsi/**','tests/**','configure*','makefile.in','.github/workflows/smp.yml']},'push'=>{'branches'=>['modern-c']},'workflow_dispatch'=>{}},'permissions'=>{'contents'=>'read'},'env'=>{'HOMEBREW_NO_AUTO_UPDATE'=>'1'},'jobs'=>{'smp'=>{'runs-on'=>m['runner'],'timeout-minutes'=>30,'steps'=>steps}}}
File.write(m['workflow'],YAML.dump(JSON.parse(JSON.generate(workflow))))
puts JSON.generate(workflow:m['workflow'],modules:modules.size,orchestrator:'native Gambit Scheme',parentRepositoryRequired:false,remoteExecuted:false)
