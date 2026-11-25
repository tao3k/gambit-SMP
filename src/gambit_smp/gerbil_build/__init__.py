"""Public Gerbil build capabilities; implementation belongs to responsibility modules."""

from gambit_smp.gerbil_build.policy import STAGES, CI_ENVIRONMENT_KEYS
from gambit_smp.gerbil_build.batches import stdlib_batch_prefixes
from gambit_smp.gerbil_build.bootstrap import validate, build
from gambit_smp.gerbil_build.owned_compiler import build_owned_compiler
from gambit_smp.gerbil_build.consumer_tests import validate_test, test
from gambit_smp.gerbil_build.frame_tests import gvm_host_witness
from gambit_smp.gerbil_build.ci_profile import build_ci_profile
from gambit_smp.gerbil_build.bootstrap_observation import observe_bazel_bootstrap
from gambit_smp.gerbil_build.bazel_build import build_bazel_compiler
from gambit_smp.gerbil_build.package import package_test_scope, execute_package
from gambit_smp.gerbil_build.sources import source_files, source_identity

__all__ = ['validate', 'stdlib_batch_prefixes', 'build', 'build_owned_compiler', 'validate_test', 'test', 'gvm_host_witness', 'build_ci_profile', 'observe_bazel_bootstrap', 'build_bazel_compiler', 'package_test_scope', 'execute_package', 'STAGES', 'CI_ENVIRONMENT_KEYS', 'source_files', 'source_identity']
