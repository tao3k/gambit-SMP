------------------------ MODULE saved_stack_last_access ------------------------

EXTENDS Integers, Sequences, FiniteSets, TLC, Apalache, Variants

VARIABLE
  (*
    @type: Int;
  *)
  rank

VARIABLE
  (*
    @type: { active: Bool, badRead: Bool, recycled: Bool, requireDrain: Bool, returned: Bool, started: Bool };
  *)
  reader

(*
  @type: ((Bool) => { active: Bool, badRead: Bool, recycled: Bool, requireDrain: Bool, returned: Bool, started: Bool });
*)
readerInitial(required_30) ==
  [requireDrain |-> required_30,
    started |-> FALSE,
    active |-> FALSE,
    returned |-> FALSE,
    recycled |-> FALSE,
    badRead |-> FALSE]

VARIABLE
  (*
    @type: { anchor: Bool, collection: Bool, cycleClosed: Bool, fault: Int, rawOrigins: Set(Str), workPending: Bool };
  *)
  g

VARIABLE
  (*
    @type: { badRead: Bool, borrowed: Bool, copied: Bool, epoch: Int, fault: Int, owner: Str, phase: Int, recycled: Bool, slotCleaned: Bool, slotReused: Bool, vmAlive: Bool };
  *)
  a

VARIABLE
  (*
    @type: { donorStorage: Bool, executing: Bool, heapFrame: Bool, policy: Str, published: Bool, released: Bool, retired: Bool, returned: Bool, saved: Bool, scanning: Bool };
  *)
  R_retirementState

(*
  @type: ((Int) => { badRead: Bool, borrowed: Bool, copied: Bool, epoch: Int, fault: Int, owner: Str, phase: Int, recycled: Bool, slotCleaned: Bool, slotReused: Bool, vmAlive: Bool });
*)
initial(fault_694) ==
  [fault |-> fault_694,
    phase |-> 0,
    owner |-> "none",
    borrowed |-> FALSE,
    slotCleaned |-> FALSE,
    slotReused |-> FALSE,
    vmAlive |-> TRUE,
    epoch |-> 0,
    copied |-> FALSE,
    recycled |-> FALSE,
    badRead |-> FALSE]

(*
  @type: ((Str) => { donorStorage: Bool, executing: Bool, heapFrame: Bool, policy: Str, published: Bool, released: Bool, retired: Bool, returned: Bool, saved: Bool, scanning: Bool });
*)
R_initial(R_policy_1254) ==
  [policy |-> R_policy_1254,
    saved |-> FALSE,
    executing |-> TRUE,
    published |-> FALSE,
    heapFrame |-> FALSE,
    donorStorage |-> TRUE,
    scanning |-> FALSE,
    retired |-> FALSE,
    released |-> FALSE,
    returned |-> FALSE]

(*
  @type: ((Int) => { anchor: Bool, collection: Bool, cycleClosed: Bool, fault: Int, rawOrigins: Set(Str), workPending: Bool });
*)
graphInitial(fault_266) ==
  [fault |-> fault_266,
    anchor |-> FALSE,
    collection |-> FALSE,
    rawOrigins |-> { "tail-link", "escaped-origin" },
    workPending |-> FALSE,
    cycleClosed |-> FALSE]

(*
  @type: (() => Bool);
*)
R_releaseStorage ==
  R_retirementState["retired"]
    /\ ~(R_retirementState["scanning"])
    /\ ~(R_retirementState["released"])
    /\ R_retirementState'
      := [
        [ R_retirementState EXCEPT !["donorStorage"] = FALSE ] EXCEPT
          !["released"] = TRUE
      ]

(*
  @type: (() => Bool);
*)
closureTerminal == a["phase"] = 7 \/ a["phase"] = 10

(*
  @type: (() => Bool);
*)
R_continuationStorageSafe ==
  (~(R_retirementState["saved"]) \/ R_retirementState["heapFrame"])
    \/ R_retirementState["donorStorage"]

(*
  @type: (() => Bool);
*)
R_exclusiveExecution ==
  ~(R_retirementState["published"]) \/ ~(R_retirementState["executing"])

(*
  @type: (() => Bool);
*)
R_scannerStorageSafe ==
  ~(R_retirementState["scanning"]) \/ R_retirementState["donorStorage"]

(*
  @type: (() => Bool);
*)
rawNeeded == a["owner"] = "thread" \/ a["owner"] = "break"

(*
  @type: (() => Bool);
*)
lastConsumerSafe == ~(a["badRead"])

(*
  @type: (() => Bool);
*)
rootCovered == ~(g["collection"]) \/ g["anchor"]

(*
  @type: (() => Bool);
*)
chainCovered == ~(a["recycled"]) \/ g["rawOrigins"] = {}

(*
  @type: (() => Bool);
*)
phaseCovered == ~(a["recycled"]) \/ ~(g["workPending"])

(*
  @type: (() => Bool);
*)
lastAccessSafe ==
  ~(reader["badRead"]) /\ (~(reader["recycled"]) \/ ~(reader["active"]))

(*
  @type: (() => Bool);
*)
initFixed ==
  a = initial(0) /\ R_retirementState = R_initial("copy-before-retire")

(*
  @type: (() => Bool);
*)
keepR == R_retirementState' := R_retirementState

(*
  @type: (() => Bool);
*)
R_capture ==
  ~(R_retirementState["saved"])
    /\ R_retirementState' := [ R_retirementState EXCEPT !["saved"] = TRUE ]

(*
  @type: (() => Bool);
*)
R_detachExecution ==
  R_retirementState["saved"]
    /\ R_retirementState["executing"]
    /\ R_retirementState' := [ R_retirementState EXCEPT !["executing"] = FALSE ]

(*
  @type: (() => Bool);
*)
R_publish ==
  R_retirementState["saved"]
    /\ ~(R_retirementState["published"])
    /\ (~(R_retirementState["executing"])
      \/ R_retirementState["policy"] = "publish-first")
    /\ R_retirementState' := [ R_retirementState EXCEPT !["published"] = TRUE ]

(*
  @type: (() => Bool);
*)
retireExecutor ==
  a["phase"] = 3
    /\ R_retirementState["published"]
    /\ ~(R_retirementState["executing"])
    /\ R_retirementState["donorStorage"]
    /\ R_retirementState' := [ R_retirementState EXCEPT !["retired"] = TRUE ]
    /\ a' := [ a EXCEPT !["phase"] = 4 ]

(*
  @type: (() => Bool);
*)
cleanupSlot ==
  a["phase"] = 4
    /\ R_retirementState'
      := [
        R_retirementState EXCEPT
          !["donorStorage"] =
            IF a["fault"] = 1 THEN FALSE ELSE R_retirementState["donorStorage"]
      ]
    /\ a' := [ [ a EXCEPT !["phase"] = 5 ] EXCEPT !["slotCleaned"] = TRUE ]

(*
  @type: (() => Bool);
*)
restoreRaw ==
  a["phase"] = 5
    /\ a["owner"] = "thread"
    /\ R_retirementState'
      := [
        R_retirementState EXCEPT
          !["saved"] =
            IF a["fault"] = 2 THEN FALSE ELSE R_retirementState["saved"]
      ]
    /\ a'
      := [
        [ [ a EXCEPT !["phase"] = 6 ] EXCEPT !["owner"] = "break" ] EXCEPT
          !["borrowed"] = IF a["fault"] = 2 THEN FALSE ELSE a["borrowed"]
      ]

(*
  @type: (() => Bool);
*)
consumeRawFrame ==
  a["phase"] = 6
    /\ R_retirementState'
      := [
        [ R_retirementState EXCEPT !["saved"] = FALSE ] EXCEPT
          !["returned"] = TRUE
      ]
    /\ a'
      := [
        [
          [ [ a EXCEPT !["phase"] = 7 ] EXCEPT !["owner"] = "receiver" ] EXCEPT
            !["borrowed"] = FALSE
        ] EXCEPT
          !["badRead"] =
            (a["badRead"] \/ ~(R_retirementState["donorStorage"]))
              \/ a["epoch"] /= 0
      ]

(*
  @type: (() => Bool);
*)
R_beginScan ==
  R_retirementState["saved"]
    /\ ~(R_retirementState["heapFrame"])
    /\ ~(R_retirementState["scanning"])
    /\ R_retirementState["donorStorage"]
    /\ R_retirementState' := [ R_retirementState EXCEPT !["scanning"] = TRUE ]

(*
  @type: (() => Bool);
*)
R_copyFrames ==
  R_retirementState["scanning"]
    /\ R_retirementState["donorStorage"]
    /\ R_retirementState'
      := [
        [ R_retirementState EXCEPT !["scanning"] = FALSE ] EXCEPT
          !["heapFrame"] = TRUE
      ]

(*
  @type: (() => Bool);
*)
resumeCopied ==
  a["phase"] = 9
    /\ R_retirementState'
      := [
        [ R_retirementState EXCEPT !["saved"] = FALSE ] EXCEPT
          !["returned"] = TRUE
      ]
    /\ a' := [ [ a EXCEPT !["phase"] = 10 ] EXCEPT !["owner"] = "receiver" ]

(*
  @type: (() => Bool);
*)
recycleOldHalf ==
  ~(a["recycled"])
    /\ ((a["phase"] = 9 /\ ~(a["borrowed"]))
      \/ ((a["fault"] = 2 /\ a["phase"] = 6) /\ ~(a["borrowed"])))
    /\ R_releaseStorage
    /\ a' := [ [ a EXCEPT !["recycled"] = TRUE ] EXCEPT !["epoch"] = 1 ]

(*
  @type: (() => Bool);
*)
accessTerminal == closureTerminal /\ ~(reader["active"])

(*
  @type: (() => Bool);
*)
R_safe ==
  (R_continuationStorageSafe /\ R_exclusiveExecution) /\ R_scannerStorageSafe

(*
  @type: (() => Bool);
*)
backingCoverage ==
  ~rawNeeded
    \/ ((a["vmAlive"] /\ R_retirementState["donorStorage"]) /\ a["epoch"] = 0)

(*
  @type: (() => Bool);
*)
noClosedConsumerReuse ==
  ~(((reader["requireDrain"] /\ reader["returned"]) /\ reader["recycled"])
    /\ closureTerminal)

(*
  @type: (() => Bool);
*)
initClosure == \E fault \in { 0, 1, 2, 3 }: initFixed /\ g = graphInitial(fault)

(*
  @type: (() => Bool);
*)
keepA == a' := a /\ keepR

(*
  @type: (() => Bool);
*)
save ==
  a["phase"] = 0
    /\ R_capture
    /\ a'
      := [
        [ [ a EXCEPT !["phase"] = 1 ] EXCEPT !["owner"] = "thread" ] EXCEPT
          !["borrowed"] = TRUE
      ]

(*
  @type: (() => Bool);
*)
detach ==
  a["phase"] = 1 /\ R_detachExecution /\ a' := [ a EXCEPT !["phase"] = 2 ]

(*
  @type: (() => Bool);
*)
publish == a["phase"] = 2 /\ R_publish /\ a' := [ a EXCEPT !["phase"] = 3 ]

(*
  @type: (() => Bool);
*)
reinitializeSlot ==
  a["phase"] = 5
    /\ ~(a["slotReused"])
    /\ keepR
    /\ a'
      := [
        [ a EXCEPT !["slotReused"] = TRUE ] EXCEPT
          !["epoch"] = IF a["fault"] = 3 THEN 1 ELSE a["epoch"]
      ]

(*
  @type: (() => Bool);
*)
restoreHead == g["anchor"] /\ restoreRaw /\ g' := g

(*
  @type: (() => Bool);
*)
consumeHead == consumeRawFrame /\ g' := g

(*
  @type: (() => Bool);
*)
beginCollection ==
  (a["phase"] = 5 \/ a["phase"] = 6)
    /\ R_beginScan
    /\ a' := [ a EXCEPT !["phase"] = 8 ]

(*
  @type: (() => Bool);
*)
finishCollection ==
  a["phase"] = 8
    /\ R_copyFrames
    /\ a'
      := [
        [
          [ [ a EXCEPT !["phase"] = 9 ] EXCEPT !["owner"] = "heap" ] EXCEPT
            !["copied"] = TRUE
        ] EXCEPT
          !["borrowed"] = FALSE
      ]

(*
  @type: (() => Bool);
*)
resumeHead == a["recycled"] /\ resumeCopied /\ g' := g

(*
  @type: (() => Bool);
*)
completeCensusSafe == ~(reader["requireDrain"]) \/ lastAccessSafe

(*
  @type: (() => Bool);
*)
nextCycleReuse == g["cycleClosed"] /\ recycleOldHalf /\ g' := g

(*
  @type: (() => Bool);
*)
safe == (R_safe /\ backingCoverage) /\ lastConsumerSafe

(*
  @type: (() => Bool);
*)
initAccess ==
  \E required \in { FALSE, TRUE }:
    initClosure /\ reader = readerInitial(required) /\ rank = 0

(*
  @type: (() => Bool);
*)
keepRoots == keepA /\ g' := g

(*
  @type: (() => Bool);
*)
retirePrefix ==
  (save
      \/ detach
      \/ publish
      \/ retireExecutor
      \/ cleanupSlot
      \/ reinitializeSlot)
    /\ g' := g

(*
  @type: (() => Bool);
*)
establishRoot ==
  a["phase"] = 5
    /\ ~(g["anchor"])
    /\ keepA
    /\ g' := [ g EXCEPT !["anchor"] = TRUE ]

(*
  @type: (() => Bool);
*)
collect ==
  (g["anchor"] \/ g["fault"] = 1)
    /\ beginCollection
    /\ g' := [ g EXCEPT !["collection"] = TRUE ]

(*
  @type: (() => Bool);
*)
forwardHead == finishCollection /\ g' := [ g EXCEPT !["workPending"] = TRUE ]

(*
  @type: (() => Bool);
*)
retargetOrigin ==
  \E origin \in g["rawOrigins"]:
    a["phase"] = 9
      /\ ~(a["recycled"])
      /\ keepA
      /\ g' := [ g EXCEPT !["rawOrigins"] = g["rawOrigins"] \ {origin} ]

(*
  @type: (() => Bool);
*)
drainTargetWork ==
  a["phase"] = 9
    /\ g["workPending"]
    /\ keepA
    /\ g' := [ g EXCEPT !["workPending"] = FALSE ]

(*
  @type: (() => Bool);
*)
closeCycle ==
  a["phase"] = 9
    /\ ~(g["cycleClosed"])
    /\ (((g["rawOrigins"] = {} /\ ~(g["workPending"])) \/ g["fault"] = 2)
      \/ (g["fault"] = 3 /\ g["rawOrigins"] = {}))
    /\ keepA
    /\ g' := [ g EXCEPT !["cycleClosed"] = TRUE ]

(*
  @type: (() => Bool);
*)
q_inv == noClosedConsumerReuse

(*
  @type: (() => Bool);
*)
reuse ==
  (~(reader["requireDrain"]) \/ ~(reader["active"]))
    /\ nextCycleReuse
    /\ reader' := [ reader EXCEPT !["recycled"] = TRUE ]

(*
  @type: (() => Bool);
*)
closureSafe ==
  g["fault"] /= 0 \/ (((safe /\ rootCovered) /\ chainCovered) /\ phaseCovered)

(*
  @type: (() => Bool);
*)
rootProtocol ==
  (retirePrefix
      \/ establishRoot
      \/ restoreHead
      \/ consumeHead
      \/ collect
      \/ forwardHead
      \/ retargetOrigin
      \/ drainTargetWork
      \/ closeCycle
      \/ resumeHead)
    /\ reader' := reader

(*
  @type: (() => Bool);
*)
beginRead ==
  g["collection"]
    /\ g["workPending"]
    /\ ~(reader["recycled"])
    /\ g["rawOrigins"] /= {}
    /\ ~(reader["started"])
    /\ keepRoots
    /\ reader'
      := [ [ reader EXCEPT !["started"] = TRUE ] EXCEPT !["active"] = TRUE ]

(*
  @type: (() => Bool);
*)
lastAccess ==
  reader["active"]
    /\ keepRoots
    /\ reader'
      := [
        [ [ reader EXCEPT !["active"] = FALSE ] EXCEPT !["returned"] = TRUE ] EXCEPT
          !["badRead"] = reader["recycled"]
      ]

(*
  @type: (() => Bool);
*)
q_init == initAccess

(*
  @type: (() => Bool);
*)
declaredRootSafe == closureSafe

(*
  @type: (() => Bool);
*)
accessStep ==
  (g["fault"] = 0
      /\ ~accessTerminal
      /\ (rootProtocol
        \/ beginRead
        \/ lastAccess
        \/ reuse)
      /\ rank' := (rank + 1))
    \/ ((g["fault"] /= 0 \/ accessTerminal)
      /\ keepRoots
      /\ reader' := reader
      /\ rank' := rank)

(*
  @type: (() => Bool);
*)
accessCompletion ==
  [](g["fault"] /= 0) \/ (WF_{rank}(accessStep) => <>accessTerminal)

(*
  @type: (() => Bool);
*)
q_step == accessStep

================================================================================
