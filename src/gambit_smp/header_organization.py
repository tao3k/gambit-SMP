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
