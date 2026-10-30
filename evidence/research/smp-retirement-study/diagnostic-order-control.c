/* Evidence-only assembly control: never linked or executed. Not Gambit. */
typedef unsigned long word;
typedef struct { word address, stage, commit, raw; } record;
_Static_assert(sizeof(word)==8,"64-bit evidence target required");
_Static_assert(__atomic_always_lock_free(8,0),"lock-free footer required");
#define BEGIN() d->address=(word)cell; d->stage=1
#define COMMIT(order) __atomic_store_n(&d->commit,seq,order)
__attribute__((noinline)) word release_only(record*d,word const*cell,word seq) {
 BEGIN(); COMMIT(__ATOMIC_RELEASE); return *cell;
}
__attribute__((noinline)) word signal_only(record*d,word const*cell,word seq) {
 BEGIN(); COMMIT(__ATOMIC_RELEASE); __atomic_signal_fence(__ATOMIC_SEQ_CST); return *cell;
}
__attribute__((noinline)) word store_seqcst(record*d,word const*cell,word seq) {
 BEGIN(); COMMIT(__ATOMIC_SEQ_CST); return *cell;
}
__attribute__((noinline)) word full_barrier(record*d,word const*cell,word seq) {
 BEGIN(); COMMIT(__ATOMIC_RELEASE); __atomic_thread_fence(__ATOMIC_SEQ_CST); return *cell;
}
/* header is a separate parameter: no claim to implement Gambit tags. */
__attribute__((noinline)) word two_reads(record*d,word const*cell,word const*header,word seq) {
 BEGIN(); COMMIT(__ATOMIC_RELEASE); __atomic_thread_fence(__ATOMIC_SEQ_CST);
 word obj=*cell;
 d->raw=obj; d->address=(word)header; d->stage=2;
 __atomic_store_n(&d->commit,seq+1,__ATOMIC_RELEASE);
 __atomic_thread_fence(__ATOMIC_SEQ_CST); return *header;
}
