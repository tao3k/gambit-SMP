import WillDrainAst
namespace WillDrain
open WillDrainAst
set_option maxHeartbeats 3000000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem reserveExternalPreserves (q : State) (h : Safe q) (g : reserveExternalGuard q) : Safe (reserveExternalNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,reserveExternalGuard,reserveExternalNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reserveChildPreserves (q : State) (h : Safe q) (g : reserveChildGuard q) : Safe (reserveChildNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,reserveChildGuard,reserveChildNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem commitWillPreserves (q : State) (h : Safe q) (g : commitWillGuard q) : Safe (commitWillNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,commitWillGuard,commitWillNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem abortReservationPreserves (q : State) (h : Safe q) (g : abortReservationGuard q) : Safe (abortReservationNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,abortReservationGuard,abortReservationNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unknownCommitPreserves (q : State) (h : Safe q) (g : unknownCommitGuard q) : Safe (unknownCommitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,unknownCommitGuard,unknownCommitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeExternalPreserves (q : State) (h : Safe q) (g : closeExternalGuard q) : Safe (closeExternalNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,closeExternalGuard,closeExternalNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem makeExecutablePreserves (q : State) (h : Safe q) (g : makeExecutableGuard q) : Safe (makeExecutableNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,makeExecutableGuard,makeExecutableNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem dequeuePreserves (q : State) (h : Safe q) (g : dequeueGuard q) : Safe (dequeueNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,dequeueGuard,dequeueNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem loadOperandsPreserves (q : State) (h : Safe q) (g : loadOperandsGuard q) : Safe (loadOperandsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,loadOperandsGuard,loadOperandsNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem zapWillFieldsPreserves (q : State) (h : Safe q) (g : zapWillFieldsGuard q) : Safe (zapWillFieldsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,zapWillFieldsGuard,zapWillFieldsNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem enterActionPreserves (q : State) (h : Safe q) (g : enterActionGuard q) : Safe (enterActionNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,enterActionGuard,enterActionNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem capturePreserves (q : State) (h : Safe q) (g : captureGuard q) : Safe (captureNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,captureGuard,captureNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem returnActionPreserves (q : State) (h : Safe q) (g : returnActionGuard q) : Safe (returnActionNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,returnActionGuard,returnActionNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem escapeActionPreserves (q : State) (h : Safe q) (g : escapeActionGuard q) : Safe (escapeActionNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,escapeActionGuard,escapeActionNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resumeCapturePreserves (q : State) (h : Safe q) (g : resumeCaptureGuard q) : Safe (resumeCaptureNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,resumeCaptureGuard,resumeCaptureNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retireOneCapturePreserves (q : State) (h : Safe q) (g : retireOneCaptureGuard q) : Safe (retireOneCaptureNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,retireOneCaptureGuard,retireOneCaptureNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resolveUnknownDonePreserves (q : State) (h : Safe q) (g : resolveUnknownDoneGuard q) : Safe (resolveUnknownDoneNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,resolveUnknownDoneGuard,resolveUnknownDoneNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resolveUnknownReadyPreserves (q : State) (h : Safe q) (g : resolveUnknownReadyGuard q) : Safe (resolveUnknownReadyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,resolveUnknownReadyGuard,resolveUnknownReadyNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem attestRootMapsPreserves (q : State) (h : Safe q) (g : attestRootMapsGuard q) : Safe (attestRootMapsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,attestRootMapsGuard,attestRootMapsNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem attestAliasClosurePreserves (q : State) (h : Safe q) (g : attestAliasClosureGuard q) : Safe (attestAliasClosureNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,attestAliasClosureGuard,attestAliasClosureNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem issuePreserves (q : State) (h : Safe q) (g : issueGuard q) : Safe (issueNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,issueGuard,issueNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reusePreserves (q : State) (h : Safe q) (g : reuseGuard q) : Safe (reuseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,reuseGuard,reuseNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unmanagedInterferencePreserves (q : State) (h : Safe q) (g : unmanagedInterferenceGuard q) : Safe (unmanagedInterferenceNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17⟩
 cases t : q.issued <;> simp_all [Safe,unmanagedInterferenceGuard,unmanagedInterferenceNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (g : Step q r) : Safe r := by
 rcases g with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23
 · rcases h0 with ⟨g,e⟩; rw [e]; exact reserveExternalPreserves q h g
 · rcases h1 with ⟨g,e⟩; rw [e]; exact reserveChildPreserves q h g
 · rcases h2 with ⟨g,e⟩; rw [e]; exact commitWillPreserves q h g
 · rcases h3 with ⟨g,e⟩; rw [e]; exact abortReservationPreserves q h g
 · rcases h4 with ⟨g,e⟩; rw [e]; exact unknownCommitPreserves q h g
 · rcases h5 with ⟨g,e⟩; rw [e]; exact closeExternalPreserves q h g
 · rcases h6 with ⟨g,e⟩; rw [e]; exact makeExecutablePreserves q h g
 · rcases h7 with ⟨g,e⟩; rw [e]; exact dequeuePreserves q h g
 · rcases h8 with ⟨g,e⟩; rw [e]; exact loadOperandsPreserves q h g
 · rcases h9 with ⟨g,e⟩; rw [e]; exact zapWillFieldsPreserves q h g
 · rcases h10 with ⟨g,e⟩; rw [e]; exact enterActionPreserves q h g
 · rcases h11 with ⟨g,e⟩; rw [e]; exact capturePreserves q h g
 · rcases h12 with ⟨g,e⟩; rw [e]; exact returnActionPreserves q h g
 · rcases h13 with ⟨g,e⟩; rw [e]; exact escapeActionPreserves q h g
 · rcases h14 with ⟨g,e⟩; rw [e]; exact resumeCapturePreserves q h g
 · rcases h15 with ⟨g,e⟩; rw [e]; exact retireOneCapturePreserves q h g
 · rcases h16 with ⟨g,e⟩; rw [e]; exact resolveUnknownDonePreserves q h g
 · rcases h17 with ⟨g,e⟩; rw [e]; exact resolveUnknownReadyPreserves q h g
 · rcases h18 with ⟨g,e⟩; rw [e]; exact attestRootMapsPreserves q h g
 · rcases h19 with ⟨g,e⟩; rw [e]; exact attestAliasClosurePreserves q h g
 · rcases h20 with ⟨g,e⟩; rw [e]; exact issuePreserves q h g
 · rcases h21 with ⟨g,e⟩; rw [e]; exact reusePreserves q h g
 · rcases h22 with ⟨g,e⟩; rw [e]; exact unmanagedInterferencePreserves q h g
 · rw [h23]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ edge ih => exact stepPreserves _ _ ih edge
theorem ticketConservation (q : State) (h : Safe q) : q.created-q.retired=q.weak+q.ready+q.claimed+q.loaded+q.runnable+q.active+q.unknown := by simp_all [Safe]
theorem issuedHasNoCaptures (q : State) (h : Safe q) (i : q.issued=true) : q.captures=0 := by simp_all [Safe]
theorem issuedHasNoUnknown (q : State) (h : Safe q) (i : q.issued=true) : q.unknown=0 := by simp_all [Safe]
theorem issuedHasNoWeak (q : State) (h : Safe q) (i : q.issued=true) : q.weak=0 := by simp_all [Safe]
theorem returnRetainsCaptures (q : State) : (returnActionNext q).captures=q.captures := by rfl
theorem zapTransfersLoaded (q : State) : (zapWillFieldsNext q).runnable=q.runnable+1 := by rfl
theorem childReservationSurvivesReturn (q : State) : (returnActionNext (reserveChildNext q)).pins=q.pins+1 := by rfl
theorem closeDoesNotEraseWeak (q : State) : (closeExternalNext q).weak=q.weak := by rfl
theorem closeDoesNotEraseCapture (q : State) : (closeExternalNext q).captures=q.captures := by rfl
theorem replayCreatesTicket (q : State) : (resumeCaptureNext q).created=q.created+1 := by rfl
theorem resumeNeedsCapability (q : State) (g : resumeCaptureGuard q) : q.captures>0 := by exact g
theorem noEarlyPermit (q : State) (h : Safe q) (w : q.weak>0 ∨ q.runnable>0 ∨ q.captures>0 ∨ q.unknown>0) : q.issued=false := by cases t : q.issued <;> simp_all [Safe] <;> omega
end WillDrain
