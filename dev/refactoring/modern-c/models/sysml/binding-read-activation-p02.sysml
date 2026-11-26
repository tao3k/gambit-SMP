package GambitBindingReadActivationP02 {
  private import ScalarValues::*;
  ref part baseOwner = GambitBindingActivation::context;
  ref part moduleOwner = GambitBindingActivation::module;
  ref part rootOwner = GambitBindingActivation::roots;
  ref part retirementOwner = GambitBindingActivation::retirement;
  attribute baseline:String="1b1aa854";
  attribute profile:String="884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69";
  attribute scope:String="P0-2 binding-read activation refinement: merge duplicate ___global_page lookups inside primitive_value into one single-page acquire lookup, route ___primitive_ref through ps->context->binding_view.vm when open with root_writer_open fallback, and route generated-module ___GLOBALVARPRIMREF through ___binding_vm ? ___binding_primitive(...) : ___EXT(___primitive_ref)(...) under ___ORDERED_WORD_NATIVE while preserving dynamic .o1 ABI and freeze revocation.";
  attribute formalDuty:String="SysML owns P0-2 source anchors and dynamic ABI boundaries. Quint binding_read_activation.qnt owns open/freeze/restore/close lifecycle, fast-path vs fallback equivalence, and stale-view revocation histories. Lean BindingReadActivationRefinement.lean owns single-page acquire-flag-before-cell observational equivalence and fast/slow dispatch soundness. CBMC binding-read/activation-equivalence/harness.c owns C-level pointer/page equivalence and null-view fallback.";
  attribute maxCompilerRssGiB:Integer=8;
  part def SourceCut { attribute id:String; attribute file:String; attribute anchor:String; attribute contract:String; }
  part singlePagePrimitiveValue:SourceCut {
    attribute :>> id="primitive-value-single-page";
    attribute :>> file="vendor/gambit/lib/_mem/global-bindings.inc";
    attribute :>> anchor="___HIDDEN ___SCMOBJ primitive_value";
    attribute :>> contract="Resolve ___global_page(vm, g->val) once, acquire-load page->primitive_flags[slot], then acquire-load page->primitives[slot] when flagged; identical semantics to dual-page lookup with half the directory traversals.";
  }
  part fastPrimitiveRef:SourceCut {
    attribute :>> id="primitive-ref-binding-view";
    attribute :>> file="vendor/gambit/lib/_mem/global-bindings.inc";
    attribute :>> anchor="___SCMOBJ ___primitive_ref";
    attribute :>> contract="When ps != 0 && ps->context != 0 && ps->context->binding_view.vm == ___VMSTATE_FROM_PSTATE(ps), read via primitive_value(view_vm, g) directly without root_writer_open; whenever binding_view.vm == 0 (frozen, parked, raw native, or closing), fall back to root_writer_open(ps).";
  }
  part moduleGlobalVarPrimRef:SourceCut {
    attribute :>> id="globalvarprimref-fast-macro";
    attribute :>> file="vendor/gambit/include/_gambit/declarations_end.h.in";
    attribute :>> anchor="#undef ___GLOBALVARPRIMREF";
    attribute :>> contract="Under defined(___MODULE_NAME) && ___ORDERED_WORD_NATIVE, redefine ___GLOBALVARPRIMREF(gv) to (__binding_vm ? ___binding_primitive(___binding_vm, ___GLOBALVARSTRUCT(gv)) : ___EXT(___primitive_ref)(___ps, ___GLOBALVARSTRUCT(gv))), keeping ___EXT(___primitive_ref) in ___global_state_struct for -D___DYNAMIC bundles.";
  }
  part stage10UnconditionalAbi:SourceCut {
    attribute :>> id="stage10-unconditional-gstate-abi";
    attribute :>> file="vendor/gambit/include/_gambit/global_state.h.in";
    attribute :>> anchor="___rest_observation_";
    attribute :>> contract="Keep runtime ___EXT dispatch slots and observation hooks layout-stable across dynamic .o1 bundles compiled with or without observation macros, preserving zero undefined symbols under Darwin -bundle -D___DYNAMIC.";
  }
}
