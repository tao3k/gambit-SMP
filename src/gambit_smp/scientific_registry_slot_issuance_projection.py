from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'registry_slot_issuance', 'namespace': 'SlotIssuanceAst', 'fields': {'storage': 'int', 'generation': 'int', 'request': 'int', 'lo': 'int', 'hi': 'int', 'key': 'int', 'keyGeneration': 'int', 'savedGeneration': 'int', 'fresh': 'int', 'freshLo': 'int', 'freshHi': 'int', 'reg': 'int', 'mode': 'int', 'lease': 'int', 'boundGeneration': 'int', 'boundPayload': 'int', 'payload': 'int', 'copy': 'int', 'known': 'int', 'borrow': 'int', 'lookup': 'int', 'scan': 'int', 'gc': 'int', 'sourceBorrow': 'int', 'backing': 'int', 'rejected': 'int', 'queries': 'int'}, 'actions': ['probeSubview', 'probeAdjacent', 'probeOverlap', 'probeUnownedExact', 'issueSubview', 'issueFresh', 'rejectOverlap', 'rejectUnownedExact', 'saveKey', 'prepareAlias', 'prepareCopy', 'materializeCopy', 'publishAlias', 'publishCopy', 'queryCommit', 'releaseCopyLease', 'beginLookup', 'acceptBorrow', 'lookupUnknown', 'resolveLookup', 'rejectLookup', 'returnBorrow', 'closeRegistry', 'beginScan', 'finishScan', 'scanUnknown', 'resolveScan', 'retireRegistry', 'releaseRetiredAliasLease', 'abortCandidate', 'sourceWrite', 'sourceBorrowBegin', 'sourceBorrowReturn', 'closeStorage', 'settleBacking', 'reclaimStorage', 'reuseStorage', 'rejectStaleKey']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_registry_slot_issuance_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
