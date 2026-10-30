#include <stddef.h>
#include <stdio.h>
#include "gambit.h"
#define FIELD(t,f) printf("\"" #f "\":%zu,",offsetof(t,f))
int main(void) {
  printf("{\"pstate\":{");
  FIELD(struct ___processor_state_struct,vmstate);
  FIELD(struct ___processor_state_struct,context);
  printf("\"stride\":%zu},\"vm\":{",sizeof(___aligned_processor_state_struct));
  FIELD(struct ___virtual_machine_state_struct,processor_count);
  FIELD(struct ___virtual_machine_state_struct,gc_round);FIELD(struct ___virtual_machine_state_struct,collector_workers);
  FIELD(struct ___virtual_machine_state_struct,mem.the_msections_);
  FIELD(struct ___virtual_machine_state_struct,mem.alloc_msection_);
  FIELD(struct ___virtual_machine_state_struct,mem.nb_msections_assigned_);
  FIELD(struct ___virtual_machine_state_struct,mem.nb_msections_stacks_);
  FIELD(struct ___virtual_machine_state_struct,mem.normal_overflow_reserve_);
  FIELD(struct ___virtual_machine_state_struct,mem.overflow_reserve_);
  FIELD(struct ___virtual_machine_state_struct,resize.phase);
  FIELD(struct ___virtual_machine_state_struct,execution_contexts);
  FIELD(struct ___virtual_machine_state_struct,mem.occupied_words_movable_);
  FIELD(struct ___virtual_machine_state_struct,mem.occupied_words_still_);
  FIELD(struct ___virtual_machine_state_struct,mem.heap_size_);FIELD(struct ___virtual_machine_state_struct,mem.nb_gcs_);
  printf("\"end\":0},\"context\":{");
  FIELD(___execution_context,mem.alloc_heap_start_);FIELD(___execution_context,mem.alloc_heap_ptr_);FIELD(___execution_context,mem.alloc_heap_limit_);FIELD(___execution_context,mem.alloc_stack_start_);FIELD(___execution_context,mem.alloc_stack_ptr_);FIELD(___execution_context,mem.alloc_stack_limit_);FIELD(___execution_context,mem.words_prev_msections_);FIELD(___execution_context,mem.stack_msection_);FIELD(___execution_context,mem.heap_msection_);FIELD(___execution_context,mem.words_still_objs_);FIELD(___execution_context,mem.tospace_offset_);FIELD(___execution_context,hp);FIELD(___execution_context,fp);
  FIELD(___execution_context,heap_limit);FIELD(___execution_context,stack_limit);
  printf("\"stride\":%zu},\"sections\":{",sizeof(___execution_context));
  FIELD(___msections,nb_sections);FIELD(___msections,head);FIELD(___msections,tail);
  printf("\"end\":0},\"section\":{");
  FIELD(___msection,index);FIELD(___msection,next);FIELD(___msection,base);
printf("\"end\":0},\"round\":{");
FIELD(___gc_round,source_words);FIELD(___gc_round,source_sections);FIELD(___gc_round,invalid_copy_cell);FIELD(___gc_round,invalid_copy_body);FIELD(___gc_round,invalid_copy_worker);
printf("\"end\":0},\"worker\":{");FIELD(___collector_worker,carrier);FIELD(___collector_worker,context);FIELD(___collector_worker,copied_words);FIELD(___collector_worker,duplicate_scans);FIELD(___collector_worker,local_scan_chunk_);FIELD(___collector_worker,active_scan_chunk_);FIELD(___collector_worker,active_scan_object_);FIELD(___collector_worker,scan_origin_);FIELD(___collector_worker,chunks_published_);FIELD(___collector_worker,chunks_claimed_);FIELD(___collector_worker,chunks_completed_);FIELD(___collector_worker,alloc_heap_chunk_start_);FIELD(___collector_worker,scan_ptr_);FIELD(___collector_worker,heap_chunks_to_scan_head_);FIELD(___collector_worker,heap_chunks_to_scan_tail_);printf("\"stride\":%zu}}\n",sizeof(___collector_worker));return 0;

}
