module completed_source_selection {
  // A checked plan selects custody, never a numeric identifier or filename rank.
  type State = { explicit: bool, valid: bool, ambiguous: bool,
    sourceBound: bool, productBound: bool, globalFirstValid: bool,
    checked: bool, chosenExplicit: bool, reused: bool, policy: str }
  var s: State
  pure def initial(explicit: bool, valid: bool, ambiguous: bool,
                   sourceBound: bool, productBound: bool, globalFirstValid: bool,
                   policy: str): State = {
    explicit: explicit, valid: valid, ambiguous: ambiguous,
    sourceBound: sourceBound, productBound: productBound, globalFirstValid: globalFirstValid,
    checked: false, chosenExplicit: false, reused: false, policy: policy,
  }
  action init = {
    nondet explicit = Set(false, true).oneOf()
    nondet valid = Set(false, true).oneOf()
    nondet ambiguous = Set(false, true).oneOf()
    nondet sourceBound = Set(false, true).oneOf()
    nondet productBound = Set(false, true).oneOf()
    nondet globalFirstValid = Set(false, true).oneOf()
    s' = initial(explicit, valid, ambiguous, sourceBound, productBound, globalFirstValid, "strict")
  }
  action initSorted = s' = initial(true, true, false, true, true, false, "sorted")
  action initFallback = s' = initial(true, false, false, true, true, true, "fallback")
  action initAmbiguous = s' = initial(true, true, true, true, true, true, "ambiguous")
  val explicitEligible = s.explicit and s.valid and not(s.ambiguous) and s.sourceBound and s.productBound
  action selectProducer = all {
    not(s.checked),
    s' = { ...s, checked: true,
      chosenExplicit: s.explicit and s.policy != "sorted",
      reused: if (s.policy == "sorted") s.globalFirstValid
              else if (s.policy == "fallback") s.globalFirstValid
              else if (s.policy == "ambiguous") s.valid and s.sourceBound and s.productBound
              else if (s.explicit) explicitEligible
              else s.globalFirstValid and s.sourceBound and s.productBound },
  }
  action step = any { selectProducer, s' = s }
  val exactCustody = not(s.reused) or (s.sourceBound and s.productBound
    and (not(s.explicit) or (s.valid and not(s.ambiguous) and s.chosenExplicit)))
  val noFilenameVeto = not(s.checked and explicitEligible) or (s.reused and s.chosenExplicit)
  val safe = exactCustody and noFilenameVeto
  temporal completion = weakFair(selectProducer, s).implies(eventually(s.checked))
}
