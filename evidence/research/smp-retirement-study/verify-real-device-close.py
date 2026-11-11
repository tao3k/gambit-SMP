"""Darwin close interposition on actual Scheme file ports and final GSI."""
from pathlib import Path
import hashlib,importlib.util,json,os,re
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.framework import execute
from gambit_smp.recipes import tree_identity
ROOT=Path(__file__).resolve().parents[3]
BUILD=ROOT/'.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6'
SOURCE=BUILD/'source'
PREFIX=r'''
(define tested-port (open-output-file (getenv "SMP_CLOSE_PATH")))
(display "file bytes" tested-port)(force-output tested-port)
(define close-error? #f)
(with-exception-catcher (lambda (e) (set! close-error? #t))
 (lambda () (close-output-port tested-port)))
(if (not close-error?) (error "injected close error was not observed"))
(define replacement-port (open-output-file (getenv "SMP_REPLACEMENT_PATH")))
(display "replacement bytes" replacement-port)(force-output replacement-port)
(##gc)
(display "still usable" replacement-port)(force-output replacement-port)
(display "REAL-PORT-CLOSE-ERROR-ROOTED\n")(force-output)
'''
def main():
 spec=importlib.util.spec_from_file_location('control',ROOT/'evidence/research/smp-retirement-study/verify-owned-request-native.py');control=importlib.util.module_from_spec(spec);spec.loader.exec_module(control)
 with w.execution_scope(ROOT,'repair-9-12'),workspace_lease(ROOT,SOURCE,tree_identity(SOURCE)):
  out=w.task_output(ROOT,ROOT/'.cache/real-device-close');out.mkdir(parents=True,exist_ok=True)
  env=dict(os.environ);env.update(json.loads((BUILD/'configure-proof.json').read_text())['commands'][0]['environment']);env.pop('GAMBOPT',None)
  receipt=dict(schema='real-device-close.v1',gsiSha256=hashlib.sha256((SOURCE/'gsi/gsi').read_bytes()).hexdigest(),rows=[],nativeAdmitted=False)
  def run(n,args,cap,extra=None):
   e=dict(env);e.update(extra or {});meta={};rc,log,to,sec=execute(args,out,cap,env=e,metadata=meta);(out/(n+'.log')).write_text(log);row=dict(name=n,exit=rc,timedOut=to,seconds=sec,process=meta);receipt['rows'].append(row);(out/'receipt.json').write_text(json.dumps(receipt,indent=2));print(n,rc,to,sec,log[-1800:],flush=True);return row,log
  code=control.C.replace('#include <errno.h>','#include <errno.h>\n#include <string.h>\n#include <sys/param.h>\nstatic int close_calls,target_fd=-1,consumed_close,replacement_closes;')
  code=code.replace('static int injected_close(int fd) {',r'''static int injected_close(int fd) {
 char path[PATH_MAX];const char *target=getenv("SMP_CLOSE_PATH");
 const char *replacement=getenv("SMP_REPLACEMENT_PATH");
 if(replacement && fcntl(fd,F_GETPATH,path)==0 && strcmp(path,replacement)==0)replacement_closes++;
 if((fd==target_fd && fcntl(fd,F_GETFD)<0) || (target && fcntl(fd,F_GETPATH,path)==0 && strcmp(path,target)==0)) {
  target_fd=fd;close_calls++;
  int cm=atoi(getenv("SMP_CLOSE_MODE"));
  if(cm==4 && close_calls==1){close(fd);consumed_close=1;}
  errno=cm==1?EIO:cm==2?EBADF:EINTR;return -1;
 }
''')
  code=code.replace('char b[240];int n=snprintf',r'''char b[240];int replacement_open=0;const char *replacement=getenv("SMP_REPLACEMENT_PATH");
 char path[PATH_MAX];for(int i=0;i<256;i++)if(replacement && fcntl(i,F_GETPATH,path)==0 && strcmp(path,replacement)==0)replacement_open=1;
 int n=snprintf(b,sizeof(b),"REAL-CLOSE calls=%d fd-open=%d consumed=%d replacement-open=%d replacement-closes=%d\n",close_calls,target_fd>=0 && fcntl(target_fd,F_GETFD)>=0,consumed_close,replacement_open,replacement_closes);write(2,b,n);
 n=snprintf''')
  c=out/'close.c';c.write_text(code);lib=out/'close.dylib';row,_=run('compile-injector',['/opt/homebrew/Cellar/gcc/16.2.0/bin/gcc-16','-dynamiclib','-O1','-o',str(lib),str(c)],30)
  if row['exit'] or row['timedOut']:raise RuntimeError('close injector compilation failed')
  p=out/'close.scm';p.write_text(PREFIX+control.FAULT)
  for mode in [1,2,3,4]:
   row,log=run('close-'+str(mode),[str(SOURCE/'gsi/gsi'),'-:p11,~~lib='+str(SOURCE/'lib')+',~~bin='+str(SOURCE/'bin')+',~~include='+str(SOURCE/'include'),str(p)],30,dict(DYLD_INSERT_LIBRARIES=str(lib),SMP_WAKE_FAULT='2',SMP_WAKE_ARM_FILE=str(out/('arm-'+str(mode))),SMP_CLOSE_PATH=str(out/('original-'+str(mode))),SMP_REPLACEMENT_PATH=str(out/('replacement-'+str(mode))),SMP_CLOSE_MODE=str(mode)))
   m=re.search(r'REAL-CLOSE calls=(\d+) fd-open=(\d+) consumed=(\d+) replacement-open=(\d+) replacement-closes=(\d+)',log);row['closeObservation']=list(map(int,m.groups())) if m else None
   row['passed']=bool(row['exit']==70 and not row['timedOut'] and m and int(m[1])==1 and int(m[3])==(mode==4) and int(m[4])+int(m[5])==1 and 'REAL-PORT-CLOSE-ERROR-ROOTED' in log and 'SMP-FAULT coordinator=P0 prepared' in log and 'cleanup failed with retained runtime resources' in log)
   (out/'receipt.json').write_text(json.dumps(receipt,indent=2))
  print(out,flush=True)
  if not all(r.get('passed',True) for r in receipt['rows']):raise RuntimeError('real close failure control failed')
if __name__=='__main__':main()
