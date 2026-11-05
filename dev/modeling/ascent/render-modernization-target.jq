def row: "| "+(map(tostring)|join(" | "))+" |";
if $view=="d2" then
 "direction: right", "vars: { d2-config: { theme-id: 0 } }",
 (.canonicalModules[]|"m_\(.moduleId): { label: \(.label|@json) }"),
 (.canonicalInterfaces[]|"m_\(.producerId) -> m_\(.consumerId): \(.interfaceId|@json)")
else
 "#+TITLE: Whole Modern C Modernization Target Matrix", "#+LANGUAGE: en", "#+OPTIONS: toc:3 num:nil", "#+PROPERTY: header-args :eval never", "",
 "* Six architectural replacements", "| Decision | Canonical owner | Target | Lesson | Replacement | Retirement | Benefit condition | Added cost |", "|---+---+---+---+---+---+---+---|",
 (.architecture[]|[.decisionId,.owner.ownerPath,.target,.lesson,.replacement,.retirement,.benefit,.addedCost]|row),"",
 "* Whole-source composition obligations", "Existing QNT/Lean fragments do not qualify these larger scopes. The native DSL keeps them open.",
 "| Decision | Source anchors | Interleaving need | Induction need | Full obligation |", "|---+---+---+---+---|",
 (.architecture[]|[.decisionId,.sourceAnchors,.interleaving.obligationId,.induction.obligationId,.obligation]|row),"",
 "* Canonical cross-module contracts", "| Contract | Producer | Consumer | Payload | Required order | Failure custody |", "|---+---+---+---+---+---|",
 (.canonicalInterfaces[]|[.interfaceId,.producerId,.consumerId,.payload,.orderedContract,.failureCustody]|row),"",
 "* MC-SCOPE candidate assessment", "| Criterion | Native model value |", "|---+---|",
 (.candidate|to_entries[]|[.key,.value]|row),"",
 "* Evidence boundary", "The source commit is real; architectural adoption is false. No six-decision composition is closed by local gate tests. Four retained native milestone contracts remain open and the 8/12 history is unchanged."
end
