"""One metadata view of existing gxc definitions, with lazy compiler activation."""

import re
from pathlib import Path


def catalog_source():
    """Derive function bodies from their canonical owner, never duplicate them.

    The canonical file requires top-level definitions at column zero. Native
    parsing and source-function controls qualify the emitted module. The
    atomic observation writer is restricted to catalogue-use observations.
    """
    text = (Path(__file__).resolve().parent.parent/'gerbil_compile_products.ss').read_text()
    definitions = list(re.finditer(r'^\(def (?:\()?([^\s()]+)', text, re.M))
    names = {'compile-product-git', 'compile-product-file', 'compile-product-key',
             'compile-product-json', 'compile-product-record',
             'compile-product-marker',
             'compile-product-interface', 'compile-product-module-plan',
             'compile-product-module-used'}
    blocks = {}
    for index, match in enumerate(definitions):
        name = match[1]
        if name in names:
            if name in blocks:
                raise ValueError('ambiguous compiler catalogue definition')
            stop = definitions[index+1].start() if index+1 < len(definitions) else len(text)
            blocks[name] = text[match.start():stop]
    if set(blocks) != names:
        raise ValueError('compiler catalogue owner is incomplete')
    # Specialize the original atomic observation writer to its catalogue mode.
    # No native snapshot/GC-root bookkeeping is initialized by this module.
    record = blocks['compile-product-record']
    cut = '    (when (equal? suffix ".request")'
    if record.count(cut) != 1:
        raise ValueError('compiler observation writer boundary differs')
    record = record[:record.index(cut)] + '  ))\n\n'
    record = record.replace('(def (compile-product-record key suffix value)\n',
        '''(def (compile-product-record key suffix value)
  (unless (equal? suffix ".module-used")
    (error "catalogue cannot record native work" suffix))
''', 1)
    blocks['compile-product-record'] = record
    return (''';;; Derived from the existing compile-products owner; metadata only.
namespace: gxc
(import :gerbil/expander)
(export compile-product-marker compile-product-interface
        compile-product-module-plan compile-product-module-used)

'''+''.join(blocks[match[1]] for match in definitions if match[1] in names))


def catalog_bootstrap_source(text, *, inverse=False):
    old = '(gx#import-module (path-expand "../gerbil/compiler/driver.ss" srcdir) #t #t)'
    new = '''(when (getenv "GERBIL_COMPILE_CONTEXT" #f)
  (gx#import-module (path-expand "../gerbil/compiler/compile-product-catalog.ss" srcdir) #t #t))'''
    if inverse:
        if new in text:
            if text.count(new) != 1:
                raise ValueError('ambiguous catalogue bootstrap')
            return text.replace(new, old)
        return text
    if new in text:
        return text
    if text.count(old) != 1:
        raise ValueError('pinned compiler bootstrap differs')
    return text.replace(old, new)


def lazy_compiler_source(text, *, inverse=False):
    """Activate once under the existing import mutex, before any actual work."""
    anchor = '    ;; import with mutex\n'
    activation = '''    ;; Metadata-only builds never activate the source compiler.
    (def compiler-active? #f)
    (def (activate-compiler!)
      (when (and (getenv "GERBIL_COMPILE_CONTEXT" #f) (not compiler-active?))
        (gx#import-module
         (path-expand "src/gerbil/compiler/driver.ss"
                      (path-directory (getenv "GERBIL_BUILD_PREFIX"))) #t #t)
        (set! compiler-active? #t)
        (displayln "COMPILER-DRIVER-ACTIVATED")))
'''
    source_activation=activation
    bootstrap_call="""        (gx#import-module
         (path-expand "src/gerbil/compiler/driver.ss"
                      (path-directory (getenv "GERBIL_BUILD_PREFIX"))) #t #t)"""
    compiled_call="""        (let* ((root (path-directory (getenv "GERBIL_BUILD_PREFIX")))
               (path (path-expand "compiler-driver/ready.scm" (getenv "GERBIL_COMPILE_PRODUCTS")))
               (binding (and (file-exists? path) (call-with-input-file path read))))
          (if binding
            (begin
              (unless (and (list? binding) (= (length binding) 5)
                           (equal? (car binding) (getenv "GERBIL_COMPILE_CONTEXT"))
                           (equal? (cadr binding) (gxc#compile-product-file
                                      (path-expand "src/gerbil/compiler/driver.ss" root)))
                           (equal? (caddr binding) (gxc#compile-product-file
                                      (path-expand "src/gerbil/compiler/compile-products.ss" root)))
                           (equal? (list-ref binding 4) (gxc#compile-product-file (list-ref binding 3))))
                (error "compiled compiler service binding changed" path))
              (load (list-ref binding 3)))
            (gx#import-module (path-expand "src/gerbil/compiler/driver.ss" root) #t #t)))"""
    activation=activation.replace(bootstrap_call,compiled_call)
    if source_activation in text and activation not in text:
        text=text.replace(source_activation,activation)
    catalogue = '''    ;; Keep one metadata owner through all managed consumers. Do not replace
    ;; the full driver's observation writer after it has been activated.
    (when (and (getenv "GERBIL_COMPILE_CONTEXT" #f)
               (not (with-catch (lambda (_) #f)
                      (lambda () (procedure? (eval 'gxc#compile-product-module-plan))))))
      (gx#import-module
        (path-expand "src/gerbil/compiler/compile-product-catalog.ss"
                     (path-directory (getenv "GERBIL_BUILD_PREFIX"))) #t #t))
'''
    old_import = '      (with-lock import-mx (lambda ()\n      (let (path '
    new_import = '      (with-lock import-mx (lambda ()\n      (activate-compiler!)\n      (let (path '
    old_worker = '       (for (spec workch)\n         (build spec settings)'
    new_worker = '''       (for (spec workch)
         (when (getenv "GERBIL_COMPILE_CONTEXT" #f)
           (with-lock import-mx activate-compiler!))
         (build spec settings)'''
    old_entry='        (compile-product-module srcpath (lambda () (compile-module srcpath gxc-opts)))'
    new_entry="""        (let (entry (eval 'gxc#compile-module))
          (compile-product-module srcpath (lambda () (entry srcpath gxc-opts))))"""
    pairs = [(anchor, catalogue+activation+anchor), (old_import, new_import),
             (old_worker, new_worker)]
    if old_entry in text or new_entry in text:
        pairs.append((old_entry,new_entry))
    if inverse:
        if activation not in text:
            return text
        if catalogue not in text:
            pairs[0] = (anchor, activation+anchor)
        prior_worker = '''       (for (spec workch)
         (with-lock import-mx activate-compiler!)
         (build spec settings)'''
        if new_worker not in text and text.count(prior_worker) == 1:
            # Upgrade only the already-installed checked source adapter.
            # No alternate runtime name or loader is retained.
            pairs[2] = (old_worker, prior_worker)
        if old_entry in text and new_entry not in text and len(pairs)==4:
            pairs.pop()  # The preceding source incarnation used a static alias.
        for old, new in reversed(pairs):
            if text.count(new) != 1:
                raise ValueError('lazy compiler activation projection differs')
            text = text.replace(new, old)
        return text
    if activation in text:
        return lazy_compiler_source(lazy_compiler_source(text, inverse=True))
    for old, new in pairs:
        if text.count(old) != 1:
            raise ValueError('pinned compiler activation boundary differs')
        text = text.replace(old, new)
    return text


def check_catalog(ctx, source, store, modules):
    """Read issued plans without replacing the driver, then qualify activation."""
    import json
    from gambit_smp.framework import digest
    from gambit_smp.workspace import write
    source, store = Path(source), Path(store)
    if ctx.env.get('GERBIL_COMPILE_PRODUCTS') != str(store):
        raise ValueError('catalogue store differs from the execution binding')
    catalog = source/'src/gerbil/compiler/compile-product-catalog.ss'
    driver = source/'src/gerbil/compiler/driver.ss'
    if catalog.read_text() != catalog_source():
        raise ValueError('catalogue does not match its canonical definitions')
    paths = [source/'src'/(name+'.ss') for name in modules]
    make=source/'src/std/make.ss';make_text=make.read_text()
    first=make_text.index('    ;; Keep one metadata owner')
    last=make_text.index('    ;; Metadata-only builds never activate',first)
    guard=make_text[first:last]
    ctx.bind([catalog, driver, make, *paths])
    expression = '''(import :gerbil/expander)
(def absent (list 'absent))
(def (driver-binding)
  (with-catch (lambda (_) absent) (lambda () (eval 'gxc#compile-product-invoke))))
(def previous-driver (driver-binding))
MANAGEDGUARD
(unless (eq? previous-driver (driver-binding)) (error "catalogue activated driver"))
(def plan (eval 'gxc#compile-product-module-plan))
(def used (eval 'gxc#compile-product-module-used))
(def snapshots
  (map (lambda (source)
         (let (value (plan source))
           (unless value (error "actual issued catalogue plan required" source))
           (used source ((eval 'gxc#compile-product-interface) source) "build-metadata")
           value)) SOURCES))
(displayln "CATALOG-READ-PASS sources=" (length snapshots) " driver-binding-preserved")
(def observer (eval 'gxc#compile-product-record))
(unless (with-catch (lambda (_) #t)
          (lambda () (observer "catalogue-forbidden" ".request" []) #f))
  (error "catalogue granted native work"))
(when (file-exists? (path-expand "catalogue-forbidden.request.json"
                                (getenv "GERBIL_COMPILE_ATTEMPT")))
  (error "catalogue wrote a native request before refusing it"))
(parameterize ((current-expander-compiling? #t) (current-compilation-target 'C))
  (import-module DRIVER #t #t))
(unless (procedure? (driver-binding)) (error "source driver activation failed"))
(unless (equal? snapshots (map (eval 'gxc#compile-product-module-plan) SOURCES))
  (error "source activation changed issued plans"))
(displayln "CATALOG-ACTIVATION-PASS")
(def native-writer (eval 'gxc#compile-product-record))
MANAGEDGUARD
(unless (eq? native-writer (eval 'gxc#compile-product-record))
  (error "metadata reentry replaced the native writer"))
(displayln "CATALOG-REENTRY-PASS")'''
    expression = expression.replace('MANAGEDGUARD', guard)
    expression = expression.replace('DRIVER #t', json.dumps(str(driver))+' #t', 1)
    expression = expression.replace('SOURCES', '(list '+' '.join(json.dumps(str(p)) for p in paths)+')')
    output = ctx.require('compiler-catalog-native-control',
        [str(source/'run.sh'), 'gxi', '-:p1', '-e', expression],
        source/'src', min(30, ctx.remaining()))
    if (f'CATALOG-READ-PASS sources={len(paths)} driver-binding-preserved' not in output
            or 'CATALOG-ACTIVATION-PASS' not in output
            or 'CATALOG-REENTRY-PASS' not in output):
        raise ValueError('catalogue/driver native handoff markers missing')
    ctx.bind([catalog, driver, make, *paths])
    result = dict(complete=True, modules=modules, makeSha256=digest(make), catalogSha256=digest(catalog),
        driverSha256=digest(driver), output=output, runtimeAdmitted=False,
        scope='Actual same-namespace catalogue reads and observations leave the driver binding unchanged; actual source activation preserves issued plan values. No complete Make or performance admission.')
    write(ctx.directory/'catalog-properties.json', result)
    return result

def check_targets(ctx, source):
    """Observe the real normalized build spec; never infer targets from receipts."""
    import json
    from gambit_smp.framework import digest
    from gambit_smp.workspace import write
    source=Path(source)
    files=[source/'src/std'/name for name in
           ['build.ss','build-std.ss','build-spec.ss','build-config.ss','build-features.ss','make.ss']]
    catalog=source/'src/gerbil/compiler/compile-product-catalog.ss'
    ctx.bind([catalog,*files])
    expression='''(import :gerbil/expander)
(def srcdir SRCDIR)
(def libdir LIBDIR)
(add-load-path! srcdir)
(displayln "TARGET-CENSUS-STAGE gambit-prefix") (force-output)
(let (gambit-sharp (path-expand "lib/_gambit#.scm" (getenv "GERBIL_BUILD_PREFIX")))
  (eval `(begin-foreign (include ,gambit-sharp))))
(displayln "TARGET-CENSUS-STAGE catalog") (force-output)
(import-module CATALOG #t #t)
(displayln "TARGET-CENSUS-STAGE build-std") (force-output)
(import-module BUILDSTD #t #t)
(displayln "TARGET-CENSUS-STAGE build-spec") (force-output)
(def raw ((eval 'std/build-std#build-spec)))
(displayln "TARGET-CENSUS-STAGE normalize") (force-output)
(def specs ((eval 'std/make#normalize-buildspec) raw))
(def settings ((eval 'std/make#make-settings)
               srcdir: srcdir libdir: libdir debug: #t
               target: (string->symbol (getenv "GERBIL_BUILD_TARGET" "C"))))
(displayln "TARGET-CENSUS-STAGE targets") (force-output)
(def rows
  (map (lambda (spec)
         [(keyword->string ((eval 'std/make#spec-type) spec))
          ((eval 'std/make#spec-file) spec settings)
          ((eval 'std/make#spec-inputs) spec settings)
          ((eval 'std/make#spec-outputs) spec settings)]) specs))
(display "MAKE-TARGETS ")
((eval 'gxc#compile-product-json) rows (current-output-port))
(newline)
(displayln "MAKE-TARGETS-PASS")'''
    for token,path in [('SRCDIR',source/'src/std'),('LIBDIR',source/'build/lib'),
                       ('CATALOG',catalog),('BUILDSTD',source/'src/std/build-std.ss')]:
        expression=expression.replace(token,json.dumps(str(path)),1)
    output=ctx.require('compiler-target-census',
        [str(source/'run.sh'),'gxi','-:p1','-e',expression],
        source/'src/std',min(30,ctx.remaining()))
    rows=[json.loads(line.removeprefix('MAKE-TARGETS '))for line in output.splitlines()
          if line.startswith('MAKE-TARGETS ')]
    if len(rows)!=1 or 'MAKE-TARGETS-PASS'not in output:
        raise ValueError('actual target census did not complete')
    targets=rows[0]
    if (any(not isinstance(row,list)or len(row)!=4 for row in targets)
            or len({row[1]for row in targets})!=len(targets)):
        raise ValueError('unique normalized target identities required')
    ctx.bind([catalog,*files])
    result=dict(complete=True,count=len(targets),targets=targets,
        sourceBindings={str(p):digest(p)for p in [catalog,*files]},
        runtimeAdmitted=False,scope='Actual build-spec, normalize-buildspec, settings and spec input/output functions. Declaration census only; no target or parent completion follows.')
    write(ctx.directory/'target-census.json',result)
    return result
