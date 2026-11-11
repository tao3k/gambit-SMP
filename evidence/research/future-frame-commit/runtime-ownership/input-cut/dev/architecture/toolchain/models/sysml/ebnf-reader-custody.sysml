package EbnfReaderCustody {
 private import ScalarValues::*;
 part def Region { attribute key : String; attribute ownership : String; attribute anchor : String; attribute labelText : String; attribute rule : String; }
 part region0 : Region {
 attribute :>> key = "entry";
 attribute :>> ownership = "definition";
 attribute :>> anchor = "expander/module.ss:275-318; ebnf/lang.ss:5-18";
 attribute :>> labelText = "Selected reader procedure and phase instance";
 attribute :>> rule = "Preserve selected phase export and original instance; same spelling is insufficient";
 }
 part region1 : Region {
 attribute :>> key = "grammar";
 attribute :>> ownership = "candidate";
 attribute :>> anchor = "ebnf/deflexer.ss:73-93; lang-reader.ss:267-351";
 attribute :>> labelText = "Generated lexer languages and reductions";
 attribute :>> rule = "Reuse already-loaded grammar definitions; freezing requires no mutable aliases to lists, structs, tables or callbacks";
 }
 part region2 : Region {
 attribute :>> key = "derivatives";
 attribute :>> ownership = "candidate";
 attribute :>> anchor = "ebnf/rlang.ss:35-44,78-115";
 attribute :>> labelText = "Regular-language nodes and charset hash tables";
 attribute :>> rule = "Deriv/delta read existing nodes and allocate results; reachable charset hash tables are mutable representations, not intrinsically frozen";
 }
 part region3 : Region {
 attribute :>> key = "reductions";
 attribute :>> ownership = "callback";
 attribute :>> anchor = "ebnf/lexer.ss:120-206; deflexer.ss:51-67";
 attribute :>> labelText = "Reduction callbacks and maximal-munch fallback";
 attribute :>> rule = "Callbacks receive lexeme and location; lex1 E also captures stream, accepted chars, languages and reductions";
 }
 part region4 : Region {
 attribute :>> key = "invocation";
 attribute :>> ownership = "session";
 attribute :>> anchor = "ebnf/lang-reader.ss:20-126,131-264";
 attribute :>> labelText = "Section parser and request closures";
 attribute :>> rule = "Port, accumulated ASTs/rules and K/E are per invocation; action syntax is read as data here, not evaluated here";
 }
 part region5 : Region {
 attribute :>> key = "streams";
 attribute :>> ownership = "owner";
 attribute :>> anchor = "ebnf/stream.ss:19-72; lexer.ss:20-22,54-97";
 attribute :>> labelText = "Physical port plus character/token buffers";
 attribute :>> rule = "One resource domain owns all aliases; per-character port mutex does not serialize the full multi-layer reader protocol";
 }
 part region6 : Region {
 attribute :>> key = "parserK_E";
 attribute :>> ownership = "borrow";
 attribute :>> anchor = "ebnf/defparser.ss:17-40,445-475; lang-reader.ss:204-216";
 attribute :>> labelText = "Ordinary success/failure continuations";
 attribute :>> rule = "Preserve stack-tail eq used by rewind, stream aliases and callback order; these procedures are not themselves captured call/cc continuations";
 }
 part region7 : Region {
 attribute :>> key = "readtable";
 attribute :>> ownership = "dynamic";
 attribute :>> anchor = "runtime/syntax.ss:255-276; vendor/gambit/lib/_io.scm:12694-12699,13300-13323";
 attribute :>> labelText = "Dynamic readtable callbacks and native refill";
 attribute :>> rule = "Transitive handler/refill effects require a capability cut; extension callbacks are not made pure by a constant reader procedure";
 }
 part region8 : Region {
 attribute :>> key = "result";
 attribute :>> ownership = "output";
 attribute :>> anchor = "ebnf/lang-reader.ss:59-86,131-139; parser/base.ss:7-24,72-79";
 attribute :>> labelText = "AST/token/location output graph";
 attribute :>> rule = "Syntax locations use port name/container; tokens and exceptions may retain locations that still reference ports";
 }
 part region9 : Region {
 attribute :>> key = "errors";
 attribute :>> ownership = "custody";
 attribute :>> anchor = "ebnf/lang-reader.ss:59-71; parser/base.ss:28-69; _io.scm:10003-10014";
 attribute :>> labelText = "Error translation, diagnostics and resource exit";
 attribute :>> rule = "Retain original non-ParseError exception and diagnostic state; ordinary call-with-input-file shown closes after normal return, not via dynamic-wind";
 }
 part region10 : Region {
 attribute :>> key = "continuation";
 attribute :>> ownership = "dynamic";
 attribute :>> anchor = "vendor/gambit/lib/_thread.scm:8302-8320,8555-8584";
 attribute :>> labelText = "Nonlocal exit and continuation reentry";
 attribute :>> rule = "Preserve dynamic extent and current mutable state; continuation restoration is not rollback of streams or effects";
 }
 part region11 : Region {
 attribute :>> key = "handoff";
 attribute :>> ownership = "unresolved";
 attribute :>> anchor = "ebnf/lang-reader.ss:165-170,237-245; lexer.ss:163-189; stream.ss:59-65";
 attribute :>> labelText = "Lexer lookahead to direct Scheme read";
 attribute :>> rule = "Old char buffer is distinct from port cursor; prove observationally harmless buffered prefix or retain legacy/refuse managed handoff";
 }
 part def Edge { attribute producer : Integer; attribute consumer : Integer; }
 part edge0 : Edge { attribute :>> producer = 0; attribute :>> consumer = 1; }
 part edge1 : Edge { attribute :>> producer = 0; attribute :>> consumer = 4; }
 part edge2 : Edge { attribute :>> producer = 1; attribute :>> consumer = 2; }
 part edge3 : Edge { attribute :>> producer = 1; attribute :>> consumer = 3; }
 part edge4 : Edge { attribute :>> producer = 4; attribute :>> consumer = 5; }
 part edge5 : Edge { attribute :>> producer = 4; attribute :>> consumer = 6; }
 part edge6 : Edge { attribute :>> producer = 4; attribute :>> consumer = 7; }
 part edge7 : Edge { attribute :>> producer = 4; attribute :>> consumer = 8; }
 part edge8 : Edge { attribute :>> producer = 4; attribute :>> consumer = 9; }
 part edge9 : Edge { attribute :>> producer = 5; attribute :>> consumer = 3; }
 part edge10 : Edge { attribute :>> producer = 5; attribute :>> consumer = 11; }
 part edge11 : Edge { attribute :>> producer = 3; attribute :>> consumer = 5; }
 part edge12 : Edge { attribute :>> producer = 3; attribute :>> consumer = 7; }
 part edge13 : Edge { attribute :>> producer = 6; attribute :>> consumer = 5; }
 part edge14 : Edge { attribute :>> producer = 7; attribute :>> consumer = 10; }
 part edge15 : Edge { attribute :>> producer = 10; attribute :>> consumer = 4; }
 part edge16 : Edge { attribute :>> producer = 8; attribute :>> consumer = 5; }
 part edge17 : Edge { attribute :>> producer = 9; attribute :>> consumer = 8; }
 part edge18 : Edge { attribute :>> producer = 11; attribute :>> consumer = 7; }
 part def Gate { attribute key : String; attribute rule : String; attribute qualified : Boolean; }
 part gate0 : Gate { attribute :>> key = "captureAliases"; attribute :>> rule = "All aliases/writers for grammar, reductions, stream and outputs are classified"; attribute :>> qualified = false; }
 part gate1 : Gate { attribute :>> key = "callbackEffects"; attribute :>> rule = "Reader handlers, native refill and diagnostic effects are qualified"; attribute :>> qualified = false; }
 part gate2 : Gate { attribute :>> key = "cursorHandoff"; attribute :>> rule = "Buffered-prefix/direct-port handoff preserves source observations"; attribute :>> qualified = false; }
 part gate3 : Gate { attribute :>> key = "continuationExtent"; attribute :>> rule = "Reentry, nonlocal exit, closed-port results and dynamic bindings are source-equivalent"; attribute :>> qualified = false; }
 part gate4 : Gate { attribute :>> key = "outputFreeze"; attribute :>> rule = "Returned output and failure evidence have an admitted identity and lifetime cut"; attribute :>> qualified = false; }
 part def Benefit { attribute key : String; attribute removed : String; attribute mechanism : String; attribute added : String; }
 part benefit0 : Benefit {
 attribute :>> key = "grammar";
 attribute :>> removed = "Only additional cross-session reinitialization/decode can be removed; current module reuse is baseline";
 attribute :>> mechanism = "Immutable qualified grammar definitions with original singleton identity";
 attribute :>> added = "Alias audit and publication; derivative result allocation is still required unless separately optimized";
 }
 part benefit1 : Benefit {
 attribute :>> key = "streams";
 attribute :>> removed = "False serialization between independent ports can be removed";
 attribute :>> mechanism = "Resource domains with per-invocation buffers and callbacks";
 attribute :>> added = "For normal section/action paths T = sections + embedded actions: T char-stream and T token-stream constructor calls remain baseline; also pins, owner stack and callback tracking";
 }
 part benefit2 : Benefit {
 attribute :>> key = "readerResults";
 attribute :>> removed = "Repeated reads/parses only if exact consumer observation is equivalent";
 attribute :>> mechanism = "Qualified result/effect snapshot with input/readtable/identity evidence";
 attribute :>> added = "Locations, exceptions, callbacks and cursor state can invalidate reuse; data-only AST equality is insufficient";
 }
 part benefit3 : Benefit {
 attribute :>> key = "continuations";
 attribute :>> removed = "Avoid holding physical locks while control leaves a reader";
 attribute :>> mechanism = "Retain logical resource lease and roots across suspension; reenter with original dynamic bindings";
 attribute :>> added = "Lifetime retention, closed-port observations and multi-shot semantics; no replay/rollback saving credited";
 }
 attribute actualAdmitted : Boolean = false;
 attribute consumerCount : Integer = 2;
 attribute depthLimit : Integer = 3;
 part def ReaderWitness { attribute requested : Boolean; attribute captureAliases : Boolean; attribute callbackEffects : Boolean; attribute cursorHandoff : Boolean; attribute continuationExtent : Boolean; attribute outputFreeze : Boolean; }
 requirement def ReaderAdmissionLaw {
 subject witness : ReaderWitness;
 require constraint { not witness.requested or (witness.captureAliases and witness.callbackEffects and witness.cursorHandoff and witness.continuationExtent and witness.outputFreeze) }
 }
 part history : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "ER-H"; attribute :>> kind = "interleaving"; attribute :>> subjectPath = "models/build/ebnf_reader_custody.qnt"; attribute :>> subjectScope = "ebnf_reader_custody:Test$"; attribute :>> premise = "Finite alias/owner, buffer handoff, nested callback, suspension/reentry, exception root and result reuse controls; no native claim";
 }
 part induction : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "ER-I"; attribute :>> kind = "induction"; attribute :>> subjectPath = "models/build/EbnfReaderCustody.lean"; attribute :>> subjectScope = "EbnfReaderCustody:bufferHead;handoffIfEmpty;bufferLossCounterexample;resumeRetainsMutation;exitRetainsPort;rootBlocksReclaim;workThreshold"; attribute :>> premise = "Conditional buffered observation and custody kernels; full source and QNT simulation remain open";
 }
 part source : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "ER-S"; attribute :>> kind = "source-refinement"; attribute :>> subjectPath = "dev/architecture/toolchain/ebnf-reader-custody-design.org"; attribute :>> subjectScope = "ER-S:reader-source-refinement"; attribute :>> premise = "Actual lexer/direct reader handoff, aliases, custom handlers, multi-shot continuation and closed-resource observations remain open";
 }
 part platform : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "ER-E"; attribute :>> kind = "environment-refinement"; attribute :>> subjectPath = "dev/architecture/toolchain/ebnf-reader-custody-design.org"; attribute :>> subjectScope = "ER-E:reader-native-refinement"; attribute :>> premise = "GC roots, owner affinity, dynamic extent, native port refill and publication require source/platform qualification";
 }
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = platform; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = GerbilInitializationClosure::source; }
}
