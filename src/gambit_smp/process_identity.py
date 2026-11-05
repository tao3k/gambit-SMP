"""Kernel process identity, without spawning a second process to identify one."""
import ctypes
import errno
import os
from pathlib import Path
import sys


def boot_id():
    if sys.platform=='darwin':
        libc=ctypes.CDLL(None,use_errno=True);buffer=ctypes.create_string_buffer(128);size=ctypes.c_size_t(len(buffer))
        if libc.sysctlbyname(b'kern.bootsessionuuid',buffer,ctypes.byref(size),None,0):raise OSError(ctypes.get_errno(),'boot identity unavailable')
        return buffer.value.decode()
    return Path('/proc/sys/kernel/random/boot_id').read_text().strip()


class BSDInfo(ctypes.Structure):
    # SDK sys/proc_info.h: struct proc_bsdinfo, PROC_PIDTBSDINFO.
    _fields_=[(name,ctypes.c_uint32) for name in ('flags','status','xstatus','pid','ppid','uid','gid','ruid','rgid','svuid','svgid','reserved')]+[
        ('comm',ctypes.c_char*16),('name',ctypes.c_char*32)]+[(name,ctypes.c_uint32) for name in ('nfiles','pgid','jobc','tdev','tpgid')]+[
        ('nice',ctypes.c_int32),('start_sec',ctypes.c_uint64),('start_usec',ctypes.c_uint64)]


def process(pid):
    if isinstance(pid,bool) or not isinstance(pid,int) or pid<=0:raise ValueError('positive kernel PID required')
    if sys.platform=='darwin':
        library=ctypes.CDLL('/usr/lib/libproc.dylib',use_errno=True);info=BSDInfo()
        result=library.proc_pidinfo(int(pid),3,0,ctypes.byref(info),ctypes.sizeof(info))
        if result!=ctypes.sizeof(info):
            error=ctypes.get_errno()
            if error==errno.ESRCH:return None
            raise OSError(error,'kernel process identity unavailable')
        return dict(pid=info.pid,ppid=info.ppid,pgid=info.pgid,uid=info.uid,
                    startSeconds=info.start_sec,startMicroseconds=info.start_usec,
                    name=bytes(info.comm).decode(errors='replace'),method='proc_pidinfo-PROC_PIDTBSDINFO')
    try:
        text=Path(f'/proc/{pid}/stat').read_text();fields=text[text.rindex(')')+2:].split()
        ticks=int(fields[19]);hz=os.sysconf('SC_CLK_TCK')
        boot=int(next(line.split()[1] for line in Path('/proc/stat').read_text().splitlines() if line.startswith('btime ')))
        return dict(pid=int(pid),ppid=int(fields[1]),pgid=int(fields[2]),uid=Path(f'/proc/{pid}').stat().st_uid,
                    startTicks=ticks,startSeconds=boot+ticks//hz,startMicroseconds=(ticks%hz)*1000000//hz,method='proc-stat-starttime')
    except FileNotFoundError:return None


def pids(uid=None):
    if sys.platform=='darwin':
        library=ctypes.CDLL('/usr/lib/libproc.dylib',use_errno=True)
        kind,arg=(1,0) if uid is None else (4,int(uid))
        size=library.proc_listpids(kind,arg,None,0)
        if size<=0:raise OSError(ctypes.get_errno(),'kernel process census unavailable')
        buffer=(ctypes.c_int*(size//4+4096))();count=library.proc_listpids(kind,arg,buffer,ctypes.sizeof(buffer))
        if count<=0 or count>=ctypes.sizeof(buffer):raise OSError('incomplete kernel process census')
        return sorted(value for value in buffer[:count//4] if value)
    return sorted(int(p.name) for p in Path('/proc').iterdir() if p.name.isdigit() and (uid is None or p.stat().st_uid==uid))


def same_birth(expected,observed):
    keys=('pid','startSeconds','startMicroseconds') if 'startSeconds' in expected else ('pid','startTicks')
    return observed is not None and all(expected.get(k)==observed.get(k) for k in keys)
