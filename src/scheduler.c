#include <time.h>
#include <stdio.h>
#include "tasks.h"
#include "executor.h"
#include "scheduler.h"

#ifdef _WIN32
    #include <windows.h>
    #define SLEEP() Sleep(60000)   // milliseconds
#else
    #include <unistd.h>
    #define SLEEP() sleep(60)      // seconds
#endif

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

void init_schedule(){
    printf("\n[SCHED] Initialising schedule...\n");
    for (int i = 0; i < task_count; i++) {
        if (tasks[i].sched_type != SCHED_NONE) {
            tasks[i].next_run = calculate_next_run(&tasks[i]);
            printf("[SCHED] Task '%s' first run at: %s",
                   tasks[i].name, ctime(&tasks[i].next_run));
        }
    }
}

void scheduler_loop(){

    while(1) {
    time_t now = time(NULL);
    for (int i = 0; i < task_count; i++) {

    // skip event-driven tasks 
        if (tasks[i].sched_type == SCHED_NONE) continue;

    // skip disabled tasks
        if (!tasks[i].enabled) continue;

        if (tasks[i].next_run <= now) {
            printf("[SCHED] Executing task: %s\n", tasks[i].name);
            execute_task(&tasks[i]);
            tasks[i].next_run = calculate_next_run(&tasks[i]);
            printf("[SCHED] Next run at: %s", ctime(&tasks[i].next_run));
        }
    }
    sleep(); // tick every minute
}

}

