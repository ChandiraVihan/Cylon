#ifndef TASKS_H 
#define TASKS_H

#include <time.h>
#define MAX_TASKS 1000

/* What command does this task run? */
typedef enum {
    CMD_RUN,
    CMD_MOVE,
    CMD_SEND,
    CMD_GENERATE,
    CMD_EXPORT,
    CMD_NOTIFY
} CommandType;

/* How is it scheduled? */
typedef enum {
    SCHED_NONE,       /* no time schedule — event driven */
    SCHED_INTERVAL,   /* EVERY 5 MINUTES                 */
    SCHED_DAILY,      /* EVERY DAY AT 06:00              */
    SCHED_WEEKLY      /* EVERY WEEK ON MONDAY AT 03:00   */
} ScheduleType;

/* AFTER or BEFORE another task? */
typedef enum {
    DEP_NONE,
    DEP_AFTER,
    DEP_BEFORE
} DepType;

/* IF SUCCESS or IF FAILED? */
typedef enum {
    COND_NONE,
    COND_SUCCESS,
    COND_FAILED
} ConditionType;


typedef struct TASK {

    /* ── Identity ── */
    char name[64];              /* "backupFiles"                          */

    /* ── Command ── */
    CommandType cmd_type;       /* CMD_RUN, CMD_MOVE etc.                 */
    char arg1[256];             /* RUN "script.sh"      → "script.sh"    */
                                /* MOVE "src" TO "dst"  → "src"          */
                                /* SEND "msg" TO "x"    → "msg"          */
                                /* NOTIFY "alert"       → "alert"        */
    char arg2[256];             /* MOVE dst / SEND recipient             */
                                /* empty for single-arg commands         */

    /* ── Schedule ── */
    ScheduleType sched_type;    /* SCHED_NONE / INTERVAL / DAILY / WEEKLY */
    int interval_seconds;       /* EVERY 5 MINUTES → 300                 */
                                /* EVERY 2 HOURS   → 7200                */
                                /* unused for DAILY / WEEKLY             */
    int hour;                   /* EVERY DAY AT 06:00 → 6                */
    int minute;                 /* EVERY DAY AT 06:00 → 0                */
    int weekday;                /* EVERY WEEK ON MONDAY → 1              */
                                /* 0=Sun 1=Mon ... 6=Sat                 */
                                /* unused for DAILY / INTERVAL           */

    /* ── Dependency ── */
    DepType dep_type;           /* DEP_NONE / DEP_AFTER / DEP_BEFORE     */
    char dep_target[64];        /* "cleanupTask" — the task to wait for  */

    /* ── Condition ── */
    ConditionType condition;    /* COND_NONE / COND_SUCCESS / COND_FAILED */

    /* ── Runtime state (scheduler fills these) ── */
    time_t next_run;            /* when to fire next — Unix timestamp    */
    int last_exit_code;         /* 0 = success, non-zero = failed        */
    int enabled;                /* 1 = active, 0 = disabled              */

} Task;

/* ── Shared task list — defined in tasks.c ── */
extern Task tasks[MAX_TASKS];
extern int  task_count;

#endif