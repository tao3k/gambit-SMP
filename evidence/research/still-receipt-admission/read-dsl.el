(require 'json)
(let* ((path (getenv "RA_DSL")) (out (getenv "RA_DSL_JSON")) (ast (with-temp-buffer (insert-file-contents path) (read (current-buffer)))) (facts nil))
 (dolist (form (cddr ast))
  (when (eq (car-safe form) 'fact)
   (let ((row (cadr form)))
    (push (cons (symbol-name (car row)) (vconcat (cdr row))) facts))))
 (with-temp-file out
  (insert (json-encode (vconcat (mapcar (lambda (x) (vector (car x) (cdr x))) (nreverse facts)))))))
