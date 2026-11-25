from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'formatter_restore_reentry', 'namespace': 'FormatterRestoreAst', 'fields': {'phase': 'int', 'writer': 'int', 'generation': 'int', 'savedWriter': 'int', 'installGen': 'int', 'epoch': 'int', 'scopeEpoch': 'int', 'tickets': 'int', 'borrowers': 'int', 'captures': 'int', 'attempts': 'int', 'demand': 'int', 'certGen': 'int', 'certEpoch': 'int', 'legacyPc': 'int', 'legacyWriter': 'int', 'legacySaved': 'int', 'legacyCaptureSaved': 'int', 'legacyGen': 'int', 'legacyResumes': 'int', 'legacyTarget': 'int', 'active': 'bool', 'frameClosed': 'bool', 'registrationClosed': 'bool', 'custody': 'bool', 'errorSeen': 'bool', 'qualified': 'bool', 'certificate': 'bool', 'retired': 'bool', 'legacyCaptured': 'bool', 'legacyNewer': 'bool', 'legacyClobbered': 'bool'}, 'actions': ['beginScope', 'bodyReturns', 'restoreOwned', 'escapeOwned', 'publishOther', 'publishSameIdentity', 'yieldConflict', 'changeEpoch', 'acceptTicket', 'startTicket', 'finishBorrower', 'capture', 'rejectStalePermit', 'detachCapture', 'closeRegistration', 'namedDemand', 'namedSupply', 'rawMetadata', 'ioFailure', 'qualifyProfile', 'issue', 'consumeSecond', 'legacyEnter', 'legacyCapture', 'legacyEscape', 'legacyPublish', 'legacyResolve', 'legacyReturn', 'legacyRestore', 'legacyResume', 'legacyLateEntry']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_formatter_restore_reentry_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
