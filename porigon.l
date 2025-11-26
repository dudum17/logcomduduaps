%{
#include "porigon.tab.h"
#include <stdlib.h>
#include <stdio.h>
%}

DIGIT   [0-9]
NUMBER  {DIGIT}+

%%

"pick"          { return PICK; }
"start"         { return START; }
"end"           { return END; }

"if"            { return IF; }
"else"          { return ELSE; }
"while"         { return WHILE; }

"special"       { return SPECIAL; }
"normal"        { return NORMAL; }
"cure"          { return CURE; }

"life"          { return LIFE; }
"attack"        { return ATTACK; }
"enemy_life"    { return ENEMY_LIFE; }
"enemy_attack"  { return ENEMY_ATTACK; }

">="            { return GEQ; }
"<="            { return LEQ; }
">"             { return GT; }
"<"             { return LT; }
"="             { return EQ; }

":"             { return COLON; }

{NUMBER}        { yylval.ival = atoi(yytext); return NUMBER; }

[ \t\r\n]+      { /* ignora espaços */ }

.               { fprintf(stderr, "Caracter inesperado: %s\n", yytext); }

%%

int yywrap(void) { return 1; }
