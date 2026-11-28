# Map Conditional Arguments and Refuters

Reviewed: 2026-10-20. Handwritten conditional arguments and counterexamples,
not checked proofs, executed schedules or native witnesses. Read the
[design](map-scheme-zig-design.md), [source/papers](map-scheme-zig-evidence.md)
and [matrix](map-scheme-zig-cost-matrix.md).

| ID | Premises | Conditional conclusion / open boundary |
| --- | --- | --- |
| MH01 | Stable finite single-list input, no forcing/reentry, normal one-value callback returns, successful allocations, selected source order | Induction: callback result is saved, recursive call maps the post-callback cdr, then a new pair prepends result to returned tail. n callbacks and n output pairs; no theorem for arbitrary mutation, failure or configured value-count rules. |
| MH02 | Source-preservation envelope permits input mutation; saved current pair survives callback; semantic order and normal/control successors preserved | Reading its cdr after callback preserves those observations. R7RS excludes input-list mutation; this is not a portable-domain necessity, and a separately admitted no-mutation domain may permit more transformations. |
| MH03 | Generic call carries actual ProcRef/SELF/arity/environment identity and complete return/frame state | Both captured cells and return obligations compose with admitted Gambit runtime calls. A Zig function-pointer cast cannot discharge these premises. |
| MH04 | Every collecting/capture edge materializes all semantic/protocol roots across active and saved frames; scanner/restore contracts agree; subsequent uses reload | Live callback results, pair/proc and control survive relocation. Independent semantic-root versus physical-map evidence is still required; a bitmap constructed from the same mistaken liveness is not independent proof. |
| MH05 | Each non-tail call retains a valid Scheme frame and each native dispatch returns before the next invocation; all exceptional/foreign edges follow the profile | Native depth is bounded by the admitted dispatcher/service bound, while pending Scheme control remains O(n). No constant total-stack/memory claim follows, and arbitrary callback native recursion is outside this bound. |
| MH06 | Capture/restore preserves logical frames/dynamic environment; repeated activation does not mutate previous returned output; actual interval rights are reacquired; code/maps remain held | Reexecuted suffix operations create valid new output and use current roots/storage. Prior heap effects are not rolled back. Actual frame sharing/copying, VM ownership and native islands remain qualification obligations. |
| MH07 | Local no-handles pair writes have W=P=delta=3, current h≤L and L+3≤b, valid provenance, no hidden allocation/safepoint | One output pair is bounded; no inference about proc/apply/force/frame or total map B. A collecting slow edge reloads roots and actual allocation binding before further writes. |
| MH08 | Multi-list helper policy/order/sentinel branches preserved; equal stable lengths and no force/reentry under source-level evaluation | nm cars-cons + nm successful cdrs-cons + n output-cons + one outer cons. Optimization can change physical allocation only under a separate refinement; captured precomputed rests remain distinct from one-list post-callback reads. |
| MH09 | New completed graph/products cover all old consumers, chosen cohort has one _std supplier, code/frame/init users close | Old C-specific semantic/packing/rendering/transfer obligations can retire only in the admitted domain; Scheme/GC/capture behavior remains. No retirement receipt exists here. |
| MH10 | Full C and Zig reconstruction/maintenance/delay costs are bounded from B0 at equal admitted capability; common and candidate-specific burdens counted once | Positive lower bound for total selected net and incremental Zig net permits economic selection. No need to build modern C first; unpriced generators or unknown Zig integration costs invalidate the bound. |

| ID | Logical counterexample | Refuted claim |
| --- | --- | --- |
| MX01 | Within the stronger source-preservation envelope, a callback cuts the saved pair's cdr; provider cached the old tail. | Source refinement under MH02, not correctness of every R7RS-conforming no-mutation optimization. |
| MX02 | Ordinary Zig callback directly returns while capture expects a Scheme after-proc frame. | Generic call/capture equivalence [MH03/06]. |
| MX03 | Only latest result is rooted; an earlier pending cons result is in an unregistered native vector. | Complete saved-chain root coverage [MH04]. |
| MX04 | Allocate the frame/spill container before protecting its input result. | Root protection before collecting preparation [MH04]. |
| MX05 | A slice into a moved frame or old pair is used after callback GC. | Reload/provenance discipline [MH04]. |
| MX06 | Treat non-tail recursive map work as constant-space because native dispatch does not recurse. | Distinction between native depth and Scheme continuation storage [MH05]. |
| MX07 | A captured continuation consumes a unique arena/lock/allocation token on first return and reuses it on invocation. | Replayable state and actual storage rights [MH06]. |
| MX08 | Reuse a mutable output list as builder when captured map returns again. | Earlier output nonmutation and fresh cons obligations [MH06]. |
| MX09 | Replace dynamic-wind by Zig defer or let C longjmp bypass a live Zig activation. | Scheme control/native cleanup composition [MH03/05/06]. |
| MX10 | Callback returns false or an integer and implementation mistakes that element for the tail sentinel. | Value-role separation and error propagation [MH01/08]. |
| MX11 | Fold mutable mismatch policy from its initial true value. | Multi-list policy and invalidation contract [MH08]. |
| MX12 | Translate multi-list map to repeatedly reread original list cdrs after callback. | Preserved precomputed-rests/helper order [MH08]. |
| MX13 | B=3 is used for the whole callback/recursive span, despite arbitrary allocations. | Actual per-span bound [MH07]. |
| MX14 | Native nonlocal or foreign callbacks have not been classified, but ordinary Scheme calls pass locally. | Complete control domain [MH03/05/09]. |
| MX15 | Old _std and a new map supplier coexist, or unload frees code held by a captured return point. | Unique binding and code-user closure [MH06/09]. |
| MX16 | Modern C generator/validator/library integration costs are assigned zero because it is a comparison control. | Fair full delivery-path economics [MH10]. |
| MX17 | Credit all common modernization benefit to Zig while ignoring a viable C reconstruction. | Incremental net accounting [MH10]. |
| MX18 | Count 23 labels as 23 deleted FFI wrappers, or potential future components as assured amortization. | Necessary-work denominator and shared support cost [MH03/10]. |

All full runtime, semantic/provider, retirement, total-cost and Zig-increment
questions remain unresolved. The design is more explicit, but no backend,
native profile, optimizer pass, checked proof or economic gate is admitted.
