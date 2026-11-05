"""Reconstruct lock-bound evidence bytes in memory; no build/workspace mutation."""
from pathlib import Path
import re,json,hashlib
R=Path.cwd()
def sha(data):return hashlib.sha256(data).hexdigest()
def apply_file(source,patch,name,reverse=False):
 lines=patch.splitlines(keepends=True);tag='diff --git a/'+name+' b/'+name
 found=[i for i,x in enumerate(lines) if x.rstrip('\n')==tag]
 if not found:return source
 assert len(found)==1
 start=found[0];stop=next((i for i in range(start+1,len(lines)) if lines[i].startswith('diff --git ')),len(lines))
 old=source.splitlines(keepends=True);result=[];cursor=0;pos=start
 while pos<stop:
  m=re.match(r'@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@',lines[pos])
  if not m:pos+=1;continue
  begin=int(m.group(3 if reverse else 1))-1
  assert begin>=cursor;result.extend(old[cursor:begin]);cursor=begin;pos+=1
  while pos<stop and not lines[pos].startswith('@@ '):
   line=lines[pos];pos+=1
   if line.startswith('\\'):continue
   op=line[:1];body=line[1:]
   if op not in (' ','+','-'):continue
   if reverse:op={' ':' ','+':'-','-':'+'}[op]
   if op in (' ','-'):assert old[cursor]==body,(name,cursor+1);cursor+=1
   if op in (' ','+'):result.append(body)
 result.extend(old[cursor:]);return ''.join(result)
def materialize():
 e=R/'evidence/research/smp-retirement-study'
 old=json.loads((e/'diagnostic-order-id-generated-c.json').read_text())
 new=json.loads((R/'evidence/research/processor-interrupt-collective-wait/current-lock-scan-carrier.lock.json').read_text())
 oldpatch=(R/old['patch']).read_text();patch=(R/new['patch']).read_text()
 assert sha(patch.encode())==new['patchSha256']
 files={}
 for name,row in new['files'].items():
  p=R/old['candidate']/name;assert sha(p.read_bytes())==old['sourceHashes'][name]
  base=apply_file(p.read_text(),oldpatch,name,True);assert sha(base.encode())==row['baseSha256'],name
  candidate=apply_file(base,patch,name);assert sha(candidate.encode())==row['candidateSha256'],name
  files[name]=candidate
 return files,old,new
if __name__=='__main__':
 files,_,_=materialize()
 print(json.dumps(dict(lockedFiles=len(files),hashes={p:sha(t.encode()) for p,t in files.items() if p in ['lib/mem.c','lib/setup.c','include/gambit.h.in']})))
 a=files['lib/mem.c'].splitlines()
 for name in ['gc_diag_note_fault','gc_diag_bind_shared','gc_diag_bind_owner','gc_diag_publish','___setup_mem_pstate','___garbage_collect_pstate','mark_array_body']:
  print(name,[(i+1,z.strip()) for i,z in enumerate(a) if re.search(r'\b'+name+r'\b',z)][:6])
