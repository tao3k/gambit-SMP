(require 'json)
(let* ((data (with-temp-buffer
               (insert-file-contents ".cache/tasks/still-receipt-admission/org-parse.json")
               (json-parse-buffer :object-type 'alist :array-type 'list)))
       (missing nil) (bad-anchors nil))
  (dolist (link (alist-get 'fileLinks data))
    (let* ((target (expand-file-name (alist-get 'path link)
                    (file-name-directory (expand-file-name (alist-get 'source link)))))
           (search (alist-get 'search link)))
      (cond ((not (file-exists-p target)) (push link missing))
            ((and (string-prefix-p "#" search) (string-suffix-p ".org" target))
             (with-temp-buffer
               (insert-file-contents target)
               (unless (re-search-forward
                        (concat "^:CUSTOM_ID:[ \t]*" (regexp-quote (substring search 1)) "[ \t]*$") nil t)
                 (push link bad-anchors)))))))
  (with-temp-file ".cache/tasks/still-receipt-admission/org-links.json"
    (insert (json-encode (list :fileLinks (length (alist-get 'fileLinks data))
      :missingFiles (vconcat missing) :missingCustomIds (vconcat bad-anchors)
      :duplicateIds (vconcat (alist-get 'duplicateIds data))
      :babelExecuted :json-false :nativeRuntimeTest :json-false))))
  (when (or missing bad-anchors (alist-get 'duplicateIds data)) (kill-emacs 1)))
