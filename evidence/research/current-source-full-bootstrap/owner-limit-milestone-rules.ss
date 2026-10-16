;;; Twelve current-producer obligations. Absence remains open. Finite model
;;; observations never qualify a native gate. Other campaigns need their own
;;; complete, source-bound execution receipts before contributing here.
;;; This asset is scoped to the two owner-limit stress Recipes: each suite
;;; declares all four unchanged files, whole-parallel mode, and the same
;;; completed source producer. gambit.suite checks exact native completion.
(ascent-fragment
  (relation milestone_required ((gate symbol?)))
  (relation milestone_checked ((gate symbol?)))
  (relation milestone_open ((gate symbol?)))
  ((milestone_required (lit 'bootstrap)) <-- (required_step (lit 'producer)))
  ((milestone_required (lit 'complete-gsi)) <-- (required_step (lit 'producer)))
  ((milestone_required (lit 'pr-regressions-gsi)) <-- (required_step (lit 'producer)))
  ((milestone_required (lit 'complete-gsc)) <-- (required_step (lit 'producer)))
  ((milestone_required (lit 'pr-regressions-gsc)) <-- (required_step (lit 'producer)))
  ((milestone_required (lit 'stress-gsi)) <-- (required_step (lit 'producer)))
  ((milestone_required (lit 'stress-gsc)) <-- (required_step (lit 'producer)))
  ((milestone_required (lit 'registry-lifetime)) <-- (required_step (lit 'producer)))
  ((milestone_required (lit 'lifecycle-faults)) <-- (required_step (lit 'producer)))
  ((milestone_required (lit 'gc-ffi)) <-- (required_step (lit 'producer)))
  ((milestone_required (lit 'gerbil-correctness)) <-- (required_step (lit 'producer)))
  ((milestone_required (lit 'release-performance)) <-- (required_step (lit 'producer)))
  ((milestone_checked (lit 'bootstrap)) <--
    (observed_step (lit 'producer) (lit 'PASS) (lit 'gambit.completed-runtime)))
  ((milestone_checked (lit 'stress-gsi)) <--
    (observed_step (lit 'stress-gsi) (lit 'PASS) (lit 'gambit.suite)))
  ((milestone_checked (lit 'stress-gsc)) <--
    (observed_step (lit 'stress-gsc) (lit 'PASS) (lit 'gambit.suite)))
  ((milestone_open G) <-- (milestone_required G) (not (milestone_checked G))))
