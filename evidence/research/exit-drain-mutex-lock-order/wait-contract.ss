;;; Source-bound observations, not a deadlock detector or an action planner.
(define-evidence (make-scheduler-wait-evidence)
  (sources question wait_observation owner_observation phase_observation
    required_participant participation coherent_sample held_lock held_inventory
    cohort_observation stress_observation retirement_question retirement_boundary retirement_census retirement_coherence)
  (outputs correlated_wait held_context pending_participation missing evidence_requirement model_reference
    retirement_applicability conditional_retirement_hazard
    cohort_returned cohort_blocked false_cohort_pass)
  (relation question ((id string?)))
  (relation wait_observation ((id string?) (producer string?) (sample string?)
    (lock string?) (waiter string?) (owner string?) (epoch exact-integer?)))
  (relation owner_observation ((producer string?) (sample string?)
    (lock string?) (owner string?) (method string?)))
  (relation phase_observation ((producer string?) (sample string?)
    (owner string?) (epoch exact-integer?) (phase string?)))
  (relation required_participant ((producer string?) (sample string?)
    (epoch exact-integer?) (processor string?)))
  (relation participation ((producer string?) (sample string?)
    (epoch exact-integer?) (processor string?)))
  ;; The host must bind this to a real observation boundary and provenance.
  ;; Merely choosing the same sample label is not a coherence witness.
  (relation coherent_sample ((producer string?) (sample string?) (witness string?)))
  (relation held_lock ((producer string?) (sample string?) (processor string?)
    (lock string?) (kind string?)))
  ;; A witnessed zero count is valid; an absent inventory is unknown.
  (relation held_inventory ((producer string?) (sample string?) (processor string?)
    (count exact-integer?) (witness string?)))
  (relation held_count (producer sample processor count))
  (relation complete_inventory (producer sample processor))
  (relation bad_inventory (producer sample processor))
  (relation caller_inventory (id))
  (relation owner_inventory (id))
  (relation has_wait (id))
  (relation has_owner (id))
  (relation has_phase (id))
  (relation has_coherence (id))
  (relation ambiguous_wait (id))
  (relation conflicting_owner (producer sample lock))
  (relation correlated_wait (id producer sample lock waiter owner epoch phase))
  (relation held_context (id processor lock kind))
  (relation pending_participation (id epoch waiter))
  (relation missing (id obligation))
  (relation evidence_requirement (obligation description))
  (relation model_reference (obligation path))
  ;; Controlled request identities. Ticket counters are not holders.
  ;; gc_return 0 with a pass label is a false pass. A timeout with request 1
  ;; and return 0 stays an open failure. A control return does not close it.
  (relation cohort_observation ((producer string?) (mode string?) (thread_owner string?)
    (condvar_owner string?) (waiter string?) (gc_request exact-integer?)
    (gc_return exact-integer?) (outcome string?) (witness string?)))
  (relation cohort_returned (producer mode))
  (relation cohort_blocked (producer mode))
  (relation false_cohort_pass (producer mode))
  ((has_wait I) <-- (wait_observation I _ _ _ _ _ _))
  ((has_owner I) <-- (wait_observation I P S L W O E)
    (owner_observation P S L O Method))
  ((has_phase I) <-- (wait_observation I P S L W O E)
    (phase_observation P S O E Phase))
  ((has_coherence I) <-- (wait_observation I P S L W O E)
    (coherent_sample P S Witness))
  ((ambiguous_wait I) <-- (wait_observation I P S L W O E)
    (wait_observation I P2 S2 L2 W2 O2 E2)
    (if (P S L W O E P2 S2 L2 W2 O2 E2)
      (or (not (equal? P P2)) (not (equal? S S2)) (not (equal? L L2))
          (not (equal? W W2)) (not (equal? O O2)) (not (= E E2)))))
  ((conflicting_owner P S L) <-- (owner_observation P S L O Method)
    (owner_observation P S L Other OtherMethod)
    (if (O Other) (not (equal? O Other))))
  ((held_count P S A N) <-- (held_inventory P S A _ _)
    (aggregate N gerbil-ascent-count () (held_lock P S A L Kind)))
  ((bad_inventory P S A) <-- (held_inventory P S A Declared Witness)
    (held_count P S A Actual) (if (Declared Actual) (not (= Declared Actual))))
  ((complete_inventory P S A) <-- (held_inventory P S A N Witness)
    (held_count P S A N) (not (bad_inventory P S A)))
  ((caller_inventory I) <-- (wait_observation I P S L W O E) (complete_inventory P S W))
  ((owner_inventory I) <-- (wait_observation I P S L W O E)
    (complete_inventory P S O) (held_lock P S O L Kind))
  ((missing I (lit "wait-identity")) <-- (question I) (not (has_wait I)))
  ((missing I (lit "actual-owner")) <-- (question I) (not (has_owner I)))
  ((missing I (lit "same-generation-gc-phase")) <-- (question I) (not (has_phase I)))
  ((missing I (lit "coherent-observation-boundary")) <-- (question I) (not (has_coherence I)))
  ((missing I (lit "caller-held-lock-inventory")) <-- (question I) (not (caller_inventory I)))
  ((missing I (lit "owner-held-lock-inventory")) <-- (question I) (not (owner_inventory I)))
  ((missing I (lit "ambiguous-wait-identity")) <-- (question I) (ambiguous_wait I))
  ((missing I (lit "conflicting-holder-observations")) <-- (question I)
    (wait_observation I P S L W O E) (conflicting_owner P S L))
  ((correlated_wait I P S L W O E Phase) <-- (question I)
    (wait_observation I P S L W O E) (owner_observation P S L O Method)
    (phase_observation P S O E Phase) (coherent_sample P S Witness)
    (complete_inventory P S W) (complete_inventory P S O) (held_lock P S O L Kind)
    (not (ambiguous_wait I)) (not (conflicting_owner P S L)))
  ((held_context I A Lock Kind) <-- (correlated_wait I P S L W O E Phase)
    (held_lock P S A Lock Kind) (if (A W O) (or (equal? A W) (equal? A O))))
  ;; A published participant obligation without an observed acknowledgement is
  ;; pending evidence, not proof that the processor cannot run or is deadlocked.
  ((pending_participation I E W) <--
    (correlated_wait I P S L W O E (lit "collective-await"))
    (required_participant P S E W) (not (participation P S E W)))
  (fact (evidence_requirement "actual-owner"
    "Identify the low-level lock holder; logical Scheme mutex ownership alone is insufficient."))
  (fact (evidence_requirement "same-generation-gc-phase"
    "Separate request publication, participant acknowledgement, mark work, termination and post-GC callbacks."))
  (fact (evidence_requirement "coherent-observation-boundary"
    "Bind producer, lock identity, owner and GC epoch to a justified observation boundary; account for observer perturbation."))
  (fact (evidence_requirement "root-and-revalidation"
    "A returning collective must preserve live roots and lock metadata; reload moved arguments and revalidate termination state."))
  (fact (evidence_requirement "error-disposition"
    "A failed collective must not return success or reclaim a still-owned frame or runtime resource."))
  (fact (model_reference "root-and-revalidation" "models/gambit/scheduler_lock_moving_root.qnt"))
  (fact (model_reference "same-generation-gc-phase" "models/gambit/scheduler_retry_gc_participation.qnt"))
  (fact (model_reference "root-and-revalidation" "models/gambit/scheduler_wait_gc_contract.qnt"))
  (fact (model_reference "error-disposition" "models/gambit/scheduler_wait_gc_contract.qnt"))
  ;; Producer-level classifications are not question obligations. A request,
  ;; return and outcome tuple does not by itself attach a case, prove deadlock,
  ;; or say anything about original TFIB.
  ((cohort_returned P M) <--
    (cohort_observation P M T C W R G (lit "returned") Witness)
    (if (R G) (and (= R 1) (= G 1))))
  ((cohort_blocked P M) <--
    (cohort_observation P M T C W R G (lit "timeout") Witness)
    (if (R G) (and (= R 1) (= G 0))))
  ((false_cohort_pass P M) <--
    (cohort_observation P M T C W R G Outcome Witness)
    (if (G Outcome) (and (= G 0) (equal? Outcome (lit "pass")))))
  ;; Same question id, same producer, and the same coherent-sample witness.
  ;; Another question or producer stays outside this case.
  ((missing I (lit "false-cohort-pass")) <--
    (question I)
    (wait_observation I P S _ _ _ _)
    (coherent_sample P S Witness)
    (cohort_observation P M _ _ _ R G (lit "pass") Witness)
    (if (G) (= G 0)))
  ((missing I (lit "retained-lock-not-returned")) <--
    (question I)
    (wait_observation I P S _ _ _ _)
    (coherent_sample P S Witness)
    (cohort_observation P (lit "retained-lock") _ _ _ R G (lit "timeout") Witness)
    (if (R G) (and (= R 1) (= G 0))))
  (fact (evidence_requirement "retained-lock-not-returned"
    "For this question, producer and observation witness only: a retained thread lock with GC request 1 and return 0 is an open cohort failure. It is not a deadlock verdict, not original TFIB causality, and not a ticket-inferred holder. A return on another producer or question does not close it."))
  (fact (evidence_requirement "false-cohort-pass"
    "For this question, producer and observation witness only: a pass label with GC return 0 is not a cohort return."))
  (fact (model_reference "retained-lock-not-returned" "models/gambit/scheduler_wait_gc_contract.qnt"))
  ;; Native stress rows stay on their own producer and witness. A returned
  ;; cohort, including one with the same producer name, does not close them.
  (relation stress_observation ((producer string?) (program string?)
    (status_hi exact-integer?) (status_lo exact-integer?) (outcome string?)
    (witness string?)))
  (relation stress_failed (producer program outcome))
  (relation cohort_leaves_stress_open (cohort_producer mode stress_producer program))
  ((stress_failed P Program Outcome) <--
    (stress_observation P Program Hi Lo Outcome Witness)
    (if (Hi Lo Outcome)
      (or (and (= Hi 0) (> Lo 0) (equal? Outcome (lit "signal")))
          (and (= Hi 70) (= Lo 0) (equal? Outcome (lit "software-exit")))
          (and (equal? Outcome (lit "inactive"))))))
  ((cohort_leaves_stress_open CP M SP Program) <--
    (cohort_observation CP M _ _ _ R G (lit "returned") _)
    (stress_failed SP Program Outcome)
    (if (R G) (and (= R 1) (= G 1))))
  ((missing I (lit "stress-not-closed-by-cohort")) <--
    (question I)
    (wait_observation I P S _ _ _ _)
    (coherent_sample P S Witness)
    (stress_observation P Program _ _ Outcome Witness)
    (stress_failed P Program Outcome))
  (fact (evidence_requirement "stress-not-closed-by-cohort"
    "For this question, producer and observation witness only: signal status HI=0 and LO>0, software exit HI=70 LO=0, or an inactivity outcome stays open. Printed heap overflow is that software-exit shape on its own program. A returned controlled cohort does not close it and is not original TFIB causality. The retained suite boundaries are cumulative and do not establish a startup crash."))
  (fact (model_reference "stress-not-closed-by-cohort" "models/gambit/scheduler_wait_gc_contract.qnt"))
  ;; run-tests stamps show-bar after each file, from one start-time.
  ;; The filename on a bar line is the next file, not a duration of zero.
  (fact (evidence_requirement "suite-clock-is-cumulative"
    "For the retained participation stress log only: run-tests initializes start-time once, prints the 0.0s bar before tfib_stress.scm, and show-bar runs after that file. The 127.4s bar is the cumulative boundary after signal 10. The 127.5s bar is the cumulative boundary after thread_interrupt2_stress.scm software exit 70. These are rounded suite boundaries, about 127.4 seconds then about 0.1 seconds, not per-child timers and not a startup crash."))
  (fact (model_reference "suite-clock-is-cumulative" "vendor/gambit/tests/run-unit-tests.scm"))
  (fact (evidence_requirement "direct-go-not-suite-boundary"
    "For tfib-join-duration-1 only: a direct gsi of the same (go 15 5000) body printed TFIB-5000-START and was still running when the 200-second cap killed it. Exit -9, seconds 200.0209407910006, stderr empty. That does not reproduce the suite signal 10, does not make 127.4 seconds a deterministic crash time, and is not original TFIB acceptance."))
  (fact (model_reference "direct-go-not-suite-boundary" "models/gambit/native/tfib_join_duration.scm"))
  ;; Published retirement research is a different protocol. Do not copy it
  ;; and do not treat its timeouts as this producer's TFIB cause.
  (fact (evidence_requirement "scheme-join-is-not-os-retirement"
    "Scheme thread-join! on an end-condvar is not OS pthread join and is not processor retirement. The published last-consumer classes distinguish retained bytes from scanner-visible roots, a joined OS thread from transferred memory, and an empty queue from a finished producer. No retained trace shows the current TFIB failure entered resize, retirement, or an allocating release callback. Those documents do not assign this signal."))
  (fact (model_reference "scheme-join-is-not-os-retirement" "docs/smp-retirement-research-index.md"))
  (fact (model_reference "scheme-join-is-not-os-retirement" "models/gambit/retirement_last_consumers.qnt"))
  (fact (model_reference "scheme-join-is-not-os-retirement" "models/gambit/retirement_pre_exit.qnt"))
  ;; Evidence is scoped to one execution interval, not a Scheme thread identity.
  ;; The host supplies an actual coherence/census witness, never a guessed label.
  (relation retirement_question ((id string?) (producer string?) (execution string?) (interval string?)))
  (relation retirement_boundary ((producer string?) (execution string?) (interval string?)
    (event string?) (witness string?)))
  (relation retirement_census ((producer string?) (execution string?) (interval string?)
    (entries exact-integer?) (witness string?)))
  (relation retirement_coherence ((producer string?) (execution string?) (interval string?) (witness string?)))
  (relation retirement_entered (id))
  (relation retirement_excluded (id))
  (relation retirement_conflict (id))
  (relation retirement_applicability (id status))
  (relation conditional_retirement_hazard (id))
  ((retirement_entered I) <-- (retirement_question I P Run Span)
    (retirement_coherence P Run Span Witness)
    (retirement_boundary P Run Span (lit "entered") Witness))
  ((retirement_conflict I) <-- (retirement_question I P Run Span)
    (retirement_entered I) (retirement_coherence P Run Span Witness)
    (retirement_census P Run Span 0 Witness))
  ((retirement_excluded I) <-- (retirement_question I P Run Span)
    (retirement_coherence P Run Span Witness) (retirement_census P Run Span 0 Witness)
    (not (retirement_entered I)))
  ((retirement_applicability I (lit "entered")) <--
    (retirement_entered I) (not (retirement_conflict I)))
  ((retirement_applicability I (lit "excluded-in-interval")) <-- (retirement_excluded I))
  ((retirement_applicability I (lit "conflicting-witnesses")) <-- (retirement_conflict I))
  ((retirement_applicability I (lit "unknown")) <-- (retirement_question I _ _ _)
    (not (retirement_entered I)) (not (retirement_excluded I)))
  ;; Only establishes that the conditional protocol counterexample applies to
  ;; this observed interval. It is NOT a causal verdict for signal 10 or join 70.
  ((conditional_retirement_hazard I) <-- (retirement_question I P Run Span)
    (retirement_applicability I (lit "entered"))
    (retirement_coherence P Run Span Witness)
    (retirement_boundary P Run Span (lit "entered") Witness)
    (retirement_boundary P Run Span (lit "callback-gc") Witness)
    (retirement_boundary P Run Span (lit "withdrawn-or-joining-wait-cycle") Witness))
  (fact (evidence_requirement "retirement-activation-correspondence"
    "Bind actual processor retirement, callback GC and the waiting cohort to the same producer, execution and witnessed interval. Scheme thread-join!, signal 10, software exit 70 and inactivity do not supply those events. Only a complete interval census can exclude entry. A model path establishes a conditional hazard, not native fault causality."))
  (fact (model_reference "retirement-activation-correspondence" "models/gambit/tfib_retirement_correspondence.qnt")))
