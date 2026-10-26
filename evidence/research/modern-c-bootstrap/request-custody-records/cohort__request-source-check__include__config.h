/* include/config.h.  Generated from config.h.in by configure.  */
/* File: "config.h.in" */

/*
 * Copyright (c) 1994-2026 by Marc Feeley, All Rights Reserved.
 */

#ifndef CONFIG_H
#define CONFIG_H

/*---------------------------------------------------------------------------*/

/*
 * These definitions are used by the "gambit.h" header file.
 */

/* Define as 1 if you want to compile for debugging.  */
/* #undef ___DEBUG */

/* Define as 1 if you want to generate a debugging log file.  */
/* #undef ___DEBUG_LOG */

/* Define as 1 if you want to generate a C backtrace when a program crashes.  */
/* #undef ___DEBUG_C_BACKTRACE */

/* Define as 1 if you want to compile for debugging the control flow history.  */
/* #undef ___DEBUG_CTRL_FLOW_HISTORY */

/* Define as 1 if you want to compile for debugging the host changes.  */
/* #undef ___DEBUG_HOST_CHANGES */

/* Define as 1 if you want to generate a log of the memory allocations. */
/* #undef ___DEBUG_ALLOC_MEM */

/* Define as 1 if you want to compile for debugging the garbage collector.  */
/* #undef ___DEBUG_GARBAGE_COLLECT */

/* Define as 1 if you want to compile with profiling.  */
/* #undef ___PROFILE */

/* Define as 1 if you want to compile each Scheme file into one C function.  */
#define ___SINGLE_HOST /**/

/* Define as 1 if you want to mix the execution of C and machine code.  */
/* #undef ___SUPPORT_LOWLEVEL_EXEC */

/* Define as 1 if you want trampoline jumps to be inlined.  */
#define ___INLINE_JUMPS /**/

/* Define as 1 if you trust the C compiler does TCO properly */
#define ___TRUST_C_TCO /**/

/* Define as 1 if you want to compile as a shared library.  */
/* #undef ___SHARED */

/* Define as 1 if dynamically loaded code should not be unloaded.  */
/* #undef ___DONT_UNLOAD_DYN_CODE */

/* Define as 1 if thread local storage variables can be referenced from dynamically loaded code */
/* #undef ___DYNAMIC_TLS */

/* Define as 1 if C library functions can be called from dynamically loaded code */
#define ___CAN_IMPORT_CLIB_DYNAMICALLY /**/

/* Define as 1 if C library setjmp function can be called from dynamically loaded code */
#define ___CAN_IMPORT_SETJMP_DYNAMICALLY /**/

/* Define as 1 if Gambit RTS functions can be called from dynamically loaded code */
/* #undef ___CAN_IMPORT_DYNAMICALLY */

/*---------------------------------------------------------------------------*/

/* Determine which header files are available. */

#ifndef _GNU_SOURCE
#define _GNU_SOURCE /**/
#endif

#define HAVE_ERRNO_H 1
#define HAVE_UNISTD_H 1
#define HAVE_PWD_H 1
#define HAVE_DIRENT_H 1
#define HAVE_DLFCN_H 1
/* #undef HAVE_DL_H */
/* #undef HAVE_SYS_DXE_H */
#define HAVE_MACH_O_DYLD_H 1
#define HAVE_MACH_MACH_TIME_H 1
#define HAVE_MACH_THREAD_ACT_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_SYS_TIME_H 1
#define HAVE_SYS_TIMES_H 1
#define HAVE_SYS_TIMEB_H 1
/* #undef HAVE_SYS_TIMERS_H */
#define HAVE_TIME_H 1
#define HAVE_SYS_RESOURCE_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_WAIT_H 1
#define HAVE_SYS_MMAN_H 1
#define HAVE_SYSLOG_H 1
#define HAVE_EXECINFO_H 1
/* #undef HAVE_STAT_H */
#define HAVE_SIGNAL_H 1
#define HAVE_NETDB_H 1
#define HAVE_GRP_H 1
/* #undef HAVE_EMSCRIPTEN_H */
/* #undef HAVE_WINDOWS_H */
/* #undef HAVE_IO_H */
/* #undef HAVE_TCHAR_H */
#define HAVE_FLOAT_H 1
/* #undef HAVE_FPU_CONTROL_H */
/* #undef HAVE_OS2_H */
/* #undef HAVE_DOS_H */
/* #undef HAVE_DIRECT_H */
/* #undef HAVE_RETRACE_H */
/* #undef HAVE_FILES_H */
/* #undef HAVE_FINDER_H */
/* #undef HAVE_ERRORS_H */
/* #undef HAVE_FOLDERS_H */
/* #undef HAVE_OSUTILS_H */
/* #undef HAVE_POWER_H */
/* #undef HAVE_CODEFRAGMENTS_H */
/* #undef HAVE_SIOUX_H */
/* #undef HAVE_MAC_GUI_H */
/* #undef HAVE_UNIX_H */
/* #undef HAVE_WDEFWIN_H */
/* #undef HAVE_TFORK_H */
#define HAVE_CURSES_H 1
#define HAVE_NCURSES_H 1
#define HAVE_NETINET_IN_H 1
#define HAVE_ARPA_INET_H 1
#define HAVE_TERMIOS_H 1
/* #undef HAVE_TERM_H */
/* #undef HAVE_PTY_H */
/* #undef HAVE_STROPTS_H */
/* #undef HAVE_LIBUTIL_H */
#define HAVE_UTIL_H 1
/* #undef HAVE_SYS_FPU_H */
#define HAVE_FENV_H 1
#define HAVE_FCNTL_H 1
#define HAVE_SYS_IOCTL_H 1
#define HAVE_SYS_SOCKET_H 1
#define HAVE_STDIO_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRING_H 1
#define HAVE_STRINGS_H 1
#define HAVE_MEMORY_H 1
#define HAVE_SYS_SYSCTL_H 1
#define HAVE_SYS_SYSCALL_H 1
/* #undef HAVE_LINUX_FS_H */
#define HAVE_CRT_EXTERNS_H 1
/* #undef HAVE_WS2TCPIP_H */
/* #undef HAVE_LM_H */
#define HAVE_TARGETCONDITIONALS_H 1
#define HAVE_AVAILABILITYMACROS_H 1
#define HAVE_POLL_H 1
#define HAVE_SCHED_H 1

/*---------------------------------------------------------------------------*/

/* Determine which library functions are available. */

#define HAVE_OPEN 1
#define HAVE_OPENAT 1
#define HAVE_PIPE 1
#define HAVE_SOCKETPAIR 1
#define HAVE_CHDIR 1
#define HAVE_EXECVP 1
/* #undef HAVE_GETENV */
#define HAVE_GETGRNAM 1
#define HAVE_GETPID 1
#define HAVE_GETPPID 1
#define HAVE_GETPWNAM 1
#define HAVE_IOCTL 1
#define HAVE_READLINK 1
#define HAVE_READLINKAT 1
#define HAVE_LINK 1
#define HAVE_LINKAT 1
#define HAVE_MKDIR 1
#define HAVE_MKDIRAT 1
#define HAVE_MKFIFO 1
#define HAVE_MKFIFOAT 1
#define HAVE_OPENDIR 1
#define HAVE_FDOPENDIR 1
#define HAVE_RMDIR 1
#define HAVE_SOCKET 1
#define HAVE_UTIMES 1
#define HAVE_STAT 1
#define HAVE_STAT64 1
#define HAVE_FSTATAT 1
#define HAVE_STRERROR 1
#define HAVE_SYMLINK 1
#define HAVE_SYMLINKAT 1
#define HAVE_SYSCONF 1
#define HAVE_SYSCTL 1
#define HAVE_SYSCTLBYNAME 1
#define HAVE_SYSLOG 1
#define HAVE_BACKTRACE_SYMBOLS_FD 1
#define HAVE_UNLINK 1
#define HAVE_UNLINKAT 1
#define HAVE_WAITPID 1
#define HAVE_MMAP 1
#define HAVE_FCNTL 1
#define HAVE_GETCWD 1

#define HAVE_TCGETSETATTR /**/

#define HAVE_SIGACTION /**/
#define HAVE_SIGNAL /**/
#define HAVE_SIGEMPTYSET /**/
#define HAVE_SIGADDSET /**/
#define HAVE_SIGPROCMASK /**/

/* Define one of these to support timekeeping (timeouts, current-time, etc): */
/* #undef HAVE_EMSCRIPTEN_GET_NOW */
#define HAVE_CLOCK_GETTIME 1
#define HAVE_MACH_ABSOLUTE_TIME 1
/* #undef HAVE_GETCLOCK */
/* #undef HAVE_GETSYSTEMTIMEASFILETIME */
/* #undef HAVE_TIMEBEGINPERIOD */
#define HAVE_GETTIMEOFDAY 1
#define HAVE_FTIME 1
#define HAVE_TIME 1

#define HAVE_NANOSLEEP 1
/* #undef HAVE_Sleep */
#define HAVE_SLEEP 1

/* #undef HAVE_GETPROCESSTIMES */
#define HAVE_GETRUSAGE 1
#define HAVE_TIMES 1
#define HAVE_CLOCK 1
/* #undef HAVE_DOSQUERYSYSINFO */

/* #undef HAVE_CLOSEFROM */
/* #undef HAVE_SYS_close_range */
#define HAVE_GETRLIMIT 1

/* Define one of these to support preemptive Scheme thread scheduling: */
#define HAVE_SETITIMER 1
/* #undef HAVE_DOS_SETVECT */
/* #undef HAVE_DOSSTARTTIMER */
/* #undef HAVE_VINSTALL */
/* #undef HAVE_CREATETHREAD */

/* Define one of these to support dynamically loadable object files: */
/* #undef HAVE_SHL_LOAD */
/* #undef HAVE_LOADLIBRARY */
/* #undef HAVE_DOSLOADMODULE */
/* #undef HAVE_DXE_LOAD */
/* #undef HAVE_GETDISKFRAGMENT */
#define HAVE_NSLINKMODULE 1
#define HAVE__NSGETEXECUTABLEPATH 1
#define HAVE_DLOPEN 1

#define HAVE_GETHOSTNAME 1
#define HAVE_INET_PTON 1
#define HAVE_GETADDRINFO 1
#define HAVE_GETHOSTBYNAME 1
#define HAVE_GETHOSTBYADDR 1
#define HAVE_GETSERVBYNAME 1
#define HAVE_GETSERVBYPORT 1
#define HAVE_GETPROTOBYNAME 1
#define HAVE_GETPROTOBYNUMBER 1
#define HAVE_GETNETBYNAME 1

/* Define one of these to support nonblocking I/O: */
#define HAVE_SELECT 1
#define HAVE_POLL 1
/* #undef HAVE_PPOLL */
/* #undef HAVE_MSGWAITFORMULTIPLEOBJECTS */

/* #undef HAVE_TGETSTR */
/* #undef HAVE_TIGETSTR */

#define HAVE_OPENPTY 1
/* #undef HAVE_GETPT */
#define HAVE_PTSNAME 1
#define HAVE_CTERMID 1
/* #undef HAVE_ISASTREAM */

#define HAVE_HSTRERROR 1

#define HAVE_SNPRINTF 1

/* #undef HAVE_GET_FPC_CSR */

#define HAVE_ENVIRON /**/
#define HAVE__NSGETENVIRON /**/
#define HAVE_REMOVE 1
#define HAVE_RENAME 1
#define HAVE_RENAMEAT 1
/* #undef HAVE_RENAMEAT2 */
#define HAVE_RENAMEATX_NP 1

/* #undef HAVE_PTHREAD_SETAFFINITY_NP */

/* #undef HAVE_SCHED_GETCPU */

/* Determine which types are available */

/* #undef HAVE_STRUCT_STAT64 */

/* Define appropriately if sys/types.h does not define socklen_t.  */
/* #undef socklen_t */

/*
 * Define appropriately as the prefix and suffix added to function
 * names by the C compiler.
 */
/* #undef ___IMPORTED_ID_PREFIX */
/* #undef ___IMPORTED_ID_SUFFIX */

/* Define as 1 if you want to enable OpenSSL support */
/* #undef USE_OPENSSL */

/* Define as 1 if you want to enable poll support */
/* #undef USE_POLL_FOR_SELECT */

/* Define as 1 if you want to enable high-resolution timing */
/* #undef USE_HIGH_RES_TIMING */

/* Define as 1 if you want to force using ITIMER_REAL for itimer */
/* #undef USE_ITIMER_REAL */

/* Define as 1 to select a filesystem path encoding */
/* #undef ___PATH_ENCODING_UTF8 */
/* #undef ___PATH_ENCODING_LATIN1 */
/* #undef ___PATH_ENCODING_UCS2 */
/* #undef ___PATH_ENCODING_UCS4 */
/* #undef ___PATH_ENCODING_WCHAR */
/* #undef ___PATH_ENCODING_NATIVE */

/*
 * Define as a UCS_2 array initialization containing the default
 * runtime options, e.g. #define ___DEFAULT_RUNTIME_OPTIONS {'d','2','\0'}
 */
#define ___DEFAULT_RUNTIME_OPTIONS {'s', 'e', 'a', 'r', 'c', 'h', '=', '~', '~', 'u', 's', 'e', 'r', 'l', 'i', 'b', ',', 's', 'e', 'a', 'r', 'c', 'h', '=', '~', '~', 'l', 'i', 'b', ',', 'w', 'h', 'i', 't', 'e', 'l', 'i', 's', 't', '=', 'g', 'i', 't', 'h', 'u', 'b', '.', 'c', 'o', 'm', '/', 'g', 'a', 'm', 'b', 'i', 't', '\0'}

/*
 * Define as a UCS_2 array initialization containing the default
 * compile options
 */
#define ___DEFAULT_COMPILE_OPTIONS {'(', 'c', 'o', 'm', 'p', 'a', 'c', 't', 'n', 'e', 's', 's', ' ', '9', ')', '\0'}

/*---------------------------------------------------------------------------*/

#endif
