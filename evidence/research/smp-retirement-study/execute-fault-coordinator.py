"""Apply a VM-rooted fault coordinator to the existing native experiment."""
from pathlib import Path
import difflib
import hashlib
import json
import os
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.framework import execute, available_processors
from gambit_smp.recipes import tree_identity

ROOT = Path(__file__).resolve().parents[3]
BUILD = ROOT / '.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6'
SOURCE = BUILD / 'source'

COORDINATOR = r'''
;;; Permanent wake faults have native scalar ownership and a traced VM carrier.
;;; VM slot2 was unused in this exact source. It is scanned by mark_vm_scmobj.
(define-prim (##fault-control-record)
  (macro-vm-unused-field2 (macro-current-vm)))

(define-prim (##fault-control-native-phase)
  (##c-code "___RESULT = ___FIX(__atomic_load_n (&___VMSTATE->os.wake_fault_phase, __ATOMIC_ACQUIRE));"))

(define-prim (##wait-fault-observe-unlocked!)
  (##declare (not interrupts-enabled))
  ;; All callers are outside T, P, V and condvar primitive locks.
  (if (##c-code #<<end-of-code
    int expected = 1;
    ___RESULT = __atomic_compare_exchange_n (&___VMSTATE->os.wake_fault_phase,
      &expected, 2, 0, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE) ? ___TRU : ___FAL;
end-of-code
      )
      (let ((record (##fault-control-record)))
        (if (##vector? record)
            (##thread-start! (##vector-ref record 0))
            ;; No invented Scheme context in a partial startup/embedding.
            (##c-code "__atomic_store_n (&___VMSTATE->os.wake_fault_phase, 6, __ATOMIC_RELEASE);")))))

(define-prim (##fault-control-route-exit! code)
  (##declare (not interrupts-enabled))
  (let ((record (##fault-control-record)))
    (if (and (##vector? record) (##fx> (##fault-control-native-phase) 0))
        (begin
          ;; Recursive exit is intent, not a second native unwind. The carrier
          ;; is the sole committer, even when a callback requests another exit.
          (##vector-set! record 6 code)
          #t)
        #f)))

(define-prim (##fault-control-cursor! record slot execute)
  (let loop ()
    (let ((lst (##vector-ref record slot)))
      (if (##pair? lst)
          (let ((item (##car lst)))
            ;; Transfer the suffix before the external call; item and caught
            ;; error are strong roots through every nested collection.
            (##vector-set! record slot (##cdr lst))
            (##vector-set! record 7 item)
            (##with-exception-catcher
             (lambda (exc) (##vector-set! record 5 exc))
             (lambda () (execute item)))
            (##vector-set! record 7 #f)
            (loop))))))

(define-prim (##fault-control-run! record)
  (##declare (not interrupts-enabled))
  (if (##not (##fx= (##current-processor-id) 0))
      (##error "fault coordinator migrated off P0"))
  (if (##not (##c-code #<<end-of-code
    int expected = 2;
    ___RESULT = __atomic_compare_exchange_n (&___VMSTATE->os.wake_fault_phase,
      &expected, 3, 0, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE) ? ___TRU : ___FAL;
end-of-code
        ))
      (##error "fault coordinator claimed twice"))
  (##vector-set! record 1 3)
  (##vector-set! record 2
    (##c-code "___RESULT = ___FIX(__atomic_load_n (&___VMSTATE->os.wake_fault_errno, __ATOMIC_ACQUIRE));"))
  (set! ##cleaning-up? #t)
  (##vector-set! record 3 (macro-fifo-remove-all! ##exit-jobs))
  (##fault-control-cursor! record 3 (lambda (job) (job)))
  (##vector-set! record 4 (macro-fifo-remove-all! ##final-will-registry))
  (##fault-control-cursor! record 4 ##will-execute!)
  (##vector-set! record 1 4)
  (##c-code #<<end-of-code
    __atomic_store_n (&___VMSTATE->os.wake_fault_phase, 4, __ATOMIC_RELEASE);
    fprintf (stderr, "SMP-FAULT coordinator=P0 prepared errno=%d\n",
      __atomic_load_n (&___VMSTATE->os.wake_fault_errno, __ATOMIC_ACQUIRE));
end-of-code
  )
  ;; Native cleanup/join may still retain failure; this is not an invented
  ;; result-mutex reply or evidence that native storage was already released.
  (##exit-with-err-code-no-cleanup (##fx+ (macro-EXIT-CODE-SOFTWARE) 1)))

(define-prim (##fault-control-make!)
  (##declare (not interrupts-enabled))
  (let* ((record (##vector #f 0 0 '() '() #f #f #f))
         (thread (##make-root-thread
                  (lambda () (##fault-control-run! record))
                  'fault-coordinator
                  (macro-thread-tgroup (macro-primordial-thread)))))
    (macro-thread-pinned-set! thread (##processor 0))
    (##vector-set! record 0 thread)
    (macro-vm-unused-field2-set! (macro-current-vm) record)
    (##exit-admission-hook-set!
     (lambda () (##fx> (##fault-control-native-phase) 0)))
    (##exit-coordinator-hook-set! ##fault-control-route-exit!)))

'''

def replace_once(text, old, new):
    assert text.count(old) == 1, old[:100]
    return text.replace(old, new, 1)

def transformed():
    files = {}
    text = (SOURCE / 'include/gambit.h.in').read_text()
    # Correct the retained first-build macro transcription error explicitly.
    # Historical first delta contained a literal '+'; the canonical owned
    # request patch now already includes that correction.
    if '\n+} while (0)' in text:
        text = text.replace('\n+} while (0)', '\n} while (0)', 1)
    anchor = '} ___vmstate_os;'
    text = replace_once(text, anchor, '''  /* Sticky for one VM lifetime; never reset by resize or a good write. */
  volatile int wake_fault_errno;
  volatile int wake_fault_phase; /* healthy/faulted/posted/running/prepared/closed/retained */
  volatile unsigned int wake_writers;
  volatile unsigned int wake_selectors;
''' + anchor)
    files['include/gambit.h.in'] = text
    text = (SOURCE / 'lib/os_io.c').read_text()
    text = replace_once(text, 'static ___SCMOBJ device_select_with_cap\n', 'static ___SCMOBJ device_select_impl\n')
    anchor = '\n\n___SCMOBJ ___device_select\n'
    wrapper = r'''

static ___SCMOBJ device_select_with_cap
   ___P((___device **devs, int nr, int nw, int ne, ___time timeout,
         ___F64 cap, int *reason),
        (devs, nr, nw, ne, timeout, cap, reason)
___device **devs; int nr; int nw; int ne; ___time timeout;
___F64 cap; int *reason;)
{
  ___virtual_machine_state vm = ___VMSTATE_FROM_PSTATE(___PSTATE);
  ___SCMOBJ result;
  __atomic_fetch_add (&vm->os.wake_selectors, 1, __ATOMIC_ACQ_REL);
  result = device_select_impl (devs, nr, nw, ne, timeout, cap, reason);
  __atomic_fetch_sub (&vm->os.wake_selectors, 1, __ATOMIC_RELEASE);
  return result;
}
'''
    text = replace_once(text, anchor, wrapper + anchor)
    old = '  write (___ps->os.select_abort.writing_fd, buf, 1); /* ignore error */'
    new = r'''  ___virtual_machine_state vm = ___VMSTATE_FROM_PSTATE(___ps);
  int n, saved_errno, retry = 0;
  __atomic_fetch_add (&vm->os.wake_writers, 1, __ATOMIC_ACQ_REL);
  if (__atomic_load_n (&vm->os.wake_fault_phase, __ATOMIC_ACQUIRE) >= 5)
    { __atomic_fetch_sub (&vm->os.wake_writers, 1, __ATOMIC_RELEASE); return; }
  do { n = write (___ps->os.select_abort.writing_fd, buf, 1); }
  while (n < 0 && errno == EINTR && ++retry < 4);
  saved_errno = n == 1 ? 0 : (n < 0 ? errno : EIO);
  if (saved_errno != 0 && saved_errno != EAGAIN && saved_errno != EWOULDBLOCK)
    {
      int expected = 0;
      if (__atomic_compare_exchange_n (&vm->os.wake_fault_errno, &expected,
            saved_errno, 0, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE))
        { expected = 0;
          __atomic_compare_exchange_n (&vm->os.wake_fault_phase, &expected,
            1, 0, __ATOMIC_RELEASE, __ATOMIC_RELAXED); }
    }
  __atomic_fetch_sub (&vm->os.wake_writers, 1, __ATOMIC_RELEASE);'''
    text = replace_once(text, old, new)
    start = text.index('___SCMOBJ ___setup_io_vmstate\n')
    body = text.index('{\n', start) + 2
    text = text[:body] + '''  __atomic_store_n (&___vms->os.wake_fault_errno, 0, __ATOMIC_RELAXED);
  __atomic_store_n (&___vms->os.wake_fault_phase, 0, __ATOMIC_RELAXED);
  __atomic_store_n (&___vms->os.wake_writers, 0, __ATOMIC_RELAXED);
  __atomic_store_n (&___vms->os.wake_selectors, 0, __ATOMIC_RELAXED);
''' + text[body:]
    files['lib/os_io.c'] = text
    text = (SOURCE / 'lib/_kernel.scm').read_text()
    text = replace_once(text, '(define ##cleaning-up? #f)', '''(define ##cleaning-up? #f)
(define ##exit-coordinator-hook #f)
(define-prim (##exit-coordinator-hook-set! hook)
  (set! ##exit-coordinator-hook hook))''')
    text = replace_once(text, '''(define-prim (##add-exit-job! thunk)
  (##add-job! ##exit-jobs thunk))''', '''(define ##exit-admission-hook #f)
(define-prim (##exit-admission-hook-set! hook) (set! ##exit-admission-hook hook))
(define-prim (##add-exit-job! thunk)
  (if (and ##exit-admission-hook (##exit-admission-hook))
      (##error "exit callback admission closed after wake fault")
      (##add-job! ##exit-jobs thunk)))''')
    text = replace_once(text, '''  (##exit-cleanup)
  (##exit-with-err-code-no-cleanup err-code))''', '''  (if (and ##exit-coordinator-hook (##exit-coordinator-hook err-code))
      (##void)
      (begin (##exit-cleanup) (##exit-with-err-code-no-cleanup err-code))))''')
    text = replace_once(text, '''  (##exit-with-err-code-no-cleanup (##fx+ status 1)))''', '''  (let ((code (##fx+ status 1)))
    (if (and ##exit-coordinator-hook (##exit-coordinator-hook code))
        (##void)
        (##exit-with-err-code-no-cleanup code))))''')
    files['lib/_kernel.scm'] = text
    text = (SOURCE / 'lib/_thread.scm').read_text()
    start = text.index('(define-prim (##thread-interrupt!\n')
    pos = text.index('  (let ((action', start)
    text = text[:pos] + '''  ;; New public requests are refused before mutex/node ownership transfer.
  ;; Internal GC/collective requests use ##thread-intr! and remain serviceable.
  (if (##fx> (##fault-control-native-phase) 0)
      (##error "thread interrupt admission closed after wake fault"))

''' + text[pos:]
    pos = text.index('(define-prim (##thread-report-scheduler-error! code)')
    text = text[:pos] + COORDINATOR + text[pos:]
    # P-held device helper is deliberately NOT an observer boundary.
    old = '''                     (##wait! #f #t)
                     (##service-interrupts!)'''
    text = replace_once(text, old, old.replace('(##service-interrupts!)', '(##wait-fault-observe-unlocked!)\n                     (##service-interrupts!)'))
    old = '''                       (macro-unlock-current-processor!)

                       (##service-interrupts!)'''
    text = replace_once(text, old, old.replace('(##service-interrupts!)', '(##wait-fault-observe-unlocked!)\n                       (##service-interrupts!)'))
    start = text.index('(define-prim (##thread-heartbeat!)')
    pos = text.index('    (macro-unlock-current-processor!)', start) + len('    (macro-unlock-current-processor!)')
    text = text[:pos] + '\n    (##wait-fault-observe-unlocked!)\n' + text[pos:]
    start = text.index('(define-prim (##other-interrupt!)')
    pos = text.index('  (##thread-intr-drain!)', start)
    text = text[:pos] + '  (##wait-fault-observe-unlocked!)\n' + text[pos:]
    start = text.index('(define-prim (##startup-threading!)')
    end = text.index('(define-prim (##gc-interrupt!)', start)
    part = text[start:end]
    part = replace_once(part, '    (##void)))', '    (##fault-control-make!)\n    (##void)))')
    text = text[:start] + part + text[end:]
    start = text.index('(define-prim (##thread-migrate-to! id)')
    pos = text.index('  ;; Interrupt queue', start)
    text = text[:pos] + '''  (let ((record (##fault-control-record)))
    (if (and (##vector? record)
             (##eq? (macro-current-thread) (##vector-ref record 0))
             (##not (##fx= id 0)))
        (##error "fault coordinator cannot migrate")))
''' + text[pos:]
    files['lib/_thread.scm'] = text
    text = (SOURCE / 'lib/setup.c').read_text()
    start = text.index('___EXP_FUNC(___SCMOBJ,___cleanup_checked)')
    pos = text.index('  ___ps = ___PSTATE;', start)
    text = text[:pos] + '''  /* Raw unwind during fault preparation cannot release rooted suffix/error. */
  if (__atomic_load_n (&___vms->os.wake_fault_errno, __ATOMIC_ACQUIRE) != 0 &&
      __atomic_load_n (&___vms->os.wake_fault_phase, __ATOMIC_ACQUIRE) != 4)
    { cleanup_error = ___FIX(___INVALID_OP_ERR); cleanup_phase = 2;
      return cleanup_error; }

''' + text[pos:]
    pos = text.index('  ___cleanup_pstate (___ps);', start)
    text = text[:pos] + '''  /* Workers have joined; late producers require the existing host lifetime
     contract. Never free a descriptor, selector or VM still in actual use. */
  __atomic_store_n (&___vms->os.wake_fault_phase, 5, __ATOMIC_RELEASE);
  if (__atomic_load_n (&___vms->os.wake_writers, __ATOMIC_ACQUIRE) != 0 ||
      __atomic_load_n (&___vms->os.wake_selectors, __ATOMIC_ACQUIRE) != 0)
    { cleanup_error = ___FIX(___INVALID_OP_ERR); cleanup_phase = 2;
      return cleanup_error; }

''' + text[pos:]
    files['lib/setup.c'] = text
    return files

def main():
    with w.execution_scope(ROOT, 'repair-9-12'):
        out = w.task_output(ROOT, ROOT / '.cache/fault-coordinator-repair')
        out.mkdir(parents=True, exist_ok=True)
        env = dict(os.environ)
        env.update(json.loads((BUILD / 'configure-proof.json').read_text())['commands'][0]['environment'])
        env['GAMBOPT'] = 'p1'  # Same registered core build policy, not a native-test reduction.
        receipt = dict(schema='fault-coordinator-repair.v1', stages=[], nativeAdmitted=False)
        prior = json.loads((ROOT/'.cache/tasks/repair-9-12/runs/61d28a43005e4cc38e7b3ebdf40c6dc1/outputs/owned-request-repair/receipt.json').read_text())
        receipt['priorBuild'] = '61d28a43005e4cc38e7b3ebdf40c6dc1'
        def remaining(name, cap):
            return cap - sum(row['seconds'] for row in prior['stages'] if row['name']==name)
        def save(): (out / 'receipt.json').write_text(json.dumps(receipt, indent=2))
        def run(name, argv, cap):
            meta = {}; rc, log, timed, seconds = execute(argv, SOURCE, cap, env=env, metadata=meta)
            (out / (name + '.log')).write_text(log)
            receipt['stages'].append(dict(name=name, exit=rc, timedOut=timed, seconds=seconds, process=meta))
            save(); print(name, rc, timed, seconds, log[-1200:], flush=True)
            if rc != 0 or timed: raise RuntimeError(name + ' failed')
        with workspace_lease(ROOT, SOURCE, tree_identity(SOURCE)):
            changes = transformed(); delta = out / 'delta'
            patch = ''.join(''.join(difflib.unified_diff((SOURCE/n).read_text().splitlines(keepends=True), s.splitlines(keepends=True), fromfile='a/'+n, tofile='b/'+n)) for n,s in changes.items())
            (ROOT/'evidence/research/smp-retirement-study/fault-coordinator-repair.patch').write_text(patch)
            (out/'fault-coordinator-repair.patch').write_text(patch)
            receipt['sources'] = {}
            for name, text in changes.items():
                before=out/'before'/name;before.parent.mkdir(parents=True,exist_ok=True);before.write_bytes((SOURCE/name).read_bytes())
                target=delta/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(text)
                receipt['sources'][name]=dict(before=hashlib.sha256(before.read_bytes()).hexdigest(),after=hashlib.sha256(target.read_bytes()).hexdigest())
            state=json.loads((BUILD/'source-state.json').read_text());incoming=dict(state['inputs']);incoming.update(tree_identity(delta))
            w.sync_build_source(ROOT,BUILD,delta,inventory=incoming,mutable=state.get('mutable',[]),overlay_files=state.get('overlayFiles',[]));save()
            try:
                run('configured-header',['/bin/sh','./config.status','include/gambit.h'],60)
                run('scheme-generation',['make','-C',str(SOURCE/'lib'),'_kernel.c','_thread.c','_gambit.c'],remaining('thread-generation',120))
                run('native-core',['make','-j'+str(available_processors()),'-C',str(SOURCE/'lib'),'libgambit.a'],remaining('native-core',300))
                run('native-gsi',['make','-j'+str(available_processors()),'-C',str(SOURCE/'gsi'),'gsi'],60)
                receipt['gsiSha256']=hashlib.sha256((SOURCE/'gsi/gsi').read_bytes()).hexdigest();save()
            finally:
                w.checkpoint_build_source(SOURCE,phase='building',faultCoordinatorExperiment=dict(receipt=str(out/'receipt.json'),diagnosticOnly=True,runtimeAdmitted=False))
        print(out,flush=True)

if __name__=='__main__':main()
