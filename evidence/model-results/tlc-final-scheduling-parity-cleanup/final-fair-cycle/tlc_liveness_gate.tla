--------------------------- MODULE tlc_liveness_gate ---------------------------

EXTENDS Integers, Sequences, FiniteSets, TLC, Apalache, Variants

VARIABLE
  (*
    @type: { phase: Int, policy: Str };
  *)
  s

(*
  @type: (() => Bool);
*)
initTerminating == s' := [policy |-> "terminate", phase |-> 0]

(*
  @type: (() => Bool);
*)
initCycle == s = [policy |-> "cycle", phase |-> 0]

(*
  @type: (() => Bool);
*)
step ==
  s'
    := [
      s EXCEPT
        !["phase"] = IF s["policy"] = "terminate" THEN 1 ELSE 1 - s["phase"]
    ]

(*
  @type: (() => Bool);
*)
safe == s["phase"] = 0 \/ s["phase"] = 1

(*
  @type: (() => Bool);
*)
zero == s["phase"] = 0

(*
  @type: (() => Bool);
*)
progress == WF_{s}(step) => <>(s["policy"] = "terminate" /\ s["phase"] = 1)

(*
  @type: (() => Bool);
*)
q_init == initCycle

(*
  @type: (() => Bool);
*)
q_step == step

(*
  @type: (() => Bool);
*)
q_inv == safe

(*
  @type: (() => Bool);
*)
q_temporalProps == progress

================================================================================
