----------------------- MODULE handler_admission_window -----------------------

EXTENDS Integers, Sequences, FiniteSets, TLC, Apalache, Variants

VARIABLE
  (*
    @type: { admitted: Bool, cReaders: Int, crossed: Bool, deliveryEpoch: Int, reopened: Bool, requireOsDrain: Bool, stage: Int };
  *)
  h

(*
  @type: ((Bool) => { admitted: Bool, cReaders: Int, crossed: Bool, deliveryEpoch: Int, reopened: Bool, requireOsDrain: Bool, stage: Int });
*)
initial(required_31) ==
  [requireOsDrain |-> required_31,
    stage |-> 0,
    cReaders |-> 0,
    deliveryEpoch |-> 1,
    crossed |-> FALSE,
    admitted |-> FALSE,
    reopened |-> FALSE]

VARIABLE
  (*
    @type: { cleaned: Bool, control: Int, cross: Bool, detached: Bool, done: Bool, entered: Bool, epoch: Int, failed: Bool, hostQuiet: Bool, joinable: Bool, oldHandler: Bool, pending: Int, phase: Int, sealed: Bool };
  *)
  G_s

(*
  @type: ((Int) => { cleaned: Bool, control: Int, cross: Bool, detached: Bool, done: Bool, entered: Bool, epoch: Int, failed: Bool, hostQuiet: Bool, joinable: Bool, oldHandler: Bool, pending: Int, phase: Int, sealed: Bool });
*)
G_initial(G_c_505) ==
  [phase |-> 0,
    pending |-> IF G_c_505 >= 2 THEN 0 ELSE 1,
    joinable |-> G_c_505 = 0,
    detached |-> G_c_505 = 1,
    failed |-> FALSE,
    cleaned |-> FALSE,
    epoch |-> 1,
    oldHandler |-> G_c_505 >= 2,
    hostQuiet |-> G_c_505 = 3,
    sealed |-> FALSE,
    entered |-> FALSE,
    cross |-> FALSE,
    done |-> FALSE,
    control |-> G_c_505]

(*
  @type: (() => Bool);
*)
G_enterCross ==
  G_s["phase"] = 4
    /\ G_s["epoch"] = 2
    /\ G_s["oldHandler"]
    /\ ~(G_s["hostQuiet"])
    /\ G_s'
      := [
        [
          [ [ G_s EXCEPT !["phase"] = 5 ] EXCEPT !["entered"] = TRUE ] EXCEPT
            !["cross"] = TRUE
        ] EXCEPT
          !["done"] = TRUE
      ]

(*
  @type: (() => Bool);
*)
returnInvocation ==
  (h["stage"] = 2 \/ h["stage"] = 4)
    /\ G_s'
      := [ [ G_s EXCEPT !["oldHandler"] = FALSE ] EXCEPT !["hostQuiet"] = TRUE ]
    /\ h' := [ [ h EXCEPT !["stage"] = 3 ] EXCEPT !["cReaders"] = 0 ]

(*
  @type: (() => Bool);
*)
reopen ==
  G_s["phase"] = 3
    /\ h["cReaders"] = 0
    /\ ~(h["reopened"])
    /\ (~(h["requireOsDrain"]) \/ h["stage"] = 3)
    /\ G_s'
      := [
        [ [ G_s EXCEPT !["phase"] = 4 ] EXCEPT !["epoch"] = 2 ] EXCEPT
          !["sealed"] = FALSE
      ]
    /\ h' := [ h EXCEPT !["reopened"] = TRUE ]

(*
  @type: (() => Bool);
*)
noCross == ~(h["crossed"])

(*
  @type: (() => Bool);
*)
noCompletedDrain == ~((h["requireOsDrain"] /\ h["reopened"]) /\ h["stage"] = 3)

(*
  @type: (() => Bool);
*)
counterAccurate ==
  h["cReaders"] = (IF h["stage"] = 1 \/ h["stage"] = 2 THEN 1 ELSE 0)

(*
  @type: (() => Bool);
*)
noPostReleaseTail == h["stage"] /= 4

(*
  @type: (() => Bool);
*)
tailHasNoCountedLease == h["stage"] /= 4 \/ h["cReaders"] = 0

(*
  @type: (() => Bool);
*)
initCounter == G_s = G_initial(2) /\ h = initial(FALSE)

(*
  @type: (() => Bool);
*)
initDrain == G_s' := (G_initial(2)) /\ h' := (initial(TRUE))

(*
  @type: (() => Bool);
*)
keepGeneration == G_s' := G_s

(*
  @type: (() => Bool);
*)
G_sealAdmitted ==
  G_s["phase"] = 0
    /\ (G_s["control"] = 2 \/ G_s["control"] = 3)
    /\ G_s["pending"] = 0
    /\ G_s["oldHandler"]
    /\ G_s' := [ [ G_s EXCEPT !["phase"] = 3 ] EXCEPT !["sealed"] = TRUE ]

(*
  @type: (() => Bool);
*)
admitNewGeneration ==
  h["stage"] = 1
    /\ G_s["phase"] = 4
    /\ G_enterCross
    /\ h'
      := [
        [ [ h EXCEPT !["stage"] = 2 ] EXCEPT !["admitted"] = TRUE ] EXCEPT
          !["crossed"] = h["deliveryEpoch"] /= G_s["epoch"]
      ]

(*
  @type: (() => Bool);
*)
seal == G_s["phase"] = 0/\ h["stage"] = 0/\ G_sealAdmitted/\ h' := h

(*
  @type: (() => Bool);
*)
rejectSealed ==
  h["stage"] = 1
    /\ G_s["phase"] = 3
    /\ keepGeneration
    /\ h' := [ h EXCEPT !["stage"] = 2 ]

(*
  @type: (() => Bool);
*)
releaseCensus ==
  h["stage"] = 2
    /\ h["admitted"]
    /\ h["cReaders"] = 1
    /\ keepGeneration
    /\ h' := [ [ h EXCEPT !["stage"] = 4 ] EXCEPT !["cReaders"] = 0 ]

(*
  @type: (() => Bool);
*)
finish == h["reopened"]/\ h["stage"] = 3/\ keepGeneration/\ h' := h

(*
  @type: (() => Bool);
*)
drainSafe ==
  ~(h["requireOsDrain"]) \/ (noCross /\ (~(h["reopened"]) \/ h["stage"] = 3))

(*
  @type: (() => Bool);
*)
firstCInstruction ==
  G_s["phase"] >= 3
    /\ h["stage"] = 0
    /\ keepGeneration
    /\ h' := [ [ h EXCEPT !["stage"] = 1 ] EXCEPT !["cReaders"] = 1 ]

(*
  @type: (() => Bool);
*)
q_init == initCounter

(*
  @type: (() => Bool);
*)
q_inv == tailHasNoCountedLease

(*
  @type: (() => Bool);
*)
step ==
  seal
    \/ firstCInstruction
    \/ admitNewGeneration
    \/ rejectSealed
    \/ releaseCensus
    \/ returnInvocation
    \/ reopen
    \/ finish

(*
  @type: (() => Bool);
*)
progress == WF_{<<G_s, h>>}(step) => <>(h["reopened"] /\ h["stage"] = 3)

(*
  @type: (() => Bool);
*)
q_step == step

(*
  @type: (() => Bool);
*)
q_temporalProps == progress

================================================================================
