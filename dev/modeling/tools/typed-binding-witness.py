"""Research admission checker for one pinned closed Quint JSON fragment, not a compiler."""
import json
class Refusal(ValueError): pass
def require(p,why):
 if not p:raise Refusal(why)
def read_json(text):
 def pairs(xs):
  result={}
  for k,v in xs:
   require(k not in result,"duplicate-json-key");result[k]=v
  return result
 return json.loads(text,object_pairs_hook=pairs,parse_constant=lambda s: (_ for _ in ()).throw(Refusal("nonfinite-json")))
def check(ir):
 require(ir.get("stage")=="typechecking","wrong-ir-stage")
 require(not ir.get("errors"),"diagnostics")
 require(len(ir["modules"])==1 and ir["modules"][0]["name"]=="map_frame_abi","module-scope")
 ds=ir["modules"][0]["declarations"];byid={};byn={};nodes={}
 def walk(v):
  if isinstance(v,dict):
   if "id" in v:
    n=v["id"];require(type(n) is int and n>=0,"non-natural-id");require(n not in nodes,"duplicate-syntax-id");nodes[n]=v
   for z in v.values():walk(z)
  elif isinstance(v,list):
   for z in v:walk(z)
 walk(ir["modules"][0])
 for d in ds:
  require(d["kind"] in ["typedef","var","def"],"unsupported-declaration")
  require(d["id"] not in byid and d["name"] not in byn,"duplicate-declaration")
  byid[d["id"]]=d;byn[d["name"]]=d
 vs=[d for d in ds if d["kind"]=="var"]
 require(len(vs)==1 and vs[0]["name"]=="s","state-variable")
 state=vs[0];sid=state["id"]
 selected=["initial","safe","init","capture","collect","reload","resume","returnShot","abiEdit","emit","compile","toolEdit","bind","releaseCaptured","step"]
 refs=[]
 def shape(v):
  if isinstance(v,dict):return {k:shape(z) for k,z in v.items() if k!="id"}
  if isinstance(v,list):return [shape(z) for z in v]
  return v
 def expr(v):
  require(isinstance(v,dict),"expression-shape")
  if v.get("kind")=="name":
   oid=v["id"];row=ir["table"].get(str(oid));require(isinstance(row,dict),"missing-reference")
   target=row.get("id");require(type(target) is int and target in byid,"unknown-target")
   d=byid[target]
   require({k:z for k,z in row.items() if k not in ["depth","typeAnnotation"]}=={k:z for k,z in d.items() if k not in ["depth","typeAnnotation"]},"lookup-body-mismatch")
   require("typeAnnotation" not in row or row["typeAnnotation"]==d.get("typeAnnotation"),"lookup-annotation-mismatch")
   require(row.get("depth")==0 and v["name"]==d["name"],"scope-or-spelling")
   require(d["kind"] in ["var","def"],"non-value-reference")
   require(d["kind"]!="var" or target==sid,"wrong-state-identity")
   vt=ir["types"].get(str(oid));dt=ir["types"].get(str(target))
   require(vt is not None and dt is not None and shape(vt)==shape(dt),"reference-type-mismatch")
   refs.append(dict(occurrence=oid,target=target,name=v["name"],kind=d["kind"],depth=row["depth"]))
  if v.get("kind")=="app":
   for a in v["args"]:expr(a)
  require(v.get("kind") in ["name","app","int","bool","str"],"unsupported-expression")
 for name in selected:
  require(name in byn,"missing-selected-definition");expr(byn[name]["expr"])
 return dict(stateDeclaration=sid,syntaxNodes=len(nodes),selectedDefinitions=len(selected),references=refs,allSelectedReferencesBound=True,jsonParserProved=False,referenceTableProducerProved=False,fullActionExtractionProved=False)
