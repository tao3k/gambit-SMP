;; Controlled production join path, not original TFIB acceptance.
;; The paired control releases the held thread lock before the same GC request.
(declare (standard-bindings) (extended-bindings) (not interrupts-enabled))
(c-declare #<<end-of-code
#include <stdio.h>
#include <fcntl.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
static unsigned int join_cohort_flags[5];
static char *join_cohort_witness;
end-of-code
)
(define init-witness!
  (c-lambda (int int) bool
    "int fd = open(\"join-cohort.witness\", O_RDWR | O_CREAT | O_EXCL, 0600);
     if (fd < 0) { ___return(0); }
     if (ftruncate(fd, 4096) != 0) { close(fd); ___return(0); }
     join_cohort_witness = mmap(0, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
     close(fd);
     if (join_cohort_witness == MAP_FAILED) { ___return(0); }
     memset(join_cohort_witness, 0, 4096);
     snprintf(join_cohort_witness + 64, 128,
              \"JOIN-COHORT:MODE=%d PROCESSORS=%d\\n\", ___arg1, ___arg2);
     ___return(1);"))
(define publish!
  (c-lambda (int unsigned-int) void
    "__atomic_store_n(&join_cohort_flags[___arg1], ___arg2, __ATOMIC_RELEASE);"))
(define observed
  (c-lambda (int) unsigned-int
    "___return(__atomic_load_n(&join_cohort_flags[___arg1], __ATOMIC_ACQUIRE));"))
(define queued-tickets
  (c-lambda (scheme-object) int
    "___SCMOBJ c1 = __atomic_load_n(&___FIELD(STRUCTURE,___arg1,9), __ATOMIC_ACQUIRE);
     ___SCMOBJ n = __atomic_load_n(&___FIELD(STRUCTURE,___arg1,1), __ATOMIC_ACQUIRE);
     ___SCMOBJ c2 = __atomic_load_n(&___FIELD(STRUCTURE,___arg1,9), __ATOMIC_ACQUIRE);
     ___return(c1 == c2 ? ___INT(n) - ___INT(c1) : -1);"))
(define trace!
  (c-lambda (int) void
    "const char *s = ___arg1 == 0
       ? \"JOIN-COHORT:THREAD-OWNER=0 CONDVAR-OWNER=1 WAITER=2\\n\"
       : ___arg1 == 1 ? \"JOIN-COHORT:GC-REQUEST=1\\n\"
                       : \"JOIN-COHORT:GC-RETURN=1\\n\";
     memcpy(join_cohort_witness + 256 * (___arg1 + 1), s, strlen(s) + 1);
     __atomic_store_n(((unsigned int *)join_cohort_witness) + ___arg1,
                      1, __ATOMIC_RELEASE);"))
(define (participate!)
  (if (##c-code "___RESULT = ___ps->intr_flag[___INTR_SYNC_OP] != ___FIX(0) ? ___TRU : ___FAL;")
      (##sync-op-interrupt!)))
(define (await! index)
  (let loop ()
    (if (= (observed index) 0) (begin (participate!) (loop)))))
(define population (##current-vm-processor-count))
(if (< population 4) (error "four role placements require four available VM processors"))
(define mode (string->number (or (getenv "GAMBIT_SMP_JOIN_COHORT_MODE") "1")))
(if (not (memv mode '(1 2))) (error "unknown cohort mode" mode))
(if (not (init-witness! mode population)) (error "exclusive witness mapping unavailable"))
(define joiner #f)
(define target #f)
(define (role)
  (if (eq? (current-thread) joiner)
      (begin
        (publish! 0 (+ 1 (##current-processor-id)))
        (await! 1)
        (thread-join! target))
      (begin (await! 4) 'target-returned)))
(define first (make-thread role))
(define second (make-thread role))
;; Use the actual lock ordering, not allocation order or a fixed address.
(if (##object-before? first second)
    (begin (set! joiner first) (set! target second))
    (begin (set! joiner second) (set! target first)))
(define contender
  (make-thread
   (lambda ()
     (publish! 2 (+ 1 (##current-processor-id)))
     (thread-join! target))))
;; The end-condvar slot is 20 in the locked enable-smp thread representation.
(define end-condvar (##unchecked-structure-ref target 20 #f #f))
(##thread-migrate-to! 0)
(##thread-pin! joiner (##processor 1))
(##thread-pin! contender (##processor 2))
(##thread-pin! target (##processor 3))
(thread-start! target)
(thread-start! joiner)
(await! 0)
(if (or (not (= (##current-processor-id) 0))
        (not (= (observed 0) 2))
        (not (##object-before? joiner target)))
    (error "role or ordered-lock precondition changed"))
(##primitive-lock! joiner 1 9)
(publish! 1 1)
;; No actor except joiner can own this condvar yet. A successful probe is
;; released immediately; after a failed probe only the joiner can hold it.
(let loop ()
  (if (##primitive-trylock! end-condvar 1 9)
      (begin (##primitive-unlock! end-condvar 1 9) (loop))))
(thread-start! contender)
(await! 2)
(if (not (= (observed 2) 3)) (error "contender placement changed"))
;; A reserved second ticket establishes arrival at the actual raw lock.
;; Ticket counters alone are NOT used to infer its holder.
(let loop () (if (not (= (queued-tickets end-condvar) 2)) (loop)))
(trace! 0)
(if (= mode 1)
    (begin
      (##primitive-unlock! joiner 1 9)
      ;; Both reserved tickets must leave before the control requests GC.
      (let loop ()
        (if (not (= (queued-tickets end-condvar) 0))
            (begin (participate!) (loop))))))
(trace! 1)
(##gc)
(trace! 2)
(if (= mode 2) (##primitive-unlock! joiner 1 9))
(publish! 4 1)
(if (not (equal? (map thread-join! (list target joiner contender))
                 '(target-returned target-returned target-returned)))
    (error "cohort return values changed"))
(display "JOIN-CONDVAR-GC:PASS\n")
