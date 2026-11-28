// One eligible section admits one rest grant. A claim whose soft room is
// short of the batch restores the assigned count and publishes nothing.
// This is abstract ledger arithmetic, not a GSI trace or the 295/300 campaign.
module rest_section_grant {
  pure def halfWords: int = 65536
  pure def fudgeWords: int = 9220
  pure def softRoom: int = halfWords - fudgeWords
  pure def retryWords: int = 12002

  pure def granted(claimed: bool, room: int, words: int): bool =
    claimed and words >= 0 and room >= words

  pure def assignedAfter(assigned: int, claimed: bool, room: int, words: int): int =
    if (granted(claimed, room, words)) assigned + 1 else assigned

  pure def firstGetsSection(freeSections: int, room: int, words: int): bool =
    freeSections >= 1 and granted(true, room, words)

  pure def secondGetsSection(freeSections: int, room: int, words: int): bool =
    freeSections >= 2 and granted(true, room, words)

  run oneSectionOneGrantTest =
    assert(firstGetsSection(1, softRoom, retryWords) and
           not(secondGetsSection(1, softRoom, retryWords)) and
           softRoom == 56316 and retryWords < softRoom)

  run failedExtentRefundsLedgerTest =
    assert(not(granted(true, retryWords - 1, retryWords)) and
           assignedAfter(4, true, retryWords - 1, retryWords) == 4)

  run exactExtentKeepsOneAssignmentTest =
    assert(granted(true, retryWords, retryWords) and
           assignedAfter(4, true, retryWords, retryWords) == 5)

  run insufficientBudgetDoesNotClaimTest =
    assert(not(granted(false, softRoom, retryWords)) and
           assignedAfter(4, false, softRoom, retryWords) == 4)

  run partialBatchStaysZeroTest =
    assert(not(granted(true, softRoom, softRoom + 1)) and
           assignedAfter(1, true, softRoom, softRoom + 1) == 1)

  // The count and cursor are VM-owned. An earlier snapshot cannot undo a
  // different owner's commit, even when the rejecting owner holds the lock.
  type Ledger = { cursor: int, assigned: int, owner: int, snapshot: int }
  var ledger: Ledger

  action start = ledger' = { cursor: 0, assigned: 0, owner: 0, snapshot: 0 }
  action takeOldSnapshot = ledger' = { ...ledger, snapshot: ledger.cursor }
  action otherCommits = all {
    ledger.owner == 0,
    ledger' = { ...ledger, cursor: 1, assigned: 1, owner: 1 },
  }
  action rejectWithOldRollback = all {
    ledger.owner == 1,
    ledger' = { ...ledger, cursor: ledger.snapshot, assigned: ledger.snapshot },
  }
  action rejectBeforeClaim = all { ledger.owner == 1, ledger' = ledger }
  action secondTriesLastSection = all { ledger.cursor == 1, ledger' = ledger }

  val committedOwnerKeepsSection =
    ledger.owner == 0 or (ledger.cursor == 1 and ledger.assigned == 1)

  run preLockSnapshotCanUndoOtherGrantTest =
    start.then(takeOldSnapshot).then(otherCommits).then(rejectWithOldRollback)
      .expect(not(committedOwnerKeepsSection))

  run rejectBeforeClaimPreservesOtherGrantTest =
    start.then(otherCommits).then(rejectBeforeClaim).then(secondTriesLastSection)
      .expect(committedOwnerKeepsSection and ledger.owner == 1)
}

// Two contenders interleave acquisition, validation and publication. The
// lock/linearization correspondence and actual word geometry are native duties.
module rest_section_claim {
  type Claim = {
    free: int, lockOwner: int, checked: bool, owner: int, room: int, words: int,
    grants: Set[int], refused: Set[int], custody: Set[int], snapshot: int,
    requested: Set[int], published: Set[int], eligible: Set[int]
  }
  var claim: Claim
  val actors = Set(1, 2)
  action init = claim' = {
    free: 1, lockOwner: 0, checked: false, owner: 0, room: 2, words: 2,
    grants: Set(), refused: Set(), custody: actors, snapshot: 1,
    requested: Set(), published: Set(), eligible: actors
  }
  action shortInit = init.then(all { claim' = {...claim, room: 1} })
  // The handler supplies a coherent post-recovery view. A short soft grant
  // with enough physical room never reaches the fresh-section lock.
  pure def mayRequest(c: Claim, actor: int, validSource: bool,
    reloaded: bool, stackFits: bool, soft: int, hardTail: int, guard: int): bool =
    Set(1, 2).contains(actor) and validSource and reloaded and stackFits and
    c.words > 0 and soft >= 0 and soft < c.words and hardTail >= 0 and guard >= 0 and
    hardTail < guard + c.words and not(c.requested.contains(actor))
  action request(actor: int, soft: int, hardTail: int, guard: int): bool = all {
    mayRequest(claim, actor, true, true, true, soft, hardTail, guard),
    claim' = {...claim, requested: claim.requested.union(Set(actor))}
  }
  action twoRequests = request(1, 1, 4, 3).then(request(2, 1, 4, 3))
  pure def pending(current: Claim, actor: int): bool = Set(1, 2).contains(actor) and
    current.requested.contains(actor) and
    not(current.grants.contains(actor)) and not(current.refused.contains(actor))
  action acquire(actor: int): bool = all {
    pending(claim, actor), claim.lockOwner == 0,
    claim' = {...claim, lockOwner: actor, checked: false}
  }
  action validate(actor: int): bool = all {
    claim.lockOwner == actor, not(claim.checked),
    claim' = {...claim, checked: true}
  }
  pure def fitsCandidate(c: Claim, actor: int): bool =
    c.free == 1 and c.eligible.contains(actor) and c.words <= c.room
  action commit(actor: int): bool = all {
    claim.lockOwner == actor, claim.checked, fitsCandidate(claim, actor),
    claim' = {...claim, free: 0, owner: actor, lockOwner: 0, checked: false,
      grants: claim.grants.union(Set(actor))}
  }
  // Publication occurs after the lock is released; the concrete producer
  // must supply the actual room and retained custody. A claim is not a grant.
  pure def mayPublish(c: Claim, actor: int, actualRoom: int): bool =
    c.owner == actor and c.grants.contains(actor) and
    not(c.published.contains(actor)) and actualRoom >= c.words
  action publish(actor: int, actualRoom: int): bool = all {
    mayPublish(claim, actor, actualRoom),
    claim' = {...claim, published: claim.published.union(Set(actor))}
  }
  action refuse(actor: int): bool = all {
    claim.lockOwner == actor, claim.checked, not(fitsCandidate(claim, actor)),
    claim' = {...claim, lockOwner: 0, checked: false,
      refused: claim.refused.union(Set(actor))}
  }
  val safe = all {
    claim.free >= 0, claim.free + claim.grants.size() == 1,
    claim.grants.size() <= 1,
    (claim.owner == 0) == (claim.grants.size() == 0),
    claim.owner == 0 or claim.grants.contains(claim.owner),
    claim.custody == actors,
    claim.grants.intersect(claim.refused).size() == 0,
    claim.published.subseteq(claim.grants),
    claim.grants.subseteq(claim.requested),
    not(claim.checked) or actors.contains(claim.lockOwner)
  }
  action step = {
    nondet actor = actors.oneOf()
    any { request(actor, 1, 4, 3), acquire(actor), validate(actor), commit(actor),
          publish(actor, claim.room), refuse(actor), claim' = claim }
  }
  action staleRollback = claim' = {...claim, free: claim.snapshot, owner: 0}
  action publishWithoutLock(actor: int): bool = claim' = {
    ...claim, free: 0, owner: actor, grants: claim.grants.union(Set(actor))
  }

  run firstContenderWinsTest = init.then(twoRequests).then(acquire(1)).then(validate(1)).then(commit(1))
    .then(acquire(2)).then(validate(2)).then(refuse(2))
    .then(publish(1, 2)).expect(safe and claim.published == Set(1) and claim.refused == Set(2))
  run secondContenderWinsTest = init.then(twoRequests).then(acquire(2)).then(validate(2)).then(commit(2))
    .then(acquire(1)).then(validate(1)).then(refuse(1))
    .then(publish(2, 2)).expect(safe and claim.published == Set(2) and claim.refused == Set(1))
  run oneWordShortPublishesNothingTest = shortInit.then(twoRequests).then(acquire(1))
    .then(validate(1)).then(refuse(1)).then(acquire(2)).then(validate(2)).then(refuse(2))
    .expect(safe and claim.free == 1 and claim.grants == Set() and claim.refused == actors)
  run heldLockKeepsOtherContenderPendingTest = init.then(twoRequests).then(acquire(1)).then(validate(1))
    .expect(safe and claim.lockOwner == 1 and pending(claim, 2) and claim.custody.contains(2))
  run staleRollbackErasesWinnerControlTest = init.then(twoRequests).then(acquire(1)).then(validate(1))
    .then(commit(1)).then(staleRollback).expect(not(safe))
  run unlockedSecondClaimControlTest = init.then(twoRequests).then(acquire(1)).then(validate(1))
    .then(commit(1)).then(publishWithoutLock(2)).expect(not(safe))
  run invalidOrSufficientCannotEnterContestTest = init
    .expect(not(mayRequest(claim, 1, false, true, true, 1, 4, 3)) and
      not(mayRequest(claim, 1, true, false, true, 1, 4, 3)) and
      not(mayRequest(claim, 1, true, true, false, 1, 4, 3)) and
      not(mayRequest(claim, 2, true, true, true, 2, 5, 3)) and not(pending(claim, 1)))
  run softOnlyShortageDoesNotRequestSectionTest = init
    .expect(not(mayRequest(claim, 1, true, true, true, 1, 5, 3)) and
      mayRequest(claim, 1, true, true, true, 1, 4, 3))
  run claimDoesNotSupplyPublicationTest = init.then(twoRequests).then(acquire(1))
    .then(validate(1)).then(commit(1)).expect(safe and claim.published == Set() and
      not(mayPublish(claim, 1, 1)) and mayPublish(claim, 1, 2))
}
