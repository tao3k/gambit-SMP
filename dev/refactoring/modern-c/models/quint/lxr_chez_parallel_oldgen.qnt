// Phase B: LXR Shared Old Generation (Deferred RC + Immix Line Recycling + Concurrent SATB)
// + Chez-Style Parallel Work-Stealing Evacuation (CAS Forwarding Uniqueness)
module lxr_chez_parallel_oldgen {
  pure val OBJS: Set[int] = Set(1, 2, 3)
  pure val WORKERS: Set[int] = Set(0, 1)

  // Object lifecycle state in shared old gen S:
  //   "LIVE"      -> live in Immix block
  //   "EVACUATED" -> moved by parallel worker; fwd[o] holds unique new block ID
  //   "RECLAIMED" -> reclaimed by DRC or SATB sweep
  var objState: int -> str

  // Root reachability flag (1 = referenced by mutator root)
  var rooted: int -> bool

  // Deferred RC count (non-negative; >= 1 if referenced by another live object)
  var drc: int -> int

  // SATB mark state during concurrent major cycle: "WHITE", "GREY", "BLACK"
  var color: int -> str

  // Concurrent SATB cycle active flag
  var satbActive: bool

  // SATB pre-write log buffer (set of object IDs logged before pointer overwrite)
  var satbLog: Set[int]

  // Unique forwarding destination installed via CAS (0 = none, 10/11 = worker target block)
  var fwd: int -> int

  // Number of CAS winners for each object (must never exceed 1)
  var fwdWinners: int -> int

  action init = all {
    objState' = OBJS.mapBy(_ => "LIVE"),
    rooted' = Map(1 -> true, 2 -> true, 3 -> false),
    drc' = Map(1 -> 1, 2 -> 1, 3 -> 0),
    color' = OBJS.mapBy(_ => "WHITE"),
    satbActive' = false,
    satbLog' = Set(),
    fwd' = OBJS.mapBy(_ => 0),
    fwdWinners' = OBJS.mapBy(_ => 0),
  }

  // Start concurrent SATB major marking: snapshot all currently rooted live objects as GREY
  action startSATB: bool = all {
    not(satbActive),
    satbActive' = true,
    color' = OBJS.mapBy(o =>
      if (objState.get(o) != "RECLAIMED" and rooted.get(o)) "GREY" else "WHITE"
    ),
    satbLog' = Set(),
    objState' = objState,
    rooted' = rooted,
    drc' = drc,
    fwd' = fwd,
    fwdWinners' = fwdWinners,
  }

  // Mutator drops a root reference to object o:
  // If SATB is active, Yuasa pre-write barrier logs o before clearing the root.
  action dropRoot(o: int): bool = all {
    rooted.get(o),
    rooted' = rooted.set(o, false),
    drc' = drc.set(o, if (drc.get(o) > 0) drc.get(o) - 1 else 0),
    satbLog' = if (satbActive and objState.get(o) != "RECLAIMED") satbLog.union(Set(o)) else satbLog,
    satbActive' = satbActive,
    color' = color,
    objState' = objState,
    fwd' = fwd,
    fwdWinners' = fwdWinners,
  }

  // Concurrent marker drains an object from satbLog into GREY
  action drainSATBLog(o: int): bool = all {
    satbActive,
    satbLog.contains(o),
    satbLog' = satbLog.exclude(Set(o)),
    color' = if (color.get(o) == "WHITE") color.set(o, "GREY") else color,
    satbActive' = satbActive,
    objState' = objState,
    rooted' = rooted,
    drc' = drc,
    fwd' = fwd,
    fwdWinners' = fwdWinners,
  }

  // Concurrent marker shades a GREY object BLACK
  action markGreyToBlack(o: int): bool = all {
    satbActive,
    color.get(o) == "GREY",
    color' = color.set(o, "BLACK"),
    satbActive' = satbActive,
    satbLog' = satbLog,
    objState' = objState,
    rooted' = rooted,
    drc' = drc,
    fwd' = fwd,
    fwdWinners' = fwdWinners,
  }

  // Finish SATB cycle once all GREY objects and SATB logs are drained; reclaim WHITE objects
  action finishSATBSweep: bool = all {
    satbActive,
    satbLog == Set(),
    OBJS.forall(o => color.get(o) != "GREY"),
    objState' = OBJS.mapBy(o =>
      if (objState.get(o) != "RECLAIMED" and color.get(o) == "WHITE" and not(rooted.get(o)))
        "RECLAIMED"
      else objState.get(o)
    ),
    satbActive' = false,
    color' = OBJS.mapBy(_ => "WHITE"),
    satbLog' = Set(),
    rooted' = rooted,
    drc' = drc,
    fwd' = fwd,
    fwdWinners' = fwdWinners,
  }

  // LXR Deferred-RC immediate line reclaim:
  // Reclaim only when SATB is inactive, drc[o] == 0, and not rooted.
  action drcReclaim(o: int): bool = all {
    not(satbActive),
    objState.get(o) == "LIVE",
    drc.get(o) == 0,
    not(rooted.get(o)),
    objState' = objState.set(o, "RECLAIMED"),
    rooted' = rooted,
    drc' = drc,
    color' = color,
    satbActive' = satbActive,
    satbLog' = satbLog,
    fwd' = fwd,
    fwdWinners' = fwdWinners,
  }

  // Chez-style parallel work-stealing evacuation:
  // Worker w races to install forwarding pointer (10 + w) via CAS (succeeds iff fwd[o] == 0).
  action parallelEvacCAS(w: int, o: int): bool = all {
    objState.get(o) == "LIVE",
    rooted.get(o),
    fwd.get(o) == 0,
    fwd' = fwd.set(o, 10 + w),
    fwdWinners' = fwdWinners.set(o, fwdWinners.get(o) + 1),
    objState' = objState.set(o, "EVACUATED"),
    rooted' = rooted,
    drc' = drc,
    color' = color,
    satbActive' = satbActive,
    satbLog' = satbLog,
  }

  action step = any {
    startSATB,
    finishSATBSweep,
    nondet o = OBJS.oneOf()
    nondet w = WORKERS.oneOf()
    any {
      dropRoot(o),
      drainSATBLog(o),
      markGreyToBlack(o),
      drcReclaim(o),
      parallelEvacCAS(w, o),
    }
  }

  // Invariant 1: No rooted live object is ever reclaimed (no use-after-reclaim)
  val inv_no_use_after_reclaim: bool = OBJS.forall(o =>
    rooted.get(o) implies objState.get(o) != "RECLAIMED"
  )

  // Invariant 2: CAS forwarding installation has at most 1 winner per object
  val inv_forwarding_unique: bool = OBJS.forall(o =>
    fwdWinners.get(o) <= 1 and (objState.get(o) == "EVACUATED" implies fwd.get(o) != 0)
  )

  // Invariant 3: When SATB is active, every currently rooted object is protected
  // (either GREY, BLACK, or present in satbLog)
  val inv_satb_no_lost_object: bool =
    satbActive implies OBJS.forall(o =>
      rooted.get(o) implies (color.get(o) != "WHITE" or satbLog.contains(o))
    )

  // Invariant 4: DRC count is never negative
  val inv_drc_nonneg: bool = OBJS.forall(o => drc.get(o) >= 0)

  val inv_all: bool = all {
    inv_no_use_after_reclaim,
    inv_forwarding_unique,
    inv_satb_no_lost_object,
    inv_drc_nonneg,
  }
}
