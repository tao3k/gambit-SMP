(require 'org)
(require 'seq)
(require 'org-element)
(require 'json)
(setq enable-local-variables nil org-confirm-babel-evaluate t)
(let ((files (with-temp-buffer
               (insert-file-contents ".cache/tasks/still-completion-lifetime/artifacts.txt")
               (seq-filter (lambda (f) (string-suffix-p ".org" f))
                           (split-string (buffer-string) "\n" t))))
      (headings 0) (links 0) (blocks 0) (ids (make-hash-table :test 'equal))
      (duplicates nil) (file-links nil) (models nil))
  (dolist (file files)
    (with-temp-buffer
      (setq buffer-file-name (expand-file-name file))
      (setq default-directory (file-name-directory buffer-file-name))
      (insert-file-contents buffer-file-name)
      (org-mode)
      (let ((tree (org-element-parse-buffer)))
        (org-element-map tree 'headline
          (lambda (el)
            (setq headings (1+ headings))
            (let ((id (org-element-property :ID el)))
              (when id
                (if (gethash id ids) (push (list id file) duplicates)
                  (puthash id file ids))))))
        (org-element-map tree 'src-block
          (lambda (el) (setq blocks (1+ blocks))))
        (org-element-map tree 'link
          (lambda (el)
            (setq links (1+ links))
            (when (equal (org-element-property :type el) "file")
              (push (list :source file :path (org-element-property :path el)
                          :search (or (org-element-property :search-option el) ""))
                    file-links)))))))
  (with-temp-file ".cache/tasks/still-completion-lifetime/org-parse.json"
    (insert (json-encode
             (list :files (length files) :headings headings :sourceBlocks blocks
                   :links links :stableIds (hash-table-count ids)
                   :duplicateIds (vconcat duplicates)
                   :fileLinks (vconcat file-links)
                   :babelExecuted :json-false :exportExecuted :json-false))))
  (princ (format "Org parse: %d files, %d headings, %d links, %d stable IDs, %d duplicates\n"
                 (length files) headings links (hash-table-count ids) (length duplicates)))
  (when duplicates (kill-emacs 1)))
