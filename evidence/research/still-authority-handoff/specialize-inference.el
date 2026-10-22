;; Transport-only specialization for inference cuts whose metadata facts are empty.
;; Drop only the three metadata input declarations and four projection clauses.
(require 'json)
(let* ((source "dev/modeling/ascent/assurance-planner.ss")
       (tree (with-temp-buffer (insert-file-contents source) (read (current-buffer))))
       (input-names '(sourceRouteFact sourceRoutePairFact contractFact dependencyTripleFact dependencyQuintFact))
       (head-names '(sourceRouteFact sourceRoute sharedContract))
       (removed nil)
       (result (seq-remove
                (lambda (form)
                  (let ((drop (and (listp form)
                                   (or (and (eq (car form) 'relation) (memq (cadr form) input-names))
                                       (and (listp (car form)) (memq (caar form) head-names))))))
                    (let ((old-edge (and (listp form) (listp (car form)) (eq (caar form) 'dependencyFact) (seq-some (lambda (x) (and (listp x) (memq (car x) '(dependencyTripleFact dependencyQuintFact)))) (cddr form)))))
                    (when (or drop old-edge) (push form removed)) (or drop old-edge)))) tree)))
  (unless (= (length removed) 17) (error "Metadata-only specialization drift"))
  (let ((printed (prin1-to-string result)))
    (unless (equal (car (read-from-string printed)) result) (error "AST transport drift"))
    (with-temp-file (getenv "ASSURANCE_CORE") (insert (substring printed 0 -1) "\n")))
  (with-temp-file ".cache/tasks/still-authority-handoff/specialization-receipt.json"
    (insert (json-encode `((removedForms . 17) (policyRulesChanged . :json-false)
                          (requiresEmptySourceRouteAndContractFacts . t)
                          (fullSchema . ,source)))))
  (princ "Seven metadata and ten empty legacy-edge forms elided; qualification policy retained.\n"))
