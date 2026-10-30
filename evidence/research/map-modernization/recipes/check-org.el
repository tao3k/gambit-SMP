(require 'org)
(require 'json)
(setq enable-local-variables nil org-confirm-babel-evaluate t)
(let ((files '("dev/refactoring/modern-c/map-multishot-composition.org"
               "dev/refactoring/modern-c/map-multishot-matrix.org"
               "dev/refactoring/modern-c/index.org"
               "dev/refactoring/modern-c/modernization-target.org"
               "dev/architecture/runtime/control/index.org"))
      (count 0) (links 0))
  (dolist (file files)
    (with-temp-buffer
      (insert-file-contents file)
      (org-mode)
      (let ((tree (org-element-parse-buffer)) (ids (make-hash-table :test 'equal)))
        (org-element-map tree 'headline
          (lambda (h)
            (let ((id (org-element-property :CUSTOM_ID h)))
              (when id
                (when (gethash id ids) (error "Duplicate CUSTOM_ID %s" id))
                (puthash id t ids)))))
        ;; Existing index links retain their own historical audits. Check new views.
        (when (member file (seq-take files 2))
          (org-element-map tree 'link
            (lambda (link)
              (when (equal (org-element-property :type link) "file")
                (let* ((path (org-element-property :path link))
                       (target (expand-file-name path (file-name-directory file))))
                  (unless (file-exists-p target) (error "Missing link %s" target))
                  (setq links (1+ links))))))))
      (setq count (1+ count))))
  (with-temp-file ".cache/tasks/map-modernization/org-check.json"
    (insert (json-encode `((parsedFiles . ,count) (newFileLinksChecked . ,links)
                          (babelExecuted . :json-false) (status . "pass"))))))
