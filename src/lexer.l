%{
#include "parser.tab.h"
#include <string.h>
%}

%%

"TASK"        { return TASK; }
"RUN"         { return RUN; }
"MOVE"        { return MOVE; }
"SEND"        { return SEND; }
"TO"          { return TO; }
"GENERATE"    { return GENERATE; }
"EXPORT"      { return EXPORT; }
"AFTER"       { return AFTER; }
"BEFORE"      { return BEFORE; }
"IF"          { return IF; }
"SUCCESS"     { return SUCCESS; }
"FAILED"      { return FAILED; }
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

"{"           { return LBRACE; }
"}"           { return RBRACE; }

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