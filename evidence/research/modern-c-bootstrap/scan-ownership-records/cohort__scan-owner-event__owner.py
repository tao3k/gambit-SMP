import json,lldb
def read(p,a):
 e=lldb.SBError();d=p.ReadMemory(a,8,e)
 if e.Fail():raise RuntimeError(str(e))
 return int.from_bytes(d,'little')
def event(f,b,u):
 p=f.GetThread().GetProcess();work=f.FindRegister('x20').GetValueAsUnsigned();body=f.FindRegister('x21').GetValueAsUnsigned();state=f.FindRegister('x0').GetValueAsUnsigned();owners=[]
 for t in p:
  for sf in t:
   if sf.GetFunctionName()=='scan':
    owners.append({'tid':t.GetThreadID(),'frame':sf.GetFrameID(),'body':hex(sf.FindRegister('x21').GetValueAsUnsigned()),'worker':hex(sf.FindRegister('x20').GetValueAsUnsigned())})
 print('SCAN-OWNER '+json.dumps({'event':'duplicate-scan-request','thread':f.GetThread().GetThreadID(),'worker':hex(work),'body':hex(body),'header':hex(read(p,body-8)),'state':state,'previousDuplicates':read(p,work+24),'activeScanFrames':owners}),flush=True)
 return True
