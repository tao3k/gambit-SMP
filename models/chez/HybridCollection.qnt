// Two live objects, four alias roots, two fixed segment owners; stopped mutators.
// SC actions abstract payload/bitmap visibility, not native fences or fairness.
module HybridCollection {
  import WorkObligations.* from "../library/gc/WorkObligations"
  const Mutation: str
  val objects = Set(0, 1)
  val slots = Set(0, 1, 2, 3)
  pure def objectOf(r: int): int = if (r < 2) 0 else 1
  pure def segment(profile: str, o: int): int = if (profile == "mixed-new") 0 else o
  pure def owner(profile: str, o: int): int = segment(profile, o)
  // Eligibility abstracts min_mark_gen/MIN_TG; compact includes segment+chunk tests.
  pure def shouldMark(profile: str, o: int): bool =
    if (profile == "mixed-new") o == 0
    else profile == "immobile" or profile == "compact-target"
  pure def canonical(profile: str, o: int): int =
    if (shouldMark(profile, o)) o else o + 2
  type State = { profile: str, mode: int -> str, refs: int -> int,
    pending: Set[int], privateWork: Set[int], queued: Set[int], scanning: Set[int],
    initialized: Set[int], addressWritten: Set[int], forwarded: Set[int],
    marked: Set[int], scanned: Set[int], bitmapReady: Set[int],
    wrongOwner: bool, done: bool }
  var s: State
  action init = {
    nondet profile = Set("copy", "immobile", "compact-target", "sparse-target", "mixed-new").oneOf()
    s' = { profile: profile, mode: Map(0 -> "", 1 -> ""),
      refs: Map(0 -> 0, 1 -> 0, 2 -> 1, 3 -> 1), pending: objects,
      privateWork: Set(), queued: Set(), scanning: Set(), initialized: Set(),
      addressWritten: Set(), forwarded: Set(), marked: Set(), scanned: Set(),
      bitmapReady: Set(), wrongOwner: false, done: false }
  }
  action prepare(o: int, w: int): bool = all {
    not(s.done), s.pending.contains(o),
    w == owner(s.profile, o) or Mutation == "wrong-owner",
    s' = { ...s, pending: s.pending.exclude(Set(o)), privateWork: s.privateWork.union(Set(o)),
      mode: s.mode.set(o, if (shouldMark(s.profile, o) or
        (Mutation == "mask-selects-mode" and s.profile == "mixed-new" and
          s.bitmapReady.contains(segment(s.profile, o))))
        "mark" else "copy"), wrongOwner: s.wrongOwner or w != owner(s.profile, o) }
  }
  action initialize(o: int): bool = all {
    not(s.done), s.privateWork.contains(o), not(s.initialized.contains(o)),
    s' = { ...s, initialized: s.initialized.union(Set(o)),
      bitmapReady: if (s.mode.get(o) == "mark")
        s.bitmapReady.union(Set(segment(s.profile, o))) else s.bitmapReady }
  }
  // mkgc.ss emits FWDADDRESS before FWDMARKER; payload body precedes both.
  action writeAddress(o: int): bool = all {
    not(s.done), s.privateWork.contains(o), s.mode.get(o) == "copy",
    s.initialized.contains(o),
    s' = { ...s, addressWritten: s.addressWritten.union(Set(o)) }
  }
  action publishCopy(o: int): bool = all {
    not(s.done), s.privateWork.contains(o), s.mode.get(o) == "copy",
    s.addressWritten.contains(o) or Mutation == "early-forward",
    s' = { ...s, privateWork: s.privateWork.exclude(Set(o)), queued: s.queued.union(Set(o)),
      forwarded: s.forwarded.union(Set(o)) }
  }
  action publishMark(o: int): bool = all {
    not(s.done), s.privateWork.contains(o), s.mode.get(o) == "mark",
    s.initialized.contains(o) or Mutation == "early-bitmap",
    s' = { ...s, privateWork: s.privateWork.exclude(Set(o)), queued: s.queued.union(Set(o)),
      marked: s.marked.union(Set(o)) }
  }
  action redirect(r: int): bool = all {
    not(s.done), s.forwarded.contains(objectOf(r)) or s.marked.contains(objectOf(r)),
    s' = { ...s, refs: s.refs.set(r,
      if (s.mode.get(objectOf(r)) == "mark") objectOf(r) else objectOf(r) + 2) }
  }
  action acquire(o: int): bool = all {
    not(s.done), s.queued.contains(o),
    s' = { ...s, queued: s.queued.exclude(Set(o)), scanning: s.scanning.union(Set(o)) }
  }
  action scan(o: int): bool = all {
    not(s.done), s.scanning.contains(o),
    s' = { ...s, scanning: s.scanning.exclude(Set(o)), scanned: s.scanned.union(Set(o)) }
  }
  action finish = all {
    not(s.done),
    (s.pending.size() == 0 and s.scanned == objects and
      noOutstanding(s.privateWork, Set(), s.queued, s.scanning) and
      slots.forall(r => s.refs.get(r) == canonical(s.profile, objectOf(r))))
      or Mutation == "early-finish",
    s' = { ...s, done: true }
  }
  action step = any {
    prepare(0, 0), prepare(1, 1), prepare(0, 1), prepare(1, 0),
    initialize(0), initialize(1), writeAddress(0), writeAddress(1),
    publishCopy(0), publishCopy(1), publishMark(0), publishMark(1),
    redirect(0), redirect(1), redirect(2), redirect(3),
    acquire(0), acquire(1), scan(0), scan(1), finish
  }
  val modeSafe = objects.forall(o => s.mode.get(o) == "" or
    (s.mode.get(o) == "mark") == shouldMark(s.profile, o))
  val publicationSafe = s.forwarded.subseteq(s.initialized) and
    s.forwarded.subseteq(s.addressWritten) and s.marked.subseteq(s.initialized) and
    s.marked.forall(o => s.bitmapReady.contains(segment(s.profile, o))) and
    s.forwarded.intersect(s.marked).size() == 0
  val identitySafe = objects.forall(o => canonicalReferences(s.refs,
    slots.filter(r => objectOf(r) == o), o, canonical(s.profile, o)))
  val closureSafe = s.done implies (s.scanned == objects and s.pending.size() == 0 and
    noOutstanding(s.privateWork, Set(), s.queued, s.scanning) and
    slots.forall(r => s.refs.get(r) == canonical(s.profile, objectOf(r))))
  val workConserved = s.pending.union(s.privateWork).union(s.queued).union(s.scanning).union(s.scanned) == objects and
    s.pending.size() + s.privateWork.size() + s.queued.size() + s.scanning.size() + s.scanned.size() == objects.size()
  val Safe = modeSafe and publicationSafe and identitySafe and closureSafe and workConserved and not(s.wrongOwner)
}
