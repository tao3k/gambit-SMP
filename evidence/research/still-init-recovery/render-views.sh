#!/bin/bash
set -euo pipefail
r=.cache/tasks/still-init-recovery
jq -r --arg view matrix -f dev/modeling/ascent/render-still-init-recovery.jq "$r/native-projection.json" > dev/architecture/runtime/gc/still-init-recovery-matrix.org
jq -r --arg view d2 -f dev/modeling/ascent/render-still-init-recovery.jq "$r/native-projection.json" > dev/architecture/runtime/gc/diagrams/still-init-recovery.d2
jq '. as $p|.components|=map(.id as $id|.needs=([.needs[]]+[$p.refinementNeeds[]|select((.owner.componentId//"host-roots")==$id)]))|.dependencies+=.refinementDependencies' "$r/native-projection.json" > "$r/graph-view.json"
jq -r -f dev/modeling/ascent/render-component-dependencies.jq "$r/graph-view.json" > dev/modeling/diagrams/component-proof-dependencies.d2
d2 --layout elk dev/architecture/runtime/gc/diagrams/still-init-recovery.d2 dev/architecture/runtime/gc/diagrams/still-init-recovery.svg > "$r/d2.log" 2>&1
d2 --layout elk dev/modeling/diagrams/component-proof-dependencies.d2 dev/modeling/diagrams/component-proof-dependencies.svg > "$r/d2-global.log" 2>&1
rsvg-convert -w 1500 dev/architecture/runtime/gc/diagrams/still-init-recovery.svg -o "$r/still-init-recovery.png"
