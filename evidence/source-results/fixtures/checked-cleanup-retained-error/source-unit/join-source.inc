___SCMOBJ ___thread_join
   ___P((___thread *thread),
        (thread)
___thread *thread;)
{
#ifdef ___USE_POSIX_THREAD_SYSTEM

  int err = pthread_join (thread->thread_id, NULL);

  if (err != 0)
    return ___FIX(___ERRNO_ERR(err));

  return ___FIX(___NO_ERR);

#endif

#ifdef ___USE_WIN32_THREAD_SYSTEM

  if (WaitForSingleObject (thread->thread_handle, INFINITE) == WAIT_FAILED)
    return err_code_from_GetLastError ();

  return ___FIX(___NO_ERR);

#endif

#ifndef ___USE_POSIX_THREAD_SYSTEM
#ifndef ___USE_WIN32_THREAD_SYSTEM

  return ___FIX(___UNIMPL_ERR);

#endif
#endif
}

