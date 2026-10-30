"""Restricted typed-IR projection of the existing frame-root action slice.
JSON parsing, this emitter and the Quint built-in interpretation are trusted.
Integer power is admitted only for nonnegative exponents; no native C claim.
"""
import json,hashlib
NAMES=['width','start','startRun','root','eligible','advanceCursor','runWord','runCoverage','runCurrent','runSafe','runStep']
def generate(ir):
 assert not ir.get('errors') and len(ir['modules'])==1
 mod=ir['modules'][0];assert mod['name']=='frame_roots'
 ds={d['name']:d for d in mod['declarations']};assert len(ds)==len(mod['declarations'])
 fields=ds['Scan']['type']['fields']['fields'];expected=['fs','bitmap','slot','word','next','seen','visits','mode','excluded','first','past','delivered','runs','scanWidth']
 assert [f['fieldName'] for f in fields]==expected
 assert all(f['fieldType']['kind']==('set' if f['fieldName'] in ['seen','delivered'] else 'int') for f in fields)
 assert all(f['fieldType'].get('elem',{}).get('kind')=='int' for f in fields if f['fieldType']['kind']=='set')
 refs=[];calls=[];ops=set()
 def typ(t):
  if t['kind']=='int':return 'Int'
  if t['kind']=='bool':return 'Prop'
  if t['kind']=='set':assert t['elem']['kind']=='int';return '(Int → Prop)'
  if t['kind']=='const':assert t['name']=='Scan';return 'Scan'
  raise AssertionError(t)
 def emit(e,env,action=False):
  k=e['kind']
  if k=='int':assert type(e['value']) is int;return '('+str(e['value'])+' : Int)'
  if k=='bool':return 'True' if e['value'] else 'False'
  if k=='name':
   name=e['name']
   if name not in env:
    assert name in NAMES and ds[name]['expr']['kind']!='lambda'
    row=ir['table'][str(e['id'])];assert row['id']==ds[name]['id'] and row['kind']=='def'
    calls.append([e['id'],row['id'],name]);return name if name=='width' else '('+name+' q)'
   assert name in env,(name,env)
   row=ir['table'][str(e['id'])];assert row['id']==env[name][0] and row['name']==name,(name,row,env[name])
   refs.append([e['id'],row['id'],name]);return env[name][1]
  if k=='let':
   d=e['opdef'];assert d['qualifier']=='val' and d['name'] not in env
   rhs=emit(d['expr'],env,action);env=dict(env,**{d['name']:(d['id'],d['name'])})
   return '(let '+d['name']+' := '+rhs+'; '+emit(e['expr'],env,action)+')'
  assert k=='app',k
  op=e['opcode'];a=e['args'];ops.add(op)
  if op=='Rec':
   pairs=list(zip(a[::2],a[1::2],strict=True));assert [k['value'] for k,v in pairs]==expected
   return '{'+', '.join(k['value']+':='+emit(v,env) for k,v in pairs)+'}'
  if op=='Set':assert not a;return '(fun _ : Int => False)'
  if op=='field':assert a[1]['kind']=='str' and a[1]['value'] in expected;return '('+emit(a[0],env)+').'+a[1]['value']
  if op=='with':
   assert a[1]['kind']=='str' and a[1]['value'] in expected
   return '{'+emit(a[0],env)+' with '+a[1]['value']+':='+emit(a[2],env)+'}'
  if op=='assign':assert action and a[0]['kind']=='name' and a[0]['name']=='s';emit(a[0],env);return emit(a[1],env)
  if op=='ite':return '(if '+emit(a[0],env)+' then '+emit(a[1],env,action)+' else '+emit(a[2],env,action)+')'
  if op in ['iadd','isub','imul','idiv','imod','eq','neq','ilt','ilte','igt','igte','implies','iff']:
   assert len(a)==2
   token=dict(iadd='+',isub='-',imul='*',idiv='/',imod='%',eq='=',neq='≠',ilt='<',ilte='≤',igt='>',igte='≥',implies='→',iff='↔')[op]
   if op=='eq' and ir['types'][str(a[0]['id'])]['type']['kind']=='bool':token='↔'
   return '('+emit(a[0],env)+' '+token+' '+emit(a[1],env)+')'
  if op=='ipow':assert len(a)==2;return '('+emit(a[0],env)+' ^ ('+emit(a[1],env)+').toNat)'
  if op in ['and','or','actionAll']:
   return '('+(' ∨ ' if op=='or' else ' ∧ ').join(emit(x,env) for x in a)+')'
  if op=='not':assert len(a)==1;return '(¬'+emit(a[0],env)+')'
  if op=='to':return '(fun i : Int => '+emit(a[0],env)+'≤i ∧ i≤'+emit(a[1],env)+')'
  if op=='union':return '(fun i : Int => ('+emit(a[0],env)+') i ∨ ('+emit(a[1],env)+') i)'
  if op=='contains':return '(('+emit(a[0],env)+') '+emit(a[1],env)+')'
  if op in ['forall','filter']:
   lam=a[1];assert lam['kind']=='lambda' and len(lam['params'])==1
   param=lam['params'][0];assert param['name'] not in env
   body=emit(lam['expr'],dict(env,**{param['name']:(param['id'],param['name'])}))
   return ('(∀ '+param['name']+' : Int, ('+emit(a[0],env)+') '+param['name']+' → '+body+')' if op=='forall' else '(fun '+param['name']+' : Int => ('+emit(a[0],env)+') '+param['name']+' ∧ '+body+')')
  assert op in NAMES and op!='runStep',op
  row=ir['table'][str(e['id'])];assert row['id']==ds[op]['id'] and row['kind']=='def'
  calls.append([e['id'],row['id'],op]);return '('+op+' '+ ' '.join('('+emit(x,env)+')' for x in a)+')'
 out=['import Std','namespace Gambit.FrameCursorAst','noncomputable section','attribute [local instance] Classical.propDecidable','structure Scan where']
 out+=[' '+f['fieldName']+' : '+typ(f['fieldType']) for f in fields]
 for name in NAMES:
  d=ds[name];expr=d['expr'];env={'s':(ds['s']['id'],'q')};params=[]
  if expr['kind']=='lambda':
   for p in expr['params']:
    assert p['name'] not in env;env[p['name']]=(p['id'],p['name']);params.append('('+p['name']+' : '+typ(p['typeAnnotation'])+')')
   expr=expr['expr']
  else:params=[] if name=='width' else ['(q : Scan)']
  result='Scan' if name=='runStep' else typ(d['typeAnnotation']['res'] if d['expr']['kind']=='lambda' else ir['types'][str(expr['id'])]['type'])
  out+=['def '+('runNext' if name=='runStep' else name)+' '+' '.join(params)+' : '+result+' := '+emit(expr,env,name=='runStep')]
 out+=['end','end Gambit.FrameCursorAst']
 return '\n'.join(out)+'\n',dict(slice=NAMES,nameReferences=refs,callReferences=calls,operators=sorted(ops),sourceAstSha256=hashlib.sha256(json.dumps([ds[n] for n in NAMES],sort_keys=True).encode()).hexdigest(),integerEncoding='Int; pow exponent admitted nonnegative only',setEncoding='Int membership predicates; extensional equality',parserVerified=False,emitterVerified=False,nativeRefinement=False,wholeModuleExtraction=False)
