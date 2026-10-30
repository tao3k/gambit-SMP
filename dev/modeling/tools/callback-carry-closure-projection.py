from pathlib import Path
import importlib.util
SPEC={'module': 'callback_carry_closure', 'namespace': 'CallbackCarryAst', 'fields': {'pc': 'int', 'wlo': 'int', 'whi': 'int', 'rlo': 'int', 'rhi': 'int', 'carry': 'int', 'physical': 'int', 'bias': 'int', 'roots': 'int', 'active': 'int', 'epoch': 'int', 'sealedEpoch': 'int', 'closed': 'bool', 'mapped': 'bool', 'released': 'bool', 'permit': 'bool', 'unknown': 'bool'}, 'actions': ['beginLegal', 'beginInternalCarry', 'advanceFifo', 'allocateCandidate', 'installShared', 'expose', 'allocationFailure', 'capture', 'resume', 'returnActivation', 'attestRootRetirement', 'release', 'changeRegistration', 'unknownCallback', 'attestEffects']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py');s=importlib.util.spec_from_file_location('interval_scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
