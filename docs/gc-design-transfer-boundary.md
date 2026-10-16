# Collector Design Transfer Boundary

## Facts Versus Motivation

The fixed Gambit source documents movable, still and permanent allocation
classes in `vendor/gambit/lib/mem.c:57-83`. Still objects are nonmoving and
mark/sweep managed. Permanent objects are not traced and may only refer to
permanent heap objects. Movable objects use the collector's relocation path.
Generation-named header tags are not evidence of a working multi-generation
collection policy, promotion schedule or remembered-set protocol.

The C-interface manual in `vendor/gambit/doc/gambit.txi:19712-19728` also requires
external reference ownership: nonmoving does not mean immortal or safe after
release. Chez likewise supports locked objects and FFI; it is not correct to
describe FFI or address stability as an exclusive Gambit property.

Scheme-to-C compilation and explicit still-object ownership are source facts.
"Generational barriers would greatly slow C compilation" and "these choices
cause millisecond scheduling" are hypotheses, not established explanations.
Both collectors support continuations. None of these facts ranks their general
performance or establishes that one design is uniformly heavier or superior.

## Transferable And Collector-Specific Obligations

| Reusable obligation | Chez mechanism | Gambit-specific question |
| --- | --- | --- |
| Identity is not scan readiness | Segment-owner copy/mark, resweep | Which consumers only redirect a forwarding pointer, and which read copied body/chunk data? |
| Deferred work cannot disappear | Remote mask/object owner routing | Does private/chunk/stack/still-object work remain accounted for through processor and VM retirement? |
| Scan every strong field, preserve aliases | Generated shape masks and stack maps | Do subtype/closure/continuation/root readers scan exactly the Scheme pointer fields? |
| Keep stable objects live, then release safely | Locked/immobile objects | Are still-object external counts and VM/FFI roots balanced across failure and teardown? |
| Close all work before reclamation | Counted sweepers and queued resweeps | Do queues, private producers and active scanners agree at the completion boundary? |
| Preserve younger-reference obligations | Generation promotion and dirty cards | Not directly applicable to the current Gambit collector; requires a separately proposed generational design. |

Do not transplant Chez's card layout, pointer-mask encoding, segment ownership
or in-place density thresholds into Gambit without a separate costed design.
`library/gc` holds only genuinely generic contracts. Chez generation/card models
remain implementation-specific profiles, not requirements that Gambit lacks.

## Repeated Shape Coverage

`models/chez/RepeatedResweep.qnt` has six explicit classes: scalar, pair, vector,
mixed record, closure and wide frame. Its source map distinguishes exact
generator sections from abstract bounded layouts. Four remote dependencies
among three owners demonstrate why the worker count cannot be a universal
resweep limit. The model does not establish an unbounded termination argument.

The new comparison lock is the current 23-file fdset-owned-rollback candidate;
the previous 22-file comparison remains historical. No prior binary result is
credited to this lock. The public object-retention regression below covers
Scheme-visible alias/value/closure/stack survival, not physical bitmap spans,
Chez masks, still-object C reference counts or multi-VM isolation.

Any runtime repair requires exact-source reproduction, original failure, actual
three-flag configuration, compiled and interpreted tests, GC/FFI/VM teardown,
and matched input/topology measurements. A finite model result and a scheduling
sample cannot replace those gates.
