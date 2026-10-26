package GambitCompilerBindingResolutionResearch {
  private import ScalarValues::*;
  part study {
    attribute status:String="ISOLATED-RESEARCH-NOT-FIRST-REV";
    attribute owner:String="Scheme compiler frontend; separate from runtime context/participant/worker responsibilities";
    attribute proposal:String="evidence/research/compiler-binding-resolution/proposal.patch";
    attribute evidence:String="evidence/research/compiler-binding-resolution/receipt.json";
    attribute phaseDistinction:String="Scheme reader, lexical/macro resolution and path handling precede generated C. GCC C preprocessing and macro diagnostics are a different phase. Neither sampled frontend activity nor a partial C prefix establishes a C-preprocessor or GC defect.";
    attribute invariant:String="One compiler owner; ordered variable list remains authoritative; shared global binding identity; immutable names; branch-specific macro precedence. A monotone union of macro names may prove absence only, never select another view's macro. Scheme-managed identities survive GC without raw-address revisions.";
    attribute cost:String="Expected hashing may replace repeated scans, but strong tables and growth/rebuild peaks add O(binding and macro-name count) storage. No matched net speedup or lower peak was established. Variable-only bootstrap340.13 seconds and combined proposal283.94 seconds are separate observations, not a controlled causal comparison.";
    attribute disposition:String="Remove all four proposal paths from vendor first-REV source. Retain patch, native successes/failures and a compiler-only seed for independent research. Current SDK research cohort is not a mainline producer credential.";
    attribute formalRole:String="Source refinement and native generation/semantic equivalence are the next research obligations. Do not duplicate existing GC schedule QNT or conditional Lean laws for this sequential resolver.";
    attribute firstRevisionAdmission:Boolean=false;
  }
}
