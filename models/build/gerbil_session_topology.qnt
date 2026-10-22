// Generated from GerbilSessionClosure SysML.
module gerbil_session_topology {
  val Nodes = Set(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
  val Roots = Set(0, 6, 8)
  val ObservedCensus = false
  pure def calls(n: int): Set[int] =
    if (n == 0) Set(1, 3)
    else if (n == 1) Set(2, 5)
    else if (n == 2) Set(5)
    else if (n == 3) Set(4)
    else if (n == 4) Set(5)
    else if (n == 5) Set()
    else if (n == 6) Set(7)
    else if (n == 7) Set()
    else if (n == 8) Set(5)
    else if (n == 9) Set()
    else Set()
  val Required = Nodes.fold(Roots, (found, _) =>
    found.union(found.fold(Set(), (out, n) => out.union(calls(n)))))
}

