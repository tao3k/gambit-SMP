module publisher_contract {
  // Staged -> published/discarded over the existing build model.
  // Real multi-file group commit, rename/fsync and consumer traces remain open.
  import incremental_build.* from "./incremental_build"
  run currentPublicationTest = initLeaf.then(start(0)).then(finish(0)).then(publish(0))
    .expect(safe and s.phase.get(0) == 2 and s.out.get(0).bytes == 1)
  run changedInputDiscardTest = initLeaf.then(start(0)).then(finish(0)).then(invalidate).then(discard(0))
    .expect(safe and s.phase.get(0) == 4 and s.out.get(0).bytes == 0)
  run cancelledDiscardTest = initLeaf.then(start(0)).then(finish(0)).then(cancel).then(discard(0))
    .expect(safe and s.phase.get(0) == 4)
  run staleCommitControlTest = initStalePublish.then(start(0)).then(finish(0)).then(invalidate).then(publish(0))
    .expect(not(publicationSafe))
}
