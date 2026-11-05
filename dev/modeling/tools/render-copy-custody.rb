require 'json'
m=JSON.parse(File.read('.cache/tasks/modern-c-frame-contract/cohort/copy-custody-model/native-projection.json'))
d="direction: right\n"
m['contracts'].each do |x|
 d<<x['id'].tr('-','_')+': '+JSON.generate(x['id']+': '+x['cSource'])+"\n"
 %w[quint lean].each do |method|
  artifact=x.fetch(method+'Artifact');node=File.basename(artifact).tr('.-','__')
  d<<node+': '+JSON.generate(artifact)+"\n"
  d<<x['id'].tr('-','_')+' -> '+node+': '+JSON.generate(method+' obligations')+"\n"
 end
end
m['edges'].each{|x|d<<x['producer'].tr('-','_')+' -> '+x['consumer'].tr('-','_')+': '+JSON.generate(x['obligation'])+"\n"}
d<<"sysml: SysML contracts and handoffs\nascent: ASCENT artifact-qualified evidence and dependency joins\nsource: Current Modern C source lock\nnative: Exact Bazel O1/O3 bootstrap and scoped native controls\nopen: \"OPEN: C simulation, complete root/writer coverage and pre-flip C planner; commit blocked\" {style.fill: \"#fff0dc\"}\nsysml -> ascent\nascent -> source\nascent -> native\n"
m['contracts'].each{|x|d<<x['id'].tr('-','_')+" -> open: C simulation remains open\n"}
File.write('dev/refactoring/modern-c/diagrams/copy-custody.d2',d)
