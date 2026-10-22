idx=8
for need in history induction joinResult membership tracing commitState lifetime memoryOrder; do
 for attr in obligationId kind premise subjectPath subjectScope; do field "refinementNeeds.$idx.$attr" "GambitRetainedRcScan::$need.$attr"; done
 idx=$((idx+1))
done
for num in {0..27}; do
 idx=$((num+26))
 for attr in dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId; do field "refinementDependencies.$idx.$attr" "GambitRetainedRcScan::dependency$num.$attr"; done
done
idx=6
for route in joinResult membership tracing commitState lifetime memoryOrder; do
 for attr in need.obligationId sourceAnchors patchAnchors projection failureCustodian status; do field "sourceRoutes.$idx.$attr" "GambitRetainedRcScan::${route}Route.$attr"; done
 idx=$((idx+1))
done
for attr in identity membership freeze scanSnapshot trace commit acknowledgement physicalLifetime capacity memoryOrder quarantine; do field "retainedProtocol.$attr" "GambitRetainedRcScan::protocol.$attr"; done
for attr in rootComponent.componentId collectorComponent.componentId; do field "retainedProtocol.$attr" "GambitRetainedRcScan::protocol.$attr"; done
