require 'json'
base = '.cache/tasks/modern-c-frame-contract/cohort/causal-architecture-model'
m = JSON.parse(File.read(base+'/native-projection.json'))
raise 'unexpected authority' unless m['arguments'].map { |a| a['id'] } == %w[exit work copy ffi release frames profile generation]
raise 'pressure mismatch' unless m['arguments'].all? { |a| a['id']==a['painId'] }
d = "direction: right\nvars: { d2-config: { layout-engine: elk } }\n"
d << "evidence: \"Historical failure / patch evidence\"\nsysml: \"SysML causal arguments and canonical owners\"\nascent: \"ASCENT: exact evidence + prerequisite gaps\"\n"
m['arguments'].each do |a|
  d << a['id']+': '+JSON.generate(a['id']+': '+a['responsibleModule'])+"\n"
  d << 'sysml -> '+a['id']+": conditional exclusion argument\n"
  d << a['id']+" -> ascent: C refinement / progress / retirement / benefit\n"
end
m['dependencies'].each { |e| d << e['prerequisite']+' -> '+e['dependent']+': '+JSON.generate(e['why'])+"\n" }
d << "evidence -> sysml\nformal: \"QNT finite histories + conditional Lean laws\"\nnative: \"Exact-source bootstrap / roots / multi-shot / GC\"\nformal -> ascent\nnative -> ascent\nopen: \"OPEN: composed C refinement, full inventories and measured net benefit\" { style.fill: \"#fff0dc\" }\nascent -> open\n"
File.write('dev/refactoring/modern-c/diagrams/causal-architecture.d2',d)
safe = ->s { s.to_s.gsub('|','/').gsub("\n",' ') }
table = "| Pressure | Gates affected (not solved) | Mechanism | Present scope | Gain | Added cost | Refutation |\n|---+---+---+---+---+---+---|\n"
m['arguments'].each { |a| table << '| '+[a['id'],a['gates'],a['rule'],a['present'],a['gain'],a['cost'],a['refutation']].map { |s| safe.call(s) }.join(' | ')+" |\n" }
path='dev/refactoring/modern-c/causal-architecture.org'
text=File.read(path)
raise 'missing Org view' unless text.include?('#+BEGIN: sysml-view :kind causal-architecture')
text.sub!(/(\#\+BEGIN: sysml-view :kind causal-architecture[^\n]*\n).*?(\#\+END:)/m,"\\1"+table+"\\2")
File.write(path,text)
puts JSON.generate(arguments:m['arguments'].size,dependencies:m['dependencies'].size,gateAssociations:m['arguments'].sum { |a| a['gates'].split(';').size })
