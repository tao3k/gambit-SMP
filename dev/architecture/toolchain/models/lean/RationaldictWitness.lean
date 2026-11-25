import HostFrameBridge

-- Selected retained C metadata, not an SCM->C or native ABI admission.
-- Rows mechanically transcribed from rationaldict-native-witness.json.
namespace Gambit.RationaldictWitness
open HostResourceSemantics HostFrameBridge
structure Row where
 label : Nat
 procedure : Nat
 localLabel : Nat
 frame : FrameSpec
 outline : Bool
 roots : List Nat

def rows : List Row := [
 ⟨2, 0, 1, ⟨2, 7, 17, 0, 16241⟩, false, [5, 6, 7, 9, 10, 11, 12, 13, 14]⟩,
 ⟨3, 0, 2, ⟨2, 7, 17, 0, 16241⟩, false, [5, 6, 7, 9, 10, 11, 12, 13, 14]⟩,
 ⟨4, 0, 3, ⟨1, 1, 1, 0, 1⟩, false, []⟩,
 ⟨5, 0, 4, ⟨1, 1, 1, 0, 1⟩, false, []⟩,
 ⟨6, 0, 5, ⟨1, 1, 1, 0, 1⟩, false, []⟩,
 ⟨7, 0, 6, ⟨1, 1, 1, 0, 1⟩, false, []⟩,
 ⟨8, 0, 7, ⟨1, 1, 1, 0, 1⟩, false, []⟩,
 ⟨9, 0, 8, ⟨1, 1, 1, 0, 1⟩, false, []⟩,
 ⟨10, 0, 9, ⟨2, 8, 17, 0, 16131⟩, false, [2, 9, 10, 11, 12, 13, 14]⟩,
 ⟨11, 0, 10, ⟨1, 5, 5, 0, 3⟩, false, [2]⟩,
 ⟨12, 0, 11, ⟨2, 4, 13, 0, 1009⟩, false, [5, 6, 7, 8, 9, 10]⟩,
 ⟨13, 0, 12, ⟨1, 1, 1, 0, 1⟩, false, []⟩,
 ⟨16, 1, 1, ⟨2, 0, 9, 0, 63⟩, false, [2, 3, 4, 5, 6]⟩,
 ⟨19, 2, 1, ⟨1, 1, 1, 0, 1⟩, false, []⟩,
 ⟨20, 2, 2, ⟨2, 4, 13, 4, 1008⟩, false, [6, 7, 8, 9, 10]⟩,
 ⟨21, 2, 3, ⟨2, 8, 17, 0, 16369⟩, false, [5, 6, 7, 8, 9, 10, 11, 12, 13, 14]⟩,
 ⟨22, 2, 4, ⟨1, 1, 1, 0, 1⟩, false, []⟩,
 ⟨25, 3, 1, ⟨1, 5, 5, 0, 7⟩, false, [2, 3]⟩,
 ⟨26, 3, 2, ⟨2, 8, 17, 0, 16133⟩, false, [3, 9, 10, 11, 12, 13, 14]⟩,
 ⟨27, 3, 3, ⟨1, 5, 5, 0, 5⟩, false, [3]⟩,
 ⟨28, 3, 4, ⟨1, 5, 5, 0, 5⟩, false, [3]⟩,
 ⟨29, 3, 5, ⟨2, 8, 17, 8, 16132⟩, false, [3, 10, 11, 12, 13, 14]⟩,
 ⟨30, 3, 6, ⟨2, 12, 21, 0, 261893⟩, true, [3, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18]⟩,
 ⟨33, 4, 1, ⟨2, 1, 13, 4, 1008⟩, false, [6, 7, 8, 9, 10]⟩,
 ⟨34, 4, 2, ⟨2, 1, 13, 4, 1008⟩, false, [6, 7, 8, 9, 10]⟩,
 ⟨36, 4, 4, ⟨2, 0, 9, 0, 63⟩, false, [2, 3, 4, 5, 6]⟩,
 ⟨39, 5, 1, ⟨1, 5, 5, 0, 3⟩, false, [2]⟩,
 ⟨40, 5, 2, ⟨2, 8, 17, 8, 16128⟩, false, [10, 11, 12, 13, 14]⟩,
 ⟨41, 5, 3, ⟨2, 8, 17, 8, 16128⟩, false, [10, 11, 12, 13, 14]⟩,
 ⟨42, 5, 4, ⟨2, 8, 17, 8, 16128⟩, false, [10, 11, 12, 13, 14]⟩,
 ⟨45, 6, 1, ⟨1, 5, 5, 0, 7⟩, false, [2, 3]⟩,
 ⟨46, 6, 2, ⟨2, 8, 17, 0, 16129⟩, false, [9, 10, 11, 12, 13, 14]⟩,
 ⟨47, 6, 3, ⟨1, 1, 1, 0, 1⟩, false, []⟩,
 ⟨48, 6, 4, ⟨1, 1, 1, 0, 1⟩, false, []⟩,
 ⟨49, 6, 5, ⟨2, 1, 13, 0, 1009⟩, false, [5, 6, 7, 8, 9, 10]⟩,
 ⟨50, 6, 6, ⟨2, 8, 17, 0, 16369⟩, false, [5, 6, 7, 8, 9, 10, 11, 12, 13, 14]⟩,
 ⟨53, 7, 1, ⟨1, 5, 5, 0, 3⟩, false, [2]⟩,
 ⟨54, 7, 2, ⟨2, 8, 17, 0, 16129⟩, false, [9, 10, 11, 12, 13, 14]⟩,
 ⟨55, 7, 3, ⟨1, 1, 1, 0, 1⟩, false, []⟩,
 ⟨56, 7, 4, ⟨1, 1, 1, 0, 1⟩, false, []⟩,
 ⟨57, 7, 5, ⟨2, 1, 13, 0, 1009⟩, false, [5, 6, 7, 8, 9, 10]⟩,
 ⟨58, 7, 6, ⟨2, 8, 17, 0, 16369⟩, false, [5, 6, 7, 8, 9, 10, 11, 12, 13, 14]⟩,
 ⟨61, 8, 1, ⟨1, 5, 5, 0, 3⟩, false, [2]⟩,
 ⟨62, 8, 2, ⟨2, 8, 17, 0, 16129⟩, false, [9, 10, 11, 12, 13, 14]⟩,
 ⟨63, 8, 3, ⟨1, 1, 1, 0, 1⟩, false, []⟩,
 ⟨64, 8, 4, ⟨1, 1, 1, 0, 1⟩, false, []⟩,
 ⟨65, 8, 5, ⟨2, 8, 17, 0, 16369⟩, false, [5, 6, 7, 8, 9, 10, 11, 12, 13, 14]⟩,
 ⟨68, 9, 1, ⟨2, 9, 21, 0, 258311⟩, true, [2, 3, 9, 13, 14, 15, 16, 17, 18]⟩,
 ⟨69, 9, 2, ⟨1, 5, 5, 0, 7⟩, false, [2, 3]⟩,
 ⟨70, 9, 3, ⟨2, 8, 17, 0, 16135⟩, false, [2, 3, 9, 10, 11, 12, 13, 14]⟩,
 ⟨71, 9, 4, ⟨1, 5, 5, 0, 7⟩, false, [2, 3]⟩,
 ⟨72, 9, 5, ⟨1, 5, 5, 0, 7⟩, false, [2, 3]⟩,
 ⟨73, 9, 6, ⟨1, 5, 5, 0, 7⟩, false, [2, 3]⟩,
 ⟨74, 9, 7, ⟨2, 8, 17, 0, 16135⟩, false, [2, 3, 9, 10, 11, 12, 13, 14]⟩,
 ⟨75, 9, 8, ⟨2, 0, 9, 0, 63⟩, false, [2, 3, 4, 5, 6]⟩,
 ⟨76, 9, 9, ⟨2, 8, 17, 0, 16135⟩, false, [2, 3, 9, 10, 11, 12, 13, 14]⟩,
 ⟨77, 9, 10, ⟨1, 5, 5, 0, 3⟩, false, [2]⟩,
 ⟨78, 9, 11, ⟨2, 12, 21, 0, 261895⟩, true, [2, 3, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18]⟩,
 ⟨79, 9, 12, ⟨1, 5, 5, 0, 7⟩, false, [2, 3]⟩,
 ⟨82, 10, 1, ⟨2, 9, 21, 0, 258311⟩, true, [2, 3, 9, 13, 14, 15, 16, 17, 18]⟩,
 ⟨83, 10, 2, ⟨1, 5, 5, 0, 7⟩, false, [2, 3]⟩,
 ⟨84, 10, 3, ⟨2, 8, 17, 0, 16135⟩, false, [2, 3, 9, 10, 11, 12, 13, 14]⟩,
 ⟨85, 10, 4, ⟨1, 5, 5, 0, 7⟩, false, [2, 3]⟩,
 ⟨86, 10, 5, ⟨1, 5, 5, 0, 7⟩, false, [2, 3]⟩,
 ⟨87, 10, 6, ⟨1, 5, 5, 0, 7⟩, false, [2, 3]⟩,
 ⟨88, 10, 7, ⟨2, 8, 17, 0, 16135⟩, false, [2, 3, 9, 10, 11, 12, 13, 14]⟩,
 ⟨89, 10, 8, ⟨2, 0, 9, 0, 63⟩, false, [2, 3, 4, 5, 6]⟩,
 ⟨90, 10, 9, ⟨2, 8, 17, 0, 16135⟩, false, [2, 3, 9, 10, 11, 12, 13, 14]⟩,
 ⟨91, 10, 10, ⟨1, 5, 5, 0, 3⟩, false, [2]⟩,
 ⟨92, 10, 11, ⟨2, 12, 21, 0, 261895⟩, true, [2, 3, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18]⟩,
 ⟨93, 10, 12, ⟨1, 5, 5, 0, 7⟩, false, [2, 3]⟩,
 ⟨96, 11, 1, ⟨1, 5, 5, 0, 3⟩, false, [2]⟩,
 ⟨97, 11, 2, ⟨2, 8, 17, 0, 16129⟩, false, [9, 10, 11, 12, 13, 14]⟩,
 ⟨98, 11, 3, ⟨1, 1, 1, 0, 1⟩, false, []⟩,
 ⟨99, 11, 4, ⟨1, 1, 1, 0, 1⟩, false, []⟩,
 ⟨100, 11, 5, ⟨2, 1, 13, 0, 1009⟩, false, [5, 6, 7, 8, 9, 10]⟩,
 ⟨101, 11, 6, ⟨2, 8, 17, 0, 16369⟩, false, [5, 6, 7, 8, 9, 10, 11, 12, 13, 14]⟩,
 ⟨104, 12, 1, ⟨1, 1, 1, 0, 1⟩, false, []⟩,
 ⟨105, 12, 2, ⟨2, 4, 13, 4, 1008⟩, false, [6, 7, 8, 9, 10]⟩,
 ⟨106, 12, 3, ⟨2, 8, 17, 0, 16369⟩, false, [5, 6, 7, 8, 9, 10, 11, 12, 13, 14]⟩,
 ⟨107, 12, 4, ⟨1, 1, 1, 0, 1⟩, false, []⟩,
 ⟨110, 13, 1, ⟨1, 5, 5, 0, 7⟩, false, [2, 3]⟩,
 ⟨111, 13, 2, ⟨2, 8, 17, 8, 16128⟩, false, [10, 11, 12, 13, 14]⟩,
 ⟨112, 13, 3, ⟨2, 8, 17, 0, 16369⟩, false, [5, 6, 7, 8, 9, 10, 11, 12, 13, 14]⟩,
 ⟨113, 13, 4, ⟨2, 8, 17, 0, 16369⟩, false, [5, 6, 7, 8, 9, 10, 11, 12, 13, 14]⟩,
 ⟨114, 13, 5, ⟨1, 1, 1, 0, 1⟩, false, []⟩,
 ⟨117, 14, 1, ⟨1, 5, 5, 0, 7⟩, false, [2, 3]⟩,
 ⟨118, 14, 2, ⟨2, 8, 17, 8, 16128⟩, false, [10, 11, 12, 13, 14]⟩,
 ⟨119, 14, 3, ⟨2, 8, 17, 0, 16369⟩, false, [5, 6, 7, 8, 9, 10, 11, 12, 13, 14]⟩,
 ⟨120, 14, 4, ⟨2, 8, 17, 0, 16369⟩, false, [5, 6, 7, 8, 9, 10, 11, 12, 13, 14]⟩,
 ⟨121, 14, 5, ⟨1, 1, 1, 0, 1⟩, false, []⟩,
 ⟨124, 15, 1, ⟨1, 5, 5, 0, 7⟩, false, [2, 3]⟩,
 ⟨125, 15, 2, ⟨2, 8, 17, 0, 16135⟩, false, [2, 3, 9, 10, 11, 12, 13, 14]⟩,
 ⟨126, 15, 3, ⟨1, 5, 5, 0, 7⟩, false, [2, 3]⟩,
 ⟨127, 15, 4, ⟨1, 5, 5, 0, 13⟩, false, [3, 4]⟩,
 ⟨128, 15, 5, ⟨1, 5, 5, 0, 13⟩, false, [3, 4]⟩,
 ⟨129, 15, 6, ⟨2, 0, 9, 0, 63⟩, false, [2, 3, 4, 5, 6]⟩,
 ⟨130, 15, 7, ⟨1, 5, 5, 1, 30⟩, false, [3, 4, 5]⟩,
 ⟨131, 15, 8, ⟨2, 0, 9, 0, 63⟩, false, [2, 3, 4, 5, 6]⟩,
 ⟨132, 15, 9, ⟨2, 8, 17, 1, 16159⟩, false, [1, 3, 4, 5, 9, 10, 11, 12, 13, 14]⟩,
 ⟨133, 15, 10, ⟨1, 5, 5, 1, 30⟩, false, [3, 4, 5]⟩,
 ⟨134, 15, 11, ⟨1, 5, 5, 1, 31⟩, false, [1, 3, 4, 5]⟩,
 ⟨135, 15, 12, ⟨1, 5, 5, 1, 31⟩, false, [1, 3, 4, 5]⟩,
 ⟨136, 15, 13, ⟨1, 9, 9, 1, 63⟩, false, [1, 3, 4, 5, 6]⟩,
 ⟨137, 15, 14, ⟨1, 9, 9, 1, 62⟩, false, [3, 4, 5, 6]⟩,
 ⟨138, 15, 15, ⟨1, 9, 9, 1, 127⟩, false, [1, 3, 4, 5, 6, 7]⟩,
 ⟨139, 15, 16, ⟨1, 9, 9, 1, 63⟩, false, [1, 3, 4, 5, 6]⟩,
 ⟨142, 16, 1, ⟨2, 0, 9, 0, 63⟩, false, [2, 3, 4, 5, 6]⟩,
 ⟨145, 17, 1, ⟨1, 5, 5, 0, 3⟩, false, [2]⟩,
 ⟨146, 17, 2, ⟨2, 8, 17, 8, 16128⟩, false, [10, 11, 12, 13, 14]⟩,
 ⟨147, 17, 3, ⟨2, 8, 17, 8, 16128⟩, false, [10, 11, 12, 13, 14]⟩,
 ⟨148, 17, 4, ⟨2, 8, 17, 8, 16128⟩, false, [10, 11, 12, 13, 14]⟩,
 ⟨151, 18, 1, ⟨2, 1, 13, 4, 1008⟩, false, [6, 7, 8, 9, 10]⟩,
 ⟨152, 18, 2, ⟨2, 1, 13, 4, 1008⟩, false, [6, 7, 8, 9, 10]⟩,
 ⟨154, 18, 4, ⟨2, 9, 21, 1, 258311⟩, true, [1, 3, 9, 13, 14, 15, 16, 17, 18]⟩,
 ⟨155, 18, 5, ⟨1, 5, 5, 1, 7⟩, false, [1, 3]⟩,
 ⟨156, 18, 6, ⟨2, 8, 17, 1, 16134⟩, false, [3, 9, 10, 11, 12, 13, 14]⟩,
 ⟨157, 18, 7, ⟨1, 5, 5, 1, 6⟩, false, [3]⟩,
 ⟨158, 18, 8, ⟨2, 12, 21, 1, 261894⟩, true, [3, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18]⟩,
 ⟨160, 18, 10, ⟨2, 0, 9, 0, 63⟩, false, [2, 3, 4, 5, 6]⟩,
 ⟨163, 19, 1, ⟨2, 0, 9, 0, 63⟩, false, [2, 3, 4, 5, 6]⟩,
 ⟨166, 20, 1, ⟨1, 5, 5, 0, 3⟩, false, [2]⟩,
 ⟨167, 20, 2, ⟨2, 8, 17, 8, 16128⟩, false, [10, 11, 12, 13, 14]⟩,
 ⟨168, 20, 3, ⟨2, 8, 17, 8, 16128⟩, false, [10, 11, 12, 13, 14]⟩,
 ⟨169, 20, 4, ⟨2, 8, 17, 8, 16128⟩, false, [10, 11, 12, 13, 14]⟩,
 ⟨172, 21, 1, ⟨2, 1, 13, 4, 1008⟩, false, [6, 7, 8, 9, 10]⟩,
 ⟨173, 21, 2, ⟨2, 1, 13, 4, 1008⟩, false, [6, 7, 8, 9, 10]⟩,
 ⟨175, 21, 4, ⟨2, 9, 21, 1, 258311⟩, true, [1, 3, 9, 13, 14, 15, 16, 17, 18]⟩,
 ⟨176, 21, 5, ⟨1, 5, 5, 1, 7⟩, false, [1, 3]⟩,
 ⟨177, 21, 6, ⟨2, 8, 17, 1, 16134⟩, false, [3, 9, 10, 11, 12, 13, 14]⟩,
 ⟨178, 21, 7, ⟨1, 5, 5, 1, 6⟩, false, [3]⟩,
 ⟨179, 21, 8, ⟨2, 12, 21, 1, 261894⟩, true, [3, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18]⟩,
 ⟨181, 21, 10, ⟨2, 0, 9, 0, 63⟩, false, [2, 3, 4, 5, 6]⟩,
 ⟨184, 22, 1, ⟨2, 0, 9, 0, 63⟩, false, [2, 3, 4, 5, 6]⟩,
 ⟨187, 23, 1, ⟨1, 5, 5, 0, 3⟩, false, [2]⟩,
 ⟨188, 23, 2, ⟨2, 8, 17, 8, 16128⟩, false, [10, 11, 12, 13, 14]⟩,
 ⟨189, 23, 3, ⟨2, 8, 17, 8, 16128⟩, false, [10, 11, 12, 13, 14]⟩,
 ⟨190, 23, 4, ⟨2, 8, 17, 8, 16128⟩, false, [10, 11, 12, 13, 14]⟩]

def rowCorrect (r : Row) : Prop := Valid r.frame ∧
 ordinarySlots r.frame=r.roots ∧
 r.frame.actualFs=(if r.frame.kind=2 then ((r.frame.storedFs+3)/4)*4+9 else r.frame.storedFs) ∧
 (r.outline=true ↔ r.frame.actualFs>20)

instance (r : Row) : Decidable (rowCorrect r) := by
 unfold rowCorrect Valid
 infer_instance

theorem allRowsCorrect : rows.all (fun r => decide (rowCorrect r))=true := by decide +kernel
 theorem descriptorCount : rows.length=138 := by decide +kernel
 theorem outlineCount : (rows.filter (·.outline)).length=9 := by decide +kernel
 theorem rootOccurrences : (rows.map (fun r => r.roots.length)).foldl (·+·) 0=612 := by decide +kernel
 theorem labelsUnique : (rows.map (·.label)).Nodup := by decide +kernel

-- Resource indices: HEAP0 FP1 R0=2 R1=3 R2=4 R3=5 R4=6.
def moduleResources : List Nat := [0,1,2,3,4,5,6]
def minKeyReads : List Nat := [1,4]
def minKeyWrites : List Nat := [4]
def keep : Keep := fun r => decide (r ∈ minKeyReads)
theorem writeCovered : keep 4=true := by decide +kernel
 theorem fpReadOnly : 1 ∈ minKeyReads ∧ 1 ∉ minKeyWrites := by decide +kernel
 theorem moduleNotProcedure : moduleResources≠minKeyReads := by decide +kernel

def selected : FrameSpec := ⟨2,0,9,0,63⟩
theorem actualRow163 : ∃ r ∈ rows, r.label=163 ∧ r.procedure=19 ∧ r.localLabel=1 ∧
 r.frame.kind=2 ∧ r.frame.storedFs=0 ∧ r.frame.actualFs=9 ∧ r.frame.link=0 ∧ r.frame.bitmap=63 := by decide +kernel
 theorem selectedRoots : ordinarySlots selected=[2,3,4,5,6] := by decide +kernel

-- Frame cells are a separate namespace; no slot->register identity assumption.
def place (base slot : Nat) : Nat := base+7+slot
 theorem placeInjective (base : Nat) : Function.Injective (place base) := by
  intro a b h
  exact Nat.add_left_cancel h
 theorem rootsSeparateFromRegisters (base slot : Nat) : 7≤place base slot := by
  simp [place]; omega
 theorem selectedRootUpdate (base : Nat) (h : Host) (move : Nat → Nat)
 (slot : Nat) (member : slot ∈ [2,3,4,5,6]) :
 (observe keep (pollFrame keep selected (place base) move h)).regs (place base slot)=
 move ((observe keep h).regs (place base slot)) := by
  apply ordinaryRootUpdated
  simpa [selectedRoots] using member
 theorem selectedLinkExcluded (base : Nat) : place base 1 ∉ rootCells selected (place base) := by
  exact linkCellExcluded selected (place base) (placeInjective base)

-- SET_R2(FAL) -> POLL(1) is an actual source slice; FAL's tagged encoding is
-- an arbitrary value parameter. Transfer/arity guard remain explicit boundaries.
def assign (m : Machine) (v : Nat) : Machine := {m with regs:=set m.regs 4 v}
def assignLocal (h : Host) (v : Nat) : Host := {h with localRegs:=set h.localRegs 4 v}
 theorem assignmentSimulation (h : Host) (v : Nat) :
 observe keep (assignLocal h v)=assign (observe keep h) v := by
  have eq : overlay keep h.base.regs (set h.localRegs 4 v)=set (overlay keep h.base.regs h.localRegs) 4 v := by
   funext i
   by_cases same : i=4
   · subst i; simp [overlay,HostResourceSemantics.set,writeCovered]
   · simp [overlay,HostResourceSemantics.set,same]
  change {h.base with regs:=overlay keep h.base.regs (set h.localRegs 4 v)}=_
  rw [eq]; rfl
 theorem sourceSliceSimulation (base : Nat) (h : Host) (move : Nat → Nat) (v : Nat) :
 observe keep (pollFrame keep selected (place base) move (assignLocal h v))=
 poll (rootCells selected (place base)) move (assign (observe keep h) v) := by
  rw [framePollSimulation,assignmentSimulation]
 theorem capturedRoots (base : Nat) (move : Nat → Nat) (m : Machine) :
 capture (poll (rootCells selected (place base)) move m)=
 moveSnapshot (rootCells selected (place base)) move (capture m) := rfl
 theorem multiShot (h : Host) (k : Snapshot) (between : Machine → Machine) :
 observe keep (boundaryStep keep (resume k) (boundaryStep keep between (boundaryStep keep (resume k) h)))=
 resume k (between (resume k (observe keep h))) := multiShotResumeSimulation keep h k between
 theorem mixedGenerationRejected : (1792170496 : Nat)≠1789984941 := by decide +kernel
end Gambit.RationaldictWitness
