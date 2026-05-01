%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


char* g_schedule = NULL;
char* g_dependency = NULL;
char* g_condition = NULL;


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
        printf("Executing Task: %s\n", $2);
        printf("  Script: %s\n", $4);
        if(g_schedule)  printf("  Schedule: %s\n", g_schedule);
        if(g_dependency) printf("  Depends on: %s\n", g_dependency);
        if(g_condition)  printf("  Condition: %s\n", g_condition);
        g_schedule = NULL;
        g_dependency = NULL;
        g_condition = NULL;
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


RunCmd:
    RUN STRING { $$ = $2; }
;


MoveCmd:
    MOVE STRING TO STRING 
    { 
        char buf[200];
        sprintf(buf, "%s TO %s", $2, $4);
        $$ = strdup(buf);
    }
;


SendCmd:
    SEND STRING TO STRING 
    { 
        char buf[200];
        sprintf(buf, "%s TO %s", $2, $4);
        $$ = strdup(buf);
    }
;


GenerateCmd:
    GENERATE STRING { $$ = $2; }
;


ExportCmd:
    EXPORT STRING { $$ = $2; }
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
    }
;

    
ScheduleTime:
    EVERY DAY        { $$ = "EVERY DAY"; }
    | EVERY WEEK ON DayOfWeek { $$ = "EVERY WEEK ON ..."; }
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