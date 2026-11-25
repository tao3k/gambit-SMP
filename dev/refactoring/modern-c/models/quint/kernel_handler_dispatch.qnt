// Roles are semantic identities. The C slot extractor owns layout evidence.
module kernel_handler_dispatch {
  type Layout = {legacySlotIsRole: bool, generatedMapMatches: bool}
  type State = {layout: Layout, published: bool, dispatched: bool,
    actualRole: bool, rejected: bool}
  var s: State

  pure def initial(legacySlotIsRole: bool, generatedMapMatches: bool): State =
    { layout: {legacySlotIsRole: legacySlotIsRole, generatedMapMatches: generatedMapMatches},
      published: false, dispatched: false, actualRole: false, rejected: false }

  action shifted = s' = initial(false, true)
  action shiftedStale = s' = initial(false, false)
  action original = s' = initial(true, true)
  action publishLegacy = all {
    not(s.published), not(s.rejected),
    s' = { ...s, published: true, actualRole: s.layout.legacySlotIsRole }
  }
  action validateAndPublish = all {
    not(s.published), not(s.rejected),
    s' = if (s.layout.generatedMapMatches) { ...s, published: true, actualRole: true }
      else { ...s, rejected: true }
  }
  action dispatch = all { s.published, not(s.dispatched), s' = { ...s, dispatched: true } }
  val safe = s.dispatched implies (s.actualRole and not(s.rejected))

  run shiftedLegacyCanDispatchWrongRoleTest = shifted.then(publishLegacy).then(dispatch)
    .expect(not(safe))
  run originalLegacyDispatchTest = original.then(publishLegacy).then(dispatch).expect(safe)
  run shiftedRoleMapDispatchTest = shifted.then(validateAndPublish).then(dispatch).expect(safe)
  run staleRoleMapRejectsBeforePublicationTest = shiftedStale.then(validateAndPublish)
    .expect(s.rejected and not(s.published) and not(s.dispatched))
}
