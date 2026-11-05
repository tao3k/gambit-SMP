"""Exact header representation refinement inside the existing native workspace.

This module owns no process runner, build profile, cache or runtime semantics.
The existing ExecutionContext and workspace lease own all native work.
"""
from pathlib import Path
import hashlib
import re


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def manifest(raw):
    lines = raw.decode('ascii').splitlines()
    names = []
    for line in lines:
        match = re.fullmatch(r'#include "(_gambit/[a-z_]+\.h\.in)"', line)
        if not match:
            raise ValueError('header manifest must contain only ordered private fragments')
        names.append(match[1])
    if not names or len(set(name.casefold() for name in names)) != len(names):
        raise ValueError('nonempty collision-free header manifest required')
    return names


def reconstruct(root):
    root = Path(root)
    names = manifest((root / 'include/gambit.h.in').read_bytes())
    payload = []
    for name in names:
        path = root / 'include' / name
        if path.is_symlink() or not path.is_file():
            raise ValueError('regular private header fragment required: ' + name)
        payload.append(path.read_bytes())
    return names, b''.join(payload)


def build_contract(root):
    """Refine the publication owner separately from the historical byte move."""
    root = Path(root)
    names, raw = reconstruct(root)
    configure = (root / 'configure.ac').read_text()
    make = (root / 'include/makefile.in').read_text()
    if 'AC_CONFIG_COMMANDS([include/gambit.h]' not in configure:
        raise ValueError('configure must delegate public header publication')
    if re.search(r'include/gambit\.h:include/', configure):
        raise ValueError('configure retains a second module inventory')
    if any(name in make for name in names):
        raise ValueError('Make retains a second module inventory')
    for contract in ('HEADER_TEMPLATES := $(shell $(AWK)',
                     '$(srcdirpfx)gambit.h.in',
                     'RCFILES = makefile.in gambit.h.in config.h.in stamp-release.h $(HEADER_TEMPLATES)',
                     'gambit.h: | stamp-gambit', 'cmp -s "$$tmp" gambit.h',
                     'touch stamp-gambit'):
        if contract not in make:
            raise ValueError('missing publication/dependency contract: ' + contract)
    return dict(complete=True, fragments=len(names), payloadSha256=digest(raw),
                maintainedInventories=1, publicHeaders=1,
                configurationOwner='config.status', publicationOwner='include/makefile',
                runtimeSemanticsChanged=False)


def validate(root, baseline):
    root = Path(root)
    names, actual = reconstruct(root)
    if actual != baseline:
        raise ValueError('header source partition changes the baseline bytes')
    target = 'include/gambit.h:' + ':'.join('include/' + name for name in names)
    for name in ('configure.ac', 'configure', 'include/makefile.in'):
        text = (root / name).read_text()
        if target not in text:
            raise ValueError('header publication inventory differs: ' + name)
    make = (root / 'include/makefile.in').read_text()
    listed = re.search(r'HEADER_TEMPLATES = (.*?)\nHEADER_CONFIG', make, re.S)
    if not listed or listed[1].replace('\\\n', '').split() != names:
        raise ValueError('header dependency inventory differs')
    if re.search(r'#include "_gambit/', actual.decode()):
        raise ValueError('installed header must not require private fragments')
    return dict(complete=True, fragments=len(names), bytes=len(actual),
                lines=len(actual.splitlines()), baselineSha256=digest(baseline),
                reconstructedSha256=digest(actual), manifestLines=len(names),
                runtimeSemanticsChanged=False)


def submission_contract(submission, changed):
    """Admit only the complete lossless representation cut, never header semantics.

    An organization unit has no runtime integration credit. Its exact payload
    equality is checked from Git and the qualified workspace, not a JSON claim.
    """
    if submission.native.get('qualificationKind') != 'header-organization':
        raise ValueError('source-bound header qualification required')
    before = submission.git('show', submission.base + ':include/gambit.h.in')
    observation = validate(submission.workspace, before)
    names = manifest((submission.workspace/'include/gambit.h.in').read_bytes())
    required = {'include/gambit.h.in', 'configure.ac', 'configure',
                'include/makefile.in', 'misc/change-gvm-regs', 'misc/changev',
                'misc/configure-vstudio.js'}
    required.update('include/' + name for name in names)
    required.update('misc/' + name + '.bat' for name in
                    ('vstudio', 'vcexpress', 'vc2012', 'openwatcom', 'vc2008', 'vctoolkit'))
    if set(changed) != required:
        raise ValueError('organization must replace the complete header consumer cut')
    if (submission.native.get('configuredHeaderEqual') is not True or
            submission.native.get('installation', {}).get('complete') is not True or
            submission.native.get('partition') != observation):
        raise ValueError('matching generation/installation/refinement receipt required')
    return observation
