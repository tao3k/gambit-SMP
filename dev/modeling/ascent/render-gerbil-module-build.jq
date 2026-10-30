# Presentation only. Values originate in native GerbilModuleBuild evaluation.
if $view == "matrix" then
  "#+TITLE: Gerbil Module Build Benefit and Cost Matrix\n#+SETUPFILE: ../../modeling/org/setup.org\n#+CATEGORY: toolchain\n\n* RESEARCH Native SysML projection\n:PROPERTIES:\n:CUSTOM_ID: gerbil-build-matrix\n:AUTHORITY: GerbilModuleBuild\n:STATUS: source-refinement-open\n:END:\n\nDerived from [[file:models/sysml/gerbil-module-build.sysml][SysML]]; explanation and source identity are in\n[[file:gerbil-module-build-design.org][the design]]. No measured gain or qualification receipt is asserted.\n\n| Boundary | Source anchor | Redesign | Conditional benefit | Added cost | Open condition | Existing duty |\n|---+---+---+---+---+---+---|\n" +
  ([.planning,.frontend,.readiness,.execution] | map(
    "| " + ([.boundaryId,.sourceAnchor,.redesign,.gain,.addedCost,.openCondition,
      (.sourceDuty.owner.componentId + "/" + .sourceDuty.obligationId)] | join(" | ")) + " |") | join("\n")) + "\n"
elif $view == "d2" then
  "direction: right\n# Contract decomposition, not a serial module action schedule.\n" +
  ([.planning,.frontend,.readiness,.execution] | map(
    .boundaryId + ": " + ((.labelText + "\n" + .sourceDuty.obligationId + " remains open") | tojson)) | join("\n")) + "\n" +
  ([.edge0,.edge1,.edge2] | map(.producer.boundaryId + " -> " + .consumer.boundaryId + ": contract input") | join("\n")) + "\n"
else error("unknown presentation") end
