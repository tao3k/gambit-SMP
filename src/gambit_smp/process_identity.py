"""Kernel process identity, without spawning a second process to identify one."""
import ctypes
import errno
import os
from pathlib import Path
import sys



class CensusChanged(ValueError):
    """A session changed inside a non-atomic sample; no sample is admitted."""
    def __init__(self, pid, previous_session, current_session):
        self.observation = dict(pid=pid, previousSession=previous_session,
                                currentSession=current_session)
        super().__init__('resource census changed: '+str(self.observation))


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
                    name=bytes(info.comm).decode(errors='replace'),status=info.status,
                    method='proc_pidinfo-PROC_PIDTBSDINFO')
    try:
        text=Path(f'/proc/{pid}/stat').read_text();fields=text[text.rindex(')')+2:].split()
        ticks=int(fields[19]);hz=os.sysconf('SC_CLK_TCK')
        boot=int(next(line.split()[1] for line in Path('/proc/stat').read_text().splitlines() if line.startswith('btime ')))
        return dict(pid=int(pid),ppid=int(fields[1]),pgid=int(fields[2]),uid=Path(f'/proc/{pid}').stat().st_uid,
                    startTicks=ticks,startSeconds=boot+ticks//hz,startMicroseconds=(ticks%hz)*1000000//hz,method='proc-stat-starttime')
    except FileNotFoundError:return None


def pids(uid=None,*,pgid=None):
    if uid is not None and pgid is not None:raise ValueError('choose UID or process-group census')
    if sys.platform=='darwin':
        library=ctypes.CDLL('/usr/lib/libproc.dylib',use_errno=True)
        # SDK sys/proc_info.h: PROC_PGRP_ONLY=2, PROC_UID_ONLY=4.
        kind,arg=(2,int(pgid)) if pgid is not None else ((1,0) if uid is None else (4,int(uid)))
        ctypes.set_errno(0)
        size=library.proc_listpids(kind,arg,None,0)
        if size==0 and pgid is not None and ctypes.get_errno() in (0,errno.ESRCH):return []
        if size<=0:raise OSError(ctypes.get_errno(),'kernel process census unavailable')
        ctypes.set_errno(0)
        buffer=(ctypes.c_int*(size//4+4096))();count=library.proc_listpids(kind,arg,buffer,ctypes.sizeof(buffer))
        if count==0 and pgid is not None and ctypes.get_errno() in (0,errno.ESRCH):return []
        if count<=0 or count>=ctypes.sizeof(buffer):raise OSError('incomplete kernel process census')
        return sorted(value for value in buffer[:count//4] if value)
    result=sorted(int(p.name) for p in Path('/proc').iterdir() if p.name.isdigit() and (uid is None or p.stat().st_uid==uid))
    if pgid is not None:result=[pid for pid in result if (info:=process(pid)) and info['pgid']==pgid]
    return result


def same_birth(expected,observed):
    keys=('pid','startSeconds','startMicroseconds') if 'startSeconds' in expected else ('pid','startTicks')
    return observed is not None and all(expected.get(k)==observed.get(k) for k in keys)


class TaskInfo(ctypes.Structure):
    # Local macOS SDK sys/proc_info.h: PROC_PIDTASKINFO (4), proc_taskinfo.
    _fields_=[(name,ctypes.c_uint64) for name in (
        'virtual_size','resident_size','total_user','total_system','threads_user','threads_system')]+[
        (name,ctypes.c_int32) for name in (
        'policy','faults','pageins','cow_faults','messages_sent','messages_received',
        'syscalls_mach','syscalls_unix','csw','threadnum','numrunning','priority')]


class RusageInfoV0(ctypes.Structure):
    # SDK sys/resource.h rusage_info_v0. V0 includes the footprint ledger;
    # do not guess a newer structure or interpret RSS as this ledger.
    _fields_=[('uuid',ctypes.c_uint8*16)]+[(name,ctypes.c_uint64) for name in (
        'user_time','system_time','pkg_idle_wkups','interrupt_wkups','pageins',
        'wired_size','resident_size','phys_footprint','proc_start_abstime','proc_exit_abstime')]


class RusageInfoV4(ctypes.Structure):
    # SDK sys/resource.h: two child CPU counters and 22 other counters
    # follow the V0 prefix before ri_runnable_time.
    _fields_ = [('v0', RusageInfoV0), ('child_user_time', ctypes.c_uint64),
                ('child_system_time', ctypes.c_uint64), ('unused_v4_counters', ctypes.c_uint64 * 22),
                ('runnable_time', ctypes.c_uint64)]


def group_cpu_snapshot(owner):
    """Cumulative CPU of sampled group members, excluding already reaped children."""
    if sys.platform != 'darwin':
        raise ValueError('Darwin process CPU accounting required')
    pgid = owner['pid']
    leader = process(pgid)
    if not same_birth(owner, leader) or leader['pgid'] != pgid:
        raise ValueError('process group owner changed')
    timebase = (ctypes.c_uint32 * 2)()
    if ctypes.CDLL(None).mach_timebase_info(ctypes.byref(timebase)) or not all(timebase):
        raise ValueError('Mach timebase unavailable')
    library = ctypes.CDLL('/usr/lib/libproc.dylib', use_errno=True)
    rusage = library.proc_pid_rusage
    rusage.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_void_p]
    rusage.restype = ctypes.c_int
    members, unavailable = [], []
    for pid in pids(pgid=pgid):
        identity = process(pid)
        if identity is None or identity['pgid'] != pgid:
            unavailable.append(pid)
            continue
        usage = RusageInfoV4()
        if rusage(pid, 4, ctypes.byref(usage)) == 0:
            sample = dict(userMachTicks=int(usage.v0.user_time),
                          systemMachTicks=int(usage.v0.system_time),
                          accountedRunnableMachTicks=int(usage.runnable_time),
                          childUserMachTicks=int(usage.child_user_time),
                          childSystemMachTicks=int(usage.child_system_time),
                          timeSource='RUSAGE_INFO_V4')
        else:
            info = TaskInfo()
            size = ctypes.sizeof(info)
            count = library.proc_pidinfo(pid, 4, 0, ctypes.byref(info), size)
            sample = dict(userMachTicks=int(info.total_user), systemMachTicks=int(info.total_system),
                          timeSource='PROC_PIDTASKINFO') if count == size else None
        current = process(pid)
        if sample is None or not same_birth(identity, current) or current['pgid'] != pgid:
            unavailable.append(pid)
            continue
        members.append(dict(process=identity, **sample))
    leader = process(pgid)
    if not same_birth(owner, leader) or leader['pgid'] != pgid:
        raise ValueError('process group owner changed')
    ticks = sum(row['userMachTicks'] + row['systemMachTicks'] for row in members)
    return dict(pgid=pgid, members=members, unavailablePids=unavailable,
                machTimebaseNumerator=timebase[0], machTimebaseDenominator=timebase[1],
                cpuLowerBoundSeconds=ticks * timebase[0] / timebase[1] / 1_000_000_000)


def footprint_bytes(identity):
    """Darwin's per-task dirty-memory ledger, not unique machine RAM usage.

    The kernel includes charged compressed memory. A missing live observation
    refuses admission; it is never replaced with RSS, zero or a Linux metric.
    """
    if sys.platform!='darwin':raise ValueError('Darwin footprint accounting required')
    if identity.get('status')==5:return 0
    library=ctypes.CDLL('/usr/lib/libproc.dylib',use_errno=True)
    function=library.proc_pid_rusage
    function.argtypes=[ctypes.c_int,ctypes.c_int,ctypes.c_void_p]
    function.restype=ctypes.c_int
    info=RusageInfoV0()
    if function(identity['pid'],0,ctypes.byref(info)):
        if process(identity['pid']) is None:return None
        raise OSError(ctypes.get_errno(),'live process footprint unavailable')
    return int(info.phys_footprint) if same_birth(identity,process(identity['pid'])) else None


def resident_bytes(identity):
    """RSS belongs to one kernel birth; missing data never means zero live RSS."""
    pid=identity['pid']
    if sys.platform=='darwin':
        if identity.get('status')==5:return 0  # SDK SZOMB: no live address space.
        library=ctypes.CDLL('/usr/lib/libproc.dylib',use_errno=True);info=TaskInfo()
        count=library.proc_pidinfo(pid,4,0,ctypes.byref(info),ctypes.sizeof(info))
        if count!=ctypes.sizeof(info):
            if process(pid) is None:return None
            raise OSError(ctypes.get_errno(),'live process RSS unavailable')
        value=int(info.resident_size)
    else:
        try:value=int(Path(f'/proc/{pid}/statm').read_text().split()[1])*os.sysconf('SC_PAGE_SIZE')
        except FileNotFoundError:return None
    return value if same_birth(identity,process(pid)) else None


def group_memory(pgid):
    """Sample the owned process group, including orphan members; not an OS hard cap.

    Shared resident pages may be counted more than once. Birth changes are
    excluded, unavailable live observations fail closed, and short-lived peaks
    between samples are not claimed as measured.
    """
    result=groups_memory({pgid})
    return dict(pgid=pgid,rssBytes=result['rssBytes'],members=result['members'])


def groups_memory(groups, *, footprint=False, sessions=None):
    """Kernel group-filtered census; each PID is charged once.

    An unrelated protected desktop process is not an owned resource input.
    Unreadable members of the selected groups still fail closed.
    """
    sessions=sessions or {}
    members=[]
    selected=set().union(*(set(pids(pgid=group)) for group in groups)) if sys.platform=='darwin' else set(pids(os.getuid()))
    session_members={}
    if sessions:
        for pid in pids(os.getuid()):
            try:sid=os.getsid(pid)
            except ProcessLookupError:continue
            if sid in sessions:
                selected.add(pid);session_members[pid]=sid
    for pid in sorted(selected):
        info=process(pid)
        if info is None or (info['pgid'] not in groups and pid not in session_members):continue
        rss=resident_bytes(info)
        if rss is not None:
            row=dict(process=info,rssBytes=rss)
            if pid in session_members:
                sid=session_members[pid]
                try:
                    current_sid=os.getsid(pid)
                    if current_sid!=sid:raise CensusChanged(pid,sid,current_sid)
                except ProcessLookupError:continue
                row.update(sessionId=sid,sessionOwnerBirth=sessions[sid])
            if footprint:
                charged=footprint_bytes(info)
                if charged is None:continue
                row['footprintBytes']=charged
            members.append(row)
    result=dict(pgids=sorted(groups),rssBytes=sum(row['rssBytes'] for row in members),members=members,
                metric='sum-process-rss', sharedPagesDeduplicated=False,
                atomicSnapshot=False, physicalMemoryQuotaEquivalent=False)
    if sessions:result.update(sessionIds=sorted(sessions),scope='registered groups and birth-anchored POSIX sessions',
                              detachedSessionsCovered=False)
    if footprint:
        result.update(footprintBytes=sum(row['footprintBytes'] for row in members),
                      footprintMetric='sum-darwin-phys-footprint')
    return result
