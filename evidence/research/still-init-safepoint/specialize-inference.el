;; Transport-only specialization for inference cuts whose metadata facts are empty.
;; Drop only the three metadata input declarations and four projection clauses.
(require 'json)
(let* ((source "dev/modeling/ascent/assurance-planner.ss")
       (tree (with-temp-buffer (insert-file-contents source) (read (current-buffer))))
       (input-names '(sourceRouteFact sourceRoutePairFact contractFact))
       (head-names '(sourceRouteFact sourceRoute sharedContract))
       (removed nil)
       (result (seq-remove
                (lambda (form)
                  (let ((drop (and (listp form)
                                   (or (and (eq (car form) 'relation) (memq (cadr form) input-names))
                                       (and (listp (car form)) (memq (caar form) head-names))))))
                    (when drop (push form removed)) drop)) tree)))
  (unless (= (length removed) 7) (error "Metadata-only specialization drift"))
  (let ((printed (prin1-to-string result)))
    (unless (equal (car (read-from-string printed)) result) (error "AST transport drift"))
    (with-temp-file (getenv "ASSURANCE_CORE") (insert (substring printed 0 -1) "\n")))
  (with-temp-file ".cache/tasks/still-init-safepoint/specialization-receipt.json"
    (insert (json-encode `((removedForms . 7) (policyRulesChanged . :json-false)
                          (requiresEmptySourceRouteAndContractFacts . t)
                          (fullSchema . ,source)))))
  (princ "Exactly seven metadata-only forms elided; qualification policy retained.\n"))
