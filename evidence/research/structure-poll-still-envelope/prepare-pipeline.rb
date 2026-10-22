r='.cache/tasks/structure-poll-still-envelope';o='.cache/tasks/rest-gc-resume-envelope'
%w[read-native.sh compose.sh refresh.sh render-cases.sh run-queries.sh assert.sh verify-final.sh facts.jq render-available.jq cuts.jq read-association.el check-org.el check-org-links.el render-views.sh].each do |n|
 s=File.read("#{o}/#{n}").gsub('rest-gc-resume-envelope','structure-poll-still-envelope').gsub('rest_gc_resume_envelope','structure_poll_still_envelope').gsub('RestGcResumeEnvelope','StructurePollStillEnvelope')
 if n=='read-native.sh'
  s=s.gsub('GambitStructurePollStillEnvelope','GambitRestGcResumeEnvelope')
  insert=<<~SH
idx=58
for n in history induction poll frames still peak; do
 for a in owner.componentId obligationId kind premise subjectPath subjectScope; do field "refinementNeeds.$idx.$a" "GambitStructurePollStillEnvelope::$n.$a"; done
 idx=$((idx+1))
done
for n in {0..23}; do
 idx=$((208+n))
 for a in dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId; do field "refinementDependencies.$idx.$a" "GambitStructurePollStillEnvelope::dependency$n.$a"; done
done
idx=40
for n in poll frames still peak; do
 for a in need.owner.componentId need.obligationId sourceAnchors patchAnchors projection failureCustodian status; do field "sourceRoutes.$idx.$a" "GambitStructurePollStillEnvelope::${n}Route.$a"; done
 idx=$((idx+1))
done
for n in {0..5}; do
 for a in callerId sourceAnchors actualChain hazard replacement; do field "structureCallers.$n.$a" "GambitStructurePollStillEnvelope::caller$n.$a"; done
done
for n in {0..8}; do
 for a in capability removedWork bound addedCost condition; do field "structureCosts.$n.$a" "GambitStructurePollStillEnvelope::cost$n.$a"; done
done
for n in {0..11}; do
 for a in nodeId labelText; do field "structureNodes.$n.$a" "GambitStructurePollStillEnvelope::node$n.$a"; done
done
for n in {0..17}; do
 for a in producer.nodeId consumer.nodeId labelText; do field "structureEdges.$n.$a" "GambitStructurePollStillEnvelope::edge$n.$a"; done
done
SH
  s=s.sub('args=(-strict -validate -json)',insert+'args=(-strict -validate -json)')
 end
 if n=='compose.sh'
  s=s.gsub('16 passing','18 passing').gsub('guaranteed-tail-placement','rest-gc-resume-envelope').gsub('length==32','length==34')
 end
 s=s.gsub('"RG-H","RG-I"','"SP-H","SP-I"') if %w[compose.sh render-cases.sh].include?(n)
 s=s.gsub('==248','==272').gsub('==90','==96').gsub('==40','==44') if %w[compose.sh assert.sh].include?(n)
 if n=='assert.sh'
  s=s.gsub('==26 and (.pendingCheck|length)==48','==28 and (.pendingCheck|length)==52').gsub('==74','==80').gsub('length==34','length==36').gsub('RG-I','SP-I').gsub('RG-H','SP-H').gsub('RG-RESUME','SP-POLL')
 end
 File.write("#{r}/#{n}",s)
end
%w[render-cases.sh run-queries.sh render-available.jq read-association.el scenarios-template.json].each do|n|
 s=File.read("#{o}/build-cut/#{n}").gsub('rest-gc-resume-envelope','structure-poll-still-envelope')
 File.write("#{r}/build-cut/#{n}",s)
end
s=File.read('dev/modeling/ascent/render-rest-gc-resume-envelope.jq').gsub('restNodes','structureNodes').gsub('restEdges','structureEdges').gsub('restCallers','structureCallers').gsub('restCosts','structureCosts').gsub('Rest construction, GC resume','Structure POLL, frames and still').gsub('rest-','structure-').gsub('RG-','SP-').gsub('[186:]','[208:]')
File.write('dev/modeling/ascent/render-structure-poll-still-envelope.jq',s)
