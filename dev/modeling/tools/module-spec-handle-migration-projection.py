"""Restricted typed IR projection; never claims native-source or SysML parser correctness."""
from pathlib import Path
import importlib.util
SPEC={'module': 'module_spec_handle', 'namespace': 'ModuleHandleAst', 'fields': {'phase': 'int', 'ticket': 'int', 'stage': 'int', 'aliases': 'int', 'loans': 'int', 'entry': 'int', 'reply': 'int', 'leaf': 'bool', 'edges': 'bool', 'hasOpaque': 'bool', 'qualified': 'bool', 'sealed': 'bool', 'handle': 'bool', 'raw': 'bool', 'effects': 'bool', 'unknown': 'bool', 'privateRoot': 'bool', 'publishedRoot': 'bool', 'payloadRetired': 'bool', 'receipt': 'bool'}, 'actions': ['recordLeaf', 'recordEdges', 'declareOpaque', 'qualifyNative', 'sealSpec', 'reserve', 'protectCandidate', 'startEffects', 'commit', 'acknowledge', 'retryReply', 'dropCandidate', 'abortBeforeEffects', 'unknownReserved', 'unknownCommitted', 'exposeRaw', 'borrowNative', 'returnBorrow', 'beginNativeInit', 'returnNativeInit', 'beginSchemeInit', 'returnSchemeInit', 'failInit', 'removeAlias', 'publishAlias', 'close', 'retirePayload', 'issue', 'permit', 'rejectLate']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('scalar_projection',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
