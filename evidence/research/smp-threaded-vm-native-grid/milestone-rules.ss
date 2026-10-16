;;; Coverage obligations only; checked execution is not source refinement.
;;; These names bind future stages to the existing observation graph, not to
;;; historical package timings or unrelated finite-model checks.
(ascent-fragment
  (relation grid_required ((stage symbol?) (capability symbol?)))
  (relation grid_checked ((stage symbol?)))
  (relation milestone_open ((stage symbol?)))
  ((grid_required (lit 'pr-regressions-gsi) (lit 'gambit.suite)) <--
    (required_step (lit 'independent-vms)))
  ((grid_required (lit 'pr-regressions-gsc) (lit 'gambit.suite)) <--
    (required_step (lit 'independent-vms)))
  ((grid_required (lit 'stress-gsi) (lit 'gambit.suite)) <--
    (required_step (lit 'independent-vms)))
  ((grid_required (lit 'stress-gsc) (lit 'gambit.suite)) <--
    (required_step (lit 'independent-vms)))
  ((grid_required (lit 'registry-lifetime-native) (lit 'gambit.executable-test)) <--
    (required_step (lit 'independent-vms)))
  ((grid_required (lit 'lifecycle-faults-native) (lit 'gambit.executable-test)) <--
    (required_step (lit 'independent-vms)))
  ((grid_required (lit 'gc-ffi-native) (lit 'gambit.executable-test)) <--
    (required_step (lit 'independent-vms)))
  ((grid_required (lit 'gerbil-correctness) (lit 'native.test)) <--
    (required_step (lit 'independent-vms)))
  ((grid_required (lit 'release-performance) (lit 'native.test)) <--
    (required_step (lit 'independent-vms)))
  ((grid_checked S) <-- (grid_required S C) (observed_step S (lit 'PASS) C))
  ((milestone_open S) <-- (grid_required S C) (not (grid_checked S))))
