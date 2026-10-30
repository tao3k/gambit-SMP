from pathlib import Path
import importlib.util
SPEC={'module': 'restore_entry_issuers', 'namespace': 'RestoreIssuerAst', 'fields': {'intent': 'int', 'source': 'int', 'sourceRoot': 'int', 'pin': 'int', 'carrier': 'int', 'version': 'int', 'copiedVersion': 'int', 'guard': 'int', 'issued': 'int', 'marker': 'int', 'handoff': 'int', 'escrow': 'int', 'outer': 'int', 'reuses': 'int', 'allocations': 'int', 'rejected': 'int'}, 'actions': ['classifyFresh', 'classifyNavigation', 'classifyScheduler', 'classifyForeign', 'classifyConversion', 'sourceFrame', 'sourceRc', 'sourceRaw', 'pinSource', 'publishCarrier', 'gcSourceOnly', 'gcPublished', 'reserveGuard', 'guardAllocationFails', 'publishGuard', 'releaseSource', 'allocateMarker', 'enter', 'exceptionToOwner', 'observeOuter', 'killMarker', 'complete', 'reuseExisting', 'rejectRaw', 'recoverPreAdmission']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py');s=importlib.util.spec_from_file_location('scalar_projection',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
