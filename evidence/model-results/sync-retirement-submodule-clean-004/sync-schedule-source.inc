#define SYNC_WAITING -1

#define SYNC_INIT_MSG(var) var = SYNC_WAITING

#define SYNC_GET_MSG_SPIN_TIMEOUT 2000

#define SYNC_GET_MSG(expr) \
do { \
     int loops_left = SYNC_GET_MSG_SPIN_TIMEOUT; \
     while ((expr) == SYNC_WAITING) \
       { \
         WASTE_TIME(); \
         if (--loops_left == 0) \
           { \
             loops_left = SYNC_GET_MSG_SPIN_TIMEOUT; \
             ___MUTEX_LOCK(___ps->sync_mut); \
             if ((expr) == SYNC_WAITING) \
               ___sync_wait (___ps); \
             ___MUTEX_UNLOCK(___ps->sync_mut); \
           } \
       } \
     ___SHARED_MEMORY_BARRIER(); /* acquire payload after observing message */ \
   } while (0)

#define SYNC_SEND_MSG(ps,field,val) \
do { \
     ___MUTEX_LOCK(ps->sync_mut); \
     ___SHARED_MEMORY_BARRIER(); /* publish payload before message flag */ \
     ps->field = val; \
     ___SHARED_MEMORY_BARRIER(); /* make sure write happens promptly */  \
     ___MUTEX_UNLOCK(ps->sync_mut); \
     ___CONDVAR_SIGNAL(ps->sync_cv); \
   } while (0)

___HIDDEN void setup_sync_op_pstate
   ___P((___processor_state ___ps),
        (___ps)
___processor_state ___ps;)
{
  SYNC_INIT_MSG(___ps->sync_id0);
  SYNC_INIT_MSG(___ps->sync_id1);
  SYNC_INIT_MSG(___ps->sync_id2);

  ___MUTEX_INIT(___ps->sync_mut);
  ___CONDVAR_INIT(___ps->sync_cv);
}

___EXP_FUNC(void,___cleanup_pstate)
   ___P((___processor_state ___ps),
        (___ps)
___processor_state ___ps;)
{
  cleanup_interrupts_pstate (___ps);
  cleanup_os_and_mem_pstate (___ps);
}

