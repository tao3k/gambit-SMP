from pathlib import Path
import importlib.util
SPEC={'module': 'native_binding_plan_retirement', 'namespace': 'NativeBindingPlanAst', 'fields': {'stage': 'int', 'epoch': 'int', 'planEpoch': 'int', 'mode': 'int', 'demand': 'int', 'headerDemand': 'int', 'prmCount': 'int', 'gloCount': 'int', 'entry': 'bool', 'layout': 'bool', 'exclusive': 'bool', 'noObservers': 'bool', 'sealed': 'bool', 'first': 'bool', 'second': 'bool', 'prm': 'bool', 'glo': 'bool', 'paused': 'bool', 'revoked': 'bool', 'custody': 'bool', 'closed': 'bool', 'receipt': 'bool'}, 'actions': ['discover', 'resolve', 'closeWriters', 'admitElision', 'requireMetadata', 'writeHeader', 'sealPlan', 'firstElide', 'firstPreserve', 'emitPrm', 'secondElide', 'secondPreserve', 'emitGlo', 'closeOutput', 'issue', 'pause', 'resumeSame', 'foreignReentry', 'lateWriter', 'escapedObserver', 'unknownExit', 'rejectResume']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py');s=importlib.util.spec_from_file_location('native_binding_scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
