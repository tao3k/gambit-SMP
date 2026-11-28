module gvm_poll_dominance {
  // Poll kinds carried by gsc/_gvm.scm on source lock 3ffea79b…:
  //   "none"  = #f, "stack" = 'stack, "full" = #t.
  // combine follows combine-poll: #t wins, otherwise 'stack, otherwise #f.
  // dominates is the skip permission that combination must preserve:
  //   full covers every kind, stack covers none and stack, none covers none.
  // replacementSkip is the patched find-equiv-lbl test:
  //   eqv?(combine-poll(incoming, branch), incoming).
  // oldSkip is the boolean test still in that function on this lock:
  //   (or incoming (not branch)), with only #f falsy.
  // The walk visits all 9 pairs. It does not encode basic blocks, and a
  // satisfying run is not GVM reachability, bootstrap, or runtime admission.

  pure def combine(a: str, b: str): str =
    if (a == "full" or b == "full") "full"
    else if (a == "stack" or b == "stack") "stack"
    else "none"

  pure def dominates(incoming: str, branch: str): bool =
    if (incoming == "full") true
    else if (incoming == "stack") not(branch == "full")
    else incoming == "none" and branch == "none"

  pure def replacementSkip(incoming: str, branch: str): bool =
    combine(incoming, branch) == incoming

  pure def oldSkip(incoming: str, branch: str): bool =
    not(incoming == "none") or branch == "none"

  pure def pairReplacementAgrees(incoming: str, branch: str): bool =
    replacementSkip(incoming, branch) == dominates(incoming, branch)

  pure def pairOldAgrees(incoming: str, branch: str): bool =
    oldSkip(incoming, branch) == dominates(incoming, branch)

  pure def codeName(code: int): str =
    if (code == 0) "none"
    else if (code == 1) "stack"
    else "full"

  // Index i packs branch = i / 3 and incoming = i % 3. Pair 7 is stack then full.
  pure val exhaustive =
    0.to(8).forall(i =>
      pairReplacementAgrees(codeName(i % 3), codeName(i / 3)) and
      (not(pairOldAgrees(codeName(i % 3), codeName(i / 3))) == (i == 7)))

  type State = {
    phase: str,
    index: int,
    incoming: str,
    branch: str,
    seenOldDefect: bool
  }
  var s: State

  action initScan = s' = {
    phase: "scan", index: 0, incoming: "none", branch: "none",
    seenOldDefect: false
  }

  action advance = all {
    s.phase == "scan",
    s.index >= 0,
    s.index < 9,
    s.incoming == codeName(s.index % 3),
    s.branch == codeName(s.index / 3),
    s' = {
      phase: if (s.index + 1 == 9) "done" else "scan",
      index: s.index + 1,
      incoming: if (s.index + 1 == 9) s.incoming else codeName((s.index + 1) % 3),
      branch: if (s.index + 1 == 9) s.branch else codeName((s.index + 1) / 3),
      seenOldDefect: s.seenOldDefect or not(pairOldAgrees(s.incoming, s.branch))
    }
  }
  action hold = all { s.phase == "done", s' = s }
  action step = any { advance, hold }

  val replacementAgrees = exhaustive and
    (s.phase == "scan" implies
      s.index >= 0 and s.index < 9 and
      s.incoming == codeName(s.index % 3) and
      s.branch == codeName(s.index / 3) and
      pairReplacementAgrees(s.incoming, s.branch)) and
    (s.phase == "done" implies s.index == 9 and s.seenOldDefect)
  val oldAgrees = s.phase != "scan" or pairOldAgrees(s.incoming, s.branch)
  temporal progress = weakFair(step, Set(s)).implies(eventually(s.phase == "done"))
}
