((bindings ())
 (checkpoint "clue-read:7736096a6a90842009cb1a7181dff18b730a489208b33386e4e6c195ec18d950")
 (displayBytes 18000)
 (selector "(define-evidence (query) (sources clue factor) (outputs question identity_factor) (include clue-selection-schema) (relation selected (id digest)) (relation question (claim)) (relation identity_factor (claim name value)) ((selected I D) <-- (factor I D _ (lit \"models/gambit/scheduler_wait_gc_contract.qnt\"))) ((question C) <-- (selected I D) (clue I D C _ _ _)) ((identity_factor C N V) <-- (selected I D) (clue I D C _ _ _) (factor I D N V)))"))
