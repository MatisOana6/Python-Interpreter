#ifndef INTERPRETER_H
#define INTERPRETER_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct Expression {
    int num;
    char *name;
} Expression;

typedef struct Statement {
    char type;
    Expression *condition;
    struct Statement *body;
    struct Statement *next;
} Statement;

Expression* create_expression(int num, char *value);
Expression* create_expression_with_operator(Expression *left, char *op, Expression *right);
void free_expression(Expression *expr);
void yyerror(const char *msg);

Statement* create_statement(int type, Expression *condition, Statement *body, Statement *next);
void free_statement(Statement *stmt);
void execute_statement(Statement *stmt);

void set_variable(char *name, int value);
int get_variable(char *name);
int evaluate_expression(Expression *expr);
void free_variables();
#endif

