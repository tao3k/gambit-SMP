"""Rejecting projection of the pinned map QNT typed-IR subset, for formal artifacts only."""
import json,hashlib
from pathlib import Path

def generate(ir,source_hash):
 assert not ir.get("errors") and len(ir["modules"])==1
 module=ir["modules"][0];assert module["name"]=="map_frame_abi"
 defs={d["name"]:d for d in module["declarations"] if d["kind"]=="def"}
 variables=[d for d in module["declarations"] if d["kind"]=="var"]
 assert len(variables)==1 and variables[0]["name"]=="s", "one state variable only"
 assert all(d["kind"] in ["typedef","var","def"] for d in module["declarations"]), "no imports or instances"
 init=defs["init"]["expr"]
 assert init["kind"]=="app" and init["opcode"]=="assign"
 assert [(x["kind"],x.get("name")) for x in init["args"]]==[("name","s"),("name","initial")], "exact initial assignment required"
 typ=next(d for d in module["declarations"] if d.get("name")=="State")["type"]
 assert typ["kind"]=="rec" and typ["fields"]["other"]["kind"]=="empty"
 fields={x["fieldName"]:x["fieldType"]["kind"] for x in typ["fields"]["fields"]}
 assert len(fields)==20 and set(fields.values())=={"int","bool"}
 names=["capture","collect","reload","resume","returnShot","abiEdit","emit","compile","toolEdit","bind","releaseCaptured"]
 def app(e,op,n=None):
  assert e["kind"]=="app" and e["opcode"]==op
  a=e["args"];assert n is None or len(a)==n;return a
 def field(e):
  s,k=app(e,"field",2);assert s["kind"]=="name" and s["name"]=="s" and k["kind"]=="str"
  f=k["value"];assert f in fields;return f
 def it(e):
  if e["kind"]=="int":return "(.lit ("+str(e["value"])+"))"
  if e.get("opcode")=="field":
   f=field(e);assert fields[f]=="int";return "(.get ."+f+")"
  a,b=app(e,"iadd",2);return "(.add "+it(a)+" "+it(b)+")"
 def bv(e):
  if e["kind"]=="bool":return "(.lit "+str(e["value"]).lower()+")"
  f=field(e);assert fields[f]=="bool";return "(.get ."+f+")"
 def conjunction(es):
  return fold("conj",[bt(e) for e in es],"(.truth (.lit true))")
 def fold(op,es,end):
  for e in reversed(es):end="(."+op+" "+e+" "+end+")"
  return end
 def bt(e):
  if e["kind"]=="bool" or e.get("opcode")=="field":return "(.truth "+bv(e)+")"
  op=e.get("opcode");a=e.get("args",[])
  if op=="not":assert len(a)==1;return "(.neg "+bt(a[0])+")"
  if op in ["and","or","implies"]:
   assert len(a)==2;return "(."+{"and":"conj","or":"disj","implies":"implies"}[op]+" "+bt(a[0])+" "+bt(a[1])+")"
  if op=="actionAll":return conjunction(a)
  if op=="eq":
   assert len(a)==2
   isbool=a[0]["kind"]=="bool" or (a[0].get("opcode")=="field" and fields[field(a[0])]=="bool")
   fn=bv if isbool else it;return "(.eq"+("B" if isbool else "I")+" "+fn(a[0])+" "+fn(a[1])+")"
  assert op in ["ilt","ilte","igte"] and len(a)==2,op
  left,right=(a[1],a[0]) if op=="igte" else (a[0],a[1])
  return "(."+("lt" if op=="ilt" else "le")+" "+it(left)+" "+it(right)+")"
 def updates(e):
  if e["kind"]=="name":assert e["name"]=="s";return []
  if e.get("opcode")=="Rec":
   args=e["args"];assert len(args)%2==0
   pairs=[(args[i]["value"],args[i+1]) for i in range(0,len(args),2) if args[i]["kind"]=="str"]
   assert len(pairs)*2==len(args) and set(k for k,v in pairs)==set(fields)
  else:
   base,k,v=app(e,"with",3);assert k["kind"]=="str";pairs=updates(base)+[(k["value"],v)]
  ks=[k for k,v in pairs];assert len(ks)==len(set(ks)),"duplicate update field"
  for k,v in pairs:assert k in fields
  return pairs
 def record(e):
  us=updates(e);return "["+", ".join("(."+("int" if fields[k]=="int" else "bool")+" ."+k+" "+(it(v) if fields[k]=="int" else bv(v))+")" for k,v in us)+"]"
 def atom(e):
  args=app(e,"actionAll");assigns=[x for x in args if x.get("opcode")=="assign"]
  assert len(assigns)==1 and args[-1] is assigns[0],"one terminal state assignment required"
  target,rhs=app(assigns[0],"assign",2);assert target["kind"]=="name" and target["name"]=="s"
  return "(.atom "+conjunction(args[:-1])+" "+record(rhs)+")"
 output=["import RetiOfdSemantics","namespace MapExpressionAst","open MapFrameAbi RetiOfdSemantics","-- GENERATED from official typed IR of SHA256 "+source_hash]
 output += ["def initialAst : List Update := "+record(defs["initial"]["expr"]),"def safeAst : BExpr := "+bt(defs["safe"]["expr"])]
 for name in names:output.append("def a_"+name+" : Action := "+atom(defs[name]["expr"]))
 step=app(defs["step"]["expr"],"actionAny");assert len(step)==12
 assert [e["name"] for e in step[:-1] if e["kind"]=="name"]==names
 output.append("def a_stutter : Action := "+atom(step[-1]))
 output.append("def stepAst : Action := "+fold("choice",["a_"+n for n in names],"a_stutter"))
 simp="runAction,evalB,evalBV,evalI,evalUpdates,applyUpdate,setI,setB,getI,getB,qStep,qGuard,qNext,and_assoc"
 for name in names+["stutter"]:
  output += ["theorem "+name+"Meaning (q q' : QState) : runAction a_"+name+" q q' ↔ qStep ."+name+" q q' := by", " simp [a_"+name+","+simp+"]"]
 output += ["theorem invariantMeaning (q : QState) : evalB safeAst q ↔ qSafe q := by simp [safeAst,evalB,evalBV,evalI,getI,getB,qSafe,and_assoc]",
 "theorem initialMeaning : evalUpdates initial initialAst initial=initial := by decide",
 "theorem stepMeaning (q q' : QState) : runAction stepAst q q' ↔ ∃ e : Event, qStep e q q' := by",
 " change ("+" ∨ ".join("runAction a_"+n+" q q'" for n in names+["stutter"])+") ↔ ∃ e : Event, qStep e q q'",
 " simp only ["+",".join(n+"Meaning" for n in names+["stutter"])+"]",
 " constructor",
 " · intro h; rcases h with "+"|".join("h" for _ in names+["stutter"]),
 "   all_goals first | exact ⟨Event.capture,h⟩ | exact ⟨Event.collect,h⟩ | exact ⟨Event.reload,h⟩ | exact ⟨Event.resume,h⟩ | exact ⟨Event.returnShot,h⟩ | exact ⟨Event.abiEdit,h⟩ | exact ⟨Event.emit,h⟩ | exact ⟨Event.compile,h⟩ | exact ⟨Event.toolEdit,h⟩ | exact ⟨Event.bind,h⟩ | exact ⟨Event.releaseCaptured,h⟩ | exact ⟨Event.stutter,h⟩",
 " · rintro ⟨e,h⟩; cases e <;> simp_all",
 "theorem astToNested (q q' : QState) (h : runAction stepAst q q') : ∃ e : Event, lStep e (alpha q) (alpha q') := by",
 " obtain ⟨e,step⟩ := (stepMeaning q q').mp h; exact ⟨e,forwardSimulation e q q' (alpha q) rfl step⟩",
 "theorem astPreserves (q q' : QState) (safe : evalB safeAst q) (h : runAction stepAst q q') : evalB safeAst q' := by",
 " obtain ⟨e,guard,next⟩ := (stepMeaning q q').mp h",
 " apply (invariantMeaning q').mpr; rw [next]; exact qPreserves e q ((invariantMeaning q).mp safe) guard",
 "def simultaneous : List Update := [.int .epoch (.add (.get .epoch) (.lit 1)),.int .loaded (.get .epoch)]",
 "theorem simultaneousReadsOld (q : QState) : (evalUpdates q simultaneous q).loaded=q.epoch := rfl",
 "end MapExpressionAst"]
 return "\n".join(output)+"\n",dict(fields=fields,actions=names,ignoredDeclarations=[n for n in defs if n not in names+["initial","safe","step","init"]],qntParserAndExtractorVerified=False)
