#include <stdio.h>
#include <stdlib.h>

/* Execute the unchanged embedded C boundary with deterministic mock GC.
 * This is not the Gambit ABI, moving collector or OS-thread runtime. */
typedef int ___SCMOBJ;
static int cached_frame, processor_frame, cached_root, processor_root;
static int frame_ra[3], ra_saved, bad_roots, collections, r0 = 9;
static int result_value;

#define ___R0 r0
#define ___ARG1 0
#define ___ARG2 0
#define ___RESULT result_value
#define ___FRAME_STORE_RA(ra) do { frame_ra[cached_frame] = (ra); ra_saved = 1; } while (0);
#define ___FRAME_FETCH_RA frame_ra[cached_frame]
#define ___SET_R0(ra) do { r0 = (ra); } while (0);
#define ___W_ALL do { processor_frame = cached_frame; processor_root = cached_root; } while (0);
#define ___R_ALL do { cached_frame = processor_frame; cached_root = processor_root; } while (0);

static ___SCMOBJ ___os_condvar_select(int devices, int timeout)
{
    (void)devices;
    (void)timeout;
    for (int epoch = 0; epoch < collections; epoch++) {
        bad_roots |= processor_root != 7 + epoch;
        processor_frame++;
        processor_root++;
        frame_ra[processor_frame] = ra_saved ? 9 : 0;
    }
    return 99;
}

static void boundary(void)
{
#include "ffi-source.inc"
}

int main(int argc, char **argv)
{
    if (argc != 2) return 2;
    collections = atoi(argv[1]);
    if (collections < 0 || collections > 2) return 2;
    cached_root = 7;
    processor_root = 3;
    frame_ra[0] = 9;
    boundary();
    processor_frame = cached_frame;
    processor_root = cached_root;
    int valid = !bad_roots && processor_frame == collections &&
        processor_root == 7 + collections && r0 == 9 && result_value == 99;
    printf("COLLECTIONS %d ROOTS %d FRAME %d REGISTER %d RA %d RESULT %d\n",
           collections, !bad_roots, processor_frame, processor_root, r0, result_value);
    puts(valid ? "SOURCE-UNIT-OK" : "SOURCE-UNIT-DENY");
    return valid ? 0 : 1;
}
