%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "interpreter.h"
#include "y.tab.h"

extern FILE *yyin;
extern int yylineno;
extern int yylex(void);

extern Expression *create_expression(int num, char *value);
extern Expression *create_expression_with_operator(Expression *left, char *op, Expression *right);
extern void free_expression(Expression *expr);
extern void yyerror(const char *msg);

extern Statement *create_statement(int type, Expression *condition, Statement *body, Statement *next);
extern void free_statement(Statement *stmt);
extern void execute_statement(Statement *stmt);

%}

%union {
    struct Expression *expression;
    struct Statement *statement;
    char *string;
    int num;
}

%token <string> STRING
%token <num> NUMBER
%token <string> NAME
%token END
%token ASSIGN LT GT LE GE EQ NE IF ELSE WHILE PRINT FUNCTION RETURN LPAREN RPAREN COLON COMMA FOR IN PLUS MINUS TIMES DIVIDE RANGE NEWLINE END INDENT DEDENT TAB
%type <expression> expression
%type <statement> statement statements while_statement for_statement 


%%

program : statements
        | /* empty */
        ;

statements : statement NEWLINE
           | statements statement NEWLINE
           ;

statement : assignment
          | while_statement
          | for_statement
          | print_statement
          | if_statement
          | END {printf("END Found");}
          ;

assignment : NAME ASSIGN expression
           {
               printf("Assignment: %s = %d\n", $1, $3->num);
               set_variable($1, $3->num);
               free($1);
               free_expression($3);
           }
           ;

if_statement : IF expression COLON NEWLINE INDENT statements DEDENT END
             {

                 printf("Parsing if statement with condition\n");

                 if (evaluate_expression($2)) {

                     if ($6) {

                         execute_statement($6);

                     } else {

                         printf("Warning: if body is NULL\n");

                     }

                 }

             }
             | IF expression COLON NEWLINE INDENT statements DEDENT ELSE COLON NEWLINE INDENT statements DEDENT END
             {

                 printf("Parsing if-else statement with condition\n");

                 if (evaluate_expression($2)) {

                     if ($6) {

                         execute_statement($6);

                     } else {

                         printf("Warning: if body is NULL\n");

                     }

                 } else {

                     if ($12) {

                         execute_statement($12);

                     } else {

                         printf("Warning: else body is NULL\n");

                     }

                 }

             }
             | IF expression COLON NEWLINE INDENT statements DEDENT ELSE COLON NEWLINE INDENT statements DEDENT if_statement
             {

                 printf("Parsing if-else statement with condition\n");

                 if (evaluate_expression($2)) {

                     if ($6) {

                         execute_statement($6);

                     } else {

                         printf("Warning: if body is NULL\n");

                     }

                 } else {

                     if ($12) {

                         execute_statement($12);

                     } else {

                         printf("Warning: else body is NULL\n");

                     }

                 }

                 // Continue parsing additional else-if or else statements if present
                 execute_statement($12);

             }
             ;


print_statement : PRINT LPAREN STRING RPAREN
                {
                    printf("%s\n", $3);
                    free($3);
                }
                | PRINT LPAREN expression RPAREN
                {
                    printf("%d\n", evaluate_expression($3));
                    free_expression($3);
                }
                ;

while_statement : WHILE expression COLON NEWLINE INDENT statements DEDENT END
                {
                    printf("Parsing while statement with condition\n");
                    $$ = create_statement('W', $2, $6, NULL);
                    execute_statement($$);
                }
                ;

for_statement : FOR NAME IN RANGE LPAREN expression COMMA expression RPAREN COLON NEWLINE INDENT statements DEDENT
               {
                   int start = evaluate_expression($6);
                   int end = evaluate_expression($8);
                   char *loop_variable_name = $2;
                   set_variable(loop_variable_name, start);
                   for (int x = start; x < end; ++x) {
                       set_variable(loop_variable_name, x);
                       execute_statement($13);
                   }
                   free($2);
                   free_expression($6);
                   free_expression($8);
               }
               ;

expression : expression PLUS expression
           {
               printf("Expression: %d + %d\n", $1->num, $3->num);
               $$ = create_expression($1->num + $3->num, NULL);
               free_expression($1);
               free_expression($3);
           }
           | expression MINUS expression
           {
               printf("Expression: %d - %d\n", $1->num, $3->num);
               $$ = create_expression($1->num - $3->num, NULL);
               free_expression($1);
               free_expression($3);
           }
           | expression TIMES expression
           {
               printf("Expression: %d * %d\n", $1->num, $3->num);
               $$ = create_expression($1->num * $3->num, NULL);
               free_expression($1);
               free_expression($3);
           }
           | expression DIVIDE expression
           {
               printf("Expression: %d / %d\n", $1->num, $3->num);
               $$ = create_expression(0, NULL);
               int divisor = $3->num;
               if (divisor == 0) {
                   yyerror("Division by zero");
               } else {
                   $$->num = $1->num / divisor;
               }
               free_expression($1);
               free_expression($3);
           }
           | LPAREN expression RPAREN
           {
               $$ = $2;
           }
           | NAME
           {
               printf("Expression: variable %s\n", $1);
               $$ = create_expression(get_variable($1), NULL);
               free($1);
           }
           | NUMBER
           {
               printf("Expression: number %d\n", $1);
               $$ = create_expression($1, NULL);
           }
           | expression LT expression
           {
               printf("Expression: %d < %d\n", $1->num, $3->num);
               $$ = create_expression_with_operator($1, "<", $3);
           }
           | expression GT expression
           {
               printf("Expression: %d > %d\n", $1->num, $3->num);
               $$ = create_expression_with_operator($1, ">", $3);
           }
           | expression LE expression
           {
               printf("Expression: %d <= %d\n", $1->num, $3->num);
               $$ = create_expression_with_operator($1, "<=", $3);
           }
           | expression GE expression
           {
               printf("Expression: %d >= %d\n", $1->num, $3->num);
               $$ = create_expression_with_operator($1, ">=", $3);
           }
           | expression EQ expression
           {
               printf("Expression: %d == %d\n", $1->num, $3->num);
               $$ = create_expression_with_operator($1, "==", $3);
           }
           | expression NE expression
           {
               printf("Expression: %d != %d\n", $1->num, $3->num);
               $$ = create_expression_with_operator($1, "!=", $3);
           }
           ;

%%
           
      
void yyerror(const char *msg) {
    fprintf(stderr, "Syntax error at line %d: %s\n", yylineno, msg);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s input_file\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    yyin = fopen(argv[1], "r");
    if (!yyin) {
        fprintf(stderr, "Error: Couldn't open input file %s\n", argv[1]);
        exit(EXIT_FAILURE);
    }

    printf("Input file opened successfully\n");

    yyparse();

    fclose(yyin);
    
    free_variables();
    return 0;
}


