;;; Library ordering from the pinned Gerbil builder, Copyright vyzo.
(def (order-modules all-modules (resolve import-module) (view #f))
  ;; Begin immutable dependency view.
  (let ((expander-context-id (if view (hash-ref view 'expander-context-id) expander-context-id))
        (module-context? (if view (hash-ref view 'module-context?) module-context?))
        (prelude-context? (if view (hash-ref view 'prelude-context?) prelude-context?))
        (module-import? (if view (hash-ref view 'module-import?) module-import?))
        (module-export? (if view (hash-ref view 'module-export?) module-export?))
        (import-set? (if view (hash-ref view 'import-set?) import-set?))
        (core-context-prelude (if view (hash-ref view 'core-context-prelude) core-context-prelude))
        (module-context-import (if view (hash-ref view 'module-context-import) module-context-import))
        (prelude-context-import (if view (hash-ref view 'prelude-context-import) prelude-context-import))
        (module-import-source (if view (hash-ref view 'module-import-source) module-import-source))
        (module-import-phi (if view (hash-ref view 'module-import-phi) module-import-phi))
        (module-export-context (if view (hash-ref view 'module-export-context) module-export-context))
        (import-set-source (if view (hash-ref view 'import-set-source) import-set-source))
        (import-set-phi (if view (hash-ref view 'import-set-phi) import-set-phi)))
  ;; End immutable dependency view.
  (def visited-modules
    (make-hash-table-eq))

  (def (module-id modf)
    (string->symbol (string-append ":" modf)))

  (def (module-file modctx)
    (symbol->string (expander-context-id modctx)))

  (def (module-exclude? modctx)
    (or (not (expander-context-id modctx)) ; root prelude
        (string-prefix? "gerbil/core" (symbol->string (expander-context-id modctx)))))

  (def (import-set-template in phi)
    (let ((iphi (fx+ phi (import-set-phi in)))
          (imports (module-context-import (import-set-source in))))
      (let lp ((rest imports) (r []))
        (match rest
          ([in . rest]
           (cond
            ((module-context? in)
             (if (fxzero? iphi)
               (lp rest (cons in r))
               (lp rest r)))
            ((module-import? in)
             (let (iphi (fx+ phi (module-import-phi in)))
               (if (fxzero? iphi)
                 (lp rest (cons (module-export-context (module-import-source in)) r))
                 (lp rest r))))
            ((import-set? in)
             (let (xphi (fx+ iphi (import-set-phi in)))
               (if (fxzero? xphi)
                 (lp rest (cons (import-set-source in) r))
                 (lp rest r))))
            (else
             (lp rest r))))
          (else r)))))

  (def (find-deps modctx)
    ;; Completion belongs to this context object, not its printed module ID.
    ;; Keep aliases with different contexts distinct until the original final
    ;; ID fold. Issue a completion only after every child has returned: an
    ;; active cycle is neither skipped nor assigned a new initialization order.
    (def completed-contexts (make-hash-table-eq))
    (let lp ((rest [modctx]) (deps []))
      (match rest
        ([hd . rest]
         (cond
          ((module-context? hd)
           (let ((id (expander-context-id hd))
                 (imports (module-context-import hd)))
             (cond
              ((or (hash-get visited-modules id) (module-exclude? hd)
                   (hash-get completed-contexts hd))
               (lp rest deps))
              ((core-context-prelude hd)
               => (lambda (pre)
                    (let (deps (lp (cons pre imports) deps))
                      (hash-put! completed-contexts hd #t)
                      (lp rest (cons hd deps)))))
              (else
               (let (deps (lp imports deps))
                 (hash-put! completed-contexts hd #t)
                 (lp rest (cons hd deps)))))))
          ((prelude-context? hd)
           (let (id (expander-context-id hd))
             (if (or (hash-get visited-modules id) (module-exclude? hd)
                     (hash-get completed-contexts hd))
               (lp rest deps)
               (let (deps (lp (prelude-context-import hd) deps))
                 (hash-put! completed-contexts hd #t)
                 (lp rest (cons hd deps))))))
          ((module-import? hd)
           (if (fxzero? (module-import-phi hd))
             (lp (cons (module-import-source hd) rest) deps)
             (lp rest deps)))
          ((module-export? hd)
           (lp (cons (module-export-context hd) rest) deps))
          ((import-set? hd)
           (cond
            ((fxzero? (import-set-phi hd))
             (lp (cons (import-set-source hd) rest) deps))
            ((fxpositive? (import-set-phi hd))
             (let (xdeps (import-set-template hd 0))
               (lp (foldl cons rest xdeps) deps)))
            (else
             (lp rest deps))))
          (else
           (error "unexpected dependency" hd))))
        (else deps))))

  (let lp ((rest all-modules) (ordered []))
    (match rest
      ([modf . rest]
       (let (mod-id (module-id modf))
         (if (hash-get visited-modules mod-id)
           (lp rest ordered)
           (let* ((modctx (resolve mod-id))
                  (deps (find-deps modctx))
                  (ordered
                   (foldl
                     (lambda (dep r)
                       (if (hash-get visited-modules (expander-context-id dep))
                         r
                         (begin
                           (hash-put! visited-modules (expander-context-id dep) #t)
                           (cons (module-file dep) r))))
                     ordered
                     (reverse deps))))
             (lp rest ordered)))))
      (else
       (reverse ordered))))))
