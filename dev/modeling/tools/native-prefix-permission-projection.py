"""Prefix-permission NativeScope typed-IR projection; no native refinement claim."""
import importlib.util
from pathlib import Path
SPEC = {'module': 'native_prefix_permission', 'namespace': 'NativePrefixAst', 'fields': {'phase': 'int', 'profile': 'int', 'identity': 'int', 'bindingEpoch': 'int', 'sealEpoch': 'int', 'fast': 'int', 'durable': 'int', 'sourceRoot': 'int', 'carrierRoot': 'int', 'intent': 'int', 'allocation': 'int', 'recorded': 'int', 'hook': 'int', 'unknown': 'int', 'custodian': 'int', 'epoch': 'int', 'rootEpoch': 'int', 'localEpoch': 'int', 'gate': 'int'}, 'actions': ['selectPlain', 'selectCollecting', 'selectReentrant', 'selectAbandoning', 'selectOpaque', 'selectWrongSelf', 'selectDebugIO', 'replaceBeforeGrant', 'grantFast', 'grantDurable', 'denyProfile', 'closeAdmission', 'beginAllocation', 'obtainNativeMemory', 'enterHook', 'returnHook', 'gcRound', 'reloadRoot', 'captureOutcome', 'publishInputs', 'abandonBeforeRecord', 'loseRecordedResponse', 'recoverPrivateRecord', 'recoverPublishedRecord', 'releaseSource', 'handoffBank', 'rollbackPlain']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
 r.pop('c11Refinement',None);r['c23Refinement']=False
 return a,r
