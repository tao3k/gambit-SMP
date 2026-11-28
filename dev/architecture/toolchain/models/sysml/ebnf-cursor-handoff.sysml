package EbnfCursorHandoff {
 private import ScalarValues::*;
 part def Case { attribute key : String; attribute lexerKind : Integer; attribute prefix : String; attribute suffix : String; attribute legacyDatum : Integer; attribute coherentDatum : Integer; attribute scope : String; attribute reasoning : String; }
 part case0 : Case {
 attribute :>> key = "lexerQuote";
 attribute :>> lexerKind = 0;
 attribute :>> prefix = " ->";
 attribute :>> suffix = "'(T 42)\n";
 attribute :>> legacyDatum = 1;
 attribute :>> coherentDatum = 2;
 attribute :>> scope = "source-derived-reader-and-generator-shape";
 attribute :>> reasoning = "Adjacent quote is buffered; current action (T 42) and coherent action (quote (T 42)) both fit deflexer token/action pair";
 }
 part case1 : Case {
 attribute :>> key = "lexerParen";
 attribute :>> lexerKind = 0;
 attribute :>> prefix = " ->";
 attribute :>> suffix = "(T 42)\n";
 attribute :>> legacyDatum = 3;
 attribute :>> coherentDatum = 1;
 attribute :>> scope = "source-derived-reader-entry";
 attribute :>> reasoning = "Adjacent opening paren is buffered; current reads T then remaining lexer validation differs";
 }
 part case2 : Case {
 attribute :>> key = "lexerSpace";
 attribute :>> lexerKind = 0;
 attribute :>> prefix = " ->";
 attribute :>> suffix = " (T 42)\n";
 attribute :>> legacyDatum = 1;
 attribute :>> coherentDatum = 1;
 attribute :>> scope = "datum-only-under-standard-reader";
 attribute :>> reasoning = "Discarded single space is ignored by standard datum reading; effects/locations and rule spans still need qualification";
 }
 part case3 : Case {
 attribute :>> key = "lexerNewline";
 attribute :>> lexerKind = 0;
 attribute :>> prefix = " ->";
 attribute :>> suffix = "\n(T 42)\n";
 attribute :>> legacyDatum = 1;
 attribute :>> coherentDatum = 1;
 attribute :>> scope = "datum-only-under-standard-reader";
 attribute :>> reasoning = "Discarded newline may retain datum but port and private location counters differ";
 }
 part case4 : Case {
 attribute :>> key = "parserQuote";
 attribute :>> lexerKind = 1;
 attribute :>> prefix = "=>";
 attribute :>> suffix = "'value\n";
 attribute :>> legacyDatum = 4;
 attribute :>> coherentDatum = 5;
 attribute :>> scope = "source-derived-selected-action-boundary";
 attribute :>> reasoning = "ACTION wins equal-length tie over Ident; quote cannot extend Ident; helper reach from a whole production remains separately scoped";
 }
 part case5 : Case {
 attribute :>> key = "parserNumber";
 attribute :>> lexerKind = 1;
 attribute :>> prefix = "=>";
 attribute :>> suffix = "42\n";
 attribute :>> legacyDatum = -1;
 attribute :>> coherentDatum = -1;
 attribute :>> scope = "source-derived-not-an-action";
 attribute :>> reasoning = "Ident extends through digits; maximal munch consumes =>42, so a delimiter-only ACTION model is invalid";
 }
 part case6 : Case {
 attribute :>> key = "arrowEOF";
 attribute :>> lexerKind = 0;
 attribute :>> prefix = " ->";
 attribute :>> suffix = "";
 attribute :>> legacyDatum = 0;
 attribute :>> coherentDatum = 0;
 attribute :>> scope = "source-derived-action-then-explicit-error";
 attribute :>> reasoning = "No extra character exists; read-syntax returns EOF and reader helper raises its explicit syntax error";
 }
 part def Node { attribute key : String; attribute ownership : String; attribute anchor : String; attribute rule : String; }
 part node0 : Node {
 attribute :>> key = "witness";
 attribute :>> ownership = "source";
 attribute :>> anchor = "ebnf/lang-reader.ss:237-245,318-327; deflexer.ss:51-67";
 attribute :>> rule = "Reader-accepted, generator-shaped quote-loss witness; standard handler assumptions explicit";
 }
 part node1 : Node {
 attribute :>> key = "scan";
 attribute :>> ownership = "protocol";
 attribute :>> anchor = "ebnf/lexer.ss:120-206";
 attribute :>> rule = "Maximal munch reads past accepted delimiter; first matching reduction wins ties";
 }
 part node2 : Node {
 attribute :>> key = "chars";
 attribute :>> ownership = "owner";
 attribute :>> anchor = "ebnf/stream.ss:40-65";
 attribute :>> rule = "Private unread characters and location history do not rewind physical port";
 }
 part node3 : Node {
 attribute :>> key = "tokens";
 attribute :>> ownership = "owner";
 attribute :>> anchor = "ebnf/lexer.ss:54-99; defparser.ss:17-24";
 attribute :>> rule = "Pending token objects preserve identity; token payload alone cannot reconstruct source trivia";
 }
 part node4 : Node {
 attribute :>> key = "receipt";
 attribute :>> ownership = "contract";
 attribute :>> anchor = "runtime/syntax.ss:255-276; ebnf/stream.ss:93-100";
 attribute :>> rule = "One custody record binds physical/logical coordinates, epoch, aliases and declared observation mode";
 }
 part node5 : Node {
 attribute :>> key = "reader";
 attribute :>> ownership = "consumer";
 attribute :>> anchor = "ebnf/lang-reader.ss:165-170,237-245; _io.scm:13835-13870";
 attribute :>> rule = "Current helper reads physical port; coherent adapter reads buffered suffix plus remaining source";
 }
 part node6 : Node {
 attribute :>> key = "observations";
 attribute :>> ownership = "open";
 attribute :>> anchor = "parser/base.ss:72-96; lexer.ss:99-105; stream.ss:31-35";
 attribute :>> rule = "Datum, locations, errors and callbacks matter; fresh-stream zero end gives intermediate off arithmetic, while normal Gambit filepos packing uses line/column";
 }
 part node7 : Node {
 attribute :>> key = "mode";
 attribute :>> ownership = "decision";
 attribute :>> anchor = "ebnf/lang-reader.ss:165-170,237-245";
 attribute :>> rule = "Coherent quote preservation changes an existing accepted source observation; classify as behavior repair";
 }
 part node8 : Node {
 attribute :>> key = "settlement";
 attribute :>> ownership = "custody";
 attribute :>> anchor = "ebnf/lexer.ss:163-189; expander/module.ss:275-318";
 attribute :>> rule = "Reject retains source owner; unknown commit retains authoritative record and prevents blind replay";
 }
 part def Edge { attribute producer : Integer; attribute consumer : Integer; }
 part edge0 : Edge { attribute :>> producer = 0; attribute :>> consumer = 1; }
 part edge1 : Edge { attribute :>> producer = 1; attribute :>> consumer = 2; }
 part edge2 : Edge { attribute :>> producer = 1; attribute :>> consumer = 3; }
 part edge3 : Edge { attribute :>> producer = 2; attribute :>> consumer = 4; }
 part edge4 : Edge { attribute :>> producer = 3; attribute :>> consumer = 4; }
 part edge5 : Edge { attribute :>> producer = 4; attribute :>> consumer = 5; }
 part edge6 : Edge { attribute :>> producer = 5; attribute :>> consumer = 6; }
 part edge7 : Edge { attribute :>> producer = 6; attribute :>> consumer = 7; }
 part edge8 : Edge { attribute :>> producer = 4; attribute :>> consumer = 8; }
 part edge9 : Edge { attribute :>> producer = 8; attribute :>> consumer = 4; }
 part def Gate { attribute key : String; attribute rule : String; attribute qualified : Boolean; }
 part gate0 : Gate { attribute :>> key = "tokenBoundary"; attribute :>> rule = "No future token residue or fully qualified raw-span delivery; payload printing is insufficient"; attribute :>> qualified = false; }
 part gate1 : Gate { attribute :>> key = "positions"; attribute :>> rule = "Port identity, encoding/EOL, logical/physical coordinates and rule spans are preserved for declared mode"; attribute :>> qualified = false; }
 part gate2 : Gate { attribute :>> key = "effectsAndErrors"; attribute :>> rule = "Readtable/refill and exception observations are source-equivalent or classified as behavior repair"; attribute :>> qualified = false; }
 part gate3 : Gate { attribute :>> key = "settlement"; attribute :>> rule = "Epoch-pinned, root-protected single custody and commit-result settlement are qualified"; attribute :>> qualified = false; }
 part def Benefit { attribute key : String; attribute removed : String; attribute mechanism : String; attribute added : String; }
 part benefit0 : Benefit {
 attribute :>> key = "resetConstructors";
 attribute :>> removed = "Baseline T=sections+actions character-stream and token-stream constructor calls";
 attribute :>> mechanism = "Keep one coherent cursor domain only after mode-specific equivalence";
 attribute :>> added = "Cannot credit removal before token/location/error consumers and continuation aliases are migrated";
 }
 part benefit1 : Benefit {
 attribute :>> key = "tokenReplay";
 attribute :>> removed = "Avoid repeated token construction only where source consumer no longer needs it";
 attribute :>> mechanism = "Preserve canonical tokens or stable raw spans without re-lexing";
 attribute :>> added = "Span storage, token identity and trivia/handler history; some work is mandatory";
 }
 part benefit2 : Benefit {
 attribute :>> key = "parallelConsumers";
 attribute :>> removed = "Remove false serialization for independent input domains";
 attribute :>> mechanism = "Owner-scoped cursors and qualified immutable reader definitions";
 attribute :>> added = "Pins, epochs, owner handoff and unknown-result settlement; shared physical input remains serialized";
 }
 part benefit3 : Benefit {
 attribute :>> key = "acceptedBehavior";
 attribute :>> removed = "Quote loss has a source-derived accepted-reader witness";
 attribute :>> mechanism = "Choose an explicit behavior-repair decision before corrected buffered reading";
 attribute :>> added = "Correctness repair is not an automatic speedup or equivalence claim";
 }
 attribute sourceWitnessDerived : Boolean = true;
 attribute nativeWitnessReproduced : Boolean = false;
 attribute actualAdapterAdmitted : Boolean = false;
 part def CursorRecord {
 attribute portOrigin : String; attribute inputGeneration : Integer;
 attribute characterEncoding : String; attribute eolPolicy : String;
 attribute readtableIdentity : String; attribute readerInstance : String;
 attribute physicalNext : Integer; attribute logicalNext : Integer;
 attribute lastCharacterLocation : String; attribute newlineHistoryIdentity : String;
 attribute characterResidueIdentity : String; attribute tokenResidueIdentity : String;
 attribute pendingTokens : Integer; attribute callbackExtent : String;
 attribute ownerSource : Boolean; attribute ownerTarget : Boolean; attribute rootPinned : Boolean;
 attribute legacyMode : Boolean; attribute coherentMode : Boolean;
 attribute transferRequested : Boolean; attribute epochMatches : Boolean;
 }
 requirement def CursorRecordLaw { subject record : CursorRecord;
 require constraint { not record.transferRequested or
 ((record.ownerSource or record.ownerTarget) and not (record.ownerSource and record.ownerTarget) and
 record.rootPinned and record.epochMatches and record.pendingTokens == 0 and
 (record.legacyMode or record.coherentMode) and not (record.legacyMode and record.coherentMode)) }
 }
 part def HandoffWitness { attribute requested : Boolean; attribute tokenBoundary : Boolean; attribute positions : Boolean; attribute effectsAndErrors : Boolean; attribute settlement : Boolean; }
 requirement def HandoffLaw { subject witness : HandoffWitness;
 require constraint { not witness.requested or (witness.tokenBoundary and witness.positions and witness.effectsAndErrors and witness.settlement) }
 }
 part history : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "CH-H"; attribute :>> kind = "interleaving"; attribute :>> subjectPath = "models/build/ebnf_cursor_handoff.qnt"; attribute :>> subjectScope = "ebnf_cursor_handoff:Test$"; attribute :>> premise = "Native-derived selected delimiter suffixes, maximal-munch boundary, declared observation modes and epoch/custody controls; finite fixture reader only";
 }
 part induction : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "CH-I"; attribute :>> kind = "induction"; attribute :>> subjectPath = "models/build/EbnfCursorHandoff.lean"; attribute :>> subjectScope = "EbnfCursorHandoff:remainderConserved;emptyBufferAgreement;quoteLossDistinct;tokenPayloadNotSource;negativeFreshOff;commitRetainsSingleOwner;workThreshold"; attribute :>> premise = "Conditional suffix conservation, quoted datum distinction, noninjective token payload, legacy off arithmetic and custody kernels";
 }
 part source : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "CH-S"; attribute :>> kind = "source-refinement"; attribute :>> subjectPath = "dev/architecture/toolchain/ebnf-cursor-handoff-design.org"; attribute :>> subjectScope = "CH-S:handoff-source-refinement"; attribute :>> premise = "Selected legal-reader witness derived; full production simulation, token residue, custom callbacks, errors and mode-specific observation relation remain open";
 }
 part platform : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "CH-E"; attribute :>> kind = "environment-refinement"; attribute :>> subjectPath = "dev/architecture/toolchain/ebnf-cursor-handoff-design.org"; attribute :>> subjectScope = "CH-E:handoff-native-refinement"; attribute :>> premise = "Native adapter, port counters/encoding, root transfer, linearizable commit and continuation winding remain unqualified";
 }
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = platform; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = EbnfReaderCustody::source; }
}
