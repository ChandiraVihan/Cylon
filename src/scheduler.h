#ifndef SCHEDULER_H
#define SCHEDULER_H

#include "tasks.h"

time_t calculate_next_run(Task *task);
void   init_schedule(void);
void   scheduler_loop(void);

#endif