r='.cache/tasks/still-init-safepoint';o='.cache/tasks/structure-poll-still-envelope'
%w[read-native.sh compose.sh refresh.sh render-cases.sh render-pair-controls.sh run-queries.sh assert.sh verify-final.sh facts.jq render-available.jq cuts.jq read-association.el check-org.el check-org-links.el render-views.sh render-route-cuts.sh check-receipt-transport.el].each do |n|
 s=File.read("#{o}/#{n}").gsub('structure-poll-still-envelope','still-init-safepoint').gsub('structure_poll_still_envelope','still_init_safepoint').gsub('StructurePollStillEnvelope','StillInitSafepoint')
 if n=='read-native.sh'
  s=s.gsub('GambitStillInitSafepoint','GambitStructurePollStillEnvelope')
  insert=<<~SH
idx=64
for n in history induction admission custody; do
 for a in owner.componentId obligationId kind premise subjectPath subjectScope; do field "refinementNeeds.$idx.$a" "GambitStillInitSafepoint::$n.$a"; done
 idx=$((idx+1))
done
for n in {0..13}; do
 idx=$((232+n))
 for a in dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId; do field "refinementDependencies.$idx.$a" "GambitStillInitSafepoint::dependency$n.$a"; done
done
idx=44
for n in admission custody; do
 for a in need.owner.componentId need.obligationId sourceAnchors patchAnchors projection failureCustodian status; do field "sourceRoutes.$idx.$a" "GambitStillInitSafepoint::${n}Route.$a"; done
 idx=$((idx+1))
done
for n in {0..7}; do
 for a in callerId sourceAnchors actualChain hazard replacement; do field "initCallers.$n.$a" "GambitStillInitSafepoint::caller$n.$a"; done
done
for n in {0..6}; do
 for a in capability removedWork bound addedCost condition; do field "initCosts.$n.$a" "GambitStillInitSafepoint::cost$n.$a"; done
done
for n in {0..9}; do
 for a in nodeId labelText; do field "initNodes.$n.$a" "GambitStillInitSafepoint::node$n.$a"; done
done
for n in {0..13}; do
 for a in producer.nodeId consumer.nodeId labelText; do field "initEdges.$n.$a" "GambitStillInitSafepoint::edge$n.$a"; done
done
SH
  s=s.sub('args=(-strict -validate -json)',insert+'args=(-strict -validate -json)')
 end
 if n=='compose.sh'
  s=s.gsub('18 passing','20 passing').gsub('rest-gc-resume-envelope','structure-poll-still-envelope').gsub('length==34','length==36')
  s=s.sub('"vendor/gambit/lib/os_base.c",','"vendor/gambit/lib/os_base.c","vendor/gambit/lib/os_time.c","vendor/gambit/lib/os_setup.c","vendor/gambit/lib/_num.scm","vendor/gambit/lib/_system.scm",')
 end
 s=s.gsub('SP-H','SI-H').gsub('SP-I','SI-I') if %w[compose.sh render-cases.sh render-pair-controls.sh assert.sh check-receipt-transport.el].include?(n)
 if n=='assert.sh'
  s=s.gsub('==272','==286').gsub('==96','==100').gsub('==44','==46').gsub('==28 and (.pendingCheck|length)==52','==30 and (.pendingCheck|length)==54').gsub('==80','==84').gsub('length==36','length==38').gsub('SP-POLL','SI-GATE')
  s=s.gsub('models-only omit-placement omit-checks omit-restore omit-peak omit-root-binding','models-only omit-admission omit-custody omit-root-binding')
 end
 if n=='compose.sh'
  s=s.gsub('==272','==286').gsub('==96','==100')
 end
 if n=='render-route-cuts.sh'
  s=s.gsub('[:22]','[:23]').gsub('[22:]','[23:]')
 end
 if n=='refresh.sh'
  s=s.gsub(%q{sed '$d' dev/modeling/ascent/assurance-planner.ss > "$r/common.ss"},%q{ASSURANCE_CORE="$r/common.ss" emacs -Q --batch -l "$r/specialize-inference.el"})
  s=s.gsub(%q{sed '$d' dev/modeling/ascent/assurance-planner.ss > "$r/build-cut/common.ss"},%q{ASSURANCE_CORE="$r/build-cut/common.ss" emacs -Q --batch -l "$r/specialize-inference.el"})
  s=s.gsub('models-only omit-placement omit-checks omit-restore omit-peak omit-root-binding','models-only omit-admission omit-custody omit-root-binding')
 end
 if n=='check-receipt-transport.el'
  s=s.gsub('(length receipts) 28','(length receipts) 30').gsub('pairs 14','pairs 15')
 end
 File.write("#{r}/#{n}",s)
end
%w[render-cases.sh run-queries.sh render-available.jq read-association.el scenarios-template.json].each{|n|File.write("#{r}/build-cut/#{n}",File.read("#{o}/build-cut/#{n}").gsub('structure-poll-still-envelope','still-init-safepoint'))}
s=File.read('dev/modeling/ascent/render-structure-poll-still-envelope.jq').gsub('structureNodes','initNodes').gsub('structureEdges','initEdges').gsub('structureCallers','initCallers').gsub('structureCosts','initCosts').gsub('Structure POLL, frames and still','Still initialization, safe-point and root custody').gsub('structure-','init-').gsub('SP-','SI-').gsub('[208:]','[232:]')
File.write('dev/modeling/ascent/render-still-init-safepoint.jq',s)
