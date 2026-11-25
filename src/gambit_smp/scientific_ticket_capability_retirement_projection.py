from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'ticket_capability_retirement', 'namespace': 'TicketCapabilityAst', 'fields': {'t0phase': 'int', 't0exit': 'int', 't0outcome': 'int', 't0enters': 'int', 't0settles': 'int', 't0ack': 'bool', 't0unknown': 'bool', 't1phase': 'int', 't1exit': 'int', 't1outcome': 'int', 't1enters': 'int', 't1settles': 'int', 't1ack': 'bool', 't1unknown': 'bool', 'cap': 'int', 'messageGeneration': 'int', 'rejected': 'int', 'duplicateReplies': 'int', 'h0open': 'bool', 'h1issued': 'bool', 'h1open': 'bool', 'b0issued': 'bool', 'b0open': 'bool', 'b1issued': 'bool', 'b1open': 'bool', 's0issued': 'bool', 's0open': 'bool', 's1issued': 'bool', 's1open': 'bool', 'rawEscape': 'bool', 'aliasCensus': 'bool', 'maps': 'bool', 'maintenanceClosed': 'bool', 'rootRetired': 'bool'}, 'actions': ['reserve0', 'enter0', 'observeSuccess0', 'observeFailure0', 'commit0', 'query0', 'queryPending0', 'conflictingSettle0', 'loseReply0', 'retainTombstone0', 'reserve1', 'enter1', 'observeSuccess1', 'observeFailure1', 'commit1', 'query1', 'queryPending1', 'conflictingSettle1', 'loseReply1', 'retainTombstone1', 'cloneHandle1', 'dropHandle0', 'dropHandle1', 'duplicateDrop0', 'borrowNative0', 'returnNative0', 'borrowNative1', 'returnNative1', 'duplicateNativeReturn0', 'closeCapability', 'discoverRawEscape', 'attestAliasCensus', 'attestRootMaps', 'closeAuthority', 'pinScanner0', 'unpinScanner0', 'pinScanner1', 'unpinScanner1', 'closeMaintenance', 'retireRoot', 'selectStaleGeneration', 'selectCurrentGeneration', 'rejectStaleRequest']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_ticket_capability_retirement_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
