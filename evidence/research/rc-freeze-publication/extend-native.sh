#!/bin/bash
set -euo pipefail
r=.cache/tasks/rc-freeze-publication
# Add executable source routes to native model. Evidence routing is not source proof.
model=dev/architecture/runtime/ffi/models/sysml/rc-freeze-publication.sysml
sed '$d' "$model" > "$r/fz.tmp"
for spec in 'census:primitive' 'freeze:primitive' 'publication:primitive' 'callback:dynamic' 'cleanup:release' 'memoryOrder:primitive'; do
 n=${spec%:*}; anchor=${spec#*:}
 cat >> "$r/fz.tmp" <<EOF
    part ${n}Route : GambitHostRootsRefinement::Route {
        ref part :>> need = $n;
        attribute :>> sourceAnchors = $anchor.sourceAnchors;
        attribute :>> patchAnchors = "cumulative.patch:3160-3234,3443-3460,4350-4501; no complete freeze/barrier/deferred-cleanup adapter";
        attribute :>> projection = protocol.receipt;
        attribute :>> failureCustodian = protocol.unknown;
        attribute :>> status = "design-specified-source-and-memory-refinement-open";
    }
EOF
done
echo '}' >> "$r/fz.tmp"
cp "$r/fz.tmp" "$model"
model=dev/architecture/runtime/gc/models/sysml/generational-admission.sysml
sed '$d' "$model" > "$r/gen.tmp"
cat >> "$r/gen.tmp" <<'EOF'
    part sourceRoute : GambitHostRootsRefinement::Route {
        ref part :>> need = source;
        attribute :>> sourceAnchors = "mem.c:3410-3469,3490-3665,3969-3986,6678-6770; gambit.h.in:5482-5485; _kernel.scm:3154-3162,3439-3550; _t-c-2.scm:3356-3365";
        attribute :>> patchAnchors = "cumulative.patch:3443-3460; existing root repair is not a generational barrier";
        attribute :>> projection = candidate.roots;
        attribute :>> failureCustodian = "VM/root/collector custodian retains all regions, source slots and unfinished promotion debt";
        attribute :>> status = "candidate-only-current-source-is-full-copying";
    }
}
EOF
cp "$r/gen.tmp" "$model"
sed '/^args=/,$d' .cache/tasks/retained-rc-scan/read-native.sh | sed 's@r=.cache/tasks/retained-rc-scan@r=.cache/tasks/rc-freeze-publication@' > "$r/read-native.sh"
cat >> "$r/read-native.sh" <<'EOF'
idx=16
for need in history induction census freeze publication callback cleanup memoryOrder; do
 for attr in owner.componentId obligationId kind premise subjectPath subjectScope; do field "refinementNeeds.$idx.$attr" "GambitRcFreezePublication::$need.$attr"; done
 idx=$((idx+1))
done
for need in history induction source; do
 for attr in owner.componentId obligationId kind premise subjectPath subjectScope; do field "refinementNeeds.$idx.$attr" "GambitGenerationalAdmission::$need.$attr"; done
 idx=$((idx+1))
done
idx=54
for spec in GambitRcFreezePublication:28 GambitGenerationalAdmission:6; do
 package=${spec%:*}; last=${spec#*:}
 for ((n=0;n<=last;n++)); do
  for attr in dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId; do field "refinementDependencies.$idx.$attr" "$package::dependency$n.$attr"; done
  idx=$((idx+1))
 done
done
idx=12
for n in census freeze publication callback cleanup memoryOrder; do
 for attr in need.owner.componentId need.obligationId sourceAnchors patchAnchors projection failureCustodian status; do field "sourceRoutes.$idx.$attr" "GambitRcFreezePublication::${n}Route.$attr"; done
 idx=$((idx+1))
done
for attr in need.owner.componentId need.obligationId sourceAnchors patchAnchors projection failureCustodian status; do field "sourceRoutes.$idx.$attr" "GambitGenerationalAdmission::sourceRoute.$attr"; done
for attr in identity preparation close receipt publication mutation collector deletion cleanup unknown; do field "freezeProtocol.$attr" "GambitRcFreezePublication::protocol.$attr"; done
for attr in allocationPolicy minor mature stores overflow roots continuation ffi major retirement; do field "generationalPolicy.$attr" "GambitGenerationalAdmission::candidate.$attr"; done
idx=0
for n in primitive converter dynamic tcl release resources exports; do
 for attr in routeId sourceAnchors authority obligation boundary; do field "census.$idx.$attr" "GambitRcFreezePublication::$n.$attr"; done
 idx=$((idx+1))
done
idx=0
for n in scheme stores nursery remembered domains minor mature major release ffi; do
 for attr in nodeId labelText; do field "viewNodes.$idx.$attr" "GambitGenerationalAdmission::$n.$attr"; done
 idx=$((idx+1))
done
for n in {0..11}; do
 for attr in producer.nodeId consumer.nodeId labelText; do field "viewEdges.$n.$attr" "GambitGenerationalAdmission::edge$n.$attr"; done
done
EOF
sed -n '/^args=/,$p' .cache/tasks/retained-rc-scan/read-native.sh >> "$r/read-native.sh"
bash "$r/read-native.sh"
