/* Historical repair reference; no native admission from source location. */
package GambitSharedHeapSmpPr988Mechanisms {
 private import GambitSharedHeapSmp::*;
 part pr988GcPhase:SourceSite {
  attribute :>> id="pr988GcPhase";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> anchor="mark_reachable_from_marked";
  attribute :>> role="request-service-design";
  attribute :>> observed="Current source anchor reviewed independently of PR988 patch ancestry.";
  attribute :>> required="Root publication before scanning; phase barrier does not prove writer closure, Tail custody or capacity.";
  attribute :>> gap="Current-producer native failure and cost acceptance remains open; reuse existing models and tests in pr988-refactoring-validation.org.";
  ref part :>> question=cutSource;
 }
 part pr988Rehash:SourceSite {
  attribute :>> id="pr988Rehash";
  attribute :>> artifact="vendor/gambit/lib/_mem/weak-tables.inc";
  attribute :>> anchor="gc_hash_table_rehash_in_situ";
  attribute :>> role="request-service-design";
  attribute :>> observed="Current source anchor reviewed independently of PR988 patch ancestry.";
  attribute :>> required="Hash strategy and layout ownership; private C copy does not justify published Scheme resize.";
  attribute :>> gap="Current-producer native failure and cost acceptance remains open; reuse existing models and tests in pr988-refactoring-validation.org.";
  ref part :>> question=cutSource;
 }
 part pr988TableTransaction:SourceSite {
  attribute :>> id="pr988TableTransaction";
  attribute :>> artifact="vendor/gambit/lib/_system.scm";
  attribute :>> anchor="(define-prim (##table-set!";
  attribute :>> role="request-service-design";
  attribute :>> observed="Current source anchor reviewed independently of PR988 patch ancestry.";
  attribute :>> required="Probe and allocating predicates outside commit; validate revision, reload moved operands, settle all exceptions.";
  attribute :>> gap="Current-producer native failure and cost acceptance remains open; reuse existing models and tests in pr988-refactoring-validation.org.";
  ref part :>> question=cutSource;
 }
 part pr988SymbolIdentity:SourceSite {
  attribute :>> id="pr988SymbolIdentity";
  attribute :>> artifact="vendor/gambit/lib/_mem/symbols.inc";
  attribute :>> anchor="symkey_intern";
  attribute :>> role="request-service-design";
  attribute :>> observed="Current source anchor reviewed independently of PR988 patch ancestry.";
  attribute :>> required="Shared identity publication under writer admission and root freeze; lock name alone is not ownership.";
  attribute :>> gap="Current-producer native failure and cost acceptance remains open; reuse existing models and tests in pr988-refactoring-validation.org.";
  ref part :>> question=cutSource;
 }
 part pr988ProcessWait:SourceSite {
  attribute :>> id="pr988ProcessWait";
  attribute :>> artifact="vendor/gambit/lib/os_io.c";
  attribute :>> anchor="execvp_errno";
  attribute :>> role="request-service-design";
  attribute :>> observed="Current source anchor reviewed independently of PR988 patch ancestry.";
  attribute :>> required="Checked nonblocking setup, GC participation and fd/child cleanup; historical PR ignores fcntl failures.";
  attribute :>> gap="Current-producer native failure and cost acceptance remains open; reuse existing models and tests in pr988-refactoring-validation.org.";
  ref part :>> question=cutSource;
 }
 part pr988StartupReadiness:SourceSite {
  attribute :>> id="pr988StartupReadiness";
  attribute :>> artifact="vendor/gambit/lib/_thread.scm";
  attribute :>> anchor="(define (##startup-parallelism!)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Current source anchor reviewed independently of PR988 patch ancestry.";
  attribute :>> required="Initialized member/root/capacity publication, partial failure and unknown join custody; not a ready boolean.";
  attribute :>> gap="Current-producer native failure and cost acceptance remains open; reuse existing models and tests in pr988-refactoring-validation.org.";
  ref part :>> question=cutSource;
 }
 part pr988WaitCost:SourceSite {
  attribute :>> id="pr988WaitCost";
  attribute :>> artifact="vendor/gambit/gsc/_t-c-2.scm";
  attribute :>> anchor="(targ-jump-inline \"##thread-park!\"";
  attribute :>> role="request-service-design";
  attribute :>> observed="Current source anchor reviewed independently of PR988 patch ancestry.";
  attribute :>> required="Exact wait frames, static retry and general multi-shot fallback; phase repairs do not eliminate per-request capture.";
  attribute :>> gap="Current-producer native failure and cost acceptance remains open; reuse existing models and tests in pr988-refactoring-validation.org.";
  ref part :>> question=cutSource;
 }
 part pr988Validation:AdapterClause {
  attribute :>> id="pr988Validation";
  attribute :>> kind="validation";
  attribute :>> rule="Historical repairs, existing-model counterexamples, archived binary replay and current-producer qualification are distinct evidence classes";
  attribute :>> missing="No PR988 whole Repair9 receipt or current-cohort native failure/cost campaign";
  attribute :>> acceptance="Same-cohort native ownership, failure, GC, exit and original-load cost pass before old duties retire";
  ref part :>> adapter=freezeAdapter; ref part :>> site=pr988WaitCost;
 }
 part pr988Refinement:SourceCase {
  attribute :>> id="pr988Refinement";
  attribute :>> precondition="Pinned diff/report, current source identities and archived executable distinguished; no patch import, runtime change or expanded budget";
  attribute :>> argument="Separate root publication, table movement, identity publication, process wait and startup custody. A synchronization repair does not remove wait capture, service retention, user continuation or whole-collector obligations.";
  attribute :>> conclusion="Selected mechanisms constrain modern-C responsibility replacement; Repair9 completion and net benefit remain conditional";
  attribute :>> missing="Generated static retry lowering, current-cohort failure controls and original 360-million-request cost/peak acceptance";
  attribute :>> acceptance="Joint five-gate campaign preserves shared identity, multiple continuation shots, roots, failures and workload while measuring eliminated and added work";
  attribute :>> formalBoundary="Source case only: existing QNT owns histories; Lean owns slot/alias/interval representation. No duplicated proof or mechanized C claim.";
  attribute :>> counterexample="All phase barriers pass but request replays or user continuation retains service state; table test passes while failed nonblocking setup blocks GC";
  ref part :>> clause=pr988Validation; ref part :>> entrySite=pr988GcPhase; ref part :>> exitSite=pr988WaitCost;
 }
 part pr988Flow:Flow { ref part :>> producer=collector; ref part :>> consumer=control; attribute :>> contract="Repair9: selected historical GC repairs do not replace same-wait/service/exit ownership or original-load net-benefit acceptance"; }
}
