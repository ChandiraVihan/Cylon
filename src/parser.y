%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ── Task registry ── */
#define MAX_TASKS 100

char* g_schedule = NULL;
char* g_dependency = NULL;
char* g_condition = NULL;
char* g_cmd_label  = "Script";


/* Store every task name and its dependency */
char* task_names[MAX_TASKS];
char* task_deps[MAX_TASKS];   /* task_deps[i] = what task_names[i] depends on, or NULL */
int   task_count = 0;


/* ── Duplicate check ── */
int is_duplicate(char* name) {
    for (int i = 0; i < task_count; i++)
        if (strcmp(task_names[i], name) == 0) return 1;
    return 0;
}


/* ── Find index of a task by name, -1 if not found ── */
int find_task(char* name) {
    for (int i = 0; i < task_count; i++)
        if (strcmp(task_names[i], name) == 0) return i;
    return -1;
}


/* ── DFS cycle detection ──
   visited: 0 = unvisited, 1 = in current path, 2 = fully processed */
int dfs(int node, int* visited) {
    if (visited[node] == 1) return 1;   /* back edge = cycle */
    if (visited[node] == 2) return 0;   /* already safe */

    visited[node] = 1;

    if (task_deps[node] != NULL) {
        int dep = find_task(task_deps[node]);
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
            /* reset in-path markers before each DFS start */
            int v[MAX_TASKS] = {0};
            if (dfs(i, v)) {
                fprintf(stderr, "\nERROR: Circular dependency detected involving task '%s'\n", task_names[i]);
                exit(1);
            }
            /* merge visited info */
            for (int j = 0; j < task_count; j++)
                if (v[j] == 2) visited[j] = 2;
        }
    }
}


extern int yylineno;
extern FILE *yyin;
void run_interactive(void); 
void yyerror(const char *s);
int yylex();
%}

%union {
    char* str;
    int num;
}

%type <str> Command
%type <str> RunCmd
%type <str> MoveCmd
%type <str> SendCmd
%type <str> GenerateCmd
%type <str> ExportCmd
%type <str> NotifyCmd
%type <str> ScheduleStmt
%type <str> ScheduleTime
%type <str> ConditionType
%type <str> DayOfWeek
%type <str> frequencyUnit

%token <str> IDENTIFIER STRING TIME
%token <num> NUMBER
%token TASK
%token RUN 
%token EVERY
%token DAY
%token AT
%token ON
%token MOVE
%token SEND
%token TO
%token GENERATE
%token EXPORT
%token NOTIFY
%token AFTER
%token BEFORE
%token IF
%token SUCCESS
%token FAILED
%token WEEK
%token SUNDAY
%token MONDAY
%token TUESDAY
%token WEDNESDAY
%token THURSDAY
%token FRIDAY
%token SATURDAY
%token ON_FAILURE
%token HOUR
%token MINUTE
%token SECOND
%token LBRACE RBRACE

%% 

cylon:
    task_list
    {
        /* After all tasks parsed - run all semantic checks */
        check_circular_dependencies();
    }
;

task_list:
     Task |
     task_list Task
;


Task:
    TASK IDENTIFIER LBRACE Command TaskBodyOpt RBRACE
    {
        /* Duplicate task name check */
        if (is_duplicate($2)) {
            fprintf(stderr, "SEMANTIC ERROR at line %d: Duplicate task name '%s'\n", yylineno, $2);
            exit(1);
        }

        /* Undefined dependency check */
        if (g_dependency != NULL && find_task(g_dependency) < 0) {
            fprintf(stderr, "SEMANTIC ERROR at line %d: Task '%s' depends on undefined task '%s'\n", yylineno, $2, g_dependency);
            exit(1);
        }

        /* Register task in table */
        task_names[task_count] = strdup($2);
        task_deps[task_count]  = g_dependency ? strdup(g_dependency) : NULL;
        task_count++;

        /* Print execution details */
        printf("\nExecuting Task: %s\n", $2);
        printf("  %s: %s\n", g_cmd_label, $4);
        if (g_schedule)   printf("  Schedule: %s\n",   g_schedule);
        if (g_dependency) printf("  Depends on: %s\n", g_dependency);
        if (g_condition)  printf("  Condition: %s\n",  g_condition);

        /* Reset globals for next task */
        g_schedule   = NULL;
        g_dependency = NULL;
        g_condition  = NULL;
        g_cmd_label  = "Script";
    }
;


 TaskBodyOpt:
    %empty
    | TaskBodyOpt TaskBody
;


TaskBody:
    ScheduleStmt
    | Dependency
    | Condition
;


Command:
    RunCmd    { $$ = $1; }
    | MoveCmd    { $$ = $1; }
    | GenerateCmd { $$ = $1; }
    | ExportCmd  { $$ = $1; }
    | SendCmd    { $$ = $1; }
    | NotifyCmd  { $$ = $1; }
;


/* Script Execution — RUN "script.py" */
RunCmd:
    RUN STRING
    {
        g_cmd_label = "RUN";
        $$ = $2;
    }
;


/* File Transfer — MOVE "src" TO "dest" */
MoveCmd:
    MOVE STRING TO STRING
    {
        g_cmd_label = "Move";
        char buf[300];
        sprintf(buf, "%s TO %s", $2, $4);
        $$ = strdup(buf);
    }
;


/* Email Notification — SEND "msg" TO "recipient" */
SendCmd:
    SEND STRING TO STRING
    {
        g_cmd_label = "Send";
        char buf[300];
        sprintf(buf, "%s TO %s", $2, $4);
        $$ = strdup(buf);
    }
;


/* Report Generation — GENERATE "report.pdf" */
GenerateCmd:
    GENERATE STRING
    {
        g_cmd_label = "Generate";
        $$ = $2;
    }
;


/* Data Export — EXPORT "output.csv" */
ExportCmd:
    EXPORT STRING
    {
        g_cmd_label = "Export";
        $$ = $2;
    }
;

/* Notify User — NOTIFY "message" */
NotifyCmd:
    NOTIFY STRING
    {
        g_cmd_label = "Notify";
        $$ = $2;
    }
;


Dependency:
    AFTER IDENTIFIER  { g_dependency = strdup($2); }
    | BEFORE IDENTIFIER { g_dependency = strdup($2); }
;


Condition:
    IF ConditionType { g_condition = strdup($2); }
;


ConditionType:
    SUCCESS  { $$ = "success"; }
    | FAILED { $$ = "failed"; }
;

ScheduleStmt:
    ScheduleTime AT TIME
    {
        char buf[100];
        sprintf(buf, "%s AT %s", $1, $3);
        g_schedule = strdup(buf);
        free($1);
    }
    | EVERY NUMBER frequencyUnit
    {
        char buf[100];
        sprintf(buf, "EVERY %d %s", $2, $3);
        g_schedule = strdup(buf);
    }

;


DayOfWeek:
    SUNDAY    { $$ = "SUNDAY"; }
    | MONDAY  { $$ = "MONDAY"; }
    | TUESDAY { $$ = "TUESDAY"; }
    | WEDNESDAY { $$ = "WEDNESDAY"; }
    | THURSDAY  { $$ = "THURSDAY"; }
    | FRIDAY    { $$ = "FRIDAY"; }
    | SATURDAY  { $$ = "SATURDAY"; }
;

frequencyUnit:
    MINUTE  { $$ = "MINUTE(S)"; }
    | HOUR   { $$ = "HOUR(S)"; }
    | SECOND { $$ = "SECOND(S)"; }


ScheduleTime:
    EVERY DAY        
    { 
        $$ = strdup("EVERY DAY"); 
    }
    | EVERY WEEK ON DayOfWeek 
    { 
        char buf[100];
        sprintf(buf, "EVERY WEEK ON %s", $4);
        $$ = strdup(buf); 
    }
;

//needs to be changed according to the new phrase plan 
      
%%


void yyerror(const char *s) {
    fprintf(stderr, "Syntax error at line %d: %s\n", yylineno, s);
}


int main(int argc, char **argv) {

    /* Interactive mode — no arguments */
    if (argc == 1) {
        run_interactive();
        return 0;
    }

    /* File mode — only prints banner here */
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
        if (yyin == NULL) {
            fprintf(stderr, "ERROR: Could not open file '%s'\n", argv[1]);
            return 1;
        }
    }

    /* Banner and parsing output only for file mode */
    printf("\n");
    printf(" ██████╗██╗   ██╗██╗      ██████╗ ███╗   ██╗\n");
    printf("██╔════╝╚██╗ ██╔╝██║     ██╔═══██╗████╗  ██║\n");
    printf("██║      ╚████╔╝ ██║     ██║   ██║██╔██╗ ██║\n");
    printf("██║       ╚██╔╝  ██║     ██║   ██║██║╚██╗██║\n");
    printf("╚██████╗   ██║   ███████╗╚██████╔╝██║ ╚████║\n");
    printf(" ╚═════╝   ╚═╝   ╚══════╝ ╚═════╝ ╚═╝  ╚═══╝\n\n");
    printf("Parsing TaskLang++ input...\n\n");
    printf("--- EXECUTION START ---\n");

    int result = yyparse();

    if (argc == 2 && yyin != NULL) fclose(yyin);

    if (result == 0) {
        printf("\n--- EXECUTION COMPLETE ---\n");
    } else {
        printf("\n--- EXECUTION FAILED ---\n");
    }
    return result;
}