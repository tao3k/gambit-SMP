"""Restricted actual Quint typed-IR projection; parser/emitter remain trusted."""
ACTIONS=['forward','initializeCopy','publishReady','publishBatch','duplicateTask','closeInputs','finishTail','claim0','claim1','own0','own1','skip0','skip1','done0','done1','drain0','drain1','idle0','idle1','terminate']
def generate(ir):
 assert not ir.get('errors') and len(ir['modules'])==1
 module=ir['modules'][0];assert module['name']=='object_scan_custody'
 ds=module['declarations'];assert len({d['name'] for d in ds})==len(ds)
 defs={d['name']:d for d in ds};var=defs['s'];assert var['kind']=='var'
 fields={f['fieldName']:f['fieldType']['kind'] for f in defs['State']['type']['fields']['fields']}
 assert fields==dict(phase='int',owner='int',t0='int',t1='int',payload='bool',forwarded='bool',copier='bool',tail='bool',privateChunk='bool',child0='bool',child1='bool',active0='bool',active1='bool',closed='bool',terminated='bool')
 refs=[]
 def state(e):
  assert e['kind']=='name' and e['name']=='s'
  row=ir['table'][str(e['id'])];assert row['id']==var['id'] and row['kind']=='var' and row['depth']==0
  refs.append((e['id'],row['id']))
 def field(e):
  assert e['opcode']=='field' and len(e['args'])==2
  state(e['args'][0]);f=e['args'][1];assert f['kind']=='str' and f['value'] in fields
  return f['value']
 def integer(e):
  if e['kind']=='int':assert type(e['value']) is int;return '('+str(e['value'])+')'
  if e.get('opcode')=='iuminus':assert len(e['args'])==1;return '(-'+integer(e['args'][0])+')'
  f=field(e);assert fields[f]=='int';return 'q.'+f
 def prop(e):
  if e['kind']=='bool':return 'True' if e['value'] else 'False'
  if e.get('opcode')=='field':f=field(e);assert fields[f]=='bool';return '(q.'+f+'=true)'
  op=e['opcode'];a=e['args']
  if op in ['and','or','actionAll','actionAny']:
   return '('+(' ∧ ' if op in ['and','actionAll'] else ' ∨ ').join(prop(x) for x in a)+')'
  if op=='not':assert len(a)==1;return '(¬'+prop(a[0])+')'
  if op=='implies':assert len(a)==2;return '('+prop(a[0])+' → '+prop(a[1])+')'
  if op in ['eq','neq','ilt','ilte','igt','igte']:
   assert len(a)==2;return '('+integer(a[0])+dict(eq='=',neq='≠',ilt='<',ilte='≤',igt='>',igte='≥')[op]+integer(a[1])+')'
  raise AssertionError(op)
 def updates(e):
  if e['kind']=='name':state(e);return []
  assert e['opcode']=='with' and len(e['args'])==3
  old,k,v=e['args'];xs=updates(old);assert k['kind']=='str' and k['value'] in fields and k['value'] not in [k for k,_ in xs]
  f=k['value']
  if fields[f]=='bool':assert v['kind']=='bool';value=str(v['value']).lower()
  else:value=integer(v)
  return xs+[(f,value)]
 out=['import Std','namespace ObjectScanAst','set_option maxRecDepth 10000','structure State where']
 out += [' '+k+' : '+('Bool' if t=='bool' else 'Int') for k,t in fields.items()]
 out += [' deriving DecidableEq','def Safe (q : State) : Prop := '+prop(defs['safe']['expr'])]
 initial=defs['initial']['expr'];assert initial['opcode']=='Rec'
 pairs=list(zip(initial['args'][::2],initial['args'][1::2],strict=True));assert [k['value'] for k,_ in pairs]==list(fields)
 init=[]
 for k,v in pairs:
  f=k['value'];value=str(v['value']).lower() if fields[f]=='bool' else integer(v);init.append(f+':='+value)
 out += ['def initial : State := {'+', '.join(init)+'}']
 for name in ACTIONS:
  expr=defs[name]['expr'];assert expr['opcode']=='actionAll';xs=expr['args'];last=xs[-1]
  assert last['opcode']=='assign';state(last['args'][0]);us=updates(last['args'][1])
  out += ['def '+name+'Guard (q : State) : Prop := '+' ∧ '.join(prop(x) for x in xs[:-1]),'def '+name+'Next (q : State) : State := {q with '+', '.join(k+':='+v for k,v in us)+'}']
 # The executable step roster must be exactly the projected actions plus stutter.
 step=defs['step']['expr'];assert step['opcode']=='actionAny'
 assert [x['name'] for x in step['args'][:-1]]==ACTIONS
 for x in step['args'][:-1]:assert ir['table'][str(x['id'])]['id']==defs[x['name']]['id']
 last=step['args'][-1];assert last['opcode']=='actionAll' and len(last['args'])==1
 eq=last['args'][0];assert eq['opcode']=='assign';state(eq['args'][0]);state(eq['args'][1])
 out += ['def Step (q r : State) : Prop := '+' ∨ '.join('('+n+'Guard q ∧ r='+n+'Next q)' for n in ACTIONS)+' ∨ r=q','end ObjectScanAst']
 return '\n'.join(out)+'\n',dict(actions=ACTIONS,stateReferences=refs,fullStepRosterChecked=True,parserVerified=False,emitterVerified=False,c11Refinement=False)
