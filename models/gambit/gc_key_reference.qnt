module gc_key_reference {
  var scanKey: bool
  var rootScanned: bool
  var tableScanned: bool
  var rootAddress: int
  var tableAddress: int
  var phase: int
  var found: bool

  // Fault injection, not an observed flag value in the failing native run.
  action initMissingScan = all {
    scanKey' = false, rootScanned' = false, tableScanned' = false,
    rootAddress' = 0, tableAddress' = 0, phase' = 0, found' = true,
  }
  // Strong allocated keys require MEM_ALLOC_KEYS at scan's dispatch point.
  action initFixed = all {
    scanKey' = true, rootScanned' = false, tableScanned' = false,
    rootAddress' = 0, tableAddress' = 0, phase' = 0, found' = true,
  }
  // Canonical forwarding address 1 abstracts mark_array's successful CAS.
  // Either worker may encounter the shared object first; no body-copy proof.
  action scanRoot = all {
    phase == 0, not(rootScanned), rootScanned' = true, rootAddress' = 1,
    scanKey' = scanKey, tableScanned' = tableScanned, tableAddress' = tableAddress,
    phase' = phase, found' = found,
  }
  action scanTable = all {
    phase == 0, not(tableScanned), tableScanned' = true,
    tableAddress' = if (scanKey) 1 else tableAddress,
    scanKey' = scanKey, rootScanned' = rootScanned, rootAddress' = rootAddress,
    phase' = phase, found' = found,
  }
  action finish = all {
    phase == 0, rootScanned, tableScanned, phase' = 1,
    scanKey' = scanKey, rootScanned' = rootScanned, tableScanned' = tableScanned,
    rootAddress' = rootAddress, tableAddress' = tableAddress, found' = found,
  }
  // Perfect rehash still cannot equate a stale key slot with its moved alias.
  action lookup = all {
    phase == 1, phase' = 2, found' = (rootAddress == tableAddress),
    scanKey' = scanKey, rootScanned' = rootScanned, tableScanned' = tableScanned,
    rootAddress' = rootAddress, tableAddress' = tableAddress,
  }
  action idle = all {
    phase == 2, phase' = phase, found' = found, scanKey' = scanKey,
    rootScanned' = rootScanned, tableScanned' = tableScanned,
    rootAddress' = rootAddress, tableAddress' = tableAddress,
  }
  action step = any { scanRoot, scanTable, finish, lookup, idle }
  val safe = found
}
