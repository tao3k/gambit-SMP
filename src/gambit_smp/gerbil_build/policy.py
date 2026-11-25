"""Gerbil build: policy."""

from gambit_smp.framework import digest, relative, available_processors


CI_ENVIRONMENT_KEYS=frozenset({'PATH','SDKROOT','CFLAGS','LDFLAGS','PKG_CONFIG_PATH','GERBIL_BUILD_CORES'})
STAGES = ('boot-gxi', 'stage0', 'stage1', 'stdlib', 'libgerbil', 'lang', 'tools')
def _compiler_jobs(env):
    """Honor the caller's explicit worker budget without changing VM options."""
    requested = env.get('GERBIL_BUILD_CORES')
    if requested is None:
        return max(1, (available_processors() - 1) // 2)
    if not isinstance(requested, str) or not requested.isascii() or not requested.isdecimal() or int(requested) < 1:
        raise ValueError('GERBIL_BUILD_CORES must be a positive integer')
    return int(requested)


def _native_jobs(value):
    """A separate CPU schedule is meaningful only after the producer drains."""
    if value is not None and (type(value) is not int or not 1 <= value <= available_processors()):
        raise ValueError('stdlibNativeJobs must fit the available CPU capacity')
    return value


def _batch_size(value):
    if value is not None and (type(value) is not int or not 1 <= value <= 128):
        raise ValueError('stdlibBatchSize must be an integer from 1 through 128')
    return value


def _through_stage(value):
    if value not in ('stage1', 'stdlib', 'tools'):
        raise ValueError('throughStage must select stage1, stdlib or tools')
    return value


def _bootstrap_release(value):
    """An official release seed is a build-host input, never a target profile."""
    if value is None:
        return None
    from gambit_smp.native_capabilities import fields
    import re
    fields(value, ('repository', 'tag', 'revision'))
    if (value['repository'] != 'https://github.com/gambit/gambit.git'
            or not re.fullmatch(r'v[0-9]+\.[0-9]+\.[0-9]+', value['tag'])
            or not re.fullmatch('[0-9a-f]{40}', value['revision'])):
        raise ValueError('official bootstrap release requires an exact tag and commit')
    return dict(value)


def _configured_smp(features):
    import re
    enabled=bool(re.search(r'^PRELUDE_OPT\s*=.*\(define-cond-expand-feature\|enable-smp\|\)',features,re.MULTILINE))
    disabled=bool(re.search(r'^PRELUDE_OPT\s*=.*\(define-cond-expand-feature\|disable-smp\|\)',features,re.MULTILINE))
    return enabled if enabled != disabled else None


def _runtime_profile(value=None):
    from gambit_smp.native_capabilities import fields
    if value is None:
        value=dict(multipleThreadedVms=True,multipleVms=True,smp=True)
    fields(value,('multipleThreadedVms','multipleVms','smp'))
    if any(type(v) is not bool for v in value.values()):
        raise ValueError('runtime profile requires explicit boolean capabilities')
    return dict(value)


def _admit_runtime_profile(policy, expected):
    if policy and policy.get('runtimeMode') == 'build-concurrency' and any(expected.values()):
        raise ValueError('SysML build-concurrency scope does not admit SMP or multiple VM profiles')
