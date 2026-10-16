module continuation_link_handoff {
  // One copied frame whose continuation link is still producer-owned.
  // Sequentially consistent schedule; queue eligibility is an explicit premise.
  // link: 0=old stack pointer, 1=forward pointer, 2=false sentinel,
  //       3=retagged old stack pointer, 4=retagged forward pointer.
  type State = { fixed: bool, published: bool, producerDone: bool,
    consumer: int, link: int, saved: int, earlyRead: bool }
  var s: State
  pure def initialState(fixed: bool): State = {
    fixed: fixed, published: false, producerDone: false,
    consumer: 0, link: 0, saved: 0, earlyRead: false,
  }
  action initOld = s' = initialState(false)
  action initFixed = s' = initialState(true)
  action publish = all {
    not(s.published),
    not(s.fixed) or s.producerDone,
    s' = { ...s, published: true },
  }
  // The next producer iteration executes *ptr=forw on the previous frame.
  action completeLink = all {
    not(s.producerDone), s' = { ...s, producerDone: true, link: 1 },
  }
  // ___sFRAME reads the link before replacing it with a false sentinel.
  action readLink = all {
    s.published, s.consumer == 0,
    s' = { ...s, consumer: 1, saved: s.link,
      earlyRead: not(s.producerDone) },
  }
  action maskLink = all { s.consumer == 1, s' = { ...s, consumer: 2, link: 2 } }
  // mark_frame is abstracted; the saved link is restored with SUBTYPED tag.
  action restoreLink = all {
    s.consumer == 2,
    s' = { ...s, consumer: 3, link: if (s.saved == 0) 3 else 4 },
  }
  val terminal = s.producerDone and s.consumer == 3
  action finished = all { terminal, s' = s }
  action step = any { publish, completeLink, readLink, maskLink, restoreLink, finished }
  val readySafe = not(s.earlyRead)
  val updateSafe = not(terminal) or Set(1, 4).contains(s.link)
  val safe = readySafe and updateSafe
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
