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
%token TASK RUN EVERY DAY AT
%token LBRACE RBRACE

%%

Task:
    TASK IDENTIFIER LBRACE RunStmt ScheduleStmt RBRACE
    {
        printf("Parsed TASK: %s\n", $2);
    }
;

RunStmt:
    RUN STRING
    {
    }
;

ScheduleStmt:
    EVERY DAY AT TIME
    {
        printf(" Schedule at: %s\n", $4);
    }
;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main() {
    return yyparse();
}