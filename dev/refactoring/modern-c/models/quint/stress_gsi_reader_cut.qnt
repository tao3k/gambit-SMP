module stress_gsi_reader_cut {
  // Abstract old-parity physical reader, not a simulation of Gambit barriers.
  type State = { reader: bool, drained: bool, retired: bool, reused: bool }
  var s: State
  action init = s' = { reader: false, drained: false, retired: false, reused: false }
  action enter = all { not(s.drained), not(s.retired), not(s.reader), s' = { ...s, reader: true } }
  action leave = all { s.reader, s' = { ...s, reader: false } }
  action drain = all { not(s.reader), not(s.drained), s' = { ...s, drained: true } }
  action retire = all { s.drained, not(s.reader), not(s.retired), s' = { ...s, retired: true } }
  action reuse = all { s.retired, not(s.reused), s' = { ...s, reused: true } }
  action step = any { enter, leave, drain, retire, reuse, all { s' = s } }
  val safe = all { s.retired implies (s.drained and not(s.reader)), s.reused implies s.retired }
  run delayedReaderTest = init.then(enter).then(all { assert(not(s.drained) and not(s.retired)), s' = s }).then(leave).then(drain).then(retire).then(reuse).then(all { assert(safe and s.reused), s' = s })
  run prematureRetireControlTest = init.then(enter).then(all { s' = { ...s, retired: true } }).then(all { assert(not(safe)), s' = s })
}
