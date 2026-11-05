module will_classification_cut {
 type State={managed:bool,strongLive:bool,live:bool,da:bool,db:bool,ea:bool,eb:bool,cut:bool,finished:bool}
 pure val initial:State={managed:true,strongLive:false,live:false,da:false,db:false,ea:false,eb:false,cut:false,finished:false}
 var s:State
 action init=s'=initial
 action initLegacy=s'={...initial,managed:false}
 val safe=s.managed implies all{
 s.da implies (s.ea==not(s.strongLive)),
 s.db implies (s.eb==not(s.strongLive)),
 s.cut implies (s.da and s.db),
 (s.live and not(s.strongLive)) implies s.cut,
 s.finished implies (s.cut and s.live),
 (s.da and s.db) implies (s.ea==s.eb)}
 action strongReachable=all{not(s.da),not(s.db),not(s.cut),not(s.live),s'={...s,strongLive:true,live:true}}
 action decideA=all{s.managed,not(s.da),not(s.cut),s'={...s,da:true,ea:not(s.strongLive)}}
 action decideB=all{s.managed,not(s.db),not(s.cut),s'={...s,db:true,eb:not(s.strongLive)}}
 action legacyDecideA=all{not(s.managed),not(s.da),s'={...s,da:true,ea:not(s.live)}}
 action legacyDecideB=all{not(s.managed),not(s.db),s'={...s,db:true,eb:not(s.live)}}
 action classifyCut=all{s.managed,s.da,s.db,s'={...s,cut:true}}
 action weakMark=all{(s.managed and s.cut) or (not(s.managed) and (s.da or s.db)),s'={...s,live:true}}
 action finish=all{s.managed,s.cut,s.live,s'={...s,finished:true}}
 action step=any{strongReachable,decideA,decideB,legacyDecideA,legacyDecideB,classifyCut,weakMark,finish,all{s'=s}}
 run sharedDeadTest=init.then(decideA).then(decideB).then(classifyCut).then(weakMark).then(finish).then(all{assert(safe and s.ea and s.eb),s'=s})
 run reverseOrderTest=init.then(decideB).then(decideA).then(classifyCut).then(weakMark).then(all{assert(safe),s'=s})
 run sharedStrongTest=init.then(strongReachable).then(decideA).then(decideB).then(classifyCut).then(weakMark).then(all{assert(safe and not(s.ea) and not(s.eb)),s'=s})
 run legacyInterferenceTest=initLegacy.then(legacyDecideA).then(weakMark).then(legacyDecideB).then(all{assert(s.ea and not(s.eb)),s'=s})
 run missingCutControlTest=init.then(decideA).then(all{s'={...s,live:true}}).then(all{assert(not(safe)),s'=s})
 run incompleteRosterControlTest=init.then(decideA).then(all{s'={...s,cut:true}}).then(all{assert(not(safe)),s'=s})
}
