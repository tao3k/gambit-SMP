module planner_contract {
  // Qualification histories over the existing ten-node GSC slice.
  // No real reader, hashing, 74-action refinement or filesystem implementation.
  import incremental_build.* from "./incremental_build"
  run noChangeTest = initNoChange.then(reuse(0)).then(reuse(1))
    .expect(safe and noChangeWork and s.executed == Set())
  run leafCutTest = initLeaf.then(start(0)).then(finish(0)).then(publish(0)).then(reuse(1))
    .expect(safe and ready(2) and not(ready(6)) and s.out.get(0).bytes == 1)
  run macroFanoutTest = initMacro.then(start(0)).then(finish(0)).then(publish(0))
    .then(start(1)).then(finish(1)).then(publish(1)).then(start(4))
    .expect(safe and s.staged.get(4).meta == 2)
  run forgedReuseControlTest = initBadReuse.then(reuse(0)).expect(not(reuseSafe))
}
