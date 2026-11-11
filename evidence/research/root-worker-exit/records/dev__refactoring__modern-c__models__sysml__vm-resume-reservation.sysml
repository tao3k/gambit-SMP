package GambitVMResumeReservation {
  private import ScalarValues::*;
  ref part transaction = GambitVMResizeTransaction::grant;
  ref part collector = GambitVMResizeTransaction::census;
  attribute id:String = "vm-resume-reservation";
  attribute source:String = "mem.c prepare_mem_pstate, compute_resume_msections, reserve_vm_resize, resize_heap";
  attribute invariant:String = "Let F=MSECTION_FUDGE, O=normal overflow reserve, W=MSECTION_SIZE. R=ceil((O+4F)/W). Capacity covers assigned+2*new+actual restore endpoints+R. Charge only startup pairs; R remains VM-unassigned. Then global available words are at least 4F and the first stack allowance at least F before its physical limit.";
  attribute retirement:String = "A physical allocation receipt without a nonzero logical resume allowance is insufficient. Remove the zero-headroom grant and policy contraction that recreates it after GC.";
  attribute cost:String = "On the observed 64-bit profile O=204808, F=8194, W=131072, so R=2 sections. These two MiB are derived capacity, not measured RSS or claimed net overhead versus a correct allocator.";
  attribute open:String = "Caller B coverage, arbitrary foreign allocation, bounds on simultaneous allocation, memory ordering, owner death and all C-to-model refinements remain conditional; no commit admission.";
  attribute quint:String = "dev/refactoring/modern-c/models/quint/vm_resize_transaction.qnt";
  attribute lean:String = "dev/refactoring/modern-c/models/lean/VMResizeTransaction.lean";
  attribute native:String = "evidence/research/modern-c-bootstrap/resize-resume-bootstrap.recipe.json";
  attribute runtimeAdmitted:Boolean = false;
}
