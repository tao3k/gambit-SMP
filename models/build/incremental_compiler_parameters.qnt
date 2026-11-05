// Native IncrementalCompilerArchitecture projection.
module incremental_compiler_parameters {
  pure val NodeCount = 8
  pure val Capacity = 2
  pure val Parents = Map(0 -> Set(), 1 -> Set(0), 2 -> Set(0,1), 3 -> Set(0,1), 4 -> Set(2), 5 -> Set(3), 6 -> Set(4,5), 7 -> Set())
}
