from pathlib import Path
import re,hashlib,json
R=Path.cwd()
def sha(b):return hashlib.sha256(b).hexdigest()
def apply_mem(source,patch,reverse=False):
 lines=patch.splitlines(keepends=True)
 start=next(i for i,x in enumerate(lines) if x.startswith('diff --git a/lib/mem.c b/lib/mem.c'))
 stop=next((i for i in range(start+1,len(lines)) if lines[i].startswith('diff --git ')),len(lines))
 pos=start;cursor=0;result=[];original=source.splitlines(keepends=True)
 while pos<stop:
  m=re.match(r'@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@',lines[pos])
  if not m:pos+=1;continue
  expected=int(m.group(3 if reverse else 1))-1
  assert expected>=cursor,(expected,cursor)
  result.extend(original[cursor:expected]);cursor=expected;pos+=1
  while pos<stop and not lines[pos].startswith('@@ '):
   ln=lines[pos];pos+=1
   if ln.startswith('\\'):continue
   op=ln[:1];body=ln[1:]
   if op not in ' +-':continue
   if reverse:op={'+':'-','-':'+',' ':' '}[op]
   if op in ' -':assert original[cursor]==body,(cursor+1,original[cursor],body);cursor+=1
   if op in ' +':result.append(body)
 result.extend(original[cursor:])
 return ''.join(result)
def materialize():
 j=json.loads((R/'evidence/research/smp-retirement-study/diagnostic-order-id-generated-c.json').read_text())
 old=R/j['candidate']/'lib/mem.c';assert sha(old.read_bytes())==j['sourceHashes']['lib/mem.c']
 base=apply_mem(old.read_text(),(R/j['patch']).read_text(),True)
 lock=R/'evidence/research/processor-interrupt-collective-wait/current-lock-scan-diag.lock.json';new=json.loads(lock.read_text())
 assert sha(base.encode())==new['files']['lib/mem.c']['baseSha256']
 text=apply_mem(base,(R/new['patch']).read_text())
 assert sha(text.encode())==new['files']['lib/mem.c']['candidateSha256']
 return text,j,new
if __name__=='__main__':
 text,_,_=materialize();a=text.splitlines()
 names=['gc_diag_publish','mark_array_body','mark_captured_continuation','mark_frame','mark_continuation','mark_rc','scan_and_advance','___setup_mem_pstate','___setup_mem_vmstate','___cleanup_mem_pstate','___cleanup_mem_vmstate','garbage_collect_mark_strong_phase','___garbage_collect_pstate']
 for name in names:
  print(name,[(i+1,z.strip()) for i,z in enumerate(a) if re.search(r'\b'+re.escape(name)+r'\b',z)][:8])
 print('sha256',sha(text.encode()))
