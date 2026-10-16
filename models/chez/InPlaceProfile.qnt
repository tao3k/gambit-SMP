// Marks retain the object address; generation/segment semantics remain separate.
module InPlaceProfile {
  import CollectionContract(Relocate = false, Mutation = "none").* from "../library/gc/CollectionContract"
}
