;; Exercise the internal migration used by the C-return processor hook.
;; No pinning, resize or sleep is used to enforce the requested destination.
(define population (##current-vm-processor-count))
(if (< population 2) (error "requires parallel processors"))
(do ((round 0 (+ round 1))) ((= round population))
  (let ((target (modulo (+ (##current-processor-id) 1) population)))
    (display (list 'migration-enter round 'target target
                   'caller (##current-processor-id)))
    (newline)
    (force-output)
    (##thread-migrate-to! target)
    (if (not (= target (##current-processor-id)))
        (error "migration returned on wrong processor"
               target (##current-processor-id)))
    (##gc)
    (display (list 'migration-return round))
    (newline)
    (force-output)))
(display "NATIVE-OK:thread_migration_target\n")
