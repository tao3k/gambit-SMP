(require 'org)
(require 'json)
(setq enable-local-variables nil org-confirm-babel-evaluate t)
(let ((files '("dev/refactoring/modern-c/frame-contract-realization.org"
               "dev/refactoring/modern-c/frame-contract-matrix.org"
               "dev/refactoring/modern-c/index.org"))
      (links 0))
  (dolist (file files)
    (with-temp-buffer
      (insert-file-contents file)
      (setq buffer-file-name (expand-file-name file)
            default-directory (file-name-directory buffer-file-name))
      (org-mode)
      (let ((tree (org-element-parse-buffer)) (ids (make-hash-table :test 'equal)))
        (org-element-map tree 'headline
          (lambda (h)
            (let ((id (org-element-property :CUSTOM_ID h)))
              (when id
                (when (gethash id ids) (error "Duplicate CUSTOM_ID %s" id))
                (puthash id t ids)))))
        (when (member file (list (car files) (cadr files)))
          (org-element-map tree 'link
            (lambda (link)
              (when (equal (org-element-property :type link) "file")
                (let* ((path (org-element-property :path link))
                       (target (expand-file-name path default-directory)))
                  (unless (file-exists-p target) (error "Missing file link %s" target))
                  (setq links (1+ links))))))))))
  (with-temp-file ".cache/tasks/modern-c-frame-contract/org-check.json"
    (insert (json-encode `((parsedFiles . 3) (newFileLinksChecked . ,links)
                          (babelExecuted . :json-false) (status . "pass"))))))
