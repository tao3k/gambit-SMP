#!/usr/bin/env python3
"""Repository-local, bounded SMP CI. Requires only Python and the C toolchain.

Research models and formal evidence belong to the separate SMP repository.
Each result binds actual input bytes, argv, output, exit and process teardown.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def execute(argv, cwd, env, budget, directory, name, records):
    out, err = directory / (name + '.stdout'), directory / (name + '.stderr')
    started = time.monotonic()
    with out.open('wb') as stdout, err.open('wb') as stderr:
        proc = subprocess.Popen(list(map(str, argv)), cwd=cwd, env=env,
                                stdout=stdout, stderr=stderr, start_new_session=True)
        timed_out = False
        try:
            proc.wait(timeout=budget)
        except subprocess.TimeoutExpired:
            timed_out = True
            os.killpg(proc.pid, signal.SIGKILL)
            proc.wait()
    try:
        os.killpg(proc.pid, 0)
        quiescent = False
        os.killpg(proc.pid, signal.SIGKILL)
    except ProcessLookupError:
        quiescent = True
    records.append(dict(argv=list(map(str, argv)), cwd=str(cwd), budget=budget,
                        seconds=time.monotonic()-started, exit=proc.returncode,
                        timeout=timed_out, parentReaped=True,
                        processGroupQuiescent=quiescent,
                        stdout=out.name, stdoutSha256=sha(out),
                        stderr=err.name, stderrSha256=sha(err)))
    if timed_out or proc.returncode or not quiescent:
        raise RuntimeError('failed or non-quiescent command: ' + name)
    return out.read_text()


def run(args):
    plan = json.loads((ROOT/'tests/smp/plan.json').read_text())
    runtime = args.runtime.resolve(strict=True)
    directory = args.out.resolve()
    directory.mkdir(parents=True, exist_ok=False)
    compiler = Path(shutil.which(args.cc) or args.cc).resolve(strict=True)
    records = []
    receipt = dict(module=args.module, outcome='FAIL', commands=records,
                   runtime=str(runtime), compiler=str(compiler),
                   compilerSha256=sha(compiler), remoteCI=bool(os.getenv('GITHUB_ACTIONS')),
                   runnerSha256=sha(__file__), planSha256=sha(ROOT/'tests/smp/plan.json'),
                   wholeSmpAdmitted=False, commitAdmitted=False)
    started = time.monotonic()
    # Ignore ambient Scheme paths and processor/heap options; no heap increase.
    env = dict(os.environ)
    for key in ('GAMBOPT', 'GERBIL_HOME', 'GERBIL_LOADPATH', 'GERBIL_GSC',
                'SDKROOT', 'LIBRARY_PATH', 'CPATH'):
        env.pop(key, None)
    workers = max(1, (os.cpu_count() or 1)-1)
    paths = ',~~lib='+str(runtime/'lib')+',~~bin='+str(runtime/'bin')+',~~include='+str(runtime/'include')
    env.update(CC=str(compiler), CFLAGS='-pipe', GAMBOPT='p'+str(workers)+paths)
    receipt['compilerProcessors'] = workers
    try:
        def command(name, argv, budget, cwd=runtime):
            return execute(argv, cwd, env, budget, directory, name, records)

        if args.module == 'bootstrap':
            if runtime != ROOT:
                raise ValueError('bootstrap must build this checkout')
            configure = plan['configure']
            command('configure', ['/bin/sh', './configure', *configure], 150)
            # Upstream pre-generated C provides the seed. Then discard generated
            # C and require both real Scheme regeneration/bootstrap passes.
            command('seed', ['make', '-j'+str(workers), 'GAMBOPT=p'+str(workers), 'core'], 600)
            shutil.copy2(runtime/'gsc/gsc', runtime/'gsc-boot')
            generated = sorted(p for d in ('lib','gsi','gsc') for p in (runtime/d).glob('_*.c'))
            before = {str(p.relative_to(runtime)): sha(p)
                      for d in ('lib','gsi','gsc') for p in (runtime/d).glob('*.scm')}
            command('bootclean', ['make','bootclean'], 10)
            if not generated or any(p.exists() for p in generated):
                raise RuntimeError('generated C was not removed')
            log = command('bootstrap', ['make','-j'+str(workers),
                                       'GAMBOPT=p'+str(workers),'from-scratch'], 600)
            counts = {p: len(re.findall(r'^\*\*\* making '+p+r'$',log,re.M))
                      for p in ('phase1','phase2','phase3','phase4')}
            receipt['phaseCounts'] = counts
            if any(n != 2 for n in counts.values()) or any(not p.is_file() for p in generated):
                raise RuntimeError('complete two-pass generation not established')
            if any(sha(runtime/p) != h for p,h in before.items()):
                raise RuntimeError('Scheme source changed during bootstrap')
            receipt['fullTwoPassBootstrapEstablished'] = True
        else:
            case = next(c for c in plan['modules'] if c['id'] == args.module)
            program = ROOT/case['program']
            receipt.update(program=case['program'], programSha256=sha(program))
            # Configured header template and allocator bodies must match this
            # checkout even when a local researcher reuses an existing producer.
            sources = ['include/gambit.h.in','lib/mem.c',
                       *sorted(str(p.relative_to(ROOT)) for p in (ROOT/'lib/memory').glob('*.inc'))]
            receipt['runtimeSource'] = {p: sha(ROOT/p) for p in sources}
            if any(sha(runtime/p) != h for p,h in receipt['runtimeSource'].items()):
                raise ValueError('runtime source differs from test checkout')
            deadline = time.monotonic()+case['budget']
            def bounded(name, argv, cap, cwd=runtime):
                left = deadline-time.monotonic()
                if left <= 0:
                    raise TimeoutError('module deadline exhausted')
                return command(name, argv, min(cap,left), cwd)
            if case['kind'] == 'kernel':
                executable = directory/'kernel'
                bounded('compile', [compiler,'-std=c23','-O1','-pthread',
                        '-DHAVE_CONFIG_H','-I',runtime/'include',program,'-o',executable],30)
                output = bounded('run',[executable],10)
                if (directory/'run.stderr').stat().st_size:
                    raise RuntimeError('unexpected kernel diagnostics')
                if case['id'] == 'runtime-storage':
                    if not re.fullmatch(r'RUNTIME-ROLES-STORAGE-PASS word=(32|64) context=[1-9][0-9]* worker=[1-9][0-9]* participant=[1-9][0-9]* carrier=[1-9][0-9]* vm=[1-9][0-9]*\n',output):
                        raise RuntimeError('invalid runtime layout result')
                elif output != case['stdout']:
                    raise RuntimeError('kernel result mismatch')
            elif case['kind'] == 'make':
                baseline = bounded('unchanged',['make','-q','mem.o'],10,runtime/'lib')
                fragments = sorted((runtime/'lib/memory').glob('*.inc'))
                if len(fragments) != 25:
                    raise RuntimeError('memory inventory is incomplete')
                for i,p in enumerate(fragments):
                    log = bounded('fragment-'+str(i),['make','-n','-W',str(p.relative_to(runtime/'lib')),'mem.o'],10,runtime/'lib')
                    if not re.search(r'\s-c\s.*mem\.c', log):
                        raise RuntimeError('fragment does not invalidate mem.o: '+str(p))
                output = 'MEMORY-DEPENDENCIES-PASS fragments=25\n'
            else:
                fixture = directory/'fixture.scm'
                shutil.copy2(program,fixture)
                executable = directory/'fixture'
                bounded('compile',[runtime/'gsc/gsc','-exe','-o',executable,
                        '-cc-options','-pthread','-ld-options','-pthread',fixture],90,directory)
                population = workers if case['topology']=='host-managed' else 1
                env.update(GAMBOPT='p'+str(population)+paths,
                           GAMBIT_SMP_EXPECTED_PROCESSORS=str(population))
                receipt['executionProcessors'] = population
                output = bounded('run',[executable],30,directory)
                if (directory/'run.stderr').stat().st_size:
                    raise RuntimeError('unexpected Scheme or cleanup diagnostics')
                if output != case['stdout']:
                    raise RuntimeError('Scheme result mismatch')
            if sha(program) != receipt['programSha256']:
                raise RuntimeError('test input changed')
            if any(sha(runtime/p) != h for p,h in receipt['runtimeSource'].items()):
                raise RuntimeError('runtime changed during test')
            print(output, end='')
        receipt['outcome'] = 'PASS'
    except Exception as error:
        receipt['error'] = str(error)
    finally:
        receipt['seconds'] = time.monotonic()-started
        (directory/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
    return receipt['outcome'] == 'PASS'


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('module')
    parser.add_argument('--runtime',type=Path,default=ROOT)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--cc',default='gcc-16')
    raise SystemExit(0 if run(parser.parse_args()) else 1)
