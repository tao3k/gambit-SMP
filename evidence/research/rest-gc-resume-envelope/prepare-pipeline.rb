r='.cache/tasks/rest-gc-resume-envelope'; old='.cache/tasks/guaranteed-tail-placement'
files=%w[read-native.sh compose.sh refresh.sh render-cases.sh run-queries.sh assert.sh finalize.sh verify-final.sh facts.jq render-available.jq cuts.jq read-association.el check-org.el check-org-links.el]
files.each do |name|
 s=File.read("#{old}/#{name}").gsub('guaranteed-tail-placement','rest-gc-resume-envelope').gsub('guaranteed_tail_placement','rest_gc_resume_envelope').gsub('GuaranteedTailPlacement','RestGcResumeEnvelope')
 # Restore native inherited GT extraction: only new scalar projection uses RG names.
 if name=='read-native.sh'
  s=s.gsub('GambitRestGcResumeEnvelope','GambitGuaranteedTailPlacement')
  insert=<<~SH
idx=52
for n in history induction completion resume lifetime peak; do
 for a in owner.componentId obligationId kind premise subjectPath subjectScope; do field "refinementNeeds.$idx.$a" "GambitRestGcResumeEnvelope::$n.$a"; done
 idx=$((idx+1))
done
for n in {0..21}; do
 idx=$((186+n))
 for a in dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId; do field "refinementDependencies.$idx.$a" "GambitRestGcResumeEnvelope::dependency$n.$a"; done
done
idx=36
for n in completion resume lifetime peak; do
 for a in need.owner.componentId need.obligationId sourceAnchors patchAnchors projection failureCustodian status; do field "sourceRoutes.$idx.$a" "GambitRestGcResumeEnvelope::${n}Route.$a"; done
 idx=$((idx+1))
done
for n in {0..5}; do
 for a in callerId sourceAnchors actualChain hazard replacement; do field "restCallers.$n.$a" "GambitRestGcResumeEnvelope::caller$n.$a"; done
done
for n in {0..7}; do
 for a in capability removedWork bound addedCost condition; do field "restCosts.$n.$a" "GambitRestGcResumeEnvelope::cost$n.$a"; done
done
for n in {0..10}; do
 for a in nodeId labelText; do field "restNodes.$n.$a" "GambitRestGcResumeEnvelope::node$n.$a"; done
done
for n in {0..13}; do
 for a in producer.nodeId consumer.nodeId labelText; do field "restEdges.$n.$a" "GambitRestGcResumeEnvelope::edge$n.$a"; done
done
SH
  s=s.sub('args=(-strict -validate -json)',insert+"args=(-strict -validate -json)")
 end
 if name=='compose.sh'
  s=s.gsub('17 passing','16 passing').gsub('promotion-interval-handoff','guaranteed-tail-placement').gsub('length==30','length==32')
  s=s.sub('"vendor/gambit/lib/_kernel.scm",','"vendor/gambit/lib/_kernel.scm","vendor/gambit/lib/_kernel.c",')
 end
 s=s.gsub('"GT-H","GT-I"','"RG-H","RG-I"') if ['compose.sh','render-cases.sh'].include?(name)
 if %w[compose.sh assert.sh finalize.sh verify-final.sh].include?(name)
  # Only exact count tokens, not source line anchors.
  s=s.gsub('==226','==248').gsub('==84','==90').gsub('==36','==40')
 end
 if name=='assert.sh'
  s=s.gsub('==24 and (.pendingCheck|length)==44','==26 and (.pendingCheck|length)==48').gsub('==68','==74').gsub('length==32','length==34')
  s=s.gsub('GT-I','RG-I').gsub('GT-H','RG-H').gsub('GT-RESTORE','RG-RESUME')
 end
 File.write("#{r}/#{name}",s)
end
%w[render-cases.sh run-queries.sh].each do |name|
 s=File.read("#{old}/build-cut/#{name}").gsub('guaranteed-tail-placement','rest-gc-resume-envelope')
 File.write("#{r}/build-cut/#{name}",s)
end
FileUtils=nil if false
File.write("#{r}/build-cut/scenarios-template.json",File.read("#{old}/build-cut/scenarios-template.json"))
