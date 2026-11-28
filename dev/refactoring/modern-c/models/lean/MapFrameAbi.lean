import Std
namespace MapFrameAbi
-- Lean QState mirrors the selected QNT protocol; the QNT-language semantic bridge is open.
structure QState where
 cb : Int
 rc : Int
 fs : Int
 link : Int
 captured : Bool
 root : Bool
 pin : Bool
 running : Bool
 epoch : Int
 loaded : Int
 shots : Int
 frameAbi : Int
 runtimeAbi : Int
 abi : Int
 emitAbi : Int
 objAbi : Int
 emitted : Bool
 native : Bool
 tool : Int
 objTool : Int
 deriving DecidableEq
structure Shape where
 cb : Int
 rc : Int
 fs : Int
 link : Int
 deriving DecidableEq
structure Runtime where
 captured : Bool
 root : Bool
 pin : Bool
 running : Bool
 epoch : Int
 loaded : Int
 shots : Int
 frameAbi : Int
 runtimeAbi : Int
 deriving DecidableEq
structure Artifacts where
 abi : Int
 emitAbi : Int
 objAbi : Int
 emitted : Bool
 native : Bool
 tool : Int
 objTool : Int
 deriving DecidableEq
structure LState where
 shape : Shape
 run : Runtime
 build : Artifacts
 deriving DecidableEq
def alpha (q : QState) : LState :=
 ⟨⟨q.cb,q.rc,q.fs,q.link⟩,⟨q.captured,q.root,q.pin,q.running,q.epoch,q.loaded,q.shots,q.frameAbi,q.runtimeAbi⟩,⟨q.abi,q.emitAbi,q.objAbi,q.emitted,q.native,q.tool,q.objTool⟩⟩
def initial : QState := ⟨7,9,5,0,false,false,false,false,0,0,0,1,1,1,1,1,true,true,1,1⟩
def relates (q : QState) (l : LState) := alpha q=l
def qSafe (q : QState) : Prop :=
 q.cb=7 ∧ q.rc=9 ∧ q.fs=5 ∧ q.link=0 ∧ 0≤q.shots ∧ q.shots≤3 ∧
 (q.captured=true → q.root=true ∧ q.pin=true ∧ q.frameAbi=q.runtimeAbi) ∧
 (q.running=true → q.captured=true ∧ q.loaded=q.epoch) ∧
 (q.emitted=true → q.emitAbi=q.abi) ∧
 (q.native=true → q.emitted=true ∧ q.objAbi=q.abi ∧ q.objTool=q.tool)
def lSafe (l : LState) : Prop :=
 l.shape.cb=7 ∧ l.shape.rc=9 ∧ l.shape.fs=5 ∧ l.shape.link=0 ∧ 0≤l.run.shots ∧ l.run.shots≤3 ∧
 (l.run.captured=true → l.run.root=true ∧ l.run.pin=true ∧ l.run.frameAbi=l.run.runtimeAbi) ∧
 (l.run.running=true → l.run.captured=true ∧ l.run.loaded=l.run.epoch) ∧
 (l.build.emitted=true → l.build.emitAbi=l.build.abi) ∧
 (l.build.native=true → l.build.emitted=true ∧ l.build.objAbi=l.build.abi ∧ l.build.objTool=l.build.tool)
theorem initialSafe : qSafe initial := by simp [qSafe,initial]
inductive Event where
 | capture | collect | reload | resume | returnShot | abiEdit | emit | compile | toolEdit | bind | releaseCaptured | stutter
 deriving DecidableEq
def qGuard (e : Event) (q : QState) : Prop := match e with
 | .capture => q.captured=false ∧ q.running=false
 | .collect => q.captured=true ∧ q.root=true ∧ q.running=false
 | .reload => q.running=false
 | .resume => q.captured=true ∧ q.root=true ∧ q.pin=true ∧ q.running=false ∧ q.loaded=q.epoch ∧ q.shots<3
 | .returnShot => q.running=true
 | .compile => q.emitted=true
 | .bind => q.native=true ∧ q.captured=false ∧ q.running=false
 | .releaseCaptured => q.captured=true ∧ q.running=false
 | _ => True
def qNext (e : Event) (q : QState) : QState := match e with
 | .capture => {q with captured:=true,root:=true,pin:=true,frameAbi:=q.runtimeAbi,shots:=0}
 | .collect => {q with epoch:=q.epoch+1}
 | .reload => {q with loaded:=q.epoch}
 | .resume => {q with running:=true,shots:=q.shots+1}
 | .returnShot => {q with running:=false}
 | .abiEdit => {q with abi:=q.abi+1,emitted:=false,native:=false}
 | .emit => {q with emitAbi:=q.abi,emitted:=true,native:=false}
 | .compile => {q with objAbi:=q.emitAbi,objTool:=q.tool,native:=true}
 | .toolEdit => {q with tool:=q.tool+1,native:=false}
 | .bind => {q with runtimeAbi:=q.abi}
 | .releaseCaptured => {q with captured:=false,root:=false,pin:=false}
 | .stutter => q
def lGuard (e : Event) (l : LState) : Prop := match e with
 | .capture => l.run.captured=false ∧ l.run.running=false
 | .collect => l.run.captured=true ∧ l.run.root=true ∧ l.run.running=false
 | .reload => l.run.running=false
 | .resume => l.run.captured=true ∧ l.run.root=true ∧ l.run.pin=true ∧ l.run.running=false ∧ l.run.loaded=l.run.epoch ∧ l.run.shots<3
 | .returnShot => l.run.running=true
 | .compile => l.build.emitted=true
 | .bind => l.build.native=true ∧ l.run.captured=false ∧ l.run.running=false
 | .releaseCaptured => l.run.captured=true ∧ l.run.running=false
 | _ => True
def lNext (e : Event) (l : LState) : LState := match e with
 | .capture => {l with run:={l.run with captured:=true,root:=true,pin:=true,frameAbi:=l.run.runtimeAbi,shots:=0}}
 | .collect => {l with run:={l.run with epoch:=l.run.epoch+1}}
 | .reload => {l with run:={l.run with loaded:=l.run.epoch}}
 | .resume => {l with run:={l.run with running:=true,shots:=l.run.shots+1}}
 | .returnShot => {l with run:={l.run with running:=false}}
 | .abiEdit => {l with build:={l.build with abi:=l.build.abi+1,emitted:=false,native:=false}}
 | .emit => {l with build:={l.build with emitAbi:=l.build.abi,emitted:=true,native:=false}}
 | .compile => {l with build:={l.build with objAbi:=l.build.emitAbi,objTool:=l.build.tool,native:=true}}
 | .toolEdit => {l with build:={l.build with tool:=l.build.tool+1,native:=false}}
 | .bind => {l with run:={l.run with runtimeAbi:=l.build.abi}}
 | .releaseCaptured => {l with run:={l.run with captured:=false,root:=false,pin:=false}}
 | .stutter => l
def qStep (e : Event) (q q' : QState) := qGuard e q ∧ q'=qNext e q
def lStep (e : Event) (l l' : LState) := lGuard e l ∧ l'=lNext e l
theorem guardCorrespondence (e : Event) (q : QState) : qGuard e q ↔ lGuard e (alpha q) := by cases e <;> rfl
theorem updateCorrespondence (e : Event) (q : QState) : alpha (qNext e q)=lNext e (alpha q) := by cases e <;> rfl
theorem forwardSimulation (e : Event) (q q' : QState) (l : LState) (r : relates q l) (h : qStep e q q') : lStep e l (alpha q') := by
 subst l
 rcases h with ⟨guard,step⟩
 exact ⟨(guardCorrespondence e q).mp guard,by rw [step,updateCorrespondence]⟩
theorem safetyReflection (q : QState) (l : LState) (r : relates q l) : qSafe q ↔ lSafe l := by subst l; rfl
theorem qPreserves (e : Event) (q : QState) (safe : qSafe q) (guard : qGuard e q) : qSafe (qNext e q) := by
 cases e <;> simp only [qSafe,qGuard,qNext] at safe guard ⊢
 all_goals rcases safe with ⟨hcb,hrc,hfs,hl,hzero,hmax,hcap,hrun,hem,hnat⟩
 all_goals simp_all
 all_goals omega
inductive QHistory : QState → QState → Prop where
 | nil (q) : QHistory q q
 | cons {q r t} : (e : Event) → qStep e q r → QHistory r t → QHistory q t
inductive LHistory : LState → LState → Prop where
 | nil (l) : LHistory l l
 | cons {l r t} : (e : Event) → lStep e l r → LHistory r t → LHistory l t
theorem historySimulation {q q' : QState} (h : QHistory q q') : LHistory (alpha q) (alpha q') := by
 induction h with
 | nil => exact .nil _
 | cons e step _ ih => exact .cons e (forwardSimulation e _ _ _ rfl step) ih
theorem historySafe {q q' : QState} (safe : qSafe q) (h : QHistory q q') : qSafe q' := by
 induction h with
 | nil => exact safe
 | cons e step _ ih => rcases step with ⟨guard,eq⟩; exact ih (eq ▸ qPreserves e _ safe guard)
-- Current stored normal-return witnesses only; no generic OFD/RETI theorem claimed.
def ifd (fs link mask : Nat) := mask*4096+link*128+fs*4+1
def decFs (d : Nat) := (d/4)%32
def decLink (d : Nat) := (d/128)%32
def decMask (d : Nat) := d/4096
theorem callbackDescriptor : decFs (ifd 5 0 7)=5 ∧ decLink (ifd 5 0 7)=0 ∧ decMask (ifd 5 0 7)=7 := by decide
theorem recursiveDescriptor : decFs (ifd 5 0 9)=5 ∧ decLink (ifd 5 0 9)=0 ∧ decMask (ifd 5 0 9)=9 := by decide
theorem mapsNotInterchangeable : (7 : Nat)≠9 := by decide
def stackOffset (i : Int) := 8-i
def heapIndex (i : Int) := 6-i
theorem coordinateDifference (i : Int) : stackOffset i-heapIndex i=2 := by simp [stackOffset,heapIndex]; omega
theorem liveSlotBounds (i : Int) (h : 1≤i ∧ i≤5) : 3≤stackOffset i ∧ stackOffset i≤7 ∧ 1≤heapIndex i ∧ heapIndex i≤5 := by simp [stackOffset,heapIndex]; omega
end MapFrameAbi
