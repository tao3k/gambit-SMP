"""Checked source adapters for module-owned native work and publication.

The inverse is a producer-role projection, never a generated-file normalizer.
Unknown edits outside these exact boundaries remain in the fingerprint.
"""

DRIVER_OLD = """(def (with-output-to-scheme-file path fun)
  (begin0 (with-output-to-file [path: path . scheme-file-settings] fun)
    (compile-product-output path)))"""
DRIVER_NEW = """(def (with-output-to-scheme-file path fun)
  (let (target (compile-product-output-path path))
    (begin0 (with-output-to-file [path: target . scheme-file-settings] fun)
      (compile-product-output path))))"""

BATCH = r'''
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

(def (compile-product-publish state)
  (compile-product-drain state)
  ;; All native tasks are joined before the interface becomes importable.
  (for-each (lambda (row) (rename-file (cadr row) (car row)))
            (reverse (vector-ref state 8))))
'''

HELPER_PAIRS = [
    ('(def (compile-product-invoke program arguments source)',
     '(def (compile-product-invoke-now program arguments source)'),
    ('(state (vector #f [] [] [] [] #t))',
     '(state (vector #f [] [] [] [] #t #t [] []))'),
    ('(parameterize ((current-compile-product-module state)) (thunk))',
     '(parameterize ((current-compile-product-module state))\n        (thunk)\n        (compile-product-publish state))'),
    ('''      (let (state (current-compile-product-module))
        (vector-set! state 2
          (cons [key (compile-product-plain-source?
                      (path-expand (string-append key ".input.scm") (getenv "GERBIL_COMPILE_ATTEMPT")) #t)]
                (vector-ref state 2)))))))''',
     '''      (let* ((state (current-compile-product-module))
             (task [key (compile-product-plain-source?
                         (path-expand (string-append key ".input.scm") (getenv "GERBIL_COMPILE_ATTEMPT")) #t)]))
        (with-driver-mutex
          (vector-set! state 2 (cons task (vector-ref state 2))))))))''')]


GENERATION_BODY_OLD = '''      (parameterize ((current-compile-product-module state))
        (thunk)
        (compile-product-publish state))
      (unless (and (vector-ref state 0) (equal? before (compile-product-file source))
                   (compile-product-dependencies? (vector-ref state 4)))
        (error "module completion lacks stable source/identity" source))'''
GENERATION_BODY_NEW = '''      (parameterize ((current-compile-product-module state))
        (unless (compile-product-generation-restore key source before state)
          (thunk)
          (compile-product-generation-close key source before state))
        (compile-product-publish state
          (lambda ()
            (unless (and (vector-ref state 0) (equal? before (compile-product-file source))
                         (compile-product-dependencies? (vector-ref state 4)))
              (error "module completion lacks stable source/identity" source)))))'''
PUBLISH_OLD = '''(def (compile-product-publish state)
  (compile-product-drain state)
  ;; All native tasks are joined before the interface becomes importable.'''
PUBLISH_NEW = '''(def (compile-product-publish state (before-publish void))
  (compile-product-drain state)
  (before-publish)
  ;; All native tasks are joined before the interface becomes importable.'''


def generation_source(text, *, inverse=False):
    """Invert only the source-owned generation continuation, not the generator.

    Scheme remains the single implementation. Both the approved section and
    its call boundary must match; unknown edits cannot disappear from identity.
    """
    from pathlib import Path
    import hashlib
    start = '\n;;; Module generation closes before native jobs can consume its output bundle.'
    end = ';;; End module generation ownership.\n'
    canonical = (Path(__file__).resolve().parent.parent/'gerbil_compile_products.ss').read_text()
    section = canonical[canonical.index(start):canonical.index(end)+len(end)]
    if hashlib.sha256(section.encode()).hexdigest() != '6a3d1ea4fc3d19650746cdb65370017f6a6db7b6db4b0f66826039feb04ac5f3':
        raise ValueError('unreviewed module generation continuation')
    if inverse:
        if start not in text:
            return text
        if (text.count(section+'\n') != 1 or text.count(GENERATION_BODY_NEW) != 1
                or text.count(PUBLISH_NEW) != 1):
            raise ValueError('module generation continuation inverse differs')
        return (text.replace(section+'\n', '').replace(GENERATION_BODY_NEW, GENERATION_BODY_OLD)
                .replace(PUBLISH_NEW, PUBLISH_OLD))
    if start in text:
        generation_source(text, inverse=True)
        return text
    anchor = '(def (compile-product-module source thunk)'
    if (text.count(anchor) != 1 or text.count(GENERATION_BODY_OLD) != 1
            or text.count(PUBLISH_OLD) != 1):
        raise ValueError('module generation continuation boundary differs')
    return (text.replace(anchor, section+'\n'+anchor).replace(GENERATION_BODY_OLD, GENERATION_BODY_NEW)
            .replace(PUBLISH_OLD, PUBLISH_NEW))


def module_source(text, *, driver=False, inverse=False):
    """Apply or invert only the complete reviewed adapter, fail on partial edits."""
    if driver:
        old, new = DRIVER_OLD, DRIVER_NEW
        if inverse and new not in text:
            return text
        if not inverse and new in text:
            return text
        a, b = (new, old) if inverse else (old, new)
        if text.count(a) != 1:
            raise ValueError('module publication driver boundary differs')
        return text.replace(a, b)
    if inverse:
        text = generation_source(text, inverse=True)
    marker = ';;; Native jobs belong to one module;'
    if inverse:
        if marker not in text:
            return text
        if text.count(BATCH) != 1:
            raise ValueError('module native ownership adapter differs')
        text = text.replace(BATCH, '')
        for old, new in reversed(HELPER_PAIRS):
            if text.count(new) != 1:
                raise ValueError('module native ownership inverse differs')
            text = text.replace(new, old)
        return text
    if marker in text:
        module_source(text, inverse=True)
        return generation_source(text)
    for old, new in HELPER_PAIRS:
        if text.count(old) != 1:
            raise ValueError('module native ownership boundary differs')
        text = text.replace(old, new)
    return generation_source(text + BATCH)
