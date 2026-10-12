module vm_retirement_join_composition {
  import vm_retirement_join_core(INSTANCE = 0) as Core from "./vm_retirement_join_core"
  export Core.*
}
