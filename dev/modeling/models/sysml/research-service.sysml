/* Architectural ownership; checked observations do not prove arbitrary OS behavior. */
package GambitResearchService {
    private import ScalarValues::*;
    part def ServiceObservation {
        attribute providerMatches:Boolean;
        attribute requestMatches:Boolean;
        attribute closed:Boolean;
        attribute clientSucceeded:Boolean;
        attribute serviceSucceeded:Boolean;
        attribute serviceReaped:Boolean;
        attribute clientReaped:Boolean;
        attribute controlledStop:Boolean;
        attribute forcedStop:Boolean;
        attribute binaryStable:Boolean;
        attribute childrenBound:Boolean;
        attribute contradictoryRow:Boolean;
        attribute admitted:Boolean;
    }
    requirement def ServiceAdmissionLaw {
        subject observation:ServiceObservation;
        require constraint { not observation.admitted or
            (observation.providerMatches and observation.requestMatches and
             observation.closed and observation.clientSucceeded and
             observation.serviceSucceeded and observation.serviceReaped and
             observation.clientReaped and observation.controlledStop and
             not observation.forcedStop and observation.binaryStable and
             observation.childrenBound and not observation.contradictoryRow) }
    }
    part identity {
        attribute owner:String = "Existing research_kernel seal and task_processes durable birth/exec registry";
        attribute inputs:String = "SDK connected-model runtime files, project lock, official service digest and executable role, module closure, ASCENT policy";
        attribute request:String = "Exact model bytes, qualified part, fresh nonce, provider identity and original monotonic deadline";
        attribute replay:String = "Frozen old-frontend input plus complete owned attribute oracle; current and frozen SDK projections must both match";
        attribute checkout:String = "Source directory is a parameter; identity mismatch refuses, never re-signs or selects revision-specific code";
    }
    part lifetime {
        attribute states:String = "planned -> starting -> listening -> client-complete -> stopping -> closed | retained";
        attribute children:String = "Service and RPC client have distinct task birth tokens; startup address is protocol framing, not model stdout parsing";
        attribute cleanup:String = "Five seconds reserved inside the original stage; parent validation reserve also consumes original budget; no timeout renewal";
        attribute interruption:String = "Unreaped or unknown execution remains owned by task-process-registry; output presence or exit zero alone cannot admit";
        attribute publication:String = "Matching provider and nonce; both children reaped; controlled unforced stop; stable binary; full-field oracle when declared; ASCENT admits exactly the requested row";
        attribute profile:String = "Reviewed Darwin arm64 connected parse/instantiate profile; endpoint loopback selection is not a network sandbox";
    }
    part obligations {
        attribute sysml:String = "Architecture, ownership, exclusive obligation assignment and retirement dependencies";
        attribute python:String = "Real SDK API, byte and process identity, original deadlines, controlled stop and wait; no fabricated OS evidence";
        attribute ascent:String = "Finite observed lifecycle and contradictory-row refusal; missing observation yields no admission";
        attribute qnt:String = "No new duplicate model for scalar projection; existing runtime QNT retains concurrent GC/SMP protocols; shared-server concurrency would require a separate transition model before admission";
        attribute lean:String = "No claim that fixture equality proves all models or OS behavior; existing semantic refinement remains independent; no duplicate finite truth-table proof";
        attribute gap:String = "Arbitrary providers, other platforms, host-wide cancellation/reaper failure and unknown native effects remain unqualified";
        attribute runtimeAdmitted:Boolean = false;
    }
    part retirement {
        attribute replaced:String = "Production sysml.project stdout model parser, external endpoint operator path, storage-policy/flow standalone loops and their stdout parsers";
        attribute retained:String = "Task dispatcher, shared sealed worker implementation, one immutable independent frontend oracle, startup address frame";
        attribute otherRunners:String = "Retire each independent runner only after all callers migrate, closure and budgets match, negative controls pass and cold checkout refuses absent evidence";
        attribute globalRebinding:String = "Remove only after the last consumer has private explicit inputs; this source-chain qualification is not global migration evidence";
        attribute allRunnersRetired:Boolean = false;
    }
    part architectureViews {
        attribute renderer:String="src/gambit_smp/architecture_views.py::ArchitectureViews; explicit root/output context; no global ROOT/TASK mutation";
        attribute nativeStructure:String="sysml.structure uses the same sealed SDK/service owner and explicit convert capability; native CLI fixture graph digest is independent";
        attribute preflight:String="architecture.preflight retains Org source hashes and rejects nonportable cache links before expensive native work";
        attribute refinement:String="Nine helper AST identities and post-export renderer body retain independent pre-relocation hashes; eight controls preserve lookup/definition/portable-link refusals";
        attribute retirement:String="sync-views standalone loop, global TASK reassignment, implicit source --write and two CLI launches removed without stubs";
        attribute openTransport:String="Complete DEV SDK projection timed out under original 60-second stage; no retry with a larger budget and no whole-view acceptance";
        attribute openSource:String="Actual old/new renderer both reject vendor/gambit/lib/_kernel.scm:5275-5337 against the current 5333-line source";
        attribute fullViewAdmitted:Boolean=false;
        attribute runtimeAdmitted:Boolean=false;
        attribute qntDuty:String="None duplicated for finite structural conversion; runtime/scheduler transitions remain existing QNT owners";
        attribute leanDuty:String="AST relocation checks are not a proof of arbitrary SDK conversion or full semantic equivalence; existing Lean refinement obligations remain independent";
    }

    part workspaceCohort {
        attribute component:String="Existing research_flow owner context; no additional runner or lifecycle";
        attribute covered:String="123 existing entry modules, 4223 execution-time reads and 168 helper alias assignments";
        attribute algorithmEvidence:String="tests/fixtures/sysml-api/workspace-context-migration.json; normalized pre-migration AST identities and exact numeric-control inventories";
        attribute admission:String="Existing research.audit consumes the declared fixture and checks the entire cohort before terminal ASCENT acceptance";
        attribute removed:String="Cross-module vars/__globals__ discovery, namespace writes, helper rebinding and namespace restoration";
        attribute retained:String="Module-level paths are immutable task-selection hints; all scientific entries are static private libraries; historical/native qualification remains open";
        attribute exitLaw:String="Owner exits normally or exceptionally -> active flag is revoked before context reset; copied callback contexts cannot revive workspace reads/writes after exit";
        attribute boundary:String="In-flight native effects, context-transfer races and whole historical scientific study execution are not proved by inverse AST checks";
        attribute nativeAdmitted:Boolean=false;
        attribute stdoutRetired:Boolean=true;
    }

    part selectedFields {
        attribute producer:String="Existing sysml.project capability; declared literal field paths, exact scalar kinds and explicit model input identities";
        attribute selection:String="tests/fixtures/sysml-api/three-study-selection.json; 807 independently observed fields plus two root-scalar regression controls; three direct layout consumers and complete ordered transport cohort";
        attribute equality:String="Exact JSON scalar kinds and complete ordered fields/layout; Python bool/int equality cannot qualify";
        attribute consumer:String="Existing research_flow projected_fields reads CURRENT artifact provenance; no execution, cache search, model stdout decoding or fallback";
        attribute input:String="Scientific library entries receive a typed dependent Recipe selection; external --projection-run and private run lookup are retired";
        attribute callerProof:String="Main scientific body and limits are unchanged after reversing the single typed input; workspace proof composes with the declared transport replacement";
        attribute failure:String="Missing/stale/changed run, wrong checkout, field-order mismatch or nonempty unqualified model diagnostics refuse delivery";
        attribute retired:String="Three CLI launch and stdout projection blocks; old snippets survive only as inert selected regression data";
        attribute open:String="All 101 remaining guarded decoders and shared formal-study decoder migrated as one source cohort; 133 entries now use the existing capability owner; historic parent inputs remain; whole-study native behavior unqualified";
        attribute cohort:String="tests/fixtures/sysml-api/stdout-cohort-migration.json; 102 complete source inverses; 98 direct request sites and five stdout recovery branches retired";
        attribute orderedDelivery:String="Existing projected_fields supports ordered literal references and original requested model scope; missing reviewed field values refuse; CLI metadata is replaced by explicit typed provenance";
        attribute qntDuty:String="Existing transition and scheduler obligations; no duplicate model for finite field/order/type checks";
        attribute leanDuty:String="Existing unbounded semantic refinement; finite source/fixture checks do not establish whole-study preservation";
        attribute nativeRuntimeAdmitted:Boolean=false;
    }

}
