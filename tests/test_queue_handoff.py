import unittest

from gambit_smp.source_binding import queue_acquire_handoff, postcopy_headroom


class QueueHandoffTests(unittest.TestCase):
    def test_postcopy_floor_keeps_cap_after_actual_assignment_admission(self):
        floor = ("lower_bound_nb_sections += compute_nb_msections_allocation_headroom();"
                 "SET_MAX(lower_bound_nb_sections,"
                 "nb_msections_assigned + compute_nb_msections_allocation_headroom());")
        admission = "SET_MAX(target_nb_sections,lower_bound_nb_sections);"
        cap = "SET_MIN(target_nb_sections,upper_bound_nb_sections);"
        def source(body):
            return "___HIDDEN ___BOOL resize_heap\n" + body + "___BOOL ___stack_limit_debug\n"
        self.assertEqual("passed", postcopy_headroom(source(floor + admission + cap))["postcopyHeadroomSourceBinding"])
        for body in (floor + admission, admission + cap + floor,
                     floor.replace("nb_msections_assigned", "target_processor_count") + admission + cap):
            with self.assertRaises(ValueError):
                postcopy_headroom(source(body))

    def test_every_queue_consumer_acquires_after_waiting(self):
        lock = "___SPINLOCK_LOCK(heap_chunks_to_scan_lock);"
        steal = "___SPINLOCK_LOCK(ps->mem.heap_chunks_to_scan_lock_);"
        fence = "___SHARED_MEMORY_BARRIER();"
        source = ("___HIDDEN void scan_movable_objs_to_scan\n" + (lock + fence) * 2 +
                  "___HIDDEN void free_unmarked_still_objs\n" +
                  "___HIDDEN void mark_reachable_from_marked\n" + steal + fence +
                  "___HIDDEN void garbage_collect_setup_phase\n")
        self.assertEqual("passed", queue_acquire_handoff(source)["queueAcquireHandoffSourceBinding"])
        for occurrence in range(3):
            pieces = source.split(fence)
            pieces[occurrence] += "/* no acquire */"
            invalid = fence.join(pieces[:occurrence+1]) + "".join(pieces[occurrence+1:])
            with self.assertRaises(ValueError):
                queue_acquire_handoff(invalid)
        with self.assertRaises(ValueError):
            queue_acquire_handoff(source.replace(steal + fence, fence + steal))
