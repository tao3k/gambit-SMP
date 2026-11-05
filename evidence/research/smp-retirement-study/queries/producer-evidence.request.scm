((bindings ())
 (checkpoint "clue-read:05c5360b2cc25536c85572c1fcff1347d91418ea929eac558c8a8deac27a750f")
 (displayBytes 18000)
 (selector "(define-evidence (query) (sources clue factor) (outputs question identity_factor) (include clue-selection-schema) (relation selected (id digest)) (relation question (claim)) (relation identity_factor (claim name value)) ((selected I D) <-- (factor I D _ (lit \"2fe7e4073bd6615e9d5d1d86bbf5a274e99a881b455cb0e6c49c6ba3dfa854eb\"))) ((question C) <-- (selected I D) (clue I D C _ _ _)) ((identity_factor C N V) <-- (selected I D) (clue I D C _ _ _) (factor I D N V)))"))
