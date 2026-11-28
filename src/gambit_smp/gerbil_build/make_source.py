"""Gerbil build: make source."""

from pathlib import Path
import json

from gambit_smp.gerbil_build.compiler_source import module_source
from gambit_smp.gerbil_build.library_source import library_order_source, library_initialization_source
from gambit_smp.gerbil_build.static_units import library_static_source
from gambit_smp.gerbil_build.catalog_source import catalog_source, catalog_bootstrap_source, lazy_compiler_source


def _metadata_make_source(make):
    """Separate admitted graph metadata from macro activation in official Make."""
    if '(def (plan/mx mod)' in make:
        return make
    extern='(extern namespace: gxc compile-product-marker compile-product-interface compile-product-module compile-product-module-used)'
    if make.count(extern)!=1:raise ValueError('pinned Make compiler interface differs')
    make=make.replace(extern,extern[:-1]+' compile-product-module-plan)')
    anchor='    ;; import with mutex\n'
    if make.count(anchor)!=1:raise ValueError('pinned Make import boundary differs')
    make=make.replace(anchor,'''    ;; Planning a completed program must not import its macro phases.
    (def (plan/mx mod)
      (and (getenv "GERBIL_COMPILE_CONTEXT" #f)
           (compile-product-module-plan mod)))
'''+anchor)
    old='''          ((".ss" ".ssi")
           (expander-context-id (import/mx file)))'''
    new='''          ((".ss" ".ssi")
           (let (plan (plan/mx file))
             (if plan (string->symbol (car plan))
                 (expander-context-id (import/mx file)))))'''
    if make.count(old)!=1:raise ValueError('pinned Make identity boundary differs')
    make=make.replace(old,new)
    old='''    (def (build-coordinator spec)
      (let* ((file (spec-file spec settings))
             (mod (import/mx file)))
        (for (in (module-context-import mod))
          (consider in (expander-context-id mod)))
        (if (or (build? spec)
                (build-dependent? spec mod))
          ;; it needs to be built, put it to the work channel
          (channel-put workch spec)
          ;; no need to build, unblock dependents
          (completion-post! (hash-ref completions (module-id spec)) 'done))
        ;; clear the barrrier
        (barrier-post! build-barrier)))'''
    new='''    (def (build-coordinator spec)
      (let* ((file (spec-file spec settings))
             (plan (plan/mx file)))
        (if plan
          (let ((id (string->symbol (car plan)))
                (dependencies (map string->symbol (cadr plan))))
            (for (dependency dependencies) (wait-for-id dependency id))
            ;; Preserve the official input/output and dependency freshness
            ;; checks after providers complete, including extra build inputs.
            (if (or (build? spec)
                    (ormap (lambda (dependency)
                             (and (not (eq? dependency id))
                                  (let (ts (with-catch false
                                              (lambda () (dependency-timestamp dependency))))
                                    (if ts
                                      (ormap (lambda (output) (> ts (file-timestamp output)))
                                             (spec-outputs spec settings))
                                      #t))))
                           dependencies))
              (channel-put workch spec)
              (begin
                (compile-product-module-used file (compile-product-interface file) "build-metadata")
                (completion-post! (hash-ref completions id) 'done))))
          (let (mod (import/mx file))
            (for (in (module-context-import mod))
              (consider in (expander-context-id mod)))
            (if (or (build? spec) (build-dependent? spec mod))
              (channel-put workch spec)
              (completion-post! (hash-ref completions (module-id spec)) 'done))))
        (barrier-post! build-barrier)))'''
    if make.count(old)!=1:raise ValueError('pinned Make coordinator boundary differs')
    make=make.replace(old,new)
    old='''    (def (wait-for ctx self)
      (alet* ((id (expander-context-id ctx)) ; :<root> prelude has no id
              ;; Nested modules are built with their enclosing file.
              (id (module-strip-nesting id)))
        ;; A module may import its own nested modules; never wait on itself.
        (unless (eq? id self)
          (alet (completion (hash-get completions id))
            (completion-wait! completion)))))'''
    new='''    (def (wait-for-id id self)
      ;; Native contexts and admitted metadata share the original completion
      ;; table and the same nested-module/self-dependency rule.
      (let (id (module-strip-nesting id))
        (unless (eq? id self)
          (alet (completion (hash-get completions id))
            (completion-wait! completion)))))

    (def (wait-for ctx self)
      (alet (id (expander-context-id ctx)) ; :<root> prelude has no id
        (wait-for-id id self)))'''
    if make.count(old)!=1:raise ValueError('pinned Make completion edge differs')
    return make.replace(old,new)


def _generation_make_source(make, *, inverse=False):
    """Let a closed generation schedule work, never certify its completion.

    The existing issuer owns source/dependency/output validation. This reader
    consumes only its planning fields; the worker still owns restore, native
    joining and public interface publication.
    """
    query = ''';; Begin closed generation planning query.
(def (module-generation-plan source)
  (let* ((source (path-normalize source))
         (marker (string-append (compile-product-marker source) ".generation")))
    (and (file-exists? marker)
         (let (datum (call-with-input-file marker read))
           (unless (and (list? datum) (= (length datum) 10)
                        (equal? (car datum) (getenv "GERBIL_COMPILE_CONTEXT"))
                        (equal? (cadr datum) source)
                        (string? (list-ref datum 3))
                        (list? (list-ref datum 4))
                        (andmap string? (list-ref datum 4))
                        (eq? (list-ref datum 8) #t)
                        (equal? (list-ref datum 9) (path-normalize (current-directory))))
             (error "invalid generation planning credential" source marker))
           [(list-ref datum 3) (list-ref datum 4)]))))
;; End closed generation planning query.

'''
    anchor = '(def default-gambit-gsc '
    fallback = '''          (let (mod (import/mx file))
            (for (in (module-context-import mod))
              (consider in (expander-context-id mod)))
            (if (or (build? spec) (build-dependent? spec mod))
              (channel-put workch spec)
              (completion-post! (hash-ref completions (module-id spec)) 'done))))'''
    continuation = '''          (let (generation (and (getenv "GERBIL_COMPILE_CONTEXT" #f)
                                 (module-generation-plan file)))
            (if generation
              (begin
                (for (dependency (cadr generation))
                  (wait-for-id (string->symbol dependency) (string->symbol (car generation))))
                ;; Generation is not completion. The original worker must
                ;; restore, join all native jobs and publish the private SSI.
                (channel-put workch spec))
              (let (mod (import/mx file))
                (for (in (module-context-import mod))
                  (consider in (expander-context-id mod)))
                (if (or (build? spec) (build-dependent? spec mod))
                  (channel-put workch spec)
                  (completion-post! (hash-ref completions (module-id spec)) 'done))))))'''
    identity = '(let (plan (plan/mx file))'
    issued_identity = '''(let (plan (or (plan/mx file)
                             (and (getenv "GERBIL_COMPILE_CONTEXT" #f)
                                  (module-generation-plan file))))'''
    pairs = [(anchor, query+anchor), (identity, issued_identity),
             (fallback, continuation)]
    if inverse:
        if ';; Begin closed generation planning query.' not in make:
            return make
        for old, new in reversed(pairs):
            if make.count(new) != 1:
                raise ValueError('closed generation planning projection differs')
            make = make.replace(new, old)
        return make
    if ';; Begin closed generation planning query.' in make:
        return _generation_make_source(_generation_make_source(make, inverse=True))
    for old, new in pairs:
        if make.count(old) != 1:
            raise ValueError('pinned generation planning boundary differs')
        make = make.replace(old, new)
    return make


def _identity_make_source(make, *, inverse=False):
    """Owned consumer-only edits, with a checked inverse for producer identity.

    This never normalizes generated Scheme/C, identifiers or timestamps.
    Everything outside these exact query bodies, including compiler options,
    remains byte-identical in the producer fingerprint.
    """
    if inverse:
        make = lazy_compiler_source(make, inverse=True)
        make = _generation_make_source(make, inverse=True)
    anchor='(def default-gambit-gsc '
    full_reader=''';; Query the same reader used by core-import-module, without expanding
;; its body. Custom language readers retain the original import path.
(def (read-module-id path)
  (with-catch
   (lambda (e) (if (datum-parsing-exception? e) #f (raise e)))
   (lambda ()
     (parameterize ((current-expander-context (core-context-root))
                    (current-expander-marks [])
                    (current-expander-phi 0))
       (let-values (((pre id ns body) (core-read-module/sexp path))) id)))))

'''
    header_reader=''';; The common header grammar is line-local. Anything more general uses the
;; original reader below. In particular #lang, block/datum comments and
;; multiline header values never receive a guessed identity.
(def (read-module-header-id path)
  (with-catch (lambda (_) #f)
    (lambda ()
      (call-with-input-file path
        (lambda (port)
          (def (identity pre ns pkg)
            (let-values (((pre ns pkg)
                          (if pkg (values pre ns pkg)
                              (core-read-module-package path pre ns))))
              ;; Preserve the original reader's prelude path validation.
              (cond ((core-bound-module-prelude? pre) (syntax-local-e pre))
                    ((core-library-module-path? pre) (core-resolve-library-module-path pre))
                    ((stx-string? pre) (core-resolve-module-path pre path))
                    (else (stx-e pre)))
              (let* ((name (core-module-path->namespace path))
                     (name (if pkg (string-append pkg "/" name) name)))
                (string->symbol name))))
          (let loop ((pre #f) (ns #f) (pkg #f))
            (let (line (read-line port))
              (if (eof-object? line) (identity pre ns pkg)
                (let skip ((i 0))
                  (cond
                   ((= i (string-length line)) (loop pre ns pkg))
                   ((char-whitespace? (string-ref line i)) (skip (+ i 1)))
                   ((eqv? (string-ref line i) #\\;) (loop pre ns pkg))
                   ((memv (string-ref line i) '(#\\( #\\[)) (identity pre ns pkg))
                   ((eqv? (string-ref line i) #\\#) #f)
                   (else
                    (let parse ((rest (call-with-input-string line read-all))
                                (pre pre) (ns ns) (pkg pkg))
                      (match rest
                        ([] (loop pre ns pkg))
                        ([key value . rest]
                         (and (or (symbol? value) (string? value) (eq? value #f))
                              (case key
                                ((prelude:) (parse rest value ns pkg))
                                ((namespace:)
                                 (parse rest pre
                                   (cond ((symbol? value) (symbol->string value))
                                         ((string? value) value)
                                         (else #!void)) pkg))
                                ((package:)
                                 (parse rest pre ns
                                   (if (symbol? value) (symbol->string value) value)))
                                (else #f))))
                        (else #f))))))))))))))

'''
    reader=header_reader+full_reader.replace(
        '  (with-catch\n', '  (or (read-module-header-id path)\n      (with-catch\n',1).replace(
        '(core-read-module/sexp path))) id)))))',
        '(core-read-module/sexp path))) id))))))')
    pairs=[(anchor,reader+anchor),
        ('''             (if plan (string->symbol (car plan))
                 (expander-context-id (import/mx file)))))''',
         '''             (if plan (string->symbol (car plan))
                 (or (and (getenv "GERBIL_COMPILE_CONTEXT" #f) (read-module-id file))
                     (expander-context-id (import/mx file))))))'''),
        ('''                                  (let (ts (with-catch false
                                              (lambda () (dependency-timestamp dependency))))''',
         '''                                  ;; The managed producer emits interfaces at
                                  ;; libdir/module-id.ssi. Query that immutable
                                  ;; output view without mutating load-path.
                                  (let* ((path (path-expand
                                                (string-append (symbol->string dependency) ".ssi")
                                                (settings-libdir settings)))
                                         (ts (and (file-exists? path) (file-timestamp path))))''')]
    marker='(def (read-module-id path)'
    if inverse:
        if marker not in make:return make
        if header_reader not in make and full_reader in make:
            # A previously checked query adapter has the same producer.
            # Upgrade its source in place; do not retain a runtime alias.
            pairs[0]=(anchor,full_reader+anchor)
        for old,new in reversed(pairs):
            if make.count(new)!=1:raise ValueError('owned Make query projection differs')
            make=make.replace(new,old)
        return make
    if marker in make:
        return _identity_make_source(_identity_make_source(make,inverse=True))
    for old,new in pairs:
        if make.count(old)!=1:raise ValueError('pinned Make query boundary differs')
        make=make.replace(old,new)
    return lazy_compiler_source(_generation_make_source(make))


def _completion_source_delta(source):
    """Extend the pinned producer in place; retain official names/entrypoints."""
    source = Path(source)
    driver = (source/'src/gerbil/compiler/driver.ss').read_text()
    make = (source/'src/std/make.ss').read_text()
    build = (source/'src/std/build.ss').read_text()
    # The source driver extends the running compiler through its public module
    # identities. Relative imports would recursively reload a second core.
    driver = driver.replace('prelude: "../core"', 'prelude: :gerbil/core')
    old_imports = '(import "../expander"\n        "../runtime/error"\n        "base"\n        "compile"\n        "optimize")'
    driver = driver.replace(old_imports, '(import :gerbil/expander\n        :gerbil/runtime/error\n        :gerbil/compiler/base\n        :gerbil/compiler/compile\n        :gerbil/compiler/optimize)')
    if '(include "compile-products.ss")' not in driver:
        anchor = '(def (gsc-compile-file path phi?)'
        old = '(invoke (gerbil-gsc)\n            [gsc-cc-opts ... gsc-ld-opts ... gsc-link-opts ... path])))'
        if driver.count(anchor)!=1 or driver.count(old)!=1:
            raise ValueError('pinned compiler invocation boundary differs')
        driver = driver.replace(anchor,'(include "compile-products.ss")\n\n'+anchor)
        driver = driver.replace(old,'(compile-product-invoke (gerbil-gsc)\n            [gsc-cc-opts ... gsc-ld-opts ... gsc-link-opts ... path] path)))')
    if '(extern namespace: gxc compile-product-marker' not in make:
        anchor = '(def default-gambit-gsc '
        old = '[(library-path mod ".ssi" settings)\n   (static-path mod settings)])'
        if make.count(anchor)!=1 or make.count(old)!=1:
            raise ValueError('pinned module output boundary differs')
        make = make.replace(anchor,'(extern namespace: gxc compile-product-marker)\n\n'+anchor)
        make = make.replace(old,'[(library-path mod ".ssi" settings)\n   (static-path mod settings)\n   (compile-product-marker (source-path mod ".ss" settings))])')
    observed_outputs='[(library-path mod ".ssi" settings)\n   (static-path mod settings)\n   (compile-product-marker (source-path mod ".ss" settings))])'
    make=make.replace(observed_outputs,
        '(append [(library-path mod ".ssi" settings) (static-path mod settings)]\n'
        '          (if (getenv "GERBIL_COMPILE_CONTEXT" #f)\n'
        '            [(compile-product-marker (source-path mod ".ss" settings))]\n'
        '            [])))')
    # make-build already owns the bounded worker population. A second deferred
    # native queue retains every module closure until all frontends finish and
    # releases dependency completion before native task completion. Each existing
    # worker must finish its module's GSC work before publishing completion.
    make = make.replace('parallel: (> (settings-parallelize settings) 1)',
                        'parallel: #f')
    if '../gerbil/compiler/driver.ss' not in build and 'compile-product-catalog.ss' not in build:
        anchor = '(gx#import-module "build-std.ss" #t #t)'
        if build.count(anchor)!=1:raise ValueError('pinned stdlib build boundary differs')
        build = build.replace(anchor,
            '(gx#import-module (path-expand "../gerbil/compiler/driver.ss" srcdir) #t #t)\n'+anchor)
    if '(compile-product-output path)' not in driver:
        driver=driver.replace('(with-output-to-file [path: path . scheme-file-settings] fun))',
            '(begin0 (with-output-to-file [path: path . scheme-file-settings] fun)\n    (compile-product-output path)))')
        driver=driver.replace('(copy-file scm0 scms)', '(begin (copy-file scm0 scms) (compile-product-output scms))')
        driver=driver.replace('(call-with-output-file scms void)', '(begin (call-with-output-file scms void) (compile-product-output scms))')
        driver=driver.replace('(def (compile-top-module ctx)\n', '(def (compile-top-module ctx)\n  (compile-product-module-info ctx)\n')
    if '(compile-product-module srcpath' not in make:
        make=make.replace('(extern namespace: gxc compile-product-marker)',
            '(extern namespace: gxc compile-product-marker compile-product-interface compile-product-module compile-product-module-used)')
        make=make.replace('(with-lock import-mx (cut import-module mod #f #f))',
            '(with-lock import-mx (lambda ()\n      (let (path (if (getenv "GERBIL_COMPILE_CONTEXT" #f) (compile-product-interface mod) mod))\n        (begin0 (import-module path #f #f)\n          (unless (equal? path mod) (compile-product-module-used mod path))))))')
        make=make.replace('(compile-module srcpath gxc-opts)))',
            '(if (getenv "GERBIL_COMPILE_CONTEXT" #f)\n        (compile-product-module srcpath (lambda () (compile-module srcpath gxc-opts)))\n        (compile-module srcpath gxc-opts))))')
    makefile=(source/'Makefile').read_text()
    if '\nlang:\n' not in makefile:
        anchor='\nlibgerbil:\n\t$(BUILD) libgerbil\n'
        if makefile.count(anchor)!=1:raise ValueError('pinned Make stage boundary differs')
        makefile=makefile.replace(anchor,anchor+'\nlang:\n\t$(BUILD) lang\n\n.PHONY: lang\n')
    if '.PHONY: lang' not in makefile:makefile+='\n.PHONY: lang\n'
    driver=module_source(driver,driver=True)
    if '(compile-product-initialization-graph ctx)' not in driver:
        anchor='    (compile-meta-code ctx)'
        if driver.count(anchor)!=1:raise ValueError('semantic graph producer cut differs')
        driver=driver.replace(anchor,anchor+'\n    (compile-product-initialization-graph ctx)')
    make=_metadata_make_source(make)
    make=_identity_make_source(make)
    build=catalog_bootstrap_source(build)
    return {'src/gerbil/compiler/driver.ss':driver,'src/std/make.ss':make,
            'src/gerbil/compiler/compile-product-catalog.ss':catalog_source(),
            'src/build/build-libgerbil.ss':library_static_source(library_initialization_source(library_order_source(library_static_source((source/'src/build/build-libgerbil.ss').read_text(),inverse=True)))),
            'src/std/build.ss':build,'src/gerbil/compiler/compile-products.ss':
                (Path(__file__).resolve().parent.parent / 'gerbil_semantic_graph.ss').read_text()+'\n'+
                (Path(__file__).resolve().parent.parent / 'gerbil_compile_products.ss').read_text(),
            'Makefile':makefile}


def _install_compile_products(ctx, work, source):
    from gambit_smp.recipes import tree_identity
    from gambit_smp.workspace import sync_build_source, checkpoint_build_source
    work, source = Path(work), Path(source)
    if source.resolve() not in ctx.leased_workspaces:
        raise ValueError('compiler source delta requires the exclusive source lease')
    delta = _completion_source_delta(source)
    staged = ctx.directory/'compiler-source-delta'
    staged.mkdir()
    for name,text in delta.items():
        path = staged/name;path.parent.mkdir(parents=True,exist_ok=True)
        path.write_text(text)
        original = source/name
        if original.exists():path.chmod(original.stat().st_mode & 0o777)
    state=json.loads((work/'source-state.json').read_text())
    inventory=dict(state['inputs']);inventory.update(tree_identity(staged))
    update=sync_build_source(ctx.root,work,staged,inventory=inventory,
        mutable=state.get('mutable',()),overlay_files=set(state.get('overlayFiles',()))|set(delta))
    checkpoint_build_source(source)
    return update
