%{
#include <stdio.h>
#include <stdlib.h>

void yyerror(const char *s);
int yylex();
%}

%union {
    char* str;
}

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

Task:
    TASK IDENTIFIER LBRACE Command TaskBodyOpt RBRACE
    {
        printf("Executing TASK: %s\n", $2);
    }
;
    
TaskBodyOpt: 
     TaskBody | /* empty */;

TaskBody:
     ScheduleOpt DependencyOpt ConditionOpt;

ScheduleOpt:
     ScheduleStmt | /* empty */;
     

DependencyOpt:    
     Dependency | /* empty */;
      
      
ConditionOpt:     
     Condition | /* empty */;

Command:
     RunCmd | MoveCmd | GenerateCmd | ExportCmd | SendCmd;


RunCmd:
     RUN STRING;


MoveCmd:
     MOVE STRING TO STRING;


SendCmd:
     SEND STRING TO STRING;


GenerateCmd:
     GENERATE STRING;


ExportCmd:
     EXPORT STRING;


Dependency:
     AFTER IDENTIFIER | BEFORE IDENTIFIER;


Condition:
     IF ConditionType;


ConditionType:
     SUCCESS | FAILED;


ScheduleStmt:
     ScheduleTime AT TIME;

    
ScheduleTime:
     EVERY DAY | EVERY WEEK ON DayOfWeek;


DayOfWeek:
     SUNDAY | MONDAY | TUESDAY | WEDNESDAY | THURSDAY | FRIDAY | SATURDAY;
        
%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main() {
    printf("--- Execution START ---");
    return yyparse();
}