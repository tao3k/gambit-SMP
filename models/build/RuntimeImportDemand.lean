import Std.Tactic

/-!
A reference planner for runtime import pruning. The expander supplies canonical
references and the build supplies exact dependency rows for one artifact generation.
The planner opens rows on demand. An unavailable row selects ordinary evaluation.
-/
namespace RuntimeImportDemand

structure BindingKey where
  owner : Nat
  phase : Int
  slot : Nat
  deriving DecidableEq, Repr

structure ExportName where
  interface : Nat
  phase : Int
  spelling : Nat
  deriving DecidableEq, Repr

inductive ExportEntry where
  | defined (key : BindingKey)
  | reexported (target : ExportName)
  deriving DecidableEq, Repr

abbrev Exports := ExportName → Option ExportEntry

inductive Resolves (table : Exports) : ExportName → BindingKey → Prop where
  | defined : table atName = some (.defined key) → Resolves table atName key
  | reexported : table atName = some (.reexported target) →
      Resolves table target key → Resolves table atName key

/-- Follow only the requested export chain. The result is the defining
binding, including its phase, regardless of intermediate spellings. -/
def resolveName (table : Exports) : Nat → ExportName → Option BindingKey
  | 0, _ => none
  | fuel + 1, name =>
    match table name with
    | none => none
    | some (.defined key) => some key
    | some (.reexported target) => resolveName table fuel target

theorem resolution_sound {table : Exports}
    (observed : resolveName table fuel name = some key) : Resolves table name key := by
  induction fuel generalizing name with
  | zero => simp [resolveName] at observed
  | succ fuel ih =>
    cases hit : table name with
    | none => simp [resolveName, hit] at observed
    | some entry =>
      cases entry with
      | defined binding =>
        have same : binding = key := by simpa [resolveName, hit] using observed
        exact .defined (by simpa [same] using hit)
      | reexported next =>
        exact .reexported hit (ih (by simpa only [resolveName, hit] using observed))

theorem resolution_unique {table : Exports} (first : Resolves table name key)
    (second : Resolves table name other) : key = other := by
  induction first with
  | defined hit =>
    cases second with
    | defined same => simpa [hit] using same
    | reexported wrong _ => simp [hit] at wrong
  | reexported hit _ ih =>
    cases second with
    | defined wrong => simp [hit] at wrong
    | reexported same resolved =>
      simp [hit] at same
      cases same
      exact ih resolved

-- A visibility key contains the consumer spelling and phase. Strong imports
-- conflict on distinct binding identities even if no reference uses that key.
def StrongImportConflict {name : Type} (first second : name → Option BindingKey) : Prop :=
  ∃ key left right, first key = some left ∧ second key = some right ∧ left ≠ right

def visibleSubset {name : Type} [DecidableEq name]
    (demanded : List name) (exports : name → Option BindingKey) : name → Option BindingKey :=
  fun key => if key ∈ demanded then exports key else none

theorem projected_import_conflict_iff {name : Type} [DecidableEq name]
    (demanded : List name) (first second : name → Option BindingKey) :
    StrongImportConflict (visibleSubset demanded first) (visibleSubset demanded second) ↔
      ∃ key left right, key ∈ demanded ∧ first key = some left ∧
        second key = some right ∧ left ≠ right := by
  constructor
  · rintro ⟨key, left, right, hl, hr, distinct⟩
    by_cases present : key ∈ demanded
    · exact ⟨key, left, right, present,
        by simpa [visibleSubset, present] using hl,
        by simpa [visibleSubset, present] using hr, distinct⟩
    · simp [visibleSubset, present] at hl
  · rintro ⟨key, left, right, present, hl, hr, distinct⟩
    exact ⟨key, left, right,
      by simpa [visibleSubset, present] using hl,
      by simpa [visibleSubset, present] using hr, distinct⟩

theorem unused_import_conflict_counterexample :
    let first : Bool → Option BindingKey := fun key =>
      some (if key then ⟨1, 0, 1⟩ else ⟨1, 0, 2⟩)
    let second : Bool → Option BindingKey := fun key =>
      if key then none else some ⟨2, 0, 2⟩
    StrongImportConflict first second ∧
      ¬ StrongImportConflict (visibleSubset [true] first) (visibleSubset [true] second) := by
  dsimp
  constructor
  · exact ⟨false, ⟨1, 0, 2⟩, ⟨2, 0, 2⟩, rfl, rfl, by decide⟩
  · rw [projected_import_conflict_iff]
    rintro ⟨key, _, right, present, _, hr, _⟩
    simp at present
    subst key
    contradiction

inductive Request where
  | lookup (name : ExportName)
  | transformer (key : BindingKey)
  | value (key : BindingKey)
  | visit (owner : Nat) (phase : Int)
  | observeClass (key : BindingKey)
  | initialize (owner : Nat) (phase : Int) (slot : Nat)
  | image (owner : Nat) (phase : Int) (partition : Nat)
  deriving DecidableEq, Repr

abbrev Graph (α : Type) := α → α → Prop
abbrev Table (α : Type) := α → Option (List α)

inductive Required (roots : List α) (edge : Graph α) : α → Prop where
  | root : a ∈ roots → Required roots edge a
  | follow : Required roots edge a → edge a b → Required roots edge b

def Admissible (roots : List α) (edge : Graph α) (kept : α → Prop) : Prop :=
  (∀ a, a ∈ roots → kept a) ∧ (∀ a b, kept a → edge a b → kept b)

def Exact (table : Table α) (edge : Graph α) : Prop :=
  ∀ a row, table a = some row → ∀ b, b ∈ row ↔ edge a b

theorem required_least {roots : List α} {edge : Graph α} {kept : α → Prop}
    (safe : Admissible roots edge kept) (needed : Required roots edge a) : kept a := by
  induction needed with
  | root mem => exact safe.1 _ mem
  | follow _ hop ih => exact safe.2 _ _ ih hop

private def remaining [DecidableEq α] (seen : List α) : List α → List α
  | [] => []
  | a :: rest => if a ∈ seen then remaining seen rest else a :: rest

private theorem remaining_subset [DecidableEq α] (seen todo : List α) :
    remaining seen todo ⊆ todo := by
  induction todo with
  | nil => simp [remaining]
  | cons a rest ih =>
    by_cases mem : a ∈ seen
    · intro b hb
      exact List.mem_cons_of_mem _ (ih (by simpa [remaining, mem] using hb))
    · simp [remaining, mem]

private theorem remaining_covers [DecidableEq α] {seen todo : List α} {a : α}
    (mem : a ∈ todo) : a ∈ seen ∨ a ∈ remaining seen todo := by
  induction todo with
  | nil => simp at mem
  | cons b rest ih =>
    by_cases opened : b ∈ seen
    · simp only [remaining, ite_eq_left opened]
      rcases List.mem_cons.mp mem with rfl | h
      · exact Or.inl opened
      · exact ih h
    · exact Or.inr (by simpa [remaining, opened] using mem)

private theorem remaining_head_fresh [DecidableEq α] {seen todo rest : List α} {a : α}
    (head : remaining seen todo = a :: rest) : a ∉ seen := by
  induction todo with
  | nil => simp [remaining] at head
  | cons b tail ih =>
    by_cases opened : b ∈ seen
    · exact ih (by simpa [remaining, opened] using head)
    · have eq : b = a := (List.cons.inj (by simpa [remaining, opened] using head)).1
      simpa [eq] using opened

/-- A unit of fuel pays for opening one distinct dependency row. The planner
does not enumerate the finite domain used to justify the bound. -/
def search [DecidableEq α] (table : Table α) :
    Nat → List α → List α → Option (List α)
  | 0, todo, seen =>
    match remaining seen todo with
    | [] => some seen
    | _ :: _ => none
  | fuel + 1, todo, seen =>
    match remaining seen todo with
    | [] => some seen
    | a :: rest =>
      match table a with
      | none => none
      | some row => search table fuel (row ++ rest) (a :: seen)

private structure Frontier (roots : List α) (edge : Graph α) (seen todo : List α) : Prop where
  distinct : seen.Nodup
  seenRequired : ∀ a, a ∈ seen → Required roots edge a
  todoRequired : ∀ a, a ∈ todo → Required roots edge a
  rootsCovered : ∀ a, a ∈ roots → a ∈ seen ∨ a ∈ todo
  edgesCovered : ∀ a b, a ∈ seen → edge a b → b ∈ seen ∨ b ∈ todo

private theorem initial (roots : List α) (edge : Graph α) :
    Frontier roots edge [] roots where
  distinct := List.nodup_nil
  seenRequired := by simp
  todoRequired := fun _ h => .root h
  rootsCovered := fun _ h => Or.inr h
  edgesCovered := by simp

private theorem step [DecidableEq α] {roots : List α} {edge : Graph α}
    {seen todo rest row : List α} {a : α}
    (front : Frontier roots edge seen todo)
    (trim : remaining seen todo = a :: rest)
    (rowExact : ∀ b, b ∈ row ↔ edge a b) :
    Frontier roots edge (a :: seen) (row ++ rest) := by
  have requiredA := front.todoRequired a
    (remaining_subset seen todo (trim.symm ▸ List.mem_cons_self))
  have cover (b : α) (h : b ∈ seen ∨ b ∈ todo) :
      b ∈ a :: seen ∨ b ∈ row ++ rest := by
    rcases h with before | waiting
    · exact Or.inl (List.mem_cons_of_mem _ before)
    · rcases remaining_covers (seen := seen) waiting with before | pending
      · exact Or.inl (List.mem_cons_of_mem _ before)
      · rw [trim, List.mem_cons] at pending
        rcases pending with rfl | later
        · exact Or.inl List.mem_cons_self
        · exact Or.inr (List.mem_append.mpr (Or.inr later))
  refine ⟨List.nodup_cons.mpr ⟨remaining_head_fresh trim, front.distinct⟩, ?_, ?_, ?_, ?_⟩
  · intro b h
    rcases List.mem_cons.mp h with rfl | earlier
    · exact requiredA
    · exact front.seenRequired _ earlier
  · intro b h
    rcases List.mem_append.mp h with fromRow | earlier
    · exact .follow requiredA ((rowExact b).mp fromRow)
    · exact front.todoRequired b
        (remaining_subset seen todo (trim.symm ▸ List.mem_cons_of_mem _ earlier))
  · exact fun b h => cover b (front.rootsCovered b h)
  · intro b c hb hc
    rcases List.mem_cons.mp hb with rfl | earlier
    · exact Or.inr (List.mem_append.mpr (Or.inl ((rowExact c).mpr hc)))
    · exact cover c (front.edgesCovered b c earlier hc)

private theorem finish [DecidableEq α] {roots : List α} {edge : Graph α}
    {seen todo : List α} (front : Frontier roots edge seen todo)
    (done : remaining seen todo = []) :
    seen.Nodup ∧ ∀ a, a ∈ seen ↔ Required roots edge a := by
  have close (a : α) (h : a ∈ seen ∨ a ∈ todo) : a ∈ seen := by
    rcases h with h | h
    · exact h
    · have covered := remaining_covers (seen := seen) h
      simpa [done] using covered
  refine ⟨front.distinct, fun a => ⟨front.seenRequired a, ?_⟩⟩
  apply required_least
  exact ⟨fun b h => close b (front.rootsCovered b h),
         fun b c hb hc => close c (front.edgesCovered b c hb hc)⟩

private theorem successful [DecidableEq α] {roots : List α} {edge : Graph α}
    {table : Table α} (exactRows : Exact table edge) {fuel : Nat}
    {seen todo result : List α} (front : Frontier roots edge seen todo)
    (ran : search table fuel todo seen = some result) :
    result.Nodup ∧ ∀ a, a ∈ result ↔ Required roots edge a := by
  induction fuel generalizing seen todo with
  | zero =>
    cases trim : remaining seen todo with
    | nil =>
      have eq : seen = result := by simpa [search, trim] using ran
      simpa [eq] using finish front trim
    | cons a rest => simp [search, trim] at ran
  | succ fuel ih =>
    cases trim : remaining seen todo with
    | nil =>
      have eq : seen = result := by simpa [search, trim] using ran
      simpa [eq] using finish front trim
    | cons a rest =>
      cases hit : table a with
      | none => simp [search, trim, hit] at ran
      | some row =>
        exact ih (step front trim (exactRows a row hit))
          (by simpa only [search, trim, hit] using ran)

private theorem total [DecidableEq α] {roots : List α} {edge : Graph α}
    {table : Table α} (exactRows : Exact table edge)
    (complete : ∀ a, Required roots edge a → ∃ row, table a = some row)
    (domain : List α) (finite : ∀ a, Required roots edge a → a ∈ domain)
    {fuel : Nat} {seen todo : List α} (front : Frontier roots edge seen todo)
    (capacity : domain.length ≤ seen.length + fuel) :
    ∃ result, search table fuel todo seen = some result := by
  induction fuel generalizing seen todo with
  | zero =>
    cases trim : remaining seen todo with
    | nil => exact ⟨seen, by simp [search, trim]⟩
    | cons a rest =>
      have h : (a :: seen).Nodup :=
        List.nodup_cons.mpr ⟨remaining_head_fresh trim, front.distinct⟩
      have sub : a :: seen ⊆ domain := by
        intro b hb
        rcases List.mem_cons.mp hb with rfl | hb
        · exact finite _ (front.todoRequired _
            (remaining_subset seen todo (trim.symm ▸ List.mem_cons_self)))
        · exact finite _ (front.seenRequired _ hb)
      have bound := h.length_le_of_subset sub
      simp only [List.length_cons] at bound
      omega
  | succ fuel ih =>
    cases trim : remaining seen todo with
    | nil => exact ⟨seen, by simp [search, trim]⟩
    | cons a rest =>
      obtain ⟨row, hit⟩ := complete a (front.todoRequired a
        (remaining_subset seen todo (trim.symm ▸ List.mem_cons_self)))
      obtain ⟨result, resultEq⟩ := ih (step front trim (exactRows a row hit))
        (by simp only [List.length_cons]; omega)
      exact ⟨result, by simp only [search, trim, hit]; exact resultEq⟩

def plan [DecidableEq α] (table : Table α) (budget : Nat) (roots : List α) :
    Option (List α) :=
  search table budget roots []

theorem plan_exact [DecidableEq α] {roots : List α} {edge : Graph α} {table : Table α}
    (exactRows : Exact table edge) (ran : plan table budget roots = some result) :
    result.Nodup ∧ ∀ a, a ∈ result ↔ Required roots edge a :=
  successful exactRows (initial roots edge) ran

/-- Scope closure composes under the same compiler graph. Ordered effects use
the ordinary schedule; closure membership alone does not prescribe order. -/
theorem required_scopes {scopes : List (List α)} {edge : Graph α} {a : α} :
    Required scopes.flatten edge a ↔ ∃ scope ∈ scopes, Required scope edge a := by
  constructor
  · refine fun needed => required_least (kept := fun node => ∃ scope ∈ scopes, Required scope edge node) ?_ needed
    constructor
    · intro node root
      obtain ⟨scope, inScopes, inScope⟩ := List.mem_flatten.mp root
      exact ⟨scope, inScopes, .root inScope⟩
    · intro source target reached hop
      obtain ⟨scope, inScopes, needed⟩ := reached
      exact ⟨scope, inScopes, .follow needed hop⟩
  · rintro ⟨scope, inScopes, needed⟩
    apply required_least _ needed
    exact ⟨fun node inScope => .root (List.mem_flatten.mpr ⟨scope, inScopes, inScope⟩),
      fun _ _ reached hop => .follow reached hop⟩

/-- A combined validated closure and the individual validated closures identify
the same obligations, even when two scopes share a provider. -/
theorem plan_scopes_exact [DecidableEq α] {scopes : List (List α)}
    {edge : Graph α} {table : Table α}
    (exactRows : Exact table edge)
    (combined : plan table budget scopes.flatten = some result)
    (each : ∀ scope ∈ scopes, ∃ selected, plan table budget scope = some selected) :
    a ∈ result ↔
      ∃ scope ∈ scopes, ∃ selected, plan table budget scope = some selected ∧ a ∈ selected := by
  rw [(plan_exact exactRows combined).2 a, required_scopes]
  constructor
  · rintro ⟨scope, inScopes, needed⟩
    obtain ⟨selected, validated⟩ := each scope inScopes
    exact ⟨scope, inScopes, selected, validated, (plan_exact exactRows validated).2 a |>.mpr needed⟩
  · rintro ⟨scope, inScopes, selected, validated, included⟩
    exact ⟨scope, inScopes, (plan_exact exactRows validated).2 a |>.mp included⟩

theorem plan_exists [DecidableEq α] {roots : List α} {edge : Graph α} {table : Table α}
    (exactRows : Exact table edge)
    (complete : ∀ a, Required roots edge a → ∃ row, table a = some row)
    (domain : List α) (finite : ∀ a, Required roots edge a → a ∈ domain)
    (budget : Nat) (enough : domain.length ≤ budget) :
    ∃ result, plan table budget roots = some result :=
  total exactRows complete domain finite (initial roots edge) (by simpa using enough)

theorem plan_least [DecidableEq α] {roots : List α} {edge : Graph α} {table : Table α}
    (exactRows : Exact table edge) (ran : plan table budget roots = some result)
    (safe : Admissible roots edge kept) : ∀ a, a ∈ result → kept a :=
  fun a mem => required_least safe ((plan_exact exactRows ran).2 a |>.mp mem)


/-- A hand-selected set and the automatic result agree when both are
admissible and the manual set contains only required nodes. -/
theorem exact_manual_parity [DecidableEq α] {roots : List α} {edge : Graph α}
    {table : Table α} {manual : List α} (exactRows : Exact table edge)
    (ran : plan table budget roots = some result)
    (safe : Admissible roots edge fun a => a ∈ manual)
    (minimal : ∀ a, a ∈ manual → Required roots edge a) :
    ∀ a, a ∈ result ↔ a ∈ manual :=
  fun a => ⟨plan_least exactRows ran safe a, fun h => (plan_exact exactRows ran).2 a |>.mpr (minimal a h)⟩

private theorem search_preserves_seen [DecidableEq α] {table : Table α} {fuel : Nat}
    {todo seen result : List α} (ran : search table fuel todo seen = some result) :
    seen ⊆ result := by
  induction fuel generalizing todo seen with
  | zero =>
    cases trim : remaining seen todo with
    | nil =>
      have eq : seen = result := by simpa [search, trim] using ran
      simp [eq]
    | cons a rest => simp [search, trim] at ran
  | succ fuel ih =>
    cases trim : remaining seen todo with
    | nil =>
      have eq : seen = result := by simpa [search, trim] using ran
      simp [eq]
    | cons a rest =>
      cases hit : table a with
      | none => simp [search, trim, hit] at ran
      | some row =>
        have after : search table fuel (row ++ rest) (a :: seen) = some result := by
          simpa only [search, trim, hit] using ran
        intro b mem
        exact ih after (List.mem_cons_of_mem _ mem)

private theorem search_local [DecidableEq α] {first second : Table α} {fuel : Nat}
    {todo seen result : List α} (ran : search first fuel todo seen = some result)
    (same : ∀ a, a ∈ result → first a = second a) :
    search second fuel todo seen = some result := by
  induction fuel generalizing todo seen with
  | zero => simpa only [search] using ran
  | succ fuel ih =>
    cases trim : remaining seen todo with
    | nil => simpa only [search, trim] using ran
    | cons a rest =>
      cases hit : first a with
      | none => simp [search, trim, hit] at ran
      | some row =>
        have tailRan : search first fuel (row ++ rest) (a :: seen) = some result := by
          simpa only [search, trim, hit] using ran
        have opened : a ∈ result := search_preserves_seen tailRan List.mem_cons_self
        have other : second a = some row := (same a opened).symm.trans hit
        simpa only [search, trim, other] using ih tailRan

/-- Rows outside the successful worklist cannot even change its visitation order. -/
theorem plan_local [DecidableEq α] {first second : Table α}
    (ran : plan first budget roots = some result)
    (same : ∀ a, a ∈ result → first a = second a) :
    plan second budget roots = some result :=
  search_local ran same

private theorem search_rows [DecidableEq α] {table : Table α} {fuel : Nat}
    {todo seen result : List α} (ran : search table fuel todo seen = some result)
    (a : α) (member : a ∈ result) : a ∈ seen ∨ ∃ row, table a = some row := by
  induction fuel generalizing todo seen with
  | zero =>
    cases trim : remaining seen todo with
    | nil =>
      have eq : seen = result := by simpa [search, trim] using ran
      exact Or.inl (eq.symm ▸ member)
    | cons b rest => simp [search, trim] at ran
  | succ fuel ih =>
    cases trim : remaining seen todo with
    | nil =>
      have eq : seen = result := by simpa [search, trim] using ran
      exact Or.inl (eq.symm ▸ member)
    | cons b rest =>
      cases hit : table b with
      | none => simp [search, trim, hit] at ran
      | some row =>
        have continued : search table fuel (row ++ rest) (b :: seen) = some result := by
          simpa only [search, trim, hit] using ran
        rcases ih continued with known | read
        · rcases List.mem_cons.mp known with rfl | known
          · exact Or.inr ⟨row, hit⟩
          · exact Or.inl known
        · exact Or.inr read

theorem missing_required_row_falls_back [DecidableEq α] {roots : List α} {edge : Graph α}
    {table : Table α} (exactRows : Exact table edge)
    (needed : Required roots edge a) (missing : table a = none) :
    plan table budget roots = none := by
  cases hit : plan table budget roots with
  | none => rfl
  | some result =>
    have member := (plan_exact exactRows hit).2 a |>.mpr needed
    rcases search_rows hit a member with impossible | ⟨row, read⟩
    · simp at impossible
    · simp [missing] at read

structure Row (α : Type) where
  epoch : Nat
  dependencies : List α

def admittedTable (epoch : Nat) (select : α → Option (Row α)) : Table α :=
  fun a => (select a).bind fun row =>
    if row.epoch = epoch then some row.dependencies else none

inductive Decision (α : Type) where
  | ordinary
  | prune (kept : List α)
  deriving DecidableEq, Repr

def decidePlan [DecidableEq α] (opaqueBoundary : Bool) (epoch budget : Nat)
    (select : α → Option (Row α)) (roots : List α) : Decision α :=
  if opaqueBoundary then .ordinary else
    match plan (admittedTable epoch select) budget roots with
    | none => .ordinary
    | some kept => .prune kept

theorem opaque_fallback [DecidableEq α] (select : α → Option (Row α)) (roots : List α) :
    decidePlan true epoch budget select roots = .ordinary := rfl

theorem stale_row_absent {select : α → Option (Row α)} {a : α} {row : Row α}
    (hit : select a = some row) (stale : row.epoch ≠ epoch) :
    admittedTable epoch select a = none := by
  simp [admittedTable, hit, stale]

/-- The graph finds the required set. Effect execution follows the existing
initialization order, even for cycles of binding references. -/
def projectSchedule [DecidableEq α] (kept : List α) (owner : evt → α)
    (schedule : List evt) : List evt :=
  schedule.filter fun event => decide (owner event ∈ kept)

theorem schedule_keeps_order [DecidableEq α] (kept : List α) (owner : evt → α)
    (schedule : List evt) : (projectSchedule kept owner schedule).Sublist schedule :=
  List.filter_sublist

theorem plan_preserves_effect_trace [DecidableEq α] {roots : List α} {edge : Graph α}
    {table : Table α} (exactRows : Exact table edge)
    (ran : plan table budget roots = some result) (owner : evt → α) (effects : List evt)
    (necessary : ∀ event, event ∈ effects → Required roots edge (owner event)) :
    projectSchedule result owner effects = effects := by
  apply List.filter_eq_self.mpr
  intro event mem
  exact decide_eq_true ((plan_exact exactRows ran).2 _ |>.mpr (necessary event mem))

-- A reflection result can expose a subclass even when the consumer has
-- no lexical reference to that class. The schedule must retain the class's
-- method binding and interface prototype, and the implementation they read.
theorem plan_keeps_reflected_class_initializers {roots : List Request}
    {edge : Graph Request} {table : Table Request} {budget : Nat} {result : List Request}
    {parent child : BindingKey} {bind prototype image : Request}
    (exactRows : Exact table edge) (ran : plan table budget roots = some result)
    (inspect : .observeClass parent ∈ roots)
    (subclasses : edge (.observeClass parent) (.observeClass child))
    (methodTable : edge (.observeClass child) prototype)
    (prototypeReadsMethod : edge prototype bind) (methodReadsBody : edge bind image) :
    projectSchedule result id [bind, prototype] = [bind, prototype] ∧ image ∈ result := by
  have seesChild := Required.follow (Required.root inspect) subclasses
  have needsPrototype := Required.follow seesChild methodTable
  have needsBinding := Required.follow needsPrototype prototypeReadsMethod
  constructor
  · apply plan_preserves_effect_trace exactRows ran
    intro event mem
    simp at mem
    rcases mem with rfl | rfl
    · exact needsBinding
    · exact needsPrototype
  · exact (plan_exact exactRows ran).2 image |>.mpr (Required.follow needsBinding methodReadsBody)

/-- Interpreted as a sum over a shared domain, with independent nonnegative
weights for descriptor reads, checking and materialization. -/
def cost [DecidableEq α] (domain kept : List α) (weight : α → Nat) : Nat :=
  (domain.map fun a => if a ∈ kept then weight a else 0).sum

theorem cost_monotone [DecidableEq α] (domain : List α) (weight : α → Nat)
    {small large : List α} (subset : small ⊆ large) :
    cost domain small weight ≤ cost domain large weight := by
  induction domain with
  | nil => simp [cost]
  | cons a rest ih =>
    change (if a ∈ small then weight a else 0) + cost rest small weight ≤
        (if a ∈ large then weight a else 0) + cost rest large weight
    by_cases mem : a ∈ small
    · simpa [mem, subset mem] using Nat.add_le_add_left ih (weight a)
    · by_cases sup : a ∈ large
      · simpa [mem, sup] using Nat.le_trans ih (Nat.le_add_left (cost rest large weight) (weight a))
      · simpa [mem, sup] using ih

theorem plan_minimizes_weighted_footprint [DecidableEq α]
    {roots : List α} {edge : Graph α} {table : Table α}
    (exactRows : Exact table edge) (ran : plan table budget roots = some result)
    (domain alternative : List α) (weight : α → Nat)
    (safe : Admissible roots edge fun a => a ∈ alternative) :
    cost domain result weight ≤ cost domain alternative weight :=
  cost_monotone domain weight (fun _ mem => plan_least exactRows ran safe _ mem)

/-- When the required execution work is shared, the new startup wins exactly
when its extra discovery and validation are cheaper than the avoided work. -/
theorem startup_break_even (required discovery checking avoided : Nat) :
    required + (discovery + checking) < required + avoided ↔
      discovery + checking < avoided := by omega

/-- Exact selected artifact identities, backed in an implementation by
the existing loader's provenance. Names and mtimes do not supply this identity. -/
structure StartupSelection where
  consumer : Nat
  interfaces : Nat
  images : Nat
  deriving DecidableEq, Repr

structure PreparedStartup (evt : Type) where
  selection : StartupSelection
  actions : List evt
  deriving DecidableEq, Repr

/-- Ordinary expansion establishes the roots and visibility. All graph search
and schedule projection happen before native startup. -/
def prepareStartup [DecidableEq α] (selection : StartupSelection)
    (table : Table α) (budget : Nat) (roots : List α) (owner : evt → α)
    (ordinarySchedule : List evt) : Option (PreparedStartup evt) :=
  (plan table budget roots).map fun kept =>
    ⟨selection, projectSchedule kept owner ordinarySchedule⟩

/-- Activation has no dependency-table or export-table argument. A failed
admission returns no actions and leaves the ordinary path responsible. -/
def activateStartup (current : StartupSelection) (opaqueBoundary : Bool)
    (prepared : PreparedStartup evt) : Option (List evt) :=
  if opaqueBoundary then none
  else if current = prepared.selection then some prepared.actions else none

theorem activate_prepared_schedule [DecidableEq α] {table : Table α}
    {roots : List α} {kept : List α} (ran : plan table budget roots = some kept)
    (selection : StartupSelection) (owner : evt → α) (ordinarySchedule : List evt) :
    (prepareStartup selection table budget roots owner ordinarySchedule).bind
        (activateStartup selection false) =
      some (projectSchedule kept owner ordinarySchedule) := by
  simp [prepareStartup, activateStartup, ran]

theorem stale_startup_falls_back (prepared : PreparedStartup evt)
    (different : current ≠ prepared.selection) :
    activateStartup current false prepared = none := by
  simp [activateStartup, different]

theorem opaque_startup_falls_back (prepared : PreparedStartup evt)
    (current : StartupSelection) :
    activateStartup current true prepared = none := rfl

theorem activate_matches_manual_schedule [DecidableEq α] {roots manual kept : List α}
    {edge : Graph α} {table : Table α} (exactRows : Exact table edge)
    (ran : plan table budget roots = some kept)
    (safe : Admissible roots edge fun a => a ∈ manual)
    (minimal : ∀ a, a ∈ manual → Required roots edge a)
    (selection : StartupSelection) (owner : evt → α) (ordinarySchedule : List evt) :
    (prepareStartup selection table budget roots owner ordinarySchedule).bind
        (activateStartup selection false) =
      some (projectSchedule manual owner ordinarySchedule) := by
  rw [activate_prepared_schedule ran]
  congr 1
  unfold projectSchedule
  apply List.filter_congr
  intro event _
  have sameRoots := exact_manual_parity exactRows ran safe minimal (owner event)
  by_cases selected : owner event ∈ kept
  · simp [selected, sameRoots.mp selected]
  · have absent : owner event ∉ manual := fun mem => selected (sameRoots.mpr mem)
    simp [selected, absent]

structure StartupCost where
  discovery : Nat
  validation : Nat
  dispatch : Nat

def StartupCost.total (cost : StartupCost) : Nat :=
  cost.discovery + cost.validation + cost.dispatch

def scheduledWork (actions : List evt) (weight : evt → Nat) : Nat :=
  (actions.map weight).sum

/-- Once the same physical action sequence is available, parity is a bound
on startup overhead. A separate, independently measured bound must include
artifact admission, even for a precomputed plan. -/
theorem startup_manual_cost_parity {automatic manual : List evt}
    (same : automatic = manual) (weight : evt → Nat) (autoCost manualCost : StartupCost) :
    scheduledWork automatic weight + autoCost.total ≤
      scheduledWork manual weight + manualCost.total ↔ autoCost.total ≤ manualCost.total := by
  subst automatic
  omega

/-- Costs certified by matching measurements can use conservative bounds.
No tolerance is assumed for the parity gate. -/
theorem startup_manual_cost_gate {automatic manual : List evt}
    (same : automatic = manual) (weight : evt → Nat) (autoCost manualCost : StartupCost)
    (upper lower : Nat) (autoBound : autoCost.total ≤ upper)
    (manualBound : lower ≤ manualCost.total) (qualifies : upper ≤ lower) :
    scheduledWork automatic weight + autoCost.total ≤
      scheduledWork manual weight + manualCost.total :=
  (startup_manual_cost_parity same weight autoCost manualCost).mpr
    (Nat.le_trans autoBound (Nat.le_trans qualifies manualBound))

namespace Example

def cell : BindingKey := ⟨7, 0, 1⟩
def phaseCell : BindingKey := ⟨7, 1, 1⟩
def helper : BindingKey := ⟨7, 1, 2⟩
def facadeName : ExportName := ⟨1, 0, 42⟩
def renamedExport : ExportName := ⟨7, 0, 24⟩
def facade : Request := .lookup facadeName
def reexport : Request := .lookup renamedExport

def availableExports : Exports
  | name =>
    if name = facadeName then some (.reexported renamedExport)
    else if name = renamedExport then some (.defined cell)
    else none

#guard resolveName availableExports 2 facadeName == some cell
#guard resolveName availableExports 1 facadeName == none
#guard resolveName (fun n => some (.reexported n)) 3 facadeName == none

def useBinding : Request := .value cell
def expandBinding : Request := .transformer phaseCell
def phaseHelper : Request := .value helper
def initializeConfig : Request := .initialize 8 0 0
def registerType : Request := .initialize 7 0 0
def body : Request := .image 7 0 0
def transformerImage : Request := .image 7 1 0
def unusedSocket : Request := .image 9 0 0

def graphRows (request : Request) : Option (List Request) :=
  if request = facade then some [reexport]
  else if request = useBinding then some [body]
  else if request = expandBinding then some [.visit 7 1]
  else if request = .visit 7 1 then some [phaseHelper, transformerImage]
  else if request = phaseHelper then some [transformerImage, expandBinding]
  else if request = registerType then some [body]
  else some []

def target : List Request := [facade, useBinding, initializeConfig, registerType]
def fullInit : List Request := [initializeConfig, registerType]

def contains (choice : Option (List Request)) (request : Request) : Bool :=
  (choice.getD []).contains request

-- Looking up a reexport does not call the transformer or open its image.
#guard contains (plan graphRows 20 [facade]) reexport
#guard !(contains (plan graphRows 20 [facade]) transformerImage)
-- The original runtime observations keep their initialization roots.
#guard projectSchedule ((plan graphRows 20 target).getD []) id fullInit == fullInit
#guard !(contains (plan graphRows 20 target) unusedSocket)
-- The narrower root list would drop an observable startup effect.
#guard projectSchedule ((plan graphRows 20 [useBinding]).getD []) id fullInit == []
-- A cyclic phase-helper reference opens the shared phase image once.
#guard ((plan graphRows 20 [expandBinding, expandBinding]).getD []).length == 4
#guard contains (plan graphRows 20 [expandBinding]) phaseHelper
#guard contains (plan graphRows 20 [expandBinding]) transformerImage
#guard !(contains (plan graphRows 20 [expandBinding]) body)
#guard cell != phaseCell

def epochRows (request : Request) : Option (Row Request) :=
  (graphRows request).map fun dependencies => ⟨4, dependencies⟩

#guard decidePlan false 5 20 epochRows target == .ordinary
#guard decidePlan true 4 20 epochRows target == .ordinary
#guard decidePlan false 4 0 epochRows target == .ordinary
#guard decidePlan false 4 20 epochRows target != .ordinary

-- Fewer images alone cannot pay for the discovery and validation path.
example : 10 + 2 < 10 + (8 + 5) := by decide

def streamReceiver : BindingKey := ⟨31, 0, 1⟩
def datagramReceiver : BindingKey := ⟨31, 0, 2⟩
def bindDatagram : Request := .initialize 32 0 1
def buildDatagramPrototype : Request := .initialize 32 0 2
def datagramImage : Request := .image 33 0 0

def socketRows (request : Request) : Option (List Request) :=
  if request = .observeClass streamReceiver then some [.observeClass datagramReceiver]
  else if request = .observeClass datagramReceiver then some [buildDatagramPrototype]
  else if request = buildDatagramPrototype then some [bindDatagram]
  else if request = bindDatagram then some [datagramImage]
  else some []

-- Having a reference to a receiver differs from enumerating its subclasses.
#guard !(contains (plan socketRows 20 [.value streamReceiver]) datagramImage)
#guard contains (plan socketRows 20 [.observeClass streamReceiver]) datagramImage
#guard projectSchedule ((plan socketRows 20 [.observeClass streamReceiver]).getD []) id
  [bindDatagram, buildDatagramPrototype] == [bindDatagram, buildDatagramPrototype]

def selectedStartup : StartupSelection := ⟨1, 5, 9⟩

def frozenSocketPlan : Option (PreparedStartup Request) :=
  prepareStartup selectedStartup socketRows 20 [.value streamReceiver] id
    [bindDatagram, buildDatagramPrototype, datagramImage]

#guard (frozenSocketPlan.bind (activateStartup selectedStartup false)) == some []
#guard (frozenSocketPlan.bind (activateStartup { selectedStartup with interfaces := 6 } false)).isNone
#guard (frozenSocketPlan.bind (activateStartup { selectedStartup with images := 10 } false)).isNone
#guard (frozenSocketPlan.bind (activateStartup selectedStartup true)).isNone
#guard (StartupCost.total ⟨0, 2, 1⟩) > (StartupCost.total ⟨0, 0, 1⟩)
#guard (frozenSocketPlan.bind (activateStartup { selectedStartup with consumer := 2 } false)).isNone

-- A hand-narrowed load sequence that drops an observable initializer
-- differs from the schedule of the ordinary program's required roots.
#guard (prepareStartup selectedStartup graphRows 20 target id fullInit).bind
  (activateStartup selectedStartup false) == some fullInit
#guard (prepareStartup selectedStartup graphRows 20 target id fullInit).bind
  (activateStartup selectedStartup false) != some [registerType]

end Example
namespace Effects

abbrev Store := Nat → Nat

def update (store : Store) (key value : Nat) : Store :=
  fun cell => if cell = key then value else store cell

def Agree (live : List Nat) (ordinary selected : Store) : Prop :=
  ∀ cell, cell ∈ live → ordinary cell = selected cell

inductive Action where
  | put (cell value : Nat)
  | capture (destination source : Nat)
  | observe (cell : Nat)
  | emit (event : Nat)
  | require (cell value error : Nat)
  | fail (code : Nat)
  | unknown (query : Nat)
  deriving DecidableEq, Repr

inductive Observation where
  | value (cell value : Nat)
  | event (id : Nat)
  deriving DecidableEq, Repr

structure Result where
  store : Store
  failure : Option Nat
  trace : List Observation

/-- Put and capture are local writes with no external effect. The compiler
must prove this property. External writes, output, and registrations observed
beyond the local store require their own ordinary action or opaque fallback. -/
abbrev UnknownEffect := Nat → Store → Result

def execute (unknownEffect : UnknownEffect) (store : Store) : List Action → Result
  | [] => ⟨store, none, []⟩
  | .put cell value :: rest => execute unknownEffect (update store cell value) rest
  | .capture destination source :: rest =>
    execute unknownEffect (update store destination (store source)) rest
  | .observe cell :: rest =>
    let next := execute unknownEffect store rest
    { next with trace := .value cell (store cell) :: next.trace }
  | .emit event :: rest =>
    let next := execute unknownEffect store rest
    { next with trace := .event event :: next.trace }
  | .require cell value error :: rest =>
    if store cell = value then execute unknownEffect store rest else ⟨store, some error, []⟩
  | .fail code :: _ => ⟨store, some code, []⟩
  | .unknown query :: rest =>
    let result := unknownEffect query store
    if result.failure.isSome then result
    else
      let next := execute unknownEffect result.store rest
      { next with trace := result.trace ++ next.trace }

structure Projection where
  before : List Nat
  actions : List Action
  deriving DecidableEq, Repr

def exceptCell (cells : List Nat) (cell : Nat) : List Nat :=
  cells.filter (· != cell)

/-- The continuation declares which cells it can read on success or failure.
A finite observation reads its actual cell. Unknown effects reject the plan. -/
def project (success failure : List Nat) : List Action → Option Projection
  | [] => some ⟨success, []⟩
  | .unknown _ :: _ => none
  | .fail code :: _ => some ⟨failure, [.fail code]⟩
  | .put cell value :: rest => (project success failure rest).map fun tail =>
    if cell ∈ tail.before then
      ⟨exceptCell tail.before cell, .put cell value :: tail.actions⟩
    else tail
  | .capture destination source :: rest => (project success failure rest).map fun tail =>
    if destination ∈ tail.before then
      ⟨source :: exceptCell tail.before destination, .capture destination source :: tail.actions⟩
    else tail
  | .observe cell :: rest => (project success failure rest).map fun tail =>
    ⟨cell :: tail.before, .observe cell :: tail.actions⟩
  | .emit event :: rest => (project success failure rest).map fun tail =>
    ⟨tail.before, .emit event :: tail.actions⟩
  | .require cell value error :: rest => (project success failure rest).map fun tail =>
    ⟨cell :: (tail.before ++ failure), .require cell value error :: tail.actions⟩

def SameResult (success failure : List Nat) (ordinary selected : Result) : Prop :=
  ordinary.failure = selected.failure ∧ ordinary.trace = selected.trace ∧
    Agree (if ordinary.failure.isSome then failure else success) ordinary.store selected.store

theorem update_agrees {live : List Nat} {ordinary selected : Store} {cell value : Nat}
    (agreement : Agree (exceptCell live cell) ordinary selected) :
    Agree live (update ordinary cell value) (update selected cell value) := by
  intro other member
  by_cases same : other = cell
  · simp [update, same]
  · have retained : other ∈ exceptCell live cell := by simp [exceptCell, member, same]
    simpa [update, same] using agreement other retained

theorem omit_write_agrees {live : List Nat} {ordinary selected : Store} {cell value : Nat}
    (absent : cell ∉ live) (agreement : Agree live ordinary selected) :
    Agree live (update ordinary cell value) selected := by
  intro other member
  have different : other ≠ cell := fun same => absent (same ▸ member)
  simpa [update, different] using agreement other member

theorem agree_tail {head : Nat} {live : List Nat} {ordinary selected : Store}
    (agreement : Agree (head :: live) ordinary selected) : Agree live ordinary selected :=
  fun cell member => agreement cell (List.mem_cons_of_mem head member)

theorem project_sound {code : List Action} {success failure : List Nat}
    {ordinary selected : Store} {p : Projection} (unknownEffect : UnknownEffect)
    (prepared : project success failure code = some p)
    (agreement : Agree p.before ordinary selected) :
    SameResult success failure (execute unknownEffect ordinary code) (execute unknownEffect selected p.actions) := by
  induction code generalizing p ordinary selected with
  | nil =>
    simp [project] at prepared
    subst p
    exact ⟨rfl, rfl, agreement⟩
  | cons action rest ih =>
    cases action with
    | unknown query => simp [project] at prepared
    | fail code =>
      simp [project] at prepared
      subst p
      exact ⟨rfl, rfl, agreement⟩
    | put cell value =>
      cases next : project success failure rest with
      | none => simp [project, next] at prepared
      | some tail =>
        by_cases kept : cell ∈ tail.before
        · simp [project, next, kept] at prepared
          subst p
          have nextAgreement : Agree tail.before
              (update ordinary cell value) (update selected cell value) := update_agrees agreement
          simpa only [execute] using ih (p := tail) next nextAgreement
        · simp [project, next, kept] at prepared
          subst p
          simpa only [execute] using ih (p := tail) next (omit_write_agrees kept agreement)
    | capture destination source =>
      cases next : project success failure rest with
      | none => simp [project, next] at prepared
      | some tail =>
        by_cases kept : destination ∈ tail.before
        · simp [project, next, kept] at prepared
          subst p
          have sourceAgrees := agreement source List.mem_cons_self
          have after : Agree tail.before (update ordinary destination (ordinary source))
              (update selected destination (selected source)) := by
            rw [← sourceAgrees]
            exact update_agrees (agree_tail agreement)
          simpa only [execute] using ih (p := tail) next after
        · simp [project, next, kept] at prepared
          subst p
          simpa only [execute] using ih (p := tail) next (omit_write_agrees kept agreement)
    | observe cell =>
      cases next : project success failure rest with
      | none => simp [project, next] at prepared
      | some tail =>
        simp [project, next] at prepared
        subst p
        obtain ⟨status, trace, agreed⟩ := ih (p := tail) next (agree_tail agreement)
        refine ⟨by simpa only [execute] using status, ?_, agreed⟩
        have observed := agreement cell List.mem_cons_self
        simp only [execute, observed, trace]
    | emit event =>
      cases next : project success failure rest with
      | none => simp [project, next] at prepared
      | some tail =>
        simp [project, next] at prepared
        subst p
        obtain ⟨status, trace, agreed⟩ := ih (p := tail) next agreement
        exact ⟨by simpa only [execute] using status,
          by simpa only [execute] using congrArg (List.cons (.event event)) trace,
          agreed⟩
    | require cell value error =>
      cases next : project success failure rest with
      | none => simp [project, next] at prepared
      | some tail =>
        simp [project, next] at prepared
        subst p
        have observed := agreement cell List.mem_cons_self
        by_cases met : ordinary cell = value
        · have metSelected : selected cell = value := observed ▸ met
          have beforeTail : Agree tail.before ordinary selected := by
            intro key member
            exact agreement key (by simp [member])
          simpa only [execute, met, metSelected, ite_true] using ih (p := tail) next beforeTail
        · have missedSelected : selected cell ≠ value := observed ▸ met
          have beforeFailure : Agree failure ordinary selected := by
            intro key member
            exact agreement key (by simp [member])
          simp only [execute, met, missedSelected, ite_false]
          exact ⟨rfl, rfl, beforeFailure⟩

def prepareEffects (selection : StartupSelection) (success failure : List Nat)
    (code : List Action) : Option (PreparedStartup Action) :=
  (project success failure code).map fun result => ⟨selection, result.actions⟩

def chooseActions (selection current : StartupSelection) (opaqueBoundary : Bool)
    (success failure : List Nat) (code : List Action) : List Action :=
  ((prepareEffects selection success failure code).bind
    (activateStartup current opaqueBoundary)).getD code

theorem sameResult_refl (success failure : List Nat) (result : Result) :
    SameResult success failure result result := ⟨rfl, rfl, fun _ _ => rfl⟩

/-- The ordinary interpreter is the reference for both admitted plans and
fallback. Execution uses the same entry store on either path. -/
theorem chosen_actions_refine_ordinary (unknownEffect : UnknownEffect)
    (store : Store) (selection current : StartupSelection) (opaqueBoundary : Bool)
    (success failure : List Nat) (code : List Action) :
    SameResult success failure (execute unknownEffect store code)
      (execute unknownEffect store (chooseActions selection current opaqueBoundary success failure code)) := by
  cases sliced : project success failure code with
  | none =>
    simp [chooseActions, prepareEffects, sliced]
    exact sameResult_refl success failure _
  | some result =>
    by_cases sameSelection : current = selection
    · subst current
      cases opaqueBoundary
      · simp [chooseActions, prepareEffects, sliced, activateStartup]
        exact project_sound unknownEffect sliced (fun _ _ => rfl)
      · simp [chooseActions, prepareEffects, sliced, activateStartup]
        exact sameResult_refl success failure _
    · cases opaqueBoundary <;>
        simp [chooseActions, prepareEffects, sliced, activateStartup, sameSelection] <;>
        exact sameResult_refl success failure _

/-- Abstract the existing module registry. The native loader still owns the
lock, completion publication, and exception memoization. -/
inductive LoaderSlot where
  | absent
  | loading (owner : Nat)
  | settled (failure : Option Nat)
  deriving DecidableEq, Repr

inductive LoaderDecision where
  | start
  | wait
  | reentrant
  | reuse (failure : Option Nat)
  deriving DecidableEq, Repr

def requestSlot (requester : Nat) : LoaderSlot → LoaderDecision
  | .absent => .start
  | .loading owner => if owner = requester then .reentrant else .wait
  | .settled failure => .reuse failure

def publishResult (result : Result) : LoaderSlot := .settled result.failure

theorem prepared_activation_publishes_same_outcome (unknownEffect : UnknownEffect)
    (store : Store) (selection current : StartupSelection) (opaqueBoundary : Bool)
    (success failure : List Nat) (code : List Action) :
    publishResult (execute unknownEffect store code) =
      publishResult (execute unknownEffect store
        (chooseActions selection current opaqueBoundary success failure code)) :=
  congrArg LoaderSlot.settled
    (chosen_actions_refine_ordinary unknownEffect store selection current opaqueBoundary
      success failure code).1

theorem settled_never_starts_again (requester : Nat) (result : Result) :
    requestSlot requester (publishResult result) = .reuse result.failure := rfl

theorem self_request_does_not_wait (requester : Nat) :
    requestSlot requester (.loading requester) = .reentrant := by
  simp [requestSlot]

namespace Counterexample

def empty : Store := fun _ => 0
def exampleUnknown : UnknownEffect := fun query store => ⟨store, none, [.event query]⟩

def captureTemporaryDirectory : List Action :=
  [.put 0 1, .capture 1 0, .put 0 2, .observe 1]

-- Both programs can produce the same JSON receipt. Late observation of the
-- captured value distinguishes expanding the ordinary and hand-selected scopes.
#guard (execute exampleUnknown empty captureTemporaryDirectory).trace == [.value 1 1]
#guard (execute exampleUnknown empty [.put 0 1, .put 0 2, .capture 1 0, .observe 1]).trace == [.value 1 2]
#guard (project [0] [] captureTemporaryDirectory).map (·.actions) ==
  some captureTemporaryDirectory

def methodRegistration : List Action :=
  [.put 2 37, .capture 3 2, .capture 4 3, .observe 4]

-- The datum 37 represents the provider's actual procedure identity.
#guard (execute exampleUnknown empty methodRegistration).trace == [.value 4 37]
#guard (execute exampleUnknown empty [.capture 3 2, .capture 4 3, .observe 4]).trace == [.value 4 0]
#guard (project [] [] methodRegistration).map (·.actions) == some methodRegistration

-- An initializer failure stops the ordinary trace. Its continuation can still
-- observe a write that happened before the exception.
def failedInitialization : List Action := [.put 5 1, .put 6 2, .fail 70, .emit 3]
#guard (project [] [5] failedInitialization).map (·.actions) == some [.put 5 1, .fail 70]
#guard (execute exampleUnknown empty failedInitialization).failure == some 70
#guard (execute exampleUnknown empty failedInitialization).trace == []
#guard (project [] [] [.put 2 37, .unknown 41, .observe 4]).isNone

-- Skipping an unread initializer can still turn a native binding check
-- into a failure and change the continuation's state.
def checkedRegistration : List Action :=
  [.put 5 1, .put 2 37, .require 2 37 70, .observe 2]
#guard (execute exampleUnknown empty checkedRegistration).failure.isNone
#guard (execute exampleUnknown empty [.put 5 1, .require 2 37 70, .observe 2]).failure == some 70
#guard (project [] [5] checkedRegistration).map (·.actions) == some checkedRegistration

#guard (execute exampleUnknown empty [.put 2 37, .unknown 41, .observe 2]).trace ==
  [.event 41, .value 2 37]

def preparedSelection : StartupSelection := ⟨1, 2, 3⟩
def deadWrite : List Action := [.put 6 27, .emit 8]

#guard chooseActions preparedSelection preparedSelection false [] [] deadWrite == [.emit 8]
#guard chooseActions preparedSelection { preparedSelection with interfaces := 7 } false
  [] [] deadWrite == deadWrite
#guard chooseActions preparedSelection preparedSelection true [] [] deadWrite == deadWrite
#guard requestSlot 7 (.loading 7) == .reentrant
#guard requestSlot 8 (.loading 7) == .wait
#guard requestSlot 8 (publishResult (execute exampleUnknown empty failedInitialization)) == .reuse (some 70)
#guard requestSlot 8 (publishResult (execute exampleUnknown empty methodRegistration)) == .reuse none

-- A continuation that reads a cell restores the write dependency.
-- An incomplete observation boundary can admit a different observable state.
#guard (project [] [] deadWrite).map (·.actions) == some [.emit 8]
#guard (project [6] [] deadWrite).map (·.actions) == some deadWrite
#guard (execute exampleUnknown empty deadWrite).store 6 !=
  (execute exampleUnknown empty [.emit 8]).store 6

-- Identical artifacts do not establish agreement on the entering store.
#guard (execute exampleUnknown (update empty 1 1) [.observe 1]).trace !=
  (execute exampleUnknown (update empty 1 2) [.observe 1]).trace

end Counterexample
/-- The compiler assigns a physical block independently of the lexical phase.
The owner is the actual emitted image's module. A block can contain several
actions, which execute together when the existing loader opens the image.
A wrapper has no block number. The lexical phase does not change a filename. -/
structure ImageIdentity where
  owner : Nat
  phase : Int
  block : Option Nat
  deriving DecidableEq, Repr

structure ImageGroup where
  identity : ImageIdentity
  actions : List Action
  deriving DecidableEq, Repr

def imageActions (images : List ImageGroup) : List Action :=
  images.flatMap (·.actions)

def selectImages (requested : List ImageIdentity) (ordinary : List ImageGroup) :
    List ImageGroup :=
  ordinary.filter fun image => decide (image.identity ∈ requested)

/-- Compile-time acceptance of a proposed physical cut. Compare effects of both
ordered schedules under ordinary execution. Retained images are copied whole.
Unknown actions, duplicate image identities and missing requested images fail
admission. A successful schedule need not run this checker at startup. -/
def checkImagePlan (success failure : List Nat) (ordinary : List ImageGroup)
    (requested : List ImageIdentity) : Option (List ImageGroup) :=
  let inventory := ordinary.map (·.identity)
  let filenames := inventory.map fun id => (id.owner, id.block)
  if !decide filenames.Nodup || !(requested.all fun id => inventory.contains id) then none
  else
    let selected := selectImages requested ordinary
    match project success failure (imageActions ordinary),
          project success failure (imageActions selected) with
    | some baseline, some candidate =>
      if baseline.actions = candidate.actions then some selected else none
    | _, _ => none

theorem sameResult_symm {success failure : List Nat} {a b : Result}
    (same : SameResult success failure a b) : SameResult success failure b a := by
  refine ⟨same.1.symm, same.2.1.symm, ?_⟩
  rw [← same.1]
  intro cell live
  exact (same.2.2 cell live).symm

theorem sameResult_trans {success failure : List Nat} {a b c : Result}
    (left : SameResult success failure a b) (right : SameResult success failure b c) :
    SameResult success failure a c := by
  refine ⟨left.1.trans right.1, left.2.1.trans right.2.1, ?_⟩
  intro cell live
  exact (left.2.2 cell live).trans (right.2.2 cell (by rwa [← left.1]))

theorem equal_action_projections_refine {success failure : List Nat}
    {ordinary candidate : List Action} {reference selected : Projection}
    (unknownEffect : UnknownEffect) (store : Store)
    (baseline : project success failure ordinary = some reference)
    (plan : project success failure candidate = some selected)
    (same : reference.actions = selected.actions) :
    SameResult success failure (execute unknownEffect store ordinary)
      (execute unknownEffect store candidate) := by
  have first := project_sound unknownEffect baseline (ordinary := store)
    (selected := store) (fun _ _ => rfl)
  have second := project_sound unknownEffect plan (ordinary := store)
    (selected := store) (fun _ _ => rfl)
  rw [same] at first
  exact sameResult_trans first (sameResult_symm second)

theorem checked_images_refine_ordinary {success failure : List Nat}
    {ordinary selected : List ImageGroup} {requested : List ImageIdentity}
    (unknownEffect : UnknownEffect) (store : Store)
    (admitted : checkImagePlan success failure ordinary requested = some selected) :
    SameResult success failure (execute unknownEffect store (imageActions ordinary))
      (execute unknownEffect store (imageActions selected)) := by
  dsimp [checkImagePlan] at admitted
  split at admitted
  · contradiction
  · split at admitted
    next baseline candidate planA planB =>
      split at admitted
      next same =>
        have eq : selectImages requested ordinary = selected := Option.some.inj admitted
        subst selected
        exact equal_action_projections_refine unknownEffect store planA planB same
      next _ => contradiction
    next => contradiction

namespace ImageControl

def unneededBody : ImageIdentity := ⟨11, 0, some 0⟩
def mixedBody : ImageIdentity := ⟨12, 0, some 0⟩
def observer : ImageIdentity := ⟨13, 0, some 0⟩

def ordinaryImages : List ImageGroup :=
  [⟨unneededBody, [.put 7 3]⟩,
   ⟨mixedBody, [.put 0 1, .capture 1 0, .put 6 8]⟩,
   ⟨observer, [.put 0 2, .observe 1]⟩]

-- The private definition in the mixed body remains part of its executable image.
#guard (checkImagePlan [0] [] ordinaryImages [mixedBody, observer]).map imageActions ==
  some [.put 0 1, .capture 1 0, .put 6 8, .put 0 2, .observe 1]
#guard (checkImagePlan [0] [] ordinaryImages [observer]).isNone
#guard (checkImagePlan [0] [] ordinaryImages [⟨12, 1, some 0⟩, observer]).isNone
#guard (checkImagePlan [] [] [⟨unneededBody,[.unknown 1]⟩] []).isNone
#guard (checkImagePlan [] [] [⟨unneededBody,[]⟩, ⟨unneededBody,[]⟩] []).isNone

#guard (checkImagePlan [] [] [⟨⟨11, 0, some 0⟩,[]⟩, ⟨⟨11, 1, some 0⟩,[]⟩] []).isNone
#guard (checkImagePlan [] [] [⟨⟨11, 0, none⟩,[]⟩, ⟨⟨11, 0, some 0⟩,[]⟩] []).isSome

end ImageControl

end Effects


/-!
The compiler's proposal is data. Check closure against independently obtained
rows, and justify membership from the ordinary expanded roots. The order in
the proposed witness is a derivation order, not an initialization order.
-/
namespace ScopeCertificate

def rowClosed [DecidableEq α] (reference : Table α) (kept : List α) (node : α) : Bool :=
  match reference node with
  | none => false
  | some dependencies => dependencies.all kept.contains

def justified [DecidableEq α] (reference : Table α) (roots seen : List α) :
    List α → Bool
  | [] => true
  | node :: rest =>
    (roots.contains node ||
      seen.any (fun parent => ((reference parent).getD []).contains node)) &&
      justified reference roots (node :: seen) rest

def validate [DecidableEq α] (reference : Table α) (roots witness : List α) : Bool :=
  decide witness.Nodup && roots.all witness.contains &&
    witness.all (rowClosed reference witness) && justified reference roots [] witness

private theorem closed_admits [DecidableEq α] {reference : Table α} {edge : Graph α}
    {roots witness : List α} (exactRows : Exact reference edge)
    (rootsKept : roots.all witness.contains = true)
    (closed : witness.all (rowClosed reference witness) = true) :
    Admissible roots edge (· ∈ witness) := by
  constructor
  · intro node mem
    exact List.contains_iff_mem.mp (List.all_eq_true.mp rootsKept node mem)
  · intro node dep mem hop
    have checked := List.all_eq_true.mp closed node mem
    cases row : reference node with
    | none => simp [rowClosed, row] at checked
    | some deps =>
      have covered : deps.all witness.contains = true := by
        simpa [rowClosed, row] using checked
      exact List.contains_iff_mem.mp
        (List.all_eq_true.mp covered dep ((exactRows node deps row dep).mpr hop))

private theorem justified_required [DecidableEq α] {reference : Table α}
    {edge : Graph α} {roots seen witness : List α}
    (exactRows : Exact reference edge)
    (known : ∀ node ∈ seen, Required roots edge node)
    (cert : justified reference roots seen witness = true) :
    ∀ node ∈ witness, Required roots edge node := by
  induction witness generalizing seen with
  | nil => simp
  | cons child rest ih =>
    simp only [justified, Bool.and_eq_true, Bool.or_eq_true] at cert
    have childRequired : Required roots edge child := by
      rcases cert.1 with root | fromParent
      · exact .root (List.contains_iff_mem.mp root)
      · obtain ⟨parent, mem, present⟩ := List.any_eq_true.mp fromParent
        cases row : reference parent with
        | none => simp [row] at present
        | some dependencies =>
          have included : child ∈ dependencies := by
            simpa [row] using List.contains_iff_mem.mp present
          exact .follow (known parent mem) ((exactRows parent dependencies row child).mp included)
    intro node mem
    rcases List.mem_cons.mp mem with rfl | tail
    · exact childRequired
    · apply ih (seen := child :: seen) _ cert.2 node tail
      intro prior priorMem
      rcases List.mem_cons.mp priorMem with rfl | earlier
      · exact childRequired
      · exact known prior earlier

/-- Successful admission proves exact membership relative to independent
ordinary roots and dependency facts. Missing rows cannot admit an image. -/
theorem validate_exact [DecidableEq α] {reference : Table α} {edge : Graph α}
    {roots witness : List α} (exactRows : Exact reference edge)
    (accepted : validate reference roots witness = true) :
    witness.Nodup ∧ ∀ node, node ∈ witness ↔ Required roots edge node := by
  simp only [validate, Bool.and_eq_true, decide_eq_true_eq] at accepted
  obtain ⟨⟨⟨noDuplicates, rootsKept⟩, closed⟩, justifiedOrder⟩ := accepted
  refine ⟨noDuplicates, fun node => ⟨?_, ?_⟩⟩
  · exact justified_required exactRows (by simp) justifiedOrder node
  · exact required_least (closed_admits exactRows rootsKept closed)

/-- A witness cannot hide loads performed by the implementation. The observed
list must match the witness in both directions, irrespective of load order. -/
def validateLoads [DecidableEq α] (reference : Table α) (roots witness observed : List α) :
    Bool :=
  validate reference roots witness && observed.all witness.contains &&
    witness.all observed.contains

theorem validateLoads_exact [DecidableEq α] {reference : Table α} {edge : Graph α}
    {roots witness observed : List α} (exactRows : Exact reference edge)
    (accepted : validateLoads reference roots witness observed = true) :
    ∀ node, node ∈ observed ↔ Required roots edge node := by
  simp only [validateLoads, Bool.and_eq_true] at accepted
  obtain ⟨⟨valid, noExtraLoads⟩, noMissingLoads⟩ := accepted
  intro node
  rw [← (validate_exact exactRows valid).2 node]
  exact ⟨fun h => List.contains_iff_mem.mp (List.all_eq_true.mp noExtraLoads node h),
    fun h => List.contains_iff_mem.mp (List.all_eq_true.mp noMissingLoads node h)⟩


open Effects

/-- Validate the touched images and the effect schedule at the same demand
boundary. Use independently obtained ordinary roots, rows and image actions.
The candidate provides its witness, and the loader supplies the observation. -/
def qualifyImages (reference : Table ImageIdentity) (roots : List ImageIdentity)
    (success failure : List Nat) (ordinary : List ImageGroup)
    (witness observed : List ImageIdentity) : Option (List ImageGroup) :=
  if validateLoads reference roots witness observed then
    (checkImagePlan success failure ordinary witness).filter
      (fun selected => decide (observed = selected.map (·.identity)))
  else none

theorem qualified_images {reference : Table ImageIdentity} {edge : Graph ImageIdentity}
    {roots witness observed : List ImageIdentity} {success failure : List Nat}
    {ordinary selected : List ImageGroup}
    (exactRows : Exact reference edge) (unknownEffect : UnknownEffect) (store : Store)
    (admitted : qualifyImages reference roots success failure ordinary witness observed =
      some selected) :
    (∀ image, image ∈ observed ↔ Required roots edge image) ∧
    observed = selected.map (·.identity) ∧
    SameResult success failure (execute unknownEffect store (imageActions ordinary))
      (execute unknownEffect store (imageActions selected)) := by
  unfold qualifyImages at admitted
  split at admitted
  next valid =>
    have checked := Option.filter_eq_some_iff.mp admitted
    exact ⟨validateLoads_exact exactRows valid, of_decide_eq_true checked.2,
      checked_images_refine_ordinary unknownEffect store checked.1⟩
  next => contradiction

private theorem checkedSelection {success failure : List Nat} {ordinary selected : List ImageGroup}
    {witness observed : List ImageIdentity} {reference : Table ImageIdentity} {roots : List ImageIdentity}
    (admitted : qualifyImages reference roots success failure ordinary witness observed =
      some selected) :
    selected = selectImages witness ordinary := by
  unfold qualifyImages at admitted
  split at admitted
  next =>
    have checked := (Option.filter_eq_some_iff.mp admitted).1
    dsimp [checkImagePlan] at checked
    split at checked
    · contradiction
    · split at checked
      next => split at checked <;> simp_all
      next => contradiction
  next => contradiction

/-- When the manual control passes the same independent qualification, the
automatic and manual observations have the same physical image sequence. -/
theorem qualified_matches_manual {reference : Table ImageIdentity} {edge : Graph ImageIdentity}
    {roots automaticWitness manualWitness automaticObserved manualObserved : List ImageIdentity}
    {success failure : List Nat} {ordinary automatic manual : List ImageGroup}
    (exactRows : Exact reference edge) (unknownEffect : UnknownEffect) (store : Store)
    (autoPass : qualifyImages reference roots success failure ordinary automaticWitness
      automaticObserved = some automatic)
    (manualPass : qualifyImages reference roots success failure ordinary manualWitness
      manualObserved = some manual) :
    automaticObserved = manualObserved := by
  have auto := qualified_images exactRows unknownEffect store autoPass
  have hand := qualified_images exactRows unknownEffect store manualPass
  have autoChecked : validateLoads reference roots automaticWitness automaticObserved = true := by
    unfold qualifyImages at autoPass
    split at autoPass <;> simp_all
  have manualChecked : validateLoads reference roots manualWitness manualObserved = true := by
    unfold qualifyImages at manualPass
    split at manualPass <;> simp_all
  simp only [validateLoads, Bool.and_eq_true] at autoChecked manualChecked
  have sameWitness : ∀ id, id ∈ automaticWitness ↔ id ∈ manualWitness := by
    intro id
    have autoWitness := (validate_exact exactRows
      autoChecked.1.1).2 id
    have handWitness := (validate_exact exactRows
      manualChecked.1.1).2 id
    exact autoWitness.trans handWitness.symm
  rw [auto.2.1, hand.2.1, checkedSelection autoPass, checkedSelection manualPass]
  congr 1
  unfold selectImages
  apply List.filter_congr
  intro image _
  simp only [sameWitness image.identity]

namespace Counterexamples

def runtimeBody : ImageIdentity := ⟨1, 0, some 0⟩
def initializer : ImageIdentity := ⟨2, 0, some 0⟩
def phaseBody : ImageIdentity := ⟨3, 1, some 2⟩
def unusedBranch : ImageIdentity := ⟨3, 1, some 1⟩
def proxy : ImageIdentity := ⟨3, 0, none⟩
def unknownPhase : ImageIdentity := ⟨4, 1, some 1⟩

def ordinaryRows (id : ImageIdentity) : Option (List ImageIdentity) :=
  if id = runtimeBody then some [initializer]
  else if id = phaseBody then some [runtimeBody]
  else if id = initializer || id = unusedBranch || id = proxy then some []
  else none

def compilerMissingEdge (id : ImageIdentity) : Option (List ImageIdentity) :=
  if id = runtimeBody then some [] else ordinaryRows id

def compilerExtraEdge (id : ImageIdentity) : Option (List ImageIdentity) :=
  if id = runtimeBody then some [initializer, unusedBranch] else ordinaryRows id

def ordinaryStartup : List ImageGroup :=
  [⟨unusedBranch, []⟩, ⟨phaseBody, []⟩, ⟨initializer, [.put 0 1, .capture 1 0]⟩,
   ⟨runtimeBody, [.put 0 2, .observe 1]⟩]

def nameLookup : List ImageIdentity := [runtimeBody, initializer]
def transformerValue : List ImageIdentity := [phaseBody, runtimeBody, initializer]

#guard validate ordinaryRows [runtimeBody] nameLookup
#guard validate ordinaryRows [phaseBody] transformerValue
-- Reading a transformer is a demand even when there is no macro call.
#guard !validate ordinaryRows [phaseBody] nameLookup
-- A candidate can pass its own graph while omitting a real initialization edge.
#guard validate compilerMissingEdge [runtimeBody] [runtimeBody]
#guard !validate ordinaryRows [runtimeBody] [runtimeBody]
-- A candidate can also justify a useless import by manufacturing an edge.
#guard validate compilerExtraEdge [runtimeBody] (nameLookup ++ [unusedBranch])
#guard !validate ordinaryRows [runtimeBody] (nameLookup ++ [unusedBranch])
#guard !validate ordinaryRows [unknownPhase] [unknownPhase]
#guard !validate ordinaryRows [runtimeBody] (nameLookup ++ [initializer])
-- Eager loading can leave the receipt intact and still miss the startup target.
#guard !validateLoads ordinaryRows [runtimeBody] nameLookup (nameLookup ++ [phaseBody])
#guard !validateLoads ordinaryRows [runtimeBody] nameLookup (nameLookup ++ [proxy])
#guard !validateLoads ordinaryRows [runtimeBody] nameLookup [runtimeBody]
-- Distinct startup decisions must also preserve ordinary initialization effects.
#guard (qualifyImages ordinaryRows [runtimeBody] [0] [] ordinaryStartup nameLookup
  [initializer, runtimeBody]).isSome
#guard (qualifyImages ordinaryRows [phaseBody] [0] [] ordinaryStartup transformerValue
  [phaseBody, initializer, runtimeBody]).isSome
#guard (qualifyImages ordinaryRows [phaseBody] [0] [] ordinaryStartup transformerValue
  [initializer, runtimeBody, phaseBody]).isNone
#guard (qualifyImages compilerMissingEdge [runtimeBody] [0] [] ordinaryStartup [runtimeBody]
  [runtimeBody]).isNone

-- Exhaust the directed graphs on three vertices, every choice of roots and
-- every observed subset. The oracle propagates reachability synchronously
-- for three rounds. The planner instead traverses rows on demand.
def vertices : List Nat := [0, 1, 2]

def rowsFromBits (edges : Nat) (node : Nat) : Option (List Nat) :=
  if node < 3 then some (vertices.filter fun target => edges.testBit (3 * node + target))
  else none

def rootsFromBits (mask : Nat) : List Nat :=
  vertices.filter mask.testBit

def expandAll (edges : Nat) (needed : List Nat) : List Nat :=
  vertices.filter fun child =>
    needed.contains child || needed.any (fun parent => edges.testBit (3 * parent + child))

def checkSmallScope (edges mask : Nat) : Bool :=
  let roots := rootsFromBits mask
  let reference := rowsFromBits edges
  let expected := vertices.foldl (fun needed _ => expandAll edges needed) roots
  match plan reference 3 roots with
  | none => false
  | some result =>
    let witness := result.reverse
    (List.range 8).all fun observed =>
      let actual := rootsFromBits observed
      validateLoads reference roots witness actual == (actual == expected)

#guard (List.range 512).all fun edges => (List.range 8).all (checkSmallScope edges)

end Counterexamples

end ScopeCertificate

namespace NativeReplay

/-- Observations are ordered within each request. The itinerary comes from the
test workload, independently of the optimizer and both runtime captures. -/
structure Checkpoint (RequestId Event : Type) where
  request : RequestId
  events : List Event
  deriving DecidableEq, Repr

structure Run (RequestId Event : Type) where
  checkpoints : List (Checkpoint RequestId Event)
  exitCode : Option Nat
  deriving DecidableEq, Repr

def checkpointShape (kind : Event → Kind) (checkpoint : Checkpoint RequestId Event) :
    Checkpoint RequestId Kind :=
  ⟨checkpoint.request, checkpoint.events.map kind⟩

def checkpointsMatch [DecidableEq RequestId] [DecidableEq Event] [DecidableEq Kind]
    (kind : Event → Kind) (itinerary : List (Checkpoint RequestId Kind)) (ordinary observed : List (Checkpoint RequestId Event)) : Bool :=
  decide (itinerary ≠ [] ∧ ordinary.map (checkpointShape kind) = itinerary ∧ observed = ordinary)

def runMatches [DecidableEq RequestId] [DecidableEq Event] [DecidableEq Kind]
    (kind : Event → Kind) (itinerary : List (Checkpoint RequestId Kind))
    (expectedExit : Nat) (ordinary observed : Run RequestId Event) : Bool :=
  checkpointsMatch kind itinerary ordinary.checkpoints observed.checkpoints &&
    decide (ordinary.exitCode = some expectedExit ∧ observed.exitCode = some expectedExit)

theorem runMatches_sound [DecidableEq RequestId] [DecidableEq Event] [DecidableEq Kind]
    {kind : Event → Kind} {itinerary : List (Checkpoint RequestId Kind)} {expectedExit : Nat} {ordinary observed : Run RequestId Event}
    (accepted : runMatches kind itinerary expectedExit ordinary observed = true) :
    itinerary ≠ [] ∧ observed.checkpoints.map (checkpointShape kind) = itinerary ∧
      observed.checkpoints = ordinary.checkpoints ∧
      observed.exitCode = some expectedExit := by
  simp only [runMatches, checkpointsMatch, Bool.and_eq_true, decide_eq_true_eq] at accepted
  obtain ⟨⟨nonempty, full, same⟩, _, exited⟩ := accepted
  exact ⟨nonempty, same ▸ full, same, exited⟩

open Effects ScopeCertificate

/-- Physical minimality and an independent ordinary execution are both checked.
The observed image inventory belongs to the demand boundary being qualified. -/
def qualifyReplay [DecidableEq RequestId] [DecidableEq Event] [DecidableEq Kind]
    (kind : Event → Kind) (itinerary : List (Checkpoint RequestId Kind))
    (expectedExit : Nat) (ordinary observed : Run RequestId Event)
    (reference : Table ImageIdentity) (roots : List ImageIdentity) (success failure : List Nat)
    (images : List ImageGroup) (witness loaded : List ImageIdentity) : Option (List ImageGroup) :=
  if runMatches kind itinerary expectedExit ordinary observed then
    qualifyImages reference roots success failure images witness loaded
  else none

theorem qualifyReplay_sound [DecidableEq RequestId] [DecidableEq Event] [DecidableEq Kind]
    {kind : Event → Kind} {itinerary : List (Checkpoint RequestId Kind)} {expectedExit : Nat} {ordinary observed : Run RequestId Event}
    {reference : Table ImageIdentity} {edge : Graph ImageIdentity}
    {roots witness loaded : List ImageIdentity} {success failure : List Nat}
    {images selected : List ImageGroup}
    (exactRows : Exact reference edge) (unknownEffect : UnknownEffect) (store : Store)
    (accepted : qualifyReplay kind itinerary expectedExit ordinary observed reference roots
      success failure images witness loaded = some selected) :
    observed.checkpoints.map (checkpointShape kind) = itinerary ∧
      observed.checkpoints = ordinary.checkpoints ∧ observed.exitCode = some expectedExit ∧
      (∀ image, image ∈ loaded ↔ Required roots edge image) ∧
      loaded = selected.map (·.identity) ∧
      SameResult success failure (execute unknownEffect store (imageActions images))
        (execute unknownEffect store (imageActions selected)) := by
  unfold qualifyReplay at accepted
  split at accepted
  next runtimeMatched =>
    obtain ⟨_, itineraryMatches, same, exited⟩ := runMatches_sound runtimeMatched
    exact ⟨itineraryMatches, same, exited, qualified_images exactRows unknownEffect store accepted⟩
  next => contradiction

end NativeReplay

namespace NativePlacement

/-- A logical module and its entry point remain separate from file placement. -/
structure Entry (Member Image Link : Type) where
  member : Member
  image : Image
  linker : Link

def Unambiguous (entries : List (Entry Member Image Link)) : Prop :=
  ∀ a ∈ entries, ∀ b ∈ entries,
    a.image = b.image → a.linker = b.linker → a.member = b.member

def resolve [DecidableEq Image] [DecidableEq Link]
    (entries : List (Entry Member Image Link)) (image : Image) (linker : Link) :
    Option (Entry Member Image Link) :=
  entries.find? fun entry => decide (entry.image = image ∧ entry.linker = linker)

theorem resolves_same_member [DecidableEq Image] [DecidableEq Link]
    {entries : List (Entry Member Image Link)} (unique : Unambiguous entries)
    {requested actual : Entry Member Image Link}
    (requestedMem : requested ∈ entries)
    (found : resolve entries requested.image requested.linker = some actual) :
    actual.member = requested.member := by
  unfold resolve at found
  have sameRoute : actual.image = requested.image ∧ actual.linker = requested.linker :=
    of_decide_eq_true (List.find?_some (p := fun (entry : Entry Member Image Link) =>
      decide (entry.image = requested.image ∧ entry.linker = requested.linker)) found)
  exact unique actual (List.mem_of_find?_eq_some found) requested requestedMem
    sameRoute.1 sameRoute.2

/-- Identity is observed on the opened image used to obtain the entry point.
The model assumes that artifact stays bound through the loader's publication. -/
structure Artifact (Image : Type) where
  generation : Nat
  image : Image
  deriving DecidableEq, Repr

def selectOpened [DecidableEq Image] (expected opened : Artifact Image) :
    Option (Artifact Image) :=
  if opened = expected then some opened else none

theorem admitted_open_has_expected_identity [DecidableEq Image]
    {expected opened used : Artifact Image} (selected : selectOpened expected opened = some used) :
    used = expected := by
  unfold selectOpened at selected
  split at selected
  next same =>
    cases selected
    exact same
  next => contradiction

theorem replacement_before_open_falls_back [DecidableEq Image]
    {expected opened : Artifact Image} (changed : opened.generation ≠ expected.generation) :
    selectOpened expected opened = none := by
  have different : opened ≠ expected := fun same =>
    changed (congrArg Artifact.generation same)
  simp [selectOpened, different]

/-- A deferred provider need not be opened at the import checkpoint. Its
installed identity must match the plan, and the selected generation must
remain stable until the last deferred lookup. -/
def admitDeferral [DecidableEq Image] (sealed : Bool)
    (expected installed : List (Artifact Image)) : Bool :=
  sealed && decide (installed = expected)

theorem deferred_lookups_use_expected [DecidableEq Image]
    {sealed : Bool} {expected installed atDemand : List (Artifact Image)}
    (accepted : admitDeferral sealed expected installed = true)
    (retained : sealed = true → atDemand = installed) :
    atDemand = expected := by
  have valid : sealed = true ∧ installed = expected := by
    simpa [admitDeferral] using accepted
  exact (retained valid.1).trans valid.2

theorem mutable_generation_uses_ordinary [DecidableEq Image]
    (expected installed : List (Artifact Image)) :
    admitDeferral false expected installed = false := by
  rfl

section
private def plannedProvider : Artifact Nat := ⟨1, 10⟩
private def sameGenerationReplacement : Artifact Nat := ⟨1, 20⟩

#guard admitDeferral true [plannedProvider] [plannedProvider]
#guard !admitDeferral false [plannedProvider] [plannedProvider]
#guard !admitDeferral true [plannedProvider] [sameGenerationReplacement]
end

/-- Newly mapped images are charged once, even if several distinct entries
execute. This is a footprint for a trace with a known initial resident set. -/
def newImages [BEq Image] (placement : Member → Image) (resident : List Image)
    (loadOrder : List Member) : List Image :=
  ((loadOrder.map placement).eraseDups).filter fun image => !(resident.contains image)

theorem new_image_iff [DecidableEq Image]
    (placement : Member → Image) (resident : List Image) (loadOrder : List Member) (image : Image) :
    image ∈ newImages placement resident loadOrder ↔
      (∃ member ∈ loadOrder, placement member = image) ∧ image ∉ resident := by
  simp [newImages, List.mem_eraseDups]

theorem placement_preserves_activation_order (placement : Member → Image) (loadOrder : List Member) :
    (loadOrder.map (fun member => (member, placement member))).map Prod.fst = loadOrder := by
  induction loadOrder with
  | nil => rfl
  | cons member rest ih => simp [ih]

def physicalWork [BEq Image] (placement : Member → Image) (resident : List Image)
    (loadOrder : List Member) (weight : Image → Nat) : Nat :=
  scheduledWork (newImages placement resident loadOrder) weight

/-- For the same logical schedule, native image work and plan overhead decide
the modeled comparison. Each term needs a separate bound from measurements. -/
theorem cost_break_even (logical packed original overhead : Nat) :
    logical + (packed + overhead) ≤ logical + original ↔ packed + overhead ≤ original := by
  omega

/-- The first checkpoint leaves all mapped images resident for the second.
    Use an independent resident snapshot for each competing placement. -/
def laterImages [BEq Image] (placement : Member → Image) (resident : List Image)
    (first later : List Member) : List Image :=
  newImages placement (resident ++ newImages placement resident first) later

theorem later_image_iff [DecidableEq Image]
    (placement : Member → Image) (resident : List Image)
    (first later : List Member) (image : Image) :
    image ∈ laterImages placement resident first later ↔
      (∃ member ∈ later, placement member = image) ∧
        image ∉ resident ∧ ¬ (∃ member ∈ first, placement member = image) := by
  classical
  simp only [laterImages, new_image_iff, List.mem_append]
  by_cases present : image ∈ resident <;> simp [present]

theorem checkpoints_partition_new_images [DecidableEq Image]
    (placement : Member → Image) (resident : List Image)
    (first later : List Member) (image : Image) :
    image ∈ newImages placement resident (first ++ later) ↔
      image ∈ newImages placement resident first ∨
        image ∈ laterImages placement resident first later := by
  simp only [later_image_iff, new_image_iff, List.mem_append]
  have member_append :
      (∃ member, (member ∈ first ∨ member ∈ later) ∧ placement member = image) ↔
        (∃ member ∈ first, placement member = image) ∨
          (∃ member ∈ later, placement member = image) := by
    constructor
    · rintro ⟨member, inFirst | inLater, located⟩
      · exact Or.inl ⟨member, inFirst, located⟩
      · exact Or.inr ⟨member, inLater, located⟩
    · rintro (⟨member, inFirst, located⟩ | ⟨member, inLater, located⟩)
      · exact ⟨member, Or.inl inFirst, located⟩
      · exact ⟨member, Or.inr inLater, located⟩
  classical
  rw [member_append]
  by_cases mapsFirst : ∃ member ∈ first, placement member = image <;> simp [mapsFirst]

theorem checkpoint_cannot_recharge [DecidableEq Image]
    (placement : Member → Image) (resident : List Image)
    (first later : List Member) (image : Image)
    (already : image ∈ newImages placement resident first) :
    image ∉ laterImages placement resident first later := by
  intro again
  exact ((later_image_iff placement resident first later image).mp again).2.2
    ((new_image_iff placement resident first image).mp already).1

/-- Both limits are cumulative. Slack at receipt cannot buy a regression
    at import. The caller supplies bounds that include admission work and
    uses the appropriate starting residency for each arm. -/
def withinCheckpointBounds (early later earlyLimit receiptLimit : Nat) : Bool :=
  early ≤ earlyLimit && early + later ≤ receiptLimit

theorem within_checkpoint_bounds (early later earlyLimit receiptLimit : Nat) :
    withinCheckpointBounds early later earlyLimit receiptLimit = true ↔
      early ≤ earlyLimit ∧ early + later ≤ receiptLimit := by
  simp [withinCheckpointBounds]

section
private def sharedImage : Nat → Nat
  | 1 | 3 => 10
  | _ => 20

-- Import two modules, then activate a third member of an already mapped image.
#guard newImages sharedImage [] [1, 2] == [10, 20]
#guard laterImages sharedImage [] [1, 2] [3] == []
#guard newImages sharedImage [10] [1, 2] == [20]
-- A cumulative receipt win can conceal an import regression.
#guard !withinCheckpointBounds 8 1 7 10
-- Zero new images can still lose to admission overhead.
#guard !withinCheckpointBounds 1 0 0 0
end

/-- Attribute a physical image to the first checkpoint that maps it in this
process. Each checkpoint retains its own ordered logical activation list. -/
def checkpointImages [BEq Image] (placement : Member → Image)
    (resident : List Image) : List (List Member) → List (List Image)
  | [] => []
  | members :: later =>
    let opened := newImages placement resident members
    opened :: checkpointImages placement (resident ++ opened) later

theorem checkpoint_images_exact [DecidableEq Image]
    (placement : Member → Image) (resident : List Image)
    (checkpoints : List (List Member)) (image : Image) :
    image ∈ (checkpointImages placement resident checkpoints).flatten ↔
      image ∈ newImages placement resident checkpoints.flatten := by
  induction checkpoints generalizing resident with
  | nil => simp [checkpointImages, newImages]
  | cons first later ih =>
    simpa only [checkpointImages, List.flatten_cons, List.mem_append, ih, laterImages] using
      (checkpoints_partition_new_images placement resident first later.flatten image).symm

theorem checkpoint_images_disjoint [DecidableEq Image]
    (placement : Member → Image) (resident : List Image)
    (checkpoints : List (List Member)) :
    (checkpointImages placement resident checkpoints).Pairwise
      (fun earlier later => ∀ image ∈ earlier, image ∉ later) := by
  induction checkpoints generalizing resident with
  | nil => simp [checkpointImages]
  | cons first later ih =>
    simp only [checkpointImages, List.pairwise_cons]
    constructor
    · intro bucket inBuckets image firstSeen laterSeen
      have inFlatten := List.mem_flatten.mpr ⟨bucket, inBuckets, laterSeen⟩
      have newly := (checkpoint_images_exact placement
        (resident ++ newImages placement resident first) later image).mp inFlatten
      exact ((new_image_iff _ _ _ _).mp newly).2
        (List.mem_append.mpr (Or.inr firstSeen))
    · exact ih _

/-- Check every cumulative deadline, with each incremental cost including
admission, logical work and physical work for that interval. -/
def fitsTimeline (elapsed : Nat) : List (Nat × Nat) → Bool
  | [] => true
  | (cost, limit) :: later =>
    let cumulative := elapsed + cost
    cumulative ≤ limit && fitsTimeline cumulative later

theorem fits_timeline_append (elapsed : Nat) (before after : List (Nat × Nat)) :
    fitsTimeline elapsed (before ++ after) = true ↔
      fitsTimeline elapsed before = true ∧
        fitsTimeline (before.foldl (fun time entry => time + entry.1) elapsed) after = true := by
  induction before generalizing elapsed with
  | nil => simp [fitsTimeline]
  | cons entry rest ih =>
    rcases entry with ⟨cost, limit⟩
    simp [fitsTimeline, ih, and_assoc]

section
private def overlappingPlacement : Nat → Nat
  | 1 | 3 => 10
  | 2 | 4 => 20
  | _ => 30

-- Two later scopes enter different members of already resident images.
#guard checkpointImages overlappingPlacement [] [[1], [2], [3, 4, 5]] ==
  [[10], [20], [30]]
-- Each process starts with its own snapshot of prewarmed images.
#guard checkpointImages overlappingPlacement [20] [[1], [2], [3, 4, 5]] ==
  [[10], [], [30]]
#guard fitsTimeline 0 [(4, 4), (2, 6), (1, 7)]
#guard !fitsTimeline 0 [(4, 4), (3, 6), (0, 7)]
end

end NativePlacement

end RuntimeImportDemand
