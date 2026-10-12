------------------------ MODULE gc_recursive_queue_wait ------------------------

EXTENDS Integers, Sequences, FiniteSets, TLC, Apalache, Variants

(*
  @type: (() => (Int -> Int));
*)
originQueue == SetAsFun({ <<0, 0>>, <<1, 0>>, <<2, 1>>, <<3, 1>> })

(*
  @type: (() => Set(Str));
*)
activeModes ==
  { "active", "probe", "claim-locked", "scanning", "probed", "recheck" }

(*
  @type: (() => Set(Int));
*)
workers == { 0, 1, 2, 3 }

(*
  @type: (() => Set(Int));
*)
objects == { 0, 1, 2, 3 }

(*
  @type: (() => (Int -> Int));
*)
edge == SetAsFun({ <<0, 1>>, <<1, 0>>, <<2, 3>>, <<3, 2>> })

(*
  @type: (() => Seq(Int));
*)
probeOrder == <<2, 0, 3, 1>>

VARIABLE
  (*
    @type: { copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) };
  *)
  s

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
countSafeOf(st_2133) ==
  (st_2133["count"]
        = Cardinality({
          w_2116 \in workers:
            st_2133["mode"][w_2116] \in activeModes
        })
      /\ st_2133["count"] >= 0)
    /\ st_2133["count"] <= Cardinality((workers))

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
payloadSafeOf(st_2162) ==
  ~(st_2162["staleRead"])
    /\ (\A o_2159 \in objects:
      st_2162["pub"][o_2159] < 2 \/ st_2162["visible"][o_2159] = 2)

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
ownershipSafeOf(st_2209) ==
  \A o_2207 \in objects:
    st_2209["scans"][o_2207] <= 1
      /\ (st_2209["work"][o_2207] /= 2
        \/ Cardinality({
          w_2200 \in workers:
            st_2209["mode"][w_2200] = "scanning"
              /\ st_2209["target"][w_2200] = o_2207
        })
          = 1)

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
eagerOwnerSafeOf(st_2277) ==
  \A o_2275 \in objects:
    st_2277["work"][o_2275] /= -1
      /\ (~(o_2275 \in st_2277["headDone"])
        \/ (st_2277["pub"][o_2275] > 0 /\ st_2277["pub"][o_2275] < 5))
      => st_2277["owner"][o_2275] \in workers

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
fieldPartitionSafeOf(st_2361) ==
  ~(st_2361["foreignHeadWrite"])
    /\ (\A o_2358 \in objects:
      st_2361["headVisits"][o_2358] <= 1
        /\ (o_2358 \in st_2361["headDone"] => st_2361["headVisits"][o_2358] = 1))

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
closureSafeOf(st_2400) ==
  ~(st_2400["terminated"])
    \/ (((st_2400["count"] = 0 /\ st_2400["headDone"] = objects)
        /\ st_2400["tailDone"] = objects)
      /\ (\A o_2396 \in objects: st_2400["work"][o_2396] = 3))

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
localExportSafeOf(st_2459) ==
  \A o_2457 \in objects:
    ~((st_2459["work"][o_2457] = 2 /\ st_2459["route"][o_2457] = "local")
      /\ st_2459["pub"][o_2457] > 0)

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
queueTopologySafeOf(st_2487) ==
  \A o_2485 \in objects:
    st_2487["work"][o_2485] = 1
      => st_2487["queueOf"][o_2485] = st_2487["owner"][o_2485]

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }, Int) => Bool);
*)
markingWorkOf(st_407, w_407) ==
  \E o_405 \in objects:
    st_407["owner"][o_405] = w_407
      /\ (~(o_405 \in st_407["headDone"])
        \/ (st_407["pub"][o_405] > 0 /\ st_407["pub"][o_405] < 5))

(*
  @type: (() => Set(Int));
*)
queues == workers

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
                x_1928 \in workers |->
                  IF x_1928 = w
                  THEN "done"
                  ELSE IF s["mode"][x_1928] = "waiting"
                  THEN "woken"
                  ELSE s["mode"][x_1928]
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
  Cardinality({ w_2097 \in workers: s["mode"][w_2097] \in activeModes })

(*
  @type: (() => Bool);
*)
terminal ==
  s["terminated"] /\ (\A w_2548 \in workers: s["mode"][w_2548] = "done")

(*
  @type: (() => Set(Int));
*)
queued == { o_349 \in objects: s["work"][o_349] = 1 }

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
    waiting == { x_786 \in workers: s["mode"][x_786] = "waiting" }
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
  @type: (() => Bool);
*)
countSafe == countSafeOf(s)

(*
  @type: (() => Bool);
*)
payloadSafe == payloadSafeOf(s)

(*
  @type: (() => Bool);
*)
ownershipSafe == ownershipSafeOf(s)

(*
  @type: (() => Bool);
*)
eagerOwnerSafe == eagerOwnerSafeOf(s)

(*
  @type: (() => Bool);
*)
fieldPartitionSafe == fieldPartitionSafeOf(s)

(*
  @type: (() => Bool);
*)
closureSafe == closureSafeOf(s)

(*
  @type: (() => Bool);
*)
localExportSafe == localExportSafeOf(s)

(*
  @type: (() => Bool);
*)
queueTopologySafe == queueTopologySafeOf(s)

(*
  @type: ((Str, Str) => { copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) });
*)
initial(policy_252, fault_252) ==
  [policy |-> policy_252,
    fault |-> fault_252,
    mode |-> [ w_124 \in workers |-> "active" ],
    work |-> SetAsFun({ <<0, 0>>, <<1, (-1)>>, <<2, 0>>, <<3, (-1)>> }),
    owner |-> SetAsFun({ <<0, 0>>, <<1, (-1)>>, <<2, 1>>, <<3, (-1)>> }),
    copied |-> [ o_162 \in objects |-> 0 ],
    visible |-> [ o_168 \in objects |-> 0 ],
    pub |-> [ o_174 \in objects |-> 0 ],
    queueOf |-> [ o_181 \in objects |-> -1 ],
    route |-> [ o_187 \in objects |-> "" ],
    queueOwner |-> [ q_194 \in queues |-> -1 ],
    scans |-> [ o_200 \in objects |-> 0 ],
    target |-> [ w_207 \in workers |-> -1 ],
    probeIndex |-> [ w_213 \in workers |-> 0 ],
    remaining |-> [ w_219 \in workers |-> {} ],
    found |-> [ w_225 \in workers |-> FALSE ],
    headDone |-> {},
    tailDone |-> {},
    headVisits |-> [ o_235 \in objects |-> 0 ],
    foreignHeadWrite |-> FALSE,
    mutex |-> -1,
    count |-> 4,
    spuriousUsed |-> {},
    staleRead |-> FALSE,
    terminated |-> FALSE]

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }, Int) => Bool);
*)
privateWorkOf(st_437, w_437) ==
  markingWorkOf(st_437, w_437)
    \/ (\E o_434 \in objects:
      st_437["owner"][o_434] = w_437 /\ st_437["work"][o_434] = 0)

(*
  @type: ((Int) => Bool);
*)
markingWork(w_445) == markingWorkOf(s, w_445)

(*
  @type: (() => Bool);
*)
finished == terminal /\ s' := s

(*
  @type: ((Int) => Bool);
*)
queuePending(q_366) == \E o_364 \in queued: s["queueOf"][o_364] = q_366

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
producerLifetimeSafeOf(st_2229) ==
  \A w_2227 \in workers:
    privateWorkOf(st_2229, w_2227) => st_2229["mode"][w_2227] \in activeModes

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
localDrainSafeOf(st_2326) ==
  \A w_2324 \in workers:
    st_2326["mode"][w_2324]
      \in { "probe", "probed", "recheck", "pre-wait", "waiting", "woken", "done"
      }
      => ~(privateWorkOf(st_2326, w_2324))
        /\ ~(\E o_2319 \in objects:
          st_2326["work"][o_2319] = 1 /\ st_2326["queueOf"][o_2319] = w_2324)

(*
  @type: (() => Bool);
*)
restoreSafe == countSafe

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
initEarlyIdle == s = initial("combined", "early-idle")

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
initSkipLocalDrain == s' := (initial("combined", "skip-local-drain"))

(*
  @type: (() => Bool);
*)
initEarlyOwnerRelease == s' := (initial("combined", "early-owner-release"))

(*
  @type: (() => Bool);
*)
initSource == s' := (initial("source", "none"))

(*
  @type: (() => Bool);
*)
initCombined == s' := (initial("combined", "none"))

(*
  @type: (() => Bool);
*)
init == \E policy \in { "source", "combined" }: s' := (initial(policy, "none"))

(*
  @type: ((Int) => Bool);
*)
privateWork(w_453) == privateWorkOf(s, w_453)

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
producerLifetimeSafe == producerLifetimeSafeOf(s)

(*
  @type: (() => Bool);
*)
localDrainSafe == localDrainSafeOf(s)

(*
  @type: (({ copied: (Int -> Int), count: Int, fault: Str, foreignHeadWrite: Bool, found: (Int -> Bool), headDone: Set(Int), headVisits: (Int -> Int), mode: (Int -> Str), mutex: Int, owner: (Int -> Int), policy: Str, probeIndex: (Int -> Int), pub: (Int -> Int), queueOf: (Int -> Int), queueOwner: (Int -> Int), remaining: (Int -> Set(Int)), route: (Int -> Str), scans: (Int -> Int), spuriousUsed: Set(Int), staleRead: Bool, tailDone: Set(Int), target: (Int -> Int), terminated: Bool, visible: (Int -> Int), work: (Int -> Int) }) => Bool);
*)
safeOf(st_2527) ==
  ((((((((countSafeOf(st_2527) /\ payloadSafeOf(st_2527))
                  /\ ownershipSafeOf(st_2527))
                /\ producerLifetimeSafeOf(st_2527))
              /\ closureSafeOf(st_2527))
            /\ localExportSafeOf(st_2527))
          /\ queueTopologySafeOf(st_2527))
        /\ fieldPartitionSafeOf(st_2527))
      /\ eagerOwnerSafeOf(st_2527))
    /\ localDrainSafeOf(st_2527)

(*
  @type: ((Int) => Bool);
*)
ready(w_461) == ~(privateWork(w_461))

(*
  @type: (() => Bool);
*)
q_init == initEarlyIdle

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
safe == safeOf(s)

(*
  @type: (() => Bool);
*)
q_inv == producerLifetimeSafe

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
progress == [](terminal \/ ENABLED step) /\ (WF_{s}(step) => <>terminal)

(*
  @type: (() => Bool);
*)
q_step == step

================================================================================
