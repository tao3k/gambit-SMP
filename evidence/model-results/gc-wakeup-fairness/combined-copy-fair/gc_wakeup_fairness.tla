-------------------------- MODULE gc_wakeup_fairness --------------------------

EXTENDS Integers, Sequences, FiniteSets, TLC, Apalache, Variants

(*
  @type: (() => Set(Int));
*)
workers == { 0, 1, 2, 3 }

(*
  @type: (() => Set(Str));
*)
activeModes ==
  { "active", "probe", "claim-locked", "scanning", "probed", "recheck" }

(*
  @type: (() => Set(Int));
*)
objects == { 0, 1, 2, 3 }

VARIABLE
  (*
    @type: { copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) };
  *)
  s

(*
  @type: (() => Seq(Int));
*)
probeOrder == <<2, 0, 3, 1>>

(*
  @type: (() => (Int -> Int));
*)
originQueue == SetAsFun({ <<0, 0>>, <<1, 0>>, <<2, 1>>, <<3, 1>> })

(*
  @type: (() => (Int -> Int));
*)
edge == SetAsFun({ <<0, 1>>, <<1, 0>>, <<2, 3>>, <<3, 2>> })

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
countSafeOf(st_2281) ==
  (st_2281["count"]
        = Cardinality({
          w_2264 \in workers:
            st_2281["mode"][w_2264] \in activeModes
        })
      /\ st_2281["count"] >= 0)
    /\ st_2281["count"] <= Cardinality((workers))

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
payloadSafeOf(st_2310) ==
  ~(st_2310["staleRead"])
    /\ (\A o_2307 \in objects:
      st_2310["pub"][o_2307] < 2 \/ st_2310["visible"][o_2307] = 2)

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
ownershipSafeOf(st_2357) ==
  \A o_2355 \in objects:
    st_2357["scans"][o_2355] <= 1
      /\ (st_2357["work"][o_2355] /= 2
        \/ Cardinality({
          w_2348 \in workers:
            st_2357["mode"][w_2348] = "scanning"
              /\ st_2357["target"][w_2348] = o_2355
        })
          = 1)

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }, Int) => Bool);
*)
markingWorkOf(st_555, w_555) ==
  \E o_553 \in objects:
    st_555["owner"][o_553] = w_555
      /\ (~(o_553 \in st_555["headDone"])
        \/ (st_555["pub"][o_553] > 0 /\ st_555["pub"][o_553] < 5))

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
closureSafeOf(st_2548) ==
  ~(st_2548["terminated"])
    \/ (((st_2548["count"] = 0 /\ st_2548["headDone"] = objects)
        /\ st_2548["tailDone"] = objects)
      /\ (\A o_2544 \in objects: st_2548["work"][o_2544] = 3))

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
localExportSafeOf(st_2607) ==
  \A o_2605 \in objects:
    ~((st_2607["work"][o_2605] = 2 /\ st_2607["route"][o_2605] = "local")
      /\ st_2607["pub"][o_2605] > 0)

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
queueTopologySafeOf(st_2635) ==
  \A o_2633 \in objects:
    st_2635["work"][o_2633] = 1
      => st_2635["queueOf"][o_2633] = st_2635["owner"][o_2633]

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
fieldPartitionSafeOf(st_2509) ==
  ~(st_2509["foreignHeadWrite"])
    /\ (\A o_2506 \in objects:
      st_2509["headVisits"][o_2506] <= 1
        /\ (o_2506 \in st_2509["headDone"] => st_2509["headVisits"][o_2506] = 1))

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
eagerOwnerSafeOf(st_2425) ==
  \A o_2423 \in objects:
    st_2425["work"][o_2423] /= -1
      /\ (~(o_2423 \in st_2425["headDone"])
        \/ (st_2425["pub"][o_2423] > 0 /\ st_2425["pub"][o_2423] < 5))
      => st_2425["owner"][o_2423] \in workers

(*
  @type: (() => Set(Int));
*)
queues == workers

(*
  @type: (() => Set(Int));
*)
queued == { o_497 \in objects: s["work"][o_497] = 1 }

(*
  @type: (() => Bool);
*)
finishProbe ==
  \E w \in workers:
    s["mode"][w] = "probe"
      /\ s["probeIndex"][w] = 4
      /\ s'
        := [
          [ s EXCEPT !["mode"] = [ s["mode"] EXCEPT ![w] = "probed" ] ] EXCEPT
            !["probeIndex"] = [ s["probeIndex"] EXCEPT ![w] = 0 ]
        ]

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
                x_2076 \in workers |->
                  IF x_2076 = w
                  THEN "done"
                  ELSE IF s["mode"][x_2076] = "waiting"
                  THEN "woken"
                  ELSE s["mode"][x_2076]
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
  @type: (() => Bool);
*)
copiedRoot == s["copied"][0] > 0 \/ s["copied"][2] > 0

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
signalWork ==
  \E o \in objects:
    LET (*@type: (() => Int); *) w == s["owner"][o] IN
    LET (*
      @type: (() => Set(Int));
    *)
    waiting == { x_934 \in workers: s["mode"][x_934] = "waiting" }
    IN
    \E wake \in IF waiting = {} THEN {(-1)} ELSE waiting:
      ((s["policy"] = "source" /\ s["pub"][o] = 3)
          \/ ((s["policy"] = "combined" /\ s["pub"][o] = 4) /\ s["mutex"] = w))
        /\ s'
          := [
            [
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
                  !["owner"] =
                    IF s["work"][o] = 3 /\ o \in s["headDone"]
                    THEN [ s["owner"] EXCEPT ![o] = -1 ]
                    ELSE s["owner"]
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
    LET (*
      @type: (() => Bool);
    *)
    retired == s["work"][o] = 3 /\ (s["pub"][o] = 0 \/ s["pub"][o] = 5)
    IN
    ~(o \in s["headDone"])
      /\ w \in workers
      /\ s["copied"][o] = 2
      /\ s["mode"][(w)] \in { "active", "scanning" }
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
              [
                (IF retired THEN [ s["owner"] EXCEPT ![o] = -1 ] ELSE s["owner"])
                  EXCEPT
                  ![child] = IF fresh THEN w ELSE s["owner"][(child)]
              ]
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
terminal ==
  s["terminated"] /\ (\A w_2696 \in workers: s["mode"][w_2696] = "done")

(*
  @type: (() => Bool);
*)
wakeUnbounded ==
  \E w \in workers:
    s["mode"][w] = "waiting"
      /\ s' := [ s EXCEPT !["mode"] = [ s["mode"] EXCEPT ![w] = "woken" ] ]

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }, Int) => Bool);
*)
privateWorkOf(st_585, w_585) ==
  markingWorkOf(st_585, w_585)
    \/ (\E o_582 \in objects:
      st_585["owner"][o_582] = w_585 /\ st_585["work"][o_582] = 0)

(*
  @type: ((Str, Str) => { copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) });
*)
initial(policy_400, fault_400) ==
  [policy |-> policy_400,
    fault |-> fault_400,
    mode |-> [ w_272 \in workers |-> "active" ],
    work |-> SetAsFun({ <<0, 0>>, <<1, (-1)>>, <<2, 0>>, <<3, (-1)>> }),
    owner |-> SetAsFun({ <<0, 0>>, <<1, (-1)>>, <<2, 1>>, <<3, (-1)>> }),
    copied |-> [ o_310 \in objects |-> 0 ],
    visible |-> [ o_316 \in objects |-> 0 ],
    pub |-> [ o_322 \in objects |-> 0 ],
    queueOf |-> [ o_329 \in objects |-> -1 ],
    route |-> [ o_335 \in objects |-> "" ],
    queueOwner |-> [ q_342 \in queues |-> -1 ],
    scans |-> [ o_348 \in objects |-> 0 ],
    target |-> [ w_355 \in workers |-> -1 ],
    probeIndex |-> [ w_361 \in workers |-> 0 ],
    remaining |-> [ w_367 \in workers |-> {} ],
    found |-> [ w_373 \in workers |-> FALSE ],
    headDone |-> {},
    tailDone |-> {},
    headVisits |-> [ o_383 \in objects |-> 0 ],
    foreignHeadWrite |-> FALSE,
    mutex |-> -1,
    count |-> 4,
    spuriousUsed |-> {},
    staleRead |-> FALSE,
    terminated |-> FALSE]

(*
  @type: ((Int) => Bool);
*)
queuePending(q_514) == \E o_512 \in queued: s["queueOf"][o_512] = q_514

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
  @type: ((Int) => Bool);
*)
markingWork(w_593) == markingWorkOf(s, w_593)

(*
  @type: (() => Bool);
*)
finished == terminal /\ s' := s

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
producerLifetimeSafeOf(st_2377) ==
  \A w_2375 \in workers:
    privateWorkOf(st_2377, w_2375) => st_2377["mode"][w_2375] \in activeModes

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
localDrainSafeOf(st_2474) ==
  \A w_2472 \in workers:
    st_2474["mode"][w_2472]
      \in { "probe", "probed", "recheck", "pre-wait", "waiting", "woken", "done"
      }
      => ~(privateWorkOf(st_2474, w_2472))
        /\ ~(\E o_2467 \in objects:
          st_2474["work"][o_2467] = 1 /\ st_2474["queueOf"][o_2467] = w_2472)

(*
  @type: ((Int) => Bool);
*)
privateWork(w_601) == privateWorkOf(s, w_601)

(*
  @type: (() => Bool);
*)
probeEmptyQueue ==
  \E w \in workers:
    LET (*@type: (() => Int); *) index == s["probeIndex"][w] IN
    s["mode"][w] = "probe"
      /\ index < 4
      /\ ~(queuePending((probeOrder)[(index + 1)]))
      /\ s'
        := [
          s EXCEPT
            !["probeIndex"] = [ s["probeIndex"] EXCEPT ![w] = index + 1 ]
        ]

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
claimLocal ==
  \E w \in workers:
    \E o \in objects:
      s["mode"][w] = "active"
        /\ s["owner"][o] = w
        /\ s["work"][o] = 0
        /\ s["pub"][o] = 0
        /\ s["copied"][o] = 2
        /\ ~(markingWork(w))
        /\ ~(queuePending(w))
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
                    [
                      [ s EXCEPT !["work"] = [ s["work"] EXCEPT ![o] = 3 ] ] EXCEPT
                        !["owner"] =
                          IF settled
                            /\ (o \in s["headDone"]
                              \/ s["fault"] = "early-owner-release")
                          THEN [ s["owner"] EXCEPT ![o] = -1 ]
                          ELSE s["owner"]
                    ] EXCEPT
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
initCombined == s = initial("combined", "none")

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
safeOf(st_2675) ==
  ((((((((countSafeOf(st_2675) /\ payloadSafeOf(st_2675))
                  /\ ownershipSafeOf(st_2675))
                /\ producerLifetimeSafeOf(st_2675))
              /\ closureSafeOf(st_2675))
            /\ localExportSafeOf(st_2675))
          /\ queueTopologySafeOf(st_2675))
        /\ fieldPartitionSafeOf(st_2675))
      /\ eagerOwnerSafeOf(st_2675))
    /\ localDrainSafeOf(st_2675)

(*
  @type: ((Int) => Bool);
*)
ready(w_609) == ~(privateWork(w_609))

(*
  @type: (() => Bool);
*)
q_init == initCombined

(*
  @type: (() => Bool);
*)
safe == safeOf(s)

(*
  @type: (() => Bool);
*)
startProbe ==
  \E w \in workers:
    s["mode"][w] = "active"
      /\ (((ready(w) /\ ~(queuePending(w))) \/ s["fault"] = "early-idle")
        \/ (ready(w) /\ s["fault"] = "skip-local-drain"))
      /\ s'
        := [
          [ s EXCEPT !["mode"] = [ s["mode"] EXCEPT ![w] = "probe" ] ] EXCEPT
            !["probeIndex"] = [ s["probeIndex"] EXCEPT ![w] = 0 ]
        ]

(*
  @type: (() => Bool);
*)
claimQueue ==
  \E w \in workers:
    \E o \in queued:
      LET (*@type: (() => Int); *) q == s["queueOf"][o] IN
      (((s["mode"][w] = "active" /\ q = w) /\ ~(markingWork(w)))
          \/ (s["mode"][w] = "probe" /\ ready(w)))
        /\ s["queueOwner"][(q)] = -1
        /\ s'
          := [
            [
              [
                [
                  s EXCEPT
                    !["queueOwner"] = [ s["queueOwner"] EXCEPT ![q] = w ]
                ] EXCEPT
                  !["target"] = [ s["target"] EXCEPT ![w] = o ]
              ] EXCEPT
                !["probeIndex"] = [ s["probeIndex"] EXCEPT ![w] = 0 ]
            ] EXCEPT
              !["mode"] = [ s["mode"] EXCEPT ![w] = "claim-locked" ]
          ]

(*
  @type: (() => Bool);
*)
focusSafe ==
  ((safe /\ ~(s["terminated"])) /\ s["count"] >= 2)
    /\ (\A o_115 \in objects:
      s["work"][o_115] = (initial(s["policy"], "none"))["work"][o_115])

(*
  @type: (() => Bool);
*)
helperSteps ==
  startProbe
    \/ probeEmptyQueue
    \/ finishProbe
    \/ lockTermination
    \/ probeRecheckQueue
    \/ countOrRetry
    \/ registerWait
    \/ resume

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
    \/ startProbe
    \/ probeEmptyQueue
    \/ finishProbe
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
fullUnbounded ==
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
    \/ startProbe
    \/ probeEmptyQueue
    \/ finishProbe
    \/ lockTermination
    \/ probeRecheckQueue
    \/ countOrRetry
    \/ registerWait
    \/ wakeUnbounded
    \/ resume
    \/ finished

(*
  @type: (() => Bool);
*)
boundedAggregate == WF_{s}(step) => <>copiedRoot

(*
  @type: (() => Bool);
*)
stepBounded == copyWord \/ helperSteps \/ spuriousWake

(*
  @type: (() => Bool);
*)
stepUnbounded == copyWord \/ helperSteps \/ wakeUnbounded

(*
  @type: (() => Bool);
*)
unboundedAggregate == WF_{s}(fullUnbounded) => <>copiedRoot

(*
  @type: (() => Bool);
*)
unboundedCopyFair == WF_{s}(fullUnbounded) /\ WF_{s}(copyWord) => <>copiedRoot

(*
  @type: (() => Bool);
*)
q_inv == focusSafe

(*
  @type: (() => Bool);
*)
q_step == stepUnbounded

(*
  @type: (() => Bool);
*)
q_temporalProps == unboundedCopyFair

================================================================================
