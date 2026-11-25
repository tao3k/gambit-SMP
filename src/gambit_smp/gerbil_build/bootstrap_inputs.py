"""Gerbil build: bootstrap inputs."""

from gambit_smp.framework import digest, relative, available_processors
from pathlib import Path
import hashlib


def _source_changes(changes, old_heads, new_heads, completed):
    """Return the first invalidated stage for a narrow Scheme-only delta."""
    import re
    if (not isinstance(changes,dict) or not changes or old_heads.get('gambit')!=new_heads.get('gambit')
            or old_heads.get('gerbil')==new_heads.get('gerbil')
            or set(completed)-{'configure','prepare','gambit','boot-gxi','stage0','stage1'}):
        raise ValueError('source update requires an unchanged runtime and only completed core phases')
    from gambit_smp.source_capabilities import source_name
    for name,sha in changes.items():
        source_name(name)
        if ((not name.startswith('src/std/') and name!='src/gerbil/compiler/driver.ss') or Path(name).suffix not in {'.ss','.scm','.md'}
                or not isinstance(sha,str) or not re.fullmatch('[0-9a-f]{64}',sha)):
            raise ValueError('source delta escapes the declared Scheme compiler components')
    return 'stage1' if 'src/gerbil/compiler/driver.ss' in changes else 'stdlib'


def _apply_source_update(ctx, source, checkout, old_heads, new_heads, changes):
    """Advance the owned source tree after original core receipts revalidate.

    Core version metadata retains its original producer revision. The ensemble
    source revision advances independently; no binary is relabelled or copied.
    """
    from gambit_smp.workspace import write
    invalidated=_source_changes(changes,old_heads,new_heads,{})
    source,checkout=Path(source),Path(checkout)
    git=ctx.tools['git']
    ctx.require('prepared-source-fetch',[git,'-C',source,'fetch','--no-tags','--depth=256',
        '--update-shallow',checkout,new_heads['gerbil']],ctx.root,30)
    actual=ctx.require('prepared-source-fetched-head',[git,'-C',source,'rev-parse','FETCH_HEAD'],ctx.root,10).strip()
    if actual!=new_heads['gerbil']:raise ValueError('source update fetched another source revision')
    paths=ctx.require('prepared-source-diff',[git,'-C',source,'diff','--name-only','-z',
        old_heads['gerbil'],new_heads['gerbil'],'--'],ctx.root,10).split('\0')
    if sorted(filter(None,paths))!=sorted(changes):
        raise ValueError('committed source delta differs from declared Scheme changes')
    for name,sha in changes.items():
        path=checkout/name
        if not path.is_file() or path.is_symlink() or digest(path)!=sha:
            raise ValueError('Scheme source provider differs: '+name)
    if invalidated=='stage1':
        name='src/gerbil/compiler/driver.ss'
        before=ctx.require('prepared-compiler-source-interface',[git,'-C',source,'show',
            old_heads['gerbil']+':'+name],ctx.root,10)
        after=(checkout/name).read_text()
        signature='(def (compile-scm-file path code (phi? #f) (static-path #f))'
        successor='\n(def (gsc-link-options '
        def interface(text):
            if text.count(signature)!=1 or text.count(successor)!=1:
                raise ValueError('one actual Scheme emitter procedure required')
            start=text.index(signature)+len(signature)
            end=text.index(successor,start)
            return text[:start],text[end:]
        if interface(before)!=interface(after):
            raise ValueError('compiler source delta changes interfaces outside compile-scm-file')
    ctx.require('prepared-source-checkout',[git,'-C',source,'checkout','-B','darwin-acceleration',
        new_heads['gerbil']],ctx.root,10)
    for name,sha in changes.items():
        path=source/name
        if not path.is_file() or path.is_symlink() or digest(path)!=sha:
            raise ValueError('updated Scheme source differs: '+name)
        ctx.bind([path])
    write(ctx.directory/'source-update.json',dict(
        previousRequestHeads=old_heads,requestHeads=new_heads,changes=changes,
        originalCoreVersionPreserved=True,coreBinaryRelabelled=False,
        stdlibProductsReused=False,sourceOverlayCount=0,firstInvalidatedPhase=invalidated))


def _index_gambit_snapshot(ctx, nested, revision):
    """FETCH_HEAD is transport state; it must never choose the target identity."""
    ctx.require('bazel-gambit-index',[ctx.tools['git'],'-C',nested,
        'reset','--mixed',revision],ctx.root,5)
    actual = ctx.require('bazel-gambit-index-head',[ctx.tools['git'],'-C',nested,
        'rev-parse','HEAD'],ctx.root,5).strip()
    if actual != revision:
        raise ValueError('nested target HEAD differs after seed acquisition; refuse native construction')
    return actual


def _configure_host_bootstrap(source):
    """Integrate upstream regeneration at Gerbil's actual Gambit producer.

    The old producer deletes boot/gsc-boot, so a preceding shell invocation
    would be discarded. Replace that two-line transition, not its consumers.
    """
    script = Path(source)/'src/build.sh'
    before = script.read_text()
    old = ('  (cd gambit && rm -rf boot gsc-boot) || die\n'
           '  (cd gambit && m="make -j ${GERBIL_BUILD_CORES:-1}" && $m bootstrap && $m from-scratch)')
    new = ('  (cd gambit && m="make -j ${GERBIL_BUILD_CORES:-1}" && '
           '$m current-gsc-boot && $m bootstrap && $m from-scratch) || die')
    if before.count(old) != 1:
        raise ValueError('Gerbil Gambit bootstrap producer drift; no native construction')
    script.write_text(before.replace(old,new))
    return dict(path=str(script), beforeSha256=hashlib.sha256(before.encode()).hexdigest(),
                sha256=digest(script), target='current-gsc-boot', role='build-host-only')
