package GambitMemoryOrganization {
  private import ScalarValues::*;
  attribute source:String="vendor/gambit/lib/mem.c";
  attribute baselineSha256:String="745705ff7dc1f5e0113d333544a7a44bda85b812c621e8fc8313ab90f5b89e3e";
  attribute preambleLines:Integer=24;
  attribute scope:String="Complete lossless source organization in one translation unit; no new runtime behavior or independent object compilation";
  attribute formalOwner:String="Source adaptation evidence only; existing QNT schedule and Lean coherence obligations are reused, not duplicated";
  part def Fragment { attribute file:String; attribute firstLine:Integer; attribute responsibility:String; }
  part m0:Fragment { attribute :>> file="memory/configuration.inc"; attribute :>> firstLine=25; attribute :>> responsibility="Representation, budgets and internal macro environment"; }
  part m1:Fragment { attribute :>> file="memory/aligned-allocation.inc"; attribute :>> firstLine=545; attribute :>> responsibility="Aligned native allocation and reclamation"; }
  part m2:Fragment { attribute :>> file="memory/rc-allocation.inc"; attribute :>> firstLine=676; attribute :>> responsibility="RC registration, payload and lifetime"; }
  part m3:Fragment { attribute :>> file="memory/movable-sections.inc"; attribute :>> firstLine=836; attribute :>> responsibility="Movable section inventory and physical allocation"; }
  part m4:Fragment { attribute :>> file="memory/permanent-allocation.inc"; attribute :>> firstLine=1093; attribute :>> responsibility="Permanent sections and allocation"; }
  part m5:Fragment { attribute :>> file="memory/global-bindings.inc"; attribute :>> firstLine=1235; attribute :>> responsibility="Global variable identity and lookup"; }
  part m6:Fragment { attribute :>> file="memory/still-refcount.inc"; attribute :>> firstLine=1447; attribute :>> responsibility="Still object external reference counts"; }
  part m7:Fragment { attribute :>> file="memory/object-allocation.inc"; attribute :>> firstLine=1491; attribute :>> responsibility="Permanent and still constructors; pair and vector APIs"; }
  part m8:Fragment { attribute :>> file="memory/symbols.inc"; attribute :>> firstLine=1825; attribute :>> responsibility="Symbol and keyword interning; shared scan macros"; }
  part m9:Fragment { attribute :>> file="memory/diagnostics.inc"; attribute :>> firstLine=2211; attribute :>> responsibility="Conditional GC consistency and debugging"; }
  part m10:Fragment { attribute :>> file="memory/heap-sections.inc"; attribute :>> firstLine=3046; attribute :>> responsibility="Stack and heap sections; chunk FIFO publication; round setup"; }
  part m11:Fragment { attribute :>> file="memory/copy-reservations.inc"; attribute :>> firstLine=3627; attribute :>> responsibility="Object scan authority, copy reservations and Tail"; }
  part m12:Fragment { attribute :>> file="memory/continuation-roots.inc"; attribute :>> firstLine=4085; attribute :>> responsibility="Captured frames, continuations and root repair"; }
  part m13:Fragment { attribute :>> file="memory/rc-roots.inc"; attribute :>> firstLine=4356; attribute :>> responsibility="RC root scanning"; }
  part m14:Fragment { attribute :>> file="memory/object-scanning.inc"; attribute :>> firstLine=4389; attribute :>> responsibility="Object fields, still queues, chunk and frontier scanning"; }
  part m15:Fragment { attribute :>> file="memory/still-sweep.inc"; attribute :>> firstLine=4794; attribute :>> responsibility="Still object sweep and destruction"; }
  part m16:Fragment { attribute :>> file="memory/memory-lifecycle.inc"; attribute :>> firstLine=4861; attribute :>> responsibility="Capacity history, setup and cleanup"; }
  part m17:Fragment { attribute :>> file="memory/wills.inc"; attribute :>> firstLine=5423; attribute :>> responsibility="Weak will execution eligibility and processing"; }
  part m18:Fragment { attribute :>> file="memory/weak-tables.inc"; attribute :>> firstLine=5549; attribute :>> responsibility="Weak table GC processing and in-place rehash"; }
  part m19:Fragment { attribute :>> file="memory/hash-table-api.inc"; attribute :>> firstLine=6167; attribute :>> responsibility="Hash lookup, mutation and union-find APIs"; }
  part m20:Fragment { attribute :>> file="memory/capacity-resize.inc"; attribute :>> firstLine=6658; attribute :>> responsibility="Continuation movement, capacity, resize and retirement"; }
  part m21:Fragment { attribute :>> file="memory/root-origins.inc"; attribute :>> firstLine=7191; attribute :>> responsibility="Context, VM and global root enumeration"; }
  part m22:Fragment { attribute :>> file="memory/collection-round.inc"; attribute :>> firstLine=7348; attribute :>> responsibility="Strong and weak traversal, cleanup and GC round driver"; }
  part m23:Fragment { attribute :>> file="memory/allocation-limits.inc"; attribute :>> firstLine=7815; attribute :>> responsibility="Mutator stack and heap checks; overflow undo"; }
  part m24:Fragment { attribute :>> file="memory/allocation-statistics.inc"; attribute :>> firstLine=8232; attribute :>> responsibility="Allocation accounting query and final delimiter"; }
}
