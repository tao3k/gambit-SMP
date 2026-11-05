import PutObjsMoveGraph
open PutObjsMoveGraphAst PutObjsMoveGraph
def badGraph : Graph := ⟨rawNext initial,0,0,1201⟩
example : ¬ Encodes badGraph initial := by
 intro h
 simp only [Encodes] at h
 rcases h with ⟨ha,hb,hrest,hh,hd,hp⟩
 simp [badGraph,initial] at hh
example : Encodes badGraph initial := by simp [Encodes,badGraph,initial]
