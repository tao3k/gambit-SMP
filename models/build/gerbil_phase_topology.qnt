// Generated from GerbilPhaseReadiness SysML; do not edit graph here.
module gerbil_phase_topology {
  val Nodes = Set(0, 1, 2, 3, 4, 5, 6, 7, 8)
  pure def deps(n: int): Set[int] =
    if (n == 0) Set()
    else if (n == 1) Set(0)
    else if (n == 2) Set(0, 1)
    else if (n == 3) Set(2)
    else if (n == 4) Set(2)
    else if (n == 5) Set(3)
    else if (n == 6) Set(4)
    else if (n == 7) Set(0)
    else if (n == 8) Set(5, 6, 7)
    else Set()
}
