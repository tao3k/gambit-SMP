;;; Scenario definitions loaded through Python/C ABI; no downstream imports or compile.
(def history-declarations
  (ascent-fragment
    (relation current_row ((query symbol?) (row symbol?)))
    (relation previous_row ((query symbol?) (row symbol?)))
    (relation current_input ((path symbol?) (hash symbol?)))
    (relation previous_input ((path symbol?) (hash symbol?)))
    (relation current_name ((path symbol?)))
    (relation previous_name ((path symbol?)))
    (relation added ((query symbol?) (row symbol?)))
    (relation removed ((query symbol?) (row symbol?)))
    (relation retained ((query symbol?) (row symbol?)))
    (relation changed_input ((path symbol?)))
    (relation added_input ((path symbol?)))
    (relation removed_input ((path symbol?)))
  ))
