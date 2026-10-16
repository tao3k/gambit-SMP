// Contract instantiation, not yet a refinement of the complete Chez collector.
module CopyingProfile {
  import CollectionContract(Relocate = true, Mutation = "none").* from "../library/gc/CollectionContract"
}
