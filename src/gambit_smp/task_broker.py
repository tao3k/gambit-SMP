"""Pass actual lease custody to tools whose provider closes inherited descriptors."""
from contextlib import contextmanager
import array
import hmac
import json
import os
from pathlib import Path
import secrets
import socket
import threading


@contextmanager
def serve(root,task,run,fd):
    # Keep Unix socket names below Darwin's 104-byte limit. The directory is 0700.
    import tempfile
    directory=Path(tempfile.mkdtemp(prefix='smp-lease-'))
    path=directory/'broker.sock'
    listener=socket.socket(socket.AF_UNIX,socket.SOCK_STREAM)
    try:
        listener.bind(str(path));os.chmod(path,0o600);listener.listen();listener.settimeout(.2)
    except BaseException:
        listener.close();path.unlink(missing_ok=True);directory.rmdir();raise
    from gambit_smp.workspace import bounded,write,context_run
    record=context_run(root,task,run)
    row=json.loads(record.read_text());st=directory.stat()
    row['broker']=dict(directory=str(directory),identity=[st.st_dev,st.st_ino])
    write(record,row)
    secret=secrets.token_hex(32);stopped=threading.Event()
    def loop():
        while not stopped.is_set():
            try:client,_=listener.accept()
            except socket.timeout:continue
            except OSError:return
            with client:
                client.settimeout(2)
                try:
                    request=json.loads(client.recv(4096))
                    if not hmac.compare_digest(request.get('secret',''),secret):continue
                    if request.get('task')!=task or request.get('run')!=run:continue
                    payload=json.dumps(dict(root=str(root),task=task,run=run)).encode()
                    client.sendmsg([payload],[(socket.SOL_SOCKET,socket.SCM_RIGHTS,array.array('i',[fd]))])
                except (OSError,ValueError,TypeError):continue
    thread=threading.Thread(target=loop,daemon=True);thread.start()
    values=dict(GAMBIT_SMP_TASK_SOCKET=str(path),GAMBIT_SMP_TASK_SECRET=secret)
    previous={key:os.environ.get(key) for key in values};os.environ.update(values)
    try:yield
    finally:
        stopped.set();listener.close();thread.join(timeout=3)
        for key,value in previous.items():
            if value is None:os.environ.pop(key,None)
            else:os.environ[key]=value
        path.unlink(missing_ok=True);directory.rmdir()


def borrow(root,task):
    address=os.environ.get('GAMBIT_SMP_TASK_SOCKET')
    if not address:return None
    with socket.socket(socket.AF_UNIX,socket.SOCK_STREAM) as client:
        client.settimeout(3);client.connect(address)
        client.sendall(json.dumps(dict(task=task,run=os.environ.get('GAMBIT_SMP_TASK_RUN'),
                                      secret=os.environ.get('GAMBIT_SMP_TASK_SECRET',''))).encode())
        data,control,flags,_=client.recvmsg(4096,socket.CMSG_SPACE(array.array('i').itemsize))
    descriptors=[]
    for level,kind,value in control:
        if level==socket.SOL_SOCKET and kind==socket.SCM_RIGHTS:
            ints=array.array('i');ints.frombytes(value[:len(value)-(len(value)%ints.itemsize)]);descriptors.extend(ints)
    try:
        bound=json.loads(data)
        if (flags & (socket.MSG_CTRUNC|socket.MSG_TRUNC) or len(descriptors)!=1 or bound!=dict(
                root=str(root),task=task,run=os.environ.get('GAMBIT_SMP_TASK_RUN'))):
            raise ValueError('invalid task custody transfer')
        fd=descriptors.pop()
        os.environ['GAMBIT_SMP_TASK_LOCK_FD']=str(fd)
        # A borrowed descriptor survives until this short-lived tool exits.
        return fd
    finally:
        for fd in descriptors:os.close(fd)


def cleanup(record):
    """After custody reconciliation, remove only the recorded orphan socket."""
    import stat
    if not record.get('broker'):return
    value=record['broker'];directory=Path(value['directory'])
    if not directory.exists():return
    st=directory.lstat()
    if (directory.is_symlink() or not directory.name.startswith('smp-lease-') or
            [st.st_dev,st.st_ino]!=value['identity']):raise ValueError('broker directory identity changed')
    for path in directory.iterdir():
        if path.name!='broker.sock' or not stat.S_ISSOCK(path.lstat().st_mode):raise ValueError('unrecognized broker artifact')
        path.unlink()
    directory.rmdir()
