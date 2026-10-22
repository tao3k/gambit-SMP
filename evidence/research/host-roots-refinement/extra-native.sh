idx=0
for need in history induction rc marker boot exitState bindingState dynamic; do
 for attr in obligationId kind premise subjectPath subjectScope; do field "refinementNeeds.$idx.$attr" "GambitHostRootsRefinement::$need.$attr"; done
 idx=$((idx+1))
done
for num in {0..25}; do
 for attr in dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId; do field "refinementDependencies.$num.$attr" "GambitHostRootsRefinement::dependency$num.$attr"; done
done
idx=0
for route in rc marker boot exitState bindingState dynamic; do
 for attr in need.obligationId sourceAnchors patchAnchors projection failureCustodian status; do field "sourceRoutes.$idx.$attr" "GambitHostRootsRefinement::${route}Route.$attr"; done
 idx=$((idx+1))
done
