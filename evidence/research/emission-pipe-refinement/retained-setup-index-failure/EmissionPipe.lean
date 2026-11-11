import EmissionPipeAst
namespace EmissionPipe
open EmissionPipeAst
set_option maxHeartbeats 10000000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem firstPreserves (q : State) (h : Safe q) (g : firstGuard q) : Safe (firstNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,firstGuard,firstNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem selectDebugPreserves (q : State) (h : Safe q) (g : selectDebugGuard q) : Safe (selectDebugNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,selectDebugGuard,selectDebugNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem selectCustomPreserves (q : State) (h : Safe q) (g : selectCustomGuard q) : Safe (selectCustomNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,selectCustomGuard,selectCustomNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem prmRemainderPreserves (q : State) (h : Safe q) (g : prmRemainderGuard q) : Safe (prmRemainderNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,prmRemainderGuard,prmRemainderNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem initTextPreserves (q : State) (h : Safe q) (g : initTextGuard q) : Safe (initTextNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,initTextGuard,initTextNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem gloPrefixPreserves (q : State) (h : Safe q) (g : gloPrefixGuard q) : Safe (gloPrefixNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,gloPrefixGuard,gloPrefixNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem scalarDispatchPreserves (q : State) (h : Safe q) (g : scalarDispatchGuard q) : Safe (scalarDispatchNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,scalarDispatchGuard,scalarDispatchNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem namedEffectPreserves (q : State) (h : Safe q) (g : namedEffectGuard q) : Safe (namedEffectNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,namedEffectGuard,namedEffectNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem customRawPreserves (q : State) (h : Safe q) (g : customRawGuard q) : Safe (customRawNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,customRawGuard,customRawNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem replaceEntryPreserves (q : State) (h : Safe q) (g : replaceEntryGuard q) : Safe (replaceEntryNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,replaceEntryGuard,replaceEntryNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unknownEffectPreserves (q : State) (h : Safe q) (g : unknownEffectGuard q) : Safe (unknownEffectNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,unknownEffectGuard,unknownEffectNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem ioAbortPreserves (q : State) (h : Safe q) (g : ioAbortGuard q) : Safe (ioAbortNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,ioAbortGuard,ioAbortNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem attestPreserves (q : State) (h : Safe q) (g : attestGuard q) : Safe (attestNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,attestGuard,attestNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem issuePreserves (q : State) (h : Safe q) (g : issueGuard q) : Safe (issueNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,issueGuard,issueNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem secondPreserves (q : State) (h : Safe q) (g : secondGuard q) : Safe (secondNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,secondGuard,secondNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem omitSecondPreserves (q : State) (h : Safe q) (g : omitSecondGuard q) : Safe (omitSecondNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,omitSecondGuard,omitSecondNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem pausePreserves (q : State) (h : Safe q) (g : pauseGuard q) : Safe (pauseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,pauseGuard,pauseNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem readChunkPreserves (q : State) (h : Safe q) (g : readChunkGuard q) : Safe (readChunkNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,readChunkGuard,readChunkNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem advanceReaderPreserves (q : State) (h : Safe q) (g : advanceReaderGuard q) : Safe (advanceReaderNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,advanceReaderGuard,advanceReaderNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem exposeWriterPreserves (q : State) (h : Safe q) (g : exposeWriterGuard q) : Safe (exposeWriterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,exposeWriterGuard,exposeWriterNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem consumeWriterPreserves (q : State) (h : Safe q) (g : consumeWriterGuard q) : Safe (consumeWriterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,consumeWriterGuard,consumeWriterNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resumePreserves (q : State) (h : Safe q) (g : resumeGuard q) : Safe (resumeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> cases l : q.locked <;> simp_all [Safe,resumeGuard,resumeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishPreserves (q : State) (h : Safe q) (g : publishGuard q) : Safe (publishNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,publishGuard,publishNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem appendTailPreserves (q : State) (h : Safe q) (g : appendTailGuard q) : Safe (appendTailNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,appendTailGuard,appendTailNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishPreserves (q : State) (h : Safe q) (g : finishGuard q) : Safe (finishNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,finishGuard,finishNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem installNewPreserves (q : State) (h : Safe q) (g : installNewGuard q) : Safe (installNewNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47⟩
 cases c : q.certificate <;> cases d : q.shared <;> simp_all [Safe,installNewGuard,installNewNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (g : Step q r) : Safe r := by
 rcases g with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26
 · rcases h0 with ⟨g,e⟩; rw [e]; exact firstPreserves q h g
 · rcases h1 with ⟨g,e⟩; rw [e]; exact selectDebugPreserves q h g
 · rcases h2 with ⟨g,e⟩; rw [e]; exact selectCustomPreserves q h g
 · rcases h3 with ⟨g,e⟩; rw [e]; exact prmRemainderPreserves q h g
 · rcases h4 with ⟨g,e⟩; rw [e]; exact initTextPreserves q h g
 · rcases h5 with ⟨g,e⟩; rw [e]; exact gloPrefixPreserves q h g
 · rcases h6 with ⟨g,e⟩; rw [e]; exact scalarDispatchPreserves q h g
 · rcases h7 with ⟨g,e⟩; rw [e]; exact namedEffectPreserves q h g
 · rcases h8 with ⟨g,e⟩; rw [e]; exact customRawPreserves q h g
 · rcases h9 with ⟨g,e⟩; rw [e]; exact replaceEntryPreserves q h g
 · rcases h10 with ⟨g,e⟩; rw [e]; exact unknownEffectPreserves q h g
 · rcases h11 with ⟨g,e⟩; rw [e]; exact ioAbortPreserves q h g
 · rcases h12 with ⟨g,e⟩; rw [e]; exact attestPreserves q h g
 · rcases h13 with ⟨g,e⟩; rw [e]; exact issuePreserves q h g
 · rcases h14 with ⟨g,e⟩; rw [e]; exact secondPreserves q h g
 · rcases h15 with ⟨g,e⟩; rw [e]; exact omitSecondPreserves q h g
 · rcases h16 with ⟨g,e⟩; rw [e]; exact pausePreserves q h g
 · rcases h17 with ⟨g,e⟩; rw [e]; exact readChunkPreserves q h g
 · rcases h18 with ⟨g,e⟩; rw [e]; exact advanceReaderPreserves q h g
 · rcases h19 with ⟨g,e⟩; rw [e]; exact exposeWriterPreserves q h g
 · rcases h20 with ⟨g,e⟩; rw [e]; exact consumeWriterPreserves q h g
 · rcases h21 with ⟨g,e⟩; rw [e]; exact resumePreserves q h g
 · rcases h22 with ⟨g,e⟩; rw [e]; exact publishPreserves q h g
 · rcases h23 with ⟨g,e⟩; rw [e]; exact appendTailPreserves q h g
 · rcases h24 with ⟨g,e⟩; rw [e]; exact finishPreserves q h g
 · rcases h25 with ⟨g,e⟩; rw [e]; exact installNewPreserves q h g
 · rw [h26]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ edge ih => exact stepPreserves _ _ ih edge
theorem permitNeedsEpoch (q : State) (h : Safe q) (c : q.certificate=true) : q.epoch=q.planEpoch := by simp_all [Safe]
theorem pendingConserved (q : State) (h : Safe q) : q.emitted-q.delivered=q.wlo+q.whi-q.rlo := by simp_all [Safe]
theorem resumeLoadsSavedIndex (q : State) : (resumeNext q).index=q.savedIndex := by rfl
theorem resumeKeepsPhysicalBuffer (q : State) : (resumeNext q).wgen=q.wgen := by rfl
theorem scalarExcludesSpecial (q : State) (h : Safe q) : q.special=false := by simp_all [Safe]
end EmissionPipe
