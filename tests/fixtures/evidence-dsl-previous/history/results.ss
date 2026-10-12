;;; Scenario definitions loaded through Python/C ABI; no downstream imports or compile.
(def history-result-rules
  (ascent-fragment
    ((added Q R) <-- (current_row Q R) (not (previous_row Q R)))
    ((removed Q R) <-- (previous_row Q R) (not (current_row Q R)))
    ((retained Q R) <-- (current_row Q R) (previous_row Q R))
  ))
