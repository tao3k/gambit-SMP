import SlotMapping
import SlotCensus
import CarrierCoverageAst
namespace SlotMappingBridge
open SlotMappingAst
def carrierCovered (q : State) : Prop := (q.alias = 1 ∧ q.m0 = 1) ∨ (q.alias = 0 ∧ q.m1 = 1)
theorem physicalCarrierCoverage (q : State) (h : Safe q) (frozen : q.gc = 1) (live : q.d1 = 2 ∨ q.d1 = 3) : carrierCovered q := by
 simp_all [Safe,carrierCovered] <;> omega
theorem parentMembershipObligation (p : CarrierCoverageAst.State) (q : State) (h : Safe q)
 (phase : p.gc = q.gc) (descriptor : p.d1 = q.d1)
 (membership : p.snap1 = 1 ↔ carrierCovered q)
 (frozen : p.gc = 1) (live : p.d1 = 2 ∨ p.d1 = 3) : p.snap1 = 1 := by
 apply membership.mpr
 exact physicalCarrierCoverage q h (by omega) (by omega)
theorem allAliasesHoldBacking (q : State) (h : Safe q) (a : q.alias = 1) (live : q.d1 = 3) : q.store0 = 1 := SlotMapping.closingAliasRetainsSlot q h a live
end SlotMappingBridge
