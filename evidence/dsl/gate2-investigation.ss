;; Receipt checks describe evidence gaps. The caller chooses which route to pursue.
(define-evidence (make-gate2-investigation)
  (sources gate2_site gate2_handler gate2_image_check gate2_member_check gate2_site_check
           gate2_draft_candidate gate2_target gate2_not_selected gate2_collection_ready gate2_missing_map
           gate2_site_unit gate2_emission_pair)
  (outputs gate2_evidence_status gate2_open_route gate2_reusable gate2_repair_need
           gate2_fillable gate2_target_option gate2_collection)
  (relation gate2_site (site image object))
  (relation gate2_site_unit (site unit))
  (relation gate2_emission_pair (unit))
  (relation gate2_handler (object))
  (relation gate2_image_check (image check subject status reason))
  (relation gate2_member_check (image object status reason))
  (relation gate2_site_check (site check subject status reason))
  (relation gate2_check_route (check route))
  (relation gate2_required_member (site image object))
  (relation gate2_evidence_status (site route check subject status reason))
  (relation gate2_open_route (site route))
  (relation gate2_reusable (site check subject))
  (relation gate2_repair_need (site check subject action))
  (relation gate2_draft_candidate (scope field))
  (relation gate2_fillable (scope field))
  (relation gate2_target (requested recorded))
  (relation gate2_target_option (action digest))
  (relation gate2_not_selected (image object))
  (relation gate2_excluded_member (site object))
  (relation gate2_collection_ready ())
  (relation gate2_missing_map (image))
  (relation gate2_collection (kind subject))
  (fact (gate2_check_route (lit "finalLink") (lit "makeProvenance")))
  (fact (gate2_check_route (lit "objectSelection") (lit "makeProvenance")))
  (fact (gate2_check_route (lit "handlerCompileInputs") (lit "makeProvenance")))
  (fact (gate2_check_route (lit "imageDeclaration") (lit "makeProvenance")))
  (fact (gate2_check_route (lit "objectDeclaration") (lit "makeProvenance")))
  (fact (gate2_check_route (lit "handlerDeclaration") (lit "makeProvenance")))
  (fact (gate2_check_route (lit "schemeGvm") (lit "schemeGvm")))
  (fact (gate2_check_route (lit "sameInvocationArtifacts") (lit "schemeGvm")))
  (fact (gate2_check_route (lit "oldFrameBacking") (lit "nativeFrame")))
  (fact (gate2_check_route (lit "savedHandlerFp") (lit "nativeFrame")))
  (fact (gate2_check_route (lit "unwoundCallerFp") (lit "nativeFrame")))
  (fact (gate2_check_route (lit "firstWrite") (lit "nativeFrame")))
  (fact (gate2_check_route (lit "noCommittedReplay") (lit "nativeFrame")))
  (fact (gate2_check_route (lit "nativeFrameComplete") (lit "nativeFrame")))
  ((gate2_required_member Site Image Object) <-- (gate2_site Site Image Object))
  ((gate2_required_member Site Image Object) <-- (gate2_site Site Image _) (gate2_handler Object))
  ((gate2_evidence_status Site Route Check Subject Status Reason) <--
    (gate2_site Site Image _) (gate2_image_check Image Check Subject Status Reason)
    (gate2_check_route Check Route))
  ((gate2_evidence_status Site Route (lit "objectSelection") Object Status Reason) <--
    (gate2_required_member Site Image Object) (gate2_member_check Image Object Status Reason)
    (gate2_check_route (lit "objectSelection") Route))
  ((gate2_evidence_status Site Route Check Subject Status Reason) <--
    (gate2_site_check Site Check Subject Status Reason) (gate2_check_route Check Route))
  ((gate2_open_route Site Route) <--
    (gate2_evidence_status Site Route _ _ Status _)
    (if (Status) (not (equal? Status "PASS"))))
  ((gate2_reusable Site Check Subject) <--
    (gate2_evidence_status Site _ Check Subject (lit "PASS") _))
  ((gate2_repair_need Site Check Subject (lit "locate-prerequisite")) <--
    (gate2_evidence_status Site _ Check Subject (lit "BLOCKED") _))
  ((gate2_repair_need Site Check Subject (lit "recover-or-reobserve")) <--
    (gate2_evidence_status Site (lit "makeProvenance") Check Subject (lit "MISSING") _)
    (not (gate2_excluded_member Site Subject))
    (if (Check) (or (equal? Check "finalLink") (equal? Check "objectSelection")
                    (equal? Check "handlerCompileInputs"))))
  ((gate2_excluded_member Site Object) <--
    (gate2_required_member Site Image Object) (gate2_not_selected Image Object))
  ((gate2_repair_need Site (lit "objectSelection") Object (lit "review-successor")) <--
    (gate2_excluded_member Site Object))
  ((gate2_repair_need Site (lit "schemeGvm") Subject (lit "review-or-reobserve-mapping")) <--
    (gate2_evidence_status Site (lit "schemeGvm") (lit "schemeGvm") Subject Status _)
    (if (Status) (or (equal? Status "MISSING") (equal? Status "MISMATCH"))))
  ((gate2_repair_need Site Check Subject (lit "resolve-conflict")) <--
    (gate2_evidence_status Site (lit "makeProvenance") Check Subject (lit "MISMATCH") _))
  ((gate2_repair_need Site Check Subject (lit "complete-declaration")) <--
    (gate2_evidence_status Site _ Check Subject (lit "MISSING") _)
    (if (Check) (or (equal? Check "imageDeclaration") (equal? Check "objectDeclaration")
                    (equal? Check "handlerDeclaration"))))
  ((gate2_fillable Site (lit "objectSha256")) <--
    (gate2_draft_candidate Site (lit "objectSha256")) (gate2_site Site _ Object)
    (gate2_reusable Site (lit "objectSelection") Object)
    (gate2_reusable Site (lit "schemeGvm") _))
  ((gate2_fillable Site Field) <--
    (gate2_draft_candidate Site Field) (gate2_site Site Image Object)
    (gate2_reusable Site (lit "finalLink") Image)
    (gate2_reusable Site (lit "objectSelection") Object)
    (gate2_reusable Site (lit "schemeGvm") _)
    (if (Field) (or (equal? Field "image") (equal? Field "imageSha256"))))
  ((gate2_fillable Image (lit "handler")) <--
    (gate2_draft_candidate Image (lit "handler"))
    (gate2_image_check Image (lit "finalLink") Image (lit "PASS") _))
  ((gate2_target_option (lit "recover-exact-image") Requested) <--
    (gate2_target Requested Recorded)
    (if (Requested Recorded) (not (equal? Requested Recorded))))
  ((gate2_target_option (lit "recover-exact-image") Requested) <--
    (gate2_target Requested Requested) (gate2_repair_need _ _ _ (lit "recover-or-reobserve")))
  ((gate2_target_option (lit "review-recorded-image") Recorded) <--
    (gate2_target Requested Recorded)
    (if (Requested Recorded) (not (equal? Requested Recorded))))
  ((gate2_collection (lit "link-map") Image) <--
    (gate2_collection_ready) (gate2_missing_map Image)
    (gate2_site Site Image _) (gate2_reusable Site (lit "finalLink") Image))
  ((gate2_collection (lit "handler-inputs") Object) <--
    (gate2_collection_ready)
    (gate2_repair_need _ (lit "handlerCompileInputs") Object (lit "recover-or-reobserve")))
  ((gate2_collection (lit "emit-gvm") Unit) <--
    (gate2_collection_ready) (gate2_site_unit Site Unit)
    (not (gate2_emission_pair Unit))
    (gate2_repair_need Site (lit "schemeGvm") _ (lit "review-or-reobserve-mapping")))
  ((gate2_repair_need Site Check Subject (lit "observe-or-repair-native-frame")) <--
    (gate2_evidence_status Site (lit "nativeFrame") Check Subject Status _)
    (if (Status) (not (equal? Status "PASS"))))
  ((gate2_collection (lit "native-frame") Site) <--
    (gate2_collection_ready)
    (gate2_reusable Site (lit "schemeGvm") _)
    (gate2_repair_need Site _ _ (lit "observe-or-repair-native-frame")))
  ((gate2_collection (lit "scheme-gvm") Site) <--
    (gate2_collection_ready)
    (gate2_repair_need Site (lit "schemeGvm") _ (lit "review-or-reobserve-mapping"))))
