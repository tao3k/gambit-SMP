/* DEV target refactoring interface, not a duplicate GC implementation/model.
 * Existing root QNT/Lean sources remain under models/ and retain scoped status. */
package GambitFrameContract {
    private import ScalarValues::*;
    part def FrameAdmission {
        attribute scanGranted : Boolean;
        attribute descriptorBound : Boolean;
        attribute sourceCoverageAccepted : Boolean;
        attribute initializedSlots : Boolean;
        attribute finalRootsPublished : Boolean;
        attribute metadataLeaseLive : Boolean;
        attribute ownerAndEpochMatched : Boolean;
        attribute resumeGranted : Boolean;
        attribute relocatedValuesReloaded : Boolean;
    }
    requirement def FrameScanLaw {
        subject witness : FrameAdmission;
        require constraint { not witness.scanGranted or
            (witness.descriptorBound and witness.sourceCoverageAccepted and witness.initializedSlots and
             witness.finalRootsPublished and witness.metadataLeaseLive and witness.ownerAndEpochMatched) }
    }
    requirement def FrameResumeLaw {
        subject witness : FrameAdmission;
        require constraint { not witness.resumeGranted or
            (witness.relocatedValuesReloaded and witness.metadataLeaseLive and witness.ownerAndEpochMatched) }
    }

    part def CoordinateLaw {
        attribute coordinateId : String;
        attribute domain : String;
        attribute equation : String;
        attribute premises : String;
        attribute sourceRefs : String;
    }
    part coordinate0 : CoordinateLaw {
        attribute :>> coordinateId = "CO-STACK";
        attribute :>> domain = "Stack word coordinates";
        attribute :>> equation = "S(F)=round_up(F+3,4); P[0]=saved return marker; B=P+S(F); slot(i)=B[-i], 1<=i<=F";
        attribute :>> premises = "P names the stored-RA origin; B names the base after FP_ADJFP(fp,-S(F)); addresses are word offsets in one admitted stack region";
        attribute :>> sourceRefs = "vendor/gambit/include/gambit.h.in:6572-6578; vendor/gambit/include/gambit.h.in:6745-6747; vendor/gambit/lib/mem.c:3700-3727";
    }
    part coordinate1 : CoordinateLaw {
        attribute :>> coordinateId = "CO-HEAP";
        attribute :>> domain = "Heap word coordinates";
        attribute :>> equation = "H[0]=saved return marker; H[F+1-i]=stackSlot(i); E=H+F+1; FP_STK(E,i)=H[F+1-i]";
        attribute :>> premises = "H is body after subtype header; FRAME_EXTRA_SLOTS=1; E is one-past body; one-based slots exclude saved RA at H[0]";
        attribute :>> sourceRefs = "vendor/gambit/lib/mem.c:3738-3768; vendor/gambit/lib/mem.c:4104-4141";
    }
    part coordinate2 : CoordinateLaw {
        attribute :>> coordinateId = "CO-LINK";
        attribute :>> domain = "Return link and caller edge";
        attribute :>> equation = "L is zero-based; linkSlot=L+1; stack=B[-(L+1)]; heap=H[F-L]";
        attribute :>> premises = "Capture/control rewrite the caller edge and forwarding marker; equality of every copied slot is not a post-rewrite invariant";
        attribute :>> sourceRefs = "vendor/gambit/lib/mem.c:3724-3729; vendor/gambit/lib/mem.c:3766-3795; vendor/gambit/lib/_kernel.scm:1190-1278";
    }
    part coordinate3 : CoordinateLaw {
        attribute :>> coordinateId = "CO-INTERNAL";
        attribute :>> domain = "Internal return coordinate law";
        attribute :>> equation = "F=align(cfs)+S(N+1)-3; S(F)=F+3; RETI_RA=-(S(N+1)-(N+1)); H[1-3-RETI_RA] names actual_ra";
        attribute :>> premises = "Actual return differs from wrapper marker; equality requires canonical internal F; retain stored cfs as well as physical F";
        attribute :>> sourceRefs = "vendor/gambit/gsc/_t-c-3.scm:502-521; vendor/gambit/include/gambit.h.in:6572-6578; vendor/gambit/include/gambit.h.in:9261-9262";
    }
    part coordinate4 : CoordinateLaw {
        attribute :>> coordinateId = "CO-MAP";
        attribute :>> domain = "Random and streaming bitmap coordinates";
        attribute :>> equation = "q=(i-1) div W; b=(i-1) mod W; word(0)=firstgcmap; word(q>0)=nextgcmap[q-1]; live(i)=unsignedBit(word(q),b)";
        attribute :>> premises = "OFD decoder consumes header and first map word, leaving nextgcmap at the second word; masks require word-sized unsigned operands";
        attribute :>> sourceRefs = "vendor/gambit/include/gambit.h.in:9301-9320; vendor/gambit/lib/mem.c:3816-3891; vendor/gambit/lib/_kernel.scm:3342-3412";
    }
    part coordinate5 : CoordinateLaw {
        attribute :>> coordinateId = "CO-OFD";
        attribute :>> domain = "Bound outline descriptor extent";
        attribute :>> equation = "boundOFDWords=1+ceil(F/W); map chunks emitted low 32 bits first; setup cursor uses actual F once";
        attribute :>> premises = "Raw OFD(kind,...) is an IFD-shaped placeholder with zero map; it is not a ready descriptor pointer; table order must match labels";
        attribute :>> sourceRefs = "vendor/gambit/gsc/_t-c-1.scm:1938-2014; vendor/gambit/gsc/_t-c-3.scm:489-500; vendor/gambit/include/gambit.h.in:9232-9259; vendor/gambit/lib/setup.c:1803-1839";
    }

    part def FrameRefinementLaw {
        attribute lawId : String;
        attribute fieldRefs : String;
        attribute parentDuties : String;
        attribute migrationCuts : String;
        attribute foundationLanes : String;
        attribute quintState : String;
        attribute quintActions : String;
        attribute quintInvariant : String;
        attribute leanObligation : String;
        attribute requiredPremises : String;
        attribute retireRoles : String;
        attribute counterexampleIds : String;
        attribute sourceRefs : String;
    }
    part refinement0 : FrameRefinementLaw {
        attribute :>> lawId = "FL-ENCODE";
        attribute :>> fieldRefs = "FS-PHYSICAL";
        attribute :>> parentDuties = "ND-ENCODE; ND-ABI";
        attribute :>> migrationCuts = "DM-CONTRACT; DM-FRAME";
        attribute :>> foundationLanes = "T0-ROOTS";
        attribute :>> quintState = "kind; storedFs; physicalFs; link; map; wordWidth; descriptorState";
        attribute :>> quintActions = "validateBounds; lower; encodeInline; encodeOutline; reject";
        attribute :>> quintInvariant = "Current-scan admission requires F>=1; admitted finite fields are disjoint and Decode(Encode(Lower(f)))=Lower(f)";
        attribute :>> leanObligation = "Prove width/shift/overflow bounds and preserve kind plus stored cfs; inverse only on admitted domain";
        attribute :>> requiredPremises = "Native C integer promotions and pointer-tag facts; logical decoding does not prove C expressions defined";
        attribute :>> retireRoles = "Packed IFD/OFD machinery remains until generated encoder and every decoder migrate";
        attribute :>> counterexampleIds = "CEX-FIELDS";
        attribute :>> sourceRefs = "vendor/gambit/include/gambit.h.in:9208-9320; vendor/gambit/gsc/_t-c-3.scm:489-532";
    }
    part refinement1 : FrameRefinementLaw {
        attribute :>> lawId = "FL-BIND";
        attribute :>> fieldRefs = "FS-PHYSICAL; MS-INSTANCE";
        attribute :>> parentDuties = "ND-ENCODE; ND-PUBLISH";
        attribute :>> migrationCuts = "DM-INSTANCE; DM-FRAME";
        attribute :>> foundationLanes = "T0-ROOTS; T0-EXECUTION";
        attribute :>> quintState = "unresolvedPoints; labelOrder; ofdCursor; extent; boundSet; published";
        attribute :>> quintActions = "reserveDescriptors; bindOutline; checkExtent; publishReady; failRetain";
        attribute :>> quintInvariant = "no scanner sees unresolved outline marker; cursor prefix equals lengths of prior accepted outline frames";
        attribute :>> leanObligation = "Prove label-order/OFD-order correspondence, extent prefix sums and bind-before-publish; zero-map ambiguity requires actual producer-domain proof";
        attribute :>> requiredPremises = "All valid inline return maps nonzero or explicit state distinction; host label setup and C visibility are separate premises";
        attribute :>> retireRoles = "Implicit sequential OFD cursor and overloaded marker convention may retire after bound PointId table accepted";
        attribute :>> counterexampleIds = "CEX-UNBOUND";
        attribute :>> sourceRefs = "vendor/gambit/include/gambit.h.in:9252-9262; vendor/gambit/lib/setup.c:1740-1844; vendor/gambit/gsc/_t-c-1.scm:1978-2014";
    }
    part refinement2 : FrameRefinementLaw {
        attribute :>> lawId = "FL-COORD";
        attribute :>> fieldRefs = "FS-SEMANTIC; FS-PHYSICAL";
        attribute :>> parentDuties = "ND-ENCODE; ND-CONTROL";
        attribute :>> migrationCuts = "DM-FRAME";
        attribute :>> foundationLanes = "T0-ROOTS; T0-CONTROL";
        attribute :>> quintState = "origin; F; P; B; H; E; slotMeaning; initializedPrefix";
        attribute :>> quintActions = "copySlot; finishPayload; rewriteLink; reconstruct; restore";
        attribute :>> quintInvariant = "logical slot i in stack and heap has the same meaning before distinguished control rewrites";
        attribute :>> leanObligation = "Prove i -> F+1-i is a bijection on 1..F, E[-i]=H[F+1-i], link index and region bounds; separate pre/post rewrite relations";
        attribute :>> requiredPremises = "C object provenance, allocation extents, subtype header/body tags and overlap-safe copying; not equality of native addresses";
        attribute :>> retireRoles = "Repeated hand-coded stack/heap offsets retire only across capture, heap scan, access, restore and rebuild consumers";
        attribute :>> counterexampleIds = "CEX-COORD";
        attribute :>> sourceRefs = "vendor/gambit/include/gambit.h.in:6745-6747; vendor/gambit/lib/mem.c:3724-3795; vendor/gambit/lib/mem.c:4104-4152; vendor/gambit/lib/_kernel.scm:3414-3459";
    }
    part refinement3 : FrameRefinementLaw {
        attribute :>> lawId = "FL-INTERNAL";
        attribute :>> fieldRefs = "FS-SEMANTIC; FS-PHYSICAL";
        attribute :>> parentDuties = "ND-ENCODE; ND-CONTROL; ND-ROOT";
        attribute :>> migrationCuts = "DM-FRAME";
        attribute :>> foundationLanes = "T0-ROOTS; T0-CONTROL";
        attribute :>> quintState = "kind; cfs; F; savedGvmRegs; wrapperRa; actualRa; actualRaLocation";
        attribute :>> quintActions = "saveRegisters; derivePhysical; capture; locateActualRa; restore";
        attribute :>> quintInvariant = "internal actual size transform applied exactly once; actual_ra location and saved-register root interpretation agree";
        attribute :>> leanObligation = "Derive S(F)=F+reserve from canonical internal transform, then derive FRAME_RETI_RA; cfs cannot be replaced by F alone";
        attribute :>> requiredPremises = "Register count, target constraints, full saved-register materialization and special-return origin match";
        attribute :>> retireRoles = "Duplicated internal-size conversion and special-return coordinate rules retire together";
        attribute :>> counterexampleIds = "CEX-INTERNAL";
        attribute :>> sourceRefs = "vendor/gambit/gsc/_t-c-2.scm:865-904; vendor/gambit/gsc/_t-c-3.scm:502-521; vendor/gambit/include/gambit.h.in:6572-6578; vendor/gambit/lib/mem.c:4114-4124";
    }
    part refinement4 : FrameRefinementLaw {
        attribute :>> lawId = "FL-MAP";
        attribute :>> fieldRefs = "FS-PHYSICAL";
        attribute :>> parentDuties = "ND-ENCODE; ND-ROOT";
        attribute :>> migrationCuts = "DM-FRAME";
        attribute :>> foundationLanes = "T0-ROOTS";
        attribute :>> quintState = "mapWords; firstWord; nextWordBase; scanSlot; randomSlot; loadedWord";
        attribute :>> quintActions = "decodeHead; streamNext; lookupSlot; refuseOutOfBounds";
        attribute :>> quintInvariant = "streaming and random lookup agree on bit i-1; all word reads and unsigned shifts are defined";
        attribute :>> leanObligation = "Prove 32-bit chunk aggregation for W=32/64, quotient/remainder lookup and first/next base convention";
        attribute :>> requiredPremises = "Check actual serializer/introspection callers and finite C masks; conditional source discrepancies are not a native reproduction";
        attribute :>> retireRoles = "Separate scan/introspection bit-extraction algorithms can retire into one generated access contract";
        attribute :>> counterexampleIds = "CEX-MAP-INDEX; CEX-SHIFT";
        attribute :>> sourceRefs = "vendor/gambit/include/gambit.h.in:9244-9259; vendor/gambit/include/gambit.h.in:9301-9320; vendor/gambit/lib/mem.c:3816-3891; vendor/gambit/lib/_kernel.scm:3342-3412; vendor/gambit/lib/_io.scm:11688-11706";
    }
    part refinement5 : FrameRefinementLaw {
        attribute :>> lawId = "FL-COVERAGE";
        attribute :>> fieldRefs = "FS-SEMANTIC; FS-CUSTODY";
        attribute :>> parentDuties = "ND-ROOT; ND-CONTROL";
        attribute :>> migrationCuts = "DM-FRAME";
        attribute :>> foundationLanes = "T0-ROOTS; T0-CONTROL; T0-WORK";
        attribute :>> quintState = "semanticLive; savedRegisters; dataSlots; returnRoots; controlEdges; externalRoots; scanResult";
        attribute :>> quintActions = "completeLiveness; materialize; enumerateData; visitControl; scan";
        attribute :>> quintInvariant = "every required logical root is in the union of admitted data, return, control and external-root routes; selected slots initialized/tag-valid";
        attribute :>> leanObligation = "Compose source liveness, representation map, coordinate relation and scanner policy; bitmap equality alone is insufficient";
        attribute :>> requiredPremises = "Whole checkpoint and FFI/native temporary census; closure environment special case; frame RA scanned separately and link tag policy preserved";
        attribute :>> retireRoles = "Duplicate root-interpretation policy may retire; necessary root visits and relocation work remain";
        attribute :>> counterexampleIds = "CEX-ROOT-UNION";
        attribute :>> sourceRefs = "vendor/gambit/gsc/_gvm.scm:137-148; vendor/gambit/gsc/_t-c-2.scm:825-904; vendor/gambit/lib/mem.c:4092-4155; vendor/gambit/lib/mem.c:6830-6870";
    }
    part refinement6 : FrameRefinementLaw {
        attribute :>> lawId = "FL-UPDATE";
        attribute :>> fieldRefs = "FS-CUSTODY; FS-PHYSICAL";
        attribute :>> parentDuties = "ND-ROOT; ND-CONTROL; ND-LIFETIME";
        attribute :>> migrationCuts = "DM-FRAME";
        attribute :>> foundationLanes = "T0-CONTROL; T0-WORK";
        attribute :>> quintState = "copyCustodian; initializedPrefix; originalLink; forwardingState; temporaryMask; nextOrigin";
        attribute :>> quintActions = "reserveCopy; initializePrefix; finishCopy; rewriteLink; hideRawLink; scan; restoreTag";
        attribute :>> quintInvariant = "partial copy never becomes completed frame; control-edge suppression retains custody; no mutator observes scanner-private rewrite";
        attribute :>> leanObligation = "Relate capture states before/after link/RA rewriting, full payload initialization, forwarding and temporary-tag restoration";
        attribute :>> requiredPremises = "Current capture copies before leaving forwarding under MISC_MEM_LOCK; do not import another copier publication order; C locking/epoch proof still open";
        attribute :>> retireRoles = "Separate implicit capture/scan control-state interpretations retire after one explicit state relation";
        attribute :>> counterexampleIds = "CEX-COPY-CONTROL";
        attribute :>> sourceRefs = "vendor/gambit/lib/mem.c:3690-3809; vendor/gambit/lib/mem.c:4132-4155; vendor/gambit/lib/_kernel.scm:1190-1278";
    }
    part refinement7 : FrameRefinementLaw {
        attribute :>> lawId = "FL-HANDOFF";
        attribute :>> fieldRefs = "FS-CUSTODY";
        attribute :>> parentDuties = "ND-PUBLISH; ND-ROOT; ND-LIFETIME";
        attribute :>> migrationCuts = "DM-FRAME; DM-BIND";
        attribute :>> foundationLanes = "T0-EXECUTION; T0-ROOTS; T0-WORK";
        attribute :>> quintState = "vm; executionOwner; participantEpoch; rootCut; scanGrant; relocationEpoch; loadedEpoch";
        attribute :>> quintActions = "materialize; freezeFinalWrites; publishRootCut; grantScanner; relocate; acknowledge; reload; resume";
        attribute :>> quintInvariant = "scanner sees final roots; relocated roots loaded before resumed managed access; scan grant is independent of processor identity";
        attribute :>> leanObligation = "Refine C release/acquire or locks to ROOT-HANDOFF; prove ownership/epoch and location/currentness under worker reassignment";
        attribute :>> requiredPremises = "Participant census and context grants, register cache reload and origin leases; current W_ALL/R_ALL wrapper already exists";
        attribute :>> retireRoles = "PSTATE-coupled scan entry selection and hand-coded generated choreography only after target protocol accepted";
        attribute :>> counterexampleIds = "CEX-EARLY-SCAN";
        attribute :>> sourceRefs = "vendor/gambit/lib/_kernel.scm:4505-4524; vendor/gambit/lib/mem.c:276-311; vendor/gambit/lib/mem.c:6830-6870; vendor/gambit/lib/mem.c:7014-7048";
    }
    part refinement8 : FrameRefinementLaw {
        attribute :>> lawId = "FL-WRITERS";
        attribute :>> fieldRefs = "FS-SEMANTIC; FS-CUSTODY";
        attribute :>> parentDuties = "ND-ROOT; ND-CONTROL";
        attribute :>> migrationCuts = "DM-FRAME; DM-RETIRE";
        attribute :>> foundationLanes = "T0-HEAP; T0-CONTROL; T0-FOREIGN";
        attribute :>> quintState = "slotKind; writeSet; nurseryEpoch; rememberedEdges; rebuildProgress; publishedFrame; aliasClass";
        attribute :>> quintActions = "admitWriter; writeSlot; rememberEdge; rebuildFrame; publishFrame; refuseUnknown";
        attribute :>> quintInvariant = "every admitted mutation preserves scan/reload contract; mature-frame scan exclusion only with complete writer/barrier closure";
        attribute :>> leanObligation = "Prove per-writer root/store obligations and initialization-before-publication; then separately prove generational remembered-edge completeness";
        attribute :>> requiredPremises = "frame-set!, continuation-set!, denv setters, deserialize, foreign aliases and all actual callers; unchanged full-scan route remains sound where necessary";
        attribute :>> retireRoles = "Raw frame writes retire only in migrated scope; no unconditional removal of full scan";
        attribute :>> counterexampleIds = "CEX-ROOT-UNION; CEX-EARLY-SCAN";
        attribute :>> sourceRefs = "vendor/gambit/lib/_kernel.scm:3153-3162; vendor/gambit/lib/_kernel.scm:3439-3597; vendor/gambit/lib/_io.scm:11705-11730";
    }
    part refinement9 : FrameRefinementLaw {
        attribute :>> lawId = "FL-T0";
        attribute :>> fieldRefs = "FS-CUSTODY";
        attribute :>> parentDuties = "ND-LIFETIME; ND-CONTROL; ND-PUBLISH";
        attribute :>> migrationCuts = "DM-FRAME; DM-RETIRE";
        attribute :>> foundationLanes = "T0-EXECUTION; T0-WORK; T0-CONTROL; T0-PROGRESS";
        attribute :>> quintState = "vmDomain; contextLease; descriptorLease; taskCustody; participantSet; workSet; closeState";
        attribute :>> quintActions = "reassignWork; migrateContext; park; capture; closeIngress; drainUsers; retire";
        attribute :>> quintInvariant = "worker reassignment cannot move Scheme ownership implicitly; closure counts all metadata/control users; safety does not imply SMP progress";
        attribute :>> leanObligation = "Compose frame laws with execution/work/control refinement and noncircular progress obligations; cross-VM continuation needs separate admission";
        attribute :>> requiredPremises = "Existing root models supply scoped contracts only; full GC/SMP target transition systems and fairness still need design/proof";
        attribute :>> retireRoles = "Implicit equality of execution owner, root owner, GC worker and processor can retire only after every adapter migrates";
        attribute :>> counterexampleIds = "CEX-WORKER-OWNER";
        attribute :>> sourceRefs = "vendor/gambit/lib/mem.c:276-311; vendor/gambit/lib/mem.c:6830-6870; vendor/gambit/lib/mem.c:6938-6958; vendor/gambit/lib/mem.c:7014-7048";
    }

    part def FrameCounterexample {
        attribute caseId : String;
        attribute lawRefs : String;
        attribute trace : String;
        attribute condition : String;
        attribute status : String;
    }
    part counterexample0 : FrameCounterexample {
        attribute :>> caseId = "CEX-FIELDS";
        attribute :>> lawRefs = "FL-ENCODE";
        attribute :>> trace = "Encode a link or fs beyond its packed field, or use a signed shift whose result is not representable";
        attribute :>> condition = "Field domain admitted without bound/definedness proof";
        attribute :>> status = "algebraic-counterexample-sketch; no executed model/native trace";
    }
    part counterexample1 : FrameCounterexample {
        attribute :>> caseId = "CEX-UNBOUND";
        attribute :>> lawRefs = "FL-BIND";
        attribute :>> trace = "Raw OFD(kind,...) retains nonzero low kind bits; ordinary decoder classifies it as inline with zero fs/map before setup replaces it";
        attribute :>> condition = "A reader admitted before bind; actual inline zero-map domain also requires proof";
        attribute :>> status = "source-derived-conditional-cut; not a demonstrated supported native execution";
    }
    part counterexample2 : FrameCounterexample {
        attribute :>> caseId = "CEX-COORD";
        attribute :>> lawRefs = "FL-COORD";
        attribute :>> trace = "Use H[F-i] for one-based i=F; it aliases H[0] (saved RA) instead of the first copied payload slot H[1]";
        attribute :>> condition = "Missing +1 in stack-to-heap map";
        attribute :>> status = "algebraic-counterexample-sketch; not native reproduction";
    }
    part counterexample3 : FrameCounterexample {
        attribute :>> caseId = "CEX-INTERNAL";
        attribute :>> lawRefs = "FL-INTERNAL";
        attribute :>> trace = "Treat stored internal cfs as already physical F, or apply internal size expansion twice; actual_ra slot changes";
        attribute :>> condition = "Wrong kind/size domain; canonical internal F law omitted";
        attribute :>> status = "conditional-algebraic-sketch; no model exploration";
    }
    part counterexample4 : FrameCounterexample {
        attribute :>> caseId = "CEX-MAP-INDEX";
        attribute :>> lawRefs = "FL-MAP";
        attribute :>> trace = "At i=W+1 decoder nextgcmap already names map word 1, but current random reader indexes nextgcmap[1], selecting map word 2; streaming reader takes nextgcmap[0]";
        attribute :>> condition = "Requires a legal multiword frame and actual caller; _io explode-frame calls frame-slot-live? across slots; native witness remains open";
        attribute :>> status = "conditional-source-discrepancy; reachability and native effect unresolved";
    }
    part counterexample5 : FrameCounterexample {
        attribute :>> caseId = "CEX-SHIFT";
        attribute :>> lawRefs = "FL-MAP";
        attribute :>> trace = "Current random reader uses int literal 1 << b; b>=width(int) is invalid, and shifting into signed sign bit can be invalid before that";
        attribute :>> condition = "Requires target integer widths and a legal requested high slot; not every frame reaches it";
        attribute :>> status = "conditional-C-definedness-gap; no native failure claimed";
    }
    part counterexample6 : FrameCounterexample {
        attribute :>> caseId = "CEX-ROOT-UNION";
        attribute :>> lawRefs = "FL-COVERAGE; FL-WRITERS";
        attribute :>> trace = "Map bits agree yet H[0], saved internal actual_ra, control link, denv or foreign root route is omitted; alternatively an untracked write introduces young reference";
        attribute :>> condition = "Treat data bitmap as complete root census or allow unregistered writer";
        attribute :>> status = "architecture-counterexample-sketch; complete source/caller admission unresolved";
    }
    part counterexample7 : FrameCounterexample {
        attribute :>> caseId = "CEX-COPY-CONTROL";
        attribute :>> lawRefs = "FL-UPDATE";
        attribute :>> trace = "Require byte equality after capture rewrites link/RA, or grant access to temporary FAL-masked control edge while scanner owns it";
        attribute :>> condition = "No phase/owner relation for distinguished control fields";
        attribute :>> status = "architecture-counterexample-sketch; current capture order not relabeled as partial publication";
    }
    part counterexample8 : FrameCounterexample {
        attribute :>> caseId = "CEX-EARLY-SCAN";
        attribute :>> lawRefs = "FL-HANDOFF; FL-WRITERS";
        attribute :>> trace = "Scanner gets grant before producer final store or mutator resumes without relocation reload; captured token or process flag is mistaken for current authority";
        attribute :>> condition = "Missing handoff/reload or rebuilt frame exposed before complete initialization";
        attribute :>> status = "architecture-counterexample-sketch; weak-memory refinement open";
    }
    part counterexample9 : FrameCounterexample {
        attribute :>> caseId = "CEX-WORKER-OWNER";
        attribute :>> lawRefs = "FL-T0";
        attribute :>> trace = "Assign work to a new worker, then interpret worker identity as Scheme context/VM ownership or reclaim image because active calls are zero";
        attribute :>> condition = "Descriptor/code still referenced by stored continuation, scanner, callback or rebuilding frame";
        attribute :>> status = "T0-architecture-counterexample-sketch; no native reproduction";
    }

    part def FrameProjection {
        attribute parentSelectorPath : String;
        attribute adapterStatus : String;
        attribute relation : String;
        attribute scope : String;
    }
    part reasoning0 : FrameProjection {
        attribute :>> parentSelectorPath = "dev/modeling/ascent/native-descriptor.ss";
        attribute :>> adapterStatus = "Fine-grained FL association adapter open; native SysML owns lookup and structure; existing parent ND associations are not FL proofs";
        attribute :>> relation = "Source -> FrameSpec law -> target T0 lane -> existing shared binding -> migration cut -> counterexample and proof gap";
        attribute :>> scope = "DEV target design; root models reused by exact binding, never copied; hypotheses do not prove native behavior";
    }

    part def FrameCostCase {
        attribute gainId : String;
        attribute lawRefs : String;
        attribute baselineRetained : String;
        attribute removedDuplication : String;
        attribute incrementalCost : String;
        attribute measure : String;
        attribute refutation : String;
    }
    part costCase0 : FrameCostCase {
        attribute :>> gainId = "FG-ENCODE";
        attribute :>> lawRefs = "FL-ENCODE; FL-BIND; FL-MAP";
        attribute :>> baselineRetained = "Descriptor decode, root-map reads and target facts already exist";
        attribute :>> removedDuplication = "Manual policy duplication and independent packed-field/bitmap interpretations";
        attribute :>> incrementalCost = "Schema/bounds validation and target qualification; no mandatory added call per slot if generated inline";
        attribute :>> measure = "Authored policy owners, generated token work, descriptor bytes and delta decode cost";
        attribute :>> refutation = "If new schema merely duplicates old emitters/decoders, support grows and no retirement gain follows";
    }
    part costCase1 : FrameCostCase {
        attribute :>> gainId = "FG-COORD";
        attribute :>> lawRefs = "FL-COORD; FL-INTERNAL; FL-UPDATE";
        attribute :>> baselineRetained = "Current copying of F words, return-address storage, link/forwarding rewrites and necessary restore remain";
        attribute :>> removedDuplication = "Repeated independently maintained origin/offset/size transforms";
        attribute :>> incrementalCost = "Generated coordinate checks and origin/copy custody metadata where not already represented";
        attribute :>> measure = "Offset-policy owners removed; copy volume and per-copy metadata delta measured separately";
        attribute :>> refutation = "Correct coordinate law alone saves zero copy words; extra dispatch/metadata can regress runtime";
    }
    part costCase2 : FrameCostCase {
        attribute :>> gainId = "FG-ROOTS";
        attribute :>> lawRefs = "FL-COVERAGE; FL-HANDOFF";
        attribute :>> baselineRetained = "Materialize/scan/update/reload roots and W_ALL/R_ALL are baseline correctness work";
        attribute :>> removedDuplication = "Independent root interpretation and avoidable duplicate publication/scans only where actually established";
        attribute :>> incrementalCost = "Root-view registry, epoch/grant validation and cross-owner synchronization deltas";
        attribute :>> measure = "Complete root coverage; signed delta root visits, handoff operations, bytes and pause components";
        attribute :>> refutation = "Do not count existing root protection as newly introduced cost or claim bitmap generation skips old-generation scans";
    }
    part costCase3 : FrameCostCase {
        attribute :>> gainId = "FG-SMP";
        attribute :>> lawRefs = "FL-HANDOFF; FL-T0";
        attribute :>> baselineRetained = "Required rendezvous, synchronization, task scan work and resource retention do not disappear";
        attribute :>> removedDuplication = "PSTATE ownership coupling and provably avoidable imbalance/duplicate coordination";
        attribute :>> incrementalCost = "Worker/task contexts, epoch membership, claims, handoff and cache-line traffic";
        attribute :>> measure = "Same-VM parallel useful work, wait/imbalance distribution, contention and peak retained memory under equal semantics";
        attribute :>> refutation = "More worker threads, fixed full barriers or forced one processor cannot establish the new architecture or net gain";
    }
    part costCase4 : FrameCostCase {
        attribute :>> gainId = "FG-GENERATION";
        attribute :>> lawRefs = "FL-WRITERS; FL-COVERAGE";
        attribute :>> baselineRetained = "Sound scanning remains for classes with incomplete writer/alias closure";
        attribute :>> removedDuplication = "Repeated mature continuation traversal only for separately admitted writer-complete classes";
        attribute :>> incrementalCost = "New remembered-set barriers/logs, promotion capacity and failure handling plus actual fallback cost";
        attribute :>> measure = "Avoided old-frame root/graph visits versus barrier/log/promotion work; no guessed percentage";
        attribute :>> refutation = "An untracked frame/denv/FFI store invalidates scan exclusion; copying another collector algorithm does not close it";
    }
    part costCase5 : FrameCostCase {
        attribute :>> gainId = "FG-LIFETIME";
        attribute :>> lawRefs = "FL-UPDATE; FL-T0";
        attribute :>> baselineRetained = "Existing live continuation/code/root custody and cleanup remain necessary";
        attribute :>> removedDuplication = "Separate incompatible lifetime interpretations and duplicate support only after real users migrate";
        attribute :>> incrementalCost = "Explicit descriptor/image/context leases, close/drain accounting and possible longer retention";
        attribute :>> measure = "Old semantic owners retired, live lease population, last-user latency and retained bytes";
        attribute :>> refutation = "No active call does not imply no saved continuation; safety without bounded retained users is not positive gain";
    }
}
