%{
#include "parser.tab.h"
#include <string.h>
%}

%%

"TASK"        { return TASK; }
"RUN"         { return RUN; }
"EVERY"       { return EVERY; }
"DAY"         { return DAY; }
"AT"          { return AT; }

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