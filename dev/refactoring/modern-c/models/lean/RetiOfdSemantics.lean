import MapFrameAbi
namespace RetiOfdSemantics
open MapFrameAbi
-- Small relational language for the explicitly admitted typed-IR subset.
inductive IField where
 | cb
 | rc
 | fs
 | link
 | epoch
 | loaded
 | shots
 | frameAbi
 | runtimeAbi
 | abi
 | emitAbi
 | objAbi
 | tool
 | objTool
 deriving DecidableEq
inductive BField where
 | captured
 | root
 | pin
 | running
 | emitted
 | native
 deriving DecidableEq
def getI (q : QState) : IField → Int
 | .cb => q.cb
 | .rc => q.rc
 | .fs => q.fs
 | .link => q.link
 | .epoch => q.epoch
 | .loaded => q.loaded
 | .shots => q.shots
 | .frameAbi => q.frameAbi
 | .runtimeAbi => q.runtimeAbi
 | .abi => q.abi
 | .emitAbi => q.emitAbi
 | .objAbi => q.objAbi
 | .tool => q.tool
 | .objTool => q.objTool
def getB (q : QState) : BField → Bool
 | .captured => q.captured
 | .root => q.root
 | .pin => q.pin
 | .running => q.running
 | .emitted => q.emitted
 | .native => q.native
def setI (q : QState) (v : Int) : IField → QState
 | .cb => {q with cb:=v}
 | .rc => {q with rc:=v}
 | .fs => {q with fs:=v}
 | .link => {q with link:=v}
 | .epoch => {q with epoch:=v}
 | .loaded => {q with loaded:=v}
 | .shots => {q with shots:=v}
 | .frameAbi => {q with frameAbi:=v}
 | .runtimeAbi => {q with runtimeAbi:=v}
 | .abi => {q with abi:=v}
 | .emitAbi => {q with emitAbi:=v}
 | .objAbi => {q with objAbi:=v}
 | .tool => {q with tool:=v}
 | .objTool => {q with objTool:=v}
def setB (q : QState) (v : Bool) : BField → QState
 | .captured => {q with captured:=v}
 | .root => {q with root:=v}
 | .pin => {q with pin:=v}
 | .running => {q with running:=v}
 | .emitted => {q with emitted:=v}
 | .native => {q with native:=v}
inductive IExpr where
 | lit : Int → IExpr
 | get : IField → IExpr
 | add : IExpr → IExpr → IExpr
inductive BVExpr where
 | lit : Bool → BVExpr
 | get : BField → BVExpr
inductive BExpr where
 | truth : BVExpr → BExpr
 | neg : BExpr → BExpr
 | conj : BExpr → BExpr → BExpr
 | disj : BExpr → BExpr → BExpr
 | implies : BExpr → BExpr → BExpr
 | eqI : IExpr → IExpr → BExpr
 | eqB : BVExpr → BVExpr → BExpr
 | lt : IExpr → IExpr → BExpr
 | le : IExpr → IExpr → BExpr
def evalI (e : IExpr) (q : QState) : Int := match e with
 | .lit n => n
 | .get f => getI q f
 | .add a b => evalI a q+evalI b q
def evalBV (e : BVExpr) (q : QState) : Bool := match e with
 | .lit b => b
 | .get f => getB q f
def evalB (e : BExpr) (q : QState) : Prop := match e with
 | .truth v => evalBV v q=true
 | .neg b => ¬evalB b q
 | .conj a b => evalB a q ∧ evalB b q
 | .disj a b => evalB a q ∨ evalB b q
 | .implies a b => evalB a q → evalB b q
 | .eqI a b => evalI a q=evalI b q
 | .eqB a b => evalBV a q=evalBV b q
 | .lt a b => evalI a q<evalI b q
 | .le a b => evalI a q≤evalI b q
inductive Update where
 | int : IField → IExpr → Update
 | bool : BField → BVExpr → Update
def applyUpdate (old acc : QState) (u : Update) : QState := match u with
 | .int f e => setI acc (evalI e old) f
 | .bool f e => setB acc (evalBV e old) f
def evalUpdates (old : QState) : List Update → QState → QState
 | [],acc => acc
 | u::us,acc => evalUpdates old us (applyUpdate old acc u)
inductive Action where
 | atom : BExpr → List Update → Action
 | choice : Action → Action → Action
def runAction (a : Action) (q q' : QState) : Prop := match a with
 | .atom guard us => evalB guard q ∧ q'=evalUpdates q us q
 | .choice a b => runAction a q q' ∨ runAction b q q'
-- Mathematical frame facts are qualified by source configuration and lifetime premises.
def actualFs (stored : Nat) := ((stored+3)/4)*4+9
def bitLive (mask slot : Nat) := ((mask/2^(slot-1))%2)=1
theorem internalEight : actualFs 8=17 := by decide
theorem internalOne : actualFs 1=13 := by decide
theorem internalThree : actualFs 3=13 := by decide
theorem savedWindowEight (i : Nat) (h : 9≤i ∧ i≤14) : bitLive 0x3f07 i := by
 have : i=9 ∨ i=10 ∨ i=11 ∨ i=12 ∨ i=13 ∨ i=14 := by omega
 rcases this with h|h|h|h|h|h <;> subst i <;> unfold bitLive <;> decide
theorem savedWindowOne (i : Nat) (h : 5≤i ∧ i≤10) : bitLive 0x3f1 i := by
 have : i=5 ∨ i=6 ∨ i=7 ∨ i=8 ∨ i=9 ∨ i=10 := by omega
 rcases this with h|h|h|h|h|h <;> subst i <;> unfold bitLive <;> decide
theorem allEightMasks (mask i : Nat) (hm : mask=0x3f07 ∨ mask=0x3f03 ∨ mask=0x3f01) (hi : 9≤i ∧ i≤14) : bitLive mask i := by
 have hs : i=9 ∨ i=10 ∨ i=11 ∨ i=12 ∨ i=13 ∨ i=14 := by omega
 rcases hm with h|h|h <;> subst mask <;> rcases hs with h|h|h|h|h|h <;> subst i <;> unfold bitLive <;> decide
theorem allSmallMasks (mask i : Nat) (hm : mask=0x3f1 ∨ mask=0x3f7) (hi : 5≤i ∧ i≤10) : bitLive mask i := by
 have hs : i=5 ∨ i=6 ∨ i=7 ∨ i=8 ∨ i=9 ∨ i=10 := by omega
 rcases hm with h|h <;> subst mask <;> rcases hs with h|h|h|h|h|h <;> subst i <;> unfold bitLive <;> decide
theorem actualReturnHomeEight : actualFs 8-14+1=4 := by decide
theorem actualReturnHomeOne : actualFs 1-10+1=4 := by decide
theorem chunkReconstruction (n : Nat) : n%2^32+2^32*(n/2^32)=n := Nat.mod_add_div n (2^32)
theorem syntheticLargeFrame : actualFs 25=37 ∧ (0x3f0000001 : Nat)%2^32=0xf0000001 ∧ (0x3f0000001 : Nat)/2^32=3 := by decide
structure Retirement where
 closed : Bool
 captured : Nat
 descriptors : Nat
 scanners : Nat
 nativeUsers : Nat
 inspectors : Nat
 unknown : Bool
def canRetire (r : Retirement) := r.closed=true ∧ r.captured=0 ∧ r.descriptors=0 ∧ r.scanners=0 ∧ r.nativeUsers=0 ∧ r.inspectors=0 ∧ r.unknown=false
theorem retireNeedsEveryUser (r : Retirement) (h : canRetire r) : r.scanners=0 ∧ r.inspectors=0 := ⟨h.2.2.2.1,h.2.2.2.2.2.1⟩
theorem unknownBlocksRetirement (r : Retirement) (h : r.unknown=true) : ¬canRetire r := by intro c; have k:=c.2.2.2.2.2.2; simp [h] at k
theorem closedAloneInsufficient : ¬canRetire ⟨true,0,0,1,0,0,false⟩ := by simp [canRetire]
end RetiOfdSemantics
