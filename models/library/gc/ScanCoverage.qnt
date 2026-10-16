module ScanCoverage {
  // Coverage denotes shape-specific metadata, not all bits set in every segment.
  pure def completeShape(ready: bool, required: Set[int], scanned: Set[int]): bool =
    ready and required.subseteq(scanned)
  pure def completeSpan(required: Set[int], covered: Set[int]): bool =
    required.subseteq(covered)
  pure def remembered(age: int, oldest: int, buffered: bool): bool =
    oldest <= age or buffered
}
