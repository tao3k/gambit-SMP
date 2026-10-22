require 'json'
a='.cache/tasks/still-init-safepoint';r='.cache/tasks/still-init-recovery'
Dir["#{a}/*.{sh,jq,el}"].each do |f|
 base=File.basename(f);next if ['finalize.sh','seal-verification.sh','verify-final.sh'].include?(base)
 File.write("#{r}/#{base}",File.read(f).gsub('still-init-safepoint','still-init-recovery'))
end
Dir.mkdir("#{r}/build-cut") unless Dir.exist?("#{r}/build-cut")
Dir["#{a}/build-cut/*.{sh,jq,el}"].each{|f|File.write("#{r}/build-cut/#{File.basename(f)}",File.read(f).gsub('still-init-safepoint','still-init-recovery'))}
File.write("#{r}/native-model-inputs.txt",File.read("#{a}/native-model-inputs.txt")+"dev/architecture/runtime/gc/models/sysml/still-init-recovery.sysml\n")
p="#{r}/read-native.sh";s=File.read(p);insertion=<<~SH
idx=68
for n in history induction progress roots delivery abort; do
 for a in owner.componentId obligationId kind premise subjectPath subjectScope; do field "refinementNeeds.$idx.$a" "GambitStillInitRecovery::$n.$a"; done
 idx=$((idx+1))
done
for n in {0..25}; do
 idx=$((248+n))
 for a in dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId; do field "refinementDependencies.$idx.$a" "GambitStillInitRecovery::dependency$n.$a"; done
done
idx=46
for n in progress roots delivery abort; do
 for a in need.owner.componentId need.obligationId sourceAnchors patchAnchors projection failureCustodian status; do field "sourceRoutes.$idx.$a" "GambitStillInitRecovery::${n}Route.$a"; done
 idx=$((idx+1))
done
for n in {0..7}; do
 for a in callerId sourceAnchors actualChain hazard replacement; do field "recoveryCallers.$n.$a" "GambitStillInitRecovery::caller$n.$a"; done
 for a in capability removedWork bound addedCost condition; do field "recoveryCosts.$n.$a" "GambitStillInitRecovery::cost$n.$a"; done
done
for n in {0..9}; do
 for a in nodeId labelText; do field "recoveryNodes.$n.$a" "GambitStillInitRecovery::node$n.$a"; done
done
for n in {0..16}; do
 for a in producer.nodeId consumer.nodeId labelText; do field "recoveryEdges.$n.$a" "GambitStillInitRecovery::edge$n.$a"; done
done
SH
s=s.sub('args=(-strict -validate -json)',insertion+"args=(-strict -validate -json)");File.write(p,s)
# Existing SysML inputs/previous sources are unchanged; new formal subjects are the only new qualifications.
p="#{r}/compose.sh";s=File.read(p).sub("'21 passing'","'30 passing'").gsub('"$r/lean-kernel.log"','"$r/lean-scopes.log"').gsub('length==36','length==38').gsub('.dependencies|length)==288','.dependencies|length)==314').gsub('.needs|length)==100','.needs|length)==106').gsub('evidence/research/structure-poll-still-envelope','evidence/research/still-init-safepoint');File.write(p,s)
%w[render-cases.sh render-pair-controls.sh render-available.jq].each do |b|
 p="#{r}/#{b}";File.write(p,File.read(p).gsub('SI-H','IR-H').gsub('SI-I','IR-I'))
end
sc={cases:[{id:'current',control:false},{id:'all-scoped-control',control:true},{id:'models-only',control:true,denied:%w[IR-PROGRESS IR-ROOT IR-DELIVERY IR-ABORT]},*%w[progress roots delivery abort].zip(%w[IR-PROGRESS IR-ROOT IR-DELIVERY IR-ABORT]).map{|x,id|{id:"omit-#{x}",control:true,denied:[id]}},{id:'omit-root-binding',control:true,denied:['HR-BIND']},{id:'wrong-detail-scope',control:true,wrongScope:'IR-I'},{id:'stale-detail-digest',control:true,stale:'IR-H'},{id:'paired-stale-detail',control:true},{id:'paired-nonpass-status',control:true}]}
File.write("#{r}/scenarios-template.json",JSON.generate(sc))
p="#{r}/refresh.sh";s=File.read(p).sub('models-only omit-admission omit-custody omit-root-binding','models-only omit-progress omit-roots omit-delivery omit-abort omit-root-binding');File.write(p,s)
# Retain every inherited formal receipt using independent exact scope/digest matching.
%w[read-association.el].each{|b|File.write("#{r}/build-cut/#{b}",File.read("#{r}/#{b}"))}
# Presentation-only adapter; source data and dependencies remain native SysML.
p='dev/modeling/ascent/render-still-init-recovery.jq';s=File.read('dev/modeling/ascent/render-still-init-safepoint.jq').gsub('initNodes','recoveryNodes').gsub('initEdges','recoveryEdges').gsub('initCallers','recoveryCallers').gsub('initCosts','recoveryCosts').gsub('SI-','IR-').gsub('[232:]','[248:]').gsub('Still initialization, safe-point and root custody and peak matrices','Partial initialization and undelivered-result recovery matrices').gsub('init-caller','recovery-caller').gsub('init-benefit','recovery-benefit').gsub('init-callers','recovery-callers').gsub('init-costs','recovery-costs').gsub('init-needs','recovery-needs').gsub('init-dependencies','recovery-dependencies');File.write(p,s)
File.write("#{r}/predecessor-qualified.json",`jq -s '{qualifiedSlice:([.[].qualifiedSlice[]]|unique)}' #{a}/case-current.json #{a}/build-cut/case-current.json`)
SHAPES=%w[vendor/gambit/lib/_kernel.scm vendor/gambit/lib/_kernel.c vendor/gambit/lib/mem.c vendor/gambit/lib/c_intf.c vendor/gambit/lib/setup.c vendor/gambit/lib/os_io.c vendor/gambit/lib/os_base.c vendor/gambit/include/gambit.h.in patches/fixtures/processor-interrupt-collective-wait-cumulative.patch evidence/research/still-init-safepoint/checks.json]
File.write("#{r}/preserved.sha256",SHAPES.map{|p|`openssl dgst -sha256 #{p}`}.join)
