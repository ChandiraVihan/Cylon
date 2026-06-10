%{
#include "parser.tab.h"
#include <string.h>
%}

%option yylineno


%%

"TASK"        { return TASK; }
"RUN"         { return RUN; }
"MOVE"        { return MOVE; }
"SEND"        { return SEND; }
"TO"          { return TO; }
"GENERATE"    { return GENERATE; }
"EXPORT"      { return EXPORT; }
"NOTIFY"      { return NOTIFY; }
"ON_FAILURE" { return ON_FAILURE; }
"AFTER"       { return AFTER; }
"BEFORE"      { return BEFORE; }
"IF"          { return IF; }
"SUCCESS"     { return SUCCESS; }
"success"     { return SUCCESS; }
"FAILED"      { return FAILED; }
"failed"      { return FAILED; }
"EVERY"       { return EVERY; }
"DAY"         { return DAY; }
"AT"          { return AT; }
"ON"          { return ON; }
"WEEK"        { return WEEK; }
"SUNDAY"      { return SUNDAY; }
"MONDAY"      { return MONDAY; }
"TUESDAY"     { return TUESDAY; }
"WEDNESDAY"   { return WEDNESDAY; }
"THURSDAY"    { return THURSDAY; }
"FRIDAY"      { return FRIDAY; }
"SATURDAY"    { return SATURDAY; }
"MINUTE"      { return MINUTE; }
"MINUTES"     { return MINUTE; }
"HOUR"        { return HOUR; }
"HOURS"       { return HOUR; }
"SECOND"      { return SECOND; }
"SECONDS"     { return SECOND; }
"{"           { return LBRACE; }
"}"           { return RBRACE; }

[0-9]+       { 
                yylval.num = atoi(yytext); 
                return NUMBER; 
             }

[0-9]{2}":"[0-9]{2} {
                yylval.str = strdup(yytext);
                return TIME;
            }

\"([^\"\n]*)\" {
                yylval.str = strdup(yytext);
                return STRING;
            }

[a-zA-Z][a-zA-Z0-9]* {
                yylval.str = strdup(yytext);
                return IDENTIFIER;
            }

[ \t\n]+      ;   // ignore whitespace

.             { printf("Unknown character: %s\n", yytext); }

%%

int yywrap() {
    
    return 1;
}