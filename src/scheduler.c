#include <time.h>
#include <stdio.h>
#include "tasks.h"
#include "executor.h"


time_t calculate_next_run(Task *task) {
    time_t now = time(NULL);
    
    switch (task->sched_type) {
        case SCHED_INTERVAL:
            return now + task->interval_seconds;

        case SCHED_DAILY: {
            struct tm *t = localtime(&now);
            t->tm_hour = task->hour;
            t->tm_min  = task->minute;
            t->tm_sec  = 0;
            time_t next = mktime(t);
            if (next <= now) next += 86400; // already passed today, use tomorrow
            return next;
        }

        case SCHED_WEEKLY: {
            struct tm *t = localtime(&now);

            int today = t->tm_wday; // 0=Sun, 1=Mon, ..., 6=Sat
            int target = task->weekday; 
            int days = (target - today + 7) % 7;
            if (days == 0) days =7 ; // if today is the target day, schedule for next week
            t->tm_mday += days;
            t->tm_hour = task->hour;
            t->tm_min  = task->minute;
            t->tm_sec  = 0;

            return mktime(t); // fix overflow
        }
        
        case SCHED_NONE:
            default:
            return 0; 
    }
    
}

init_schedule(){}

scheduler_loop(){

    while(1) {
    time_t now = time(NULL);
    for (int i = 0; i < task_count; i++) {
        if (tasks[i].next_run <= now) {
            execute_task(&tasks[i]);
            tasks[i].next_run = calculate_next_run(&tasks[i]);
        }
    }
    sleep(60000); // tick every minute
}
}

