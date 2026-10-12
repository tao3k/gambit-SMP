------------------------ MODULE gc_recursive_queue_wait ------------------------

EXTENDS Integers, Sequences, FiniteSets, TLC, Apalache, Variants

(*
  @type: (() => (Int -> Int));
*)
root == SetAsFun({ <<0, 0>>, <<1, 2>> })

(*
  @type: (() => (Int -> Int));
*)
originQueue == SetAsFun({ <<0, 0>>, <<1, 0>>, <<2, 1>>, <<3, 1>> })

(*
  @type: (() => Set(Str));
*)
activeModes == { "active", "claim-locked", "scanning", "probed", "recheck" }

(*
  @type: (() => Set(Int));
*)
workers == { 0, 1, 2, 3 }

(*
  @type: (() => Set(Int));
*)
producers == { 0, 1 }

(*
  @type: (() => Set(Int));
*)
objects == { 0, 1, 2, 3 }

(*
  @type: (() => (Int -> Int));
*)
edge == SetAsFun({ <<0, 1>>, <<1, 0>>, <<2, 3>>, <<3, 2>> })

VARIABLE
  (*
    @type: { copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) };
  *)
  s

(*
  @type: (() => Set(Int));
*)
queues == workers

(*
  @type: (() => Bool);
*)
countOrRetry ==
  \E w \in workers:
    s["mode"][w] = "recheck"
      /\ s["remaining"][w] = {}
      /\ s["mutex"] = w
      /\ s'
        := (IF s["found"][w]
        THEN [
          [
            [ s EXCEPT !["mode"] = [ s["mode"] EXCEPT ![w] = "active" ] ] EXCEPT
              !["found"] = [ s["found"] EXCEPT ![w] = FALSE ]
          ] EXCEPT
            !["mutex"] = -1
        ]
        ELSE IF s["count"] = 1
        THEN [
          [
            [ [ s EXCEPT !["count"] = 0 ] EXCEPT !["terminated"] = TRUE ] EXCEPT
              !["mutex"] = -1
          ] EXCEPT
            !["mode"] =
              [
                x_1674 \in workers |->
                  IF x_1674 = w
                  THEN "done"
                  ELSE IF s["mode"][x_1674] = "waiting"
                  THEN "woken"
                  ELSE s["mode"][x_1674]
              ]
        ]
        ELSE [
          [ s EXCEPT !["count"] = s["count"] - 1 ] EXCEPT
            !["mode"] = [ s["mode"] EXCEPT ![w] = "pre-wait" ]
        ])

(*
  @type: (() => Bool);
*)
registerWait ==
  \E w \in workers:
    s["mode"][w] = "pre-wait"
      /\ s["mutex"] = w
      /\ s'
        := [
          [ s EXCEPT !["mode"] = [ s["mode"] EXCEPT ![w] = "waiting" ] ] EXCEPT
            !["mutex"] = -1
        ]

(*
  @type: (() => Bool);
*)
spuriousWake ==
  \E w \in workers:
    s["mode"][w] = "waiting"
      /\ ~(w \in s["spuriousUsed"])
      /\ s'
        := [
          [ s EXCEPT !["mode"] = [ s["mode"] EXCEPT ![w] = "woken" ] ] EXCEPT
            !["spuriousUsed"] = s["spuriousUsed"] \union {w}
        ]

(*
  @type: (() => Bool);
*)
resume ==
  \E w \in workers:
    s["mode"][w] = "woken"
      /\ s["mutex"] = -1
      /\ s'
        := (IF s["count"] = 0
        THEN [ s EXCEPT !["mode"] = [ s["mode"] EXCEPT ![w] = "done" ] ]
        ELSE [
          [ s EXCEPT !["mode"] = [ s["mode"] EXCEPT ![w] = "active" ] ] EXCEPT
            !["count"] =
              s["count"] + (IF s["fault"] = "omit-restore" THEN 0 ELSE 1)
        ])

(*
  @type: (() => Int);
*)
counted ==
  Cardinality({ w_1843 \in workers: s["mode"][w_1843] \in activeModes })

(*
  @type: (() => Bool);
*)
payloadSafe ==
  ~(s["staleRead"])
    /\ (\A o_1887 \in objects: s["pub"][o_1887] < 2 \/ s["visible"][o_1887] = 2)

(*
  @type: (() => Bool);
*)
ownershipSafe ==
  \A o_1931 \in objects:
    s["scans"][o_1931] <= 1
      /\ (s["work"][o_1931] /= 2
        \/ Cardinality({
          w_1924 \in workers:
            s["mode"][w_1924] = "scanning" /\ s["target"][w_1924] = o_1931
        })
          = 1)

(*
  @type: (() => Bool);
*)
fieldPartitionSafe ==
  ~(s["foreignHeadWrite"])
    /\ (\A o_1976 \in objects:
      s["headVisits"][o_1976] <= 1
        /\ (o_1976 \in s["headDone"] => s["headVisits"][o_1976] = 1))

(*
  @type: (() => Bool);
*)
closureSafe ==
  ~(s["terminated"])
    \/ (((s["count"] = 0 /\ s["headDone"] = objects) /\ s["tailDone"] = objects)
      /\ (\A o_2010 \in objects: s["work"][o_2010] = 3))

(*
  @type: (() => Bool);
*)
localExportSafe ==
  \A o_2043 \in objects:
    ~((s["work"][o_2043] = 2 /\ s["route"][o_2043] = "local")
      /\ s["pub"][o_2043] > 0)

(*
  @type: (() => Bool);
*)
terminal ==
  s["terminated"] /\ (\A w_2094 \in workers: s["mode"][w_2094] = "done")

(*
  @type: (() => Set(Int));
*)
queued == { o_333 \in objects: s["work"][o_333] = 1 }

(*
  @type: ((Int) => Bool);
*)
markingWork(w_389) ==
  \E o_387 \in objects:
    s["owner"][o_387] = w_389
      /\ (~(o_387 \in s["headDone"])
        \/ (s["pub"][o_387] > 0 /\ s["pub"][o_387] < 5))

(*
  @type: (() => Bool);
*)
publish ==
  \E o \in objects:
    s["pub"][o] = 1
      /\ s'
        := [
          [
            [ s EXCEPT !["pub"] = [ s["pub"] EXCEPT ![o] = 2 ] ] EXCEPT
              !["work"] = [ s["work"] EXCEPT ![o] = 1 ]
          ] EXCEPT
            !["visible"] = [ s["visible"] EXCEPT ![o] = s["copied"][o] ]
        ]

(*
  @type: (() => Bool);
*)
releasePublication ==
  \E o \in objects:
    s["pub"][o] = 2
      /\ s'
        := [
          [ s EXCEPT !["pub"] = [ s["pub"] EXCEPT ![o] = 3 ] ] EXCEPT
            !["queueOwner"] = [ s["queueOwner"] EXCEPT ![s["queueOf"][o]] = -1 ]
        ]

(*
  @type: (() => Bool);
*)
popQueue ==
  \E w \in workers:
    LET (*@type: (() => Int); *) o == s["target"][w] IN
    s["mode"][w] = "claim-locked"
      /\ s["work"][(o)] = 1
      /\ s'
        := [
          [
            [
              [
                [
                  [
                    [
                      s EXCEPT
                        !["work"] =
                          [
                            s["work"] EXCEPT
                              ![o] =
                                IF s["fault"] = "duplicate-claim" THEN 1 ELSE 2
                          ]
                    ] EXCEPT
                      !["scans"] =
                        [ s["scans"] EXCEPT ![o] = s["scans"][(o)] + 1 ]
                  ] EXCEPT
                    !["queueOwner"] =
                      [ s["queueOwner"] EXCEPT ![s["queueOf"][(o)]] = -1 ]
                ] EXCEPT
                  !["route"] = [ s["route"] EXCEPT ![o] = "queue" ]
              ] EXCEPT
                !["mode"] = [ s["mode"] EXCEPT ![w] = "scanning" ]
            ] EXCEPT
              !["staleRead"] = s["staleRead"] \/ s["visible"][(o)] /= 2
          ] EXCEPT
            !["foreignHeadWrite"] =
              s["foreignHeadWrite"] \/ s["fault"] = "scan-head-too"
        ]

(*
  @type: (() => Bool);
*)
copyWord ==
  \E o \in objects:
    LET (*@type: (() => Int); *) w == s["owner"][o] IN
    s["work"][o] = 0
      /\ s["pub"][o] = 0
      /\ s["mode"][(w)] \in { "active", "scanning" }
      /\ s["copied"][o] < 2
      /\ s'
        := [
          s EXCEPT
            !["copied"] = [ s["copied"] EXCEPT ![o] = s["copied"][o] + 1 ]
        ]

(*
  @type: (() => Bool);
*)
acquireSignalMutex ==
  \E o \in objects:
    LET (*@type: (() => Int); *) w == s["owner"][o] IN
    s["policy"] = "combined"
      /\ s["pub"][o] = 3
      /\ s["mutex"] = -1
      /\ s'
        := [
          [ s EXCEPT !["pub"] = [ s["pub"] EXCEPT ![o] = 4 ] ] EXCEPT
            !["mutex"] = w
        ]

(*
  @type: (() => Bool);
*)
beginPublish ==
  \E o \in objects:
    LET (*@type: (() => Int); *) w == s["owner"][o] IN
    LET (*
      @type: (() => Int);
    *)
    q == IF s["fault"] = "origin-queue" THEN (originQueue)[o] ELSE w
    IN
    s["pub"][o] = 0
      /\ ((s["work"][o] = 0 /\ s["mode"][(w)] \in { "active", "scanning" })
        \/ ((s["fault"] = "local-reexport" /\ s["work"][o] = 2)
          /\ s["route"][o] = "local"))
      /\ (s["copied"][o] = 2 \/ s["fault"] = "early-publication")
      /\ s["queueOwner"][(q)] = -1
      /\ s'
        := [
          [
            [ s EXCEPT !["pub"] = [ s["pub"] EXCEPT ![o] = 1 ] ] EXCEPT
              !["queueOf"] = [ s["queueOf"] EXCEPT ![o] = q ]
          ] EXCEPT
            !["queueOwner"] = [ s["queueOwner"] EXCEPT ![q] = w ]
        ]

(*
  @type: (() => Bool);
*)
signalWork ==
  \E o \in objects:
    LET (*@type: (() => Int); *) w == s["owner"][o] IN
    LET (*
      @type: (() => Set(Int));
    *)
    waiting == { x_749 \in workers: s["mode"][x_749] = "waiting" }
    IN
    \E wake \in IF waiting = {} THEN {(-1)} ELSE waiting:
      ((s["policy"] = "source" /\ s["pub"][o] = 3)
          \/ ((s["policy"] = "combined" /\ s["pub"][o] = 4) /\ s["mutex"] = w))
        /\ s'
          := [
            [
              [
                [
                  s EXCEPT
                    !["pub"] =
                      [
                        s["pub"] EXCEPT
                          ![o] = IF s["work"][o] = 3 THEN 0 ELSE 5
                      ]
                ] EXCEPT
                  !["visible"] =
                    IF s["work"][o] = 3
                    THEN [ s["visible"] EXCEPT ![o] = 0 ]
                    ELSE s["visible"]
              ] EXCEPT
                !["mutex"] = IF s["policy"] = "combined" THEN -1 ELSE s["mutex"]
            ] EXCEPT
              !["mode"] =
                IF wake = -1
                THEN s["mode"]
                ELSE [ s["mode"] EXCEPT ![wake] = "woken" ]
          ]

(*
  @type: (() => Bool);
*)
finishHead ==
  \E o \in objects:
    LET (*@type: (() => Int); *) w == s["owner"][o] IN
    LET (*@type: (() => Int); *) child == (edge)[o] IN
    LET (*@type: (() => Bool); *) fresh == s["work"][(child)] = -1 IN
    s["copied"][o] = 2
      /\ s["mode"][(w)] \in { "active", "scanning" }
      /\ ~(o \in s["headDone"])
      /\ s'
        := [
          [
            [
              [ s EXCEPT !["headDone"] = s["headDone"] \union {o} ] EXCEPT
                !["headVisits"] =
                  [ s["headVisits"] EXCEPT ![o] = s["headVisits"][o] + 1 ]
            ] EXCEPT
              !["work"] =
                IF fresh THEN [ s["work"] EXCEPT ![child] = 0 ] ELSE s["work"]
          ] EXCEPT
            !["owner"] =
              IF fresh THEN [ s["owner"] EXCEPT ![child] = w ] ELSE s["owner"]
        ]

(*
  @type: (() => Bool);
*)
markTail ==
  \E w \in workers:
    LET (*@type: (() => Int); *) o == s["target"][w] IN
    LET (*@type: (() => Int); *) child == (edge)[(o)] IN
    LET (*@type: (() => Bool); *) fresh == s["work"][(child)] = -1 IN
    s["mode"][w] = "scanning"
      /\ ~(o \in s["tailDone"])
      /\ s'
        := [
          [
            [ s EXCEPT !["tailDone"] = s["tailDone"] \union {(o)} ] EXCEPT
              !["work"] =
                IF fresh THEN [ s["work"] EXCEPT ![child] = 0 ] ELSE s["work"]
          ] EXCEPT
            !["owner"] =
              IF fresh THEN [ s["owner"] EXCEPT ![child] = w ] ELSE s["owner"]
        ]

(*
  @type: (() => Bool);
*)
lockTermination ==
  \E w \in workers:
    s["mode"][w] = "probed"
      /\ s["mutex"] = -1
      /\ s'
        := [
          [
            [
              [ s EXCEPT !["mutex"] = w ] EXCEPT
                !["mode"] = [ s["mode"] EXCEPT ![w] = "recheck" ]
            ] EXCEPT
              !["remaining"] =
                [
                  s["remaining"] EXCEPT
                    ![w] = IF s["policy"] = "combined" THEN queues ELSE {}
                ]
          ] EXCEPT
            !["found"] = [ s["found"] EXCEPT ![w] = FALSE ]
        ]

(*
  @type: ((Str, Str) => { copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) });
*)
initial(policy_249, fault_249) ==
  [policy |-> policy_249,
    fault |-> fault_249,
    mode |-> [ w_127 \in workers |-> "active" ],
    work |-> SetAsFun({ <<0, 0>>, <<1, (-1)>>, <<2, 0>>, <<3, (-1)>> }),
    owner |-> SetAsFun({ <<0, 0>>, <<1, (-1)>>, <<2, 1>>, <<3, (-1)>> }),
    copied |-> [ o_165 \in objects |-> 0 ],
    visible |-> [ o_171 \in objects |-> 0 ],
    pub |-> [ o_177 \in objects |-> 0 ],
    queueOf |-> [ o_184 \in objects |-> -1 ],
    route |-> [ o_190 \in objects |-> "" ],
    queueOwner |-> [ q_197 \in queues |-> -1 ],
    scans |-> [ o_203 \in objects |-> 0 ],
    target |-> [ w_210 \in workers |-> -1 ],
    remaining |-> [ w_216 \in workers |-> {} ],
    found |-> [ w_222 \in workers |-> FALSE ],
    headDone |-> {},
    tailDone |-> {},
    headVisits |-> [ o_232 \in objects |-> 0 ],
    foreignHeadWrite |-> FALSE,
    mutex |-> -1,
    count |-> 4,
    spuriousUsed |-> {},
    staleRead |-> FALSE,
    terminated |-> FALSE]

(*
  @type: (() => Bool);
*)
claimLocal ==
  \E w \in workers:
    \E o \in objects:
      s["mode"][w] = "active"
        /\ s["owner"][o] = w
        /\ s["work"][o] = 0
        /\ s["pub"][o] = 0
        /\ s["copied"][o] = 2
        /\ ~(markingWork(w))
        /\ s'
          := [
            [
              [
                [
                  [ s EXCEPT !["work"] = [ s["work"] EXCEPT ![o] = 2 ] ] EXCEPT
                    !["route"] = [ s["route"] EXCEPT ![o] = "local" ]
                ] EXCEPT
                  !["scans"] = [ s["scans"] EXCEPT ![o] = s["scans"][o] + 1 ]
              ] EXCEPT
                !["target"] = [ s["target"] EXCEPT ![w] = o ]
            ] EXCEPT
              !["mode"] = [ s["mode"] EXCEPT ![w] = "scanning" ]
          ]

(*
  @type: (() => Bool);
*)
countSafe ==
  (s["count"] = counted /\ s["count"] >= 0)
    /\ s["count"] <= Cardinality((workers))

(*
  @type: (() => Bool);
*)
queueTopologySafe ==
  \A o_2059 \in queued: s["queueOf"][o_2059] = s["owner"][o_2059]

(*
  @type: (() => Bool);
*)
finished == terminal /\ s' := s

(*
  @type: ((Int) => Bool);
*)
queuePending(q_350) == \E o_348 \in queued: s["queueOf"][o_348] = q_350

(*
  @type: ((Int) => Bool);
*)
privateWork(w_416) ==
  markingWork(w_416)
    \/ (\E o_413 \in objects: s["owner"][o_413] = w_416 /\ s["work"][o_413] = 0)

(*
  @type: (() => Bool);
*)
finishScan ==
  \E w \in workers:
    LET (*@type: (() => Int); *) o == s["target"][w] IN
    LET (*
      @type: (() => Bool);
    *)
    settled == s["pub"][(o)] = 0 \/ s["pub"][(o)] = 5
    IN
    s["mode"][w] = "scanning"
      /\ o \in s["tailDone"]
      /\ ~(markingWork(w))
      /\ s'
        := [
          [
            [
              [
                [
                  [
                    [ s EXCEPT !["work"] = [ s["work"] EXCEPT ![o] = 3 ] ] EXCEPT
                      !["route"] = [ s["route"] EXCEPT ![o] = "" ]
                  ] EXCEPT
                    !["queueOf"] = [ s["queueOf"] EXCEPT ![o] = -1 ]
                ] EXCEPT
                  !["pub"] =
                    IF settled THEN [ s["pub"] EXCEPT ![o] = 0 ] ELSE s["pub"]
              ] EXCEPT
                !["visible"] =
                  IF settled
                  THEN [ s["visible"] EXCEPT ![o] = 0 ]
                  ELSE s["visible"]
            ] EXCEPT
              !["mode"] = [ s["mode"] EXCEPT ![w] = "active" ]
          ] EXCEPT
            !["target"] = [ s["target"] EXCEPT ![w] = -1 ]
        ]

(*
  @type: (() => Bool);
*)
initEarlyPublish == s' := (initial("combined", "early-publication"))

(*
  @type: (() => Bool);
*)
initDuplicateClaim == s' := (initial("combined", "duplicate-claim"))

(*
  @type: (() => Bool);
*)
initEarlyIdle == s' := (initial("combined", "early-idle"))

(*
  @type: (() => Bool);
*)
initNoRestore == s' := (initial("combined", "omit-restore"))

(*
  @type: (() => Bool);
*)
initLocalReexport == s' := (initial("combined", "local-reexport"))

(*
  @type: (() => Bool);
*)
initWrongQueue == s' := (initial("combined", "origin-queue"))

(*
  @type: (() => Bool);
*)
initScanHead == s' := (initial("combined", "scan-head-too"))

(*
  @type: (() => Bool);
*)
initSource == s = initial("source", "none")

(*
  @type: (() => Bool);
*)
initCombined == s' := (initial("combined", "none"))

(*
  @type: (() => Bool);
*)
init == \E policy \in { "source", "combined" }: s' := (initial(policy, "none"))

(*
  @type: (() => Bool);
*)
probeRecheckQueue ==
  \E w \in workers:
    \E q \in s["remaining"][w]:
      s["mode"][w] = "recheck"
        /\ s["mutex"] = w
        /\ s["queueOwner"][q] = -1
        /\ s'
          := [
            [
              s EXCEPT
                !["remaining"] =
                  [ s["remaining"] EXCEPT ![w] = s["remaining"][w] \ {q} ]
            ] EXCEPT
              !["found"] =
                [ s["found"] EXCEPT ![w] = s["found"][w] \/ queuePending(q) ]
          ]

(*
  @type: (() => Bool);
*)
producerLifetimeSafe ==
  \A w_1946 \in workers:
    privateWork(w_1946) => s["mode"][w_1946] \in activeModes

(*
  @type: (() => Bool);
*)
restoreSafe == countSafe

(*
  @type: ((Int) => Bool);
*)
ready(w_424) == ~(privateWork(w_424))

(*
  @type: (() => Bool);
*)
claimQueue ==
  \E w \in workers:
    \E o \in queued:
      LET (*@type: (() => Int); *) q == s["queueOf"][o] IN
      s["mode"][w] = "active"
        /\ ready(w)
        /\ s["queueOwner"][(q)] = -1
        /\ s'
          := [
            [
              [ s EXCEPT !["queueOwner"] = [ s["queueOwner"] EXCEPT ![q] = w ] ]
                EXCEPT
                !["target"] = [ s["target"] EXCEPT ![w] = o ]
            ] EXCEPT
              !["mode"] = [ s["mode"] EXCEPT ![w] = "claim-locked" ]
          ]

(*
  @type: (() => Bool);
*)
finalEmptyProbe ==
  \E w \in workers:
    s["mode"][w] = "active"
      /\ queued = {}
      /\ (ready(w) \/ s["fault"] = "early-idle")
      /\ s' := [ s EXCEPT !["mode"] = [ s["mode"] EXCEPT ![w] = "probed" ] ]

(*
  @type: (() => Bool);
*)
safe ==
  ((((((countSafe /\ payloadSafe) /\ ownershipSafe) /\ producerLifetimeSafe)
          /\ closureSafe)
        /\ localExportSafe)
      /\ queueTopologySafe)
    /\ fieldPartitionSafe

(*
  @type: (() => Bool);
*)
q_init == initSource

(*
  @type: (() => Bool);
*)
sourceSafe == safe

(*
  @type: (() => Bool);
*)
combinedSafe == safe

(*
  @type: (() => Bool);
*)
step ==
  copyWord
    \/ beginPublish
    \/ publish
    \/ releasePublication
    \/ acquireSignalMutex
    \/ signalWork
    \/ finishHead
    \/ claimLocal
    \/ claimQueue
    \/ popQueue
    \/ markTail
    \/ finishScan
    \/ finalEmptyProbe
    \/ lockTermination
    \/ probeRecheckQueue
    \/ countOrRetry
    \/ registerWait
    \/ spuriousWake
    \/ resume
    \/ finished

(*
  @type: (() => Bool);
*)
progress == [](terminal \/ ENABLED step) /\ (WF_{s}(step) => <>terminal)

(*
  @type: (() => Bool);
*)
q_step == step

(*
  @type: (() => Bool);
*)
q_inv == sourceSafe

(*
  @type: (() => Bool);
*)
q_temporalProps == progress

================================================================================
