;;; A checked current producer decision retires obsolete accounting only.
;;; Native step failures remain subject to the complete execution rules.
(ascent-fragment
  (relation producer_decision_history ((step symbol?) (receipt string?) (outcome symbol?)))
  (relation producer_decision_current ((step symbol?) (receipt string?) (outcome symbol?)))
  (relation producer_decision_supersedes ((step symbol?) (receipt string?) (previous symbol?) (current symbol?)))
  (relation retired_producer_decision ((step symbol?) (receipt string?)))
  (relation active_historical_producer_denial ((step symbol?) (receipt string?)))
  (relation current_producer_admitted ((step symbol?)))
  ((retired_producer_decision S R) <--
    (producer_decision_history S R (lit 'DENY))
    (producer_decision_current S R (lit 'PASS))
    (producer_decision_supersedes S R
      (lit 'expired-total-wall-clock-owner-teardown)
      (lit 'completed-stages-and-reaped-owner)))
  ((active_historical_producer_denial S R) <--
    (producer_decision_history S R (lit 'DENY))
    (not (retired_producer_decision S R)))
  ((current_producer_admitted S) <--
    (retired_producer_decision S R)
    (observed_step S (lit 'PASS) (lit 'gambit.completed-runtime))))
