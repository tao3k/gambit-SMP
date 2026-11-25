from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'restore_entry_issuers', 'namespace': 'RestoreIssuerAst', 'fields': {'intent': 'int', 'source': 'int', 'sourceRoot': 'int', 'pin': 'int', 'carrier': 'int', 'version': 'int', 'copiedVersion': 'int', 'guard': 'int', 'issued': 'int', 'marker': 'int', 'handoff': 'int', 'escrow': 'int', 'outer': 'int', 'reuses': 'int', 'allocations': 'int', 'rejected': 'int'}, 'actions': ['classifyFresh', 'classifyNavigation', 'classifyScheduler', 'classifyForeign', 'classifyConversion', 'sourceFrame', 'sourceRc', 'sourceRaw', 'pinSource', 'publishCarrier', 'gcSourceOnly', 'gcPublished', 'reserveGuard', 'guardAllocationFails', 'publishGuard', 'releaseSource', 'allocateMarker', 'enter', 'exceptionToOwner', 'observeOuter', 'killMarker', 'complete', 'reuseExisting', 'rejectRaw', 'recoverPreAdmission']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_restore_entry_issuers_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
