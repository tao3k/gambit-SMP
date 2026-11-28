"""Restricted typed IR projection; never claims native-source or SysML parser correctness."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'module_spec_handle', 'namespace': 'ModuleHandleAst', 'fields': {'phase': 'int', 'ticket': 'int', 'stage': 'int', 'aliases': 'int', 'loans': 'int', 'entry': 'int', 'reply': 'int', 'leaf': 'bool', 'edges': 'bool', 'hasOpaque': 'bool', 'qualified': 'bool', 'sealed': 'bool', 'handle': 'bool', 'raw': 'bool', 'effects': 'bool', 'unknown': 'bool', 'privateRoot': 'bool', 'publishedRoot': 'bool', 'payloadRetired': 'bool', 'receipt': 'bool'}, 'actions': ['recordLeaf', 'recordEdges', 'declareOpaque', 'qualifyNative', 'sealSpec', 'reserve', 'protectCandidate', 'startEffects', 'commit', 'acknowledge', 'retryReply', 'dropCandidate', 'abortBeforeEffects', 'unknownReserved', 'unknownCommitted', 'exposeRaw', 'borrowNative', 'returnBorrow', 'beginNativeInit', 'returnNativeInit', 'beginSchemeInit', 'returnSchemeInit', 'failInit', 'removeAlias', 'publishAlias', 'close', 'retirePayload', 'issue', 'permit', 'rejectLate']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_module_spec_handle_migration_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
