"""Read-only replay of diagnostic assembly/source evidence; no compiler/native run."""
import hashlib,json,re,sys
from pathlib import Path

NAMES=('release_only','signal_only','store_seqcst','full_barrier','two_reads')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def inspect(assembly):
 rows=[]
 for name in NAMES:
  m=re.search(r'^_'+name+r':[^\n]*\n(.*?)(?=^\s*\.cfi_endproc|^LFE\d+:)',assembly,re.M|re.S)
  body=m.group(1) if m else ''
  commits=list(re.finditer(r'\b(?:stlr|stlur)\s+x\d+,',body))
  fences=list(re.finditer(r'\bdmb\s+ish\b',body))
  loads=list(re.finditer(r'\bldr\s+x\d+,\s*\[x[12]\]',body))
  payload=list(re.finditer(r'\bstp\s+x\d+,\s*x\d+,\s*\[x0\]',body))
  calls=bool(re.search(r'^\s*(?:bl|blr)\s',body,re.M))
  count=2 if name=='two_reads' else 1
  barrier=count if name in ('full_barrier','two_reads') else 0
  okay=bool(m) and not calls and len(commits)==len(loads)==len(payload)==count and len(fences)==barrier
  if okay:
   okay=all(payload[i].start()<commits[i].start()<loads[i].start() for i in range(count))
   if barrier:okay=okay and all(commits[i].start()<fences[i].start()<loads[i].start() for i in range(count))
   if count==2:okay=okay and loads[0].start()<payload[1].start()
   if count==2:
    raw=re.search(r'^\s*str\s+x\d+,\s*\[x0,\s*#?24\]',body,re.M)
    okay=okay and bool(raw) and loads[0].start()<raw.start()<commits[1].start()
  rows.append(dict(function=name,expectedAssembly=okay,commitInstructions=[x.group(0) for x in commits],fullFences=len(fences),ordinaryLoads=len(loads),payloadPairs=len(payload),calls=calls,acceptedOrderingPattern=okay and bool(barrier),body=body))
 return rows
def negative_controls(assembly):
 # Mutate only the full_barrier body; retain all other function bytes.
 m=re.search(r'(^_full_barrier:[^\n]*\n)(.*?)(?=^\s*\.cfi_endproc|^LFE\d+:)',assembly,re.M|re.S)
 assert m
 body=m.group(2)
 def changed(b):return assembly[:m.start(2)]+b+assembly[m.end(2):]
 no_fence=re.sub(r'^\s*dmb\s+ish[^\n]*\n','',body,flags=re.M)
 commit=re.search(r'^\s*(?:stlr|stlur)\s+x\d+,[^\n]*\n',body,re.M)
 load=re.search(r'^\s*ldr\s+x\d+,\s*\[x1\][^\n]*\n',body,re.M)
 assert commit and load
 reversed_order=body[:commit.start()]+load.group(0)+body[commit.end():load.start()]+commit.group(0)+body[load.end():]
 no_raw=re.sub(r'^\s*str\s+x\d+,\s*\[x0,\s*#?24\][^\n]*\n','',assembly,flags=re.M)
 rows=[]
 for name,a,fn in [('missing-full-fence',changed(no_fence),'full_barrier'),('commit-after-load',changed(reversed_order),'full_barrier'),('missing-loaded-raw-store',no_raw,'two_reads')]:
  rejected=not next(x for x in inspect(a) if x['function']==fn)['expectedAssembly']
  assert rejected,name
  rows.append(dict(control=name,rejected=rejected))
 return rows
def verify(root,receipt):
 r=json.loads(receipt.read_text());assert sha(root/r['source'])==r['sourceSha256']
 result=[]
 for row in r['rows']:
  assert row['exit']==0 and not row['timeout']
  assert row['execution']['parentReaped'] and row['execution']['processGroupQuiescent']
  p=root/row['assembly'];assert sha(p)==row['sha256']
  checks=inspect(p.read_text());assert all(x['expectedAssembly'] for x in checks),checks
  result.append(dict(compiler=row['argv'][0],optimization=row['argv'][1],assembly=row['assembly'],assemblySha256=row['sha256'],checks=checks))
 assert len(result)==4
 return result
def main():
 root=Path(__file__).resolve().parents[3]
 index=json.loads((root/'evidence/research/smp-retirement-study/diagnostic-order-id-generated-c.json').read_text())
 for p,h in index['sourceHashes'].items():assert sha(root/index['candidate']/p)==h,p
 for p,h in index['protectedInputs'].items():assert sha(root/p)==h,p
 for p,h in index['historicalInputs'].items():assert sha(root/p)==h,p
 for key in ['lock','patch']:
  assert sha(root/index[key])==index[key+'Sha256']
 receipt=root/index['assemblyReceipt'];assert sha(receipt)==index['assemblyReceiptSha256']
 rows=verify(root,receipt)
 negatives=negative_controls((root/rows[0]['assembly']).read_text())
 assert sha(root/'evidence/research/smp-retirement-study/diagnostic-order-control.c')==json.loads(receipt.read_text())['sourceSha256']
 print(json.dumps(dict(assemblyVariants=sum(len(x['checks']) for x in rows),expectedControls=True,checkerNegativeControls=negatives,candidateFiles=len(index['sourceHashes']),protectedInputs=len(index['protectedInputs']),historicalFiles=len(index['historicalInputs']),nativeRuntimeExecutions=0)))
if __name__=='__main__':main()
