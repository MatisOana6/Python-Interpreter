%{
#include "y.tab.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

int indent_level = 0;
int prev_indent = 0;
int num_dedents = 0;

char *my_strndup(const char *s, size_t n) {
    char *p = (char*)malloc(n + 1);
    if (p) {
        strncpy(p, s, n);
        p[n] = '\0';
    }
    return p;
}
%}

%%

[ \t]       { /* ignore leading whitespace */ }

\n           { yylineno++; return NEWLINE; }

"\""[^\"\\]*"\"" {
    yylval.string = my_strndup(yytext + 1, yyleng - 2); // remove the surrounding quotes
    return STRING;
}

^([ \t]+)    {
    int indent = strlen(yytext);
    if (indent > prev_indent) {
        prev_indent = indent;
        indent_level++;
        return INDENT;
    } else if (indent < prev_indent) {
        num_dedents = (prev_indent - indent) / 4;
        prev_indent = indent;
        if (num_dedents > 0) {
            num_dedents--;
            unput('\n');
            return DEDENT;
        }
    }
}

"=="         { return EQ; }
"!="         { return NE; }
"<="         { return LE; }
">="         { return GE; }
"<"          { return LT; }
">"          { return GT; }
"="          { return ASSIGN; }
"end"        { return END; }
"for"        { return FOR; }
"if"         { return IF; }
"else"       { return ELSE; }
"while"      { return WHILE; }
"print"      { return PRINT; }
"def"        { return FUNCTION; }
"return"     { return RETURN; }
"("          { return LPAREN; }
")"          { return RPAREN; }
":"          { return COLON; }
","          { return COMMA; }
"in"         { return IN; }
"range"      { return RANGE; }

[a-zA-Z_][a-zA-Z0-9_]* { yylval.string = strdup(yytext); return NAME; }
[0-9]+      { yylval.num = atoi(yytext); return NUMBER; }
.           { return yytext[0]; }

%%

int yywrap() {
    return 1;
}

