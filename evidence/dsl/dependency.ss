;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(defrules transitive-dependencies ()
  ((_ edge path)
   (ascent-fragment
    (relation path (from to))
    ((path from to) <-- (edge from to))
    ((path from to) <-- (edge from middle) (path middle to)))))

(def (make-dependency-relations)
  (ascent-fragment
   (relation dependency (from to))
   (transitive-dependencies dependency ancestry)))

(def (native-copy-rule from to)
  (let (terms (list (gerbil-ascent-variable 'from) (gerbil-ascent-variable 'to)))
    (gerbil-ascent-rule
     (list (gerbil-ascent-atom to terms))
     (list (gerbil-ascent-atom from terms)))))

