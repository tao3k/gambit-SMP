"""Managed same-workspace request ownership repair and targeted native build."""
from pathlib import Path
import hashlib
import json
import os
import sys
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.framework import execute
from gambit_smp.recipes import tree_identity

ROOT = Path(__file__).resolve().parents[3]
BUILD = ROOT / '.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6'
SOURCE = BUILD / 'source'

PROPAGATE = r'''(define-prim (##thread-intr-propagate! interrupt)
  (##declare (not interrupts-enabled))
  ;; Request identity is this vector; target is immutable, unlike mutex-specific.
  (##thread-lock-remove-btq-toq!
   (##vector-ref interrupt 2)
   (lambda (interrupt)
     (let ((thread (##vector-ref interrupt 2)))
       (if (or (macro-terminated-thread-given-initialized? thread)
               (##not (##fx= (##vector-ref interrupt 3) 0)))
           (macro-unlock-thread! thread)
           (begin
             ;; This is the only publisher of the request's intrusive link.
             (##vector-set! interrupt 3 1)
             (let ((tail (macro-thread-interrupts-tail thread)))
               (macro-thread-interrupts-tail-set! thread interrupt)
               (if (##null? tail)
                   (macro-thread-interrupts-head-set! thread interrupt)
                   (##vector-set! tail 0 interrupt)))
             (let ((p (macro-thread-last-processor thread)))
               (##lock-processor-with-sync-participation! p)
               (let ((running? (##eq? thread (macro-processor-current-thread p)))
                     (id (macro-processor-id p)))
                 (macro-unlock-processor! p)
                 (if running?
                     (begin
                       (macro-unlock-thread! thread)
                       ;; A fresh hint has its own link and never carries the
                       ;; result mutex. It repairs the running-to-park race.
                       (##thread-intr-notify! thread id))
                     (begin
                       (macro-add-thread-to-run-queue-of-current-processor-preferably! thread)
                       (macro-unlock-thread! thread)))))))))
   interrupt))

(define-prim (##thread-intr-notify! thread id)
  (##declare (not interrupts-enabled))
  (##raise-high-level-interrupt
   id (##vector '() (lambda (hint) (##thread-intr-wake! thread)))))

(define-prim (##thread-intr-wake! thread)
  (##declare (not interrupts-enabled))
  (##thread-lock-remove-btq-toq!
   thread
   (lambda (thread)
     (if (or (macro-terminated-thread-given-initialized? thread)
             (##null? (macro-thread-interrupts-head thread)))
         (macro-unlock-thread! thread)
         (let ((p (macro-thread-last-processor thread)))
           (##lock-processor-with-sync-participation! p)
           (let ((running? (##eq? thread (macro-processor-current-thread p)))
                 (id (macro-processor-id p)))
             (macro-unlock-processor! p)
             (if running?
                 (begin
                   (macro-unlock-thread! thread)
                   (if (##eq? thread (macro-current-thread))
                       (##thread-intr-drain!)
                       ;; Migration forwards a NEW hint, never a used link.
                       (##thread-intr-notify! thread id)))
                 (begin
                   (macro-add-thread-to-run-queue-of-current-processor-preferably! thread)
                   (macro-unlock-thread! thread)))))))
   thread
   (lambda (thread)
     (and (##not (macro-terminated-thread-given-initialized? thread))
          (##not (##null? (macro-thread-interrupts-head thread)))))))

(define-prim (##thread-intr-execute! interrupt)
  (##declare (not interrupts-enabled))
  (let ((mutex (##vector-ref interrupt 1))
        (completed? #f))
    (let ((outcome
           (##dynamic-wind
            (lambda ()
              (if (##not (##fx= (##vector-ref interrupt 3) 2))
                  (##error "interrupt continuation no longer owns request")))
            (lambda ()
              (let ((outcome
                     (##with-exception-catcher
                      (lambda (exc) (##vector #f exc))
                      (lambda () (##vector #t ((macro-mutex-name mutex)))))))
                (set! completed? #t)
                outcome))
            (lambda ()
              ;; Nonlocal Scheme escape releases the actual owner, not a
              ;; fabricated successful reply. A resumed continuation is denied.
              (if (##not completed?)
                  (begin
                    (##vector-set! interrupt 3 4)
                    (macro-lock-current-thread!)
                    (##btq-abandon! mutex)
                    (macro-unlock-current-thread!)))))))
      ;; Keep outcome/request in mapped Scheme frames through unlock and GC.
      (macro-mutex-specific-set! mutex (##vector-ref outcome 1))
      (##vector-set! interrupt 3 (if (##vector-ref outcome 0) 3 4))
      (macro-mutex-unlock! mutex)
      (if (##not (##vector-ref outcome 0))
          (##raise (##vector-ref outcome 1))))))

(define-prim (##thread-intr-drain!)
  (##declare (not interrupts-enabled))
  (if (macro-current-thread)
      (let loop ()
        (macro-lock-current-thread!)
        (macro-thread-interrupts-remove-from-head!
         interrupt
         (begin
           (if (macro-mutex? (##vector-ref interrupt 1))
               (##vector-set! interrupt 3 2))
           (macro-unlock-current-thread!)
           (let ((x (##vector-ref interrupt 1)))
             (if (##procedure? x) (x interrupt)
                 (##thread-intr-execute! interrupt)))
           (loop))
         (macro-unlock-current-thread!)))))

'''

def transformed():
    result = {}
    text = (SOURCE / 'lib/_thread.scm').read_text()
    # Stale processor hints must not remove an already resumed/parked thread.
    # The predicate is checked under T before any BTQ/TOQ mutation.
    start = text.index('(define-prim (##thread-lock-remove-btq-toq! thread proc arg1)')
    end = text.index(';;; Utilities for locking multiple threads.', start)
    part = text[start:end]
    part = part.replace('(##thread-lock-remove-btq-toq! thread proc arg1)',
                        '(##thread-lock-remove-btq-toq! thread proc arg1 #!optional (should-remove? #f))', 1)
    part = part.replace('    (let ((btq (macro-thread-btq-container thread)))',
                        '    (if (and should-remove? (##not (should-remove? thread)))\n        (macro-unlock-thread! thread)\n        (let ((btq (macro-thread-btq-container thread)))', 1)
    anchor = '\n;;;----------------------------------------------------------------------------'
    boundary = part.index(anchor)
    part = part[:boundary].rstrip() + ')\n\n' + part[boundary:]
    text = text[:start] + part + text[end:]
    old = "(interrupt (##vector '() result-mutex)))"
    assert text.count(old) == 1
    text = text.replace(old, "(interrupt (##vector '() result-mutex thread 0)))", 1)
    old = '(macro-mutex-specific result-mutex)))))'
    assert text.count(old) == 1
    text = text.replace(old, '''(if (##fx= (##vector-ref interrupt 3) 4)
              (##thread-abandoned-mutex-action!)
              (macro-mutex-specific result-mutex))))))''', 1)
    start = text.index('(define-prim (##thread-intr-propagate! interrupt)')
    end = text.index('(define-prim (##other-interrupt!)', start)
    text = text[:start] + PROPAGATE + text[end:]
    start = text.index('(define-prim (##other-interrupt!)')
    end = text.index(';;TODO:deprecated', start)
    text = text[:start] + '''(define-prim (##other-interrupt!)
  (##declare (not interrupts-enabled))
  (##thread-intr-drain!)
  (let loop ()
    (let ((hint (##get-next-high-level-interrupt)))
      (if (##not (##null? hint))
          (begin
            (let ((proc (##vector-ref hint 1)))
              (if (##procedure? proc) (proc hint)
                  (##error "thread request entered processor hint queue")))
            (loop))))))

''' + text[end:]
    start = text.index('  (let ((resume-thunk', text.index('(define-prim (##thread-resume-execution!)'))
    end = text.index(';;; The procedure ##thread-schedule!', start)
    text = text[:start] + '''  (let ((resume-thunk (macro-thread-resume-thunk (macro-current-thread))))
    (##thread-intr-drain!)
    (resume-thunk)))

''' + text[end:]
    result['lib/_thread.scm'] = text
    text = (SOURCE / 'lib/setup.c').read_text()
    old = '''      if ((err = probe->execute_fn (___CAST(void*, probe), ___TRU))
          != ___FIX(___NO_ERR))
        break;'''
    assert old in text
    text = text.replace(old, old.replace('break;', 'return err; /* mutex is already released; suffix remains owned */'), 1)
    start = text.index('  ___SCMOBJ marker;', text.index('___EXP_FUNC(___SCMOBJ,___run)'))
    end = text.index('\n\n#ifdef ___USE_UNWIND_C_STACK_TO_TRAMPOLINE', start)
    part = text[start:end]
    assert part.count('___kill_sfun_stack_marker (marker);') == 1
    part = part.replace('___SCMOBJ marker;', '___SCMOBJ marker;\n  volatile ___SCMOBJ live_marker = ___FAL;')
    part = part.replace('      ___err = ___call', '      live_marker = marker;\n      ___err = ___call')
    part = part.replace('      ___kill_sfun_stack_marker (marker);\n', '')
    part = part.replace('  ___END_TRY\n', '  ___END_TRY\n\n  if (live_marker != ___FAL)\n    ___kill_sfun_stack_marker (live_marker);\n')
    text = text[:start] + part + text[end:]
    result['lib/setup.c'] = text
    text = (SOURCE / 'include/gambit.h.in').read_text()
    old = '''  while (*___CAST(___VOLATILE ___WORD*,&current) != ___ticket) \\
    ___CPU_RELAX(); \\
} while (0)'''
    assert text.count(old) == 1
    text = text.replace(old, old.replace('} while (0)', '  ___SHARED_MEMORY_BARRIER(); /* acquire after ticket grant */ \\\n} while (0)'))
    result['include/gambit.h.in'] = text
    return result

def main():
    prior_path = Path(sys.argv[1]).resolve() if len(sys.argv) == 2 else None
    prior = json.loads(prior_path.read_text()) if prior_path else None
    with w.execution_scope(ROOT, 'repair-9-12'):
        out = w.task_output(ROOT, ROOT / '.cache/owned-request-repair')
        out.mkdir(parents=True, exist_ok=True)
        env = dict(os.environ)
        env.update(json.loads((BUILD / 'configure-proof.json').read_text())['commands'][0]['environment'])
        # Original core_command/build_capacity exports this command-line make
        # variable. Omitting it makes the old bootstrap compiler hang at startup.
        env['GAMBOPT'] = 'p1'
        receipt = dict(schema='owned-request-repair.v1', stages=[], nativeAdmitted=False,
                       prior=str(prior_path) if prior_path else None, compilerRuntimeOptions='p1')
        def save(): (out / 'receipt.json').write_text(json.dumps(receipt, indent=2))
        def run(name, argv, cap, cwd=SOURCE):
            meta = {}
            rc, log, timed, seconds = execute(argv, cwd, cap, env=env, metadata=meta)
            (out / (name + '.log')).write_text(log)
            receipt['stages'].append(dict(name=name, exit=rc, timedOut=timed, seconds=seconds, process=meta))
            save(); print(name, rc, timed, seconds, log[-900:], flush=True)
            if rc != 0 or timed: raise RuntimeError(name + ' failed')
        with workspace_lease(ROOT, SOURCE, tree_identity(SOURCE)):
            delta = out / 'delta'
            changes = transformed() if prior is None else {}
            if prior:
                assert prior['stages'][-1]['name'] == 'thread-generation'
                assert prior['stages'][-1]['timedOut']
                for name, identity in prior['sources'].items():
                    assert hashlib.sha256((SOURCE/name).read_bytes()).hexdigest() == identity['after']
                receipt['sources'] = prior['sources']
            import difflib
            patch = ''.join(''.join(difflib.unified_diff(
                (SOURCE / name).read_text().splitlines(keepends=True),
                text.splitlines(keepends=True), fromfile='a/' + name,
                tofile='b/' + name)) for name, text in changes.items())
            if changes:
                (out / 'owned-request-repair.patch').write_text(patch)
                (ROOT / 'evidence/research/smp-retirement-study/owned-request-repair.patch').write_text(patch)
                receipt['sources'] = {}
            for name, text in changes.items():
                original = SOURCE / name
                before = out / 'before' / name; before.parent.mkdir(parents=True, exist_ok=True)
                before.write_bytes(original.read_bytes())
                target = delta / name; target.parent.mkdir(parents=True, exist_ok=True); target.write_text(text)
                receipt['sources'][name] = dict(before=hashlib.sha256(original.read_bytes()).hexdigest(), after=hashlib.sha256(target.read_bytes()).hexdigest())
            if changes:
                state = json.loads((BUILD / 'source-state.json').read_text())
                incoming = dict(state['inputs']); incoming.update(tree_identity(delta))
                w.sync_build_source(ROOT, BUILD, delta, inventory=incoming, mutable=state.get('mutable', []), overlay_files=state.get('overlayFiles', []))
            save()
            try:
                if not prior:
                    run('configured-header', ['/bin/sh', './config.status', 'include/gambit.h'], 60)
                run('thread-generation', ['make', '-C', str(SOURCE / 'lib'), '_thread.c', '_gambit.c'], 120)
                run('native-core', ['make', '-j4', '-C', str(SOURCE / 'lib'), 'libgambit.a'], 300)
                run('native-gsi', ['make', '-j4', '-C', str(SOURCE / 'gsi'), 'gsi'], 60)
                receipt['gsiSha256'] = hashlib.sha256((SOURCE / 'gsi/gsi').read_bytes()).hexdigest(); save()
            finally:
                w.checkpoint_build_source(SOURCE, phase='building', ownedRequestExperiment=dict(receipt=str(out / 'receipt.json'), diagnosticOnly=True, runtimeAdmitted=False))
        print(out, flush=True)

if __name__ == '__main__': main()
