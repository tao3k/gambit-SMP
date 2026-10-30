package LogicalCursor {
 private import ScalarValues::*;
 part def Facet { attribute key : String; attribute semantic : String; attribute anchor : String; attribute rule : String; }
 part facet0 : Facet {
  attribute :>> key = "raw-span"; attribute :>> semantic = "new-contract";
  attribute :>> anchor = "lexer.ss:120-190; lexer.ss:23-26,62-66";
  attribute :>> rule = "Accepted lexeme, ignored trivia and speculative lookahead have distinct half-open decoded-character intervals; token payload is not source";
 }
 part facet1 : Facet {
  attribute :>> key = "token-identity"; attribute :>> semantic = "preserve";
  attribute :>> anchor = "lexer.ss:54-105; defparser.ss:17-24";
  attribute :>> rule = "Peek/unget preserve canonical token objects and parser list-tail identity; token rewind does not repeat reductions or reader effects";
 }
 part facet2 : Facet {
  attribute :>> key = "positions"; attribute :>> semantic = "mode-qualified";
  attribute :>> anchor = "stream.ss:31-35,40-100; base.ss:72-96; _io.scm:10314-10329";
  attribute :>> rule = "Keep origin, encoding/EOL, next boundary and last-character location distinct; ordinary filepos packs line/column; changing observable intermediate locations requires repair classification";
 }
 part facet3 : Facet {
  attribute :>> key = "exceptions"; attribute :>> semantic = "preserve";
  attribute :>> anchor = "lang-reader.ss:59-76,165-170,237-245; base.ss:28-69";
  attribute :>> rule = "Preserve ParseError translation, other exception propagation, effects already performed and exact error roots; EOF remains a separate result until helper raises";
 }
 part facet4 : Facet {
  attribute :>> key = "continuation"; attribute :>> semantic = "preserve";
  attribute :>> anchor = "_thread.scm:8302-8320,8555-8584; _io.scm:10003-10014";
  attribute :>> rule = "Capture pins original live mutable domain; reentry observes current state and dynamic winding, not a copied cursor snapshot; closed resources are not reopened";
 }
 part facet5 : Facet {
  attribute :>> key = "coherent-entry"; attribute :>> semantic = "explicit-repair";
  attribute :>> anchor = "lang-reader.ss:165-170,237-245; EbnfCursorHandoff::case0";
  attribute :>> rule = "Deliver buffered quote before physical suffix; accepted quote-loss witness changes action datum and needs explicit behavior decision";
 }
 part def Gate { attribute key : String; attribute qualified : Boolean; attribute rule : String; }
 part gate0 : Gate { attribute :>> key = "span-partition"; attribute :>> qualified = false; attribute :>> rule = "All accepted and ignored intervals covered exactly; uncommitted lookahead remains unread; stable decoded source identity"; }
 part gate1 : Gate { attribute :>> key = "reader-observations"; attribute :>> qualified = false; attribute :>> rule = "Mode-specific datum, location, callback order, exceptions and external effects reflected for every actual reader entry"; }
 part gate2 : Gate { attribute :>> key = "token-aliases"; attribute :>> qualified = false; attribute :>> rule = "Canonical token and parser-tail identity plus EOF caching preserved; pending token handoff independently qualified"; }
 part gate3 : Gate { attribute :>> key = "continuation-lifetime"; attribute :>> qualified = false; attribute :>> rule = "Callbacks, dynamic-wind, captures, port close and multi-shot invocations retain original domain and individual invocation identity"; }
 part gate4 : Gate { attribute :>> key = "settlement"; attribute :>> qualified = false; attribute :>> rule = "Value/error/escape known or authoritatively pending; no automatic retry; native roots and owner transfer source-refined"; }
 part gate5 : Gate { attribute :>> key = "entry-census"; attribute :>> qualified = false; attribute :>> rule = "All five direct read-syntax sites, two reset sites, section constructors and external aliases inventoried; declared behavior repair accepted"; }
 part def Retirement { attribute key : String; attribute anchor : String; attribute condition : String; attribute avoided : String; attribute added : String; }
 part retirement0 : Retirement {
  attribute :>> key = "physical-entry"; attribute :>> anchor = "lang-reader.ss:23,99,123,166,238; module.ss:275-318";
  attribute :>> condition = "All direct reader sites use one domain, including recursive section/header paths; callbacks and native aliases mediated or rejected; explicit-repair decision recorded";
  attribute :>> avoided = "Eliminate split authority between physical reader and logical lexer at qualified handoff";
  attribute :>> added = "Reader adapter, retained source/trivia, observed-effect and error reflection";
 }
 part retirement1 : Retirement {
  attribute :>> key = "action-reset"; attribute :>> anchor = "lang-reader.ss:169,242; lexer.ss:42-44; stream.ss:31-35";
  attribute :>> condition = "Grammar selection changes without discarding character/token state; no pending future token or qualified span replay; all old stream aliases drained or redirected preserving identity";
  attribute :>> avoided = "At most 2A stream constructor calls and A initial-location constructor calls for A completed actions; not measured allocations";
  attribute :>> added = "Epoch and token side metadata; pinned legacy views may delay retirement; no credit for existing grammar reuse";
 }
 part retirement2 : Retirement {
  attribute :>> key = "domain-release"; attribute :>> anchor = "stream.ss:37-38; lexer.ss:50-52; _io.scm:10003-10014";
  attribute :>> condition = "No continuation/token/error/native borrow pins and no unknown deliveries; resource-close semantics and object reclamation treated separately";
  attribute :>> avoided = "Avoid duplicate retry/relex/reopen after unknown completion; correctness benefit has no unconditional time estimate";
  attribute :>> added = "Retention proportional to oldest live view; arbitrary multi-shot capture prevents bounded retention without further contract";
 }
 attribute actualAdmitted : Boolean = false;
 attribute fixtureChars : Integer = 5;
 part def RawSpan { attribute sourceIdentity : String; attribute inputGeneration : Integer; attribute startBoundary : Integer; attribute limitBoundary : Integer; attribute byteMapKnown : Boolean; }
 part def CursorDomain {
  attribute identity : String; attribute owner : String; attribute inputGeneration : Integer;
  attribute logicalNext : Integer; attribute fetchedNext : Integer; attribute committedNext : Integer;
  attribute readtableIdentity : String; attribute encodingPolicy : String; attribute eolPolicy : String;
  attribute tokenViewIdentity : String; attribute triviaViewIdentity : String; attribute locationViewIdentity : String;
  attribute capturePins : Integer; attribute errorPins : Integer; attribute nativePins : Integer; attribute unknownDeliveries : Integer;
  attribute retired : Boolean;
 }
 requirement def RetirementLaw { subject domain : CursorDomain;
  require constraint { not domain.retired or (domain.capturePins == 0 and domain.errorPins == 0 and domain.nativePins == 0 and domain.unknownDeliveries == 0) }
 }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner = GambitBuildAssurance::scheduler.component;
  attribute :>> obligationId = "LC-H"; attribute :>> kind = "interleaving"; attribute :>> subjectPath = "models/build/logical_cursor.qnt"; attribute :>> subjectScope = "logical_cursor:Test$"; attribute :>> premise = "Finite decoded-character interval, token alias, live continuation and value/error settlement model; not a general Scheme reader"; }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner = GambitBuildAssurance::scheduler.component;
  attribute :>> obligationId = "LC-I"; attribute :>> kind = "induction"; attribute :>> subjectPath = "models/build/LogicalCursor.lean"; attribute :>> subjectScope = "LogicalCursor:partition;spanLength;resumeCurrent;rootedCapture;settlementNoRetry;retireNeedsDrain;netWork"; attribute :>> premise = "Conditional interval, live-domain, drain and work inequalities; source simulation and native memory ordering remain open"; }
 part source : GambitAssuranceRouting::ModelNeed { ref part :>> owner = GambitBuildAssurance::scheduler.component;
  attribute :>> obligationId = "LC-S"; attribute :>> kind = "source-refinement"; attribute :>> subjectPath = "dev/architecture/toolchain/logical-cursor-design.org"; attribute :>> subjectScope = "LC-S:logical-cursor-source"; attribute :>> premise = "Actual span producers, all reader entry/reset consumers, exceptions and continuation identity need complete simulation; repair differs from equivalence"; }
 part platform : GambitAssuranceRouting::ModelNeed { ref part :>> owner = GambitBuildAssurance::scheduler.component;
  attribute :>> obligationId = "LC-E"; attribute :>> kind = "environment-refinement"; attribute :>> subjectPath = "dev/architecture/toolchain/logical-cursor-design.org"; attribute :>> subjectScope = "LC-E:logical-cursor-native"; attribute :>> premise = "Port/encoding adaptation, native borrower exclusion, GC pin lifetime and linearizable result delivery unqualified"; }
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = platform; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = EbnfCursorHandoff::source; }
}
