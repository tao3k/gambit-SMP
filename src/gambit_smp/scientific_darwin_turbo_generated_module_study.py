"""Real generated-C component control; not a whole-runtime or package admission."""
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_text as _study_write_text
import hashlib
import json
import statistics

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_write_text = _study_write_text
        _science.hashlib = hashlib
        _science.json = json
        _science.statistics = statistics
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def analyze(_science):
        h = _science.context.library('darwin_turbo_literal_study')
        baseline = (_study_workspace('OUT') / 'literal-baseline.h').read_text()
        candidate = (_study_workspace('OUT') / 'literal-candidate.h').read_text()
        original = (h.SOURCE / 'include/gambit.h').read_text()
        assert original.count(baseline) == 1
        selected = _study_workspace('OUT') / 'generated-include'
        selected.mkdir(exist_ok=True)
        header = selected / 'gambit.h'
        sdk, _ = _science.context.command('real-sdk', ['/usr/bin/xcrun', '--show-sdk-path'], policy=h.process_profile)
        flags = ['-isysroot', sdk.decode().strip(), '-std=c23', '-O1', '-pipe', '-ftrack-macro-expansion=0', '-I', selected, '-I', h.SOURCE / 'include']
        results = []
        for name in ['gsc/_gsc.c', 'lib/_kernel.c']:
            source = h.SOURCE / name
            source_digest = h.sha(source)
            tag = source.stem
            waves = []
            tokens = []
            for arm in 'ABBA':
                _study_write_text(header, original if arm == 'A' else original.replace(baseline, candidate))
                raw, elapsed = _science.context.command('real-' + tag + '-cpp-' + str(len(waves)), [h.CC, *flags, '-E', '-P', source], policy=h.process_profile)
                tokens.append(hashlib.sha256(raw).hexdigest())
                obj = _study_workspace('OUT') / (tag + '-real.o')
                _, compile_seconds = _science.context.command('real-' + tag + '-object-' + str(len(waves)), [h.CC, *flags, '-c', source, '-o', obj], policy=h.process_profile)
                waves.append(dict(arm=arm, preprocessSeconds=elapsed, objectSeconds=compile_seconds, objectSha256=h.sha(obj)))
            assert len(set(tokens)) == 1, 'Real preprocessed bytes differ'
            assert len({w['objectSha256'] for w in waves}) == 1, 'Real objects differ'
            assert h.sha(source) == source_digest, 'Source drift'
            medians = {a: statistics.median((w['objectSeconds'] for w in waves if w['arm'] == a)) for a in 'AB'}
            results.append(dict(source=str(source), sourceSha256=source_digest, str8Invocations=source.read_text().count('___STR8('), waves=waves, medians=medians, componentSpeedup=medians['A'] / medians['B'], preprocessedBytesIdentical=True, objectBytesIdentical=True))
            h.save('generated-module-partial.json', results)
        receipt = dict(results=results, fullRuntimeQualification=False, wholePackageSpeedupEstablished=False, mergeAllowed=False, scope='Current generated artifact bytes; generator/profile provenance is not certified', compilerSha256=h.sha(h.CC), originalHeaderSha256=h.sha(h.SOURCE / 'include/gambit.h'), timeoutSeconds=60)
        h.save('generated-module-final.json', receipt)
        print(json.dumps(receipt, indent=2))
