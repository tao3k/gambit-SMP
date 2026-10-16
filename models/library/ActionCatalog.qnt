// Finite subject-scoped action projection, not scientific or host authority.
module ActionCatalog {
  const Mutation: str
  var studies: Set[int]
  var bindingOwner: int
  var referenceOwner: int
  var referenceCurrent: bool
  var generation: int
  var snapshot: int
  var published: Set[int]
  var supported: Set[int]
  var authorized: bool

  val actions = studies
  val sourceSupport = studies.filter(s =>
    referenceCurrent and bindingOwner == s and
    (referenceOwner == s or Mutation == "foreign-support"))

  action init = all {
    studies' = Set(0, 1), bindingOwner' = 0, referenceOwner' = 1,
    referenceCurrent' = true, generation' = 0, snapshot' = -1,
    published' = Set(), supported' = Set(), authorized' = false
  }
  action Discover = all {
    published' = actions, supported' = sourceSupport, snapshot' = generation,
    authorized' = Mutation == "inference-authority",
    studies' = studies, bindingOwner' = bindingOwner, referenceOwner' = referenceOwner,
    referenceCurrent' = referenceCurrent, generation' = generation
  }
  action MatchReference = all {
    referenceOwner' = bindingOwner, generation' = generation + 1, generation < 3,
    studies' = studies, bindingOwner' = bindingOwner, referenceCurrent' = referenceCurrent,
    snapshot' = snapshot, published' = published, supported' = supported, authorized' = authorized
  }
  action Withdraw = all {
    generation < 3, referenceCurrent' = false,
    generation' = if (Mutation == "stale-withdrawal") generation else generation + 1,
    studies' = studies, bindingOwner' = bindingOwner, referenceOwner' = referenceOwner,
    snapshot' = snapshot, published' = published, supported' = supported, authorized' = authorized
  }
  action RemoveStudy = all {
    generation < 3, studies' = studies.exclude(Set(bindingOwner)), generation' = generation + 1,
    bindingOwner' = bindingOwner, referenceOwner' = referenceOwner,
    referenceCurrent' = referenceCurrent, snapshot' = snapshot, published' = published,
    supported' = supported, authorized' = authorized
  }
  action step = any {Discover, MatchReference, Withdraw, RemoveStudy}
  val Safe = all {
    not(authorized),
    snapshot == generation implies published == actions,
    snapshot == generation implies supported == studies.filter(s =>
      referenceCurrent and bindingOwner == s and referenceOwner == s)
  }
}
