#include "time.h";


while(1) {
    time_t now = time(NULL);
    for (int i = 0; i < task_count; i++) {
        if (tasks[i].next_run <= now) {
            execute_task(&tasks[i]);
            tasks[i].next_run = calculate_next_run(&tasks[i]);
        }
    }
    sleep(60); // tick every minute
}

time_t calculate_next_run(Task *task) {
    time_t now = time(NULL);
    
    if (task->interval_seconds > 0) {
        // EVERY N MINUTES or EVERY N HOURS
        return now + task->interval_seconds;
    }
    
    if (task->schedule_type == EVERY_DAY) {
        // find next occurrence of HH:MM today or tomorrow
        struct tm *t = localtime(&now);
        t->tm_hour = task->hour;
        t->tm_min  = task->minute;
        t->tm_sec  = 0;
        time_t next = mktime(t);
        if (next <= now) next += 86400; // already passed today, use tomorrow
        return next;
    }
    
    if (task->schedule_type == EVERY_WEEK) {
        // find next occurrence of specific weekday + time
        // similar logic but add days until correct weekday
    }
}