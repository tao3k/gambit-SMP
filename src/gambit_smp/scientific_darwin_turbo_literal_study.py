"""Isolated modern-c literal specialization: component evidence, never merge authority."""
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_text as _study_write_text
import hashlib, json, re, statistics, time
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_workspace = _study_workspace
        _science._study_write_text = _study_write_text
        _science.hashlib = hashlib
        _science.json = json
        _science.re = re
        _science.statistics = statistics
        _science.time = time
        _science.Path = Path
        _science.ROOT = _science.context.root
        _science.SOURCE = _science.ROOT / 'vendor/gambit'
        _science.CANDIDATE = Path('/private/tmp/gambit-darwin-turbo')
        _science.CC = Path('/opt/homebrew/bin/gcc-16')
        _science.process_profile = {'cap': 60, 'stream': 'stdout-seconds', 'failure': 'assertion', 'failParameter': False, 'expectedParameter': False}

    def sha(_science, p):
        return hashlib.sha256(Path(p).read_bytes()).hexdigest()

    def save(_science, name, x):
        _study_write_text(_study_workspace('OUT') / name, json.dumps(x, indent=2) + '\n')

    def analyze(_science):
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        baseline = json.loads((_study_workspace('OUT') / 'source-baseline.json').read_text())
        assert baseline['baseHead'] == _science.context.output(['git', '-C', str(_science.SOURCE), 'rev-parse', 'HEAD'], text=True, name='source-29').strip()
        sourceFile = _science.SOURCE / 'include/_gambit/module_generation.h.in'
        candidateFile = _science.CANDIDATE / 'include/_gambit/module_generation.h.in'
        bound = {str(sourceFile): _science.sha(sourceFile), str(candidateFile): _science.sha(candidateFile), str(_science.CC): _science.sha(_science.CC), str(_science.SOURCE / 'include/gambit.h'): _science.sha(_science.SOURCE / 'include/gambit.h')}
        sdk, _ = _science.context.command('sdk-path', ['/usr/bin/xcrun', '--show-sdk-path'], policy=_science.process_profile)
        sdk = sdk.decode().strip()
        version, _ = _science.context.command('compiler-version', [_science.CC, '--version'], policy=_science.process_profile)
        _science.save('toolchain.json', dict(compiler=str(_science.CC), sha256=_science.sha(_science.CC), version=version.decode(), sdk=sdk, linkerDriver='/usr/bin/clang', gccDriverLinkQualified=False, sourceBindings=bound))
        common = (_study_workspace('OUT') / 'literal-baseline.h').read_text()
        candidate = (_study_workspace('OUT') / 'literal-candidate.h').read_text()
        assert common in sourceFile.read_text() and candidate in candidateFile.read_text()
        module = sourceFile.read_text()
        packing = module[module.index('#if ___WORD_WIDTH == 32', module.index('#define ___DEF_SUB_F64VEC')):module.index('#define ___STR0 ')]
        matrix = _study_workspace('OUT') / 'matrix.c'
        selected = _study_workspace('OUT') / 'literal-selected.h'
        cases = []
        for width in [32, 64]:
            for big in [False, True]:
                for cs in [1, 2, 4]:
                    for pad in [False, True]:
                        prefix = '#define ___WORD_WIDTH ' + str(width) + '\n#define ___CS ' + str(cs) + '\n'
                        if big:
                            prefix += '#define ___BIG_ENDIAN\n'
                        prefix += '#define ___CS_SELECT(a,b,c) ' + {1: 'a', 2: 'b', 4: 'c'}[cs] + '\n'
                        prefix += '#define ___CAST(t,x) ((t)(x))\n#define ___CAST_U8(x) ((U8)(x))\n#define ___CAST_U16(x) ((U16)(x))\n#define ___CAST_U32(x) ((U32)(x))\n#define ___WORD W\n#define ___UWORD UW\n#define ___PADDING ' + (',0' if pad else '') + '\n#define ___PADDING_64 ' + (',0,0' if pad else '') + '\n'
                        body = ''
                        for n in range(9):
                            body += 'W tail' + str(n) + '[]={0\n___STR8(0,1,127,128,255,256,65535,1114111)\n___STR' + str(n) + ('(' + ','.join((str(i * 17) for i in range(n))) + ')' if n else '') + '\n'
                        _study_write_text(matrix, prefix + packing + '\n#include "literal-selected.h"\n' + body)
                        observed = []
                        for arm, text in [('A', common), ('B', candidate)]:
                            _study_write_text(selected, text)
                            raw, _ = _science.context.command(f'matrix-{width}-{int(big)}-{cs}-{int(pad)}-{arm}', [_science.CC, '-std=c23', '-E', '-P', matrix], policy=_science.process_profile)
                            observed.append(re.sub(b'\\s+', b'', raw))
                        assert observed[0] == observed[1], (width, big, cs, pad)
                        cases.append(dict(wordWidth=width, bigEndian=big, characterBytes=cs, padding=pad, tails=9, tokenBytes=len(observed[0])))
        _science.save('cpp-equivalence.json', dict(cases=cases, tailCases=24 * 9, sourceDerivedPacking=True, fullHeaderAbiQualification=False))
        unit = _study_workspace('OUT') / 'literal-unit.c'
        obj = _study_workspace('OUT') / 'literal-unit.o'
        exe = _study_workspace('OUT') / 'literal-unit'
        undef = ''.join(('#undef ___STR' + str(i) + '\n' for i in range(9)))
        _study_write_text(unit, '#include ' + json.dumps(str(_science.SOURCE / 'include/gambit.h')) + '\n#include <stdio.h>\n' + undef + '#include "literal-selected.h"\n___WORD payload[]={0\n' + '___STR8(0,1,127,128,255,256,65535,1114111)\n' * 16384 + '___STR0\nint main(void){return fwrite(payload,1,sizeof(payload),stdout)==sizeof(payload)?0:1;}\n')
        flags = ['-isysroot', sdk, '-std=c23', '-O1', '-pipe', '-ftrack-macro-expansion=0']
        semantic = []
        for arm, text in [('A', common), ('B', candidate)]:
            _study_write_text(selected, text)
            _science.context.command('semantic-build-' + arm, [_science.CC, *flags, '-c', unit, '-o', obj], policy=_science.process_profile)
            _science.context.command('semantic-link-' + arm, ['/usr/bin/clang', '-isysroot', sdk, obj, '-o', exe], policy=_science.process_profile)
            raw, _ = _science.context.command('semantic-run-' + arm, [exe], policy=_science.process_profile)
            semantic.append(hashlib.sha256(raw).hexdigest())
        assert semantic[0] == semantic[1]
        waves = []
        for arm in 'ABBAABBAABBA':
            start = time.perf_counter()
            _study_write_text(selected, common if arm == 'A' else candidate)
            _, elapsed = _science.context.command('object-' + str(len(waves)) + arm, [_science.CC, *flags, '-c', unit, '-o', obj], policy=_science.process_profile)
            waves.append(dict(arm=arm, compilerSeconds=elapsed, completeRequestSeconds=time.perf_counter() - start, objectSha256=_science.sha(obj)))
        _science.save('object-waves.json', waves)
        assert len({w['objectSha256'] for w in waves}) == 1, 'Object bytes differ'
        assert all((_science.sha(Path(f)) == v for f, v in bound.items())), 'Source/compiler/header drift'
        means = {a: statistics.median((w['completeRequestSeconds'] for w in waves if w['arm'] == a)) for a in ['A', 'B']}
        receipt = dict(sourceBindings=bound, cppContexts=len(cases), cppTailCases=len(cases) * 9, semanticPayloadSha256=semantic[0], objectBytesIdentical=True, medianRequestSeconds=means, componentSpeedup=means['A'] / means['B'], wholePackageSpeedupEstablished=False, fullGeneratedHeaderQualification=False, mergeAllowed=False, sourceRuntimeImplementation='isolated literal-header prototype only', originalModernCChanged=False, timeoutSeconds=60)
        _science.save('literal-final.json', receipt)
        print(json.dumps(receipt, indent=2))

# Preserved scientific source notes (in original order).
# Direct modern-c packing definitions; neutral scalar aliases only support CPP equivalence.
# Same TU path/argv/cwd/environment and output path in both arms. No arm env vars.
