(declare (block) (standard-bindings) (extended-bindings) (inlining-limit 200))
(begin
  (define |std/iter/macros[1]#_g200775_|
    (##structure
     gx#syntax-quote::t
     'when
     #f
     (gx#current-expander-context)
     '()))
  (define |std/iter/macros[1]#_g200777_|
    (##structure
     gx#syntax-quote::t
     'unless
     #f
     (gx#current-expander-context)
     '()))
  (define |std/iter/macros[1]#_g200792_|
    (##structure
     gx#syntax-quote::t
     'in-range
     #f
     (gx#current-expander-context)
     '()))
  (define |std/iter/macros[1]#_g200794_|
    (##structure
     gx#syntax-quote::t
     'in-range-inclusive
     #f
     (gx#current-expander-context)
     '()))
  (define |std/iter/macros[1]#_g200796_|
    (##structure
     gx#syntax-quote::t
     'in-integers
     #f
     (gx#current-expander-context)
     '()))
  (define |std/iter/macros[1]#_g200798_|
    (##structure
     gx#syntax-quote::t
     'in-numbers
     #f
     (gx#current-expander-context)
     '()))
  (define |std/iter/macros[1]#_g200800_|
    (##structure
     gx#syntax-quote::t
     'in-list
     #f
     (gx#current-expander-context)
     '()))
  (define |std/iter/macros[1]#_g200802_|
    (##structure
     gx#syntax-quote::t
     'in-vector
     #f
     (gx#current-expander-context)
     '()))
  (define |std/iter/macros[1]#_g200804_|
    (##structure
     gx#syntax-quote::t
     'in-hash
     #f
     (gx#current-expander-context)
     '()))
  (define |std/iter/macros[1]#_g200806_|
    (##structure
     gx#syntax-quote::t
     'in-hash-keys
     #f
     (gx#current-expander-context)
     '()))
  (define |std/iter/macros[1]#_g200808_|
    (##structure
     gx#syntax-quote::t
     'in-hash-values
     #f
     (gx#current-expander-context)
     '()))
  (begin
    (define |std/iter/macros[1]#binding-contract?|
      (lambda (_%contract26900%_)
        (if (let ()
              (declare (not safe))
              (|gerbil/core/contract~Interface[1]#signature-contract?|
               _%contract26900%_))
            (not (member ':=
                         (let ()
                           (declare (not safe))
                           (gx#syntax->list _%contract26900%_))
                         gx#free-identifier=?))
            '#f)))
    (define |std/iter/macros[1]#for-binding?|
      (lambda (_%bind26425%_)
        (let* ((_%__stx199522199523%_ _%bind26425%_)
               (_%$%g2643426520%_
                (lambda ()
                  (let ()
                    (declare (not safe))
                    (gx#raise-syntax-error
                     '#f
                     '"Bad syntax; invalid match target"
                     _%__stx199522199523%_)))))
          (let ((_%__kont199525199526%_
                 (lambda (_%$%g2643626879%_
                          _%$%g2643726881%_
                          _%$%g2643826882%_)
                   '#t))
                (_%__kont199527199528%_
                 (lambda (_%$%g2644526829%_
                          _%$%g2644626831%_
                          _%$%g2644726832%_
                          _%$%g2644826833%_)
                   '#t))
                (_%__kont199529199530%_
                 (lambda (_%$%g2646126759%_
                          _%$%g2646226761%_
                          _%$%g2646326762%_
                          _%$%g2646426763%_)
                   '#t))
                (_%__kont199531199532%_
                 (lambda (_%$%g2647726691%_
                          _%$%g2647826693%_
                          _%$%g2647926694%_)
                   (let ()
                     (declare (not safe))
                     (|gerbil/core/match[1]#match-pattern?|
                      _%$%g2647926694%_))))
                (_%__kont199533199534%_
                 (lambda (_%$%g2649226623%_
                          _%$%g2649326625%_
                          _%$%g2649426626%_)
                   (let ()
                     (declare (not safe))
                     (|gerbil/core/match[1]#match-pattern?|
                      _%$%g2649426626%_))))
                (_%__kont199535199536%_
                 (lambda (_%$%g2650726558%_ _%$%g2650826560%_)
                   (let ()
                     (declare (not safe))
                     (|gerbil/core/match[1]#match-pattern?|
                      _%$%g2650826560%_))))
                (_%__kont199537199538%_ (lambda () '#f)))
            (let* ((_%__match199607199608%_
                    (lambda (_%$%e2646526719%_
                             _%$%hd2646626723%_
                             _%$%tl2646726726%_
                             _%$%e2646826729%_
                             _%$%hd2646926733%_
                             _%$%tl2647026736%_
                             _%$%e2647126739%_
                             _%$%hd2647226743%_
                             _%$%tl2647326746%_
                             _%$%e2647426749%_
                             _%$%hd2647526753%_
                             _%$%tl2647626756%_)
                      (let ((_%$%g2646126759%_ _%$%tl2647626756%_)
                            (_%$%g2646226761%_ _%$%hd2647526753%_)
                            (_%$%g2646326762%_ _%$%hd2646926733%_)
                            (_%$%g2646426763%_ _%$%hd2646626723%_))
                        (if (and (let ()
                                   (declare (not safe))
                                   (gx#identifier? _%$%g2646426763%_))
                                 (|std/iter/macros[1]#binding-contract?|
                                  _%$%g2646126759%_))
                            (_%__kont199529199530%_
                             _%$%g2646126759%_
                             _%$%g2646226761%_
                             _%$%g2646326762%_
                             _%$%g2646426763%_)
                            (if (let ()
                                  (declare (not safe))
                                  (gx#stx-null? _%$%tl2647626756%_))
                                (_%__kont199533199534%_
                                 _%$%hd2647526753%_
                                 _%$%hd2646926733%_
                                 _%$%hd2646626723%_)
                                (_%__kont199537199538%_))))))
                   (_%__match199579199580%_
                    (lambda (_%$%e2644926789%_
                             _%$%hd2645026793%_
                             _%$%tl2645126796%_
                             _%$%e2645226799%_
                             _%$%hd2645326803%_
                             _%$%tl2645426806%_
                             _%$%e2645526809%_
                             _%$%hd2645626813%_
                             _%$%tl2645726816%_
                             _%$%e2645826819%_
                             _%$%hd2645926823%_
                             _%$%tl2646026826%_)
                      (let ((_%$%g2644526829%_ _%$%tl2646026826%_)
                            (_%$%g2644626831%_ _%$%hd2645926823%_)
                            (_%$%g2644726832%_ _%$%hd2645326803%_)
                            (_%$%g2644826833%_ _%$%hd2645026793%_))
                        (if (and (let ()
                                   (declare (not safe))
                                   (gx#identifier? _%$%g2644826833%_))
                                 (|std/iter/macros[1]#binding-contract?|
                                  _%$%g2644526829%_))
                            (_%__kont199527199528%_
                             _%$%g2644526829%_
                             _%$%g2644626831%_
                             _%$%g2644726832%_
                             _%$%g2644826833%_)
                            (if (let ()
                                  (declare (not safe))
                                  (gx#stx-null? _%$%tl2646026826%_))
                                (_%__kont199531199532%_
                                 _%$%hd2645926823%_
                                 _%$%hd2645326803%_
                                 _%$%hd2645026793%_)
                                (_%__kont199537199538%_))))))
                   (_%__match199551199552%_
                    (lambda (_%$%e2643926859%_
                             _%$%hd2644026863%_
                             _%$%tl2644126866%_
                             _%$%e2644226869%_
                             _%$%hd2644326873%_
                             _%$%tl2644426876%_)
                      (let ((_%$%g2643626879%_ _%$%tl2644426876%_)
                            (_%$%g2643726881%_ _%$%hd2644326873%_)
                            (_%$%g2643826882%_ _%$%hd2644026863%_))
                        (if (and (let ()
                                   (declare (not safe))
                                   (gx#identifier? _%$%g2643826882%_))
                                 (|std/iter/macros[1]#binding-contract?|
                                  _%$%g2643626879%_))
                            (_%__kont199525199526%_
                             _%$%g2643626879%_
                             _%$%g2643726881%_
                             _%$%g2643826882%_)
                            (if (let ()
                                  (declare (not safe))
                                  (gx#stx-pair? _%$%tl2644426876%_))
                                (let ((_%$%e2645526809%_
                                       (let ()
                                         (declare (not safe))
                                         (gx#syntax-e _%$%tl2644426876%_))))
                                  (let ((_%$%tl2645726816%_
                                         (let ()
                                           (declare (not safe))
                                           (##cdr _%$%e2645526809%_)))
                                        (_%$%hd2645626813%_
                                         (let ()
                                           (declare (not safe))
                                           (##car _%$%e2645526809%_))))
                                    (if (let ()
                                          (declare (not safe))
                                          (gx#identifier? _%$%hd2645626813%_))
                                        (if (let ((__tmp200774
                                                   |std/iter/macros[1]#_g200775_|))
                                              (declare (not safe))
                                              (gx#free-identifier=?
                                               __tmp200774
                                               _%$%hd2645626813%_))
                                            (if (let ()
                                                  (declare (not safe))
                                                  (gx#stx-pair?
                                                   _%$%tl2645726816%_))
                                                (let ((_%$%e2645826819%_
                                                       (let ()
                                                         (declare (not safe))
                                                         (gx#syntax-e
                                                          _%$%tl2645726816%_))))
                                                  (let ((_%$%tl2646026826%_
                                                         (let ()
                                                           (declare (not safe))
                                                           (##cdr _%$%e2645826819%_)))
                                                        (_%$%hd2645926823%_
                                                         (let ()
                                                           (declare (not safe))
                                                           (##car _%$%e2645826819%_))))
                                                    (_%__match199579199580%_
                                                     _%$%e2643926859%_
                                                     _%$%hd2644026863%_
                                                     _%$%tl2644126866%_
                                                     _%$%e2644226869%_
                                                     _%$%hd2644326873%_
                                                     _%$%tl2644426876%_
                                                     _%$%e2645526809%_
                                                     _%$%hd2645626813%_
                                                     _%$%tl2645726816%_
                                                     _%$%e2645826819%_
                                                     _%$%hd2645926823%_
                                                     _%$%tl2646026826%_)))
                                                (_%__kont199537199538%_))
                                            (if (let ((__tmp200776
                                                       |std/iter/macros[1]#_g200777_|))
                                                  (declare (not safe))
                                                  (gx#free-identifier=?
                                                   __tmp200776
                                                   _%$%hd2645626813%_))
                                                (if (let ()
                                                      (declare (not safe))
                                                      (gx#stx-pair?
                                                       _%$%tl2645726816%_))
                                                    (let ((_%$%e2647426749%_
                                                           (let ()
                                                             (declare
                                                               (not safe))
                                                             (gx#syntax-e
                                                              _%$%tl2645726816%_))))
                                                      (let ((_%$%tl2647626756%_
                                                             (let ()
                                                               (declare
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (not safe))
                       (##cdr _%$%e2647426749%_)))
                    (_%$%hd2647526753%_
                     (let () (declare (not safe)) (##car _%$%e2647426749%_))))
                (_%__match199607199608%_
                 _%$%e2643926859%_
                 _%$%hd2644026863%_
                 _%$%tl2644126866%_
                 _%$%e2644226869%_
                 _%$%hd2644326873%_
                 _%$%tl2644426876%_
                 _%$%e2645526809%_
                 _%$%hd2645626813%_
                 _%$%tl2645726816%_
                 _%$%e2647426749%_
                 _%$%hd2647526753%_
                 _%$%tl2647626756%_)))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                    (_%__kont199537199538%_))
                                                (_%__kont199537199538%_)))
                                        (_%__kont199537199538%_))))
                                (if (let ()
                                      (declare (not safe))
                                      (gx#stx-null? _%$%tl2644426876%_))
                                    (_%__kont199535199536%_
                                     _%$%hd2644326873%_
                                     _%$%hd2644026863%_)
                                    (_%__kont199537199538%_))))))))
              (if (let ()
                    (declare (not safe))
                    (gx#stx-pair? _%__stx199522199523%_))
                  (let ((_%$%e2643926859%_
                         (let ()
                           (declare (not safe))
                           (gx#syntax-e _%__stx199522199523%_))))
                    (let ((_%$%tl2644126866%_
                           (let ()
                             (declare (not safe))
                             (##cdr _%$%e2643926859%_)))
                          (_%$%hd2644026863%_
                           (let ()
                             (declare (not safe))
                             (##car _%$%e2643926859%_))))
                      (if (let ()
                            (declare (not safe))
                            (gx#stx-pair? _%$%tl2644126866%_))
                          (let ((_%$%e2644226869%_
                                 (let ()
                                   (declare (not safe))
                                   (gx#syntax-e _%$%tl2644126866%_))))
                            (let ((_%$%tl2644426876%_
                                   (let ()
                                     (declare (not safe))
                                     (##cdr _%$%e2644226869%_)))
                                  (_%$%hd2644326873%_
                                   (let ()
                                     (declare (not safe))
                                     (##car _%$%e2644226869%_))))
                              (_%__match199551199552%_
                               _%$%e2643926859%_
                               _%$%hd2644026863%_
                               _%$%tl2644126866%_
                               _%$%e2644226869%_
                               _%$%hd2644326873%_
                               _%$%tl2644426876%_)))
                          (_%__kont199537199538%_))))
                  (_%__kont199537199538%_)))))))
    (define |std/iter/macros[:0:]#for|
      (lambda (_%$stx26903%_)
        (let* ((_%__stx199684199685%_ _%$stx26903%_)
               (_%$%g2690826966%_
                (lambda ()
                  (let ()
                    (declare (not safe))
                    (gx#raise-syntax-error
                     '#f
                     '"Bad syntax; invalid match target"
                     _%__stx199684199685%_)))))
          (let ((_%__kont199687199688%_
                 (lambda (_%$%g2691027168%_
                          _%$%g2691127170%_
                          _%$%g2691227171%_)
                   (cons (let ()
                           (declare (not safe))
                           (gx#datum->syntax__0 '#f 'for1))
                         (cons _%$%g2691227171%_
                               (cons (cons (let ()
                                             (declare (not safe))
                                             (gx#datum->syntax__0 '#f 'let))
                                           (cons '()
                                                 (cons _%$%g2691127170%_
                                                       (let ((__tmp200778
                                                              (lambda (_%$%g2719027193%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                               _%$%g2719127196%_)
                        (cons _%$%g2719027193%_ _%$%g2719127196%_))))
                 (declare (not safe))
                 (foldr__0 __tmp200778 '() _%$%g2691027168%_)))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                     '())))))
                (_%__kont199691199692%_
                 (lambda (_%$%g2693127059%_
                          _%$%g2693227061%_
                          _%$%g2693327062%_)
                   (cons (let ()
                           (declare (not safe))
                           (gx#datum->syntax__0 '#f 'forN))
                         (cons (let ((__tmp200779
                                      (lambda (_%$%g2708627091%_
                                               _%$%g2708727094%_)
                                        (cons _%$%g2708627091%_
                                              _%$%g2708727094%_))))
                                 (declare (not safe))
                                 (foldr__0 __tmp200779 '() _%$%g2693327062%_))
                               (cons (cons (let ()
                                             (declare (not safe))
                                             (gx#datum->syntax__0 '#f 'let))
                                           (cons '()
                                                 (cons _%$%g2693227061%_
                                                       (let ((__tmp200780
                                                              (lambda (_%$%g2708827097%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                               _%$%g2708927100%_)
                        (cons _%$%g2708827097%_ _%$%g2708927100%_))))
                 (declare (not safe))
                 (foldr__0 __tmp200780 '() _%$%g2693127059%_)))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                     '()))))))
            (let* ((_%__match199743199744%_
                    (lambda (_%$%e2693426973%_
                             _%$%hd2693526977%_
                             _%$%tl2693626980%_
                             _%$%e2693726983%_
                             _%$%hd2693826987%_
                             _%$%tl2693926990%_
                             _%__splice199693199694%_
                             _%$%target2694026993%_
                             _%$%tl2694226996%_)
                      (letrec ((_%$%loop2694326999%_
                                (lambda (_%$%hd2694127003%_
                                         _%$%bind2694727006%_)
                                  (if (let ()
                                        (declare (not safe))
                                        (gx#stx-pair? _%$%hd2694127003%_))
                                      (let ((_%$%e2694427008%_
                                             (let ()
                                               (declare (not safe))
                                               (gx#syntax-e
                                                _%$%hd2694127003%_))))
                                        (let ((_%$%lp-tl2694627015%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##cdr _%$%e2694427008%_)))
                                              (_%$%lp-hd2694527012%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##car _%$%e2694427008%_))))
                                          (_%$%loop2694326999%_
                                           _%$%lp-tl2694627015%_
                                           (cons _%$%lp-hd2694527012%_
                                                 _%$%bind2694727006%_))))
                                      (let ((_%$%bind2694827018%_
                                             (reverse _%$%bind2694727006%_)))
                                        (if (let ()
                                              (declare (not safe))
                                              (gx#stx-pair?
                                               _%$%tl2693926990%_))
                                            (let ((_%$%e2694927021%_
                                                   (let ()
                                                     (declare (not safe))
                                                     (gx#syntax-e
                                                      _%$%tl2693926990%_))))
                                              (let ((_%$%tl2695127028%_
                                                     (let ()
                                                       (declare (not safe))
                                                       (##cdr _%$%e2694927021%_)))
                                                    (_%$%hd2695027025%_
                                                     (let ()
                                                       (declare (not safe))
                                                       (##car _%$%e2694927021%_))))
                                                (if (let ()
                                                      (declare (not safe))
                                                      (gx#stx-pair/null?
                                                       _%$%tl2695127028%_))
                                                    (let ((_%__splice199695199696%_
                                                           (let ()
                                                             (declare
                                                               (not safe))
                                                             (gx#syntax-split-splice->vector
                                                              _%$%tl2695127028%_
                                                              '0))))
                                                      (let ((_%$%tl2695427034%_
                                                             (let ()
                                                               (declare
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (not safe))
                       (##vector-ref _%__splice199695199696%_ '1)))
                    (_%$%target2695227031%_
                     (let ()
                       (declare (not safe))
                       (##vector-ref _%__splice199695199696%_ '0))))
                (if (let ()
                      (declare (not safe))
                      (gx#stx-null? _%$%tl2695427034%_))
                    (letrec ((_%$%loop2695527037%_
                              (lambda (_%$%hd2695327041%_ _%$%rest2695927044%_)
                                (if (let ()
                                      (declare (not safe))
                                      (gx#stx-pair? _%$%hd2695327041%_))
                                    (let ((_%$%e2695627046%_
                                           (let ()
                                             (declare (not safe))
                                             (gx#syntax-e
                                              _%$%hd2695327041%_))))
                                      (let ((_%$%lp-tl2695827053%_
                                             (let ()
                                               (declare (not safe))
                                               (##cdr _%$%e2695627046%_)))
                                            (_%$%lp-hd2695727050%_
                                             (let ()
                                               (declare (not safe))
                                               (##car _%$%e2695627046%_))))
                                        (_%$%loop2695527037%_
                                         _%$%lp-tl2695827053%_
                                         (cons _%$%lp-hd2695727050%_
                                               _%$%rest2695927044%_))))
                                    (let ((_%$%rest2696027056%_
                                           (reverse _%$%rest2695927044%_)))
                                      (_%__kont199691199692%_
                                       _%$%rest2696027056%_
                                       _%$%hd2695027025%_
                                       _%$%bind2694827018%_))))))
                      (_%$%loop2695527037%_ _%$%target2695227031%_ '()))
                    (let () (declare (not safe)) (_%$%g2690826966%_)))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                    (let ()
                                                      (declare (not safe))
                                                      (_%$%g2690826966%_)))))
                                            (let ()
                                              (declare (not safe))
                                              (_%$%g2690826966%_))))))))
                        (_%$%loop2694326999%_ _%$%target2694026993%_ '()))))
                   (_%__match199735199736%_
                    (lambda (_%$%e2693426973%_
                             _%$%hd2693526977%_
                             _%$%tl2693626980%_
                             _%$%e2693726983%_
                             _%$%hd2693826987%_
                             _%$%tl2693926990%_)
                      (if (let ()
                            (declare (not safe))
                            (gx#stx-pair/null? _%$%hd2693826987%_))
                          (let ((_%__splice199693199694%_
                                 (let ()
                                   (declare (not safe))
                                   (gx#syntax-split-splice->vector
                                    _%$%hd2693826987%_
                                    '0))))
                            (let ((_%$%tl2694226996%_
                                   (let ()
                                     (declare (not safe))
                                     (##vector-ref
                                      _%__splice199693199694%_
                                      '1)))
                                  (_%$%target2694026993%_
                                   (let ()
                                     (declare (not safe))
                                     (##vector-ref
                                      _%__splice199693199694%_
                                      '0))))
                              (if (let ()
                                    (declare (not safe))
                                    (gx#stx-null? _%$%tl2694226996%_))
                                  (_%__match199743199744%_
                                   _%$%e2693426973%_
                                   _%$%hd2693526977%_
                                   _%$%tl2693626980%_
                                   _%$%e2693726983%_
                                   _%$%hd2693826987%_
                                   _%$%tl2693926990%_
                                   _%__splice199693199694%_
                                   _%$%target2694026993%_
                                   _%$%tl2694226996%_)
                                  (let ()
                                    (declare (not safe))
                                    (_%$%g2690826966%_)))))
                          (let () (declare (not safe)) (_%$%g2690826966%_)))))
                   (_%__match199723199724%_
                    (lambda (_%$%e2691327110%_
                             _%$%hd2691427114%_
                             _%$%tl2691527117%_
                             _%$%e2691627120%_
                             _%$%hd2691727124%_
                             _%$%tl2691827127%_
                             _%$%e2691927130%_
                             _%$%hd2692027134%_
                             _%$%tl2692127137%_
                             _%__splice199689199690%_
                             _%$%target2692227140%_
                             _%$%tl2692427143%_)
                      (letrec ((_%$%loop2692527146%_
                                (lambda (_%$%hd2692327150%_
                                         _%$%rest2692927153%_)
                                  (if (let ()
                                        (declare (not safe))
                                        (gx#stx-pair? _%$%hd2692327150%_))
                                      (let ((_%$%e2692627155%_
                                             (let ()
                                               (declare (not safe))
                                               (gx#syntax-e
                                                _%$%hd2692327150%_))))
                                        (let ((_%$%lp-tl2692827162%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##cdr _%$%e2692627155%_)))
                                              (_%$%lp-hd2692727159%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##car _%$%e2692627155%_))))
                                          (_%$%loop2692527146%_
                                           _%$%lp-tl2692827162%_
                                           (cons _%$%lp-hd2692727159%_
                                                 _%$%rest2692927153%_))))
                                      (let ((_%$%rest2693027165%_
                                             (reverse _%$%rest2692927153%_)))
                                        (let ((_%$%g2691027168%_
                                               _%$%rest2693027165%_)
                                              (_%$%g2691127170%_
                                               _%$%hd2692027134%_)
                                              (_%$%g2691227171%_
                                               _%$%hd2691727124%_))
                                          (if (|std/iter/macros[1]#for-binding?|
                                               _%$%g2691227171%_)
                                              (_%__kont199687199688%_
                                               _%$%g2691027168%_
                                               _%$%g2691127170%_
                                               _%$%g2691227171%_)
                                              (_%__match199735199736%_
                                               _%$%e2691327110%_
                                               _%$%hd2691427114%_
                                               _%$%tl2691527117%_
                                               _%$%e2691627120%_
                                               _%$%hd2691727124%_
                                               _%$%tl2691827127%_))))))))
                        (_%$%loop2692527146%_ _%$%target2692227140%_ '())))))
              (if (let ()
                    (declare (not safe))
                    (gx#stx-pair? _%__stx199684199685%_))
                  (let ((_%$%e2691327110%_
                         (let ()
                           (declare (not safe))
                           (gx#syntax-e _%__stx199684199685%_))))
                    (let ((_%$%tl2691527117%_
                           (let ()
                             (declare (not safe))
                             (##cdr _%$%e2691327110%_)))
                          (_%$%hd2691427114%_
                           (let ()
                             (declare (not safe))
                             (##car _%$%e2691327110%_))))
                      (if (let ()
                            (declare (not safe))
                            (gx#stx-pair? _%$%tl2691527117%_))
                          (let ((_%$%e2691627120%_
                                 (let ()
                                   (declare (not safe))
                                   (gx#syntax-e _%$%tl2691527117%_))))
                            (let ((_%$%tl2691827127%_
                                   (let ()
                                     (declare (not safe))
                                     (##cdr _%$%e2691627120%_)))
                                  (_%$%hd2691727124%_
                                   (let ()
                                     (declare (not safe))
                                     (##car _%$%e2691627120%_))))
                              (if (let ()
                                    (declare (not safe))
                                    (gx#stx-pair? _%$%tl2691827127%_))
                                  (let ((_%$%e2691927130%_
                                         (let ()
                                           (declare (not safe))
                                           (gx#syntax-e _%$%tl2691827127%_))))
                                    (let ((_%$%tl2692127137%_
                                           (let ()
                                             (declare (not safe))
                                             (##cdr _%$%e2691927130%_)))
                                          (_%$%hd2692027134%_
                                           (let ()
                                             (declare (not safe))
                                             (##car _%$%e2691927130%_))))
                                      (if (let ()
                                            (declare (not safe))
                                            (gx#stx-pair/null?
                                             _%$%tl2692127137%_))
                                          (let ((_%__splice199689199690%_
                                                 (let ()
                                                   (declare (not safe))
                                                   (gx#syntax-split-splice->vector
                                                    _%$%tl2692127137%_
                                                    '0))))
                                            (let ((_%$%tl2692427143%_
                                                   (let ()
                                                     (declare (not safe))
                                                     (##vector-ref
                                                      _%__splice199689199690%_
                                                      '1)))
                                                  (_%$%target2692227140%_
                                                   (let ()
                                                     (declare (not safe))
                                                     (##vector-ref
                                                      _%__splice199689199690%_
                                                      '0))))
                                              (if (let ()
                                                    (declare (not safe))
                                                    (gx#stx-null?
                                                     _%$%tl2692427143%_))
                                                  (_%__match199723199724%_
                                                   _%$%e2691327110%_
                                                   _%$%hd2691427114%_
                                                   _%$%tl2691527117%_
                                                   _%$%e2691627120%_
                                                   _%$%hd2691727124%_
                                                   _%$%tl2691827127%_
                                                   _%$%e2691927130%_
                                                   _%$%hd2692027134%_
                                                   _%$%tl2692127137%_
                                                   _%__splice199689199690%_
                                                   _%$%target2692227140%_
                                                   _%$%tl2692427143%_)
                                                  (if (let ()
                                                        (declare (not safe))
                                                        (gx#stx-pair/null?
                                                         _%$%hd2691727124%_))
                                                      (let ((_%__splice199693199694%_
                                                             (let ()
                                                               (declare
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (not safe))
                       (gx#syntax-split-splice->vector
                        _%$%hd2691727124%_
                        '0))))
                (let ((_%$%tl2694226996%_
                       (let ()
                         (declare (not safe))
                         (##vector-ref _%__splice199693199694%_ '1)))
                      (_%$%target2694026993%_
                       (let ()
                         (declare (not safe))
                         (##vector-ref _%__splice199693199694%_ '0))))
                  (if (let ()
                        (declare (not safe))
                        (gx#stx-null? _%$%tl2694226996%_))
                      (_%__match199743199744%_
                       _%$%e2691327110%_
                       _%$%hd2691427114%_
                       _%$%tl2691527117%_
                       _%$%e2691627120%_
                       _%$%hd2691727124%_
                       _%$%tl2691827127%_
                       _%__splice199693199694%_
                       _%$%target2694026993%_
                       _%$%tl2694226996%_)
                      (let () (declare (not safe)) (_%$%g2690826966%_)))))
              (let () (declare (not safe)) (_%$%g2690826966%_))))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                          (if (let ()
                                                (declare (not safe))
                                                (gx#stx-pair/null?
                                                 _%$%hd2691727124%_))
                                              (let ((_%__splice199693199694%_
                                                     (let ()
                                                       (declare (not safe))
                                                       (gx#syntax-split-splice->vector
                                                        _%$%hd2691727124%_
                                                        '0))))
                                                (let ((_%$%tl2694226996%_
                                                       (let ()
                                                         (declare (not safe))
                                                         (##vector-ref
                                                          _%__splice199693199694%_
                                                          '1)))
                                                      (_%$%target2694026993%_
                                                       (let ()
                                                         (declare (not safe))
                                                         (##vector-ref
                                                          _%__splice199693199694%_
                                                          '0))))
                                                  (if (let ()
                                                        (declare (not safe))
                                                        (gx#stx-null?
                                                         _%$%tl2694226996%_))
                                                      (_%__match199743199744%_
                                                       _%$%e2691327110%_
                                                       _%$%hd2691427114%_
                                                       _%$%tl2691527117%_
                                                       _%$%e2691627120%_
                                                       _%$%hd2691727124%_
                                                       _%$%tl2691827127%_
                                                       _%__splice199693199694%_
                                                       _%$%target2694026993%_
                                                       _%$%tl2694226996%_)
                                                      (let ()
                                                        (declare (not safe))
                                                        (_%$%g2690826966%_)))))
                                              (let ()
                                                (declare (not safe))
                                                (_%$%g2690826966%_))))))
                                  (if (let ()
                                        (declare (not safe))
                                        (gx#stx-pair/null? _%$%hd2691727124%_))
                                      (let ((_%__splice199693199694%_
                                             (let ()
                                               (declare (not safe))
                                               (gx#syntax-split-splice->vector
                                                _%$%hd2691727124%_
                                                '0))))
                                        (let ((_%$%tl2694226996%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##vector-ref
                                                  _%__splice199693199694%_
                                                  '1)))
                                              (_%$%target2694026993%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##vector-ref
                                                  _%__splice199693199694%_
                                                  '0))))
                                          (if (let ()
                                                (declare (not safe))
                                                (gx#stx-null?
                                                 _%$%tl2694226996%_))
                                              (_%__match199743199744%_
                                               _%$%e2691327110%_
                                               _%$%hd2691427114%_
                                               _%$%tl2691527117%_
                                               _%$%e2691627120%_
                                               _%$%hd2691727124%_
                                               _%$%tl2691827127%_
                                               _%__splice199693199694%_
                                               _%$%target2694026993%_
                                               _%$%tl2694226996%_)
                                              (let ()
                                                (declare (not safe))
                                                (_%$%g2690826966%_)))))
                                      (let ()
                                        (declare (not safe))
                                        (_%$%g2690826966%_))))))
                          (let () (declare (not safe)) (_%$%g2690826966%_)))))
                  (let () (declare (not safe)) (_%$%g2690826966%_))))))))
    (define |std/iter/macros[:0:]#for1|
      (lambda (_%stx27206%_)
        (letrec ((_%make-lambda27209%_
                  (lambda (_%id27637%_ _%traits27639%_ _%body27640%_)
                    (if (let ()
                          (declare (not safe))
                          (gx#stx-null? _%traits27639%_))
                        (let* ((_%$%g2764227657%_
                                (lambda (_%$%g2764327653%_)
                                  (let ()
                                    (declare (not safe))
                                    (gx#raise-syntax-error
                                     '#f
                                     '"Bad syntax; invalid match target"
                                     _%$%g2764327653%_))))
                               (_%$%g2764127702%_
                                (lambda (_%$%g2764327661%_)
                                  (if (let ()
                                        (declare (not safe))
                                        (gx#stx-pair? _%$%g2764327661%_))
                                      (let ((_%$%e2764627664%_
                                             (let ()
                                               (declare (not safe))
                                               (gx#syntax-e
                                                _%$%g2764327661%_))))
                                        (let ((_%$%hd2764727668%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##car _%$%e2764627664%_)))
                                              (_%$%tl2764827671%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##cdr _%$%e2764627664%_))))
                                          (if (let ()
                                                (declare (not safe))
                                                (gx#stx-pair?
                                                 _%$%tl2764827671%_))
                                              (let ((_%$%e2764927674%_
                                                     (let ()
                                                       (declare (not safe))
                                                       (gx#syntax-e
                                                        _%$%tl2764827671%_))))
                                                (let ((_%$%hd2765027678%_
                                                       (let ()
                                                         (declare (not safe))
                                                         (##car _%$%e2764927674%_)))
                                                      (_%$%tl2765127681%_
                                                       (let ()
                                                         (declare (not safe))
                                                         (##cdr _%$%e2764927674%_))))
                                                  (if (let ()
                                                        (declare (not safe))
                                                        (gx#stx-null?
                                                         _%$%tl2765127681%_))
                                                      (let ((__tmp200782
                                                             (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                             (declare (not safe))
                             (gx#datum->syntax__0 '#f 'lambda))
                           (cons (cons _%$%hd2764727668%_ '())
                                 (cons _%$%hd2765027678%_ '()))))
                    (__tmp200781
                     (let ()
                       (declare (not safe))
                       (gx#stx-source _%stx27206%_))))
                (declare (not safe))
                (gx#stx-wrap-source __tmp200782 __tmp200781))
              (_%$%g2764227657%_ _%$%g2764327661%_))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                              (_%$%g2764227657%_
                                               _%$%g2764327661%_))))
                                      (_%$%g2764227657%_ _%$%g2764327661%_)))))
                          (_%$%g2764127702%_
                           (list _%id27637%_
                                 (_%make-lambda-body27211%_
                                  _%id27637%_
                                  '()
                                  _%body27640%_))))
                        (let* ((_%__stx199746199747%_ _%traits27639%_)
                               (_%$%g2770727724%_
                                (lambda ()
                                  (let ()
                                    (declare (not safe))
                                    (gx#raise-syntax-error
                                     '#f
                                     '"Bad syntax; invalid match target"
                                     _%__stx199746199747%_)))))
                          (let ((_%__kont199749199750%_
                                 (lambda (_%$%g2770927831%_
                                          _%$%g2771027833%_
                                          _%$%g2771127834%_)
                                   (let* ((_%$%g2784827863%_
                                           (lambda (_%$%g2784927859%_)
                                             (let ()
                                               (declare (not safe))
                                               (gx#raise-syntax-error
                                                '#f
                                                '"Bad syntax; invalid match target"
                                                _%$%g2784927859%_))))
                                          (_%$%g2784727908%_
                                           (lambda (_%$%g2784927867%_)
                                             (if (let ()
                                                   (declare (not safe))
                                                   (gx#stx-pair?
                                                    _%$%g2784927867%_))
                                                 (let ((_%$%e2785227870%_
                                                        (let ()
                                                          (declare (not safe))
                                                          (gx#syntax-e
                                                           _%$%g2784927867%_))))
                                                   (let ((_%$%hd2785327874%_
                                                          (let ()
                                                            (declare
                                                              (not safe))
                                                            (##car _%$%e2785227870%_)))
                                                         (_%$%tl2785427877%_
                                                          (let ()
                                                            (declare
                                                              (not safe))
                                                            (##cdr _%$%e2785227870%_))))
                                                     (if (let ()
                                                           (declare (not safe))
                                                           (gx#stx-pair?
                                                            _%$%tl2785427877%_))
                                                         (let ((_%$%e2785527880%_
                                                                (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                          (declare (not safe))
                          (gx#syntax-e _%$%tl2785427877%_))))
                   (let ((_%$%hd2785627884%_
                          (let ()
                            (declare (not safe))
                            (##car _%$%e2785527880%_)))
                         (_%$%tl2785727887%_
                          (let ()
                            (declare (not safe))
                            (##cdr _%$%e2785527880%_))))
                     (if (let ()
                           (declare (not safe))
                           (gx#stx-null? _%$%tl2785727887%_))
                         (let ((__tmp200784
                                (cons (let ()
                                        (declare (not safe))
                                        (gx#datum->syntax__0 '#f 'lambda))
                                      (cons (cons _%$%hd2785327874%_ '())
                                            (cons (cons _%$%g2771127834%_
                                                        (cons _%$%g2771027833%_
                                                              (cons _%$%hd2785627884%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                            '())))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                  '()))))
                               (__tmp200783
                                (let ()
                                  (declare (not safe))
                                  (gx#stx-source _%stx27206%_))))
                           (declare (not safe))
                           (gx#stx-wrap-source __tmp200784 __tmp200783))
                         (_%$%g2784827863%_ _%$%g2784927867%_))))
                 (_%$%g2784827863%_ _%$%g2784927867%_))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                 (_%$%g2784827863%_
                                                  _%$%g2784927867%_)))))
                                     (_%$%g2784727908%_
                                      (list _%id27637%_
                                            (_%make-lambda-body27211%_
                                             _%id27637%_
                                             _%$%g2770927831%_
                                             _%body27640%_))))))
                                (_%__kont199751199752%_
                                 (lambda (_%$%g2771827731%_)
                                   (let* ((_%$%g2774027755%_
                                           (lambda (_%$%g2774127751%_)
                                             (let ()
                                               (declare (not safe))
                                               (gx#raise-syntax-error
                                                '#f
                                                '"Bad syntax; invalid match target"
                                                _%$%g2774127751%_))))
                                          (_%$%g2773927800%_
                                           (lambda (_%$%g2774127759%_)
                                             (if (let ()
                                                   (declare (not safe))
                                                   (gx#stx-pair?
                                                    _%$%g2774127759%_))
                                                 (let ((_%$%e2774427762%_
                                                        (let ()
                                                          (declare (not safe))
                                                          (gx#syntax-e
                                                           _%$%g2774127759%_))))
                                                   (let ((_%$%hd2774527766%_
                                                          (let ()
                                                            (declare
                                                              (not safe))
                                                            (##car _%$%e2774427762%_)))
                                                         (_%$%tl2774627769%_
                                                          (let ()
                                                            (declare
                                                              (not safe))
                                                            (##cdr _%$%e2774427762%_))))
                                                     (if (let ()
                                                           (declare (not safe))
                                                           (gx#stx-pair?
                                                            _%$%tl2774627769%_))
                                                         (let ((_%$%e2774727772%_
                                                                (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                          (declare (not safe))
                          (gx#syntax-e _%$%tl2774627769%_))))
                   (let ((_%$%hd2774827776%_
                          (let ()
                            (declare (not safe))
                            (##car _%$%e2774727772%_)))
                         (_%$%tl2774927779%_
                          (let ()
                            (declare (not safe))
                            (##cdr _%$%e2774727772%_))))
                     (if (let ()
                           (declare (not safe))
                           (gx#stx-null? _%$%tl2774927779%_))
                         (let ((__tmp200786
                                (cons (let ()
                                        (declare (not safe))
                                        (gx#datum->syntax__0 '#f 'lambda))
                                      (cons (cons _%$%hd2774527766%_ '())
                                            (cons _%$%hd2774827776%_ '()))))
                               (__tmp200785
                                (let ()
                                  (declare (not safe))
                                  (gx#stx-source _%stx27206%_))))
                           (declare (not safe))
                           (gx#stx-wrap-source __tmp200786 __tmp200785))
                         (_%$%g2774027755%_ _%$%g2774127759%_))))
                 (_%$%g2774027755%_ _%$%g2774127759%_))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                 (_%$%g2774027755%_
                                                  _%$%g2774127759%_)))))
                                     (_%$%g2773927800%_
                                      (list _%id27637%_
                                            (_%make-lambda-body27211%_
                                             _%id27637%_
                                             _%$%g2771827731%_
                                             _%body27640%_)))))))
                            (let ((_%__match199765199766%_
                                   (lambda (_%$%e2771227811%_
                                            _%$%hd2771327815%_
                                            _%$%tl2771427818%_
                                            _%$%e2771527821%_
                                            _%$%hd2771627825%_
                                            _%$%tl2771727828%_)
                                     (let ((_%$%g2770927831%_
                                            _%$%tl2771727828%_)
                                           (_%$%g2771027833%_
                                            _%$%hd2771627825%_)
                                           (_%$%g2771127834%_
                                            _%$%hd2771327815%_))
                                       (if (and (let ()
                                                  (declare (not safe))
                                                  (gx#identifier?
                                                   _%$%g2771127834%_))
                                                (let ()
                                                  (declare (not safe))
                                                  (##member
                                                   _%$%g2771127834%_
                                                   '(when unless)
                                                   gx#free-identifier=?)))
                                           (_%__kont199749199750%_
                                            _%$%g2770927831%_
                                            _%$%g2771027833%_
                                            _%$%g2771127834%_)
                                           (_%__kont199751199752%_
                                            _%__stx199746199747%_))))))
                              (if (let ()
                                    (declare (not safe))
                                    (gx#stx-pair? _%__stx199746199747%_))
                                  (let ((_%$%e2771227811%_
                                         (let ()
                                           (declare (not safe))
                                           (gx#syntax-e
                                            _%__stx199746199747%_))))
                                    (let ((_%$%tl2771427818%_
                                           (let ()
                                             (declare (not safe))
                                             (##cdr _%$%e2771227811%_)))
                                          (_%$%hd2771327815%_
                                           (let ()
                                             (declare (not safe))
                                             (##car _%$%e2771227811%_))))
                                      (if (let ()
                                            (declare (not safe))
                                            (gx#stx-pair? _%$%tl2771427818%_))
                                          (let ((_%$%e2771527821%_
                                                 (let ()
                                                   (declare (not safe))
                                                   (gx#syntax-e
                                                    _%$%tl2771427818%_))))
                                            (let ((_%$%tl2771727828%_
                                                   (let ()
                                                     (declare (not safe))
                                                     (##cdr _%$%e2771527821%_)))
                                                  (_%$%hd2771627825%_
                                                   (let ()
                                                     (declare (not safe))
                                                     (##car _%$%e2771527821%_))))
                                              (_%__match199765199766%_
                                               _%$%e2771227811%_
                                               _%$%hd2771327815%_
                                               _%$%tl2771427818%_
                                               _%$%e2771527821%_
                                               _%$%hd2771627825%_
                                               _%$%tl2771727828%_)))
                                          (_%__kont199751199752%_
                                           _%__stx199746199747%_))))
                                  (_%__kont199751199752%_
                                   _%__stx199746199747%_))))))))
                 (_%make-lambda-body27211%_
                  (lambda (_%id27550%_ _%contract27552%_ _%body27553%_)
                    (if (let ()
                          (declare (not safe))
                          (gx#stx-null? _%contract27552%_))
                        _%body27553%_
                        (let* ((_%$%g2755527574%_
                                (lambda (_%$%g2755627570%_)
                                  (let ()
                                    (declare (not safe))
                                    (gx#raise-syntax-error
                                     '#f
                                     '"Bad syntax; invalid match target"
                                     _%$%g2755627570%_))))
                               (_%$%g2755427633%_
                                (lambda (_%$%g2755627578%_)
                                  (if (let ()
                                        (declare (not safe))
                                        (gx#stx-pair? _%$%g2755627578%_))
                                      (let ((_%$%e2756027581%_
                                             (let ()
                                               (declare (not safe))
                                               (gx#syntax-e
                                                _%$%g2755627578%_))))
                                        (let ((_%$%hd2756127585%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##car _%$%e2756027581%_)))
                                              (_%$%tl2756227588%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##cdr _%$%e2756027581%_))))
                                          (if (let ()
                                                (declare (not safe))
                                                (gx#stx-pair?
                                                 _%$%tl2756227588%_))
                                              (let ((_%$%e2756327591%_
                                                     (let ()
                                                       (declare (not safe))
                                                       (gx#syntax-e
                                                        _%$%tl2756227588%_))))
                                                (let ((_%$%hd2756427595%_
                                                       (let ()
                                                         (declare (not safe))
                                                         (##car _%$%e2756327591%_)))
                                                      (_%$%tl2756527598%_
                                                       (let ()
                                                         (declare (not safe))
                                                         (##cdr _%$%e2756327591%_))))
                                                  (if (let ()
                                                        (declare (not safe))
                                                        (gx#stx-pair?
                                                         _%$%tl2756527598%_))
                                                      (let ((_%$%e2756627601%_
                                                             (let ()
                                                               (declare
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (not safe))
                       (gx#syntax-e _%$%tl2756527598%_))))
                (let ((_%$%hd2756727605%_
                       (let () (declare (not safe)) (##car _%$%e2756627601%_)))
                      (_%$%tl2756827608%_
                       (let ()
                         (declare (not safe))
                         (##cdr _%$%e2756627601%_))))
                  (if (let ()
                        (declare (not safe))
                        (gx#stx-null? _%$%tl2756827608%_))
                      (cons (let ()
                              (declare (not safe))
                              (gx#datum->syntax__0 '#f 'using))
                            (cons (cons _%$%hd2756127585%_ _%$%hd2756427595%_)
                                  (cons _%$%hd2756727605%_ '())))
                      (_%$%g2755527574%_ _%$%g2755627578%_))))
              (_%$%g2755527574%_ _%$%g2755627578%_))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                              (_%$%g2755527574%_
                                               _%$%g2755627578%_))))
                                      (_%$%g2755527574%_ _%$%g2755627578%_)))))
                          (_%$%g2755427633%_
                           (list _%id27550%_
                                 _%contract27552%_
                                 _%body27553%_))))))
                 (_%make-match-lambda27212%_
                  (lambda (_%id27418%_ _%traits27420%_ _%body27421%_)
                    (let* ((_%$%g2742327438%_
                            (lambda (_%$%g2742427434%_)
                              (let ()
                                (declare (not safe))
                                (gx#raise-syntax-error
                                 '#f
                                 '"Bad syntax; invalid match target"
                                 _%$%g2742427434%_))))
                           (_%$%g2742227546%_
                            (lambda (_%$%g2742427442%_)
                              (if (let ()
                                    (declare (not safe))
                                    (gx#stx-pair? _%$%g2742427442%_))
                                  (let ((_%$%e2742727445%_
                                         (let ()
                                           (declare (not safe))
                                           (gx#syntax-e _%$%g2742427442%_))))
                                    (let ((_%$%hd2742827449%_
                                           (let ()
                                             (declare (not safe))
                                             (##car _%$%e2742727445%_)))
                                          (_%$%tl2742927452%_
                                           (let ()
                                             (declare (not safe))
                                             (##cdr _%$%e2742727445%_))))
                                      (if (let ()
                                            (declare (not safe))
                                            (gx#stx-pair? _%$%tl2742927452%_))
                                          (let ((_%$%e2743027455%_
                                                 (let ()
                                                   (declare (not safe))
                                                   (gx#syntax-e
                                                    _%$%tl2742927452%_))))
                                            (let ((_%$%hd2743127459%_
                                                   (let ()
                                                     (declare (not safe))
                                                     (##car _%$%e2743027455%_)))
                                                  (_%$%tl2743227462%_
                                                   (let ()
                                                     (declare (not safe))
                                                     (##cdr _%$%e2743027455%_))))
                                              (if (let ()
                                                    (declare (not safe))
                                                    (gx#stx-null?
                                                     _%$%tl2743227462%_))
                                                  (if (let ()
                                                        (declare (not safe))
                                                        (gx#stx-null?
                                                         _%traits27420%_))
                                                      (let ((__tmp200788
                                                             (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                             (declare (not safe))
                             (gx#datum->syntax__0 '#f 'match))
                           (cons (let ()
                                   (declare (not safe))
                                   (gx#datum->syntax__0 '#f '<>))
                                 (cons (cons _%$%hd2742827449%_
                                             (cons _%$%hd2743127459%_ '()))
                                       '()))))
                    (__tmp200787
                     (let ()
                       (declare (not safe))
                       (gx#stx-source _%stx27206%_))))
                (declare (not safe))
                (gx#stx-wrap-source __tmp200788 __tmp200787))
              (let* ((_%$%g2748327498%_
                      (lambda (_%$%g2748427494%_)
                        (let ()
                          (declare (not safe))
                          (gx#raise-syntax-error
                           '#f
                           '"Bad syntax; invalid match target"
                           _%$%g2748427494%_))))
                     (_%$%g2748227542%_
                      (lambda (_%$%g2748427502%_)
                        (if (let ()
                              (declare (not safe))
                              (gx#stx-pair? _%$%g2748427502%_))
                            (let ((_%$%e2748727505%_
                                   (let ()
                                     (declare (not safe))
                                     (gx#syntax-e _%$%g2748427502%_))))
                              (let ((_%$%hd2748827509%_
                                     (let ()
                                       (declare (not safe))
                                       (##car _%$%e2748727505%_)))
                                    (_%$%tl2748927512%_
                                     (let ()
                                       (declare (not safe))
                                       (##cdr _%$%e2748727505%_))))
                                (if (let ()
                                      (declare (not safe))
                                      (gx#stx-pair? _%$%tl2748927512%_))
                                    (let ((_%$%e2749027515%_
                                           (let ()
                                             (declare (not safe))
                                             (gx#syntax-e
                                              _%$%tl2748927512%_))))
                                      (let ((_%$%hd2749127519%_
                                             (let ()
                                               (declare (not safe))
                                               (##car _%$%e2749027515%_)))
                                            (_%$%tl2749227522%_
                                             (let ()
                                               (declare (not safe))
                                               (##cdr _%$%e2749027515%_))))
                                        (if (let ()
                                              (declare (not safe))
                                              (gx#stx-null?
                                               _%$%tl2749227522%_))
                                            (if (and (let ()
                                                       (declare (not safe))
                                                       (gx#identifier?
                                                        _%$%hd2748827509%_))
                                                     (let ()
                                                       (declare (not safe))
                                                       (##member
                                                        _%$%hd2748827509%_
                                                        '(when unless)
                                                        gx#free-identifier=?)))
                                                (let ((__tmp200790
                                                       (cons (let ()
                                                               (declare
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (not safe))
                       (gx#datum->syntax__0 '#f 'match))
                     (cons (let ()
                             (declare (not safe))
                             (gx#datum->syntax__0 '#f '<>))
                           (cons (cons _%$%hd2742827449%_
                                       (cons (cons _%$%hd2748827509%_
                                                   (cons _%$%hd2749127519%_
                                                         (cons _%$%hd2743127459%_
                                                               '())))
                                             '()))
                                 '()))))
              (__tmp200789
               (let () (declare (not safe)) (gx#stx-source _%stx27206%_))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                  (declare (not safe))
                                                  (gx#stx-wrap-source
                                                   __tmp200790
                                                   __tmp200789))
                                                (_%$%g2748327498%_
                                                 _%$%g2748427502%_))
                                            (_%$%g2748327498%_
                                             _%$%g2748427502%_))))
                                    (_%$%g2748327498%_ _%$%g2748427502%_))))
                            (_%$%g2748327498%_ _%$%g2748427502%_)))))
                (_%$%g2748227542%_ _%traits27420%_)))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                  (_%$%g2742327438%_
                                                   _%$%g2742427442%_))))
                                          (_%$%g2742327438%_
                                           _%$%g2742427442%_))))
                                  (_%$%g2742327438%_ _%$%g2742427442%_)))))
                      (_%$%g2742227546%_ (list _%id27418%_ _%body27421%_))))))
          (let* ((_%$%g2721427232%_
                  (lambda (_%$%g2721527228%_)
                    (let ()
                      (declare (not safe))
                      (gx#raise-syntax-error
                       '#f
                       '"Bad syntax; invalid match target"
                       _%$%g2721527228%_))))
                 (_%$%g2721327414%_
                  (lambda (_%$%g2721527236%_)
                    (if (let ()
                          (declare (not safe))
                          (gx#stx-pair? _%$%g2721527236%_))
                        (let ((_%$%e2721827239%_
                               (let ()
                                 (declare (not safe))
                                 (gx#syntax-e _%$%g2721527236%_))))
                          (let ((_%$%hd2721927243%_
                                 (let ()
                                   (declare (not safe))
                                   (##car _%$%e2721827239%_)))
                                (_%$%tl2722027246%_
                                 (let ()
                                   (declare (not safe))
                                   (##cdr _%$%e2721827239%_))))
                            (if (let ()
                                  (declare (not safe))
                                  (gx#stx-pair? _%$%tl2722027246%_))
                                (let ((_%$%e2722127249%_
                                       (let ()
                                         (declare (not safe))
                                         (gx#syntax-e _%$%tl2722027246%_))))
                                  (let ((_%$%hd2722227253%_
                                         (let ()
                                           (declare (not safe))
                                           (##car _%$%e2722127249%_)))
                                        (_%$%tl2722327256%_
                                         (let ()
                                           (declare (not safe))
                                           (##cdr _%$%e2722127249%_))))
                                    (if (let ()
                                          (declare (not safe))
                                          (gx#stx-pair? _%$%tl2722327256%_))
                                        (let ((_%$%e2722427259%_
                                               (let ()
                                                 (declare (not safe))
                                                 (gx#syntax-e
                                                  _%$%tl2722327256%_))))
                                          (let ((_%$%hd2722527263%_
                                                 (let ()
                                                   (declare (not safe))
                                                   (##car _%$%e2722427259%_)))
                                                (_%$%tl2722627266%_
                                                 (let ()
                                                   (declare (not safe))
                                                   (##cdr _%$%e2722427259%_))))
                                            (if (let ()
                                                  (declare (not safe))
                                                  (gx#stx-null?
                                                   _%$%tl2722627266%_))
                                                (if (|std/iter/macros[1]#for-binding?|
                                                     _%$%hd2722227253%_)
                                                    (let* ((_%$%g2728827304%_
                                                            (lambda (_%$%g2728927300%_)
                                                              (let ()
                                                                (declare
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                          (not safe))
                        (gx#raise-syntax-error
                         '#f
                         '"Bad syntax; invalid match target"
                         _%$%g2728927300%_))))
                   (_%$%g2728727410%_
                    (lambda (_%$%g2728927308%_)
                      (if (let ()
                            (declare (not safe))
                            (gx#stx-pair? _%$%g2728927308%_))
                          (let ((_%$%e2729327311%_
                                 (let ()
                                   (declare (not safe))
                                   (gx#syntax-e _%$%g2728927308%_))))
                            (let ((_%$%hd2729427315%_
                                   (let ()
                                     (declare (not safe))
                                     (##car _%$%e2729327311%_)))
                                  (_%$%tl2729527318%_
                                   (let ()
                                     (declare (not safe))
                                     (##cdr _%$%e2729327311%_))))
                              (if (let ()
                                    (declare (not safe))
                                    (gx#stx-pair? _%$%tl2729527318%_))
                                  (let ((_%$%e2729627321%_
                                         (let ()
                                           (declare (not safe))
                                           (gx#syntax-e _%$%tl2729527318%_))))
                                    (let ((_%$%hd2729727325%_
                                           (let ()
                                             (declare (not safe))
                                             (##car _%$%e2729627321%_)))
                                          (_%$%tl2729827328%_
                                           (let ()
                                             (declare (not safe))
                                             (##cdr _%$%e2729627321%_))))
                                      (if (let ()
                                            (declare (not safe))
                                            (gx#identifier?
                                             _%$%hd2729427315%_))
                                          (let* ((_%$%g2734927357%_
                                                  (lambda (_%$%g2735027353%_)
                                                    (let ()
                                                      (declare (not safe))
                                                      (gx#raise-syntax-error
                                                       '#f
                                                       '"Bad syntax; invalid match target"
                                                       _%$%g2735027353%_))))
                                                 (_%$%g2734827376%_
                                                  (lambda (_%$%g2735027361%_)
                                                    (cons (let ()
                                                            (declare
                                                              (not safe))
                                                            (gx#datum->syntax__0
                                                             '#f
                                                             'for1-dispatch))
                                                          (cons _%$%g2735027361%_
                                                                (cons _%$%hd2729727325%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                              '()))))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                            (_%$%g2734827376%_
                                             (_%make-lambda27209%_
                                              _%$%hd2729427315%_
                                              _%$%tl2729827328%_
                                              _%$%hd2722527263%_)))
                                          (let* ((_%$%g2738027388%_
                                                  (lambda (_%$%g2738127384%_)
                                                    (let ()
                                                      (declare (not safe))
                                                      (gx#raise-syntax-error
                                                       '#f
                                                       '"Bad syntax; invalid match target"
                                                       _%$%g2738127384%_))))
                                                 (_%$%g2737927406%_
                                                  (lambda (_%$%g2738127392%_)
                                                    (cons (let ()
                                                            (declare
                                                              (not safe))
                                                            (gx#datum->syntax__0
                                                             '#f
                                                             'for1-dispatch))
                                                          (cons _%$%g2738127392%_
                                                                (cons _%$%hd2729727325%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                              '()))))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                            (_%$%g2737927406%_
                                             (_%make-match-lambda27212%_
                                              _%$%hd2729427315%_
                                              _%$%tl2729827328%_
                                              _%$%hd2722527263%_))))))
                                  (_%$%g2728827304%_ _%$%g2728927308%_))))
                          (_%$%g2728827304%_ _%$%g2728927308%_)))))
              (_%$%g2728727410%_ _%$%hd2722227253%_))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                    (_%$%g2721427232%_
                                                     _%$%g2721527236%_))
                                                (_%$%g2721427232%_
                                                 _%$%g2721527236%_))))
                                        (_%$%g2721427232%_
                                         _%$%g2721527236%_))))
                                (_%$%g2721427232%_ _%$%g2721527236%_))))
                        (_%$%g2721427232%_ _%$%g2721527236%_)))))
            (_%$%g2721327414%_ _%stx27206%_)))))
    (define |std/iter/macros[:0:]#for1-dispatch|
      (lambda (_%$stx27916%_)
        (let* ((_%__stx199768199769%_ _%$stx27916%_)
               (_%$%g2792928088%_
                (lambda ()
                  (let ()
                    (declare (not safe))
                    (gx#raise-syntax-error
                     '#f
                     '"Bad syntax; invalid match target"
                     _%__stx199768199769%_)))))
          (let ((_%__kont199771199772%_
                 (lambda (_%$%g2793128778%_ _%$%g2793228780%_)
                   (cons (let ()
                           (declare (not safe))
                           (gx#datum->syntax__0 '#f 'for1-in-range))
                         (cons _%$%g2793228780%_
                               (cons _%$%g2793128778%_ '())))))
                (_%__kont199773199774%_
                 (lambda (_%$%g2794528712%_ _%$%g2794628714%_)
                   (cons (let ()
                           (declare (not safe))
                           (gx#datum->syntax__0 '#f 'for1-in-range-inclusive))
                         (cons _%$%g2794628714%_
                               (cons _%$%g2794528712%_ '())))))
                (_%__kont199775199776%_
                 (lambda (_%$%g2795928646%_ _%$%g2796028648%_)
                   (cons (let ()
                           (declare (not safe))
                           (gx#datum->syntax__0 '#f 'for1-in-integers))
                         (cons _%$%g2796028648%_
                               (cons _%$%g2795928646%_ '())))))
                (_%__kont199777199778%_
                 (lambda (_%$%g2797328580%_ _%$%g2797428582%_)
                   (cons (let ()
                           (declare (not safe))
                           (gx#datum->syntax__0 '#f 'for1-in-numbers))
                         (cons _%$%g2797428582%_
                               (cons _%$%g2797328580%_ '())))))
                (_%__kont199779199780%_
                 (lambda (_%$%g2798728512%_ _%$%g2798828514%_)
                   (cons (let ()
                           (declare (not safe))
                           (gx#datum->syntax__0 '#f 'for-each))
                         (cons _%$%g2798828514%_
                               (cons _%$%g2798728512%_ '())))))
                (_%__kont199781199782%_
                 (lambda (_%$%g2800428434%_ _%$%g2800528436%_)
                   (cons (let ()
                           (declare (not safe))
                           (gx#datum->syntax__0 '#f 'vector-for-each))
                         (cons _%$%g2800528436%_
                               (cons _%$%g2800428434%_ '())))))
                (_%__kont199783199784%_
                 (lambda (_%$%g2802128356%_ _%$%g2802228358%_)
                   (cons (let ()
                           (declare (not safe))
                           (gx#datum->syntax__0 '#f 'hash-for-each))
                         (cons (cons (let ()
                                       (declare (not safe))
                                       (gx#datum->syntax__0 '#f 'lambda))
                                     (cons (cons (let ()
                                                   (declare (not safe))
                                                   (gx#datum->syntax__0
                                                    '#f
                                                    'k))
                                                 (cons (let ()
                                                         (declare (not safe))
                                                         (gx#datum->syntax__0
                                                          '#f
                                                          'v))
                                                       '()))
                                           (cons (cons _%$%g2802228358%_
                                                       (cons (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                             (declare (not safe))
                             (gx#datum->syntax__0 '#f 'cons))
                           (cons (let ()
                                   (declare (not safe))
                                   (gx#datum->syntax__0 '#f 'k))
                                 (cons (let ()
                                         (declare (not safe))
                                         (gx#datum->syntax__0 '#f 'v))
                                       '())))
                     '()))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                 '())))
                               (cons _%$%g2802128356%_ '())))))
                (_%__kont199785199786%_
                 (lambda (_%$%g2803828278%_ _%$%g2803928280%_)
                   (cons (let ()
                           (declare (not safe))
                           (gx#datum->syntax__0 '#f 'hash-for-each))
                         (cons (cons (let ()
                                       (declare (not safe))
                                       (gx#datum->syntax__0 '#f 'lambda))
                                     (cons (cons (let ()
                                                   (declare (not safe))
                                                   (gx#datum->syntax__0
                                                    '#f
                                                    'k))
                                                 (cons (let ()
                                                         (declare (not safe))
                                                         (gx#datum->syntax__0
                                                          '#f
                                                          'v))
                                                       '()))
                                           (cons (cons _%$%g2803928280%_
                                                       (cons (let ()
                                                               (declare
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (not safe))
                       (gx#datum->syntax__0 '#f 'k))
                     '()))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                 '())))
                               (cons _%$%g2803828278%_ '())))))
                (_%__kont199787199788%_
                 (lambda (_%$%g2805528200%_ _%$%g2805628202%_)
                   (cons (let ()
                           (declare (not safe))
                           (gx#datum->syntax__0 '#f 'hash-for-each))
                         (cons (cons (let ()
                                       (declare (not safe))
                                       (gx#datum->syntax__0 '#f 'lambda))
                                     (cons (cons (let ()
                                                   (declare (not safe))
                                                   (gx#datum->syntax__0
                                                    '#f
                                                    'k))
                                                 (cons (let ()
                                                         (declare (not safe))
                                                         (gx#datum->syntax__0
                                                          '#f
                                                          'v))
                                                       '()))
                                           (cons (cons _%$%g2805628202%_
                                                       (cons (let ()
                                                               (declare
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (not safe))
                       (gx#datum->syntax__0 '#f 'v))
                     '()))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                 '())))
                               (cons _%$%g2805528200%_ '())))))
                (_%__kont199789199790%_
                 (lambda (_%$%g2807228125%_ _%$%g2807328127%_)
                   (cons (let ()
                           (declare (not safe))
                           (gx#datum->syntax__0 '#f 'for1-generic))
                         (cons _%$%g2807328127%_
                               (cons _%$%g2807228125%_ '()))))))
            (if (let ()
                  (declare (not safe))
                  (gx#stx-pair? _%__stx199768199769%_))
                (let ((_%$%e2793328738%_
                       (let ()
                         (declare (not safe))
                         (gx#syntax-e _%__stx199768199769%_))))
                  (let ((_%$%tl2793528745%_
                         (let ()
                           (declare (not safe))
                           (##cdr _%$%e2793328738%_)))
                        (_%$%hd2793428742%_
                         (let ()
                           (declare (not safe))
                           (##car _%$%e2793328738%_))))
                    (if (let ()
                          (declare (not safe))
                          (gx#stx-pair? _%$%tl2793528745%_))
                        (let ((_%$%e2793628748%_
                               (let ()
                                 (declare (not safe))
                                 (gx#syntax-e _%$%tl2793528745%_))))
                          (let ((_%$%tl2793828755%_
                                 (let ()
                                   (declare (not safe))
                                   (##cdr _%$%e2793628748%_)))
                                (_%$%hd2793728752%_
                                 (let ()
                                   (declare (not safe))
                                   (##car _%$%e2793628748%_))))
                            (if (let ()
                                  (declare (not safe))
                                  (gx#stx-pair? _%$%tl2793828755%_))
                                (let ((_%$%e2793928758%_
                                       (let ()
                                         (declare (not safe))
                                         (gx#syntax-e _%$%tl2793828755%_))))
                                  (let ((_%$%tl2794128765%_
                                         (let ()
                                           (declare (not safe))
                                           (##cdr _%$%e2793928758%_)))
                                        (_%$%hd2794028762%_
                                         (let ()
                                           (declare (not safe))
                                           (##car _%$%e2793928758%_))))
                                    (if (let ()
                                          (declare (not safe))
                                          (gx#stx-pair? _%$%hd2794028762%_))
                                        (let ((_%$%e2794228768%_
                                               (let ()
                                                 (declare (not safe))
                                                 (gx#syntax-e
                                                  _%$%hd2794028762%_))))
                                          (let ((_%$%tl2794428775%_
                                                 (let ()
                                                   (declare (not safe))
                                                   (##cdr _%$%e2794228768%_)))
                                                (_%$%hd2794328772%_
                                                 (let ()
                                                   (declare (not safe))
                                                   (##car _%$%e2794228768%_))))
                                            (if (let ()
                                                  (declare (not safe))
                                                  (gx#identifier?
                                                   _%$%hd2794328772%_))
                                                (if (let ((__tmp200791
                                                           |std/iter/macros[1]#_g200792_|))
                                                      (declare (not safe))
                                                      (gx#free-identifier=?
                                                       __tmp200791
                                                       _%$%hd2794328772%_))
                                                    (if (let ()
                                                          (declare (not safe))
                                                          (gx#stx-null?
                                                           _%$%tl2794128765%_))
                                                        (_%__kont199771199772%_
                                                         _%$%tl2794428775%_
                                                         _%$%hd2793728752%_)
                                                        (let ()
                                                          (declare (not safe))
                                                          (_%$%g2792928088%_)))
                                                    (if (let ((__tmp200793
                                                               |std/iter/macros[1]#_g200794_|))
                                                          (declare (not safe))
                                                          (gx#free-identifier=?
                                                           __tmp200793
                                                           _%$%hd2794328772%_))
                                                        (if (let ()
                                                              (declare
                                                                (not safe))
                                                              (gx#stx-null?
                                                               _%$%tl2794128765%_))
                                                            (_%__kont199773199774%_
                                                             _%$%tl2794428775%_
                                                             _%$%hd2793728752%_)
                                                            (let ()
                                                              (declare
                                                                (not safe))
                                                              (_%$%g2792928088%_)))
                                                        (if (let ((__tmp200795
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                           |std/iter/macros[1]#_g200796_|))
                      (declare (not safe))
                      (gx#free-identifier=? __tmp200795 _%$%hd2794328772%_))
                    (if (let ()
                          (declare (not safe))
                          (gx#stx-null? _%$%tl2794128765%_))
                        (_%__kont199775199776%_
                         _%$%tl2794428775%_
                         _%$%hd2793728752%_)
                        (let () (declare (not safe)) (_%$%g2792928088%_)))
                    (if (let ((__tmp200797 |std/iter/macros[1]#_g200798_|))
                          (declare (not safe))
                          (gx#free-identifier=?
                           __tmp200797
                           _%$%hd2794328772%_))
                        (if (let ()
                              (declare (not safe))
                              (gx#stx-null? _%$%tl2794128765%_))
                            (_%__kont199777199778%_
                             _%$%tl2794428775%_
                             _%$%hd2793728752%_)
                            (let () (declare (not safe)) (_%$%g2792928088%_)))
                        (if (let ((__tmp200799 |std/iter/macros[1]#_g200800_|))
                              (declare (not safe))
                              (gx#free-identifier=?
                               __tmp200799
                               _%$%hd2794328772%_))
                            (if (let ()
                                  (declare (not safe))
                                  (gx#stx-pair? _%$%tl2794428775%_))
                                (let ((_%$%e2800128502%_
                                       (let ()
                                         (declare (not safe))
                                         (gx#syntax-e _%$%tl2794428775%_))))
                                  (let ((_%$%tl2800328509%_
                                         (let ()
                                           (declare (not safe))
                                           (##cdr _%$%e2800128502%_)))
                                        (_%$%hd2800228506%_
                                         (let ()
                                           (declare (not safe))
                                           (##car _%$%e2800128502%_))))
                                    (if (let ()
                                          (declare (not safe))
                                          (gx#stx-null? _%$%tl2800328509%_))
                                        (if (let ()
                                              (declare (not safe))
                                              (gx#stx-null?
                                               _%$%tl2794128765%_))
                                            (_%__kont199779199780%_
                                             _%$%hd2800228506%_
                                             _%$%hd2793728752%_)
                                            (let ()
                                              (declare (not safe))
                                              (_%$%g2792928088%_)))
                                        (if (let ()
                                              (declare (not safe))
                                              (gx#stx-null?
                                               _%$%tl2794128765%_))
                                            (_%__kont199789199790%_
                                             _%$%hd2794028762%_
                                             _%$%hd2793728752%_)
                                            (let ()
                                              (declare (not safe))
                                              (_%$%g2792928088%_))))))
                                (if (let ()
                                      (declare (not safe))
                                      (gx#stx-null? _%$%tl2794128765%_))
                                    (_%__kont199789199790%_
                                     _%$%hd2794028762%_
                                     _%$%hd2793728752%_)
                                    (let ()
                                      (declare (not safe))
                                      (_%$%g2792928088%_))))
                            (if (let ((__tmp200801
                                       |std/iter/macros[1]#_g200802_|))
                                  (declare (not safe))
                                  (gx#free-identifier=?
                                   __tmp200801
                                   _%$%hd2794328772%_))
                                (if (let ()
                                      (declare (not safe))
                                      (gx#stx-pair? _%$%tl2794428775%_))
                                    (let ((_%$%e2801828424%_
                                           (let ()
                                             (declare (not safe))
                                             (gx#syntax-e
                                              _%$%tl2794428775%_))))
                                      (let ((_%$%tl2802028431%_
                                             (let ()
                                               (declare (not safe))
                                               (##cdr _%$%e2801828424%_)))
                                            (_%$%hd2801928428%_
                                             (let ()
                                               (declare (not safe))
                                               (##car _%$%e2801828424%_))))
                                        (if (let ()
                                              (declare (not safe))
                                              (gx#stx-null?
                                               _%$%tl2802028431%_))
                                            (if (let ()
                                                  (declare (not safe))
                                                  (gx#stx-null?
                                                   _%$%tl2794128765%_))
                                                (_%__kont199781199782%_
                                                 _%$%hd2801928428%_
                                                 _%$%hd2793728752%_)
                                                (let ()
                                                  (declare (not safe))
                                                  (_%$%g2792928088%_)))
                                            (if (let ()
                                                  (declare (not safe))
                                                  (gx#stx-null?
                                                   _%$%tl2794128765%_))
                                                (_%__kont199789199790%_
                                                 _%$%hd2794028762%_
                                                 _%$%hd2793728752%_)
                                                (let ()
                                                  (declare (not safe))
                                                  (_%$%g2792928088%_))))))
                                    (if (let ()
                                          (declare (not safe))
                                          (gx#stx-null? _%$%tl2794128765%_))
                                        (_%__kont199789199790%_
                                         _%$%hd2794028762%_
                                         _%$%hd2793728752%_)
                                        (let ()
                                          (declare (not safe))
                                          (_%$%g2792928088%_))))
                                (if (let ((__tmp200803
                                           |std/iter/macros[1]#_g200804_|))
                                      (declare (not safe))
                                      (gx#free-identifier=?
                                       __tmp200803
                                       _%$%hd2794328772%_))
                                    (if (let ()
                                          (declare (not safe))
                                          (gx#stx-pair? _%$%tl2794428775%_))
                                        (let ((_%$%e2803528346%_
                                               (let ()
                                                 (declare (not safe))
                                                 (gx#syntax-e
                                                  _%$%tl2794428775%_))))
                                          (let ((_%$%tl2803728353%_
                                                 (let ()
                                                   (declare (not safe))
                                                   (##cdr _%$%e2803528346%_)))
                                                (_%$%hd2803628350%_
                                                 (let ()
                                                   (declare (not safe))
                                                   (##car _%$%e2803528346%_))))
                                            (if (let ()
                                                  (declare (not safe))
                                                  (gx#stx-null?
                                                   _%$%tl2803728353%_))
                                                (if (let ()
                                                      (declare (not safe))
                                                      (gx#stx-null?
                                                       _%$%tl2794128765%_))
                                                    (_%__kont199783199784%_
                                                     _%$%hd2803628350%_
                                                     _%$%hd2793728752%_)
                                                    (let ()
                                                      (declare (not safe))
                                                      (_%$%g2792928088%_)))
                                                (if (let ()
                                                      (declare (not safe))
                                                      (gx#stx-null?
                                                       _%$%tl2794128765%_))
                                                    (_%__kont199789199790%_
                                                     _%$%hd2794028762%_
                                                     _%$%hd2793728752%_)
                                                    (let ()
                                                      (declare (not safe))
                                                      (_%$%g2792928088%_))))))
                                        (if (let ()
                                              (declare (not safe))
                                              (gx#stx-null?
                                               _%$%tl2794128765%_))
                                            (_%__kont199789199790%_
                                             _%$%hd2794028762%_
                                             _%$%hd2793728752%_)
                                            (let ()
                                              (declare (not safe))
                                              (_%$%g2792928088%_))))
                                    (if (let ((__tmp200805
                                               |std/iter/macros[1]#_g200806_|))
                                          (declare (not safe))
                                          (gx#free-identifier=?
                                           __tmp200805
                                           _%$%hd2794328772%_))
                                        (if (let ()
                                              (declare (not safe))
                                              (gx#stx-pair?
                                               _%$%tl2794428775%_))
                                            (let ((_%$%e2805228268%_
                                                   (let ()
                                                     (declare (not safe))
                                                     (gx#syntax-e
                                                      _%$%tl2794428775%_))))
                                              (let ((_%$%tl2805428275%_
                                                     (let ()
                                                       (declare (not safe))
                                                       (##cdr _%$%e2805228268%_)))
                                                    (_%$%hd2805328272%_
                                                     (let ()
                                                       (declare (not safe))
                                                       (##car _%$%e2805228268%_))))
                                                (if (let ()
                                                      (declare (not safe))
                                                      (gx#stx-null?
                                                       _%$%tl2805428275%_))
                                                    (if (let ()
                                                          (declare (not safe))
                                                          (gx#stx-null?
                                                           _%$%tl2794128765%_))
                                                        (_%__kont199785199786%_
                                                         _%$%hd2805328272%_
                                                         _%$%hd2793728752%_)
                                                        (let ()
                                                          (declare (not safe))
                                                          (_%$%g2792928088%_)))
                                                    (if (let ()
                                                          (declare (not safe))
                                                          (gx#stx-null?
                                                           _%$%tl2794128765%_))
                                                        (_%__kont199789199790%_
                                                         _%$%hd2794028762%_
                                                         _%$%hd2793728752%_)
                                                        (let ()
                                                          (declare (not safe))
                                                          (_%$%g2792928088%_))))))
                                            (if (let ()
                                                  (declare (not safe))
                                                  (gx#stx-null?
                                                   _%$%tl2794128765%_))
                                                (_%__kont199789199790%_
                                                 _%$%hd2794028762%_
                                                 _%$%hd2793728752%_)
                                                (let ()
                                                  (declare (not safe))
                                                  (_%$%g2792928088%_))))
                                        (if (let ((__tmp200807
                                                   |std/iter/macros[1]#_g200808_|))
                                              (declare (not safe))
                                              (gx#free-identifier=?
                                               __tmp200807
                                               _%$%hd2794328772%_))
                                            (if (let ()
                                                  (declare (not safe))
                                                  (gx#stx-pair?
                                                   _%$%tl2794428775%_))
                                                (let ((_%$%e2806928190%_
                                                       (let ()
                                                         (declare (not safe))
                                                         (gx#syntax-e
                                                          _%$%tl2794428775%_))))
                                                  (let ((_%$%tl2807128197%_
                                                         (let ()
                                                           (declare (not safe))
                                                           (##cdr _%$%e2806928190%_)))
                                                        (_%$%hd2807028194%_
                                                         (let ()
                                                           (declare (not safe))
                                                           (##car _%$%e2806928190%_))))
                                                    (if (let ()
                                                          (declare (not safe))
                                                          (gx#stx-null?
                                                           _%$%tl2807128197%_))
                                                        (if (let ()
                                                              (declare
                                                                (not safe))
                                                              (gx#stx-null?
                                                               _%$%tl2794128765%_))
                                                            (_%__kont199787199788%_
                                                             _%$%hd2807028194%_
                                                             _%$%hd2793728752%_)
                                                            (let ()
                                                              (declare
                                                                (not safe))
                                                              (_%$%g2792928088%_)))
                                                        (if (let ()
                                                              (declare
                                                                (not safe))
                                                              (gx#stx-null?
                                                               _%$%tl2794128765%_))
                                                            (_%__kont199789199790%_
                                                             _%$%hd2794028762%_
                                                             _%$%hd2793728752%_)
                                                            (let ()
                                                              (declare
                                                                (not safe))
                                                              (_%$%g2792928088%_))))))
                                                (if (let ()
                                                      (declare (not safe))
                                                      (gx#stx-null?
                                                       _%$%tl2794128765%_))
                                                    (_%__kont199789199790%_
                                                     _%$%hd2794028762%_
                                                     _%$%hd2793728752%_)
                                                    (let ()
                                                      (declare (not safe))
                                                      (_%$%g2792928088%_))))
                                            (if (let ()
                                                  (declare (not safe))
                                                  (gx#stx-null?
                                                   _%$%tl2794128765%_))
                                                (_%__kont199789199790%_
                                                 _%$%hd2794028762%_
                                                 _%$%hd2793728752%_)
                                                (let ()
                                                  (declare (not safe))
                                                  (_%$%g2792928088%_))))))))))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                (if (let ()
                                                      (declare (not safe))
                                                      (gx#stx-null?
                                                       _%$%tl2794128765%_))
                                                    (_%__kont199789199790%_
                                                     _%$%hd2794028762%_
                                                     _%$%hd2793728752%_)
                                                    (let ()
                                                      (declare (not safe))
                                                      (_%$%g2792928088%_))))))
                                        (if (let ()
                                              (declare (not safe))
                                              (gx#stx-null?
                                               _%$%tl2794128765%_))
                                            (_%__kont199789199790%_
                                             _%$%hd2794028762%_
                                             _%$%hd2793728752%_)
                                            (let ()
                                              (declare (not safe))
                                              (_%$%g2792928088%_))))))
                                (let ()
                                  (declare (not safe))
                                  (_%$%g2792928088%_)))))
                        (let () (declare (not safe)) (_%$%g2792928088%_)))))
                (let () (declare (not safe)) (_%$%g2792928088%_)))))))
    (define |std/iter/macros[:0:]#for1-in-range|
      (lambda (_%$stx28801%_)
        (let* ((_%$%g2880528823%_
                (lambda (_%$%g2880628819%_)
                  (let ()
                    (declare (not safe))
                    (gx#raise-syntax-error
                     '#f
                     '"Bad syntax; invalid match target"
                     _%$%g2880628819%_))))
               (_%$%g2880428878%_
                (lambda (_%$%g2880628827%_)
                  (if (let ()
                        (declare (not safe))
                        (gx#stx-pair? _%$%g2880628827%_))
                      (let ((_%$%e2880928830%_
                             (let ()
                               (declare (not safe))
                               (gx#syntax-e _%$%g2880628827%_))))
                        (let ((_%$%hd2881028834%_
                               (let ()
                                 (declare (not safe))
                                 (##car _%$%e2880928830%_)))
                              (_%$%tl2881128837%_
                               (let ()
                                 (declare (not safe))
                                 (##cdr _%$%e2880928830%_))))
                          (if (let ()
                                (declare (not safe))
                                (gx#stx-pair? _%$%tl2881128837%_))
                              (let ((_%$%e2881228840%_
                                     (let ()
                                       (declare (not safe))
                                       (gx#syntax-e _%$%tl2881128837%_))))
                                (let ((_%$%hd2881328844%_
                                       (let ()
                                         (declare (not safe))
                                         (##car _%$%e2881228840%_)))
                                      (_%$%tl2881428847%_
                                       (let ()
                                         (declare (not safe))
                                         (##cdr _%$%e2881228840%_))))
                                  (if (let ()
                                        (declare (not safe))
                                        (gx#stx-pair? _%$%tl2881428847%_))
                                      (let ((_%$%e2881528850%_
                                             (let ()
                                               (declare (not safe))
                                               (gx#syntax-e
                                                _%$%tl2881428847%_))))
                                        (let ((_%$%hd2881628854%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##car _%$%e2881528850%_)))
                                              (_%$%tl2881728857%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##cdr _%$%e2881528850%_))))
                                          (if (let ()
                                                (declare (not safe))
                                                (gx#stx-null?
                                                 _%$%tl2881728857%_))
                                              (cons (let ()
                                                      (declare (not safe))
                                                      (gx#datum->syntax__0
                                                       '#f
                                                       'for1-in-range-generic))
                                                    (cons _%$%hd2881328844%_
                                                          (cons _%$%hd2881628854%_
                                                                (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                (declare (not safe))
                                (gx#datum->syntax__0 '#f '<))
                              (cons (let ()
                                      (declare (not safe))
                                      (gx#datum->syntax__0 '#f '>))
                                    '())))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                              (_%$%g2880528823%_
                                               _%$%g2880628827%_))))
                                      (_%$%g2880528823%_ _%$%g2880628827%_))))
                              (_%$%g2880528823%_ _%$%g2880628827%_))))
                      (_%$%g2880528823%_ _%$%g2880628827%_)))))
          (_%$%g2880428878%_ _%$stx28801%_))))
    (define |std/iter/macros[:0:]#for1-in-range-inclusive|
      (lambda (_%$stx28882%_)
        (let* ((_%$%g2888628904%_
                (lambda (_%$%g2888728900%_)
                  (let ()
                    (declare (not safe))
                    (gx#raise-syntax-error
                     '#f
                     '"Bad syntax; invalid match target"
                     _%$%g2888728900%_))))
               (_%$%g2888528959%_
                (lambda (_%$%g2888728908%_)
                  (if (let ()
                        (declare (not safe))
                        (gx#stx-pair? _%$%g2888728908%_))
                      (let ((_%$%e2889028911%_
                             (let ()
                               (declare (not safe))
                               (gx#syntax-e _%$%g2888728908%_))))
                        (let ((_%$%hd2889128915%_
                               (let ()
                                 (declare (not safe))
                                 (##car _%$%e2889028911%_)))
                              (_%$%tl2889228918%_
                               (let ()
                                 (declare (not safe))
                                 (##cdr _%$%e2889028911%_))))
                          (if (let ()
                                (declare (not safe))
                                (gx#stx-pair? _%$%tl2889228918%_))
                              (let ((_%$%e2889328921%_
                                     (let ()
                                       (declare (not safe))
                                       (gx#syntax-e _%$%tl2889228918%_))))
                                (let ((_%$%hd2889428925%_
                                       (let ()
                                         (declare (not safe))
                                         (##car _%$%e2889328921%_)))
                                      (_%$%tl2889528928%_
                                       (let ()
                                         (declare (not safe))
                                         (##cdr _%$%e2889328921%_))))
                                  (if (let ()
                                        (declare (not safe))
                                        (gx#stx-pair? _%$%tl2889528928%_))
                                      (let ((_%$%e2889628931%_
                                             (let ()
                                               (declare (not safe))
                                               (gx#syntax-e
                                                _%$%tl2889528928%_))))
                                        (let ((_%$%hd2889728935%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##car _%$%e2889628931%_)))
                                              (_%$%tl2889828938%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##cdr _%$%e2889628931%_))))
                                          (if (let ()
                                                (declare (not safe))
                                                (gx#stx-null?
                                                 _%$%tl2889828938%_))
                                              (cons (let ()
                                                      (declare (not safe))
                                                      (gx#datum->syntax__0
                                                       '#f
                                                       'for1-in-range-generic))
                                                    (cons _%$%hd2889428925%_
                                                          (cons _%$%hd2889728935%_
                                                                (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                (declare (not safe))
                                (gx#datum->syntax__0 '#f '<=))
                              (cons (let ()
                                      (declare (not safe))
                                      (gx#datum->syntax__0 '#f '>=))
                                    '())))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                              (_%$%g2888628904%_
                                               _%$%g2888728908%_))))
                                      (_%$%g2888628904%_ _%$%g2888728908%_))))
                              (_%$%g2888628904%_ _%$%g2888728908%_))))
                      (_%$%g2888628904%_ _%$%g2888728908%_)))))
          (_%$%g2888528959%_ _%$stx28882%_))))
    (define |std/iter/macros[:0:]#for1-in-range-generic|
      (lambda (_%$stx28963%_)
        (let* ((_%__stx200124200125%_ _%$stx28963%_)
               (_%$%g2896929058%_
                (lambda ()
                  (let ()
                    (declare (not safe))
                    (gx#raise-syntax-error
                     '#f
                     '"Bad syntax; invalid match target"
                     _%__stx200124200125%_)))))
          (let ((_%__kont200127200128%_
                 (lambda (_%$%g2897129384%_
                          _%$%g2897229386%_
                          _%$%g2897329387%_
                          _%$%g2897429388%_
                          _%$%g2897529389%_
                          _%$%g2897629390%_)
                   (cons (let ()
                           (declare (not safe))
                           (gx#datum->syntax__0 '#f 'let))
                         (cons (cons (cons (let ()
                                             (declare (not safe))
                                             (gx#datum->syntax__0 '#f '$start))
                                           (cons _%$%g2897529389%_ '()))
                                     (cons (cons (let ()
                                                   (declare (not safe))
                                                   (gx#datum->syntax__0
                                                    '#f
                                                    '$end))
                                                 (cons _%$%g2897429388%_ '()))
                                           (cons (cons (let ()
                                                         (declare (not safe))
                                                         (gx#datum->syntax__0
                                                          '#f
                                                          '$step))
                                                       (cons _%$%g2897329387%_
                                                             '()))
                                                 '())))
                               (cons (cons (let ()
                                             (declare (not safe))
                                             (gx#datum->syntax__0 '#f 'cond))
                                           (cons (cons (cons (let ()
                                                               (declare
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (not safe))
                       (gx#datum->syntax__0 '#f '>))
                     (cons (let ()
                             (declare (not safe))
                             (gx#datum->syntax__0 '#f '$step))
                           (cons '0 '())))
               (cons (cons (let ()
                             (declare (not safe))
                             (gx#datum->syntax__0 '#f 'let))
                           (cons (let ()
                                   (declare (not safe))
                                   (gx#datum->syntax__0 '#f 'loop))
                                 (cons (cons (cons (let ()
                                                     (declare (not safe))
                                                     (gx#datum->syntax__0
                                                      '#f
                                                      'k))
                                                   (cons (let ()
                                                           (declare (not safe))
                                                           (gx#datum->syntax__0
                                                            '#f
                                                            '$start))
                                                         '()))
                                             '())
                                       (cons (cons (let ()
                                                     (declare (not safe))
                                                     (gx#datum->syntax__0
                                                      '#f
                                                      'when))
                                                   (cons (cons _%$%g2897229386%_
                                                               (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                               (declare (not safe))
                               (gx#datum->syntax__0 '#f 'k))
                             (cons (let ()
                                     (declare (not safe))
                                     (gx#datum->syntax__0 '#f '$end))
                                   '())))
                 (cons (cons _%$%g2897629390%_
                             (cons (let ()
                                     (declare (not safe))
                                     (gx#datum->syntax__0 '#f 'k))
                                   '()))
                       (cons (cons (let ()
                                     (declare (not safe))
                                     (gx#datum->syntax__0 '#f 'loop))
                                   (cons (cons (let ()
                                                 (declare (not safe))
                                                 (gx#datum->syntax__0 '#f '+))
                                               (cons (let ()
                                                       (declare (not safe))
                                                       (gx#datum->syntax__0
                                                        '#f
                                                        'k))
                                                     (cons (let ()
                                                             (declare
                                                               (not safe))
                                                             (gx#datum->syntax__0
                                                              '#f
                                                              '$step))
                                                           '())))
                                         '()))
                             '()))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                             '()))))
                     '()))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                 (cons (cons (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                             (declare (not safe))
                             (gx#datum->syntax__0 '#f '<))
                           (cons (let ()
                                   (declare (not safe))
                                   (gx#datum->syntax__0 '#f '$step))
                                 (cons '0 '())))
                     (cons (cons (let ()
                                   (declare (not safe))
                                   (gx#datum->syntax__0 '#f 'let))
                                 (cons (let ()
                                         (declare (not safe))
                                         (gx#datum->syntax__0 '#f 'loop))
                                       (cons (cons (cons (let ()
                                                           (declare (not safe))
                                                           (gx#datum->syntax__0
                                                            '#f
                                                            'k))
                                                         (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (declare (not safe))
                         (gx#datum->syntax__0 '#f '$start))
                       '()))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                   '())
                                             (cons (cons (let ()
                                                           (declare (not safe))
                                                           (gx#datum->syntax__0
                                                            '#f
                                                            'when))
                                                         (cons (cons _%$%g2897129384%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                             (cons (let ()
                                     (declare (not safe))
                                     (gx#datum->syntax__0 '#f 'k))
                                   (cons (let ()
                                           (declare (not safe))
                                           (gx#datum->syntax__0 '#f '$end))
                                         '())))
                       (cons (cons _%$%g2897629390%_
                                   (cons (let ()
                                           (declare (not safe))
                                           (gx#datum->syntax__0 '#f 'k))
                                         '()))
                             (cons (cons (let ()
                                           (declare (not safe))
                                           (gx#datum->syntax__0 '#f 'loop))
                                         (cons (cons (let ()
                                                       (declare (not safe))
                                                       (gx#datum->syntax__0
                                                        '#f
                                                        '+))
                                                     (cons (let ()
                                                             (declare
                                                               (not safe))
                                                             (gx#datum->syntax__0
                                                              '#f
                                                              'k))
                                                           (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                           (declare (not safe))
                           (gx#datum->syntax__0 '#f '$step))
                         '())))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                               '()))
                                   '()))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                   '()))))
                           '()))
               (cons (cons (let ()
                             (declare (not safe))
                             (gx#datum->syntax__0 '#f 'else))
                           (cons (cons (let ()
                                         (declare (not safe))
                                         (gx#datum->syntax__0
                                          '#f
                                          'contract-violation!))
                                       (cons (let ()
                                               (declare (not safe))
                                               (gx#datum->syntax__0
                                                '#f
                                                'iter-in-range))
                                             (cons (cons (let ()
                                                           (declare (not safe))
                                                           (gx#datum->syntax__0
                                                            '#f
                                                            'not))
                                                         (cons (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                               (declare (not safe))
                               (gx#datum->syntax__0 '#f 'zero?))
                             (cons _%$%g2897329387%_ '()))
                       '()))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                   (cons (let ()
                                                           (declare (not safe))
                                                           (gx#datum->syntax__0
                                                            '#f
                                                            '$step))
                                                         '()))))
                                 '()))
                     '()))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                     '())))))
                (_%__kont200129200130%_
                 (lambda (_%$%g2900129252%_
                          _%$%g2900229254%_
                          _%$%g2900329255%_
                          _%$%g2900429256%_)
                   (cons (let ()
                           (declare (not safe))
                           (gx#datum->syntax__0 '#f 'let))
                         (cons (cons (cons (let ()
                                             (declare (not safe))
                                             (gx#datum->syntax__0 '#f '$start))
                                           (cons _%$%g2900329255%_ '()))
                                     (cons (cons (let ()
                                                   (declare (not safe))
                                                   (gx#datum->syntax__0
                                                    '#f
                                                    '$end))
                                                 (cons _%$%g2900229254%_ '()))
                                           '()))
                               (cons (cons (let ()
                                             (declare (not safe))
                                             (gx#datum->syntax__0 '#f 'if))
                                           (cons (cons (let ()
                                                         (declare (not safe))
                                                         (gx#datum->syntax__0
                                                          '#f
                                                          '>))
                                                       (cons (let ()
                                                               (declare
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (not safe))
                       (gx#datum->syntax__0 '#f '$start))
                     (cons (let ()
                             (declare (not safe))
                             (gx#datum->syntax__0 '#f '$end))
                           '())))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                 (cons (cons (let ()
                                                               (declare
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (not safe))
                       (gx#datum->syntax__0 '#f 'for1-in-range-generic))
                     (cons _%$%g2900429256%_
                           (cons (cons _%$%g2900329255%_
                                       (cons _%$%g2900229254%_ (cons '-1 '())))
                                 (let ((__tmp200809
                                        (lambda (_%$%g2928029285%_
                                                 _%$%g2928129288%_)
                                          (cons _%$%g2928029285%_
                                                _%$%g2928129288%_))))
                                   (declare (not safe))
                                   (foldr__0
                                    __tmp200809
                                    '()
                                    _%$%g2900129252%_)))))
               (cons (cons (let ()
                             (declare (not safe))
                             (gx#datum->syntax__0 '#f 'for1-in-range-generic))
                           (cons _%$%g2900429256%_
                                 (cons (cons _%$%g2900329255%_
                                             (cons _%$%g2900229254%_
                                                   (cons '1 '())))
                                       (let ((__tmp200810
                                              (lambda (_%$%g2928229291%_
                                                       _%$%g2928329294%_)
                                                (cons _%$%g2928229291%_
                                                      _%$%g2928329294%_))))
                                         (declare (not safe))
                                         (foldr__0
                                          __tmp200810
                                          '()
                                          _%$%g2900129252%_)))))
                     '()))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                     '())))))
                (_%__kont200133200134%_
                 (lambda (_%$%g2902929133%_
                          _%$%g2903029135%_
                          _%$%g2903129136%_)
                   (cons (let ()
                           (declare (not safe))
                           (gx#datum->syntax__0 '#f 'for1-in-range-generic))
                         (cons _%$%g2903129136%_
                               (cons (cons '0 (cons _%$%g2903029135%_ '()))
                                     (let ((__tmp200811
                                            (lambda (_%$%g2915829161%_
                                                     _%$%g2915929164%_)
                                              (cons _%$%g2915829161%_
                                                    _%$%g2915929164%_))))
                                       (declare (not safe))
                                       (foldr__0
                                        __tmp200811
                                        '()
                                        _%$%g2902929133%_))))))))
            (let* ((_%__match200263200264%_
                    (lambda (_%$%e2903229065%_
                             _%$%hd2903329069%_
                             _%$%tl2903429072%_
                             _%$%e2903529075%_
                             _%$%hd2903629079%_
                             _%$%tl2903729082%_
                             _%$%e2903829085%_
                             _%$%hd2903929089%_
                             _%$%tl2904029092%_
                             _%$%e2904129095%_
                             _%$%hd2904229099%_
                             _%$%tl2904329102%_
                             _%__splice200135200136%_
                             _%$%target2904429105%_
                             _%$%tl2904629108%_)
                      (letrec ((_%$%loop2904729111%_
                                (lambda (_%$%hd2904529115%_
                                         _%$%ops2905129118%_)
                                  (if (let ()
                                        (declare (not safe))
                                        (gx#stx-pair? _%$%hd2904529115%_))
                                      (let ((_%$%e2904829120%_
                                             (let ()
                                               (declare (not safe))
                                               (gx#syntax-e
                                                _%$%hd2904529115%_))))
                                        (let ((_%$%lp-tl2905029127%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##cdr _%$%e2904829120%_)))
                                              (_%$%lp-hd2904929124%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##car _%$%e2904829120%_))))
                                          (_%$%loop2904729111%_
                                           _%$%lp-tl2905029127%_
                                           (cons _%$%lp-hd2904929124%_
                                                 _%$%ops2905129118%_))))
                                      (let ((_%$%ops2905229130%_
                                             (reverse _%$%ops2905129118%_)))
                                        (_%__kont200133200134%_
                                         _%$%ops2905229130%_
                                         _%$%hd2904229099%_
                                         _%$%hd2903629079%_))))))
                        (_%$%loop2904729111%_ _%$%target2904429105%_ '()))))
                   (_%__match200229200230%_
                    (lambda (_%$%e2900529174%_
                             _%$%hd2900629178%_
                             _%$%tl2900729181%_
                             _%$%e2900829184%_
                             _%$%hd2900929188%_
                             _%$%tl2901029191%_
                             _%$%e2901129194%_
                             _%$%hd2901229198%_
                             _%$%tl2901329201%_
                             _%$%e2901429204%_
                             _%$%hd2901529208%_
                             _%$%tl2901629211%_
                             _%$%e2901729214%_
                             _%$%hd2901829218%_
                             _%$%tl2901929221%_
                             _%__splice200131200132%_
                             _%$%target2902029224%_
                             _%$%tl2902229227%_)
                      (letrec ((_%$%loop2902329230%_
                                (lambda (_%$%hd2902129234%_
                                         _%$%ops2902729237%_)
                                  (if (let ()
                                        (declare (not safe))
                                        (gx#stx-pair? _%$%hd2902129234%_))
                                      (let ((_%$%e2902429239%_
                                             (let ()
                                               (declare (not safe))
                                               (gx#syntax-e
                                                _%$%hd2902129234%_))))
                                        (let ((_%$%lp-tl2902629246%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##cdr _%$%e2902429239%_)))
                                              (_%$%lp-hd2902529243%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##car _%$%e2902429239%_))))
                                          (_%$%loop2902329230%_
                                           _%$%lp-tl2902629246%_
                                           (cons _%$%lp-hd2902529243%_
                                                 _%$%ops2902729237%_))))
                                      (let ((_%$%ops2902829249%_
                                             (reverse _%$%ops2902729237%_)))
                                        (_%__kont200129200130%_
                                         _%$%ops2902829249%_
                                         _%$%hd2901829218%_
                                         _%$%hd2901529208%_
                                         _%$%hd2900929188%_))))))
                        (_%$%loop2902329230%_ _%$%target2902029224%_ '())))))
              (if (let ()
                    (declare (not safe))
                    (gx#stx-pair? _%__stx200124200125%_))
                  (let ((_%$%e2897729304%_
                         (let ()
                           (declare (not safe))
                           (gx#syntax-e _%__stx200124200125%_))))
                    (let ((_%$%tl2897929311%_
                           (let ()
                             (declare (not safe))
                             (##cdr _%$%e2897729304%_)))
                          (_%$%hd2897829308%_
                           (let ()
                             (declare (not safe))
                             (##car _%$%e2897729304%_))))
                      (if (let ()
                            (declare (not safe))
                            (gx#stx-pair? _%$%tl2897929311%_))
                          (let ((_%$%e2898029314%_
                                 (let ()
                                   (declare (not safe))
                                   (gx#syntax-e _%$%tl2897929311%_))))
                            (let ((_%$%tl2898229321%_
                                   (let ()
                                     (declare (not safe))
                                     (##cdr _%$%e2898029314%_)))
                                  (_%$%hd2898129318%_
                                   (let ()
                                     (declare (not safe))
                                     (##car _%$%e2898029314%_))))
                              (if (let ()
                                    (declare (not safe))
                                    (gx#stx-pair? _%$%tl2898229321%_))
                                  (let ((_%$%e2898329324%_
                                         (let ()
                                           (declare (not safe))
                                           (gx#syntax-e _%$%tl2898229321%_))))
                                    (let ((_%$%tl2898529331%_
                                           (let ()
                                             (declare (not safe))
                                             (##cdr _%$%e2898329324%_)))
                                          (_%$%hd2898429328%_
                                           (let ()
                                             (declare (not safe))
                                             (##car _%$%e2898329324%_))))
                                      (if (let ()
                                            (declare (not safe))
                                            (gx#stx-pair? _%$%hd2898429328%_))
                                          (let ((_%$%e2898629334%_
                                                 (let ()
                                                   (declare (not safe))
                                                   (gx#syntax-e
                                                    _%$%hd2898429328%_))))
                                            (let ((_%$%tl2898829341%_
                                                   (let ()
                                                     (declare (not safe))
                                                     (##cdr _%$%e2898629334%_)))
                                                  (_%$%hd2898729338%_
                                                   (let ()
                                                     (declare (not safe))
                                                     (##car _%$%e2898629334%_))))
                                              (if (let ()
                                                    (declare (not safe))
                                                    (gx#stx-pair?
                                                     _%$%tl2898829341%_))
                                                  (let ((_%$%e2898929344%_
                                                         (let ()
                                                           (declare (not safe))
                                                           (gx#syntax-e
                                                            _%$%tl2898829341%_))))
                                                    (let ((_%$%tl2899129351%_
                                                           (let ()
                                                             (declare
                                                               (not safe))
                                                             (##cdr _%$%e2898929344%_)))
                                                          (_%$%hd2899029348%_
                                                           (let ()
                                                             (declare
                                                               (not safe))
                                                             (##car _%$%e2898929344%_))))
                                                      (if (let ()
                                                            (declare
                                                              (not safe))
                                                            (gx#stx-pair?
                                                             _%$%tl2899129351%_))
                                                          (let ((_%$%e2899229354%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (let ()
                           (declare (not safe))
                           (gx#syntax-e _%$%tl2899129351%_))))
                    (let ((_%$%tl2899429361%_
                           (let ()
                             (declare (not safe))
                             (##cdr _%$%e2899229354%_)))
                          (_%$%hd2899329358%_
                           (let ()
                             (declare (not safe))
                             (##car _%$%e2899229354%_))))
                      (if (let ()
                            (declare (not safe))
                            (gx#stx-null? _%$%tl2899429361%_))
                          (if (let ()
                                (declare (not safe))
                                (gx#stx-pair? _%$%tl2898529331%_))
                              (let ((_%$%e2899529364%_
                                     (let ()
                                       (declare (not safe))
                                       (gx#syntax-e _%$%tl2898529331%_))))
                                (let ((_%$%tl2899729371%_
                                       (let ()
                                         (declare (not safe))
                                         (##cdr _%$%e2899529364%_)))
                                      (_%$%hd2899629368%_
                                       (let ()
                                         (declare (not safe))
                                         (##car _%$%e2899529364%_))))
                                  (if (let ()
                                        (declare (not safe))
                                        (gx#stx-pair? _%$%tl2899729371%_))
                                      (let ((_%$%e2899829374%_
                                             (let ()
                                               (declare (not safe))
                                               (gx#syntax-e
                                                _%$%tl2899729371%_))))
                                        (let ((_%$%tl2900029381%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##cdr _%$%e2899829374%_)))
                                              (_%$%hd2899929378%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##car _%$%e2899829374%_))))
                                          (if (let ()
                                                (declare (not safe))
                                                (gx#stx-null?
                                                 _%$%tl2900029381%_))
                                              (_%__kont200127200128%_
                                               _%$%hd2899929378%_
                                               _%$%hd2899629368%_
                                               _%$%hd2899329358%_
                                               _%$%hd2899029348%_
                                               _%$%hd2898729338%_
                                               _%$%hd2898129318%_)
                                              (let ()
                                                (declare (not safe))
                                                (_%$%g2896929058%_)))))
                                      (let ()
                                        (declare (not safe))
                                        (_%$%g2896929058%_)))))
                              (let ()
                                (declare (not safe))
                                (_%$%g2896929058%_)))
                          (let () (declare (not safe)) (_%$%g2896929058%_)))))
                  (if (let ()
                        (declare (not safe))
                        (gx#stx-null? _%$%tl2899129351%_))
                      (if (let ()
                            (declare (not safe))
                            (gx#stx-pair/null? _%$%tl2898529331%_))
                          (let ((_%__splice200131200132%_
                                 (let ()
                                   (declare (not safe))
                                   (gx#syntax-split-splice->vector
                                    _%$%tl2898529331%_
                                    '0))))
                            (let ((_%$%tl2902229227%_
                                   (let ()
                                     (declare (not safe))
                                     (##vector-ref
                                      _%__splice200131200132%_
                                      '1)))
                                  (_%$%target2902029224%_
                                   (let ()
                                     (declare (not safe))
                                     (##vector-ref
                                      _%__splice200131200132%_
                                      '0))))
                              (if (let ()
                                    (declare (not safe))
                                    (gx#stx-null? _%$%tl2902229227%_))
                                  (_%__match200229200230%_
                                   _%$%e2897729304%_
                                   _%$%hd2897829308%_
                                   _%$%tl2897929311%_
                                   _%$%e2898029314%_
                                   _%$%hd2898129318%_
                                   _%$%tl2898229321%_
                                   _%$%e2898329324%_
                                   _%$%hd2898429328%_
                                   _%$%tl2898529331%_
                                   _%$%e2898629334%_
                                   _%$%hd2898729338%_
                                   _%$%tl2898829341%_
                                   _%$%e2898929344%_
                                   _%$%hd2899029348%_
                                   _%$%tl2899129351%_
                                   _%__splice200131200132%_
                                   _%$%target2902029224%_
                                   _%$%tl2902229227%_)
                                  (let ()
                                    (declare (not safe))
                                    (_%$%g2896929058%_)))))
                          (let () (declare (not safe)) (_%$%g2896929058%_)))
                      (let () (declare (not safe)) (_%$%g2896929058%_))))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                  (if (let ()
                                                        (declare (not safe))
                                                        (gx#stx-null?
                                                         _%$%tl2898829341%_))
                                                      (if (let ()
                                                            (declare
                                                              (not safe))
                                                            (gx#stx-pair/null?
                                                             _%$%tl2898529331%_))
                                                          (let ((_%__splice200135200136%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (let ()
                           (declare (not safe))
                           (gx#syntax-split-splice->vector
                            _%$%tl2898529331%_
                            '0))))
                    (let ((_%$%tl2904629108%_
                           (let ()
                             (declare (not safe))
                             (##vector-ref _%__splice200135200136%_ '1)))
                          (_%$%target2904429105%_
                           (let ()
                             (declare (not safe))
                             (##vector-ref _%__splice200135200136%_ '0))))
                      (if (let ()
                            (declare (not safe))
                            (gx#stx-null? _%$%tl2904629108%_))
                          (_%__match200263200264%_
                           _%$%e2897729304%_
                           _%$%hd2897829308%_
                           _%$%tl2897929311%_
                           _%$%e2898029314%_
                           _%$%hd2898129318%_
                           _%$%tl2898229321%_
                           _%$%e2898329324%_
                           _%$%hd2898429328%_
                           _%$%tl2898529331%_
                           _%$%e2898629334%_
                           _%$%hd2898729338%_
                           _%$%tl2898829341%_
                           _%__splice200135200136%_
                           _%$%target2904429105%_
                           _%$%tl2904629108%_)
                          (let () (declare (not safe)) (_%$%g2896929058%_)))))
                  (let () (declare (not safe)) (_%$%g2896929058%_)))
              (let () (declare (not safe)) (_%$%g2896929058%_))))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                          (let ()
                                            (declare (not safe))
                                            (_%$%g2896929058%_)))))
                                  (let ()
                                    (declare (not safe))
                                    (_%$%g2896929058%_)))))
                          (let () (declare (not safe)) (_%$%g2896929058%_)))))
                  (let () (declare (not safe)) (_%$%g2896929058%_))))))))
    (define |std/iter/macros[:0:]#for1-in-integers|
      (lambda (_%$stx29425%_)
        (let* ((_%__stx200266200267%_ _%$stx29425%_)
               (_%$%g2943129480%_
                (lambda ()
                  (let ()
                    (declare (not safe))
                    (gx#raise-syntax-error
                     '#f
                     '"Bad syntax; invalid match target"
                     _%__stx200266200267%_)))))
          (let ((_%__kont200269200270%_
                 (lambda (_%$%g2943329656%_
                          _%$%g2943429658%_
                          _%$%g2943529659%_)
                   (cons (let ()
                           (declare (not safe))
                           (gx#datum->syntax__0 '#f 'let))
                         (cons (cons (cons (let ()
                                             (declare (not safe))
                                             (gx#datum->syntax__0 '#f '$start))
                                           (cons _%$%g2943429658%_ '()))
                                     (cons (cons (let ()
                                                   (declare (not safe))
                                                   (gx#datum->syntax__0
                                                    '#f
                                                    '$step))
                                                 (cons _%$%g2943329656%_ '()))
                                           '()))
                               (cons (cons (let ()
                                             (declare (not safe))
                                             (gx#datum->syntax__0 '#f 'let))
                                           (cons (let ()
                                                   (declare (not safe))
                                                   (gx#datum->syntax__0
                                                    '#f
                                                    'loop))
                                                 (cons (cons (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                             (declare (not safe))
                             (gx#datum->syntax__0 '#f 'k))
                           (cons (let ()
                                   (declare (not safe))
                                   (gx#datum->syntax__0 '#f '$start))
                                 '()))
                     '())
               (cons (cons _%$%g2943529659%_
                           (cons (let ()
                                   (declare (not safe))
                                   (gx#datum->syntax__0 '#f 'k))
                                 '()))
                     (cons (cons (let ()
                                   (declare (not safe))
                                   (gx#datum->syntax__0 '#f 'loop))
                                 (cons (cons (let ()
                                               (declare (not safe))
                                               (gx#datum->syntax__0 '#f '+))
                                             (cons (let ()
                                                     (declare (not safe))
                                                     (gx#datum->syntax__0
                                                      '#f
                                                      'k))
                                                   (cons (let ()
                                                           (declare (not safe))
                                                           (gx#datum->syntax__0
                                                            '#f
                                                            '$step))
                                                         '())))
                                       '()))
                           '())))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                     '())))))
                (_%__kont200271200272%_
                 (lambda (_%$%g2945129580%_ _%$%g2945229582%_)
                   (cons (let ()
                           (declare (not safe))
                           (gx#datum->syntax__0 '#f 'for1-in-integers))
                         (cons _%$%g2945229582%_
                               (cons (cons _%$%g2945129580%_ (cons '1 '()))
                                     '())))))
                (_%__kont200273200274%_
                 (lambda (_%$%g2946529517%_)
                   (cons (let ()
                           (declare (not safe))
                           (gx#datum->syntax__0 '#f 'for1-in-integer))
                         (cons (cons '0 (cons '1 '())) '())))))
            (if (let ()
                  (declare (not safe))
                  (gx#stx-pair? _%__stx200266200267%_))
                (let ((_%$%e2943629606%_
                       (let ()
                         (declare (not safe))
                         (gx#syntax-e _%__stx200266200267%_))))
                  (let ((_%$%tl2943829613%_
                         (let ()
                           (declare (not safe))
                           (##cdr _%$%e2943629606%_)))
                        (_%$%hd2943729610%_
                         (let ()
                           (declare (not safe))
                           (##car _%$%e2943629606%_))))
                    (if (let ()
                          (declare (not safe))
                          (gx#stx-pair? _%$%tl2943829613%_))
                        (let ((_%$%e2943929616%_
                               (let ()
                                 (declare (not safe))
                                 (gx#syntax-e _%$%tl2943829613%_))))
                          (let ((_%$%tl2944129623%_
                                 (let ()
                                   (declare (not safe))
                                   (##cdr _%$%e2943929616%_)))
                                (_%$%hd2944029620%_
                                 (let ()
                                   (declare (not safe))
                                   (##car _%$%e2943929616%_))))
                            (if (let ()
                                  (declare (not safe))
                                  (gx#stx-pair? _%$%tl2944129623%_))
                                (let ((_%$%e2944229626%_
                                       (let ()
                                         (declare (not safe))
                                         (gx#syntax-e _%$%tl2944129623%_))))
                                  (let ((_%$%tl2944429633%_
                                         (let ()
                                           (declare (not safe))
                                           (##cdr _%$%e2944229626%_)))
                                        (_%$%hd2944329630%_
                                         (let ()
                                           (declare (not safe))
                                           (##car _%$%e2944229626%_))))
                                    (if (let ()
                                          (declare (not safe))
                                          (gx#stx-pair? _%$%hd2944329630%_))
                                        (let ((_%$%e2944529636%_
                                               (let ()
                                                 (declare (not safe))
                                                 (gx#syntax-e
                                                  _%$%hd2944329630%_))))
                                          (let ((_%$%tl2944729643%_
                                                 (let ()
                                                   (declare (not safe))
                                                   (##cdr _%$%e2944529636%_)))
                                                (_%$%hd2944629640%_
                                                 (let ()
                                                   (declare (not safe))
                                                   (##car _%$%e2944529636%_))))
                                            (if (let ()
                                                  (declare (not safe))
                                                  (gx#stx-pair?
                                                   _%$%tl2944729643%_))
                                                (let ((_%$%e2944829646%_
                                                       (let ()
                                                         (declare (not safe))
                                                         (gx#syntax-e
                                                          _%$%tl2944729643%_))))
                                                  (let ((_%$%tl2945029653%_
                                                         (let ()
                                                           (declare (not safe))
                                                           (##cdr _%$%e2944829646%_)))
                                                        (_%$%hd2944929650%_
                                                         (let ()
                                                           (declare (not safe))
                                                           (##car _%$%e2944829646%_))))
                                                    (if (let ()
                                                          (declare (not safe))
                                                          (gx#stx-null?
                                                           _%$%tl2945029653%_))
                                                        (if (let ()
                                                              (declare
                                                                (not safe))
                                                              (gx#stx-null?
                                                               _%$%tl2944429633%_))
                                                            (_%__kont200269200270%_
                                                             _%$%hd2944929650%_
                                                             _%$%hd2944629640%_
                                                             _%$%hd2944029620%_)
                                                            (let ()
                                                              (declare
                                                                (not safe))
                                                              (_%$%g2943129480%_)))
                                                        (let ()
                                                          (declare (not safe))
                                                          (_%$%g2943129480%_)))))
                                                (if (let ()
                                                      (declare (not safe))
                                                      (gx#stx-null?
                                                       _%$%tl2944729643%_))
                                                    (if (let ()
                                                          (declare (not safe))
                                                          (gx#stx-null?
                                                           _%$%tl2944429633%_))
                                                        (_%__kont200271200272%_
                                                         _%$%hd2944629640%_
                                                         _%$%hd2944029620%_)
                                                        (let ()
                                                          (declare (not safe))
                                                          (_%$%g2943129480%_)))
                                                    (let ()
                                                      (declare (not safe))
                                                      (_%$%g2943129480%_))))))
                                        (if (let ()
                                              (declare (not safe))
                                              (gx#stx-null?
                                               _%$%hd2944329630%_))
                                            (if (let ()
                                                  (declare (not safe))
                                                  (gx#stx-null?
                                                   _%$%tl2944429633%_))
                                                (_%__kont200273200274%_
                                                 _%$%hd2944029620%_)
                                                (let ()
                                                  (declare (not safe))
                                                  (_%$%g2943129480%_)))
                                            (let ()
                                              (declare (not safe))
                                              (_%$%g2943129480%_))))))
                                (let ()
                                  (declare (not safe))
                                  (_%$%g2943129480%_)))))
                        (let () (declare (not safe)) (_%$%g2943129480%_)))))
                (let () (declare (not safe)) (_%$%g2943129480%_)))))))
    (define |std/iter/macros[:0:]#for1-in-numbers|
      (lambda (_%$stx29683%_)
        (let* ((_%$%g2968729716%_
                (lambda (_%$%g2968829712%_)
                  (let ()
                    (declare (not safe))
                    (gx#raise-syntax-error
                     '#f
                     '"Bad syntax; invalid match target"
                     _%$%g2968829712%_))))
               (_%$%g2968629811%_
                (lambda (_%$%g2968829720%_)
                  (if (let ()
                        (declare (not safe))
                        (gx#stx-pair? _%$%g2968829720%_))
                      (let ((_%$%e2969329723%_
                             (let ()
                               (declare (not safe))
                               (gx#syntax-e _%$%g2968829720%_))))
                        (let ((_%$%hd2969429727%_
                               (let ()
                                 (declare (not safe))
                                 (##car _%$%e2969329723%_)))
                              (_%$%tl2969529730%_
                               (let ()
                                 (declare (not safe))
                                 (##cdr _%$%e2969329723%_))))
                          (if (let ()
                                (declare (not safe))
                                (gx#stx-pair? _%$%tl2969529730%_))
                              (let ((_%$%e2969629733%_
                                     (let ()
                                       (declare (not safe))
                                       (gx#syntax-e _%$%tl2969529730%_))))
                                (let ((_%$%hd2969729737%_
                                       (let ()
                                         (declare (not safe))
                                         (##car _%$%e2969629733%_)))
                                      (_%$%tl2969829740%_
                                       (let ()
                                         (declare (not safe))
                                         (##cdr _%$%e2969629733%_))))
                                  (if (let ()
                                        (declare (not safe))
                                        (gx#stx-pair? _%$%tl2969829740%_))
                                      (let ((_%$%e2969929743%_
                                             (let ()
                                               (declare (not safe))
                                               (gx#syntax-e
                                                _%$%tl2969829740%_))))
                                        (let ((_%$%hd2970029747%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##car _%$%e2969929743%_)))
                                              (_%$%tl2970129750%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##cdr _%$%e2969929743%_))))
                                          (if (let ()
                                                (declare (not safe))
                                                (gx#stx-pair?
                                                 _%$%hd2970029747%_))
                                              (let ((_%$%e2970229753%_
                                                     (let ()
                                                       (declare (not safe))
                                                       (gx#syntax-e
                                                        _%$%hd2970029747%_))))
                                                (let ((_%$%hd2970329757%_
                                                       (let ()
                                                         (declare (not safe))
                                                         (##car _%$%e2970229753%_)))
                                                      (_%$%tl2970429760%_
                                                       (let ()
                                                         (declare (not safe))
                                                         (##cdr _%$%e2970229753%_))))
                                                  (if (let ()
                                                        (declare (not safe))
                                                        (gx#stx-pair?
                                                         _%$%tl2970429760%_))
                                                      (let ((_%$%e2970529763%_
                                                             (let ()
                                                               (declare
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (not safe))
                       (gx#syntax-e _%$%tl2970429760%_))))
                (let ((_%$%hd2970629767%_
                       (let () (declare (not safe)) (##car _%$%e2970529763%_)))
                      (_%$%tl2970729770%_
                       (let ()
                         (declare (not safe))
                         (##cdr _%$%e2970529763%_))))
                  (if (let ()
                        (declare (not safe))
                        (gx#stx-pair? _%$%tl2970729770%_))
                      (let ((_%$%e2970829773%_
                             (let ()
                               (declare (not safe))
                               (gx#syntax-e _%$%tl2970729770%_))))
                        (let ((_%$%hd2970929777%_
                               (let ()
                                 (declare (not safe))
                                 (##car _%$%e2970829773%_)))
                              (_%$%tl2971029780%_
                               (let ()
                                 (declare (not safe))
                                 (##cdr _%$%e2970829773%_))))
                          (if (let ()
                                (declare (not safe))
                                (gx#stx-null? _%$%tl2971029780%_))
                              (if (let ()
                                    (declare (not safe))
                                    (gx#stx-null? _%$%tl2970129750%_))
                                  (cons (let ()
                                          (declare (not safe))
                                          (gx#datum->syntax__0 '#f 'let))
                                        (cons (cons (let ()
                                                      (declare (not safe))
                                                      (gx#datum->syntax__0
                                                       '#f
                                                       '$start))
                                                    (cons _%$%hd2970329757%_
                                                          '()))
                                              (cons (cons (let ()
                                                            (declare
                                                              (not safe))
                                                            (gx#datum->syntax__0
                                                             '#f
                                                             'let))
                                                          (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                          (declare (not safe))
                          (gx#datum->syntax__0 '#f 'loop))
                        (cons (cons (cons (let ()
                                            (declare (not safe))
                                            (gx#datum->syntax__0 '#f 'k))
                                          (cons (let ()
                                                  (declare (not safe))
                                                  (gx#datum->syntax__0
                                                   '#f
                                                   '$start))
                                                '()))
                                    '())
                              (cons (cons (let ()
                                            (declare (not safe))
                                            (gx#datum->syntax__0 '#f 'unless))
                                          (cons (cons _%$%hd2970929777%_
                                                      (cons (let ()
                                                              (declare
                                                                (not safe))
                                                              (gx#datum->syntax__0
                                                               '#f
                                                               'k))
                                                            '()))
                                                (cons (cons _%$%hd2969729737%_
                                                            (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                            (declare (not safe))
                            (gx#datum->syntax__0 '#f 'k))
                          '()))
              (cons (cons (let ()
                            (declare (not safe))
                            (gx#datum->syntax__0 '#f 'loop))
                          (cons (cons _%$%hd2970629767%_
                                      (cons (let ()
                                              (declare (not safe))
                                              (gx#datum->syntax__0 '#f 'k))
                                            '()))
                                '()))
                    '()))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                    '()))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                    '())))
                                  (_%$%g2968729716%_ _%$%g2968829720%_))
                              (_%$%g2968729716%_ _%$%g2968829720%_))))
                      (_%$%g2968729716%_ _%$%g2968829720%_))))
              (_%$%g2968729716%_ _%$%g2968829720%_))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                              (_%$%g2968729716%_
                                               _%$%g2968829720%_))))
                                      (_%$%g2968729716%_ _%$%g2968829720%_))))
                              (_%$%g2968729716%_ _%$%g2968829720%_))))
                      (_%$%g2968729716%_ _%$%g2968829720%_)))))
          (_%$%g2968629811%_ _%$stx29683%_))))
    (define |std/iter/macros[:0:]#for1-generic|
      (lambda (_%stx29815%_)
        (let* ((_%$%g2981829836%_
                (lambda (_%$%g2981929832%_)
                  (let ()
                    (declare (not safe))
                    (gx#raise-syntax-error
                     '#f
                     '"Bad syntax; invalid match target"
                     _%$%g2981929832%_))))
               (_%$%g2981729956%_
                (lambda (_%$%g2981929840%_)
                  (if (let ()
                        (declare (not safe))
                        (gx#stx-pair? _%$%g2981929840%_))
                      (let ((_%$%e2982229843%_
                             (let ()
                               (declare (not safe))
                               (gx#syntax-e _%$%g2981929840%_))))
                        (let ((_%$%hd2982329847%_
                               (let ()
                                 (declare (not safe))
                                 (##car _%$%e2982229843%_)))
                              (_%$%tl2982429850%_
                               (let ()
                                 (declare (not safe))
                                 (##cdr _%$%e2982229843%_))))
                          (if (let ()
                                (declare (not safe))
                                (gx#stx-pair? _%$%tl2982429850%_))
                              (let ((_%$%e2982529853%_
                                     (let ()
                                       (declare (not safe))
                                       (gx#syntax-e _%$%tl2982429850%_))))
                                (let ((_%$%hd2982629857%_
                                       (let ()
                                         (declare (not safe))
                                         (##car _%$%e2982529853%_)))
                                      (_%$%tl2982729860%_
                                       (let ()
                                         (declare (not safe))
                                         (##cdr _%$%e2982529853%_))))
                                  (if (let ()
                                        (declare (not safe))
                                        (gx#stx-pair? _%$%tl2982729860%_))
                                      (let ((_%$%e2982829863%_
                                             (let ()
                                               (declare (not safe))
                                               (gx#syntax-e
                                                _%$%tl2982729860%_))))
                                        (let ((_%$%hd2982929867%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##car _%$%e2982829863%_)))
                                              (_%$%tl2983029870%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##cdr _%$%e2982829863%_))))
                                          (if (let ()
                                                (declare (not safe))
                                                (gx#stx-null?
                                                 _%$%tl2983029870%_))
                                              (let* ((_%$%g2989129899%_
                                                      (lambda (_%$%g2989229895%_)
                                                        (let ()
                                                          (declare (not safe))
                                                          (gx#raise-syntax-error
                                                           '#f
                                                           '"Bad syntax; invalid match target"
                                                           _%$%g2989229895%_))))
                                                     (_%$%g2989029952%_
                                                      (lambda (_%$%g2989229903%_)
                                                        (let* ((_%$%g2991729926%_
                                                                (lambda (_%$%g2991829922%_)
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                          (let ()
                            (declare (not safe))
                            (gx#raise-syntax-error
                             '#f
                             '"Bad syntax; invalid match target"
                             _%$%g2991829922%_))))
                       (_%$%g2991629948%_
                        (lambda (_%$%g2991829930%_)
                          (cons (let ()
                                  (declare (not safe))
                                  (gx#datum->syntax__0 '#f 'using))
                                (cons (cons _%$%g2989229903%_
                                            (cons (cons (let ()
                                                          (declare (not safe))
                                                          (gx#datum->syntax__0
                                                           '#f
                                                           'iter))
                                                        (cons _%$%hd2982929867%_
                                                              '()))
                                                  (cons (let ()
                                                          (declare (not safe))
                                                          (gx#datum->syntax__0
                                                           '#f
                                                           ':-))
                                                        (cons (let ()
                                                                (declare
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                          (not safe))
                        (gx#datum->syntax__0 '#f 'Iterator))
                      '()))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                      (cons (cons (let ()
                                                    (declare (not safe))
                                                    (gx#datum->syntax__0
                                                     '#f
                                                     'let))
                                                  (cons (let ()
                                                          (declare (not safe))
                                                          (gx#datum->syntax__0
                                                           '#f
                                                           'loop))
                                                        (cons '()
                                                              (cons (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                    (declare (not safe))
                                    (gx#datum->syntax__0 '#f 'let))
                                  (cons (cons (let ()
                                                (declare (not safe))
                                                (gx#datum->syntax__0
                                                 '#f
                                                 'next))
                                              (cons (cons _%$%g2991829930%_
                                                          '())
                                                    '()))
                                        (cons (cons (let ()
                                                      (declare (not safe))
                                                      (gx#datum->syntax__0
                                                       '#f
                                                       'unless))
                                                    (cons (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                          (declare (not safe))
                          (gx#datum->syntax__0 '#f 'eq?))
                        (cons (let ()
                                (declare (not safe))
                                (gx#datum->syntax__0 '#f 'next))
                              (cons '#!eof '())))
                  (cons (cons _%$%hd2982629857%_
                              (cons (let ()
                                      (declare (not safe))
                                      (gx#datum->syntax__0 '#f 'next))
                                    '()))
                        (cons (cons (let ()
                                      (declare (not safe))
                                      (gx#datum->syntax__0 '#f 'loop))
                                    '())
                              '()))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                              '())))
                            '()))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                            '()))))))
                  (_%$%g2991629948%_
                   (let ()
                     (declare (not safe))
                     (gx#stx-identifier
                      _%$%g2989229903%_
                      _%$%g2989229903%_
                      '".next!")))))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                (_%$%g2989029952%_
                                                 (let ()
                                                   (declare (not safe))
                                                   (gx#syntax-local-temp
                                                    '$it))))
                                              (_%$%g2981829836%_
                                               _%$%g2981929840%_))))
                                      (_%$%g2981829836%_ _%$%g2981929840%_))))
                              (_%$%g2981829836%_ _%$%g2981929840%_))))
                      (_%$%g2981829836%_ _%$%g2981929840%_)))))
          (_%$%g2981729956%_ _%stx29815%_))))
    (define |std/iter/macros[:0:]#forN|
      (lambda (_%stx29960%_)
        (letrec ((_%make-dispatch29963%_
                  (lambda (_%bindings30423%_ _%body30425%_)
                    (let _%loop30427%_ ((_%rest30430%_ _%bindings30423%_)
                                        (_%args30432%_ '())
                                        (_%it-exprs30433%_ '())
                                        (_%iters30434%_ '())
                                        (_%temps30435%_ '())
                                        (_%body30436%_ _%body30425%_)
                                        (_%match?30437%_ '#f))
                      (let* ((_%__stx200408200409%_ _%rest30430%_)
                             (_%$%g3044130462%_
                              (lambda ()
                                (let ()
                                  (declare (not safe))
                                  (gx#raise-syntax-error
                                   '#f
                                   '"Bad syntax; invalid match target"
                                   _%__stx200408200409%_)))))
                        (let ((_%__kont200411200412%_
                               (lambda (_%$%g3044330782%_ _%$%g3044430784%_)
                                 (let* ((_%$%g3079530811%_
                                         (lambda (_%$%g3079630807%_)
                                           (let ()
                                             (declare (not safe))
                                             (gx#raise-syntax-error
                                              '#f
                                              '"Bad syntax; invalid match target"
                                              _%$%g3079630807%_))))
                                        (_%$%g3079431046%_
                                         (lambda (_%$%g3079630815%_)
                                           (if (let ()
                                                 (declare (not safe))
                                                 (gx#stx-pair?
                                                  _%$%g3079630815%_))
                                               (let ((_%$%e3080030818%_
                                                      (let ()
                                                        (declare (not safe))
                                                        (gx#syntax-e
                                                         _%$%g3079630815%_))))
                                                 (let ((_%$%hd3080130822%_
                                                        (let ()
                                                          (declare (not safe))
                                                          (##car _%$%e3080030818%_)))
                                                       (_%$%tl3080230825%_
                                                        (let ()
                                                          (declare (not safe))
                                                          (##cdr _%$%e3080030818%_))))
                                                   (if (let ()
                                                         (declare (not safe))
                                                         (gx#stx-pair?
                                                          _%$%tl3080230825%_))
                                                       (let ((_%$%e3080330828%_
                                                              (let ()
                                                                (declare
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                          (not safe))
                        (gx#syntax-e _%$%tl3080230825%_))))
                 (let ((_%$%hd3080430832%_
                        (let ()
                          (declare (not safe))
                          (##car _%$%e3080330828%_)))
                       (_%$%tl3080530835%_
                        (let ()
                          (declare (not safe))
                          (##cdr _%$%e3080330828%_))))
                   (let ((_%body31039%_
                          (if (let ()
                                (declare (not safe))
                                (gx#stx-null? _%$%tl3080530835%_))
                              _%body30436%_
                              (let* ((_%__stx200386200387%_ _%$%tl3080530835%_)
                                     (_%$%g3085730874%_
                                      (lambda ()
                                        (let ()
                                          (declare (not safe))
                                          (gx#raise-syntax-error
                                           '#f
                                           '"Bad syntax; invalid match target"
                                           _%__stx200386200387%_)))))
                                (let ((_%__kont200389200390%_
                                       (lambda (_%$%g3085930949%_
                                                _%$%g3086030951%_
                                                _%$%g3086130952%_)
                                         (if (let ()
                                               (declare (not safe))
                                               (gx#stx-null?
                                                _%$%g3085930949%_))
                                             (let* ((_%$%g3096830976%_
                                                     (lambda (_%$%g3096930972%_)
                                                       (let ()
                                                         (declare (not safe))
                                                         (gx#raise-syntax-error
                                                          '#f
                                                          '"Bad syntax; invalid match target"
                                                          _%$%g3096930972%_))))
                                                    (_%$%g3096730996%_
                                                     (lambda (_%$%g3096930980%_)
                                                       (cons _%$%g3086130952%_
                                                             (cons _%$%g3086030951%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                           (cons _%$%g3096930980%_ '()))))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                               (_%$%g3096730996%_
                                                _%body30436%_))
                                             (if (let ()
                                                   (declare (not safe))
                                                   (gx#identifier?
                                                    _%$%hd3080130822%_))
                                                 (let* ((_%$%g3100231010%_
                                                         (lambda (_%$%g3100331006%_)
                                                           (let ()
                                                             (declare
                                                               (not safe))
                                                             (gx#raise-syntax-error
                                                              '#f
                                                              '"Bad syntax; invalid match target"
                                                              _%$%g3100331006%_))))
                                                        (_%$%g3100131029%_
                                                         (lambda (_%$%g3100331014%_)
                                                           (cons _%$%g3086130952%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (cons _%$%g3086030951%_
                               (cons (cons (let ()
                                             (declare (not safe))
                                             (gx#datum->syntax__0 '#f 'using))
                                           (cons (cons _%$%hd3080130822%_
                                                       _%$%g3085930949%_)
                                                 (cons _%$%g3100331014%_ '())))
                                     '()))))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                   (_%$%g3100131029%_
                                                    _%body30436%_))
                                                 (let ()
                                                   (declare (not safe))
                                                   (gx#raise-syntax-error
                                                    '#f
                                                    '"cannot apply contract to pattern"
                                                    _%stx29960%_
                                                    _%$%hd3080130822%_))))))
                                      (_%__kont200391200392%_
                                       (lambda (_%$%g3086830881%_)
                                         (if (let ()
                                               (declare (not safe))
                                               (gx#identifier?
                                                _%$%hd3080130822%_))
                                             (let* ((_%$%g3089130899%_
                                                     (lambda (_%$%g3089230895%_)
                                                       (let ()
                                                         (declare (not safe))
                                                         (gx#raise-syntax-error
                                                          '#f
                                                          '"Bad syntax; invalid match target"
                                                          _%$%g3089230895%_))))
                                                    (_%$%g3089030918%_
                                                     (lambda (_%$%g3089230903%_)
                                                       (cons (let ()
                                                               (declare
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (not safe))
                       (gx#datum->syntax__0 '#f 'using))
                     (cons (cons _%$%hd3080130822%_ _%$%g3086830881%_)
                           (cons _%$%g3089230903%_ '()))))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                               (_%$%g3089030918%_
                                                _%body30436%_))
                                             (let ()
                                               (declare (not safe))
                                               (gx#raise-syntax-error
                                                '#f
                                                '"cannot apply contract to pattern"
                                                _%stx29960%_
                                                _%$%hd3080130822%_))))))
                                  (let ((_%__match200405200406%_
                                         (lambda (_%$%e3086230929%_
                                                  _%$%hd3086330933%_
                                                  _%$%tl3086430936%_
                                                  _%$%e3086530939%_
                                                  _%$%hd3086630943%_
                                                  _%$%tl3086730946%_)
                                           (let ((_%$%g3085930949%_
                                                  _%$%tl3086730946%_)
                                                 (_%$%g3086030951%_
                                                  _%$%hd3086630943%_)
                                                 (_%$%g3086130952%_
                                                  _%$%hd3086330933%_))
                                             (if (and (let ()
                                                        (declare (not safe))
                                                        (gx#identifier?
                                                         _%$%g3086130952%_))
                                                      (let ()
                                                        (declare (not safe))
                                                        (##member
                                                         _%$%g3086130952%_
                                                         '(when unless)
                                                         gx#free-identifier=?)))
                                                 (_%__kont200389200390%_
                                                  _%$%g3085930949%_
                                                  _%$%g3086030951%_
                                                  _%$%g3086130952%_)
                                                 (_%__kont200391200392%_
                                                  _%__stx200386200387%_))))))
                                    (if (let ()
                                          (declare (not safe))
                                          (gx#stx-pair? _%__stx200386200387%_))
                                        (let ((_%$%e3086230929%_
                                               (let ()
                                                 (declare (not safe))
                                                 (gx#syntax-e
                                                  _%__stx200386200387%_))))
                                          (let ((_%$%tl3086430936%_
                                                 (let ()
                                                   (declare (not safe))
                                                   (##cdr _%$%e3086230929%_)))
                                                (_%$%hd3086330933%_
                                                 (let ()
                                                   (declare (not safe))
                                                   (##car _%$%e3086230929%_))))
                                            (if (let ()
                                                  (declare (not safe))
                                                  (gx#stx-pair?
                                                   _%$%tl3086430936%_))
                                                (let ((_%$%e3086530939%_
                                                       (let ()
                                                         (declare (not safe))
                                                         (gx#syntax-e
                                                          _%$%tl3086430936%_))))
                                                  (let ((_%$%tl3086730946%_
                                                         (let ()
                                                           (declare (not safe))
                                                           (##cdr _%$%e3086530939%_)))
                                                        (_%$%hd3086630943%_
                                                         (let ()
                                                           (declare (not safe))
                                                           (##car _%$%e3086530939%_))))
                                                    (_%__match200405200406%_
                                                     _%$%e3086230929%_
                                                     _%$%hd3086330933%_
                                                     _%$%tl3086430936%_
                                                     _%$%e3086530939%_
                                                     _%$%hd3086630943%_
                                                     _%$%tl3086730946%_)))
                                                (_%__kont200391200392%_
                                                 _%__stx200386200387%_))))
                                        (_%__kont200391200392%_
                                         _%__stx200386200387%_))))))))
                     (_%loop30427%_
                      _%$%g3044330782%_
                      (cons _%$%hd3080130822%_ _%args30432%_)
                      (cons _%$%hd3080430832%_ _%it-exprs30433%_)
                      (cons (let ()
                              (declare (not safe))
                              (gx#syntax-local-temp '$it))
                            _%iters30434%_)
                      (cons (let ()
                              (declare (not safe))
                              (gx#syntax-local-temp '$next))
                            _%temps30435%_)
                      _%body31039%_
                      (let ((_%$e31042%_ _%match?30437%_))
                        (if _%$e31042%_
                            _%$e31042%_
                            (not (let ()
                                   (declare (not safe))
                                   (gx#identifier? _%$%hd3080130822%_)))))))))
               (_%$%g3079530811%_ _%$%g3079630815%_))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                               (_%$%g3079530811%_
                                                _%$%g3079630815%_)))))
                                   (_%$%g3079431046%_ _%$%g3044430784%_))))
                              (_%__kont200413200414%_
                               (lambda (_%$%g3044830627%_
                                        _%$%g3044930629%_
                                        _%$%g3045030630%_)
                                 (let _%loop-filter30644%_ ((_%rest30647%_
                                                             (cons _%$%g3045030630%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                           (cons _%$%g3044930629%_ _%$%g3044830627%_)))
                    (_%body30649%_ _%body30436%_))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                   (let* ((_%__stx200362200363%_ _%rest30647%_)
                                          (_%$%g3065230668%_
                                           (lambda ()
                                             (let ()
                                               (declare (not safe))
                                               (gx#raise-syntax-error
                                                '#f
                                                '"Bad syntax; invalid match target"
                                                _%__stx200362200363%_)))))
                                     (let ((_%__kont200365200366%_
                                            (lambda (_%$%g3065430706%_
                                                     _%$%g3065530708%_
                                                     _%$%g3065630709%_)
                                              (let* ((_%$%g3072730735%_
                                                      (lambda (_%$%g3072830731%_)
                                                        (let ()
                                                          (declare (not safe))
                                                          (gx#raise-syntax-error
                                                           '#f
                                                           '"Bad syntax; invalid match target"
                                                           _%$%g3072830731%_))))
                                                     (_%$%g3072630757%_
                                                      (lambda (_%$%g3072830739%_)
                                                        (let ((_%body30754%_
                                                               (cons _%$%g3065630709%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                             (cons _%$%g3065530708%_
                                   (cons _%$%g3072830739%_ '())))))
                  (_%loop-filter30644%_ _%$%g3065430706%_ _%body30754%_)))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                (_%$%g3072630757%_
                                                 _%body30649%_))))
                                           (_%__kont200367200368%_
                                            (lambda ()
                                              (_%loop30427%_
                                               '()
                                               _%args30432%_
                                               _%it-exprs30433%_
                                               _%iters30434%_
                                               _%temps30435%_
                                               _%body30649%_
                                               _%match?30437%_))))
                                       (let* ((_%$%g3065130679%_
                                               (lambda ()
                                                 (if (let ()
                                                       (declare (not safe))
                                                       (gx#stx-null?
                                                        _%__stx200362200363%_))
                                                     (_%__kont200367200368%_)
                                                     (let ()
                                                       (declare (not safe))
                                                       (_%$%g3065230668%_)))))
                                              (_%__match200381200382%_
                                               (lambda (_%$%e3065730686%_
                                                        _%$%hd3065830690%_
                                                        _%$%tl3065930693%_
                                                        _%$%e3066030696%_
                                                        _%$%hd3066130700%_
                                                        _%$%tl3066230703%_)
                                                 (let ((_%$%g3065430706%_
                                                        _%$%tl3066230703%_)
                                                       (_%$%g3065530708%_
                                                        _%$%hd3066130700%_)
                                                       (_%$%g3065630709%_
                                                        _%$%hd3065830690%_))
                                                   (if (and (let ()
                                                              (declare
                                                                (not safe))
                                                              (gx#identifier?
                                                               _%$%g3065630709%_))
                                                            (let ()
                                                              (declare
                                                                (not safe))
                                                              (##member
                                                               _%$%g3065630709%_
                                                               '(when unless)
                                                               gx#free-identifier=?)))
                                                       (_%__kont200365200366%_
                                                        _%$%g3065430706%_
                                                        _%$%g3065530708%_
                                                        _%$%g3065630709%_)
                                                       (let ()
                                                         (declare (not safe))
                                                         (_%$%g3065230668%_)))))))
                                         (if (let ()
                                               (declare (not safe))
                                               (gx#stx-pair?
                                                _%__stx200362200363%_))
                                             (let ((_%$%e3065730686%_
                                                    (let ()
                                                      (declare (not safe))
                                                      (gx#syntax-e
                                                       _%__stx200362200363%_))))
                                               (let ((_%$%tl3065930693%_
                                                      (let ()
                                                        (declare (not safe))
                                                        (##cdr _%$%e3065730686%_)))
                                                     (_%$%hd3065830690%_
                                                      (let ()
                                                        (declare (not safe))
                                                        (##car _%$%e3065730686%_))))
                                                 (if (let ()
                                                       (declare (not safe))
                                                       (gx#stx-pair?
                                                        _%$%tl3065930693%_))
                                                     (let ((_%$%e3066030696%_
                                                            (let ()
                                                              (declare
                                                                (not safe))
                                                              (gx#syntax-e
                                                               _%$%tl3065930693%_))))
                                                       (let ((_%$%tl3066230703%_
                                                              (let ()
                                                                (declare
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                          (not safe))
                        (##cdr _%$%e3066030696%_)))
                     (_%$%hd3066130700%_
                      (let () (declare (not safe)) (##car _%$%e3066030696%_))))
                 (_%__match200381200382%_
                  _%$%e3065730686%_
                  _%$%hd3065830690%_
                  _%$%tl3065930693%_
                  _%$%e3066030696%_
                  _%$%hd3066130700%_
                  _%$%tl3066230703%_)))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                     (let ()
                                                       (declare (not safe))
                                                       (_%$%g3065230668%_)))))
                                             (let ()
                                               (declare (not safe))
                                               (_%$%g3065130679%_)))))))))
                              (_%__kont200415200416%_
                               (lambda ()
                                 (let* ((_%$%g3047330497%_
                                         (lambda (_%$%g3047430493%_)
                                           (let ()
                                             (declare (not safe))
                                             (gx#raise-syntax-error
                                              '#f
                                              '"Bad syntax; invalid match target"
                                              _%$%g3047430493%_))))
                                        (_%$%g3047230596%_
                                         (lambda (_%$%g3047430501%_)
                                           (if (let ()
                                                 (declare (not safe))
                                                 (gx#stx-pair?
                                                  _%$%g3047430501%_))
                                               (let ((_%$%e3047730504%_
                                                      (let ()
                                                        (declare (not safe))
                                                        (gx#syntax-e
                                                         _%$%g3047430501%_))))
                                                 (let ((_%$%hd3047830508%_
                                                        (let ()
                                                          (declare (not safe))
                                                          (##car _%$%e3047730504%_)))
                                                       (_%$%tl3047930511%_
                                                        (let ()
                                                          (declare (not safe))
                                                          (##cdr _%$%e3047730504%_))))
                                                   (if (let ()
                                                         (declare (not safe))
                                                         (gx#stx-pair/null?
                                                          _%$%hd3047830508%_))
                                                       (let ((_g200812_
                                                              (let ()
                                                                (declare
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                          (not safe))
                        (gx#syntax-split-splice _%$%hd3047830508%_ '0))))
                 (begin
                   (let ((_g200813_
                          (let ()
                            (declare (not safe))
                            (if (##values? _g200812_)
                                (##values-length _g200812_)
                                1))))
                     (if (not (let ()
                                (declare (not safe))
                                (##fx= _g200813_ 2)))
                         (error "Context expects 2 values" _g200813_)))
                   (let ((_%$%target3048030514%_
                          (let ()
                            (declare (not safe))
                            (##values-ref _g200812_ 0)))
                         (_%$%tl3048230517%_
                          (let ()
                            (declare (not safe))
                            (##values-ref _g200812_ 1))))
                     (if (let ()
                           (declare (not safe))
                           (gx#stx-null? _%$%tl3048230517%_))
                         (letrec ((_%$%loop3048330520%_
                                   (lambda (_%$%hd3048130524%_
                                            _%$%arg3048730527%_)
                                     (if (let ()
                                           (declare (not safe))
                                           (gx#stx-pair? _%$%hd3048130524%_))
                                         (let ((_%$%e3048430529%_
                                                (let ()
                                                  (declare (not safe))
                                                  (gx#syntax-e
                                                   _%$%hd3048130524%_))))
                                           (let ((_%$%lp-hd3048530533%_
                                                  (let ()
                                                    (declare (not safe))
                                                    (##car _%$%e3048430529%_)))
                                                 (_%$%lp-tl3048630536%_
                                                  (let ()
                                                    (declare (not safe))
                                                    (##cdr _%$%e3048430529%_))))
                                             (_%$%loop3048330520%_
                                              _%$%lp-tl3048630536%_
                                              (cons _%$%lp-hd3048530533%_
                                                    _%$%arg3048730527%_))))
                                         (let ((_%$%arg3048830539%_
                                                (reverse _%$%arg3048730527%_)))
                                           (if (let ()
                                                 (declare (not safe))
                                                 (gx#stx-pair?
                                                  _%$%tl3047930511%_))
                                               (let ((_%$%e3048930542%_
                                                      (let ()
                                                        (declare (not safe))
                                                        (gx#syntax-e
                                                         _%$%tl3047930511%_))))
                                                 (let ((_%$%hd3049030546%_
                                                        (let ()
                                                          (declare (not safe))
                                                          (##car _%$%e3048930542%_)))
                                                       (_%$%tl3049130549%_
                                                        (let ()
                                                          (declare (not safe))
                                                          (##cdr _%$%e3048930542%_))))
                                                   (if (let ()
                                                         (declare (not safe))
                                                         (gx#stx-null?
                                                          _%$%tl3049130549%_))
                                                       (values (if _%match?30437%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                           (let ((__tmp200815
                                  (cons (let ()
                                          (declare (not safe))
                                          (gx#datum->syntax__0 '#f 'lambda))
                                        (cons (let ()
                                                (declare (not safe))
                                                (gx#datum->syntax__0
                                                 '#f
                                                 '$args))
                                              (cons (cons (let ()
                                                            (declare
                                                              (not safe))
                                                            (gx#datum->syntax__0
                                                             '#f
                                                             'match))
                                                          (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                          (declare (not safe))
                          (gx#datum->syntax__0 '#f '$args))
                        (cons (cons (cons (let ()
                                            (declare (not safe))
                                            (gx#datum->syntax__0 '#f '@list))
                                          (let ((__tmp200816
                                                 (lambda (_%$%g3057930582%_
                                                          _%$%g3058030585%_)
                                                   (cons _%$%g3057930582%_
                                                         _%$%g3058030585%_))))
                                            (declare (not safe))
                                            (foldr__0
                                             __tmp200816
                                             '()
                                             _%$%arg3048830539%_)))
                                    (cons _%$%hd3049030546%_ '()))
                              '())))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                    '()))))
                                 (__tmp200814
                                  (let ()
                                    (declare (not safe))
                                    (gx#stx-source _%stx29960%_))))
                             (declare (not safe))
                             (gx#stx-wrap-source __tmp200815 __tmp200814))
                           (let ((__tmp200818
                                  (cons (let ()
                                          (declare (not safe))
                                          (gx#datum->syntax__0 '#f 'lambda))
                                        (cons (let ((__tmp200819
                                                     (lambda (_%$%g3058730590%_
                                                              _%$%g3058830593%_)
                                                       (cons _%$%g3058730590%_
                                                             _%$%g3058830593%_))))
                                                (declare (not safe))
                                                (foldr__0
                                                 __tmp200819
                                                 '()
                                                 _%$%arg3048830539%_))
                                              (cons _%$%hd3049030546%_ '()))))
                                 (__tmp200817
                                  (let ()
                                    (declare (not safe))
                                    (gx#stx-source _%stx29960%_))))
                             (declare (not safe))
                             (gx#stx-wrap-source __tmp200818 __tmp200817)))
                       (reverse! _%it-exprs30433%_)
                       (reverse! _%iters30434%_)
                       (reverse! _%temps30435%_))
               (_%$%g3047330497%_ _%$%g3047430501%_))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                               (_%$%g3047330497%_
                                                _%$%g3047430501%_)))))))
                           (_%$%loop3048330520%_ _%$%target3048030514%_ '()))
                         (_%$%g3047330497%_ _%$%g3047430501%_)))))
               (_%$%g3047330497%_ _%$%g3047430501%_))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                               (_%$%g3047330497%_
                                                _%$%g3047430501%_)))))
                                   (_%$%g3047230596%_
                                    (list (reverse! _%args30432%_)
                                          _%body30436%_))))))
                          (let* ((_%$%g3044030600%_
                                  (lambda ()
                                    (if (let ()
                                          (declare (not safe))
                                          (gx#stx-null? _%__stx200408200409%_))
                                        (_%__kont200415200416%_)
                                        (let ()
                                          (declare (not safe))
                                          (_%$%g3044130462%_)))))
                                 (_%__match200435200436%_
                                  (lambda (_%$%e3045130607%_
                                           _%$%hd3045230611%_
                                           _%$%tl3045330614%_
                                           _%$%e3045430617%_
                                           _%$%hd3045530621%_
                                           _%$%tl3045630624%_)
                                    (let ((_%$%g3044830627%_
                                           _%$%tl3045630624%_)
                                          (_%$%g3044930629%_
                                           _%$%hd3045530621%_)
                                          (_%$%g3045030630%_
                                           _%$%hd3045230611%_))
                                      (if (and (let ()
                                                 (declare (not safe))
                                                 (gx#identifier?
                                                  _%$%g3045030630%_))
                                               (let ()
                                                 (declare (not safe))
                                                 (##member
                                                  _%$%g3045030630%_
                                                  '(when unless)
                                                  gx#free-identifier=?)))
                                          (_%__kont200413200414%_
                                           _%$%g3044830627%_
                                           _%$%g3044930629%_
                                           _%$%g3045030630%_)
                                          (let ()
                                            (declare (not safe))
                                            (_%$%g3044130462%_))))))
                                 (_%__match200423200424%_
                                  (lambda (_%$%e3044530772%_
                                           _%$%hd3044630776%_
                                           _%$%tl3044730779%_)
                                    (let ((_%$%g3044330782%_
                                           _%$%tl3044730779%_)
                                          (_%$%g3044430784%_
                                           _%$%hd3044630776%_))
                                      (if (|std/iter/macros[1]#for-binding?|
                                           _%$%g3044430784%_)
                                          (_%__kont200411200412%_
                                           _%$%g3044330782%_
                                           _%$%g3044430784%_)
                                          (if (let ()
                                                (declare (not safe))
                                                (gx#stx-pair?
                                                 _%$%tl3044730779%_))
                                              (let ((_%$%e3045430617%_
                                                     (let ()
                                                       (declare (not safe))
                                                       (gx#syntax-e
                                                        _%$%tl3044730779%_))))
                                                (let ((_%$%tl3045630624%_
                                                       (let ()
                                                         (declare (not safe))
                                                         (##cdr _%$%e3045430617%_)))
                                                      (_%$%hd3045530621%_
                                                       (let ()
                                                         (declare (not safe))
                                                         (##car _%$%e3045430617%_))))
                                                  (_%__match200435200436%_
                                                   _%$%e3044530772%_
                                                   _%$%hd3044630776%_
                                                   _%$%tl3044730779%_
                                                   _%$%e3045430617%_
                                                   _%$%hd3045530621%_
                                                   _%$%tl3045630624%_)))
                                              (let ()
                                                (declare (not safe))
                                                (_%$%g3044130462%_))))))))
                            (if (let ()
                                  (declare (not safe))
                                  (gx#stx-pair? _%__stx200408200409%_))
                                (let ((_%$%e3044530772%_
                                       (let ()
                                         (declare (not safe))
                                         (gx#syntax-e _%__stx200408200409%_))))
                                  (let ((_%$%tl3044730779%_
                                         (let ()
                                           (declare (not safe))
                                           (##cdr _%$%e3044530772%_)))
                                        (_%$%hd3044630776%_
                                         (let ()
                                           (declare (not safe))
                                           (##car _%$%e3044530772%_))))
                                    (_%__match200423200424%_
                                     _%$%e3044530772%_
                                     _%$%hd3044630776%_
                                     _%$%tl3044730779%_)))
                                (let ()
                                  (declare (not safe))
                                  (_%$%g3044030600%_))))))))))
          (let* ((_%$%g2996629993%_
                  (lambda (_%$%g2996729989%_)
                    (let ()
                      (declare (not safe))
                      (gx#raise-syntax-error
                       '#f
                       '"Bad syntax; invalid match target"
                       _%$%g2996729989%_))))
                 (_%$%g2996530419%_
                  (lambda (_%$%g2996729997%_)
                    (if (let ()
                          (declare (not safe))
                          (gx#stx-pair? _%$%g2996729997%_))
                        (let ((_%$%e2997030000%_
                               (let ()
                                 (declare (not safe))
                                 (gx#syntax-e _%$%g2996729997%_))))
                          (let ((_%$%hd2997130004%_
                                 (let ()
                                   (declare (not safe))
                                   (##car _%$%e2997030000%_)))
                                (_%$%tl2997230007%_
                                 (let ()
                                   (declare (not safe))
                                   (##cdr _%$%e2997030000%_))))
                            (if (let ()
                                  (declare (not safe))
                                  (gx#stx-pair? _%$%tl2997230007%_))
                                (let ((_%$%e2997330010%_
                                       (let ()
                                         (declare (not safe))
                                         (gx#syntax-e _%$%tl2997230007%_))))
                                  (let ((_%$%hd2997430014%_
                                         (let ()
                                           (declare (not safe))
                                           (##car _%$%e2997330010%_)))
                                        (_%$%tl2997530017%_
                                         (let ()
                                           (declare (not safe))
                                           (##cdr _%$%e2997330010%_))))
                                    (if (let ()
                                          (declare (not safe))
                                          (gx#stx-pair/null?
                                           _%$%hd2997430014%_))
                                        (let ((_g200820_
                                               (let ()
                                                 (declare (not safe))
                                                 (gx#syntax-split-splice
                                                  _%$%hd2997430014%_
                                                  '0))))
                                          (begin
                                            (let ((_g200821_
                                                   (let ()
                                                     (declare (not safe))
                                                     (if (##values? _g200820_)
                                                         (##values-length
                                                          _g200820_)
                                                         1))))
                                              (if (not (let ()
                                                         (declare (not safe))
                                                         (##fx= _g200821_ 2)))
                                                  (error "Context expects 2 values"
                                                         _g200821_)))
                                            (let ((_%$%target2997630020%_
                                                   (let ()
                                                     (declare (not safe))
                                                     (##values-ref
                                                      _g200820_
                                                      0)))
                                                  (_%$%tl2997830023%_
                                                   (let ()
                                                     (declare (not safe))
                                                     (##values-ref
                                                      _g200820_
                                                      1))))
                                              (if (let ()
                                                    (declare (not safe))
                                                    (gx#stx-null?
                                                     _%$%tl2997830023%_))
                                                  (letrec ((_%$%loop2997930026%_
                                                            (lambda (_%$%hd2997730030%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                             _%$%bind2998330033%_)
                      (if (let ()
                            (declare (not safe))
                            (gx#stx-pair? _%$%hd2997730030%_))
                          (let ((_%$%e2998030035%_
                                 (let ()
                                   (declare (not safe))
                                   (gx#syntax-e _%$%hd2997730030%_))))
                            (let ((_%$%lp-hd2998130039%_
                                   (let ()
                                     (declare (not safe))
                                     (##car _%$%e2998030035%_)))
                                  (_%$%lp-tl2998230042%_
                                   (let ()
                                     (declare (not safe))
                                     (##cdr _%$%e2998030035%_))))
                              (_%$%loop2997930026%_
                               _%$%lp-tl2998230042%_
                               (cons _%$%lp-hd2998130039%_
                                     _%$%bind2998330033%_))))
                          (let ((_%$%bind2998430045%_
                                 (reverse _%$%bind2998330033%_)))
                            (if (let ()
                                  (declare (not safe))
                                  (gx#stx-pair? _%$%tl2997530017%_))
                                (let ((_%$%e2998530048%_
                                       (let ()
                                         (declare (not safe))
                                         (gx#syntax-e _%$%tl2997530017%_))))
                                  (let ((_%$%hd2998630052%_
                                         (let ()
                                           (declare (not safe))
                                           (##car _%$%e2998530048%_)))
                                        (_%$%tl2998730055%_
                                         (let ()
                                           (declare (not safe))
                                           (##cdr _%$%e2998530048%_))))
                                    (if (let ()
                                          (declare (not safe))
                                          (gx#stx-null? _%$%tl2998730055%_))
                                        (let ((_g200822_
                                               (_%make-dispatch29963%_
                                                (let ((__tmp200824
                                                       (lambda (_%$%g3008030083%_
                                                                _%$%g3008130086%_)
                                                         (cons _%$%g3008030083%_
                                                               _%$%g3008130086%_))))
                                                  (declare (not safe))
                                                  (foldr__0
                                                   __tmp200824
                                                   '()
                                                   _%$%bind2998430045%_))
                                                _%$%hd2998630052%_)))
                                          (begin
                                            (let ((_g200823_
                                                   (let ()
                                                     (declare (not safe))
                                                     (if (##values? _g200822_)
                                                         (##values-length
                                                          _g200822_)
                                                         1))))
                                              (if (not (let ()
                                                         (declare (not safe))
                                                         (##fx= _g200823_ 4)))
                                                  (error "Context expects 4 values"
                                                         _g200823_)))
                                            (let ((_%dispatch30089%_
                                                   (let ()
                                                     (declare (not safe))
                                                     (##values-ref
                                                      _g200822_
                                                      0)))
                                                  (_%it-exprs30091%_
                                                   (let ()
                                                     (declare (not safe))
                                                     (##values-ref
                                                      _g200822_
                                                      1)))
                                                  (_%iters30092%_
                                                   (let ()
                                                     (declare (not safe))
                                                     (##values-ref
                                                      _g200822_
                                                      2)))
                                                  (_%temps30093%_
                                                   (let ()
                                                     (declare (not safe))
                                                     (##values-ref
                                                      _g200822_
                                                      3))))
                                              (let* ((_%$%g3009530158%_
                                                      (lambda (_%$%g3009630154%_)
                                                        (let ()
                                                          (declare (not safe))
                                                          (gx#raise-syntax-error
                                                           '#f
                                                           '"Bad syntax; invalid match target"
                                                           _%$%g3009630154%_))))
                                                     (_%$%g3009430412%_
                                                      (lambda (_%$%g3009630162%_)
                                                        (if (let ()
                                                              (declare
                                                                (not safe))
                                                              (gx#stx-pair?
                                                               _%$%g3009630162%_))
                                                            (let ((_%$%e3010230165%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                           (let ()
                             (declare (not safe))
                             (gx#syntax-e _%$%g3009630162%_))))
                      (let ((_%$%hd3010330169%_
                             (let ()
                               (declare (not safe))
                               (##car _%$%e3010230165%_)))
                            (_%$%tl3010430172%_
                             (let ()
                               (declare (not safe))
                               (##cdr _%$%e3010230165%_))))
                        (if (let ()
                              (declare (not safe))
                              (gx#stx-pair? _%$%tl3010430172%_))
                            (let ((_%$%e3010530175%_
                                   (let ()
                                     (declare (not safe))
                                     (gx#syntax-e _%$%tl3010430172%_))))
                              (let ((_%$%hd3010630179%_
                                     (let ()
                                       (declare (not safe))
                                       (##car _%$%e3010530175%_)))
                                    (_%$%tl3010730182%_
                                     (let ()
                                       (declare (not safe))
                                       (##cdr _%$%e3010530175%_))))
                                (if (let ()
                                      (declare (not safe))
                                      (gx#stx-pair/null? _%$%hd3010630179%_))
                                    (let ((_g200825_
                                           (let ()
                                             (declare (not safe))
                                             (gx#syntax-split-splice
                                              _%$%hd3010630179%_
                                              '0))))
                                      (begin
                                        (let ((_g200826_
                                               (let ()
                                                 (declare (not safe))
                                                 (if (##values? _g200825_)
                                                     (##values-length
                                                      _g200825_)
                                                     1))))
                                          (if (not (let ()
                                                     (declare (not safe))
                                                     (##fx= _g200826_ 2)))
                                              (error "Context expects 2 values"
                                                     _g200826_)))
                                        (let ((_%$%target3010830185%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##values-ref _g200825_ 0)))
                                              (_%$%tl3011030188%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##values-ref _g200825_ 1))))
                                          (if (let ()
                                                (declare (not safe))
                                                (gx#stx-null?
                                                 _%$%tl3011030188%_))
                                              (letrec ((_%$%loop3011130191%_
                                                        (lambda (_%$%hd3010930195%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         _%$%it-expr3011530198%_)
                  (if (let ()
                        (declare (not safe))
                        (gx#stx-pair? _%$%hd3010930195%_))
                      (let ((_%$%e3011230200%_
                             (let ()
                               (declare (not safe))
                               (gx#syntax-e _%$%hd3010930195%_))))
                        (let ((_%$%lp-hd3011330204%_
                               (let ()
                                 (declare (not safe))
                                 (##car _%$%e3011230200%_)))
                              (_%$%lp-tl3011430207%_
                               (let ()
                                 (declare (not safe))
                                 (##cdr _%$%e3011230200%_))))
                          (_%$%loop3011130191%_
                           _%$%lp-tl3011430207%_
                           (cons _%$%lp-hd3011330204%_
                                 _%$%it-expr3011530198%_))))
                      (let ((_%$%it-expr3011630210%_
                             (reverse _%$%it-expr3011530198%_)))
                        (if (let ()
                              (declare (not safe))
                              (gx#stx-pair? _%$%tl3010730182%_))
                            (let ((_%$%e3011730213%_
                                   (let ()
                                     (declare (not safe))
                                     (gx#syntax-e _%$%tl3010730182%_))))
                              (let ((_%$%hd3011830217%_
                                     (let ()
                                       (declare (not safe))
                                       (##car _%$%e3011730213%_)))
                                    (_%$%tl3011930220%_
                                     (let ()
                                       (declare (not safe))
                                       (##cdr _%$%e3011730213%_))))
                                (if (let ()
                                      (declare (not safe))
                                      (gx#stx-pair/null? _%$%hd3011830217%_))
                                    (let ((_g200827_
                                           (let ()
                                             (declare (not safe))
                                             (gx#syntax-split-splice
                                              _%$%hd3011830217%_
                                              '0))))
                                      (begin
                                        (let ((_g200828_
                                               (let ()
                                                 (declare (not safe))
                                                 (if (##values? _g200827_)
                                                     (##values-length
                                                      _g200827_)
                                                     1))))
                                          (if (not (let ()
                                                     (declare (not safe))
                                                     (##fx= _g200828_ 2)))
                                              (error "Context expects 2 values"
                                                     _g200828_)))
                                        (let ((_%$%target3012030223%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##values-ref _g200827_ 0)))
                                              (_%$%tl3012230226%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##values-ref _g200827_ 1))))
                                          (if (let ()
                                                (declare (not safe))
                                                (gx#stx-null?
                                                 _%$%tl3012230226%_))
                                              (letrec ((_%$%loop3012330229%_
                                                        (lambda (_%$%hd3012130233%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         _%$%it3012730236%_)
                  (if (let ()
                        (declare (not safe))
                        (gx#stx-pair? _%$%hd3012130233%_))
                      (let ((_%$%e3012430238%_
                             (let ()
                               (declare (not safe))
                               (gx#syntax-e _%$%hd3012130233%_))))
                        (let ((_%$%lp-hd3012530242%_
                               (let ()
                                 (declare (not safe))
                                 (##car _%$%e3012430238%_)))
                              (_%$%lp-tl3012630245%_
                               (let ()
                                 (declare (not safe))
                                 (##cdr _%$%e3012430238%_))))
                          (_%$%loop3012330229%_
                           _%$%lp-tl3012630245%_
                           (cons _%$%lp-hd3012530242%_ _%$%it3012730236%_))))
                      (let ((_%$%it3012830248%_ (reverse _%$%it3012730236%_)))
                        (if (let ()
                              (declare (not safe))
                              (gx#stx-pair? _%$%tl3011930220%_))
                            (let ((_%$%e3012930251%_
                                   (let ()
                                     (declare (not safe))
                                     (gx#syntax-e _%$%tl3011930220%_))))
                              (let ((_%$%hd3013030255%_
                                     (let ()
                                       (declare (not safe))
                                       (##car _%$%e3012930251%_)))
                                    (_%$%tl3013130258%_
                                     (let ()
                                       (declare (not safe))
                                       (##cdr _%$%e3012930251%_))))
                                (if (let ()
                                      (declare (not safe))
                                      (gx#stx-pair/null? _%$%hd3013030255%_))
                                    (let ((_g200829_
                                           (let ()
                                             (declare (not safe))
                                             (gx#syntax-split-splice
                                              _%$%hd3013030255%_
                                              '0))))
                                      (begin
                                        (let ((_g200830_
                                               (let ()
                                                 (declare (not safe))
                                                 (if (##values? _g200829_)
                                                     (##values-length
                                                      _g200829_)
                                                     1))))
                                          (if (not (let ()
                                                     (declare (not safe))
                                                     (##fx= _g200830_ 2)))
                                              (error "Context expects 2 values"
                                                     _g200830_)))
                                        (let ((_%$%target3013230261%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##values-ref _g200829_ 0)))
                                              (_%$%tl3013430264%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##values-ref _g200829_ 1))))
                                          (if (let ()
                                                (declare (not safe))
                                                (gx#stx-null?
                                                 _%$%tl3013430264%_))
                                              (letrec ((_%$%loop3013530267%_
                                                        (lambda (_%$%hd3013330271%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         _%$%it.next!3013930274%_)
                  (if (let ()
                        (declare (not safe))
                        (gx#stx-pair? _%$%hd3013330271%_))
                      (let ((_%$%e3013630276%_
                             (let ()
                               (declare (not safe))
                               (gx#syntax-e _%$%hd3013330271%_))))
                        (let ((_%$%lp-hd3013730280%_
                               (let ()
                                 (declare (not safe))
                                 (##car _%$%e3013630276%_)))
                              (_%$%lp-tl3013830283%_
                               (let ()
                                 (declare (not safe))
                                 (##cdr _%$%e3013630276%_))))
                          (_%$%loop3013530267%_
                           _%$%lp-tl3013830283%_
                           (cons _%$%lp-hd3013730280%_
                                 _%$%it.next!3013930274%_))))
                      (let ((_%$%it.next!3014030286%_
                             (reverse _%$%it.next!3013930274%_)))
                        (if (let ()
                              (declare (not safe))
                              (gx#stx-pair? _%$%tl3013130258%_))
                            (let ((_%$%e3014130289%_
                                   (let ()
                                     (declare (not safe))
                                     (gx#syntax-e _%$%tl3013130258%_))))
                              (let ((_%$%hd3014230293%_
                                     (let ()
                                       (declare (not safe))
                                       (##car _%$%e3014130289%_)))
                                    (_%$%tl3014330296%_
                                     (let ()
                                       (declare (not safe))
                                       (##cdr _%$%e3014130289%_))))
                                (if (let ()
                                      (declare (not safe))
                                      (gx#stx-pair/null? _%$%hd3014230293%_))
                                    (let ((_g200831_
                                           (let ()
                                             (declare (not safe))
                                             (gx#syntax-split-splice
                                              _%$%hd3014230293%_
                                              '0))))
                                      (begin
                                        (let ((_g200832_
                                               (let ()
                                                 (declare (not safe))
                                                 (if (##values? _g200831_)
                                                     (##values-length
                                                      _g200831_)
                                                     1))))
                                          (if (not (let ()
                                                     (declare (not safe))
                                                     (##fx= _g200832_ 2)))
                                              (error "Context expects 2 values"
                                                     _g200832_)))
                                        (let ((_%$%target3014430299%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##values-ref _g200831_ 0)))
                                              (_%$%tl3014630302%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##values-ref _g200831_ 1))))
                                          (if (let ()
                                                (declare (not safe))
                                                (gx#stx-null?
                                                 _%$%tl3014630302%_))
                                              (letrec ((_%$%loop3014730305%_
                                                        (lambda (_%$%hd3014530309%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         _%$%next3015130312%_)
                  (if (let ()
                        (declare (not safe))
                        (gx#stx-pair? _%$%hd3014530309%_))
                      (let ((_%$%e3014830314%_
                             (let ()
                               (declare (not safe))
                               (gx#syntax-e _%$%hd3014530309%_))))
                        (let ((_%$%lp-hd3014930318%_
                               (let ()
                                 (declare (not safe))
                                 (##car _%$%e3014830314%_)))
                              (_%$%lp-tl3015030321%_
                               (let ()
                                 (declare (not safe))
                                 (##cdr _%$%e3014830314%_))))
                          (_%$%loop3014730305%_
                           _%$%lp-tl3015030321%_
                           (cons _%$%lp-hd3014930318%_ _%$%next3015130312%_))))
                      (let ((_%$%next3015230324%_
                             (reverse _%$%next3015130312%_)))
                        (if (let ()
                              (declare (not safe))
                              (gx#stx-null? _%$%tl3014330296%_))
                            (cons (let ()
                                    (declare (not safe))
                                    (gx#datum->syntax__0 '#f 'using))
                                  (cons (begin
                                          (let ()
                                            (declare (not safe))
                                            (gx#syntax-check-splice-targets
                                             _%$%it-expr3011630210%_
                                             _%$%it3012830248%_))
                                          (let ((__tmp200833
                                                 (lambda (_%$%g3037330384%_
                                                          _%$%g3037430387%_
                                                          _%$%g3037530389%_)
                                                   (cons (cons _%$%g3037430387%_
                                                               (cons (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                     (declare (not safe))
                                     (gx#datum->syntax__0 '#f 'iter))
                                   (cons _%$%g3037330384%_ '()))
                             (cons (let ()
                                     (declare (not safe))
                                     (gx#datum->syntax__0 '#f ':-))
                                   (cons (let ()
                                           (declare (not safe))
                                           (gx#datum->syntax__0 '#f 'Iterator))
                                         '()))))
                 _%$%g3037530389%_))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                            (declare (not safe))
                                            (foldr__1
                                             __tmp200833
                                             '()
                                             _%$%it-expr3011630210%_
                                             _%$%it3012830248%_)))
                                        (cons (cons (let ()
                                                      (declare (not safe))
                                                      (gx#datum->syntax__0
                                                       '#f
                                                       'let))
                                                    (cons (let ()
                                                            (declare
                                                              (not safe))
                                                            (gx#datum->syntax__0
                                                             '#f
                                                             'loop))
                                                          (cons '()
                                                                (cons (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                      (declare (not safe))
                                      (gx#datum->syntax__0 '#f 'let))
                                    (cons (begin
                                            (let ()
                                              (declare (not safe))
                                              (gx#syntax-check-splice-targets
                                               _%$%it.next!3014030286%_
                                               _%$%next3015230324%_))
                                            (let ((__tmp200834
                                                   (lambda (_%$%g3037630392%_
                                                            _%$%g3037730395%_
                                                            _%$%g3037830397%_)
                                                     (cons (cons _%$%g3037730395%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (cons (cons _%$%g3037630392%_ '()) '()))
                   _%$%g3037830397%_))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                              (declare (not safe))
                                              (foldr__1
                                               __tmp200834
                                               '()
                                               _%$%it.next!3014030286%_
                                               _%$%next3015230324%_)))
                                          (cons (cons (let ()
                                                        (declare (not safe))
                                                        (gx#datum->syntax__0
                                                         '#f
                                                         'unless))
                                                      (cons (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                            (declare (not safe))
                            (gx#datum->syntax__0 '#f 'or))
                          (let ((__tmp200835
                                 (lambda (_%$%g3037930400%_ _%$%g3038030403%_)
                                   (cons (cons (let ()
                                                 (declare (not safe))
                                                 (gx#datum->syntax__0
                                                  '#f
                                                  'eq?))
                                               (cons _%$%g3037930400%_
                                                     (cons '#!eof '())))
                                         _%$%g3038030403%_))))
                            (declare (not safe))
                            (foldr__0 __tmp200835 '() _%$%next3015230324%_)))
                    (cons (cons _%$%hd3010330169%_
                                (let ((__tmp200836
                                       (lambda (_%$%g3038130406%_
                                                _%$%g3038230409%_)
                                         (cons _%$%g3038130406%_
                                               _%$%g3038230409%_))))
                                  (declare (not safe))
                                  (foldr__0
                                   __tmp200836
                                   '()
                                   _%$%next3015230324%_)))
                          (cons (cons (let ()
                                        (declare (not safe))
                                        (gx#datum->syntax__0 '#f 'loop))
                                      '())
                                '()))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                '())))
                              '()))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                              '())))
                            (_%$%g3009530158%_ _%$%g3009630162%_)))))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                (_%$%loop3014730305%_
                                                 _%$%target3014430299%_
                                                 '()))
                                              (_%$%g3009530158%_
                                               _%$%g3009630162%_)))))
                                    (_%$%g3009530158%_ _%$%g3009630162%_))))
                            (_%$%g3009530158%_ _%$%g3009630162%_)))))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                (_%$%loop3013530267%_
                                                 _%$%target3013230261%_
                                                 '()))
                                              (_%$%g3009530158%_
                                               _%$%g3009630162%_)))))
                                    (_%$%g3009530158%_ _%$%g3009630162%_))))
                            (_%$%g3009530158%_ _%$%g3009630162%_)))))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                (_%$%loop3012330229%_
                                                 _%$%target3012030223%_
                                                 '()))
                                              (_%$%g3009530158%_
                                               _%$%g3009630162%_)))))
                                    (_%$%g3009530158%_ _%$%g3009630162%_))))
                            (_%$%g3009530158%_ _%$%g3009630162%_)))))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                (_%$%loop3011130191%_
                                                 _%$%target3010830185%_
                                                 '()))
                                              (_%$%g3009530158%_
                                               _%$%g3009630162%_)))))
                                    (_%$%g3009530158%_ _%$%g3009630162%_))))
                            (_%$%g3009530158%_ _%$%g3009630162%_))))
                    (_%$%g3009530158%_ _%$%g3009630162%_)))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                (_%$%g3009430412%_
                                                 (list _%dispatch30089%_
                                                       _%it-exprs30091%_
                                                       _%iters30092%_
                                                       (map (lambda (_%it30416%_)
                                                              (let ()
                                                                (declare
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                          (not safe))
                        (gx#stx-identifier _%it30416%_ _%it30416%_ '".next!")))
                    _%iters30092%_)
               _%temps30093%_))))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                        (_%$%g2996629993%_
                                         _%$%g2996729997%_))))
                                (_%$%g2996629993%_ _%$%g2996729997%_)))))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                    (_%$%loop2997930026%_
                                                     _%$%target2997630020%_
                                                     '()))
                                                  (_%$%g2996629993%_
                                                   _%$%g2996729997%_)))))
                                        (_%$%g2996629993%_
                                         _%$%g2996729997%_))))
                                (_%$%g2996629993%_ _%$%g2996729997%_))))
                        (_%$%g2996629993%_ _%$%g2996729997%_)))))
            (_%$%g2996530419%_ _%stx29960%_)))))
    (define |std/iter/macros[:0:]#for*|
      (lambda (_%stx31061%_)
        (let* ((_%__stx200440200441%_ _%stx31061%_)
               (_%$%g3106531130%_
                (lambda ()
                  (let ()
                    (declare (not safe))
                    (gx#raise-syntax-error
                     '#f
                     '"Bad syntax; invalid match target"
                     _%__stx200440200441%_)))))
          (let ((_%__kont200443200444%_
                 (lambda (_%$%g3106731372%_
                          _%$%g3106831374%_
                          _%$%g3106931375%_)
                   (cons (let ()
                           (declare (not safe))
                           (gx#datum->syntax__0 '#f 'for1))
                         (cons _%$%g3106931375%_
                               (cons (cons (let ()
                                             (declare (not safe))
                                             (gx#datum->syntax__0 '#f 'let))
                                           (cons '()
                                                 (cons _%$%g3106831374%_
                                                       (let ((__tmp200837
                                                              (lambda (_%$%g3139631399%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                               _%$%g3139731402%_)
                        (cons _%$%g3139631399%_ _%$%g3139731402%_))))
                 (declare (not safe))
                 (foldr__0 __tmp200837 '() _%$%g3106731372%_)))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                     '())))))
                (_%__kont200447200448%_
                 (lambda (_%$%g3109131233%_
                          _%$%g3109231235%_
                          _%$%g3109331236%_
                          _%$%g3109431237%_)
                   (if (null? (let ((__tmp200838
                                     (lambda (_%$%g3126431267%_
                                              _%$%g3126531270%_)
                                       (cons _%$%g3126431267%_
                                             _%$%g3126531270%_))))
                                (declare (not safe))
                                (foldr__0 __tmp200838 '() _%$%g3109331236%_)))
                       (cons (let ()
                               (declare (not safe))
                               (gx#datum->syntax__0 '#f 'for1))
                             (cons _%$%g3109431237%_
                                   (cons (cons (let ()
                                                 (declare (not safe))
                                                 (gx#datum->syntax__0
                                                  '#f
                                                  'let))
                                               (cons '()
                                                     (cons _%$%g3109231235%_
                                                           (let ((__tmp200839
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                          (lambda (_%$%g3127231275%_ _%$%g3127331278%_)
                            (cons _%$%g3127231275%_ _%$%g3127331278%_))))
                     (declare (not safe))
                     (foldr__0 __tmp200839 '() _%$%g3109131233%_)))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                         '())))
                       (cons (let ()
                               (declare (not safe))
                               (gx#datum->syntax__0 '#f 'for1))
                             (cons _%$%g3109431237%_
                                   (cons (cons (let ()
                                                 (declare (not safe))
                                                 (gx#datum->syntax__0
                                                  '#f
                                                  'for*))
                                               (cons (let ((__tmp200840
                                                            (lambda (_%$%g3128031285%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                             _%$%g3128131288%_)
                      (cons _%$%g3128031285%_ _%$%g3128131288%_))))
               (declare (not safe))
               (foldr__0 __tmp200840 '() _%$%g3109331236%_))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                     (cons _%$%g3109231235%_
                                                           (let ((__tmp200841
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                          (lambda (_%$%g3128231291%_ _%$%g3128331294%_)
                            (cons _%$%g3128231291%_ _%$%g3128331294%_))))
                     (declare (not safe))
                     (foldr__0 __tmp200841 '() _%$%g3109131233%_)))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                         '())))))))
            (let* ((_%__match200513200514%_
                    (lambda (_%$%e3109531137%_
                             _%$%hd3109631141%_
                             _%$%tl3109731144%_
                             _%$%e3109831147%_
                             _%$%hd3109931151%_
                             _%$%tl3110031154%_
                             _%$%e3110131157%_
                             _%$%hd3110231161%_
                             _%$%tl3110331164%_
                             _%__splice200449200450%_
                             _%$%target3110431167%_
                             _%$%tl3110631170%_)
                      (letrec ((_%$%loop3110731173%_
                                (lambda (_%$%hd3110531177%_
                                         _%$%bind-rest3111131180%_)
                                  (if (let ()
                                        (declare (not safe))
                                        (gx#stx-pair? _%$%hd3110531177%_))
                                      (let ((_%$%e3110831182%_
                                             (let ()
                                               (declare (not safe))
                                               (gx#syntax-e
                                                _%$%hd3110531177%_))))
                                        (let ((_%$%lp-tl3111031189%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##cdr _%$%e3110831182%_)))
                                              (_%$%lp-hd3110931186%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##car _%$%e3110831182%_))))
                                          (_%$%loop3110731173%_
                                           _%$%lp-tl3111031189%_
                                           (cons _%$%lp-hd3110931186%_
                                                 _%$%bind-rest3111131180%_))))
                                      (let ((_%$%bind-rest3111231192%_
                                             (reverse _%$%bind-rest3111131180%_)))
                                        (if (let ()
                                              (declare (not safe))
                                              (gx#stx-pair?
                                               _%$%tl3110031154%_))
                                            (let ((_%$%e3111331195%_
                                                   (let ()
                                                     (declare (not safe))
                                                     (gx#syntax-e
                                                      _%$%tl3110031154%_))))
                                              (let ((_%$%tl3111531202%_
                                                     (let ()
                                                       (declare (not safe))
                                                       (##cdr _%$%e3111331195%_)))
                                                    (_%$%hd3111431199%_
                                                     (let ()
                                                       (declare (not safe))
                                                       (##car _%$%e3111331195%_))))
                                                (if (let ()
                                                      (declare (not safe))
                                                      (gx#stx-pair/null?
                                                       _%$%tl3111531202%_))
                                                    (let ((_%__splice200451200452%_
                                                           (let ()
                                                             (declare
                                                               (not safe))
                                                             (gx#syntax-split-splice->vector
                                                              _%$%tl3111531202%_
                                                              '0))))
                                                      (let ((_%$%tl3111831208%_
                                                             (let ()
                                                               (declare
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (not safe))
                       (##vector-ref _%__splice200451200452%_ '1)))
                    (_%$%target3111631205%_
                     (let ()
                       (declare (not safe))
                       (##vector-ref _%__splice200451200452%_ '0))))
                (if (let ()
                      (declare (not safe))
                      (gx#stx-null? _%$%tl3111831208%_))
                    (letrec ((_%$%loop3111931211%_
                              (lambda (_%$%hd3111731215%_ _%$%rest3112331218%_)
                                (if (let ()
                                      (declare (not safe))
                                      (gx#stx-pair? _%$%hd3111731215%_))
                                    (let ((_%$%e3112031220%_
                                           (let ()
                                             (declare (not safe))
                                             (gx#syntax-e
                                              _%$%hd3111731215%_))))
                                      (let ((_%$%lp-tl3112231227%_
                                             (let ()
                                               (declare (not safe))
                                               (##cdr _%$%e3112031220%_)))
                                            (_%$%lp-hd3112131224%_
                                             (let ()
                                               (declare (not safe))
                                               (##car _%$%e3112031220%_))))
                                        (_%$%loop3111931211%_
                                         _%$%lp-tl3112231227%_
                                         (cons _%$%lp-hd3112131224%_
                                               _%$%rest3112331218%_))))
                                    (let ((_%$%rest3112431230%_
                                           (reverse _%$%rest3112331218%_)))
                                      (let ((_%$%g3109131233%_
                                             _%$%rest3112431230%_)
                                            (_%$%g3109231235%_
                                             _%$%hd3111431199%_)
                                            (_%$%g3109331236%_
                                             _%$%bind-rest3111231192%_)
                                            (_%$%g3109431237%_
                                             _%$%hd3110231161%_))
                                        (if (|std/iter/macros[1]#for-binding?|
                                             _%$%g3109431237%_)
                                            (_%__kont200447200448%_
                                             _%$%g3109131233%_
                                             _%$%g3109231235%_
                                             _%$%g3109331236%_
                                             _%$%g3109431237%_)
                                            (let ()
                                              (declare (not safe))
                                              (_%$%g3106531130%_)))))))))
                      (_%$%loop3111931211%_ _%$%target3111631205%_ '()))
                    (let () (declare (not safe)) (_%$%g3106531130%_)))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                    (let ()
                                                      (declare (not safe))
                                                      (_%$%g3106531130%_)))))
                                            (let ()
                                              (declare (not safe))
                                              (_%$%g3106531130%_))))))))
                        (_%$%loop3110731173%_ _%$%target3110431167%_ '()))))
                   (_%__match200505200506%_
                    (lambda (_%$%e3109531137%_
                             _%$%hd3109631141%_
                             _%$%tl3109731144%_
                             _%$%e3109831147%_
                             _%$%hd3109931151%_
                             _%$%tl3110031154%_
                             _%$%e3110131157%_
                             _%$%hd3110231161%_
                             _%$%tl3110331164%_)
                      (if (let ()
                            (declare (not safe))
                            (gx#stx-pair/null? _%$%tl3110331164%_))
                          (let ((_%__splice200449200450%_
                                 (let ()
                                   (declare (not safe))
                                   (gx#syntax-split-splice->vector
                                    _%$%tl3110331164%_
                                    '0))))
                            (let ((_%$%tl3110631170%_
                                   (let ()
                                     (declare (not safe))
                                     (##vector-ref
                                      _%__splice200449200450%_
                                      '1)))
                                  (_%$%target3110431167%_
                                   (let ()
                                     (declare (not safe))
                                     (##vector-ref
                                      _%__splice200449200450%_
                                      '0))))
                              (if (let ()
                                    (declare (not safe))
                                    (gx#stx-null? _%$%tl3110631170%_))
                                  (_%__match200513200514%_
                                   _%$%e3109531137%_
                                   _%$%hd3109631141%_
                                   _%$%tl3109731144%_
                                   _%$%e3109831147%_
                                   _%$%hd3109931151%_
                                   _%$%tl3110031154%_
                                   _%$%e3110131157%_
                                   _%$%hd3110231161%_
                                   _%$%tl3110331164%_
                                   _%__splice200449200450%_
                                   _%$%target3110431167%_
                                   _%$%tl3110631170%_)
                                  (let ()
                                    (declare (not safe))
                                    (_%$%g3106531130%_)))))
                          (let () (declare (not safe)) (_%$%g3106531130%_)))))
                   (_%__match200487200488%_
                    (lambda (_%$%e3107031304%_
                             _%$%hd3107131308%_
                             _%$%tl3107231311%_
                             _%$%e3107331314%_
                             _%$%hd3107431318%_
                             _%$%tl3107531321%_
                             _%$%e3107631324%_
                             _%$%hd3107731328%_
                             _%$%tl3107831331%_
                             _%$%e3107931334%_
                             _%$%hd3108031338%_
                             _%$%tl3108131341%_
                             _%__splice200445200446%_
                             _%$%target3108231344%_
                             _%$%tl3108431347%_)
                      (letrec ((_%$%loop3108531350%_
                                (lambda (_%$%hd3108331354%_
                                         _%$%rest3108931357%_)
                                  (if (let ()
                                        (declare (not safe))
                                        (gx#stx-pair? _%$%hd3108331354%_))
                                      (let ((_%$%e3108631359%_
                                             (let ()
                                               (declare (not safe))
                                               (gx#syntax-e
                                                _%$%hd3108331354%_))))
                                        (let ((_%$%lp-tl3108831366%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##cdr _%$%e3108631359%_)))
                                              (_%$%lp-hd3108731363%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##car _%$%e3108631359%_))))
                                          (_%$%loop3108531350%_
                                           _%$%lp-tl3108831366%_
                                           (cons _%$%lp-hd3108731363%_
                                                 _%$%rest3108931357%_))))
                                      (let ((_%$%rest3109031369%_
                                             (reverse _%$%rest3108931357%_)))
                                        (let ((_%$%g3106731372%_
                                               _%$%rest3109031369%_)
                                              (_%$%g3106831374%_
                                               _%$%hd3108031338%_)
                                              (_%$%g3106931375%_
                                               _%$%hd3107731328%_))
                                          (if (|std/iter/macros[1]#for-binding?|
                                               _%$%g3106931375%_)
                                              (_%__kont200443200444%_
                                               _%$%g3106731372%_
                                               _%$%g3106831374%_
                                               _%$%g3106931375%_)
                                              (_%__match200505200506%_
                                               _%$%e3107031304%_
                                               _%$%hd3107131308%_
                                               _%$%tl3107231311%_
                                               _%$%e3107331314%_
                                               _%$%hd3107431318%_
                                               _%$%tl3107531321%_
                                               _%$%e3107631324%_
                                               _%$%hd3107731328%_
                                               _%$%tl3107831331%_))))))))
                        (_%$%loop3108531350%_ _%$%target3108231344%_ '())))))
              (if (let ()
                    (declare (not safe))
                    (gx#stx-pair? _%__stx200440200441%_))
                  (let ((_%$%e3107031304%_
                         (let ()
                           (declare (not safe))
                           (gx#syntax-e _%__stx200440200441%_))))
                    (let ((_%$%tl3107231311%_
                           (let ()
                             (declare (not safe))
                             (##cdr _%$%e3107031304%_)))
                          (_%$%hd3107131308%_
                           (let ()
                             (declare (not safe))
                             (##car _%$%e3107031304%_))))
                      (if (let ()
                            (declare (not safe))
                            (gx#stx-pair? _%$%tl3107231311%_))
                          (let ((_%$%e3107331314%_
                                 (let ()
                                   (declare (not safe))
                                   (gx#syntax-e _%$%tl3107231311%_))))
                            (let ((_%$%tl3107531321%_
                                   (let ()
                                     (declare (not safe))
                                     (##cdr _%$%e3107331314%_)))
                                  (_%$%hd3107431318%_
                                   (let ()
                                     (declare (not safe))
                                     (##car _%$%e3107331314%_))))
                              (if (let ()
                                    (declare (not safe))
                                    (gx#stx-pair? _%$%hd3107431318%_))
                                  (let ((_%$%e3107631324%_
                                         (let ()
                                           (declare (not safe))
                                           (gx#syntax-e _%$%hd3107431318%_))))
                                    (let ((_%$%tl3107831331%_
                                           (let ()
                                             (declare (not safe))
                                             (##cdr _%$%e3107631324%_)))
                                          (_%$%hd3107731328%_
                                           (let ()
                                             (declare (not safe))
                                             (##car _%$%e3107631324%_))))
                                      (if (let ()
                                            (declare (not safe))
                                            (gx#stx-null? _%$%tl3107831331%_))
                                          (if (let ()
                                                (declare (not safe))
                                                (gx#stx-pair?
                                                 _%$%tl3107531321%_))
                                              (let ((_%$%e3107931334%_
                                                     (let ()
                                                       (declare (not safe))
                                                       (gx#syntax-e
                                                        _%$%tl3107531321%_))))
                                                (let ((_%$%tl3108131341%_
                                                       (let ()
                                                         (declare (not safe))
                                                         (##cdr _%$%e3107931334%_)))
                                                      (_%$%hd3108031338%_
                                                       (let ()
                                                         (declare (not safe))
                                                         (##car _%$%e3107931334%_))))
                                                  (if (let ()
                                                        (declare (not safe))
                                                        (gx#stx-pair/null?
                                                         _%$%tl3108131341%_))
                                                      (let ((_%__splice200445200446%_
                                                             (let ()
                                                               (declare
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (not safe))
                       (gx#syntax-split-splice->vector
                        _%$%tl3108131341%_
                        '0))))
                (let ((_%$%tl3108431347%_
                       (let ()
                         (declare (not safe))
                         (##vector-ref _%__splice200445200446%_ '1)))
                      (_%$%target3108231344%_
                       (let ()
                         (declare (not safe))
                         (##vector-ref _%__splice200445200446%_ '0))))
                  (if (let ()
                        (declare (not safe))
                        (gx#stx-null? _%$%tl3108431347%_))
                      (_%__match200487200488%_
                       _%$%e3107031304%_
                       _%$%hd3107131308%_
                       _%$%tl3107231311%_
                       _%$%e3107331314%_
                       _%$%hd3107431318%_
                       _%$%tl3107531321%_
                       _%$%e3107631324%_
                       _%$%hd3107731328%_
                       _%$%tl3107831331%_
                       _%$%e3107931334%_
                       _%$%hd3108031338%_
                       _%$%tl3108131341%_
                       _%__splice200445200446%_
                       _%$%target3108231344%_
                       _%$%tl3108431347%_)
                      (if (let ()
                            (declare (not safe))
                            (gx#stx-pair/null? _%$%tl3107831331%_))
                          (let ((_%__splice200449200450%_
                                 (let ()
                                   (declare (not safe))
                                   (gx#syntax-split-splice->vector
                                    _%$%tl3107831331%_
                                    '0))))
                            (let ((_%$%tl3110631170%_
                                   (let ()
                                     (declare (not safe))
                                     (##vector-ref
                                      _%__splice200449200450%_
                                      '1)))
                                  (_%$%target3110431167%_
                                   (let ()
                                     (declare (not safe))
                                     (##vector-ref
                                      _%__splice200449200450%_
                                      '0))))
                              (if (let ()
                                    (declare (not safe))
                                    (gx#stx-null? _%$%tl3110631170%_))
                                  (_%__match200513200514%_
                                   _%$%e3107031304%_
                                   _%$%hd3107131308%_
                                   _%$%tl3107231311%_
                                   _%$%e3107331314%_
                                   _%$%hd3107431318%_
                                   _%$%tl3107531321%_
                                   _%$%e3107631324%_
                                   _%$%hd3107731328%_
                                   _%$%tl3107831331%_
                                   _%__splice200449200450%_
                                   _%$%target3110431167%_
                                   _%$%tl3110631170%_)
                                  (let ()
                                    (declare (not safe))
                                    (_%$%g3106531130%_)))))
                          (let () (declare (not safe)) (_%$%g3106531130%_))))))
              (if (let ()
                    (declare (not safe))
                    (gx#stx-pair/null? _%$%tl3107831331%_))
                  (let ((_%__splice200449200450%_
                         (let ()
                           (declare (not safe))
                           (gx#syntax-split-splice->vector
                            _%$%tl3107831331%_
                            '0))))
                    (let ((_%$%tl3110631170%_
                           (let ()
                             (declare (not safe))
                             (##vector-ref _%__splice200449200450%_ '1)))
                          (_%$%target3110431167%_
                           (let ()
                             (declare (not safe))
                             (##vector-ref _%__splice200449200450%_ '0))))
                      (if (let ()
                            (declare (not safe))
                            (gx#stx-null? _%$%tl3110631170%_))
                          (_%__match200513200514%_
                           _%$%e3107031304%_
                           _%$%hd3107131308%_
                           _%$%tl3107231311%_
                           _%$%e3107331314%_
                           _%$%hd3107431318%_
                           _%$%tl3107531321%_
                           _%$%e3107631324%_
                           _%$%hd3107731328%_
                           _%$%tl3107831331%_
                           _%__splice200449200450%_
                           _%$%target3110431167%_
                           _%$%tl3110631170%_)
                          (let () (declare (not safe)) (_%$%g3106531130%_)))))
                  (let () (declare (not safe)) (_%$%g3106531130%_))))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                              (if (let ()
                                                    (declare (not safe))
                                                    (gx#stx-pair/null?
                                                     _%$%tl3107831331%_))
                                                  (let ((_%__splice200449200450%_
                                                         (let ()
                                                           (declare (not safe))
                                                           (gx#syntax-split-splice->vector
                                                            _%$%tl3107831331%_
                                                            '0))))
                                                    (let ((_%$%tl3110631170%_
                                                           (let ()
                                                             (declare
                                                               (not safe))
                                                             (##vector-ref
                                                              _%__splice200449200450%_
                                                              '1)))
                                                          (_%$%target3110431167%_
                                                           (let ()
                                                             (declare
                                                               (not safe))
                                                             (##vector-ref
                                                              _%__splice200449200450%_
                                                              '0))))
                                                      (if (let ()
                                                            (declare
                                                              (not safe))
                                                            (gx#stx-null?
                                                             _%$%tl3110631170%_))
                                                          (_%__match200513200514%_
                                                           _%$%e3107031304%_
                                                           _%$%hd3107131308%_
                                                           _%$%tl3107231311%_
                                                           _%$%e3107331314%_
                                                           _%$%hd3107431318%_
                                                           _%$%tl3107531321%_
                                                           _%$%e3107631324%_
                                                           _%$%hd3107731328%_
                                                           _%$%tl3107831331%_
                                                           _%__splice200449200450%_
                                                           _%$%target3110431167%_
                                                           _%$%tl3110631170%_)
                                                          (let ()
                                                            (declare
                                                              (not safe))
                                                            (_%$%g3106531130%_)))))
                                                  (let ()
                                                    (declare (not safe))
                                                    (_%$%g3106531130%_))))
                                          (if (let ()
                                                (declare (not safe))
                                                (gx#stx-pair/null?
                                                 _%$%tl3107831331%_))
                                              (let ((_%__splice200449200450%_
                                                     (let ()
                                                       (declare (not safe))
                                                       (gx#syntax-split-splice->vector
                                                        _%$%tl3107831331%_
                                                        '0))))
                                                (let ((_%$%tl3110631170%_
                                                       (let ()
                                                         (declare (not safe))
                                                         (##vector-ref
                                                          _%__splice200449200450%_
                                                          '1)))
                                                      (_%$%target3110431167%_
                                                       (let ()
                                                         (declare (not safe))
                                                         (##vector-ref
                                                          _%__splice200449200450%_
                                                          '0))))
                                                  (if (let ()
                                                        (declare (not safe))
                                                        (gx#stx-null?
                                                         _%$%tl3110631170%_))
                                                      (_%__match200513200514%_
                                                       _%$%e3107031304%_
                                                       _%$%hd3107131308%_
                                                       _%$%tl3107231311%_
                                                       _%$%e3107331314%_
                                                       _%$%hd3107431318%_
                                                       _%$%tl3107531321%_
                                                       _%$%e3107631324%_
                                                       _%$%hd3107731328%_
                                                       _%$%tl3107831331%_
                                                       _%__splice200449200450%_
                                                       _%$%target3110431167%_
                                                       _%$%tl3110631170%_)
                                                      (let ()
                                                        (declare (not safe))
                                                        (_%$%g3106531130%_)))))
                                              (let ()
                                                (declare (not safe))
                                                (_%$%g3106531130%_))))))
                                  (let ()
                                    (declare (not safe))
                                    (_%$%g3106531130%_)))))
                          (let () (declare (not safe)) (_%$%g3106531130%_)))))
                  (let () (declare (not safe)) (_%$%g3106531130%_))))))))
    (define |std/iter/macros[:0:]#for/collect|
      (lambda (_%$stx31412%_)
        (let* ((_%$%g3141631444%_
                (lambda (_%$%g3141731440%_)
                  (let ()
                    (declare (not safe))
                    (gx#raise-syntax-error
                     '#f
                     '"Bad syntax; invalid match target"
                     _%$%g3141731440%_))))
               (_%$%g3141531541%_
                (lambda (_%$%g3141731448%_)
                  (if (let ()
                        (declare (not safe))
                        (gx#stx-pair? _%$%g3141731448%_))
                      (let ((_%$%e3142131451%_
                             (let ()
                               (declare (not safe))
                               (gx#syntax-e _%$%g3141731448%_))))
                        (let ((_%$%hd3142231455%_
                               (let ()
                                 (declare (not safe))
                                 (##car _%$%e3142131451%_)))
                              (_%$%tl3142331458%_
                               (let ()
                                 (declare (not safe))
                                 (##cdr _%$%e3142131451%_))))
                          (if (let ()
                                (declare (not safe))
                                (gx#stx-pair? _%$%tl3142331458%_))
                              (let ((_%$%e3142431461%_
                                     (let ()
                                       (declare (not safe))
                                       (gx#syntax-e _%$%tl3142331458%_))))
                                (let ((_%$%hd3142531465%_
                                       (let ()
                                         (declare (not safe))
                                         (##car _%$%e3142431461%_)))
                                      (_%$%tl3142631468%_
                                       (let ()
                                         (declare (not safe))
                                         (##cdr _%$%e3142431461%_))))
                                  (if (let ()
                                        (declare (not safe))
                                        (gx#stx-pair? _%$%tl3142631468%_))
                                      (let ((_%$%e3142731471%_
                                             (let ()
                                               (declare (not safe))
                                               (gx#syntax-e
                                                _%$%tl3142631468%_))))
                                        (let ((_%$%hd3142831475%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##car _%$%e3142731471%_)))
                                              (_%$%tl3142931478%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##cdr _%$%e3142731471%_))))
                                          (if (let ()
                                                (declare (not safe))
                                                (gx#stx-pair/null?
                                                 _%$%tl3142931478%_))
                                              (let ((_g200842_
                                                     (let ()
                                                       (declare (not safe))
                                                       (gx#syntax-split-splice
                                                        _%$%tl3142931478%_
                                                        '0))))
                                                (begin
                                                  (let ((_g200843_
                                                         (let ()
                                                           (declare (not safe))
                                                           (if (##values?
                                                                _g200842_)
                                                               (##values-length
                                                                _g200842_)
                                                               1))))
                                                    (if (not (let ()
                                                               (declare
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (not safe))
                       (##fx= _g200843_ 2)))
                (error "Context expects 2 values" _g200843_)))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                  (let ((_%$%target3143031481%_
                                                         (let ()
                                                           (declare (not safe))
                                                           (##values-ref
                                                            _g200842_
                                                            0)))
                                                        (_%$%tl3143231484%_
                                                         (let ()
                                                           (declare (not safe))
                                                           (##values-ref
                                                            _g200842_
                                                            1))))
                                                    (if (let ()
                                                          (declare (not safe))
                                                          (gx#stx-null?
                                                           _%$%tl3143231484%_))
                                                        (letrec ((_%$%loop3143331487%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                          (lambda (_%$%hd3143131491%_ _%$%rest3143731494%_)
                            (if (let ()
                                  (declare (not safe))
                                  (gx#stx-pair? _%$%hd3143131491%_))
                                (let ((_%$%e3143431496%_
                                       (let ()
                                         (declare (not safe))
                                         (gx#syntax-e _%$%hd3143131491%_))))
                                  (let ((_%$%lp-hd3143531500%_
                                         (let ()
                                           (declare (not safe))
                                           (##car _%$%e3143431496%_)))
                                        (_%$%lp-tl3143631503%_
                                         (let ()
                                           (declare (not safe))
                                           (##cdr _%$%e3143431496%_))))
                                    (_%$%loop3143331487%_
                                     _%$%lp-tl3143631503%_
                                     (cons _%$%lp-hd3143531500%_
                                           _%$%rest3143731494%_))))
                                (let ((_%$%rest3143831506%_
                                       (reverse _%$%rest3143731494%_)))
                                  (cons (let ()
                                          (declare (not safe))
                                          (gx#datum->syntax__0
                                           '#f
                                           'with-list-builder))
                                        (cons (cons (let ()
                                                      (declare (not safe))
                                                      (gx#datum->syntax__0
                                                       '#f
                                                       'poke))
                                                    '())
                                              (cons (cons (let ()
                                                            (declare
                                                              (not safe))
                                                            (gx#datum->syntax__0
                                                             '#f
                                                             'for))
                                                          (cons _%$%hd3142531465%_
                                                                (cons (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                      (declare (not safe))
                                      (gx#datum->syntax__0 '#f 'let))
                                    (cons (cons (let ()
                                                  (declare (not safe))
                                                  (gx#datum->syntax__0
                                                   '#f
                                                   'next))
                                                (cons (cons (let ()
                                                              (declare
                                                                (not safe))
                                                              (gx#datum->syntax__0
                                                               '#f
                                                               'let))
                                                            (cons '()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                          (cons _%$%hd3142831475%_
                                (let ((__tmp200844
                                       (lambda (_%$%g3153231535%_
                                                _%$%g3153331538%_)
                                         (cons _%$%g3153231535%_
                                               _%$%g3153331538%_))))
                                  (declare (not safe))
                                  (foldr__0
                                   __tmp200844
                                   '()
                                   _%$%rest3143831506%_)))))
              '()))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                          (cons (cons (let ()
                                                        (declare (not safe))
                                                        (gx#datum->syntax__0
                                                         '#f
                                                         'unless))
                                                      (cons (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                            (declare (not safe))
                            (gx#datum->syntax__0 '#f 'eq?))
                          (cons (let ()
                                  (declare (not safe))
                                  (gx#datum->syntax__0 '#f 'next))
                                (cons '#!void '())))
                    (cons (cons (let ()
                                  (declare (not safe))
                                  (gx#datum->syntax__0 '#f 'poke))
                                (cons (let ()
                                        (declare (not safe))
                                        (gx#datum->syntax__0 '#f 'next))
                                      '()))
                          '())))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                '())))
                              '())))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                    '()))))))))
                  (_%$%loop3143331487%_ _%$%target3143031481%_ '()))
                (_%$%g3141631444%_ _%$%g3141731448%_)))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                              (_%$%g3141631444%_
                                               _%$%g3141731448%_))))
                                      (_%$%g3141631444%_ _%$%g3141731448%_))))
                              (_%$%g3141631444%_ _%$%g3141731448%_))))
                      (_%$%g3141631444%_ _%$%g3141731448%_)))))
          (_%$%g3141531541%_ _%$stx31412%_))))
    (define |std/iter/macros[:0:]#for/fold|
      (lambda (_%$stx31546%_)
        (let* ((_%$%g3155031589%_
                (lambda (_%$%g3155131585%_)
                  (let ()
                    (declare (not safe))
                    (gx#raise-syntax-error
                     '#f
                     '"Bad syntax; invalid match target"
                     _%$%g3155131585%_))))
               (_%$%g3154931726%_
                (lambda (_%$%g3155131593%_)
                  (if (let ()
                        (declare (not safe))
                        (gx#stx-pair? _%$%g3155131593%_))
                      (let ((_%$%e3155731596%_
                             (let ()
                               (declare (not safe))
                               (gx#syntax-e _%$%g3155131593%_))))
                        (let ((_%$%hd3155831600%_
                               (let ()
                                 (declare (not safe))
                                 (##car _%$%e3155731596%_)))
                              (_%$%tl3155931603%_
                               (let ()
                                 (declare (not safe))
                                 (##cdr _%$%e3155731596%_))))
                          (if (let ()
                                (declare (not safe))
                                (gx#stx-pair? _%$%tl3155931603%_))
                              (let ((_%$%e3156031606%_
                                     (let ()
                                       (declare (not safe))
                                       (gx#syntax-e _%$%tl3155931603%_))))
                                (let ((_%$%hd3156131610%_
                                       (let ()
                                         (declare (not safe))
                                         (##car _%$%e3156031606%_)))
                                      (_%$%tl3156231613%_
                                       (let ()
                                         (declare (not safe))
                                         (##cdr _%$%e3156031606%_))))
                                  (if (let ()
                                        (declare (not safe))
                                        (gx#stx-pair? _%$%hd3156131610%_))
                                      (let ((_%$%e3156331616%_
                                             (let ()
                                               (declare (not safe))
                                               (gx#syntax-e
                                                _%$%hd3156131610%_))))
                                        (let ((_%$%hd3156431620%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##car _%$%e3156331616%_)))
                                              (_%$%tl3156531623%_
                                               (let ()
                                                 (declare (not safe))
                                                 (##cdr _%$%e3156331616%_))))
                                          (if (let ()
                                                (declare (not safe))
                                                (gx#stx-pair?
                                                 _%$%tl3156531623%_))
                                              (let ((_%$%e3156631626%_
                                                     (let ()
                                                       (declare (not safe))
                                                       (gx#syntax-e
                                                        _%$%tl3156531623%_))))
                                                (let ((_%$%hd3156731630%_
                                                       (let ()
                                                         (declare (not safe))
                                                         (##car _%$%e3156631626%_)))
                                                      (_%$%tl3156831633%_
                                                       (let ()
                                                         (declare (not safe))
                                                         (##cdr _%$%e3156631626%_))))
                                                  (if (let ()
                                                        (declare (not safe))
                                                        (gx#stx-null?
                                                         _%$%tl3156831633%_))
                                                      (if (let ()
                                                            (declare
                                                              (not safe))
                                                            (gx#stx-pair?
                                                             _%$%tl3156231613%_))
                                                          (let ((_%$%e3156931636%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (let ()
                           (declare (not safe))
                           (gx#syntax-e _%$%tl3156231613%_))))
                    (let ((_%$%hd3157031640%_
                           (let ()
                             (declare (not safe))
                             (##car _%$%e3156931636%_)))
                          (_%$%tl3157131643%_
                           (let ()
                             (declare (not safe))
                             (##cdr _%$%e3156931636%_))))
                      (if (let ()
                            (declare (not safe))
                            (gx#stx-pair? _%$%tl3157131643%_))
                          (let ((_%$%e3157231646%_
                                 (let ()
                                   (declare (not safe))
                                   (gx#syntax-e _%$%tl3157131643%_))))
                            (let ((_%$%hd3157331650%_
                                   (let ()
                                     (declare (not safe))
                                     (##car _%$%e3157231646%_)))
                                  (_%$%tl3157431653%_
                                   (let ()
                                     (declare (not safe))
                                     (##cdr _%$%e3157231646%_))))
                              (if (let ()
                                    (declare (not safe))
                                    (gx#stx-pair/null? _%$%tl3157431653%_))
                                  (let ((_g200845_
                                         (let ()
                                           (declare (not safe))
                                           (gx#syntax-split-splice
                                            _%$%tl3157431653%_
                                            '0))))
                                    (begin
                                      (let ((_g200846_
                                             (let ()
                                               (declare (not safe))
                                               (if (##values? _g200845_)
                                                   (##values-length _g200845_)
                                                   1))))
                                        (if (not (let ()
                                                   (declare (not safe))
                                                   (##fx= _g200846_ 2)))
                                            (error "Context expects 2 values"
                                                   _g200846_)))
                                      (let ((_%$%target3157531656%_
                                             (let ()
                                               (declare (not safe))
                                               (##values-ref _g200845_ 0)))
                                            (_%$%tl3157731659%_
                                             (let ()
                                               (declare (not safe))
                                               (##values-ref _g200845_ 1))))
                                        (if (let ()
                                              (declare (not safe))
                                              (gx#stx-null?
                                               _%$%tl3157731659%_))
                                            (letrec ((_%$%loop3157831662%_
                                                      (lambda (_%$%hd3157631666%_
                                                               _%$%rest3158231669%_)
                                                        (if (let ()
                                                              (declare
                                                                (not safe))
                                                              (gx#stx-pair?
                                                               _%$%hd3157631666%_))
                                                            (let ((_%$%e3157931671%_
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                           (let ()
                             (declare (not safe))
                             (gx#syntax-e _%$%hd3157631666%_))))
                      (let ((_%$%lp-hd3158031675%_
                             (let ()
                               (declare (not safe))
                               (##car _%$%e3157931671%_)))
                            (_%$%lp-tl3158131678%_
                             (let ()
                               (declare (not safe))
                               (##cdr _%$%e3157931671%_))))
                        (_%$%loop3157831662%_
                         _%$%lp-tl3158131678%_
                         (cons _%$%lp-hd3158031675%_ _%$%rest3158231669%_))))
                    (let ((_%$%rest3158331681%_
                           (reverse _%$%rest3158231669%_)))
                      (if (let ()
                            (declare (not safe))
                            (gx#identifier? _%$%hd3156431620%_))
                          (cons (let ()
                                  (declare (not safe))
                                  (gx#datum->syntax__0 '#f 'let))
                                (cons (cons _%$%hd3156431620%_
                                            (cons _%$%hd3156731630%_ '()))
                                      (cons (cons (let ()
                                                    (declare (not safe))
                                                    (gx#datum->syntax__0
                                                     '#f
                                                     'for))
                                                  (cons _%$%hd3157031640%_
                                                        (cons (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                              (declare (not safe))
                              (gx#datum->syntax__0 '#f 'let))
                            (cons (cons (let ()
                                          (declare (not safe))
                                          (gx#datum->syntax__0 '#f 'next))
                                        (cons (cons (let ()
                                                      (declare (not safe))
                                                      (gx#datum->syntax__0
                                                       '#f
                                                       'begin))
                                                    (cons _%$%hd3157331650%_
                                                          (let ((__tmp200847
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                         (lambda (_%$%g3171731720%_ _%$%g3171831723%_)
                           (cons _%$%g3171731720%_ _%$%g3171831723%_))))
                    (declare (not safe))
                    (foldr__0 __tmp200847 '() _%$%rest3158331681%_))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                              '()))
                                  (cons (cons (let ()
                                                (declare (not safe))
                                                (gx#datum->syntax__0
                                                 '#f
                                                 'unless))
                                              (cons (cons (let ()
                                                            (declare
                                                              (not safe))
                                                            (gx#datum->syntax__0
                                                             '#f
                                                             'eq?))
                                                          (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                          (declare (not safe))
                          (gx#datum->syntax__0 '#f 'next))
                        (cons '#!void '())))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                                    (cons (cons (let ()
;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                          (declare (not safe))
                          (gx#datum->syntax__0 '#f 'set!))
                        (cons _%$%hd3156431620%_
                              (cons (let ()
                                      (declare (not safe))
                                      (gx#datum->syntax__0 '#f 'next))
                                    '())))
                  '())))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                        '())))
                      '())))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                            (cons _%$%hd3156431620%_ '()))))
                          (_%$%g3155031589%_ _%$%g3155131593%_)))))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                              (_%$%loop3157831662%_
                                               _%$%target3157531656%_
                                               '()))
                                            (_%$%g3155031589%_
                                             _%$%g3155131593%_)))))
                                  (_%$%g3155031589%_ _%$%g3155131593%_))))
                          (_%$%g3155031589%_ _%$%g3155131593%_))))
                  (_%$%g3155031589%_ _%$%g3155131593%_))
              (_%$%g3155031589%_ _%$%g3155131593%_))))
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                              (_%$%g3155031589%_
                                               _%$%g3155131593%_))))
                                      (_%$%g3155031589%_ _%$%g3155131593%_))))
                              (_%$%g3155031589%_ _%$%g3155131593%_))))
                      (_%$%g3155031589%_ _%$%g3155131593%_)))))
          (_%$%g3154931726%_ _%$stx31546%_))))))
