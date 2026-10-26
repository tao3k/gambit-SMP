"""Delegate scalar typed-IR projection to the pinned prior literal-coefficient emitter."""
from pathlib import Path
import importlib.util
SPECS = [{'module': 'default_section_leases', 'namespace': 'SectionLeasesAst', 'proof': 'SectionLeases', 'actions': ['fresh4worker0', 'fresh4worker1', 'fresh5worker0', 'fresh5worker1', 'shareWorker0', 'shareWorker1', 'denyStackRebind', 'denyGrow', 'denyReentry', 'unknownWriter', 'exhaustedShared0', 'closeAllocators'], 'fields': {'n': 'int', 'p': 'int', 'cursor': 'int', 'fresh': 'int', 'shared': 'int', 'visits': 'int', 'owner4': 'int', 'owner5': 'int', 'heap0': 'int', 'heap1': 'int', 'denied': 'int', 'shared0': 'bool', 'shared1': 'bool', 'certified': 'bool', 'retained': 'bool', 'closed': 'bool'}}, {'module': 'capacity_collective', 'namespace': 'CapacityCollectiveAst', 'proof': 'CapacityCollective', 'actions': ['publishReady', 'publishFailure', 'accept0', 'accept1', 'reject0', 'reject1', 'decideAccept', 'decideReject', 'acknowledge0', 'acknowledge1', 'release', 'flip0', 'flip1', 'deliver0', 'deliver1', 'retainUnknown', 'retainSetupUnknown', 'freeRejected'], 'fields': {'generation': 'int', 'decision': 'int', 'vote0': 'int', 'vote1': 'int', 'seen0': 'int', 'seen1': 'int', 'result0': 'int', 'result1': 'int', 'published': 'bool', 'poolReady': 'bool', 'ack0': 'bool', 'ack1': 'bool', 'reader0': 'bool', 'reader1': 'bool', 'released': 'bool', 'flip0': 'bool', 'flip1': 'bool', 'retained': 'bool', 'freed': 'bool'}}]
def generate(ir,cfg):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('lease_scalar_projection',p)
 m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,cfg['module'],cfg['fields'],cfg['actions'],cfg['namespace'])
