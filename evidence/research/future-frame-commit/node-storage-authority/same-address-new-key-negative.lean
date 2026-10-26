import NodeStorageAuthority
open NodeStorageAuthority
example : ¬ (StorageKey.mk 1 1=StorageKey.mk 1 2) := by decide
example : StorageKey.mk 1 1=StorageKey.mk 1 2 := by decide
