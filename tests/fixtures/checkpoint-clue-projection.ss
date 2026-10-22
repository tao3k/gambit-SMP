;; Test projection over the real host observations; no navigation policy.
(define-evidence (project-checkpoint)
  (sources requirement dependency contract receipt verified
           support_declaration support_witness required_command
           binding required_binding current_binding command command_observation
           prerequisite quiescent material available withdrawn
           required_step recorded_failure campaign_pass receipt_checked
           output_retained execution_quiescent campaign_required campaign_enumerated
           execution_location execution_process execution_end execution_sample execution_custody)
  (outputs clue factor link)
  (include evidence-checkpoint-fragment)
  (include execution-observation-fragment)
  (fact (completed_outcome (lit "PASS")))
  (relation required_step (step))
  (relation recorded_failure (step outcome))
  (relation campaign_pass ())
  (relation receipt_checked ())
  (relation output_retained (step))
  (relation execution_quiescent ())
  (relation campaign_required (step))
  (relation campaign_enumerated ())
  (relation clue (id digest claim polarity role source))
  (relation factor (id digest name value))
  (relation link (claim target label id digest))
  ((clue E E R (lit "support") (lit "observation") E) <--
    (receipt E R C _) (applicable R E))
  ((clue E E R (lit "counter") (lit "observation") E) <--
    (receipt E R C _) (enumeration_gap E Reason))
  ((factor E C (lit "requirement") R) <-- (clue E C R _ _ _))
  ((clue Ref Ref S (lit "support") (lit "observation") Ref) <--
    (execution_frontier S _ _ _ Ref))
  ((factor Ref Ref (lit "observation-kind") (lit "completed-work-not-native-PASS")) <--
    (execution_frontier _ _ _ _ Ref))
  ((link R D (lit "declaration") E E) <--
    (receipt E R C _) (clue E _ R _ _ _) (support_declaration R C _ D _ _ _ _)))

(define-evidence (select-checkpoint)
  (sources clue factor binding)
  (outputs question)
  (relation clue (id digest claim polarity role source))
  (relation factor (id digest name value))
  (relation binding (name value))
  (relation question (claim))
  ((question R) <-- (clue E D R _ _ _) (factor E D N V) (binding N V)))
