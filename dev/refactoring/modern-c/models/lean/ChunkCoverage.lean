import ChunkCoverageAst
namespace ChunkCoverage
open ChunkCoverageAst
set_option maxHeartbeats 4000000
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem initializeAPreserves (q : State) (h : Safe q) (g : initializeAGuard q) : Safe (initializeANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18⟩
 simp_all [Safe,initializeAGuard,initializeANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem initializeBPreserves (q : State) (h : Safe q) (g : initializeBGuard q) : Safe (initializeBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18⟩
 simp_all [Safe,initializeBGuard,initializeBNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem registerAPreserves (q : State) (h : Safe q) (g : registerAGuard q) : Safe (registerANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18⟩
 simp_all [Safe,registerAGuard,registerANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem registerBPreserves (q : State) (h : Safe q) (g : registerBGuard q) : Safe (registerBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18⟩
 simp_all [Safe,registerBGuard,registerBNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sealAPreserves (q : State) (h : Safe q) (g : sealAGuard q) : Safe (sealANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18⟩
 simp_all [Safe,sealAGuard,sealANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sealBPreserves (q : State) (h : Safe q) (g : sealBGuard q) : Safe (sealBNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18⟩
 simp_all [Safe,sealBGuard,sealBNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeChunkPreserves (q : State) (h : Safe q) (g : closeChunkGuard q) : Safe (closeChunkNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18⟩
 simp_all [Safe,closeChunkGuard,closeChunkNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem deferClosedPreserves (q : State) (h : Safe q) (g : deferClosedGuard q) : Safe (deferClosedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18⟩
 simp_all [Safe,deferClosedGuard,deferClosedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeAliasesPreserves (q : State) (h : Safe q) (g : closeAliasesGuard q) : Safe (closeAliasesNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18⟩
 simp_all [Safe,closeAliasesGuard,closeAliasesNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem mutateAPreserves (q : State) (h : Safe q) (g : mutateAGuard q) : Safe (mutateANext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18⟩
 simp_all [Safe,mutateAGuard,mutateANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishChunkPreserves (q : State) (h : Safe q) (g : publishChunkGuard q) : Safe (publishChunkNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18⟩
 simp_all [Safe,publishChunkGuard,publishChunkNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem claimPreserves (q : State) (h : Safe q) (g : claimGuard q) : Safe (claimNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18⟩
 simp_all [Safe,claimGuard,claimNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem completeScanPreserves (q : State) (h : Safe q) (g : completeScanGuard q) : Safe (completeScanNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18⟩
 simp_all [Safe,completeScanGuard,completeScanNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13
 · rcases a0 with ⟨g,rfl⟩; exact initializeAPreserves q h g
 · rcases a1 with ⟨g,rfl⟩; exact initializeBPreserves q h g
 · rcases a2 with ⟨g,rfl⟩; exact registerAPreserves q h g
 · rcases a3 with ⟨g,rfl⟩; exact registerBPreserves q h g
 · rcases a4 with ⟨g,rfl⟩; exact sealAPreserves q h g
 · rcases a5 with ⟨g,rfl⟩; exact sealBPreserves q h g
 · rcases a6 with ⟨g,rfl⟩; exact closeChunkPreserves q h g
 · rcases a7 with ⟨g,rfl⟩; exact deferClosedPreserves q h g
 · rcases a8 with ⟨g,rfl⟩; exact closeAliasesPreserves q h g
 · rcases a9 with ⟨g,rfl⟩; exact mutateAPreserves q h g
 · rcases a10 with ⟨g,rfl⟩; exact publishChunkPreserves q h g
 · rcases a11 with ⟨g,rfl⟩; exact claimPreserves q h g
 · rcases a12 with ⟨g,rfl⟩; exact completeScanPreserves q h g
 · rw [a13]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
-- Word-index arithmetic; C pointer provenance and descriptor authenticity remain premises.
structure Frame where
 header : Int
 fs : Int
 link : Int
 deriving DecidableEq
def past (f : Frame) : Int := f.header+f.fs+2
def linkSlot (f : Frame) : Int := past f-(f.link+1)
def Tile (lo : Int) : List Frame → Int → Prop
 | [], term => lo=term
 | f::rest, term => f.header=lo ∧ 0<f.fs ∧ 0≤f.link ∧ f.link<f.fs ∧ Tile (past f) rest term

theorem copierScannerCoordinate (h fs link : Int) :
 (h+1+1+fs)-(link+1)=(h+fs+2)-(link+1) := by omega
theorem rootSlotCoordinate (h fs i : Int) : h+2+(fs-i)=(h+fs+2)-i := by omega
theorem linkInsideFrame (f : Frame) (hl : 0≤f.link) (hu : f.link<f.fs) :
 f.header+2 ≤ linkSlot f ∧ linkSlot f < past f := by
 simp [linkSlot,past]; omega
theorem tileOrdered (lo term : Int) (frames : List Frame) (h : Tile lo frames term) : lo≤term := by
 induction frames generalizing lo with
 | nil => simp [Tile] at h; omega
 | cons f rest ih =>
   rcases h with ⟨hf,hfs,hl,hu,ht⟩
   have hp := ih (past f) ht
   simp [past] at hp; omega

theorem tileLinksCovered (lo term : Int) (frames : List Frame) (h : Tile lo frames term) :
 ∀ f ∈ frames, lo≤linkSlot f ∧ linkSlot f<term := by
 induction frames generalizing lo with
 | nil => simp
 | cons f rest ih =>
   rcases h with ⟨hf,hfs,hl,hu,ht⟩
   have hp := tileOrdered (past f) term rest ht
   have hi := linkInsideFrame f hl hu
   have hr := ih (past f) ht
   intro g hg
   simp only [List.mem_cons] at hg
   rcases hg with he | hm
   · subst g; simp [past] at *; constructor <;> omega
   · have hx := hr g hm; simp [past] at *; constructor <;> omega

theorem uniqueChunk (p lo hi lo2 hi2 : Int) (h1 : lo≤p ∧ p<hi)
 (h2 : lo2≤p ∧ p<hi2) (hd : hi≤lo2) : False := by omega

theorem slotBeforeTerminator (f : Frame) (hl : 0≤f.link) (hu : f.link<f.fs)
 (term : Int) (he : past f≤term) : linkSlot f<term := by
 have := linkInsideFrame f hl hu; omega

theorem leadingMarkerNotHeader (lo header : Int) (h : lo≤header) : lo-1≠header := by omega
-- Actual chunks may mix frames, ordinary objects, and zero-word padding vectors.
structure Span where
 header : Int
 words : Int
 deriving DecidableEq
def spanPast (e : Span) : Int := e.header+1+e.words
def SpanTile (lo : Int) : List Span → Int → Prop
 | [], term => lo=term
 | e::rest, term => e.header=lo ∧ 0≤e.words ∧ SpanTile (spanPast e) rest term

theorem spanOrdered (lo term : Int) (entries : List Span) (h : SpanTile lo entries term) : lo≤term := by
 induction entries generalizing lo with
 | nil => simp [SpanTile] at h; omega
 | cons e rest ih =>
   rcases h with ⟨he,hw,ht⟩
   have hp := ih (spanPast e) ht
   simp [spanPast] at hp; omega

theorem spanCovered (lo term : Int) (entries : List Span) (h : SpanTile lo entries term) :
 ∀ e ∈ entries, lo≤e.header ∧ spanPast e≤term := by
 induction entries generalizing lo with
 | nil => simp
 | cons e rest ih =>
   rcases h with ⟨he,hw,ht⟩
   have hp := spanOrdered (spanPast e) term rest ht
   have hr := ih (spanPast e) ht
   intro g hg
   simp only [List.mem_cons] at hg
   rcases hg with heq | hm
   · subst g; constructor <;> omega
   · have hx := hr g hm; simp [spanPast] at *; constructor <;> omega

theorem mixedChunkLinkCovered (lo term : Int) (entries : List Span)
 (ht : SpanTile lo entries term) (f : Frame)
 (hf : ({header:=f.header,words:=f.fs+1} : Span) ∈ entries)
 (hl : 0≤f.link) (hu : f.link<f.fs) : lo≤linkSlot f ∧ linkSlot f<term := by
 have hs := spanCovered lo term entries ht _ hf
 have hf := linkInsideFrame f hl hu
 simp [spanPast,past] at *; constructor <;> omega

theorem paddingThenFrame : SpanTile 100 [{header:=100,words:=0},{header:=101,words:=5}] 107 := by
 simp [SpanTile,spanPast]
theorem spanAppend (lo mid term : Int) (xs ys : List Span)
 (hx : SpanTile lo xs mid) (hy : SpanTile mid ys term) : SpanTile lo (xs++ys) term := by
 induction xs generalizing lo with
 | nil => simp [SpanTile] at hx; subst lo; exact hy
 | cons e rest ih =>
   rcases hx with ⟨he,hw,ht⟩
   exact ⟨he,hw,ih (spanPast e) ht⟩

theorem nextLeadingAliasesTerm (term nextStart : Int) (h : nextStart=term+1) : nextStart-1=term := by omega
end ChunkCoverage
