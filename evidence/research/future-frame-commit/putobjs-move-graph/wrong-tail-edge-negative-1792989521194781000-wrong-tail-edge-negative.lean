import PutObjsMoveGraph
open PutObjsMoveGraphAst PutObjsMoveGraph
def badGraph : Graph := ⟨(fun n => if n=1201 then 0 else rawNext initial n),402,0,1201⟩
example : ¬ Encodes badGraph initial := by
 intro h
 simp only [Encodes] at h
 rcases h with ⟨ha,hb,hrest,hh,hd,hp⟩
 simp [badGraph,initial] at hb
example : Encodes badGraph initial := by simp [Encodes,badGraph,initial]
