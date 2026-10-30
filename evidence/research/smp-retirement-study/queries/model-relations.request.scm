((bindings ())
 (checkpoint "clue-read:05cbb7d09a40a2ec1c27cf49768136ecda0719d8c6c78c3feb219f19bc2f9605")
 (displayBytes 12000)
 (selector "(define-evidence (query) (sources factor) (outputs question model_reference) (include clue-selection-schema) (relation question (claim)) (relation model_reference (kind value)) ((model_reference (lit \"model\") V) <-- (factor _ _ (lit \"model\") V)) ((model_reference (lit \"model-reference\") V) <-- (factor _ _ (lit \"model-reference\") V)) ((model_reference (lit \"qnt\") V) <-- (factor _ _ (lit \"qnt\") V)) ((model_reference (lit \"model-source-path\") V) <-- (factor _ _ (lit \"model-source-path\") V)))"))
