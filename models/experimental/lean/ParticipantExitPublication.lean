import WorkAccounting

namespace GambitSMP.ParticipantExitPublication

-- These contracts are conditional source obligations, not a refinement of C.
def ExitReady (work pending : Bool) : Prop := work = false ∧ pending = false

theorem emptyWorkDoesNotExcludeRequest :
    ∃ work pending : Bool, work = false ∧ ¬ ExitReady work pending := by
  exact ⟨false, true, rfl, by simp [ExitReady]⟩

theorem orphaningRevokesEmptyCensus :
    ExitReady false false ∧ ¬ ExitReady true false := by
  simp [ExitReady]

def PublicationSafe (writer reader : Bool) : Prop :=
  ¬ (writer = true ∧ reader = true)

theorem removedMemberDoesNotExcludeReader :
    ∃ member writer reader : Bool,
      member = false ∧ ¬ PublicationSafe writer reader := by
  exact ⟨false, true, true, rfl, by simp [PublicationSafe]⟩

theorem guardedPublicationExcludesReader (writer reader guard : Bool)
    (owns : writer = true → guard = true)
    (excludes : guard = true → reader = false) : PublicationSafe writer reader := by
  intro overlap
  have absent := excludes (owns overlap.1)
  rw [overlap.2] at absent
  contradiction

-- Shared-root reachability still does not imply exclusive mutation rights.
theorem rootAndParticipationAreIndependent (published : Bool) :
    ¬ GambitSMP.WorkAccounting.InactiveRootsReady published true :=
  GambitSMP.WorkAccounting.rootsDoNotPermitConcurrentMutation published

#print axioms emptyWorkDoesNotExcludeRequest
#print axioms orphaningRevokesEmptyCensus
#print axioms removedMemberDoesNotExcludeReader
#print axioms guardedPublicationExcludesReader
#print axioms rootAndParticipationAreIndependent

end GambitSMP.ParticipantExitPublication
