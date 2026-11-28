#ifndef GAMBIT_TEST_MAP_WORKER_EXEC_JOURNAL_H
#define GAMBIT_TEST_MAP_WORKER_EXEC_JOURNAL_H

#include <sys/types.h>

enum event { registered = 1, acked, reader_stopped, retiring, retired, admission_closed };
struct record { unsigned epoch, reader; enum event event; ino_t bank_inode; };

#endif
