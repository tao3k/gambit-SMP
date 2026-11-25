"""Qualification of planning-only closed-generation consumption."""

from pathlib import Path


def check_generation_planning(ctx, source, store):
    """Native reader/coordinator checks over actual issued closed generations.

    Callback seams reject import, freshness bypass and completion publication.
    These are planning properties, not complete native-program acceptance.
    """
    import json
    from gambit_smp.framework import digest
    from gambit_smp.workspace import write
    source, store = Path(source), Path(store)
    fixture = ctx.root/'tests/fixtures/generation-planning.ss'
    make = source/'src/std/make.ss'
    from gambit_smp.gerbil_build.make_source import _generation_make_source
    _generation_make_source(make.read_text(), inverse=True)
    markers = []
    for path in (store/'generations').glob('*.json'):
        record = json.loads(path.read_text())
        if (source/'build/lib'/(record['moduleId']+'.ssi')).exists():
            continue
        relative = Path(record['source']).relative_to(source)
        marker = store/'modules'/(str(relative)+'.ready.generation')
        if marker.exists():
            markers.append(marker)
    if not markers:
        raise ValueError('actual issued unfinished generations required')
    ctx.bind([make, fixture, *markers])
    copy = ctx.directory/'generation-query-probe.ready'
    expression = ('(import '+json.dumps(str(fixture))+') (verify-generation-planning '
                  +json.dumps(str(make))+' (list '
                  +' '.join(json.dumps(str(p)) for p in markers)+') '
                  +json.dumps(str(copy))+')')
    output = ctx.require('generation-planning-native-properties',
        [str(source/'run.sh'), 'gxi', '-:p1', '-e', expression],
        source/'src/std', min(30, ctx.remaining()))
    count = len(markers)*64
    if f'GENERATION-PLANNING-PASS sources={len(markers)} cases={count} ' not in output:
        raise ValueError('generation planning native property receipt missing')
    ctx.bind([make, fixture, *markers])
    record = dict(complete=True, sources=len(markers), cases=count,
        makeSha256=digest(make), fixtureSha256=digest(fixture),
        issuedMarkers={str(p):digest(p)for p in markers}, output=output,
        moduleComplete=False, publicInterfaceGranted=False, runtimeAdmitted=False,
        scope='Actual installed reader/coordinator definitions and issued generation payloads; dependency rotation and malformed credentials. Callback seams forbid import and completion. Full Make/native draining remains independent.')
    write(ctx.directory/'generation-planning-properties.json', record)
    return record


