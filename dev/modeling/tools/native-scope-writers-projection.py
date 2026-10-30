"""Closed-writer NativeScope typed-IR projection; no native refinement claim."""
import importlib.util
from pathlib import Path
SPEC = {'module': 'native_scope_writers', 'namespace': 'NativeScopeAst', 'fields': {'phase': 'int', 'generation': 'int', 'thread': 'int', 'cap': 'int', 'nested': 'int', 'gate': 'int', 'pending': 'int', 'unknown': 'int', 'pins': 'int', 'roots': 'int', 'descriptors': 'int', 'custodian': 'int', 'closedWorld': 'int', 'pub': 'int', 'view': 'int', 'rf': 'int', 'observed': 'int', 'floor0': 'int', 'floor1': 'int', 'handoffRelease': 'int', 'targetAcquired': 'int', 'returnRight': 'int', 'recorded': 'int', 'callGen': 'int', 'responseGen': 'int', 'rejected': 'int'}, 'actions': ['issue', 'beginWrite', 'publishRelease', 'recordOutcome', 'deliverOutcome', 'loseResponse', 'recoverRecorded', 'enterNested', 'leaveNested', 'catcherSubtree', 'acquire0', 'acquire1', 'closeAdmission', 'renewSameThread', 'prepareMigration', 'targetAcquire', 'issueTarget', 'rejectStaleDelivery', 'rawInterference', 'retire']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
 r.pop('c11Refinement',None);r['c23Refinement']=False
 return a,r
