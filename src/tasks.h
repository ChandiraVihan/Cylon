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
  
} Task;

#endif