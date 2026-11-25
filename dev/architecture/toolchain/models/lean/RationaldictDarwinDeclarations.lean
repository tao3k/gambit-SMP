import RationaldictAbiCut

-- Exact classified source inventory, not verified CPP or native declarations.
namespace Gambit.RationaldictDarwinDeclarations
open RationaldictAbiCut
structure Terminal where
 name : String
 category : Nat
 origins : Nat
 deriving DecidableEq

def terminals : List Terminal := [
 ⟨"___F64V1", 7, 3⟩,
 ⟨"___F64V2", 7, 3⟩,
 ⟨"___F64_FROM_U64_fn", 11, 2⟩,
 ⟨"___G__23__23_call_2d_with_2d_current_2d_continuation", 0, 1⟩,
 ⟨"___G__23__23_dead_2d_end", 0, 1⟩,
 ⟨"___G__23__23_gensym", 0, 1⟩,
 ⟨"___G__23__23_length", 0, 1⟩,
 ⟨"___G__23__23_list_3f_", 0, 1⟩,
 ⟨"___G__23__23_raise_2d_wrong_2d_number_2d_of_2d_arguments_2d_exception", 0, 1⟩,
 ⟨"___G__23__23_structure_2d_ref", 0, 1⟩,
 ⟨"___G__2d_", 0, 1⟩,
 ⟨"___G__3d_", 0, 1⟩,
 ⟨"___G_____make_2d_class_2d_predicate", 0, 1⟩,
 ⟨"___G_____make_2d_class_2d_slot_2d_accessor", 0, 1⟩,
 ⟨"___G_____make_2d_class_2d_slot_2d_mutator", 0, 1⟩,
 ⟨"___G_____make_2d_class_2d_slot_2d_unchecked_2d_accessor", 0, 1⟩,
 ⟨"___G_____make_2d_class_2d_slot_2d_unchecked_2d_mutator", 0, 1⟩,
 ⟨"___G_apply", 0, 1⟩,
 ⟨"___G_car", 0, 1⟩,
 ⟨"___G_cdr", 0, 1⟩,
 ⟨"___G_equal_3f_", 0, 1⟩,
 ⟨"___G_error", 0, 1⟩,
 ⟨"___G_make_2d_class_2d_type", 0, 1⟩,
 ⟨"___G_make_2d_instance", 0, 1⟩,
 ⟨"___G_raise_2d_contract_2d_violation_2d_error", 0, 1⟩,
 ⟨"___G_std_2f_iter_2f_iterators_23_iter", 0, 1⟩,
 ⟨"___G_std_2f_struct_2f_rbtree_23_RBTree_3a__3a__3a_init_21_____0", 0, 1⟩,
 ⟨"___G_std_2f_struct_2f_rbtree_23_RBTree_3a__3a_t", 0, 1⟩,
 ⟨"___G_std_2f_struct_2f_rbtree_23_____in_2d_rbtree_2d_keys", 0, 1⟩,
 ⟨"___G_std_2f_struct_2f_rbtree_23_____in_2d_rbtree_2d_values", 0, 1⟩,
 ⟨"___G_std_2f_struct_2f_rbtree_23_____list_2d__3e_rbtree", 0, 1⟩,
 ⟨"___G_std_2f_struct_2f_rbtree_23_____rbtree_2d__3e_list", 0, 1⟩,
 ⟨"___G_std_2f_struct_2f_rbtree_23_____rbtree_2d_empty_3f_", 0, 1⟩,
 ⟨"___G_std_2f_struct_2f_rbtree_23_____rbtree_2d_fold", 0, 1⟩,
 ⟨"___G_std_2f_struct_2f_rbtree_23_____rbtree_2d_foldr", 0, 1⟩,
 ⟨"___G_std_2f_struct_2f_rbtree_23_____rbtree_2d_for_2d_each", 0, 1⟩,
 ⟨"___G_std_2f_struct_2f_rbtree_23_____rbtree_2d_for_2d_eachr", 0, 1⟩,
 ⟨"___G_std_2f_struct_2f_rbtree_23_____rbtree_2d_put", 0, 1⟩,
 ⟨"___G_std_2f_struct_2f_rbtree_23_____rbtree_2d_ref_____25_", 0, 1⟩,
 ⟨"___G_std_2f_struct_2f_rbtree_23_____rbtree_2d_remove", 0, 1⟩,
 ⟨"___K_context", 1, 1⟩,
 ⟨"___K_contract", 1, 1⟩,
 ⟨"___K_struct", 1, 1⟩,
 ⟨"___K_transparent", 1, 1⟩,
 ⟨"___K_value", 1, 1⟩,
 ⟨"___L10_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_2d_keys", 3, 1⟩,
 ⟨"___L10_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_2d_max_2d_key_____25_", 3, 1⟩,
 ⟨"___L10_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_2d_min_2d_key_____25_", 3, 1⟩,
 ⟨"___L10_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_2d_values", 3, 1⟩,
 ⟨"___L10_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_3d__3f______25_", 3, 1⟩,
 ⟨"___L10_clan____poo____support____rationaldict_23_", 3, 1⟩,
 ⟨"___L11_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_2d_keys", 3, 1⟩,
 ⟨"___L11_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_2d_max_2d_key_____25_", 3, 1⟩,
 ⟨"___L11_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_2d_min_2d_key_____25_", 3, 1⟩,
 ⟨"___L11_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_2d_values", 3, 1⟩,
 ⟨"___L11_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_3d__3f______25_", 3, 1⟩,
 ⟨"___L11_clan____poo____support____rationaldict_23_", 3, 1⟩,
 ⟨"___L12_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_2d_keys", 3, 1⟩,
 ⟨"___L12_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_2d_values", 3, 1⟩,
 ⟨"___L12_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_3d__3f______25_", 3, 1⟩,
 ⟨"___L12_clan____poo____support____rationaldict_23_", 3, 1⟩,
 ⟨"___L13_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_2d_keys", 3, 1⟩,
 ⟨"___L13_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_2d_values", 3, 1⟩,
 ⟨"___L13_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_3d__3f______25_", 3, 1⟩,
 ⟨"___L14_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_2d_keys", 3, 1⟩,
 ⟨"___L14_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_2d_values", 3, 1⟩,
 ⟨"___L14_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_3d__3f______25_", 3, 1⟩,
 ⟨"___L15_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_2d_keys", 3, 1⟩,
 ⟨"___L15_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_2d_values", 3, 1⟩,
 ⟨"___L15_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_3d__3f______25_", 3, 1⟩,
 ⟨"___L16_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_2d_keys", 3, 1⟩,
 ⟨"___L16_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_2d_values", 3, 1⟩,
 ⟨"___L16_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_3d__3f______25_", 3, 1⟩,
 ⟨"___L17_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_3d__3f______25_", 3, 1⟩,
 ⟨"___L18_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_3d__3f______25_", 3, 1⟩,
 ⟨"___L19_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_3d__3f______25_", 3, 1⟩,
 ⟨"___L20_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_3d__3f______25_", 3, 1⟩,
 ⟨"___L21_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_3d__3f______25_", 3, 1⟩,
 ⟨"___L22_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_3d__3f______25_", 3, 1⟩,
 ⟨"___L23_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_3d__3f______25_", 3, 1⟩,
 ⟨"___L24_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_3d__3f______25_", 3, 1⟩,
 ⟨"___L25_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_3d__3f______25_", 3, 1⟩,
 ⟨"___L26_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_3d__3f______25_", 3, 1⟩,
 ⟨"___L27_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_3d__3f______25_", 3, 1⟩,
 ⟨"___L28_clan_2f_poo_2f_support_2f_rationaldict_23_rationaldict_3d__3f______25_", 3, 1⟩,
 ⟨"___LNK_clan____poo____support____rationaldict", 4, 1⟩,
 ⟨"___S_RBTree_3f_", 2, 1⟩,
 ⟨"___S_absent", 2, 1⟩,
 ⟨"___S_list_3f_", 2, 1⟩,
 ⟨"___S_next_21_", 2, 1⟩,
 ⟨"___S_procedure_3f_", 2, 1⟩,
 ⟨"___S_rationaldict", 2, 1⟩,
 ⟨"___S_std_2f_struct_2f_rbtree_23_RBTree_3a__3a_t", 2, 1⟩,
 ⟨"___S_tree", 2, 1⟩,
 ⟨"___U64_F64", 6, 3⟩,
 ⟨"___X0", 5, 1⟩,
 ⟨"___X1", 5, 1⟩,
 ⟨"___X10", 5, 1⟩,
 ⟨"___X11", 5, 1⟩,
 ⟨"___X12", 5, 1⟩,
 ⟨"___X13", 5, 1⟩,
 ⟨"___X14", 5, 1⟩,
 ⟨"___X15", 5, 1⟩,
 ⟨"___X16", 5, 1⟩,
 ⟨"___X17", 5, 1⟩,
 ⟨"___X18", 5, 1⟩,
 ⟨"___X19", 5, 1⟩,
 ⟨"___X2", 5, 1⟩,
 ⟨"___X3", 5, 1⟩,
 ⟨"___X4", 5, 1⟩,
 ⟨"___X5", 5, 1⟩,
 ⟨"___X6", 5, 1⟩,
 ⟨"___X7", 5, 1⟩,
 ⟨"___X8", 5, 1⟩,
 ⟨"___X9", 5, 1⟩,
 ⟨"___aligned_lowlevel_processor_state_struct", 6, 3⟩,
 ⟨"___c_stack_ptr", 7, 2⟩,
 ⟨"___c_stack_ptr_temp", 7, 3⟩,
 ⟨"___cnstbl", 8, 4⟩,
 ⟨"___fp", 7, 8⟩,
 ⟨"___get_tls_ptr", 11, 2⟩,
 ⟨"___glo_names", 8, 4⟩,
 ⟨"___glo_struct", 6, 5⟩,
 ⟨"___global_state", 6, 3⟩,
 ⟨"___global_state_struct", 6, 4⟩,
 ⟨"___glotbl", 8, 5⟩,
 ⟨"___gs", 7, 4⟩,
 ⟨"___gstate0", 12, 3⟩,
 ⟨"___hlbltbl", 8, 4⟩,
 ⟨"___host", 6, 3⟩,
 ⟨"___hp", 7, 15⟩,
 ⟨"___i", 7, 3⟩,
 ⟨"___init_mod", 9, 3⟩,
 ⟨"___jump", 10, 7⟩,
 ⟨"___jumpext", 10, 9⟩,
 ⟨"___key_names", 8, 4⟩,
 ⟨"___keytbl", 8, 9⟩,
 ⟨"___label_struct", 6, 3⟩,
 ⟨"___lbltbl", 8, 4⟩,
 ⟨"___local_gstate", 8, 5⟩,
 ⟨"___lp", 8, 3⟩,
 ⟨"___mod_or_lnk", 6, 3⟩,
 ⟨"___module_descr", 8, 4⟩,
 ⟨"___module_struct", 6, 3⟩,
 ⟨"___ofdtbl", 8, 3⟩,
 ⟨"___pc", 7, 16⟩,
 ⟨"___processor_state", 6, 8⟩,
 ⟨"___processor_state_struct", 6, 4⟩,
 ⟨"___ps", 7, 42⟩,
 ⟨"___ptr", 7, 6⟩,
 ⟨"___r0", 7, 5⟩,
 ⟨"___r1", 7, 5⟩,
 ⟨"___r10", 7, 2⟩,
 ⟨"___r11", 7, 2⟩,
 ⟨"___r12", 7, 2⟩,
 ⟨"___r13", 7, 2⟩,
 ⟨"___r2", 7, 5⟩,
 ⟨"___r3", 7, 5⟩,
 ⟨"___r4", 7, 5⟩,
 ⟨"___r5", 7, 2⟩,
 ⟨"___r6", 7, 2⟩,
 ⟨"___r7", 7, 2⟩,
 ⟨"___r8", 7, 2⟩,
 ⟨"___r9", 7, 2⟩,
 ⟨"___register_host_entry", 11, 2⟩,
 ⟨"___s", 13, 4⟩,
 ⟨"___s32_temp", 7, 2⟩,
 ⟨"___s64_temp", 7, 2⟩,
 ⟨"___setup_mod", 9, 3⟩,
 ⟨"___source_location", 6, 3⟩,
 ⟨"___start", 7, 9⟩,
 ⟨"___subtbl", 8, 6⟩,
 ⟨"___sym_names", 8, 4⟩,
 ⟨"___symkey_struct", 6, 5⟩,
 ⟨"___symtbl", 8, 9⟩,
 ⟨"___t", 13, 6⟩,
 ⟨"___temp", 7, 7⟩,
 ⟨"___tls_ptr", 12, 2⟩,
 ⟨"___u32_temp", 7, 2⟩,
 ⟨"___u64_temp", 7, 2⟩,
 ⟨"___u64_x", 7, 5⟩,
 ⟨"___unwind_c_stack_to_trampoline", 11, 2⟩,
 ⟨"___virtual_machine_state", 6, 3⟩,
 ⟨"___virtual_machine_state_struct", 6, 4⟩]

theorem terminalCount : terminals.length=184 := by decide +kernel
theorem namesUnique : (terminals.map (·.name)).Nodup := by decide +kernel
theorem classifiedWithOrigins : terminals.all (fun t => t.category<14 && t.origins>0)=true := by decide +kernel
theorem partitionCounts : (List.range 14).map (fun c => (terminals.filter (fun t => t.category==c)).length)=
 [37,5,8,40,1,20,15,32,14,2,2,4,2,2] := by decide +kernel

def paste (stem tag : String) := stem++tag
theorem actualSpellings : [paste "___t" "STRUCTURE",paste "___s" "FLONUM",paste "___t" "PAIR",paste "___t" "PROCEDURE"]=
 ["___tSTRUCTURE","___sFLONUM","___tPAIR","___tPROCEDURE"] := by decide

inductive Mode where | early | late deriving DecidableEq
structure Repr where
 wordBits : Nat
 gvmRegs : Nat
 labelSchema : Nat
 frameSchema : Nat
 singleHost : Bool
 deriving DecidableEq
structure ImageSpec where
 repr : Repr
 supportedBindings : List Mode
structure StateAccess where
 repr : Repr
 binding : Mode

def Compatible (image : ImageSpec) (access : StateAccess) : Prop :=
 image.repr=access.repr ∧ access.binding ∈ image.supportedBindings

instance (image : ImageSpec) (access : StateAccess) : Decidable (Compatible image access) := by
 unfold Compatible
 infer_instance

theorem representationRequired (image : ImageSpec) (access : StateAccess) (ok : Compatible image access) :
 image.repr=access.repr := ok.1
theorem bindingRequired (image : ImageSpec) (access : StateAccess) (ok : Compatible image access) :
 access.binding ∈ image.supportedBindings := ok.2

def candidateRepr : Repr := ⟨64,5,1,1,true⟩
def earlyOnly : ImageSpec := ⟨candidateRepr,[.early]⟩
def lateAccess : StateAccess := ⟨candidateRepr,.late⟩
theorem equalWordsDoNotBindServices : earlyOnly.repr.wordBits=lateAccess.repr.wordBits ∧ ¬ Compatible earlyOnly lateAccess := by decide
theorem commonImageCanSupportBoth : Compatible ⟨candidateRepr,[.early,.late]⟩ ⟨candidateRepr,.early⟩ ∧
 Compatible ⟨candidateRepr,[.early,.late]⟩ lateAccess := by decide

def ActiveReady (cut : Cut) (image : ImageSpec) (access : StateAccess)
 (profileSealed originalInputsBound : Bool) : Prop :=
 Ready cut ∧ Compatible image access ∧ profileSealed=true ∧ originalInputsBound=true
theorem unsealedRefuses (cut : Cut) (image : ImageSpec) (access : StateAccess) (bound : Bool) :
 ¬ ActiveReady cut image access false bound := by simp [ActiveReady]
theorem classifiedIsNotProfile (cut : Cut) (image : ImageSpec) (access : StateAccess) :
 ¬ ActiveReady cut image access true false := by simp [ActiveReady]

inductive Operation where | obj | dyn deriving DecidableEq
-- Effective CPP state determines binding; operation names do not.
def effectiveBinding (_op : Operation) (early late : Bool) : Option Mode :=
 match early, late with
 | true, false => some .early
 | false, true => some .late
 | _, _ => none

theorem objectCanBeLate : effectiveBinding .obj false true=some .late := rfl
theorem operationAloneInsufficient : effectiveBinding .obj true false≠effectiveBinding .obj false true := by decide
theorem conflictingBindingRefuses : effectiveBinding .dyn true true=none := rfl

-- This counts object reuse only; reduced cold frontend work has a different ledger.
def reusedObjects (cold : Bool) (available : Nat) := if cold then 0 else available
theorem coldHasNoPriorObjectCredit (available : Nat) : reusedObjects true available=0 := rfl
theorem incrementalMayReuse (available : Nat) : reusedObjects false available=available := rfl
end Gambit.RationaldictDarwinDeclarations
