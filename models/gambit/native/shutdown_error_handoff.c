/* Unchanged synchronous-loop body; mocked rendezvous and nonlocal throws.
 * A missing catcher is recorded, not dereferenced to repeat a known crash. */
#include <stdio.h>
#include <stdlib.h>
typedef int ___SCMOBJ;
typedef int ___BOOL;
struct vm { int count; };
typedef struct vm *___virtual_machine_state;
struct processor { int id; struct vm *vm; int intr_flag[1]; void *catcher; };
typedef struct processor *___processor_state;
typedef struct { int op; int arg[2]; } ___sync_op_struct;
static struct { int setup_state; } global;
static int scenario, rounds, executions, throws, invalid, thrown_error;
#define ___GSTATE (&global)
#define ___P(args, old) args
#define ___PSD ___processor_state ___ps,
#define ___PSV ___ps,
#define ___PSDKR
#define ___PSGET
#define ___PSP ___ps,
#define ___FIX(value) (value)
#define ___NO_ERR 0
#define ___INTR_SYNC_OP 0
#define ___VMSTATE_FROM_PSTATE(ps) ((ps)->vm)
#define ___PROCESSOR_ID(ps, vm) ((ps)->id + 0 * (vm)->count)
#define OP_NOOP 0
#define OP_PROCESSOR_0_THROW_ERROR 1
#define OP_OTHER 2
#define COMBINING_OP(op) 0

static int barrier_sync_op(___processor_state ps, ___sync_op_struct *op)
{
    (void)ps;
    if (++rounds > 5) abort();
    op->op = OP_NOOP;
    op->arg[0] = 42;
    if (rounds == 1 && scenario != 3) op->op = scenario == 6 ? OP_OTHER : OP_PROCESSOR_0_THROW_ERROR;
    if (scenario == 7 && rounds == 2) { op->op = OP_PROCESSOR_0_THROW_ERROR; op->arg[0] = 99; }
    return 0;
}

static void execute_sync_op(___processor_state ps, ___sync_op_struct *op)
{
    (void)ps;
    (void)op;
    executions++;
}

static void ___throw_error(___processor_state ps, ___SCMOBJ error)
{
    throws++;
    invalid += ps->catcher == NULL;
    thrown_error = error;
}

#include "sync-source.inc"

int main(int argc, char **argv)
{
    if (argc != 2) return 2;
    scenario = atoi(argv[1]);
    if (scenario < 0 || scenario > 7) return 2;
    struct vm vm = {2};
    int token = 0;
    int has_catcher = scenario != 1 && scenario != 2 && scenario != 3;
    struct processor ps = {scenario == 4 ? 1 : 0, &vm, {1}, has_catcher ? &token : NULL};
    global.setup_state = scenario == 1 || scenario == 3 ? 2 : 1;
    ___sync_op_struct op = {OP_NOOP, {0, 0}};
    execute_sync_op_loop(&ps, &op, scenario != 5);
    printf("{\"rounds\":%d,\"executions\":%d,\"throws\":%d,\"invalid\":%d,\"error\":%d,\"interrupt\":%d}\n",
           rounds, executions, throws, invalid, thrown_error, ps.intr_flag[0]);
    return 0;
}
