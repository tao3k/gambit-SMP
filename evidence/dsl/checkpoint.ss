;; One shared projection for checkpoint inspection and Clue composition.
(def execution-observation-fragment
 (ascent-fragment
  ;; Transport/liveness and completed-work observations never grant a PASS.
  (relation execution_location (token step))
  (relation execution_process (token pid observation))
  (relation execution_end (token))
  (relation execution_sample (token count monotonic reference))
  (relation execution_older (token count))
  (relation execution_pending (step token pid observation))
  (relation execution_frontier (step token count monotonic reference))
  (relation execution_unattributed (token pid observation))
  (relation execution_custody (provider state reference))
  (relation execution_detached (step provider state reference))
  ((execution_pending S T P O) <-- (execution_location T S)
    (execution_process T P O) (not (execution_end T))
    (if (O) (or (equal? O "present") (equal? O "present-unattributed"))))
  ((execution_unattributed T P O) <-- (execution_process T P O)
    (not (execution_location T _)) (not (execution_end T)))
  ((execution_older T N) <-- (execution_sample T N _ _)
    (execution_sample T M _ _) (if (N M) (< N M)))
  ((execution_frontier S T N At Ref) <-- (execution_location T S)
    (execution_sample T N At Ref) (not (execution_older T N)))
  ((execution_detached S Provider State Ref) <-- (execution_pending S _ _ _)
    (execution_custody Provider State Ref)
    (if (State) (or (equal? State "returned") (equal? State "interrupted"))))))

;; Domain projection composes the registered Library; it does not choose work.
(define-evidence (make-execution-transport)
  (sources transport_required transport_recorded transport_enumerated)
  (outputs transport_gap transport_current)
  (relation transport_required (key identity))
  (relation transport_recorded (key identity))
  (relation transport_enumerated ())
  (relation transport_gap (key))
  (relation transport_current ())
  ((transport_gap K) <-- (transport_required K D) (not (transport_recorded K D)))
  ((transport_current) <-- (transport_enumerated) (not (transport_gap _))))

(define-evidence (make-checkpoint-state)
  (sources requirement dependency contract receipt verified
           support_declaration support_witness required_command
           binding required_binding current_binding command command_observation
           prerequisite quiescent material available withdrawn
           required_step recorded_failure campaign_pass receipt_checked
           output_retained execution_quiescent campaign_required campaign_enumerated
           progress_contract progress_active progress_cursor progress_sample
           progress_attested progress_completed
           execution_location execution_process execution_end execution_sample execution_custody)
  (outputs historical_complete reusable support_declaration support_witness closed_support
           satisfied artifact_unavailable historical_only unresolved invalidated failed
           campaign_reusable invalidated_by binding_gap enumeration_gap unclosed material_gap completion_gap applicable consumable
           progress_frontier progress_advanced progress_rejected
           execution_pending execution_frontier execution_unattributed execution_detached
           failed_attempt_history)
  (include evidence-checkpoint-fragment)
  (include evidence-progress-fragment)
  (include execution-observation-fragment)
  (fact (completed_outcome (lit "PASS")))
  (relation required_step (step))
  (relation recorded_failure (step outcome))
  (relation campaign_pass ())
  (relation receipt_checked ())
  (relation inputs_current ())
  (relation output_retained (step))
  (relation execution_quiescent ())
  (relation completed_step (step))
  (relation satisfied (step))
  (relation artifact_unavailable (step))
  (relation historical_only (step))
  (relation unresolved (step))
  (relation invalidated (step))
  (relation failed (step outcome))
  (relation campaign_gap ())
  (relation campaign_required (step))
  (relation campaign_enumerated ())
  (relation campaign_reusable ())
  (relation inputs_current ())
  (relation consumable (step receipt))
  (relation attempt_recorded (step))
  (relation attempt_gap (step))
  (relation failed_attempt_history ())
  ((completed_step S) <-- (historical_complete S _))
  ((inputs_current) <-- (receipt_checked) (not (binding_gap _ _)))
  ((satisfied S) <-- (applicable S _))
  ((consumable S E) <-- (reusable S E))
  ((consumable P E) <-- (consumable S Child) (prerequisite Child P E)
                        (applicable P E) (output_retained P))
  ((artifact_unavailable S) <-- (material_gap S _ _))
  ((historical_only S) <-- (completed_step S) (output_retained S)
                          (artifact_unavailable S))
  ((unresolved S) <-- (required_step S) (not (completed_step S)))
  ((invalidated S) <-- (completed_step S) (not (satisfied S)))
  ((failed S O) <-- (required_step S) (recorded_failure S O) (receipt_checked))
  ((attempt_recorded S) <-- (receipt_checked) (receipt E S _ _) (verified E))
  ((attempt_gap S) <-- (required_step S) (not (attempt_recorded S)))
  ((attempt_gap S) <-- (campaign_required S) (not (attempt_recorded S)))
  ;; Historical failure permits review of a changed attempt, never native credit.
  ((failed_attempt_history) <-- (receipt_checked) (campaign_enumerated)
    (execution_quiescent) (failed _ _) (not (attempt_gap _)))
  ((campaign_gap) <-- (required_step S) (not (satisfied S)))
  ((campaign_gap) <-- (campaign_required S) (not (satisfied S)))
  ((campaign_gap) <-- (material_gap S _ _) (not (output_retained S)))
  ((campaign_reusable) <-- (campaign_pass) (receipt_checked) (inputs_current) (campaign_enumerated)
                          (execution_quiescent) (not (campaign_gap))))
