"""Joint-entry NativeScope typed-IR projection; no native refinement claim."""
import importlib.util
from pathlib import Path
SPEC = {'module': 'native_entry_admission', 'namespace': 'NativeEntryAst', 'fields': {'phase': 'int', 'host': 'int', 'sourcePin': 'int', 'sourceRoot': 'int', 'carrierRoot': 'int', 'registry': 'int', 'guard': 'int', 'inflight': 'int', 'nested': 'int', 'unknown': 'int', 'outcome': 'int', 'epoch': 'int', 'sourceEpoch': 'int', 'carrierEpoch': 'int', 'frozen': 'int', 'scanned': 'int', 'entryOpen': 'int', 'writeOpen': 'int', 'written': 'int', 'marker': 'int', 'receipt': 'int', 'registrationUnknown': 'int', 'scanAdmission': 'int', 'grace': 'int', 'rejected': 'int', 'holder': 'int'}, 'actions': ['pinSource', 'reserveCarrier', 'qualifyHost', 'publishCarrier', 'loseRegistrationAck', 'confirmSameRegistration', 'jointIssue', 'writeEntryState', 'allocateMarker', 'certifyTransfer', 'releaseSource', 'closeIngress', 'exhaustCarrier', 'rejectClosed', 'freezeWriters', 'scanSource', 'scanBoth', 'scanCarrier', 'thawWriters', 'enterNested', 'leaveNested', 'recordOutcome', 'loseCompletion', 'landNested', 'settleKnown', 'recoverRecorded', 'closeScanAdmission', 'confirmGrace', 'retireCarrier']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
 r.pop('c11Refinement',None);r['c23Refinement']=False
 return a,r
