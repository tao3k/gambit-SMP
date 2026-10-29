package GambitVmLifecycle {
  private import ScalarValues::*;
  part def Role {
    attribute id:String; attribute source:String; attribute entryPoint:String;
    attribute authority:String; attribute retirement:String; attribute cost:String;
  }
  part registry:Role {
    attribute :>> id="vm-registry";
    attribute :>> source="vendor/gambit/lib/_setup/vm-registry.inc";
    attribute :>> entryPoint="___lifecycle_registry_begin; ___lifecycle_registry_end; vm_registry_try_write; vm_registry_open; vm_registry_interrupt";
    attribute :>> authority="One stable process-private atomic admission word excludes list writers while signal readers borrow it. An exclusive mutation never waits for an interrupted reader. Pending interrupt bits are coalesced and delivered after publication; only LIVE VM nodes are visited.";
    attribute :>> retirement="Remove vm_list_mut and the unlocked signal traversal; allocator setup/cleanup no longer edits membership.";
    attribute :>> cost="Registry gate, pending bits, shutdown and incarnation words, signal CAS/read bookkeeping and linear dispatch over live nodes. Busy mutation is refused. No separate identity table or SDK/build profile.";
  }
  part owner:Role {
    attribute :>> id="vm-owner-retirement";
    attribute :>> source="vendor/gambit/lib/_setup/vm-lifecycle.inc;vendor/gambit/lib/_mem/still-sweep.inc";
    attribute :>> entryPoint="___setup_vmstate; ___cleanup_vmstate; cleanup_vm_owned; lifecycle_close_context; ___lifecycle_cleanup_pstate";
    attribute :>> authority="The bound owner must close nonterminal activation/root/scan leases, pending requests and cleanup escrow; only an explicitly terminal native stack may be abandoned. Complete setup publishes a LIVE record. Known successful cleanup unlinks it; returned errors and captured throws retain the node, pending object and native payload without replay.";
    attribute :>> retirement="Remove void per-VM refusal and implicit all-VM destruction. PSTATE cleanup executes once; a DRAINED global retry requests only the final registry/unlink permission and never repeats resize, roots or effects. VM memory cleanup no longer repeats it. Explicit still teardown uses the existing owner escrow.";
    attribute :>> cost="One VM-owned private control record with bounded per-context entry/request/cleanup/activation/launch storage. False/unknown receipts retain memory. A failed constructor does not itself authorize the host to free retained control storage.";
  }
  part globalReclaim:Role {
    attribute :>> id="global-reclaim-permit";
    attribute :>> source="vendor/gambit/lib/setup.c;vendor/gambit/lib/_setup/vm-lifecycle.inc";
    attribute :>> entryPoint="___setup; setup_runtime; ___cleanup; cleanup_runtime";
    attribute :>> authority="Only the exclusive registry owner with no secondary node, live reader or constructor can consider global teardown. Known primary resize/owner cleanup must finish before freeing permanent/global resources. Terminal process exit never resumes its Scheme frames. Setup records publication in a caller-local receipt, not a later shared phase.";
    attribute :>> retirement="Remove ignored per-VM cleanup results and global teardown after a refused VM. Move global interrupt shutdown after admission, not before the checks.";
    attribute :>> cost="Explicit owners must retire secondary VMs. An unacknowledged/retained VM denies global reclamation; this is safety rather than forced shutdown or arbitrary owner-death recovery.";
  }
  part def Transfer { ref part producer:Role; ref part consumer:Role; attribute condition:String; }
  part rootPublication:Transfer { ref part :>> producer=owner; ref part :>> consumer=registry; attribute :>> condition="Only a completely initialized LIVE VM is published under the exclusive writer. A subsequently retained teardown remains registered; in-progress setup is invisible to signal readers."; }
  part retirementAck:Transfer { ref part :>> producer=owner; ref part :>> consumer=globalReclaim; attribute :>> condition="Known completed teardown unlinks the VM; a false/unknown result cannot become an acknowledgement. Global cleanup refuses while any secondary remains."; }
  part registryClosure:Transfer { ref part :>> producer=registry; ref part :>> consumer=globalReclaim; attribute :>> condition="Writer admission with no readers excludes future publication until global free completes; an unlocked preflight is insufficient."; }
  attribute graph:String="live -> entry_close -> root_drain -> owner_effect -> data_drained -> global_writer -> reclaimed; owner_effect -> topology_pin; topology_pin -> writer_refused -> drained_retained; drained_retained -> release_pin -> retry_writer -> reclaimed; drained_retained -> forbid_resize_replay; effect_unknown -> retained_resource -> deny_global_free; secondary_unacked -> deny_global_free; unknown_launch -> isolated_control -> healthy_vm_gc;";
  attribute qntModel:String="dev/refactoring/modern-c/models/quint/vm_registry.qnt";
  attribute qntDuty:String="Finite two-VM/two-reader admission, signal, retirement and DRAINED-retry schedules. Current five positive/negative runs include repeated-data-preparation rejection. No liveness, arbitrary stop, weak-memory or pointer-ABA theorem.";
  attribute leanDuty:String="No new Lean proof for this finite protocol. Root/round conditional algebra remains under RuntimeRoles; it is not duplicated or claimed to prove the new C adapter.";
  attribute sourceDuty:String="Default LLM source review maps actual callers, constructor stages, owner/TLS and signal backend premises. Native tests must exercise real initialized VM records, successful global teardown and failure escrow. LLM context is ambient, not another proof producer.";
  attribute platformPremise:String="Native full-word atomic backend is required for asynchronous signal qualification. Emulated-CAS and unqualified target ABIs need separate adapters. Raw cross-thread PSTATE aliases, arbitrary stale pointers and cross-VM movable Scheme objects are not granted ownership by this protocol.";
  attribute evidence:String="dev/refactoring/modern-c/delivery-contract.org#OWNED-LIFETIME-DELIVERY";
  attribute status:String="Current exact-source/native admission is owned by GambitOwnedLifetime and its public receipt; no intermediate prototype, model-only run or historical timing qualifies this component.";
}
