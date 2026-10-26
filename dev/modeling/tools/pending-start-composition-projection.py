"""Restricted formal projection; JSON parser and this emitter remain in the trusted base."""
def generate(ir,refs,startup=False):
 assert not ir.get("errors") and len(ir["modules"])==1
 m=ir["modules"][0];assert m["name"]==("thread_thunk_root" if startup else "pending_start_composition")
 ds=m["declarations"];assert len({d["name"] for d in ds})==len(ds)
 assert all(d["kind"] in ["var","def","typedef"] for d in ds)
 defs={d["name"]:d for d in ds};v=defs["s"];assert v["kind"]=="var"
 fields={x["fieldName"]:x["fieldType"]["kind"] for x in defs["State"]["type"]["fields"]["fields"]}
 assert fields==({'parent': 'bool', 'registered': 'bool', 'future': 'bool', 'launched': 'bool', 'started': 'bool', 'syncDone': 'bool', 'entered': 'bool', 'unknown': 'bool', 'aborted': 'bool', 'rawUsed': 'bool', 'epoch': 'int', 'slot': 'int', 'localStamp': 'int'} if startup else {'phase': 'int', 'round': 'int', 'sourceA': 'bool', 'sourceB': 'bool', 'pendingA': 'bool', 'pendingB': 'bool', 'contextA': 'bool', 'contextB': 'bool', 'ackA': 'bool', 'ackB': 'bool', 'launchA': 'bool', 'launchB': 'bool', 'startA': 'bool', 'readyA': 'bool', 'memberA': 'bool', 'failedB': 'bool', 'doneB': 'bool', 'unknownB': 'bool', 'scanLease': 'bool', 'viewSourceA': 'bool', 'viewSourceB': 'bool', 'viewPendingA': 'bool', 'viewPendingB': 'bool', 'viewContextA': 'bool', 'viewContextB': 'bool'})
 def state(e):
  assert e["kind"]=="name" and e["name"]=="s"
  row=ir["table"][str(e["id"])];assert row["id"]==v["id"] and row["kind"]=="var" and row["depth"]==0
 def field(e):
  assert e["kind"]=="app" and e["opcode"]=="field" and len(e["args"])==2
  state(e["args"][0]);f=e["args"][1];assert f["kind"]=="str" and f["value"] in fields
  return f["value"]
 def integer(e):
  if e["kind"]=="int":assert type(e["value"]) is int;return "("+str(e["value"])+")"
  if e.get("opcode")=="field":f=field(e);assert fields[f]=="int";return "q."+f
  assert e.get("opcode") in ["iadd","isub"] and len(e["args"])==2
  a,b=e["args"];return "("+integer(a)+(" + " if e["opcode"]=="iadd" else " - ")+integer(b)+")"
 def guard(e):
  if e["kind"]=="bool":return "True" if e["value"] else "False"
  if e.get("opcode")=="field":f=field(e);assert fields[f]=="bool";return "(q."+("«open»" if f=="open" else f)+"=true)"
  op=e["opcode"];a=e["args"]
  if op=="not":assert len(a)==1;return "(¬"+guard(a[0])+")"
  if op in ["eq","ilt","ilte","igt","igte"]:
   assert len(a)==2;return "("+integer(a[0])+{"eq":"=","ilt":"<","ilte":"≤","igt":">","igte":"≥"}[op]+integer(a[1])+")"
  raise AssertionError(op)
 def updates(e):
  if e["kind"]=="name":state(e);return []
  assert e["opcode"]=="with" and len(e["args"])==3
  old,k,val=e["args"];pairs=updates(old);assert k["kind"]=="str" and k["value"] in fields and k["value"] not in [p[0] for p in pairs]
  f=k["value"]
  if fields[f]=="bool":assert val["kind"]=="bool";value=str(val["value"]).lower()
  else:value=integer(val)
  return pairs+[(f,value)]
 stateType="StartupFlat" if startup else "PinFlat"
 out=["import PendingStartComposition","namespace PendingStartupAst" if startup else "namespace PendingStartAst","open PendingStartComposition DerivationReceiptEnvironment","set_option maxRecDepth 10000"]
 for name,stem in ([("enterFromHandle","Enter")] if startup else [("registerA","Register"),("adoptA","Adopt"),("rollbackB","Rollback")]):
  e=defs[name]["expr"];assert e["opcode"]=="actionAll";a=e["args"];last=a[-1]
  assert last["opcode"]=="assign" and len(last["args"])==2;state(last["args"][0])
  gs=[guard(x) for x in a[:-1]];us=updates(last["args"][1]);g=" ∧ ".join(gs)
  out += [f"def ir{stem}Guard (q : {stateType}) : Prop := "+g,f"def ir{stem}Next (q : {stateType}) := {{q with "+", ".join(k+":="+v for k,v in us)+"}",f"theorem {name}GuardMeaning (q : {stateType}) : ir{stem}Guard q ↔ PendingStartComposition.q{stem}Guard q := by simp [ir{stem}Guard,PendingStartComposition.q{stem}Guard,and_assoc]",f"theorem {name}NextMeaning (q : {stateType}) : ir{stem}Next q=PendingStartComposition.q{stem}Next q := rfl"]
 if not startup:out += ["def actualRows : List (Nat × Nat) := ["+",".join("("+str(r["occurrence"])+","+str(r["target"])+")" for r in refs)+"]", "theorem actualRowsChecked : tableCheck actualRows=true := by decide", "theorem actualEnvAgrees : Matches actualRows (buildEnv actualRows) := checkedEnvironment actualRows actualRowsChecked"]
 out += ["end PendingStartupAst" if startup else "end PendingStartAst"]
 return "\n".join(out)+"\n"
