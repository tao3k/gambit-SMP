package GambitStressGsiStackInterval {
  private import ScalarValues::*;

  part grantExtent {
    attribute family : Integer = 6;
    attribute cut : String = "grant-extent";
    attribute source : String = "vendor/gambit/lib/_mem/allocation-limits.inc";
    attribute anchor : String = "static int cursor_has_stack_room";
    attribute leanArtifact : String = "dev/refactoring/modern-c/models/lean/StackIntervalAuthority.lean";
    attribute leanCheck : String = "stackFloorFallbackDoesNotAuthorizeSpill";
    attribute quintArtifact : String = "dev/refactoring/modern-c/models/quint/stack_interval_authority.qnt";
    attribute quintCheck : String = "invalidIntervalAsShortageControlTest";
    attribute sourceRefinement : String = "BC-CENTRY-REFINE";
    attribute refinementScope : String = "owned-stack-interval-before-spill";
    attribute nativeGate : String = "BC-A";
    attribute nativeScope : String = "same-sealed-GSI-stack-interval";
    attribute requiredBehavior : String = "Resolve the owned stack interval independently of fp. A short owned interval may enter the existing backed service. An invalid interval must refuse before spill, collection or application writes.";
    attribute nativeOracle : String = "On one sealed GSI observe exact fit and one-short on the owned interval. Refuse an in-range inactive half and a cursor above the owned end without spill, collection or sentinel mutation. Repeat after actual refill and bind each result to the generated entry.";
  }
}
