# GC Conditional Arguments and Counterexamples

Handwritten design reasoning, not a checked proof, model run, native witness or
finite-pause certificate. Read the [audit](gc-current-mechanism-audit.md),
[architecture](gc-native-runtime-design.md),
[evidence](gc-native-runtime-evidence.md) and
[cost matrix](gc-native-runtime-cost-matrix.md).

| ID | Premises | Conditional argument / remaining obligation |
| --- | --- | --- |
| HP01 | Reviewed constructors create MOVABLE0, copying preserves its header, full root/phase route is used and inspected stores lack an active remembered-set route | The selected current movable collector is nongenerational full copying, with parallel source branches, not proven generational by tag constants. This does not identify every external/configured/loaded runtime. |
| HP02 | Every young reference is in an admitted active/native root, young graph or remembered non-young source; all contexts/producers acknowledge the same minor cut | Tracing roots/remembered locations and recursively tracing copied young objects reaches every live young object. Complete writer/root coverage is the missing global premise; a self-derived map cannot prove its own completeness. |
| HP03 | Forwarding is claimed uniquely, only complete destinations become readable, all copy/scan/producer tasks are counted, source storage survives until completion | Every rewritten reference identifies a valid completed promoted object; racing workers preserve identity. Source young storage can be reclaimed only after global closure, not after a local queue empties. |
| HP04 | Published non-young-to-young writes are recorded before cut acknowledgement, records retain valid source owner/location, reset/re-dirty cannot erase new work | Minor scanning finds and updates cross-generation references. Immediate-only stores and truly private initialization can omit remembering only under separately proven classification/publication conditions. |
| HP05 | Major start establishes the admitted snapshot; deletion/root and new-object publication protocols retain/shade all required mature references; field accesses and logs have qualified ordering | Every object required by the chosen conservative marking invariant stays reachable to tracing until processed. This is an intended invariant implication, not an imported OCaml algorithm theorem; initialization, weak semantics and exact memory-model realization remain open. |
| HP06 | Major workers never retain unprotected young pointers, all such workers acknowledge a minor cut, promotion hands off marking work and roots/leases are rebound before resume | Minor movement composes with nonmoving major marking without stale young dereference. Every native producer and inter-phase capacity/failure edge still needs coverage. |
| HP07 | Active/captured frame maps match semantics; activation restores valid dynamic state and scan epoch; frame updates/publication follow barrier rules; code/maps remain held | Moving/aging does not lose suspended map values or invalidate continuation replay. No unique native token is consumed twice; actual frame sharing/restore and all callers remain admission work. |
| HP08 | Foreign roots are registered before allocation, borrowing/pinning/blocking/reentry follow the stated owner protocol, transfers retain cells until scanners/logs finish | Foreign activity cannot hide a live Scheme reference or resume through stale PSTATE storage under those assumptions. Marker TODO and RC owner asymmetry mean this is not already established in the current source. |
| HP09 | Closing cut excludes late old-epoch producers, acknowledges/drains logs and tasks, processes weak dependencies and releases only closed dead sets; last-user root/code/resource drain is complete | Sweeping/retirement cannot free a live or still-used object/storage unit. Eventual acknowledgement, finite work, weak fixpoint, foreign effects and pause bounds remain separate unresolved premises. |
| HP10 | Complete common capability, full current/C/Zig lifecycle costs and valued outcomes are bounded; root/barrier/algorithm gains are credited once and actual old duties retire | A positive conservative total net supports the chosen modernization, and a separate positive Zig-versus-C lower bound supports language selection. Neither follows just from generation count, Zig features or LLVM availability. |

| ID | Logical counterexample, not reproduced failure | Broken obligation |
| --- | --- | --- |
| HX01 | Treat MOVABLE1/2 declarations as proof of survivor aging while copying preserves MOVABLE0. | Current-mechanism classification [HP01]. |
| HX02 | Report native parallel GC enabled from a header whose sample defaults are single-threaded and max processors one. | Configuration/source/loaded-behavior boundary [HP01]. |
| HX03 | Instrument pair mutation but a closure/global/FFI slot writes a young reference without remembering. | Young root closure [HP02/04]. |
| HX04 | Clear a dirty card while another context re-dirties it in the next epoch. | Cut/reset ownership [HP04]. |
| HX05 | Remember a raw slot address in a captured frame, then move/free its container before consuming the record. | Record lifetime and relocation [HP04/07]. |
| HX06 | Publish a forwarding pointer or a traceable major object before its fields are initialized. | Complete destination/publication [HP03/05]. |
| HX07 | Reserve one promotion buffer per worker but leave no accounted capacity for live output/context resumption. | Actual destination/resume capacity [HP03/06]. |
| HX08 | SATB tracks overwritten heap fields but ignores root unregister or frame replacement. | Complete major snapshot [HP05/07/08]. |
| HX09 | Mark new mature objects live but omit shading their old referents on initialization/publication. | New-object edge coverage [HP05]. |
| HX10 | Barrier queue is full; overwrite first and plan to log the old value later. | Pre-write protection and log capacity [HP05]. |
| HX11 | Queue fences are present, but collector loads race with unqualified ordinary mutable stores. | Native memory-model correctness [HP05]. |
| HX12 | Major worker follows a young pointer while another phase evacuates and resets that nursery. | Inter-phase participant closure [HP06]. |
| HX13 | Continuation is restored without its active-major scan epoch, or its code binding was unloaded. | Control/root/code lifetime [HP07]. |
| HX14 | Repeated continuation activation reuses a consumed native lease or destructively edits an earlier map result. | Multi-shot semantics [HP07]. |
| HX15 | Register RC on a nonzero owner but rely solely on processor-0 traversal of its own PSTATE-local chain. | Complete native root ownership, pending actual caller proof [HP08]. |
| HX16 | Create a C-to-Scheme marker before protecting proc_or_false, assuming Zig locals will be scanned. | Pre-allocation root protection [HP08]. |
| HX17 | Foreign thread blocks holding a raw young pointer, or callbacks reenter without owner reacquisition. | Borrow/participation/control [HP08]. |
| HX18 | Treat weak slots as strong SATB entries, or sweep a foreign wrapper on a worker that cannot run its destructor. | Weak/finalization semantics and task custody [HP09]. |
| HX19 | Stop on empty work queue while a log reservation, active scanner, producer or derived cleanup task still exists. | Termination/retirement closure [HP03/09]. |
| HX20 | Attribute all reduced old-object traversal to Zig, price a modern C reconstruction at zero, or omit barrier and migration costs. | Complete total/incremental net [HP10]. |

The proposed concurrent major protocol deliberately retains phase-cut and
capacity obligations; it has no accepted bounded-work, response-time or progress
claim. An unknown foreign effect may retain storage and block closure.
All five full runtime/semantic/retirement/total-cost/Zig-increment requirements
remain unresolved.
