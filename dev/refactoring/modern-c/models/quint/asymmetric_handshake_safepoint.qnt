// Phase C: Asymmetric Per-Processor Handshake Safepoints & FFI Safe-Zone Isolation
// Eliminates global STW barriers by allowing:
//   1. Independent per-processor poll/ack without waiting for sibling cores
//   2. Coordinator-side non-blocking safe-zone scan when a processor is in SAFE_FFI or PARKED
//   3. Strict mutual exclusion between mutator execution and coordinator root scanning
module asymmetric_handshake_safepoint {
  pure val PROCS: Set[int] = Set(0, 1, 2)
  pure val MAX_EPOCH: int = 3

  // Processor handshake state:
  //   "RUNNING"      -> executing Scheme mutator code
  //   "SAFE_FFI"     -> inside C FFI / blocking I/O safe zone (roots saved)
  //   "IN_HANDSHAKE" -> coordinator holds exclusive scan lease on this processor
  var pState: int -> str

  // Global requested handshake epoch
  var reqEpoch: int

  // Per-processor acknowledged epoch
  var ackEpoch: int -> int

  // Whether coordinator currently holds scan ownership of processor p
  var coordScanning: int -> bool

  action init = all {
    pState' = PROCS.mapBy(_ => "RUNNING"),
    reqEpoch' = 0,
    ackEpoch' = PROCS.mapBy(_ => 0),
    coordScanning' = PROCS.mapBy(_ => false),
  }

  // Coordinator starts a new handshake epoch once all processors have acked previous epoch
  action startEpoch: bool = all {
    reqEpoch < MAX_EPOCH,
    PROCS.forall(p => ackEpoch.get(p) == reqEpoch and not(coordScanning.get(p))),
    reqEpoch' = reqEpoch + 1,
    pState' = pState,
    ackEpoch' = ackEpoch,
    coordScanning' = coordScanning,
  }

  // Mutator p enters FFI / blocking I/O safe zone (saves roots, transitions RUNNING -> SAFE_FFI)
  action enterFFI(p: int): bool = all {
    pState.get(p) == "RUNNING",
    not(coordScanning.get(p)),
    pState' = pState.set(p, "SAFE_FFI"),
    reqEpoch' = reqEpoch,
    ackEpoch' = ackEpoch,
    coordScanning' = coordScanning,
  }

  // Mutator p exits FFI safe zone: can only return to RUNNING if coordinator is NOT scanning it
  action exitFFI(p: int): bool = all {
    pState.get(p) == "SAFE_FFI",
    not(coordScanning.get(p)),
    pState' = pState.set(p, "RUNNING"),
    reqEpoch' = reqEpoch,
    ackEpoch' = ackEpoch,
    coordScanning' = coordScanning,
  }

  // Mutator p hits local poll word, sees ackEpoch[p] < reqEpoch, flushes its own buffer,
  // bumps ackEpoch[p] = reqEpoch, and IMMEDIATELY continues without waiting for any sibling core.
  action mutatorSelfHandshake(p: int): bool = all {
    pState.get(p) == "RUNNING",
    not(coordScanning.get(p)),
    ackEpoch.get(p) < reqEpoch,
    ackEpoch' = ackEpoch.set(p, reqEpoch),
    pState' = pState,
    reqEpoch' = reqEpoch,
    coordScanning' = coordScanning,
  }

  // Coordinator claims exclusive scan lease on a processor already in SAFE_FFI
  // (non-blocking: does NOT wake or wait for p!)
  action coordBeginFFIScan(p: int): bool = all {
    pState.get(p) == "SAFE_FFI",
    not(coordScanning.get(p)),
    ackEpoch.get(p) < reqEpoch,
    pState' = pState.set(p, "IN_HANDSHAKE"),
    coordScanning' = coordScanning.set(p, true),
    reqEpoch' = reqEpoch,
    ackEpoch' = ackEpoch,
  }

  // Coordinator finishes scanning processor p in safe zone, marks ackEpoch[p] = reqEpoch,
  // and releases processor back to SAFE_FFI.
  action coordEndFFIScan(p: int): bool = all {
    pState.get(p) == "IN_HANDSHAKE",
    coordScanning.get(p),
    pState' = pState.set(p, "SAFE_FFI"),
    coordScanning' = coordScanning.set(p, false),
    ackEpoch' = ackEpoch.set(p, reqEpoch),
    reqEpoch' = reqEpoch,
  }

  action step = any {
    startEpoch,
    nondet p = PROCS.oneOf()
    any {
      enterFFI(p),
      exitFFI(p),
      mutatorSelfHandshake(p),
      coordBeginFFIScan(p),
      coordEndFFIScan(p),
    }
  }

  // Invariant 1: Coordinator never scans a processor that is RUNNING mutator code
  val inv_scan_exclusivity: bool = PROCS.forall(p =>
    coordScanning.get(p) implies pState.get(p) == "IN_HANDSHAKE"
  )

  // Invariant 2: Acknowledged epoch never exceeds requested epoch
  val inv_epoch_bounded: bool = PROCS.forall(p =>
    ackEpoch.get(p) >= 0 and ackEpoch.get(p) <= reqEpoch
  )

  // Invariant 3: IN_HANDSHAKE state is strictly coupled with coordScanning ownership
  val inv_lease_coupled: bool = PROCS.forall(p =>
    (pState.get(p) == "IN_HANDSHAKE") == coordScanning.get(p)
  )

  val inv_all: bool = all {
    inv_scan_exclusivity,
    inv_epoch_bounded,
    inv_lease_coupled,
  }
}
