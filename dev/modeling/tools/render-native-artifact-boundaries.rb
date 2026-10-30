require 'json'; require 'digest'
path = ARGV.fetch(0)
m = JSON.parse(File.read(path))
raise 'complete native projection required' unless m.fetch('duties').size == 9 && m.fetch('boundaries').size == 3
raise 'complete role/constructor projection required' unless m.fetch('roles').size == 5 && m.fetch('constructors').size == 1
fields = %w[fidelityId dependsOn researchStatus sourcePath sourceRanges concreteBoundary encodingRule cleanControl failureMapping reflectionDuty benefitBoundary leanSupport quintSupport]
cell = ->v { v.to_s.gsub('|', '\\vert{}').gsub("\n", ' ') }
rows = m['duties'].map { |d| '| ' + fields.map { |f| cell.call(d.fetch(f)) }.join(' | ') + ' |' }
table = "| Duty | Dependencies | Status | Evidence | Ranges | Boundary | Contract | Issue / preserve | Refusal / custody | Open refinement | Benefit / cost | Lean | QNT |\n|---+---+---+---+---+---+---+---+---+---+---+---+---|\n" + rows.join("\n")
table += "\n\n| Role | Source anchors | Scheme owner | Native contract | Retiring role | Retirement condition | Benefit / cost | Obligations | Dependencies |\n|---+---+---+---+---+---+---+---+---|\n"
m['roles'].each { |r| table += '| ' + %w[roleId sourceRefs schemeOwner nativeContract retiringRole retirementCondition gainAndCost obligationRefs dependsOn].map { |f| cell.call(r.fetch(f)) }.join(' | ') + " |\n" }
org = 'dev/architecture/toolchain/macos-development-map.org'
s = File.read(org)
raise 'missing existing SysML view' unless s.sub!(/(\#\+BEGIN: sysml-view :kind macos-development[^\n]*\n).*?(\n\#\+END:)/m) { $1 + table + $2 }
marker = '* Native artifact boundary projection'
s = s.split(marker).first
s += "\n#{marker}\n:PROPERTIES:\n:MODEL_AUTHORITY: GambitDarwinDevelopment::ArtifactBoundary\n:NATIVE_PROJECTION_SHA256: #{Digest::SHA256.file(path).hexdigest}\n:END:\n\n"
s += "#+BEGIN: sysml-view :kind native-artifact-boundaries :source architecture/toolchain/models/sysml/macos-development.sysml\n"
s += "| Role | Invalidators | Downstream | Complete input projection | Reuse condition | Refusal | Removable work |\n|---+---+---+---+---+---+---|\n"
m['boundaries'].each { |b| s += '| ' + %w[role invalidators downstream inputProjection reuseCondition refusal workRemoved].map { |f| cell.call(b.fetch(f)) }.join(' | ') + " |\n" }
s += "#+END:\n\nThis projection grants no reuse permit. Existing QNT and Lean retain distinct history and refinement obligations; no duplicate model was added.\n"
s += "\n* Mutable producer contract\n#+BEGIN: sysml-view :kind mutable-producer :source architecture/toolchain/models/sysml/macos-development.sysml\n| Property | Contract |\n|---+---|\n"
m['constructors'].first.each { |k, v| s += '| ' + cell.call(k) + ' | ' + cell.call(v) + " |\n" }
s += "#+END:\n"
if m['nativeStages']
  s += "\n* Explicit native-stage contract\n#+BEGIN: sysml-view :kind explicit-native-stage :source architecture/toolchain/models/sysml/macos-development.sysml\n| Property | Contract |\n|---+---|\n"
  m.fetch('nativeStages').first.each { |k, v| s += '| ' + cell.call(k) + ' | ' + cell.call(v) + " |\n" }
  s += "#+END:\n"
end
if m['validationReuse']
  s += "\n* Validation reuse boundary projection\n#+BEGIN: sysml-view :kind validation-reuse :source architecture/toolchain/models/sysml/macos-development.sysml\n"
  s += "| Check | Source | Exact identity | Lifetime | Invalidators | Status | Still required |\n|---+---+---+---+---+---+---|\n"
  m['validationReuse'].each { |v| s += '| ' + %w[checkId sourceRefs exactIdentity lifetime invalidators reuseStatus stillRequired].map { |f| cell.call(v.fetch(f)) }.join(' | ') + " |\n" }
  s += "#+END:\n"
end
if m['sharedFixtures']
  s += "\n* Shared fixture artifact contract\n#+BEGIN: sysml-view :kind shared-fixture :source architecture/toolchain/models/sysml/macos-development.sysml\n| Property | Contract |\n|---+---|\n"
  m['sharedFixtures'].first.each { |k,v| s += '| ' + cell.call(k) + ' | ' + cell.call(v) + " |\n" }
  s += "#+END:\n"
end
File.write(org,s)
d2 = 'dev/architecture/toolchain/diagrams/macos-development.d2'
old = File.read(d2)
roles = old[old.index('roles: {')..].split('# Native artifact boundary projection').first
id = ->s { s.tr('-', '_').gsub(/[^A-Za-z0-9_]/, '_') }
diagram = "# SysML native projection; dependency closure is not runtime or reuse admission.\ndirection: down\n"
labels = m['duties'].to_h { |d| [d['fidelityId'], d['diagramLabel'] + "\n" + d['researchStatus']] }
m['duties'].each { |d| d['dependsOn'].split(';').map(&:strip).reject(&:empty?).each { |n| labels[n] ||= n } }
labels.each { |n, label| diagram += id.call(n) + ': ' + (n + "\n" + label).to_json + "\n" }
m['duties'].each { |d| d['dependsOn'].split(';').map(&:strip).reject(&:empty?).each { |n| diagram += "#{id.call(n)} -> #{id.call(d['fidelityId'])}\n" } }
diagram += roles + "\n# Native artifact boundary projection\nartifacts: {\n  label: \"Distinct artifact projections / actual reuse admission OPEN\"\n"
m['boundaries'].each { |b| diagram += '  ' + id.call(b['role']) + ': ' + (b['role'] + "\n" + b['invalidators']).to_json + "\n" }
m['boundaries'].each { |b| diagram += "  #{id.call(b['role'])} -> #{id.call(b['downstream'])}: \"changed output\"\n" unless b['downstream'].empty? }
diagram += "}\nDX_NATIVE_POLICY -> artifacts.Native_compilation: \"native policy input\"\n"
constructor = m['constructors'].first
diagram += 'constructors: ' + ("Mutable producer instance\n" + constructor['instanceIdentity'] + "\n" + constructor['admission']).to_json + "\nconstructors -> artifacts: \"completed content reuse stays separate\"\n"
if m['nativeStages']
  stage = m.fetch('nativeStages').first
  diagram += 'native_stage: ' + ("Modern C native-stage request\n" + stage['requestBoundary'] + "\n" + stage['reuseGuard']).to_json + "\n"
  diagram += "artifacts.Scheme_generation -> native_stage: \"explicit completed artifact\"\nnative_stage -> artifacts.Native_compilation: \"C leaf + ABI + existing Make\"\n"
  if stage['workspaceLifetime']
    diagram += 'native_workspace: ' + stage['workspaceLifetime'].to_json + "\n"
    diagram += 'native_configuration: ' + stage.fetch('configurationOwner').to_json + "\n"
    diagram += "native_workspace -> native_stage: \"same task-owned tree; no per-run copy\"\nnative_configuration -> native_stage: \"shared configure owner / same-request reuse\"\n"
  end
end
if m['validationReuse']
  diagram += "validation: {\n  label: \"Validation identity and lifetime / fresh execution stays separate\"\n"
  m['validationReuse'].each { |v| diagram += '  ' + id.call(v['checkId']) + ': ' + (v['checkId'] + "\n" + v['reuseStatus'] + "\n" + v['lifetime']).to_json + "\n" }
  diagram += "}\nnative_stage -> validation: \"measure checks separately from Make and tests\"\n"
end
if m['sharedFixtures']
  contract=m['sharedFixtures'].first
  diagram += "shared_fixtures: {\n  label: \"Three compilations / five fresh executions; original context retained\"\n"
  contract.fetch('producerConsumers').split(';').each do |pair|
    producer,consumer=pair.split('->').map(&:strip)
    diagram += '  ' + id.call(producer) + ': ' + (producer + "\ncompile + execute").to_json + "\n"
    diagram += '  ' + id.call(consumer) + ': ' + (consumer + "\nconsume + fresh execute").to_json + "\n"
    diagram += '  ' + id.call(producer) + ' -> ' + id.call(consumer) + ": \"exact compiled artifact / original cwd\"\n"
  end
  diagram += "}\nnative_stage -> shared_fixtures: \"same runtime + tools / no new executor\"\n"
end
File.write(d2, diagram)
puts JSON.generate(duties: m['duties'].size, boundaries: m['boundaries'].size, modelAuthority: 'SysML', runtimeAdmitted: false)
