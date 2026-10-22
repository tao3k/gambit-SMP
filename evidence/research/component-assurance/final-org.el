(require 'org)
(require 'org-element)
(dolist (source '("dev/modeling/component-assurance.org" "dev/modeling/assurance-planner.org"))
 (with-temp-buffer
  (insert-file-contents source)
  (org-mode)
  (org-element-parse-buffer)
  (princ (concat "Parsed final " source "\n"))))
