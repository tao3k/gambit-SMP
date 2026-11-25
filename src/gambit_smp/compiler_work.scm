;;; Source-instantiated diagnostic bodies, never a substitute implementation.
;;; Read the selected source forms and insert counters at checked syntax sites.
;;; Instrumented bodies alter execution cost; they do not qualify native performance.
(define f6-work-names
  '#("sourcify-calls" "sourcify-analyze" "sourcify-convert"
     "sourcify-visit" "sourcify-first-graph-node" "sourcify-pair"
     "sourcify-vector" "sourcify-box" "env-lookup-calls" "env-frames"
     "env-macro-comparisons" "env-macro-hits" "env-index-probes"
     "env-lexical-comparisons" "env-parent-hops" "env-namespace-entries"
     "env-alias-probes" "env-alias-misses" "env-alias-hits"
     "env-variable-hits" "env-lookup-misses" "sourcify-list"
     "env-macro-cache-probes" "env-macro-index-build-items"
     "env-macro-index-probes" "env-macro-index-insertions" "env-macro-index-builds"))
(define f6-work-counts (make-vector (vector-length f6-work-names) 0))
(define f6-work-publishing? #f)
(define f6-work-total-events 0)
(define f6-work-last-tick (f6-observe-now))
(define (##f6-work-snapshot)
  (if (not f6-work-publishing?)
      (begin
        (set! f6-work-publishing? #t)
        (let loop ((i 0))
          (if (< i (vector-length f6-work-names))
              (begin
                (f6-observe-record "frontend-work" "count"
                  (vector-ref f6-work-counts i) 0 (vector-ref f6-work-names i))
                (loop (+ i 1)))))
        (set! f6-work-publishing? #f))))
(define (##f6-work-add! i)
  (let ((n (+ (vector-ref f6-work-counts i) 1)))
    (vector-set! f6-work-counts i n)
    ;; Check time sparsely; publish at most once per second between boundaries.
    (set! f6-work-total-events (+ f6-work-total-events 1))
    (if (= (modulo f6-work-total-events 1024) 0)
        (let ((now (f6-observe-now)))
          (if (>= (- now f6-work-last-tick) f6-observe-frequency)
              (begin (set! f6-work-last-tick now) (##f6-work-snapshot)))))))
(define (##f6-work-alias-result result)
  (##f6-work-add! 16)
  (##f6-work-add! (if result 18 17))
  result)

;;; Weak keys and scalar-only rows do not extend the observed lists' lifetime.
;;; A row is #(id build-starts last-cache first-cell-build last-cell-build).
(define f6-macro-objects (make-table 'test: eq? 'weak-keys: #t))
(define f6-macro-next-id 0)
(define f6-macro-next-build 0)
(define f6-macro-empty-row (vector 0 0 0 0 0))
(define (##f6-macro-row object)
  (if (null? object) f6-macro-empty-row
      (or (table-ref f6-macro-objects object #f)
          (let ((row (vector (+ f6-macro-next-id 1) 0 0 0 0)))
            (set! f6-macro-next-id (+ f6-macro-next-id 1))
            (table-set! f6-macro-objects object row)
            row))))
;;; Context: head-row, cache-id, build-id, prior-starts, previous-cache,
;;; total, shared, novel, first-shared-id, first-shared-owner, prefix,
;;; owner-mismatches, within-build-revisits. It holds no source object.
(define (##f6-macro-context macros)
  (vector (##f6-macro-row macros) 0 0 0 0 0 0 0 0 0 0 0 0))
(define (##f6-macro-cache-result context cache result)
  (vector-set! context 1 (vector-ref (##f6-macro-row cache) 0))
  result)
(define (##f6-macro-start! context)
  (let* ((head (vector-ref context 0)) (prior (vector-ref head 1)))
    (set! f6-macro-next-build (+ f6-macro-next-build 1))
    (vector-set! context 2 f6-macro-next-build)
    (vector-set! context 3 prior)
    (vector-set! context 4 (vector-ref head 2))
    (vector-set! head 1 (+ prior 1))
    (vector-set! head 2 (vector-ref context 1))
    (f6-observe-record "macro-cache" "build" (vector-ref head 0)
                       f6-macro-next-build "macro-list-table")
    (f6-observe-record "macro-cache" "cache-root" f6-macro-next-build
                       (vector-ref context 1) "macro-list-table")
    (f6-observe-record "macro-cache" "prior-builds" f6-macro-next-build
                       prior "macro-list-table")
    (f6-observe-record "macro-cache" "previous-cache" f6-macro-next-build
                       (vector-ref context 4) "macro-list-table")))
(define (##f6-macro-cell! context cell)
  (let* ((row (##f6-macro-row cell))
         (build (vector-ref context 2))
         (previous (vector-ref row 4))
         (offset (vector-ref context 5)))
    (vector-set! context 5 (+ offset 1))
    (cond ((= previous build)
           (vector-set! context 12 (+ (vector-ref context 12) 1)))
          ((= previous 0)
           (vector-set! context 7 (+ (vector-ref context 7) 1))
           (vector-set! row 3 build))
          (else
           (vector-set! context 6 (+ (vector-ref context 6) 1))
           (if (= (vector-ref context 8) 0)
               (begin
                 (vector-set! context 8 (vector-ref row 0))
                 (vector-set! context 9 previous)
                 (vector-set! context 10 offset)))
           (if (not (= previous (vector-ref context 9)))
               (vector-set! context 11 (+ (vector-ref context 11) 1)))))
    (vector-set! row 4 build)))
(define (##f6-macro-finish context result)
  (let ((build (vector-ref context 2)))
    (for-each
     (lambda (entry)
       (f6-observe-record "macro-cache" (car entry) build
         (vector-ref context (cdr entry)) "macro-list-table"))
     '(("build-cells" . 5) ("shared-cells" . 6) ("novel-cells" . 7)
       ("shared-tail" . 8) ("tail-owner" . 9) ("prefix-cells" . 10)
       ("owner-mismatches" . 11) ("within-build-revisits" . 12)))
    (f6-observe-record "macro-cache" "published" build 1 "macro-list-table"))
  result)
(define (##f6-macro-generation! old new)
  (f6-observe-record "macro-cache"
    (cond ((eq? old new) "generation-same")
          ((and (pair? new) (eq? (cdr new) old)) "generation-prepend")
          (else "generation-switch"))
    (vector-ref (##f6-macro-row old) 0)
    (vector-ref (##f6-macro-row new) 0) "env-macros-set")
  (if (and (pair? new) (pair? (car new)) (symbol? (caar new)))
      (let ((name (object->string (caar new))))
        (if (and (<= (string-length name) 512)
                 (let safe ((i 0))
                   (or (= i (string-length name))
                       (and (not (memv (string-ref name i) '(#\newline #\tab)))
                            (safe (+ i 1))))))
            (f6-observe-record "macro-cache" "generation-name"
              (vector-ref (##f6-macro-row new) 0) 0 name)))))

(define (f6-work-read path wanted . optional)
  (call-with-input-file path
    (lambda (port)
      (let loop ((found '()))
        (if (let check ((xs wanted))
              (or (null? xs) (and (assq (car xs) found) (check (cdr xs)))))
            (reverse found)
            (let ((form (read port)))
              (if (eof-object? form)
                  (error "diagnostic source definitions missing" path wanted)
                  (if (and (pair? form) (memq (car form) '(define ##define-macro))
                           (memq (if (pair? (cadr form)) (caadr form) (cadr form))
                                 (append wanted (if (pair? optional) (car optional) '()))))
                      (let ((name (if (pair? (cadr form)) (caadr form) (cadr form))))
                       (if (assq name found)
                          (error "duplicate diagnostic source definition" path)
                          (loop (cons (cons name form) found))))
                      (loop found)))))))))

(define (f6-work-instrument form top)
  (let ((matched '()))
    (define (hit key)
      (let ((entry (assq key matched)))
        (if entry (set-cdr! entry (+ (cdr entry) 1))
            (set! matched (cons (cons key 1) matched)))))
    (define (counted i node)
      (hit i)
      (list 'begin (list '##f6-work-add! i) node))
    (define (walk node)
      (cond
       ((not (pair? node)) node)
       ((memq (car node) '(quote quasiquote)) node)
       ((and (eq? (car node) 'define) (pair? (cadr node)))
        (let* ((name (caadr node))
               (index (cond
                 ((eq? top '##sourcify-deep)
                  (cond ((eq? name '##sourcify-deep) 0)
                        ((eq? name 'analyze) 1) ((eq? name 'sourcify-deep) 2)
                        ((eq? name 'visit) 3) ((eq? name 'sourcify-deep-pair) 5)
                        ((eq? name 'sourcify-deep-vector) 6)
                        ((eq? name 'sourcify-deep-box) 7)
                        ((eq? name 'sourcify-deep-list) 21) (else #f)))
                 ((eq? name 'env-lookup) 8)
                 ((and (eq? top 'env-lookup) (eq? name 'search*)) 9)
                 (else #f)))
               (body (map walk (cddr node))))
          ;; Local definitions must stay before expressions in Scheme bodies.
          ;; Inject at the last expression via a begin, without moving defines.
          (if index
              (let inject ((xs body))
                (if (null? (cdr xs))
                    (list 'define (cadr node)
                          (counted index (car xs)))
                    (let ((tail (inject (cdr xs))))
                      (cons 'define (cons (cadr node)
                        (cons (car xs) (cddr tail)))))))
              (cons 'define (cons (cadr node)
                (cond
                 ((eq? name 'macro-list-table)
                  (list (list 'let
                    '((##f6-macro-context (##f6-macro-context macros)))
                    (cons 'begin body))))
                 ((eq? name 'env-macros-set)
                  (hit 'generation)
                  (cons '(##f6-macro-generation! (env-macros-ref env) macro) body))
                 (else body)))))))
       ((equal? node '(##table-set! visited obj children-being-visited))
        (counted 4 node))
       ((and (eq? top 'env-lookup) (equal? node '(eq? (car m) name)))
        (counted 10 node))
       ((and (eq? top 'env-lookup) (equal? node '(proc env name (cdr m))))
        (counted 11 node))
       ((and (eq? top 'env-lookup) (equal? node '(proc env name hit)))
        (counted 11 node))
       ((and (eq? top 'env-lookup)
             (or (equal? node '(table-ref (macro-list-table macros) name macro-index-miss))
                 (equal? node '(macro-list-ref (macro-list-table macros) name))))
        (counted 24 node))
       ((and (eq? top 'macro-list-table) (equal? node '(table-ref macro-list-index macros #f)))
        (counted 22 (list '##f6-macro-cache-result '##f6-macro-context 'macro-list-index node)))
       ((and (eq? top 'macro-list-table) (eq? (car node) 'let)
             (equal? (cadr node) '((index (make-table 'test: eq?))))
             (eq? (car (reverse (cddr node))) 'index))
        (hit 'publish)
        (cons 'let (cons (map walk (cadr node))
          (append (map walk (reverse (cdr (reverse (cddr node)))))
                  '((##f6-macro-finish ##f6-macro-context index))))))
       ((and (eq? top 'macro-list-table) (equal? node '(caar lst)))
        (counted 23 (list 'begin '(##f6-macro-cell! ##f6-macro-context lst) node)))
       ((and (eq? top 'macro-list-table) (equal? node '(make-table 'test: eq?)))
        (counted 26 (list 'begin '(##f6-macro-start! ##f6-macro-context) node)))
       ((and (eq? top 'macro-list-table) (equal? node '(table-set! index name (cdar lst))))
        (counted 25 node))
       ((and (eq? top 'env-lookup) (equal? node '(proc env name var)))
        (counted 19 node))
       ((and (eq? top 'env-lookup) (equal? node '(proc env name #f)))
        (counted 20 node))
       ((and (eq? top 'env-lookup) (equal? node '(search parent name full?)))
        (counted 14 node))
       ((and (eq? top 'env-frame-lookup-var) (equal? node '(table-ref index name #f)))
        (counted 12 node))
       ((and (eq? top 'env-frame-lookup-var) (equal? node '(eq? (var-name var) name)))
        (counted 13 node))
       ((and (eq? top 'env-namespace-lookup-both) (equal? node '(car lst)))
        (counted 15 node))
       ((and (eq? top 'env-namespace-lookup-both) (equal? node '(assq name aliases)))
        (hit 16) (list '##f6-work-alias-result node))
       (else (cons (walk (car node)) (walk (cdr node))))))
    (let* ((result (walk form))
           (required (cond ((eq? top '##sourcify-deep) '(0 1 2 3 4 5 6 7 21))
                           ((eq? top 'env-lookup)
                            (if (assq 24 matched) '(8 9 11 14 19 20 24) '(8 9 10 11 14 19 20)))
                           ((eq? top 'env-frame-lookup-var) '(12 13))
                           ((eq? top 'env-namespace-lookup-both) '(15 16))
                           ((eq? top 'macro-list-table) '(22 23 25 26 publish))
                           ((eq? top 'env-macros-set) '(generation))
                           ((memq top '(macro-list-index macro-index-miss macro-overlay-limit
                                         macro-list-cached macro-list-empty macro-list-ref
                                         macro-list-flatten macro-list-extend
                                         macro-list-prefix-length macro-list-suffix
                                         macro-list-overlay-prefix)) '())
                           ((memq top '(env-lookup-var env-define-var env-lookup-global-var env-lookup-macro
                                        env-macro env-macros-ref)) '())
                           (else (error "unknown diagnostic source role" top)))))
      (if (or (not (= (length matched) (length required)))
              (not (let check ((xs required))
                     (or (null? xs)
                         (and (equal? (assq (car xs) matched) (cons (car xs) 1))
                              (check (cdr xs)))))))
          (error "diagnostic instrumentation sites changed" top matched required))
      result)))

(define (f6-work-write eval-source env-source namespace-source macro-source resource observer-source output)
  (let ((runtime (f6-work-read eval-source '(##sourcify-deep)))
        (compiler (f6-work-read env-source
                   '(env-frame-lookup-var env-namespace-lookup-both env-lookup
                     env-lookup-var env-define-var env-lookup-global-var env-lookup-macro)
                   '(macro-list-index macro-index-miss macro-overlay-limit
                     macro-list-cached macro-list-empty macro-list-ref
                     macro-list-flatten macro-list-extend
                     macro-list-prefix-length macro-list-suffix
                     macro-list-overlay-prefix macro-list-table
                     env-macro env-macros-set env-macros-ref)))
        (absent (f6-work-read macro-source '(macro-absent-obj)))
        ;; Compile the same protocol writer, instead of interpreting each of
        ;; the many detail records. The existing startup resource owns it.
        (writer (f6-work-read observer-source '(f6-observe-record)))
        (helpers (f6-work-read resource
                   '(f6-work-names f6-work-counts f6-work-publishing?
                     f6-work-total-events f6-work-last-tick ##f6-work-snapshot
                     ##f6-work-add! ##f6-work-alias-result
                     f6-macro-objects f6-macro-next-id f6-macro-next-build f6-macro-empty-row
                     ##f6-macro-row ##f6-macro-context ##f6-macro-cache-result
                     ##f6-macro-start! ##f6-macro-cell! ##f6-macro-finish ##f6-macro-generation!))))
    (call-with-output-file output
      (lambda (port)
        (define (emit form) (write form port) (newline port))
        (emit '(##namespace ("")))
        (emit (list '##include namespace-source))
        (for-each (lambda (row) (emit (cdr row))) writer)
        (for-each (lambda (row) (emit (cdr row))) helpers)
        (emit '(##namespace ("c#")))
        (emit (list '##include namespace-source))
        (for-each (lambda (row) (emit (f6-work-instrument (cdr row) (car row)))) compiler)
        (emit '(##namespace ("")))
        (emit (cdar absent))
        (for-each (lambda (row) (emit (f6-work-instrument (cdr row) (car row)))) runtime)
        (emit '(set! f6-observe-snapshot ##f6-work-snapshot))
        (emit '(f6-observe-event "frontend-work" "installed" "native-source-diagnostic-bodies"))))))
