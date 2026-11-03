package GambitResearchStorage {
    private import ScalarValues::*;
    part def PublicationPolicy {
        attribute studyPrefixes:String;
        attribute sourceGeneratorFiles:String;
        attribute authorInputNames:String;
        attribute authorInputRoot:String;
        attribute studyRunRoot:String;
        attribute historicalCachePrefix:String;
        attribute missingEvidenceDecision:String;
        attribute studyServiceWrites:String;
        attribute formalTools:String;
        attribute readOnlyTools:String;
        attribute sourcePrefixes:String;
        attribute uncuratedTrees:String;
        attribute sourceSuffixes:String;
        attribute inputPrefixes:String;
        attribute inputSuffixes:String;
        attribute configFiles:String;
        attribute explicitInputFiles:String;
        attribute preservedFixtureFiles:String;
        attribute curatedReferencePrefixes:String;
        attribute curatedDocumentPrefixes:String;
        attribute explicitCuratedFiles:String;
        attribute forbiddenPrefixes:String;
        attribute forbiddenSegments:String;
        attribute generatedSuffixes:String;
        attribute generatedNames:String;
        attribute metadataNames:String;
        attribute cacheRoot:String;
        attribute defaultGitDecision:String;
        attribute publicationMeaning:String;
        attribute reviewBoundary:String;
        attribute maxMetadataBytes:Integer;
    }
    part policy:PublicationPolicy {
        attribute :>> uncuratedTrees="evidence/research/**;evidence/refactoring/**";
        attribute :>> studyPrefixes="dev/modeling/tools/";
        attribute :>> sourceGeneratorFiles="";
        attribute :>> authorInputNames="config.json;model-data.json;proof-modules.json;counter-config.json;pvm-paper-source.json";
        attribute :>> authorInputRoot="dev/modeling/inputs/";
        attribute :>> studyRunRoot=".cache/tasks/TASK/runs/RUN/";
        attribute :>> historicalCachePrefix=".cache/research/legacy-evidence/";
        attribute :>> missingEvidenceDecision="unavailable-not-pass";
        attribute :>> studyServiceWrites=".cache/tools/;.cache/reasoning/;.cache/history/;.state/";
        attribute :>> formalTools="sysml;lean;quint;d2;emacs;env;gambit-smp";
        attribute :>> readOnlyTools="rg;git;uname;file;nm;otool;dwarfdump;strings";
        attribute :>> sourcePrefixes="dev/;docs/;models/;src/;tests/;patches/;integrations/;.github/;evidence/dsl/;evidence/scenarios/;evidence/fixtures/";
        attribute :>> sourceSuffixes=".py;.rb;.sh;.ss;.scm;.lean;.qnt;.sysml;.kerml;.org;.md;.d2;.svg;.c;.h;.inc;.in;.s;.S;.rs;.nix;.toml;.lock;.yaml;.yml;.el;.patch;.diff;.js;.ts;.css;.html;.ll;.csv;.jq;.mk";
        attribute :>> inputPrefixes="dev/modeling/inputs/;src/;models/;tests/;patches/;integrations/;.github/;evidence/native/;evidence/dsl/;evidence/scenarios/;evidence/fixtures/";
        attribute :>> inputSuffixes=".json;.ss;.scm;.qnt;.yaml;.yml;.csv";
        attribute :>> explicitInputFiles="docs/experimental/zig/allocation-check-bound-cases.json;docs/experimental/zig/collector-work-context-fields.json;docs/experimental/zig/continuation-writer-callers.json;docs/experimental/zig/gc-native-runtime-cases.json;docs/experimental/zig/gc-native-store-inventory.json;docs/experimental/zig/generated-c-contract-samples.json;docs/experimental/zig/init-spec-constructor-inventory.json;docs/experimental/zig/map-continuation-gc-edges.json;docs/experimental/zig/map-generated-c-points.json;docs/experimental/zig/map-scheme-zig-cases.json;docs/experimental/zig/modernization-benefit-arithmetic.json;docs/experimental/zig/native-callback-callers.json;docs/experimental/zig/native-service-support-ledger.json;docs/experimental/zig/scheme-function-zig-cases.json;docs/experimental/zig/target-root-caller-inventory.json;docs/experimental/zig/tcl-cancel-external-readings.json;docs/experimental/zig/tcl-cancel-propagation-callers.json;docs/experimental/zig/tcl-cancel-propagation-cases.json;docs/experimental/zig/tcl-cancel-writer-callers.json;docs/experimental/zig/tcl-cancel-writer-cases.json;docs/experimental/zig/tcl-cancel-writer-operations.json;docs/experimental/zig/tcl-command-custody-callers.json;docs/experimental/zig/tcl-command-external-readings.json;docs/experimental/zig/tcl-control-boundary-callers.json;docs/experimental/zig/tcl-control-boundary-cases.json;docs/experimental/zig/tcl-control-external-readings.json;docs/experimental/zig/tcl-coro-invariants-caller-inventory.json;docs/experimental/zig/tcl-coro-invariants-cases.json;docs/experimental/zig/tcl-coro-invariants-operations.json;docs/experimental/zig/tcl-entry-cancel-cases.json;docs/experimental/zig/tcl-entry-cancel-operations.json;docs/experimental/zig/tcl-interpreter-reuse-callers.json;docs/experimental/zig/tcl-interpreter-reuse-cases.json;docs/experimental/zig/tcl-mixed-cancel-cases.json;docs/experimental/zig/tcl-mixed-cancel-operations.json;docs/experimental/zig/tcl-next-evaluation-cases.json;docs/experimental/zig/tcl-next-evaluation-operations.json;docs/experimental/zig/tcl-private-coro-caller-inventory.json;docs/experimental/zig/tcl-private-coro-cases.json;docs/experimental/zig/tcl-private-coro-operations.json;docs/experimental/zig/tcl-reuse-service-callers.json;docs/experimental/zig/tcl-reuse-service-cases.json;docs/experimental/zig/tcl-targeted-cancel-cases.json;docs/experimental/zig/tcl-targeted-cancel-operations.json;docs/experimental/zig/tcl-trace-cancel-caller-inventory.json;docs/experimental/zig/tcl-trace-cancel-cases.json;docs/experimental/zig/tcl-trace-cancel-operations.json;docs/experimental/zig/tcl-trace-reachability-caller-inventory.json;docs/experimental/zig/tcl-trace-reachability-cases.json;docs/experimental/zig/tcl-trace-reachability-operations.json;docs/work-items.json;evidence/campaign-rules.ss;evidence/catalog.ss;evidence/configuration-model.json;evidence/continuation-link-model.json;evidence/continuation-origin-model.json;evidence/continuation-saved-stack-origin.json;evidence/continuation-scan-lock-order.json;evidence/eager-chain-work-closure.json;evidence/eager-tail-scan-partition.json;evidence/frozen-trace-history.json;evidence/gc-induction-matrix.json;evidence/gc-notification-lock-order.json;evidence/gc-queue-wait-composition.json;evidence/gc-ranking-matrix.json;evidence/gc-recursive-queue-wait.json;evidence/gc-resize-resource-retirement.json;evidence/gc-source-wait-induction-context.json;evidence/gc-source-wait-induction.json;evidence/gc-wait-count-restore.json;evidence/gc-wait-notification.json;evidence/history-rules.ss;evidence/induction-observations.json;evidence/model-raw-log-attestations.json;evidence/native-failures.json;evidence/native-observation-bindings.json;evidence/papers-audit-expansion.json;evidence/papers.json;evidence/papers.lock.json;evidence/parallel-gc-source-comparison.json;evidence/performance-reliability-stability-model.json;evidence/progress-obligations.json;evidence/protocol-bundles.json;evidence/protocol-extensions.json;evidence/protocol-report-links.json;evidence/protocol-source-correspondence.json;evidence/protocol-source-requirements.json;evidence/pstate-failure-composition.json;evidence/pstate-log-rollback-composition.json;evidence/pstate-log-rollback-source032.json;evidence/pstate-resize-composition.json;evidence/pstate-retirement-generation.json;evidence/pstate-setup-protocol.json;evidence/pstate-spinlock-initialization.json;evidence/pstate-vm-failure-handoff.json;evidence/published-inputs.json;evidence/relations.json;evidence/research-audit.json;evidence/research-rules.ss;evidence/research-source-closure.json;evidence/resize-result-distribution.json;evidence/review-rules.ss;evidence/runtime-source-026.lock.json;evidence/runtime-source-028.lock.json;evidence/runtime-source-029.lock.json;evidence/runtime-source-030.lock.json;evidence/runtime-source-031.lock.json;evidence/runtime-source-032.lock.json;evidence/runtime-source-provisioning.json;evidence/runtime-source.lock.json;evidence/setup-outer-ownership-model.json;evidence/source-026-clean-reproduction.json;evidence/source-provisioning-history.json;evidence/source031-gc-fixtures-scope-review.json;evidence/storage-history.json;evidence/sync-retirement-round-closure.json;evidence/sync-tree-retirement-model.json;evidence/thread-abandonment-completion.json;evidence/views.json;evidence/vm-activity-log-abort-source031.json;evidence/vm-activity-log-abort.json;evidence/vm-constructor-rollback-composition.json;evidence/vm-heap-partial-allocation.json;evidence/vm-list-c-memory-order.json;evidence/vm-list-constructor-visibility.json;evidence/vm-list-reader-retirement.json;evidence/vm-mem-setup-source032.json;evidence/vm-mem-setup-transaction.json;evidence/vm-spinlock-initialization.json;models/gambit/lean/.gitignore;models/gambit/lean/lean-toolchain;models/library/lean/lean-toolchain";
        attribute :>> preservedFixtureFiles="tests/fixtures/bootstrap-stage-reuse/charged-consumption/checkpoint_budget_consumption-old-chargeSafe.log;tests/fixtures/bootstrap-stage-reuse/charged-consumption/checkpoint_budget_consumption-old-holdSafe.log;tests/fixtures/bootstrap-stage-reuse/charged-consumption/checkpoint_budget_consumption-old-receiptSafe.log;tests/fixtures/bootstrap-stage-reuse/charged-consumption/checkpoint_budget_consumption-protocol-safe.log;tests/fixtures/historical-bootstrap/bootstrap-gc-iteration-history/bootstrap.log;tests/fixtures/historical-bootstrap/bootstrap-second-core-history/bootstrap.log;tests/fixtures/historical-bootstrap/bootstrap-serialization-history/bootstrap.log;tests/fixtures/recover-model/ticket_queue_handoff-fixed.log;tests/fixtures/recover-model/ticket_queue_handoff-old.log";
        attribute :>> configFiles=".gitattributes;.gitignore;.gitmodules;.python-version;AGENTS.md;README.md;README.org;justfile;Justfile;pyproject.toml;uv.lock";
        attribute :>> curatedReferencePrefixes="evidence/research/source-references/;evidence/upstream/";
        attribute :>> curatedDocumentPrefixes="evidence/research/published/;evidence/research/retained/;evidence/research/documentary-custody/;evidence/review/";
        attribute :>> explicitCuratedFiles="evidence/native/INVESTIGATION.md;evidence/refactoring/modern-c/diagrams/qualification.d2;evidence/refactoring/modern-c/index.org;evidence/refactoring/modern-c/progress.org;evidence/source-reviews/research-binding-v4/review.json;evidence/tool-environments/herdtools7-opam.json;evidence/research/retained/**/receipt.json;evidence/research/documentary-custody/**/receipt.json;evidence/research/source-references/**/*.txt;evidence/research/section-copy-authority/closure/receipt.json;evidence/research/copy-root-admission/model-input-drift/receipt.json;evidence/research/copy-root-admission/model-history/receipt.json;evidence/research/capacity-admission/quint-initial/receipt.json;evidence/research/hash-layout/compile-failure/receipt.json;evidence/research/future-frame-commit/README.org";
        attribute :>> forbiddenPrefixes=".cache/;.state/;.data/;.venv/;evidence/model-results/;evidence/source-results/;evidence/library/;evidence/research/budget-ledgers/;evidence/research/workspace-states/";
        attribute :>> forbiddenSegments="input-cut;input-snapshot;source-snapshots;raw;configured";
        attribute :>> generatedSuffixes=".command.json;.status.json;.pyc;.pyo;-ir.json;.olean;.o;.so;.dylib;.exe;.stdout;.stderr;.log;.gz;.zip;.bundle";
        attribute :>> generatedNames="typed-ir.json;projection.json;sysml-projection.json;owner-projection.json;ascent-results.json;ascent.json;checks.json;artifacts.json;source-witnesses.json;input.json;model.json;author-data.json";
        attribute :>> metadataNames="receipt.json;provenance.json;audit.json";
        attribute :>> cacheRoot=".cache/tasks/TASK/runs/RUN/";
        attribute :>> defaultGitDecision="deny-unclassified";
        attribute :>> publicationMeaning="Source, deterministic design views and curated primary documentary inputs only; no automatic run-directory publication";
        attribute :>> reviewBoundary="Path/type classification cannot decide arbitrary author intent; unclassified new publication is refused until its role is explicitly declared";
        attribute :>> maxMetadataBytes=65536;
    }
    part def ArtifactClass { attribute category:String; attribute gitAllowed:Boolean; attribute meaning:String; attribute restriction:String; }
    part category0:ArtifactClass { attribute :>> category="maintained-source"; attribute :>> gitAllowed=true; attribute :>> meaning="Canonical maintained programs, models, DSL and deterministic Org/D2/SVG design views"; attribute :>> restriction="Declared source roots; no generated snapshot/IR or runtime-result names"; }
    part category1:ArtifactClass { attribute :>> category="maintained-input"; attribute :>> gitAllowed=true; attribute :>> meaning="Reviewed static test/scenario/schema input consumed by maintained programs"; attribute :>> restriction="Declared input roots; not automatically inferred from a JSON extension"; }
    part category2:ArtifactClass { attribute :>> category="curated-reference"; attribute :>> gitAllowed=true; attribute :>> meaning="Pinned primary source text or upstream source needed by research"; attribute :>> restriction="Reviewed reference root and preserved source identity; never an entire run directory"; }
    part category3:ArtifactClass { attribute :>> category="curated-publication"; attribute :>> gitAllowed=true; attribute :>> meaning="Small reviewed conclusions or source-bound documentary receipts"; attribute :>> restriction="Declared curated roots or exact exceptions; metadata size bound; no run streams/snapshots"; }
    part category4:ArtifactClass { attribute :>> category="execution-output"; attribute :>> gitAllowed=false; attribute :>> meaning="Command/status records, logs, compiler IR, extracted AST, samples, result projections, duplicate sources and binaries"; attribute :>> restriction="Task run cache only; immutable local locator/hash does not make it portable Git evidence"; }
    part category5:ArtifactClass { attribute :>> category="state-and-workspace"; attribute :>> gitAllowed=false; attribute :>> meaning="Lifecycle journals, leases, worktrees and installed runtimes"; attribute :>> restriction="State/cache/worktree owners; no outer-repository tracking"; }
    part def FlowContract {
        attribute owner:String;
        attribute producer:String;
        attribute consumer:String;
        attribute ruleSource:String;
        attribute requiredSourceMustShip:Boolean;
        attribute missingEvidenceCanPass:Boolean;
        attribute exitStatusAloneAdmits:Boolean;
        attribute freshExecutionRequired:Boolean;
        attribute nativeWriterClosureProved:Boolean;
        attribute verificationOwner:String;
        attribute remainingGap:String;
    }
    part artifactFlow:FlowContract {
        attribute :>> owner="dev/modeling";
        attribute :>> producer="All guarded research entries; helpers inherit caller run; explicit view generators are separate publishers";
        attribute :>> consumer="Recipe input loader; Evidence view registry; source-only checkout audit";
        attribute :>> ruleSource="evidence/dsl/research-flow.ss";
        attribute :>> requiredSourceMustShip=true;
        attribute :>> missingEvidenceCanPass=false;
        attribute :>> exitStatusAloneAdmits=false;
        attribute :>> freshExecutionRequired=true;
        attribute :>> nativeWriterClosureProved=false;
        attribute :>> verificationOwner="Native SysML policy evaluation; Python AST/access inventory and write boundary; ASCENT readiness/availability joins. No duplicate QNT/Lean obligation";
        attribute :>> remainingGap="AST inventory is not arbitrary Python alias closure. Declared native output validation is not full OS effect containment. Historical/native proof evidence remains unavailable without exact payloads and semantic verification. MS-TABLES has an exact modular declaration owner; other monolithic-header anchors still block whole-DEV source correspondence. Make migration reports the prior core-recursive policy defect without replacing its execution policy";
    }
    part def FrameworkConvergence {
        attribute taskOwner:String;
        attribute executionOwner:String;
        attribute evidenceOwner:String;
        attribute reasoningOwner:String;
        attribute missingAdapters:String;
        attribute studyDeclaration:String;
        attribute transitionalMechanisms:String;
        attribute retirementCondition:String;
        attribute maintenanceCriterion:String;
        attribute convergenceComplete:Boolean;
    }
    part frameworkBoundary:FrameworkConvergence {
        attribute :>> taskOwner="Existing workspace/task_entry/cli own task identity, leases and output allocation";
        attribute :>> executionOwner="Existing recipes.ExecutionContext and research_kernel own capability execution, deadlines, process observations and durable completion";
        attribute :>> evidenceOwner="Existing source_identity/evidence_views own immutable references, availability and stale-snapshot rejection";
        attribute :>> reasoningOwner="Existing ascent_program owns checked engine sessions; ASCENT owns joins/admission; QNT and Lean retain exclusive semantic proof obligations";
        attribute :>> missingAdapters="Typed sysml.project/source.contract now serve modular-header and Make source correspondence through existing Recipe; Lean checking and design-view publication remain unmigrated; pure-model semantic admission remains Quint-specific";
        attribute :>> studyDeclaration="SysML owns architectural intent and obligations; existing typed Recipe owns stage dependencies and artifact references; domain projectors remain explicit reviewed code";
        attribute :>> transitionalMechanisms="study_execution UUID lifecycle and per-script write wrappers remain containment debt; shared/global workspace rebinding is removed and 123 entry modules use the existing owner context";
        attribute :>> retirementCondition="Equivalent source identities, failure/unavailable outcomes, fixed budgets and negative controls through the existing managed entry must hold before deleting standalone runner/receipt/cache implementations";
        attribute :>> maintenanceCriterion="A new study or source-layout change normally changes owned models, declared inputs and fixtures; shared execution code changes only for a new capability or contract semantics. No new per-study launcher or global-variable rebinding";
        attribute :>> convergenceComplete=false;
    }
    part audit {
        attribute oracle:String="tests/fixtures/sysml-api/research-policy-baseline.json";
        attribute publicationEntry:String="tests/recipes/framework-contracts/publication-entry.json";
        attribute flowEntry:String="tests/recipes/framework-contracts/flow-entry.json";
        attribute retiredEntries:String="dev/modeling/tools/research-flow-study.py;dev/modeling/tools/research-storage-policy.py;dev/modeling/tools/sync-views.py";
        attribute executionOwner:String="Existing research.audit capability, ExecutionContext and research_kernel; no study-local cache/runner or stdout parser";
        attribute viewPublication:String="Pure framework generator emits cache previews; source changes require explicit review; normal audit only compares";
        attribute remainingDebt:String="All 133 scientific entries use existing Recipe ownership; historical/native qualification remains separate";
        attribute nativeWriterClosure:Boolean=false;
        attribute allStudyRunnersRetired:Boolean=true;
        attribute structuralRecipe:String="tests/recipes/framework-contracts/architecture-views.recipe.json";
        attribute structuralBoundary:String="Renderer relocation is AST/fixture checked; complete DEV SDK export exceeds original stage ceiling; source anchor rejects; no whole-view acceptance";
        attribute completedAmendment:String="dev/modeling/tools/darwin-target-range-study.py retired after its four expected model occurrences were checked; fixture owns regression, not another source mutator";
        attribute workspaceMigrationInput:String="tests/fixtures/sysml-api/workspace-context-migration.json";
        attribute workspaceBinding:String="123 entry modules use existing live execution context for 4223 path reads; 168 helper namespace assignments and shared namespace mutation/restore are deleted";
        attribute workspaceProofBoundary:String="Inverse AST substitution and numeric controls preserve declared live-owner algorithms; post-exit reads refuse; no native or historical proof admission";
        attribute remainingStdoutDecoderCount:Integer=0;
        attribute remainingStdoutInventorySha256:String="01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b";
        attribute stdoutMigrationInput:String="tests/fixtures/sysml-api/stdout-cohort-migration.json";
        attribute fieldHandoff:String="All 104 prior guarded decoders and shared formal-study decoder consume explicit CURRENT typed projections; 101 plus shared library form the final source cohort; no native CLI or stdout fallback";
        attribute fieldEvolutionInput:String="tests/fixtures/sysml-api/three-study-evolution.json";
        attribute clueControlsInput:String="tests/fixtures/sysml-api/clue-inference-controls.json";
        attribute scientificMigrationInput:String="tests/fixtures/sysml-api/scientific-cohort-migration.json";
        attribute scientificCatalogModel:String="dev/modeling/models/sysml/scientific-studies.sysml";
        attribute remainingStudyCount:Integer=0;
        attribute remainingStudyInventorySha256:String="01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b";
        attribute newStudyAdmission:String="No standalone study entry is admitted; ScientificStudies owns the exact 221-library/133-entry catalog";
    }

}
