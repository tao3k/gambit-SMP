import json,pathlib,struct,lldb
O=json.loads(pathlib.Path(__file__).with_name('offsets.json').read_text());vm_seen=0
def read(p,a,n=8):
 e=lldb.SBError();d=p.ReadMemory(a,n,e)
 if e.Fail():raise RuntimeError(str(e))
 return int.from_bytes(d,'little')
def duplicate(f,b,u):
 p=f.GetThread().GetProcess();w=f.FindRegister('x20').GetValueAsUnsigned();body=f.FindRegister('x21').GetValueAsUnsigned()
 carrier=read(p,w+O['worker']['carrier']);vm=read(p,carrier+O['pstate']['vmstate']);n=read(p,vm+O['vm']['processor_count'],4)
 rows=[]
 for i in range(n):
  a=vm+O['vm']['collector_workers']+i*O['worker']['stride']
  row={k:read(p,a+v,4 if k=='scan_origin_' else 8) for k,v in O['worker'].items() if k!='stride'}
  row.update(index=i,address=a,requester=a==w,sameObject=row['active_scan_object_']==body)
  rows.append(row)
 epoch=struct.unpack('<d',read(p,vm+O['vm']['mem.nb_gcs_']).to_bytes(8,'little'))[0]
 print('CHUNK-TRANSPORT '+json.dumps({'body':body,'header':read(p,body-8),'state':f.FindRegister('x0').GetValueAsUnsigned(),'completedGCs':epoch,'workers':rows}),flush=True)
 return True
def resize(f,b,u):
 global vm_seen
 p=f.GetThread().GetProcess();ps=f.FindRegister('x0').GetValueAsUnsigned();vm_seen=read(p,ps+O['pstate']['vmstate']);return False
def fatal(f,b,u):
 p=f.GetThread().GetProcess();vm=vm_seen
 if not vm:return True
 n=read(p,vm+O['vm']['processor_count'],4);rows=[]
 sect=read(p,vm+O['vm']['mem.the_msections_']);cur=read(p,sect+O['sections']['head']);regions=[]
 for _ in range(read(p,sect+O['sections']['nb_sections'],4)):
  regions.append((cur+O['section']['base'],read(p,cur+O['section']['index'],4)))
  cur=read(p,cur+O['section']['next'])
 parity=read(p,vm+O['vm']['execution_contexts']+O['context']['mem.tospace_offset_'])
 def state(link):
  for base,index in regions:
   pos=(link-base)//8-parity
   if 0<=pos<65536:
    word=read(p,base+131072*8+(pos//32)*8)
    return {'section':index,'word':pos,'state':(word>>(2*(pos%32)))&3}
  return None
 for i in range(n):
  a=vm+O['vm']['collector_workers']+i*O['worker']['stride']
  row={k:read(p,a+v,4 if k=='scan_origin_' else 8) for k,v in O['worker'].items() if k!='stride'}
  head=row['heap_chunks_to_scan_head_'];tail=row['heap_chunks_to_scan_tail_'];nxt=read(p,head)-3
  row.update(index=i,address=a,queueNext=nxt,queueNextState=state(nxt),localState=state(row['local_scan_chunk_']-8),activeState=state(row['active_scan_chunk_']-8))
  rows.append(row)
 frames=[]
 for sf in f.GetThread():
  if len(frames)>4:break
  frames.append({'name':sf.GetFunctionName(),'pc':sf.GetPC(),'registers':{r:sf.FindRegister(r).GetValueAsUnsigned() for r in ['x0','x1','x2','x3','x19','x20','x21','x22','x23','x24','x25']}})
 print('CHUNK-FATAL '+json.dumps({'vm':vm,'workers':rows,'frames':frames,'candidateX19':state(frames[1]['registers']['x19']),'candidateX20':state(frames[1]['registers']['x20'])}),flush=True)
 return True
