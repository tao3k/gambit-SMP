;; Read-only image correspondence and conditional model evidence.
(ascent-fragment
 (relation required_step ((step symbol?)))
 (relation observed_step ((step symbol?) (status string?) (capability string?)))
 (relation linked_image ((step symbol?) (image string?) (architecture string?)))
 (relation image_byte_cut ((step symbol?) (image string?) (cut string?) (start string?) (digest string?)))
 (relation image_direct_edge ((step symbol?) (image string?) (edge string?) (from string?) (to string?) (kind string?)))
 (relation image_address_slot ((step symbol?) (image string?) (slot string?) (save string?) (return string?) (overwrite string?) (offset integer?) (status string?)))
 (relation readable_parent ((image string?) (slot string?) (return string?) (overwrite string?)))
 (relation conditional_answer ((question string?) (status string?)))
 (relation local_need ((step symbol?) (capability string?)))
 (relation local_open ((step symbol?)))
 (relation native_open ((obligation string?)))
 ((local_need (lit (quote soft-budget)) (lit "quint.observe")) <-- (required_step _))
 ((local_need (lit (quote half-capacity)) (lit "quint.observe")) <-- (required_step _))
 ((local_need (lit (quote frame-geometry)) (lit "lean.check")) <-- (required_step _))
 ((local_need (lit (quote linked-cuts)) (lit "source.contract")) <-- (required_step _))
 ((local_open S) <-- (local_need S C) (not (observed_step S (lit "PASS") C)))
 ((readable_parent I N R O) <--
   (image_address_slot _ I N _ R O (lit 208) (lit "ABI-conditional-readable-address")))
 ((conditional_answer (lit "q1") (lit "valid-current-half-prefix-exits-before-pin; whole-language-witness-open")) <--
   (image_direct_edge _ _ (lit "stop-to-success-release") _ _ (lit "conditional"))
   (observed_step (lit (quote frame-geometry)) (lit "PASS") (lit "lean.check")))
 ((conditional_answer (lit "q2") (lit "nine-not-excluded-by-publication-caps; natural-producer-open")) <--
   (image_byte_cut _ _ (lit "soft-publication") _ _)
   (observed_step (lit (quote soft-budget)) (lit "PASS") (lit "quint.observe"))
   (observed_step (lit (quote frame-geometry)) (lit "PASS") (lit "lean.check")))
 ((conditional_answer (lit "q3") (lit "caller-SP-address-window-present; not-a-root-or-native-GC-witness")) <--
   (readable_parent I (lit "ordinary-parent-address") _ _)
   (readable_parent I (lit "keyword-parent-address") _ _))
 ;; native_open stays empty here. A byte fragment has no native scope and
 ;; must not emit open obligations merely because a step exists.
)
