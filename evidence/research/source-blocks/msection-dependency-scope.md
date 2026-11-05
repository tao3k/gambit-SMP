# Msection source interpretation: reviewed dependency scope

This is a reproducible source review, not a native execution receipt. Source
blocks bind the pinned Gambit baseline and the maintained source lock. They do
not assert that a generated header or an active Repair candidate has these bytes.

## Declaration scopes

The scope `literal-definition` covers the msection size comment and literal
definition only. The unit comment has an intentional empty dependency inventory;
the size interpretation also depends on that unit. Neither asserts evaluated
macro expansion, callers, ABI or active configuration.

The scope `expression-dependencies` records dependencies used by the allocation
and pointer expressions below. Edges are consumer-to-dependency. A caller's
dependency on a callee propagates changes towards the caller; it does not make
every caller edit change the callee's literal definition.

| Consumer | Reviewed dependency | Reason |
| --- | --- | --- |
| msection size interpretation | documented unit | The literal is a word count, not a byte count |
| allocation expression | msection size; word rounding; msection layout; aligned-heap entry | Actual arguments and callee in `adjust_msections` |
| word rounding | word layout | `___WORDS` reads `___WS` and `___LWS` |
| msection layout | word layout | `base` is `___WORD[1]`; size calculation uses `___WS` |
| word layout | address-mode selection | Both 32-bit and 64-bit branches are retained, not one guessed branch |
| address-mode selection | configure pointer-width probe; active generated configuration | `___VOIDSTAR_WIDTH` has a substituted default and permits a prior definition |
| aligned-heap entry | aligned-allocation implementation | Wrapper calls `alloc_mem_aligned_aux` with the heap branch |
| aligned-allocation implementation | word layout; allocation API | Converts word counts to bytes and uses `sizeof(void*)` for alignment |
| msection expansion | allocation expression | Expression is inside the expansion loop of `adjust_msections` |
| setup caller | msection expansion | `___setup_mem_vmstate` calls `adjust_msections` after deriving the requested population |
| resize caller | msection expansion | `resize_heap` calls the same function after its sizing calculation |
| stack placement | msection size; msection layout; tospace selection | Pointer addition is in `___WORD` elements, not bytes |
| tospace selection | msection layout; active VM tospace | The selected half depends on `mem.tospace_at_top` |

Byte spans in the registered view are the authority for exact locations. Line
labels are navigation only. The scope is not a claim that every allocator,
collector, object lifetime or preprocessor override has been enumerated.

## Explicit boundaries

`active-generated-configuration` deliberately has no current byte observation.
The configure source proves how a default is selected, not its result in the
current Repair image. Compiler command-line overrides and target ABI also need
that image's source-bound configuration witness. This open node propagates to
the layout-dependent summaries and callers; no absent edge is treated as proof
of independence.

The setup and resize caller excerpts witness their invocation, not the full
numeric sizing algorithm. Their declared scope is `call-site-correspondence`;
native sizing, lifecycle and GC acceptance remain separate obligations.

The scope document is a reviewed inventory declaration. Matching its digest and
edge count checks that declared inventory, not the completeness of an automatic
C dependency extractor. New callers, alternative macro definitions and evidence
against this review can be registered through the same DSL and remain open to
Agent investigation.

`active-vm-tospace` is likewise deliberately unobserved. The source expression
does not identify the half used by a particular failing address or the lifetime
of that stack. Neither missing input is filled from the host's pointer width or
from the fact that the investigation runs on macOS.

## Interpretation after compaction

Each retained understanding names the exact reviewed block digest. A changed
dependency produces an impact origin; an incomplete scope produces an unknown
boundary. A caller can recover a summary independently of its previous read
checkpoint and expand the linked raw block when needed. Neither prior display
nor a retained interpretation means the Agent remembers it or that it is true.

## Reproducible controls and proof boundary

`tests/test_real_source_impact.py` copies these exact pinned Gambit files into
temporary query fixtures, without building them. It exercises actual Scheme
closure from configuration and macros to the setup/resize callers, durable
cross-process read hints, a size-macro edit and an unrelated enclosing-file edit.
The changed-byte control updates the checked observation, not the interpretation's
historical digest. Until a byte observation is explicitly reviewed, ordinary
reference drift remains unavailable; there is no automatic hash blessing or C
anchor relocation.

ASCENT's existing `SourceUpdateFrame.lean` states the conditional arbitrary-graph
argument: changed dependencies and unknown scope reject reuse, a caller edge
propagates that rejection, and disjoint changes preserve applicability. Existing
`ClueQueryResume.qnt` checks interruption plus transitive change, lost scope
witnesses and retained understanding, with faulty controls. These models do not
prove that this authored C/configuration dependency inventory is complete, nor
that an Agent will choose an appropriate query or remember a displayed summary.
