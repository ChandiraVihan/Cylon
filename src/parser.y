%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

char* g_schedule = NULL;
char* g_dependency = NULL;
char* g_condition = NULL;
char* g_cmd_label  = "Script";
char* task_names[100]; 
int task_count = 0;

// Function to check if a name already exists
bool is_duplicate(char* name) {
    for (int i = 0; i < task_count; i++) {
        if (strcmp(task_names[i], name) == 0) return true;
    }
    return false;
}

// Function to check if a dependency target was ever defined
bool is_defined(char* name) {
    for (int i = 0; i < task_count; i++) {
        if (strcmp(task_names[i], name) == 0) return true;
    }
    return false;
}

void yyerror(const char *s);
int yylex();
%}

%union {
    char* str;

}

%type <str> Command
%type <str> RunCmd
%type <str> MoveCmd
%type <str> SendCmd
%type <str> GenerateCmd
%type <str> ExportCmd
%type <str> ScheduleStmt
%type <str> ScheduleTime
%type <str> ConditionType
%type <str> DayOfWeek

%token <str> IDENTIFIER STRING TIME
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
%token LBRACE RBRACE



%% 

cylon:
    task_list
;

task_list:
     Task |
     task_list Task
;


Task:
    TASK IDENTIFIER LBRACE Command TaskBodyOpt RBRACE
    {
         if (is_duplicate($2)) {
            fprintf(stderr, "SEMANTIC ERROR: Duplicate task name '%s' found.\n", $2);
        } else {
            
            task_names[task_count++] = strdup($2);

        
            if (g_dependency && !is_defined(g_dependency)) {
                fprintf(stderr, "SEMANTIC ERROR: Task '%s' depends on undefined task '%s'.\n", $2, g_dependency);
            }

        printf("\nExecuting Task: %s\n", $2);
        printf("  %s: %s\n", g_cmd_label, $4);
        if(g_schedule)  printf("  Schedule: %s\n", g_schedule);
        if(g_dependency) printf("  Depends on: %s\n", g_dependency);
        if(g_condition)  printf("  Condition: %s\n", g_condition);
        }
        g_schedule = NULL;
        g_dependency = NULL;
        g_condition = NULL;
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

      
%%


void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main() {
    printf("\n");
    printf(
        " ██████╗██╗   ██╗██╗      ██████╗ ███╗   ██╗\n"
        "██╔════╝╚██╗ ██╔╝██║     ██╔═══██╗████╗  ██║\n"
        "██║      ╚████╔╝ ██║     ██║   ██║██╔██╗ ██║\n"
        "██║       ╚██╔╝  ██║     ██║   ██║██║╚██╗██║\n"
        "╚██████╗   ██║   ███████╗╚██████╔╝██║ ╚████║\n"
        " ╚═════╝   ╚═╝   ╚══════╝ ╚═════╝ ╚═╝  ╚═══╝\n\n"
    );
    

    printf("Parsing TaskLang++ input...\n\n");
    printf("--- EXECUTION START ---\n");
    int result = yyparse();
    


    if (result == 0) {
        printf("\n--- EXECUTION COMPLETE ---\n");
    } else {
        printf("\n--- EXECUTION FAILED ---\n");
    }
    return result;
}