module gc_scan_barrier {
  var repair: bool
  var root0Done: bool
  var framePublished: bool
  var frameComplete: bool
  var root1Done: bool
  var scanned: bool
  var badScan: bool
  action initOld = all {
    repair' = false, root0Done' = false, framePublished' = false,
    frameComplete' = false, root1Done' = false, scanned' = false, badScan' = false,
  }
  action initFixed = all {
    repair' = true, root0Done' = false, framePublished' = false,
    frameComplete' = false, root1Done' = false, scanned' = false, badScan' = false,
  }
  action finish0 = all {
    not(root0Done), root0Done' = true, repair' = repair,
    framePublished' = framePublished, frameComplete' = frameComplete,
    root1Done' = root1Done, scanned' = scanned, badScan' = badScan,
  }
  action publishFrame = all {
    not(framePublished), framePublished' = true, root0Done' = root0Done,
    frameComplete' = frameComplete, root1Done' = root1Done,
    scanned' = scanned, badScan' = badScan, repair' = repair,
  }
  action finishCopy = all {
    framePublished, not(frameComplete), frameComplete' = true,
    root0Done' = root0Done, framePublished' = framePublished,
    root1Done' = root1Done, scanned' = scanned, badScan' = badScan, repair' = repair,
  }
  action finish1 = all {
    frameComplete, not(root1Done), root1Done' = true,
    frameComplete' = frameComplete, root0Done' = root0Done,
    framePublished' = framePublished, scanned' = scanned, badScan' = badScan, repair' = repair,
  }
  // Models a root-phase continuation frame becoming visible to scan workers.
  action scan = all {
    root0Done, framePublished, not(scanned), (not(repair) or root1Done),
    scanned' = true, badScan' = not(frameComplete),
    root0Done' = root0Done, root1Done' = root1Done,
    framePublished' = framePublished, frameComplete' = frameComplete, repair' = repair,
  }
  action idle = all {
    scanned, root0Done, root1Done, scanned' = scanned, badScan' = badScan,
    root0Done' = root0Done, root1Done' = root1Done,
    framePublished' = framePublished, frameComplete' = frameComplete, repair' = repair,
  }
  action step = any { finish0, publishFrame, finishCopy, finish1, scan, idle }
  val safe = not(badScan)
}
