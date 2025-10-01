#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "interpreter.h"

#define MAX_VARIABLES 100

typedef struct {
    char *name;
    int value;
} Variable;

Variable variables[MAX_VARIABLES];
int variable_count = 0;

Expression* create_expression(int num, char *value) {
    Expression *expr = (Expression*)malloc(sizeof(Expression));
    expr->num = num;
    expr->name = value ? strdup(value) : NULL;
    return expr;
}

Expression* create_expression_with_operator(Expression *left, char *op, Expression *right) {
    int result;
    if (strcmp(op, "+") == 0) {
        result = left->num + right->num;
    } else if (strcmp(op, "-") == 0) {
        result = left->num - right->num;
    } else if (strcmp(op, "*") == 0) {
        result = left->num * right->num;
    } else if (strcmp(op, "/") == 0) {
        if (right->num == 0) {
            yyerror("Division by zero");
            return NULL;
        }
        result = left->num / right->num;
    } else if (strcmp(op, "<") == 0) {
        result = left->num < right->num;
    } else if (strcmp(op, ">") == 0) {
        result = left->num > right->num;
    } else if (strcmp(op, "<=") == 0) {
        result = left->num <= right->num;
    } else if (strcmp(op, ">=") == 0) {
        result = left->num >= right->num;
    } else if (strcmp(op, "==") == 0) {
        result = left->num == right->num;
    } else if (strcmp(op, "!=") == 0) {
        result = left->num != right->num;
    } else {
        yyerror("Unknown operator");
        return NULL;
    }
    free_expression(left);
    free_expression(right);
    return create_expression(result, NULL);
}


void free_expression(Expression *expr) {
    if (expr) {
        if (expr->name) free(expr->name);
        free(expr);
    }
}

Statement* create_statement(int type, Expression *condition, Statement *body, Statement *next) {
    Statement *stmt = (Statement*)malloc(sizeof(Statement));
    stmt->type = type;
    stmt->condition = condition;
    stmt->body = body;
    stmt->next = next;
    return stmt;
}

void free_statement(Statement *stmt) {
    if (stmt) {
        if (stmt->condition) free_expression(stmt->condition);
        if (stmt->body) free_statement(stmt->body);
        if (stmt->next) free_statement(stmt->next);
        free(stmt);
    }
}


void execute_statement(Statement *stmt) {
    if (!stmt) return;

    switch (stmt->type) {
        case 'A': // Assignment
            set_variable(stmt->condition->name, evaluate_expression(stmt->condition));
            break;

        case 'P': // Print
            printf("%d\n", evaluate_expression(stmt->condition));
            break;

        case 'I': // If
            if (evaluate_expression(stmt->condition)) {
                execute_statement(stmt->body);
            } else if (stmt->next) {
                execute_statement(stmt->next);
            }
            break;

        case 'W': // While
            while (evaluate_expression(stmt->condition)) {
                execute_statement(stmt->body);
            }
            break;

        case 'F': // For
        {
            int start = evaluate_expression(stmt->condition);
            int end = evaluate_expression(stmt->next->condition); // Accesăm condiția pentru a obține sfârșitul intervalului
            char *loop_variable_name = stmt->condition->name;
            for (int i = start; i < end; i++) {
                set_variable(loop_variable_name, i);
                execute_statement(stmt->body);
                printf("Current value of %s: %d\n", loop_variable_name, get_variable(loop_variable_name));
            }
            break;
        }

        default:
            yyerror("Unknown statement type");
    }
}




void set_variable(char *name, int value) {
    for (int i = 0; i < variable_count; ++i) {
        if (strcmp(variables[i].name, name) == 0) {
            variables[i].value = value;
            return;
        }
    }
    if (variable_count < MAX_VARIABLES) {
        variables[variable_count].name = strdup(name);
        variables[variable_count].value = value;
        variable_count++;
    } else {
        yyerror("Too many variables");
    }
}

int get_variable(char *name) {
    for (int i = 0; i < variable_count; ++i) {
        if (strcmp(variables[i].name, name) == 0) {
            return variables[i].value;
        }
    }
    return -1; // Variable not found
}

int evaluate_expression(Expression *expr) {
    if (expr->name) {
        return get_variable(expr->name);
    }
    return expr->num;
}


void free_variables() {
    // Iterăm prin toate variabilele și eliberăm memoria
    for (int i = 0; i < MAX_VARIABLES; ++i) {
        if (variables[i].name != NULL) {
            free(variables[i].name);
            variables[i].name = NULL;
        }
    }
}

