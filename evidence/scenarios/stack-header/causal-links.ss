;;; Similar frame tags under different locks are clues, not shared causality.
(define-evidence (make-causal-links)
  (sources focus candidate probe refuted requirement resolved source)
  (outputs shared_tag_zero_distinct_base_lock historical_refutation unresolved
           established_diagnostic observed_stage)
  (explain (lambda (program result query scope)
    (hash ("status" "recorded-only") ("dependencies" (.ref program 'rules))
      ("gap" "A matching zero return tag at different offsets does not identify a shared first writer, equal source, native acceptance, or a repair."))))
  (relation focus ((candidate string?)))
  (relation candidate ((id string?) (base_source_lock string?) (scope string?)))
  (relation probe ((candidate string?) (stage string?) (below_break_bytes exact-integer?)
                   (ra_tag exact-integer?) (frame_words exact-integer?)
                   (outcome string?) (source_id string?)))
  (relation refuted ((candidate string?) (mechanism string?) (source_id string?)))
  (relation requirement ((candidate string?) (premise string?)))
  (relation resolved ((candidate string?) (premise string?) (source_id string?)))
  (relation source ((id string?) (path string?) (sha string?)))
  (relation shared_tag_zero_distinct_base_lock
    (current prior current_below_break_bytes prior_below_break_bytes ra_tag
             current_frame_words prior_frame_words current_scope prior_scope
             current_path current_sha prior_path prior_sha))
  (relation historical_refutation (current prior mechanism path sha))
  (relation unresolved (candidate premise))
  (relation established_diagnostic (candidate premise scope path sha))
  (relation observed_stage (candidate scope stage below_break_bytes ra_tag frame_words outcome path sha))
  ((shared_tag_zero_distinct_base_lock C P COffset POffset 0 CWords PWords CScope PScope CP CH PP PH) <--
    (focus C) (candidate C CL CScope) (candidate P PL PScope)
    (probe C _ COffset 0 CWords _ CS) (probe P _ POffset 0 PWords _ PS)
    (source CS CP CH) (source PS PP PH)
    (if (C P CL PL) (and (not (string=? C P)) (not (string=? CL PL)))))
  ((historical_refutation C P Mechanism Path Sha) <--
    (shared_tag_zero_distinct_base_lock C P _ _ _ _ _ _ _ _ _ _ _)
    (refuted P Mechanism S) (source S Path Sha))
  ((unresolved C R) <-- (focus C) (requirement C R) (not (resolved C R _)))
  ((established_diagnostic C R Scope Path Sha) <--
    (focus C) (candidate C _ Scope) (requirement C R)
    (resolved C R S) (source S Path Sha))
  ((observed_stage C Scope Stage Offset Tag Words Outcome Path Sha) <--
    (candidate C _ Scope) (probe C Stage Offset Tag Words Outcome S) (source S Path Sha)))
