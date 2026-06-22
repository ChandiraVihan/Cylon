%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "executor.h"
#include "tasks.h"

/* ── Per-task globals — reset after each TASK block ── */
CommandType  g_cmd_type          = CMD_RUN;
char         g_arg1[256]         = {0};
char         g_arg2[256]         = {0};
ScheduleType g_sched_type        = SCHED_NONE;
int          g_interval_seconds  = 0;
int          g_hour              = 0;
int          g_minute            = 0;
int          g_weekday           = 0;
DepType      g_dep_type          = DEP_NONE;
char         g_dep_target[64]    = {0};
ConditionType g_condition_type   = COND_NONE;


/* ── Reset all globals for next task ── */
void reset_globals() {
    g_cmd_type         = CMD_RUN;
    g_arg1[0]          = '\0';
    g_arg2[0]          = '\0';
    g_sched_type       = SCHED_NONE;
    g_interval_seconds = 0;
    g_hour             = 0;
    g_minute           = 0;
    g_weekday          = 0;
    g_dep_type         = DEP_NONE;
    g_dep_target[0]    = '\0';
    g_condition_type   = COND_NONE;
}


/* ── Duplicate check — reads from tasks[] ── */
int is_duplicate(char *name) {
    for (int i = 0; i < task_count; i++)
        if (strcmp(tasks[i].name, name) == 0) return 1;
    return 0;
}


/* ── Find task index by name, -1 if not found ── */
int find_task(char *name) {
    for (int i = 0; i < task_count; i++)
        if (strcmp(tasks[i].name, name) == 0) return i;
    return -1;
}


/* ── DFS cycle detection ──
   visited: 0 = unvisited, 1 = in current path, 2 = fully processed */
int dfs(int node, int *visited) {
    if (visited[node] == 1) return 1;   /* back edge = cycle      */
    if (visited[node] == 2) return 0;   /* already fully processed */

    visited[node] = 1;

    if (tasks[node].dep_target[0] != '\0') {
        int dep = find_task(tasks[node].dep_target);
        if (dep >= 0 && dfs(dep, visited)) return 1;
    }

    visited[node] = 2;
    return 0;
}


/* ── Run cycle check across all tasks ── */
void check_circular_dependencies() {
    int visited[MAX_TASKS] = {0};
    for (int i = 0; i < task_count; i++) {
        if (visited[i] == 0) {
            int v[MAX_TASKS] = {0};
            if (dfs(i, v)) {
                fprintf(stderr, "\nERROR: Circular dependency detected involving task '%s'\n",
                        tasks[i].name);
                exit(1);
            }
            for (int j = 0; j < task_count; j++)
                if (v[j] == 2) visited[j] = 2;
        }
    }
}


extern int  yylineno;
extern FILE *yyin;
void run_interactive(void);
void yyerror(const char *s);
int  yylex(void);

/* Strip surrounding double-quotes from a lexer STRING token */
char *strip_quotes(const char *s) {
    if (!s) return NULL;
    size_t len = strlen(s);
    if (len >= 2 && s[0] == '"' && s[len-1] == '"') {
        char *out = strdup(s + 1);
        out[len - 2] = '\0';
        return out;
    }
    return strdup(s);
}
%}

/* ── Value types ── */
%union {
    char *str;
    int   num;
}

/* ── Non-terminal types ── */
%type <str> Command
%type <str> RunCmd
%type <str> MoveCmd
%type <str> SendCmd
%type <str> GenerateCmd
%type <str> ExportCmd
%type <str> NotifyCmd
%type <num> DayOfWeek
%type <num> frequencyUnit

/* ── Tokens ── */
%token <str> IDENTIFIER STRING TIME
%token <num> NUMBER
%token TASK
%token RUN
%token EVERY DAY WEEK AT ON
%token MOVE SEND TO
%token GENERATE EXPORT NOTIFY
%token AFTER BEFORE
%token IF SUCCESS FAILED
%token SUNDAY MONDAY TUESDAY WEDNESDAY THURSDAY FRIDAY SATURDAY
%token ON_FAILURE
%token HOUR MINUTE SECOND
%token LBRACE RBRACE

%%

/* ════════════════════════════════════════════════
   Top level
   ════════════════════════════════════════════════ */

cylon:
    task_list
    {
        check_circular_dependencies();
    }
;

task_list:
    Task
    | task_list Task
;


/* ════════════════════════════════════════════════
   Task block — parse into tasks[] struct
   ════════════════════════════════════════════════ */

Task:
    TASK IDENTIFIER LBRACE Command TaskBodyOpt RBRACE
    {
        /* ── Semantic checks ── */
        if (is_duplicate($2)) {
            fprintf(stderr, "SEMANTIC ERROR at line %d: Duplicate task name '%s'\n",
                    yylineno, $2);
            exit(1);
        }

        if (g_dep_target[0] != '\0' && find_task(g_dep_target) < 0) {
            fprintf(stderr,
                    "SEMANTIC ERROR at line %d: Task '%s' depends on undefined task '%s'\n",
                    yylineno, $2, g_dep_target);
            exit(1);
        }

        /* ── Store into shared task list ── */
        Task *t = &tasks[task_count];

        strncpy(t->name, $2, sizeof(t->name) - 1);

        t->cmd_type = g_cmd_type;
        strncpy(t->arg1, g_arg1, sizeof(t->arg1) - 1);
        strncpy(t->arg2, g_arg2, sizeof(t->arg2) - 1);

        t->sched_type        = g_sched_type;
        t->interval_seconds  = g_interval_seconds;
        t->hour              = g_hour;
        t->minute            = g_minute;
        t->weekday           = g_weekday;

        t->dep_type = g_dep_type;
        strncpy(t->dep_target, g_dep_target, sizeof(t->dep_target) - 1);

        t->condition      = g_condition_type;
        t->enabled        = 1;
        t->last_exit_code = -1;
        t->next_run       = 0;   /* scheduler will set this in init_schedule() */

        task_count++;

        /* ── Debug print ── */
        printf("\n[PARSED] Task: %s\n", t->name);
        printf("  Command : %d  arg1='%s'  arg2='%s'\n",
               t->cmd_type, t->arg1, t->arg2);
        if (t->sched_type != SCHED_NONE)
            printf("  Schedule: type=%d interval=%d h=%d m=%d wday=%d\n",
                   t->sched_type, t->interval_seconds,
                   t->hour, t->minute, t->weekday);
        if (t->dep_type != DEP_NONE)
            printf("  Depends : %s\n", t->dep_target);
        if (t->condition != COND_NONE)
            printf("  Condition: %d\n", t->condition);

        reset_globals();
        free($2);
    }
;


/* ════════════════════════════════════════════════
   Task body — schedule / dependency / condition
   ════════════════════════════════════════════════ */

TaskBodyOpt:
    %empty
    | TaskBodyOpt TaskBody
;

TaskBody:
    ScheduleStmt
    | Dependency
    | Condition
;


/* ════════════════════════════════════════════════
   Commands — set g_cmd_type + g_arg1/g_arg2
   ════════════════════════════════════════════════ */

Command:
    RunCmd      { $$ = $1; }
    | MoveCmd   { $$ = $1; }
    | SendCmd   { $$ = $1; }
    | GenerateCmd { $$ = $1; }
    | ExportCmd { $$ = $1; }
    | NotifyCmd { $$ = $1; }
;

RunCmd:
    RUN STRING
    {
        g_cmd_type = CMD_RUN;
        char *s = strip_quotes($2);
        strncpy(g_arg1, s, sizeof(g_arg1) - 1);
        free(s);
        $$ = $2;
    }
;

MoveCmd:
    MOVE STRING TO STRING
    {
        g_cmd_type = CMD_MOVE;
        char *s = strip_quotes($2);
        char *d = strip_quotes($4);
        strncpy(g_arg1, s, sizeof(g_arg1) - 1);
        strncpy(g_arg2, d, sizeof(g_arg2) - 1);
        free(s); free(d);
        $$ = $2;
    }
;

SendCmd:
    SEND STRING TO STRING
    {
        g_cmd_type = CMD_SEND;
        char *s = strip_quotes($2);
        char *d = strip_quotes($4);
        strncpy(g_arg1, s, sizeof(g_arg1) - 1);
        strncpy(g_arg2, d, sizeof(g_arg2) - 1);
        free(s); free(d);
        $$ = $2;
    }
;

GenerateCmd:
    GENERATE STRING
    {
        g_cmd_type = CMD_GENERATE;
        char *s = strip_quotes($2);
        strncpy(g_arg1, s, sizeof(g_arg1) - 1);
        free(s);
        $$ = $2;
    }
;

ExportCmd:
    EXPORT STRING
    {
        g_cmd_type = CMD_EXPORT;
        char *s = strip_quotes($2);
        strncpy(g_arg1, s, sizeof(g_arg1) - 1);
        free(s);
        $$ = $2;
    }
;

NotifyCmd:
    NOTIFY STRING
    {
        g_cmd_type = CMD_NOTIFY;
        char *s = strip_quotes($2);
        strncpy(g_arg1, s, sizeof(g_arg1) - 1);
        free(s);
        $$ = $2;
    }
;


/* ════════════════════════════════════════════════
   Dependency
   ════════════════════════════════════════════════ */

Dependency:
    AFTER IDENTIFIER
    {
        g_dep_type = DEP_AFTER;
        strncpy(g_dep_target, $2, sizeof(g_dep_target) - 1);
        free($2);
    }
    | BEFORE IDENTIFIER
    {
        g_dep_type = DEP_BEFORE;
        strncpy(g_dep_target, $2, sizeof(g_dep_target) - 1);
        free($2);
    }
;


/* ════════════════════════════════════════════════
   Condition
   ════════════════════════════════════════════════ */

Condition:
    IF SUCCESS { g_condition_type = COND_SUCCESS; }
    | IF FAILED { g_condition_type = COND_FAILED; }
;


/* ════════════════════════════════════════════════
   Schedule
   ════════════════════════════════════════════════ */

ScheduleStmt:
    /* EVERY DAY AT 06:00 */
    EVERY DAY AT TIME
    {
        g_sched_type = SCHED_DAILY;
        sscanf($4, "%d:%d", &g_hour, &g_minute);
        free($4);
    }

    /* EVERY WEEK ON MONDAY AT 03:00 */
    | EVERY WEEK ON DayOfWeek AT TIME
    {
        g_sched_type = SCHED_WEEKLY;
        g_weekday    = $4;
        sscanf($6, "%d:%d", &g_hour, &g_minute);
        free($6);
    }

    /* EVERY 5 MINUTES / EVERY 2 HOURS / EVERY 30 SECONDS */
    | EVERY NUMBER frequencyUnit
    {
        g_sched_type       = SCHED_INTERVAL;
        g_interval_seconds = $2 * $3;
    }

    /* EVERY MINUTE / EVERY HOUR (no number) */
    | EVERY frequencyUnit
    {
        g_sched_type       = SCHED_INTERVAL;
        g_interval_seconds = $2;   /* frequencyUnit returns base seconds */
    }
;


/* Returns weekday as int: 0=Sun, 1=Mon … 6=Sat */
DayOfWeek:
    SUNDAY    { $$ = 0; }
    | MONDAY  { $$ = 1; }
    | TUESDAY { $$ = 2; }
    | WEDNESDAY { $$ = 3; }
    | THURSDAY  { $$ = 4; }
    | FRIDAY    { $$ = 5; }
    | SATURDAY  { $$ = 6; }
;

/* Returns base seconds for one unit */
frequencyUnit:
    SECOND  { $$ = 1;    }
    | MINUTE { $$ = 60;   }
    | HOUR   { $$ = 3600; }
;

%%

/* ════════════════════════════════════════════════
   Error handler
   ════════════════════════════════════════════════ */

void yyerror(const char *s) {
    fprintf(stderr, "Syntax error at line %d: %s\n", yylineno, s);
}


/* ════════════════════════════════════════════════
   Entry point
   ════════════════════════════════════════════════ */

int main(int argc, char **argv) {

    /* Interactive mode */
    if (argc == 1) {
        run_interactive();
        return 0;
    }

    /* File mode */
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            fprintf(stderr, "ERROR: Could not open file '%s'\n", argv[1]);
            return 1;
        }
    }

    printf("\n");
    printf(" ██████╗██╗   ██╗██╗      ██████╗ ███╗   ██╗\n");
    printf("██╔════╝╚██╗ ██╔╝██║     ██╔═══██╗████╗  ██║\n");
    printf("██║      ╚████╔╝ ██║     ██║   ██║██╔██╗ ██║\n");
    printf("██║       ╚██╔╝  ██║     ██║   ██║██║╚██╗██║\n");
    printf("╚██████╗   ██║   ███████╗╚██████╔╝██║ ╚████║\n");
    printf(" ╚═════╝   ╚═╝   ╚══════╝ ╚═════╝ ╚═╝  ╚═══╝\n\n");
    printf("Parsing Cylon input...\n\n");
    printf("--- PARSE START ---\n");

    int result = yyparse();

    if (argc == 2 && yyin) fclose(yyin);

    if (result == 0) {
        printf("\n--- PARSE COMPLETE — %d task(s) loaded ---\n", task_count);
        /* TODO: hand off to scheduler here
           init_schedule();
           scheduler_loop();
        */
    } else {
        printf("\n--- PARSE FAILED ---\n");
    }

    return result;
}
