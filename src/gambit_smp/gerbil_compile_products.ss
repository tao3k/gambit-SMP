;;; Included in the existing gxc namespace. The existing invoke function owns
;;; spawning and joining; these helpers only retain completed products.
(def (compile-product-git arguments (input #f))
  (let* ((tool (getenv "GERBIL_GIT"))
         (port (open-process [path: tool arguments: arguments
                             stdout-redirection: #t stderr-redirection: #f])))
    (when input (display input port) (force-output port) (close-output-port port))
    (let ((answer (read-line port)) (status (process-status port)))
      (close-port port)
      (unless (and (zero? status) (string? answer) (= (string-length answer) 40))
        (error "compiler product identity failed" arguments answer status))
      answer)))

(def (compile-product-file path)
  (compile-product-git ["hash-object" "--no-filters" "--" path]))

(def (compile-product-dependencies? dependencies)
  ;; One native hash process for the whole dependency closure, not one process
  ;; per header. Inputs are still checked on every actual reuse.
  (and (andmap (lambda (row) (file-exists? (car row))) dependencies)
       (let* ((port (open-process
                     [path: (getenv "GERBIL_GIT")
                      arguments: (append ["hash-object" "--no-filters" "--"] (map car dependencies))
                      stdout-redirection: #t stderr-redirection: #f]))
              (matches? (let loop ((rest dependencies) (valid? #t))
                          (if (null? rest) valid?
                              (let (value (read-line port))
                                (loop (cdr rest) (and valid? (equal? value (cadar rest))))))))
              (status (process-status port)))
         (close-port port)
         (and (zero? status) matches?))))

(def (compile-product-key datum)
  (compile-product-git ["hash-object" "--stdin"]
                      (call-with-output-string (lambda (p) (write datum p)))))

(def (compile-product-json value port)
  (cond
   ((string? value)
    (write-char #\" port)
    (string-for-each
     (lambda (ch)
       (cond
        ((or (eqv? ch #\") (eqv? ch #\\)) (write-char #\\ port) (write-char ch port))
        ((< (char->integer ch) 32)
         (display "\\u" port)
         (let (hex (number->string (char->integer ch) 16))
           (display (make-string (- 4 (string-length hex)) #\0) port) (display hex port)))
        (else (write-char ch port)))) value)
    (write-char #\" port))
   ((boolean? value) (display (if value "true" "false") port))
   ((integer? value) (write value port))
   ((list? value)
    (write-char #\[ port)
    (let loop ((rest value) (first? #t))
      (unless (null? rest)
        (unless first? (write-char #\, port))
        (compile-product-json (car rest) port) (loop (cdr rest) #f)))
    (write-char #\] port))
   (else (error "unsupported compiler product field" value))))

(def (compile-product-record key suffix value)
  (let* ((path (path-expand (string-append key suffix ".json")
                           (getenv "GERBIL_COMPILE_ATTEMPT")))
         (pending (string-append path ".pending")))
    (call-with-output-file pending (lambda (port) (compile-product-json value port) (newline port)))
    (rename-file pending path)
    (when (equal? suffix ".request")
      (let (snapshot (path-expand (string-append key ".input.scm") (getenv "GERBIL_COMPILE_ATTEMPT")))
        (copy-file (list-ref value 4) snapshot)
        (unless (equal? (compile-product-file snapshot) (list-ref value 5))
          (error "native input snapshot differs from request" snapshot))))
    (when (and (equal? suffix ".completed") (current-compile-product-module))
      (let* ((state (current-compile-product-module))
             (task [key (compile-product-plain-source?
                         (path-expand (string-append key ".input.scm") (getenv "GERBIL_COMPILE_ATTEMPT")) #t)]))
        (with-driver-mutex
          (vector-set! state 2 (cons task (vector-ref state 2))))))))

;;; Unknown macro/foreign directives cannot acquire a reuse credential.
;;; The generated source is reread, using Scheme's reader rather than a Python
;;; imitation. The approved include is bound by the frozen runtime payload.
(def (compile-product-plain-source? path (foreign? #f))
  (def (safe-tree? value)
    (cond
     ((and (pair? value) (memq (car value) '(quote ##quote))) #t)
     ((pair? value)
      (and (not (and (symbol? (car value))
                     (let (name (symbol->string (car value)))
                       (or (and (not foreign?) (or (string-prefix? "c-" name) (string-prefix? "##c-" name)))
                           (member name '("define-macro" "##define-macro" "define-syntax" "##define-syntax"))
                           (member name '("include" "##include"))))))
           (safe-tree? (car value)) (safe-tree? (cdr value))))
     ((vector? value) (andmap safe-tree? (vector->list value)))
     (else #t)))
  (def (safe-top? value)
    (and (pair? value)
         (case (car value)
           ((include ##include)
            (or (equal? (cdr value) '("~~lib/_gambit#.scm"))
                (and foreign? (getenv "GERBIL_BUILD_PREFIX" #f)
                     (equal? (cdr value)
                             (list (path-expand "lib/_gambit#.scm" (getenv "GERBIL_BUILD_PREFIX")))))))
           ((begin ##begin) (andmap safe-top? (cdr value)))
           ((declare ##declare define ##define namespace ##namespace let ##let) (safe-tree? value))
           ((load-module) (and (= (length value) 2) (string? (cadr value))))
           ;; Ordinary initialization is compiled, not evaluated by GSC.
           ;; Other initialization remains outside strict phase memoization.
           (else (and foreign? (safe-tree? value))))))
  (with-catch (lambda (_) #f)
    (lambda ()
      (call-with-input-file path
        (lambda (port)
          (let loop ()
            (let (value (read port))
              (or (eof-object? value) (and (safe-top? value) (loop))))))))))

(def (compile-product-shell-word value)
  (string-append "'" (string-join (string-split value #\') "'\\''") "'"))

(def (compile-product-options? arguments)
  (let loop ((rest (reverse (cdr (reverse arguments)))) (cacheable? #t))
    (cond
     ((null? rest) cacheable?)
     ((member (car rest) '("-debug-source" "-track-scheme")) (loop (cdr rest) cacheable?))
     ((and (pair? (cdr rest))
           (member (car rest) '("-cc-options" "-ld-options" "-e" "-target")))
      (let ((flag (car rest)) (value (cadr rest)))
        (when (and (equal? flag "-target") (not (equal? value "C")))
          (error "compiler product requires the C target" arguments))
        (when (and (equal? flag "-cc-options")
                   (or (string-prefix? "-o" value) (string-contains value " -o")
                       (string-contains value "-MF") (string-contains value "-fplugin")))
          (error "unmanaged compiler output/plugin option" arguments))
        (loop (cddr rest)
              (and cacheable?
                   (cond ((equal? flag "-cc-options") (or (equal? value "-g") (equal? value "")))
                         ((equal? flag "-ld-options") #f)
                         ((equal? flag "-e") (equal? value "(include \"~~lib/_gambit#.scm\")"))
                         (else #t))))))
     (else (error "unsupported compiler product mode" arguments)))))

(def (compile-product-invoke-now program arguments source)
  (if (not (getenv "GERBIL_COMPILE_CONTEXT" #f))
    (invoke program arguments)
    (let* ((context (getenv "GERBIL_COMPILE_CONTEXT"))
         (source (path-normalize source))
         (source-id (compile-product-file source))
         (directory (current-directory))
         (key (compile-product-key [context program arguments directory source source-id]))
         (output (string-append (path-strip-extension source) ".o1"))
         (cache-path (path-expand (string-append key ".scm") (getenv "GERBIL_COMPILE_PRODUCTS")))
         (dep-path (path-expand (string-append key ".d") (getenv "GERBIL_COMPILE_ATTEMPT")))
         (claim (path-expand (string-append "output-" (compile-product-key output) ".claim")
                             (getenv "GERBIL_COMPILE_ATTEMPT")))
         (plain? (and (compile-product-options? arguments) (compile-product-plain-source? source)))
         (cached (and (equal? (getenv "GERBIL_COMPILE_REUSE") "1") plain? (file-exists? cache-path)
                      (call-with-input-file cache-path read))))
    ;; Atomic directory creation reserves one physical output for this whole
    ;; producer attempt, including requests with different argv/source keys.
    (create-directory claim)
    (compile-product-record key ".request" [context program arguments directory source source-id output])
    (if (and cached
             (equal? (list (list-ref cached 0) (list-ref cached 1) (list-ref cached 2) (list-ref cached 3) (list-ref cached 4) (list-ref cached 5) (list-ref cached 6)) [context program arguments directory source source-id output])
             (file-exists? output) (equal? (list-ref cached 7) (compile-product-file output))
             (compile-product-dependencies? (list-ref cached 8)))
      (compile-product-record key ".completed"
        [context program arguments directory source source-id output
         (list-ref cached 7) #t "" "reused"])
      (let (observed-arguments
             (append ["-cc-options" (string-append "-MD -MF " (compile-product-shell-word dep-path))] arguments))
        ;; The original compiler continues to own the process and exit handling.
        ;; Unknown old outputs never stand in for a new successful compiler.
        (when (file-exists? output)
          (rename-file output (path-expand (string-append key ".previous.o1")
                                          (getenv "GERBIL_COMPILE_ATTEMPT"))))
        (invoke program observed-arguments)
        (unless (equal? source-id (compile-product-file source))
          (error "compiler input changed during invocation" source))
        (unless (and (file-exists? output) (file-exists? dep-path))
          (error "compiler completion lacks output/dependencies" source))
        (compile-product-record key ".completed"
          [context program arguments directory source source-id output
           (compile-product-file output) plain?
           (call-with-input-file dep-path (lambda (p) (read-line p #f))) "executed"]))))))

;;; A module program owns all phases, emitted interfaces and native tasks.
;;; Its ready file is issued only by the quiescent Evidence consumer.
(def current-compile-product-module (make-parameter #f))

(def (compile-product-marker source)
  (let* ((source (path-normalize source))
         (root (path-directory (getenv "GERBIL_BUILD_PREFIX")))
         (relative (and (string-prefix? root source)
                        (substring source (string-length root) (string-length source)))))
    (unless relative (error "module source outside owned producer" source root))
    (path-expand (string-append relative ".ready")
                 (path-expand "modules" (getenv "GERBIL_COMPILE_PRODUCTS")))))

(def (compile-product-interface source)
  (let* ((source (path-normalize source)) (marker (compile-product-marker source)))
    (if (file-exists? marker)
      (let (datum (call-with-input-file marker read))
        (unless (and (list? datum) (= (length datum) 5)
                     (equal? (car datum) (getenv "GERBIL_COMPILE_CONTEXT"))
                     (equal? (cadr datum) source) (file-exists? (caddr datum)))
          (error "invalid module completion credential" source marker))
        (caddr datum))
      source)))

;;; The admitted program supplies graph data without importing its SSI or
;;; loading a compiled macro phase. Actual compilation still owns expansion.
(def (compile-product-module-plan source)
  (let* ((source (path-normalize source)) (marker (compile-product-marker source)))
    (and (file-exists? marker)
         (let (datum (call-with-input-file marker read))
           (unless (and (list? datum) (= (length datum) 5)
                        (equal? (car datum) (getenv "GERBIL_COMPILE_CONTEXT"))
                        (equal? (cadr datum) source) (file-exists? (caddr datum))
                        (list? (list-ref datum 4)) (memv (length (list-ref datum 4)) '(2 3))
                        (string? (car (list-ref datum 4)))
                        (list? (cadr (list-ref datum 4)))
                        (andmap string? (cadr (list-ref datum 4))))
             (error "invalid module planning credential" source marker))
           (list-ref datum 4)))))

(def (compile-product-output path)
  (let (state (current-compile-product-module))
    (when state
      (let (path (path-normalize path))
        (unless (member path (vector-ref state 3))
          (vector-set! state 3 (cons path (vector-ref state 3))))))))

(def (compile-product-identities paths)
  (if (null? paths) []
    (let* ((port (open-process [path: (getenv "GERBIL_GIT")
                               arguments: (append ["hash-object" "--no-filters" "--"] paths)
                               stdout-redirection: #t stderr-redirection: #f]))
           (rows (map (lambda (path) [path (read-line port)]) paths))
           (status (process-status port)))
      (close-port port)
      (unless (and (zero? status) (andmap (lambda (row) (and (string? (cadr row)) (= (string-length (cadr row)) 40))) rows))
        (error "module identity snapshot failed" paths status))
      rows)))

(def (compile-product-dependency-files module-id)
  (let* ((base (path-expand module-id (path-expand "lib" (getenv "GERBIL_BUILD_PREFIX"))))
         (directory (path-directory base)) (prefix (path-strip-directory base)))
    (if (file-exists? directory)
      (filter-map
       (lambda (name)
         (let (path (path-expand name directory))
           (and (or (string-prefix? (string-append prefix ".") name)
                    (string-prefix? (string-append prefix "~") name))
                (eq? (file-info-type (file-info path)) 'regular) path)))
       (directory-files directory))
      [])))

(def (compile-product-module-info ctx)
  (let (state (current-compile-product-module))
    (when state
     (let ()
      (def (record-id id)
        (when id
          (let* ((name (symbol->string id)) (index (string-index name #\~))
                 (name (if index (substring name 0 index) name)))
            (unless (member name (vector-ref state 1))
              (vector-set! state 1 (cons name (vector-ref state 1)))))))
      (def (visit value)
        (cond
         ((or (module-context? value) (prelude-context? value)) (record-id (expander-context-id value)))
         ((module-import? value) (visit (module-import-source value)))
         ((module-export? value) (visit (module-export-context value)))
         ((import-set? value) (visit (import-set-source value)))
         (else (error "unknown module dependency" value))))
      (vector-set! state 0 (symbol->string (expander-context-id ctx)))
      (visit (phi-context-super ctx))
      (for-each visit (module-context-import ctx))
      (let (paths [])
        (for-each
         (lambda (id)
           (when (and (string-prefix? "std/" id) (not (equal? id (vector-ref state 0))))
             (let (files (compile-product-dependency-files id))
               (unless (find (lambda (path) (string-suffix? ".ssi" path)) files)
                 (vector-set! state 5 #f))
               (for-each (lambda (path) (unless (member path paths) (set! paths (cons path paths)))) files))))
         (vector-ref state 1))
        (vector-set! state 4 (compile-product-identities paths)))))))

;;; Capture the real semantic graph beside the interface. This is an owned
;;; output of this module program, not an inferred all-phase dependency list.
(def (compile-product-initialization-graph ctx)
  (when (current-compile-product-module)
    (let ((path (compile-output-file ctx #f ".init"))
          (graph (with-driver-mutex (semantic-context-graph ctx))))
      (with-output-to-scheme-file path
        (lambda ()
          (write ["module-initialization" (getenv "GERBIL_COMPILE_CONTEXT")
                  (symbol->string (expander-context-id ctx))
                  graph])
          (newline))))))

(def (compile-product-initialization-context id)
  (let* ((name (symbol->string id))
         (name (if (string-prefix? ":" name)
                 (substring name 1 (string-length name)) name))
         (root (path-directory (getenv "GERBIL_BUILD_PREFIX")))
         (source (path-expand (string-append "src/" name ".ss") root))
         (plan (compile-product-module-plan source)))
    (unless (and plan (= (length plan) 3) (string? (caddr plan)))
      (error "initialization graph has no completed semantic producer" id))
    (let (datum (call-with-input-file (caddr plan) read))
      (unless (and (list? datum) (= (length datum) 4)
                   (equal? (car datum) "module-initialization")
                   (equal? (cadr datum) (getenv "GERBIL_COMPILE_CONTEXT"))
                   (equal? (caddr datum) name))
        (error "initialization graph differs from admitted program" id))
      (semantic-context-restore (cadddr datum)))))


;;; Module generation closes before native jobs can consume its output bundle.
(def (compile-product-generation-close key source before state)
  (when (and (vector-ref state 0) (vector-ref state 5) (vector-ref state 6)
             (null? (vector-ref state 2)) (pair? (vector-ref state 7))
             (equal? before (compile-product-file source))
             (compile-product-dependencies? (vector-ref state 4)))
    (let (outputs
          (map (lambda (path)
                 (let* ((pending (assoc path (vector-ref state 8)))
                        (physical (if pending (cadr pending) path)))
                   [path physical (compile-product-file physical)]))
               (reverse (vector-ref state 3))))
      (compile-product-record key ".module-generated"
        [(getenv "GERBIL_COMPILE_CONTEXT") source before
         (vector-ref state 0) (vector-ref state 1)
         (reverse (vector-ref state 7)) outputs (vector-ref state 4)
         #t (path-normalize (current-directory))]))))

(def (compile-product-generation-restore key source before state)
  (let (marker (string-append (compile-product-marker source) ".generation"))
    (and (file-exists? marker)
      (let (datum (call-with-input-file marker read))
        (unless (and (list? datum) (= (length datum) 10)
                     (equal? (car datum) (getenv "GERBIL_COMPILE_CONTEXT"))
                     (equal? (cadr datum) source) (equal? (caddr datum) before)
                     (eq? (list-ref datum 8) #t)
                     (equal? (list-ref datum 9) (path-normalize (current-directory)))
                     (compile-product-dependencies? (list-ref datum 7)))
          (error "invalid module generation continuation" source marker))
        (vector-set! state 0 (list-ref datum 3))
        (vector-set! state 1 (list-ref datum 4))
        (vector-set! state 4 (list-ref datum 7))
        (vector-set! state 7 (reverse (list-ref datum 5)))
        (for-each
         (lambda (entry)
           (let* ((path (car entry)) (frozen (cadr entry)) (oid (caddr entry))
                  (target (compile-product-output-path path)))
             (unless (equal? oid (compile-product-file frozen))
               (error "module generation snapshot changed" frozen))
             (if (file-exists? target)
               (unless (equal? oid (compile-product-file target))
                 (error "module generation output changed" target))
               (copy-file frozen target))
             (compile-product-output path)))
         (list-ref datum 6))
        (compile-product-record key ".generation-used"
          [(getenv "GERBIL_COMPILE_CONTEXT") source before
           (compile-product-file marker)])
        #t))))
;;; End module generation ownership.

(def (compile-product-module source thunk)
  (if (not (getenv "GERBIL_COMPILE_CONTEXT" #f)) (thunk)
    (let* ((source (path-normalize source))
           (context (getenv "GERBIL_COMPILE_CONTEXT"))
           (before (compile-product-file source))
           (key (compile-product-key [context source]))
           (state (vector #f [] [] [] [] #t #t [] [])))
      (compile-product-record key ".module-request" [context source before])
      (parameterize ((current-compile-product-module state))
        (unless (compile-product-generation-restore key source before state)
          (thunk)
          (compile-product-generation-close key source before state))
        (compile-product-publish state
          (lambda ()
            (unless (and (vector-ref state 0) (equal? before (compile-product-file source))
                         (compile-product-dependencies? (vector-ref state 4)))
              (error "module completion lacks stable source/identity" source)))))
      (compile-product-record key ".module-completed"
        [context source before (vector-ref state 0) (vector-ref state 1)
         (reverse (vector-ref state 2))
         (compile-product-identities (reverse (vector-ref state 3)))
         (vector-ref state 4) (vector-ref state 5)]))))

(def (compile-product-module-used source interface (mode "phase-import"))
  (let* ((source (path-normalize source))
         (datum (call-with-input-file (compile-product-marker source) read))
         (key (list-ref datum 3))
         (path (path-expand (string-append key ".module-used.json") (getenv "GERBIL_COMPILE_ATTEMPT"))))
    (unless (and (equal? (car datum) (getenv "GERBIL_COMPILE_CONTEXT"))
                 (equal? (cadr datum) source) (equal? (caddr datum) interface))
      (error "module use differs from admitted program" source interface))
    (unless (file-exists? path)
      (unless (member mode '("phase-import" "build-metadata"))
        (error "unknown module consumption mode" mode))
      (compile-product-record key ".module-used" [(car datum) source interface mode]))))

;;; Native jobs belong to one module; the original gxc CPU quota is shared.
(def (compile-product-drain state)
  (let ((requests (reverse (vector-ref state 7))) (started []) (failure []))
    (vector-set! state 7 [])
    (def (remember exn) (when (null? failure) (set! failure (list exn))))
    (with-catch remember
      (lambda ()
        (for-each
         (lambda (request)
           (let (job (make-compile-job (lambda () (apply compile-product-invoke-now request))
                                      'module-native))
             (thread-start! job)
             (set! started (cons job started)))) requests)))
    ;; Even a failed start or raised #f cannot abandon already-started jobs.
    (for-each (lambda (job) (with-catch remember (lambda () (join! job))))
              (reverse started))
    (unless (null? failure) (raise (car failure)))))

(def (compile-product-invoke program arguments source)
  (let (state (current-compile-product-module))
    (if (and state (vector-ref state 6))
      (if (and (compile-product-options? arguments)
               (compile-product-plain-source? source))
        (vector-set! state 7 (cons [program arguments source] (vector-ref state 7)))
        (begin
          ;; Unknown compile-time effects retain their synchronous ordering.
          (compile-product-drain state)
          (vector-set! state 6 #f)
          (compile-product-invoke-now program arguments source)))
      (compile-product-invoke-now program arguments source))))

(def (compile-product-output-path path)
  (let (state (current-compile-product-module))
    (if (and state (string-suffix? ".ssi" path))
      (let* ((path (path-normalize path))
             (target (path-expand
                       (string-append "interface-" (compile-product-key path) ".ssi")
                       (getenv "GERBIL_COMPILE_ATTEMPT"))))
        (when (assoc path (vector-ref state 8))
          (error "duplicate module interface output" path))
        (vector-set! state 8 (cons [path target] (vector-ref state 8)))
        target)
      path)))

(def (compile-product-publish state (before-publish void))
  (compile-product-drain state)
  (before-publish)
  ;; All native tasks are joined before the interface becomes importable.
  (for-each (lambda (row) (rename-file (cadr row) (car row)))
            (reverse (vector-ref state 8))))
