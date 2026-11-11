require 'json'
require 'fileutils'

projection, admission, org, diagram = ARGV
raise 'projection, admission, Org and D2 paths required' unless diagram
p = JSON.parse(File.read(projection))
a = JSON.parse(File.read(admission))
raise 'source identity mismatch' unless p.fetch('candidateTree') == a.fetch('candidateTree')
needs = p.keys.grep(/\.gate\.id$/).map { |k| k.delete_suffix('.gate.id') }
covered = a.fetch('answers').fetch('commitCovered').map { |row| row[1] }
missing = needs.reject { |n| covered.include?(p.fetch(n + '.id')) }
raise 'coverage mismatch' unless needs.size == a.fetch('requiredObservations') && missing.size == a.fetch('missing').size
cell = ->s { s.to_s.gsub('|', '/') }
body = "#+TITLE: #{p.fetch('unit.id')} — Derived Closure Matrix\n#+LANGUAGE: en\n#+OPTIONS: toc:nil num:nil\n\n"
body << "* Exact selected source\n:PROPERTIES:\n:AUTHORITY: native SysML and actual ASCENT observations\n"
body << ":CANDIDATE_TREE: #{a.fetch('candidateTree')}\n:END:\n\n"
body << "This view is generated; requirements remain in SysML. Runtime and twelve-SMP admission are not inferred.\n\n"
body << "| Obligation | Gate | Method | Observed result | Required scope |\n|---+---+---+---+---|\n"
needs.each do |n|
  id = p.fetch(n + '.id')
  fields = [id, p.fetch(n + '.gate.id'), p.fetch(n + '.method'), covered.include?(id) ? 'PASS' : 'OPEN', p.fetch(n + '.scope')]
  body << '| ' + fields.map(&cell).join(' | ') + " |\n"
end
body << "\n| Gate | Result |\n|---+---|\n"
%w[tests learning process models questions].each do |g|
  body << "| #{g} | #{a.fetch('gateReady').include?(g) ? 'CLOSED for this unit' : 'OPEN'} |\n"
end
body << "\n* Benefit and cost boundary\n\n#{p.fetch('benefit')}\n\n#{p.fetch('addedCost')}\n\n#{p.fetch('validationBoundary')}\n"
FileUtils.mkdir_p(File.dirname(org))
File.write(org, body)
d = "direction: down\nvars: { d2-config: { layout-engine: elk } }\n"
d << 'authority: ' + JSON.generate('Native SysML: ' + p.fetch('unit.id')) + "\n"
d << 'driver: ' + JSON.generate('Ordered source inclusion; one translation unit') + "\n"
d << "parts: {\n  label: \"Responsibility payloads; shared macro/static scope\"\n  grid-columns: 4\n"
p.keys.grep(/^fragments\.\d+\.file$/).sort_by { |k| k.split('.')[1].to_i }.each do |k|
  i = k.split('.')[1]
  d << "  p#{i}: " + JSON.generate(p.fetch(k)) + "\n"
end
d << "}\nchecks: \"Reconstruction / compiler equivalence / consumers / Make edges\"\n"
d << 'admission: ' + JSON.generate("ASCENT: #{a.fetch('observed')}/#{a.fetch('requiredObservations')} observations; #{a.fetch('gateReady').size}/5 gates") + "\n"
d << "later: \"OPEN: header consumer closure / role ownership / root migration / GC / FFI\"\n"
d << "authority -> driver\ndriver -> parts\nparts -> checks\nauthority -> admission\nchecks -> admission\nadmission -> later: no runtime acceptance inferred\n"
FileUtils.mkdir_p(File.dirname(diagram))
File.write(diagram, d)
puts JSON.generate(obligations: needs.size, missing: missing.size, gates: a.fetch('gateReady').size)
