package GambitMemoryOrganization {
  private import ScalarValues::*;
  attribute baseRevision:String="dfec5508118afef2dc9bd1ade5c928930e63c0fa";
  attribute source:String="vendor/gambit/lib/mem.c";
  attribute baselineSha256:String="2acf566b6b8b2208cfab61d2b428d8ee94b74c1d9ee497589491b6edc28e198d";
  attribute preambleLines:Integer=23;
  attribute fragmentSuffix:String="/* End internal memory fragment. */\n";
  attribute scope:String="Complete lossless source organization in one translation unit; no new runtime behavior or independent object compilation";
  attribute formalOwner:String="Source adaptation evidence only; existing QNT schedule and Lean coherence obligations are reused, not duplicated";
  part def Fragment { attribute file:String; attribute firstLine:Integer; attribute responsibility:String; }
  part m0:Fragment { attribute :>> file="_mem/configuration.inc"; attribute :>> firstLine=24; attribute :>> responsibility="Representation, budgets and internal macro environment"; }
  part m1:Fragment { attribute :>> file="_mem/aligned-allocation.inc"; attribute :>> firstLine=538; attribute :>> responsibility="Aligned native allocation and reclamation"; }
  part m2:Fragment { attribute :>> file="_mem/rc-allocation.inc"; attribute :>> firstLine=669; attribute :>> responsibility="RC registration, payload and lifetime"; }
  part m3:Fragment { attribute :>> file="_mem/movable-sections.inc"; attribute :>> firstLine=829; attribute :>> responsibility="Movable section inventory and physical allocation"; }
  part m4:Fragment { attribute :>> file="_mem/permanent-allocation.inc"; attribute :>> firstLine=1086; attribute :>> responsibility="Permanent sections and allocation"; }
  part m5:Fragment { attribute :>> file="_mem/global-bindings.inc"; attribute :>> firstLine=1228; attribute :>> responsibility="Global variable identity and lookup"; }
  part m6:Fragment { attribute :>> file="_mem/still-refcount.inc"; attribute :>> firstLine=1440; attribute :>> responsibility="Still object external reference counts"; }
  part m7:Fragment { attribute :>> file="_mem/object-allocation.inc"; attribute :>> firstLine=1484; attribute :>> responsibility="Permanent and still constructors; pair and vector APIs"; }
  part m8:Fragment { attribute :>> file="_mem/symbols.inc"; attribute :>> firstLine=1818; attribute :>> responsibility="Symbol and keyword interning; shared scan macros"; }
  part m9:Fragment { attribute :>> file="_mem/diagnostics.inc"; attribute :>> firstLine=2204; attribute :>> responsibility="Conditional GC consistency and debugging"; }
  part m10:Fragment { attribute :>> file="_mem/heap-sections.inc"; attribute :>> firstLine=3036; attribute :>> responsibility="Stack and heap sections; chunk FIFO publication; round setup"; }
  part m11:Fragment { attribute :>> file="_mem/copy-reservations.inc"; attribute :>> firstLine=3468; attribute :>> responsibility="Object scan authority, copy reservations and Tail"; }
  part m12:Fragment { attribute :>> file="_mem/continuation-roots.inc"; attribute :>> firstLine=3667; attribute :>> responsibility="Captured frames, continuations and root repair"; }
  part m13:Fragment { attribute :>> file="_mem/rc-roots.inc"; attribute :>> firstLine=3918; attribute :>> responsibility="RC root scanning"; }
  part m14:Fragment { attribute :>> file="_mem/object-scanning.inc"; attribute :>> firstLine=3950; attribute :>> responsibility="Object fields, still queues, chunk and frontier scanning"; }
  part m15:Fragment { attribute :>> file="_mem/still-sweep.inc"; attribute :>> firstLine=4334; attribute :>> responsibility="Still object sweep and destruction"; }
  part m16:Fragment { attribute :>> file="_mem/memory-lifecycle.inc"; attribute :>> firstLine=4401; attribute :>> responsibility="Capacity history, setup and cleanup"; }
  part m17:Fragment { attribute :>> file="_mem/wills.inc"; attribute :>> firstLine=4944; attribute :>> responsibility="Weak will execution eligibility and processing"; }
  part m18:Fragment { attribute :>> file="_mem/weak-tables.inc"; attribute :>> firstLine=5070; attribute :>> responsibility="Weak table GC processing and in-place rehash"; }
  part m19:Fragment { attribute :>> file="_mem/hash-table-api.inc"; attribute :>> firstLine=5679; attribute :>> responsibility="Hash lookup, mutation and union-find APIs"; }
  part m20:Fragment { attribute :>> file="_mem/capacity-resize.inc"; attribute :>> firstLine=6170; attribute :>> responsibility="Continuation movement, capacity, resize and retirement"; }
  part m21:Fragment { attribute :>> file="_mem/root-origins.inc"; attribute :>> firstLine=6503; attribute :>> responsibility="Context, VM and global root enumeration"; }
  part m22:Fragment { attribute :>> file="_mem/collection-round.inc"; attribute :>> firstLine=6614; attribute :>> responsibility="Strong and weak traversal, cleanup and GC round driver"; }
  part m23:Fragment { attribute :>> file="_mem/allocation-limits.inc"; attribute :>> firstLine=7036; attribute :>> responsibility="Mutator stack and heap checks; overflow undo"; }
  part m24:Fragment { attribute :>> file="_mem/allocation-statistics.inc"; attribute :>> firstLine=7453; attribute :>> responsibility="Allocation accounting query and final delimiter"; }
}
