;;; Scenario definitions loaded through Python/C ABI; no downstream imports or compile.
(def history-source-rules
  (ascent-fragment
    ((changed_input P) <-- (current_input P H) (previous_input P K) (not (previous_input P H)))
    ((added_input P) <-- (current_input P H) (not (previous_name P)))
    ((removed_input P) <-- (previous_input P H) (not (current_name P)))
    ((previous_name P) <-- (previous_input P H))
    ((current_name P) <-- (current_input P H))
  ))
