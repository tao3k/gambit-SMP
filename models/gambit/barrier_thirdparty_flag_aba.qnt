module barrier_thirdparty_flag_aba {
  // A participant has consumed the old message before reusing its mailbox.
  // The third-party reader does not participate in that acknowledgment.
  // Even SC atomic payload fields do not make a recurring sender ID a version.
  type State = {
    writer: int, reader: int, flag: int, op: int, arg: int,
    first: int, readOp: int, readArg: int, accepted: bool
  }
  var s: State
  action init = s' = {writer: 0, reader: 0, flag: 1, op: 1, arg: 11,
    first: -1, readOp: 0, readArg: 0, accepted: false}
  action consume = all { s.writer == 0, s' = {...s, writer: 1, flag: -1} }
  action writeOp = all { s.writer == 1, s' = {...s, writer: 2, op: 2} }
  action writeArg = all { s.writer == 2, s' = {...s, writer: 3, arg: 22} }
  action publish = all { s.writer == 3, s' = {...s, writer: 4, flag: 1} }
  action before = all { s.reader == 0, s.flag == 1,
    s' = {...s, reader: 1, first: s.flag} }
  action readOp = all { s.reader == 1, s' = {...s, reader: 2, readOp: s.op} }
  action readArg = all { s.reader == 2, s' = {...s, reader: 3, readArg: s.arg} }
  action after = all { s.reader == 3,
    s' = {...s, reader: 4, accepted: s.first == 1 and s.flag == s.first} }
  action finished = all { s.writer == 4, s.reader == 4, s' = s }
  action step = any { consume, writeOp, writeArg, publish,
    before, readOp, readArg, after, finished }
  val coherent = not(s.accepted) or
    (s.readOp == 1 and s.readArg == 11) or
    (s.readOp == 2 and s.readArg == 22)
}
