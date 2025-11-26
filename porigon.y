%{
#include <stdio.h>
#include <stdlib.h>

void yyerror(const char *s);
int  yylex(void);

/* --- Estado da "VM" --- */
typedef struct {
    int life;
    int attack;
    int enemy_life;
    int enemy_attack;
} GameState;

/* Valores iniciais da batalha */
static GameState state = { 100, 20, 80, 15 };

/* Forward declarations visíveis no parser.c */
struct Expr;
struct Condition;
struct Stmt;
struct StmtList;

/* Protótipos dos construtores de AST */
static struct Expr      *make_number_expr(int v);
static struct Expr      *make_var_expr(int var);
static struct Condition *make_condition(struct Expr *l, int op, struct Expr *r);
static struct Stmt      *make_simple_stmt(int kind);
static struct Stmt      *make_if_stmt(struct Condition *cond,
                                      struct StmtList *tbranch,
                                      struct StmtList *ebranch);
static struct Stmt      *make_while_stmt(struct Condition *cond,
                                         struct StmtList *body);
static struct StmtList  *make_stmt_list(struct Stmt *stmt,
                                        struct StmtList *next);
static struct StmtList  *append_stmt_list(struct StmtList *list,
                                          struct Stmt *stmt);

static void exec_stmt_list(struct StmtList *list);
%}

/* Coisas que também precisam aparecer no .tab.h (pro Flex enxergar) */
%code requires {
    struct Expr;
    struct Condition;
    struct Stmt;
    struct StmtList;

    /* Variáveis da linguagem */
    enum {
        VAR_LIFE,
        VAR_ATTACK,
        VAR_ENEMY_LIFE,
        VAR_ENEMY_ATTACK
    };

    /* Operadores de comparação */
    enum {
        OP_GT,
        OP_LT,
        OP_EQ,
        OP_GEQ,
        OP_LEQ
    };

    /* Tipos de comando */
    enum {
        ST_SPECIAL,
        ST_NORMAL,
        ST_CURE,
        ST_IF,
        ST_WHILE
    };
}

/* Valores semânticos */
%union {
    int ival;                 /* NUMBER, operadores, etc. */
    struct Expr      *expr;
    struct Condition *cond;
    struct Stmt      *stmt;
    struct StmtList  *stmt_list;
}

/* Tokens vindos do Flex */
%token PICK START END
%token IF ELSE WHILE
%token SPECIAL NORMAL CURE
%token LIFE ATTACK ENEMY_LIFE ENEMY_ATTACK
%token GT LT EQ GEQ LEQ
%token COLON
%token <ival> NUMBER

/* Tipos dos não-terminais */
%type <expr>      operand
%type <cond>      condition
%type <ival>      comp_op
%type <stmt>      stmt if_stmt while_stmt special_cmd normal_cmd cure_cmd
%type <stmt_list> stmt_list

%start program

%%

/* --------- Gramática --------- */

program
    : PICK START stmt_list END
    {
        printf("Iniciando programa PokéWars...\n");
        printf("Estado inicial: life=%d, attack=%d, enemy_life=%d, enemy_attack=%d\n",
               state.life, state.attack, state.enemy_life, state.enemy_attack);

        exec_stmt_list($3);

        printf("Estado final:   life=%d, attack=%d, enemy_life=%d, enemy_attack=%d\n",
               state.life, state.attack, state.enemy_life, state.enemy_attack);
    }
    ;

stmt_list
    : stmt
      { $$ = make_stmt_list($1, NULL); }
    | stmt_list stmt
      { $$ = append_stmt_list($1, $2); }
    ;

stmt
    : if_stmt
    | while_stmt
    | special_cmd
    | normal_cmd
    | cure_cmd
    ;

if_stmt
    : IF condition COLON stmt_list ELSE COLON stmt_list END
      { $$ = make_if_stmt($2, $4, $7); }
    ;

while_stmt
    : WHILE condition COLON stmt_list END
      { $$ = make_while_stmt($2, $4); }
    ;

special_cmd
    : SPECIAL
      { $$ = make_simple_stmt(ST_SPECIAL); }
    ;

normal_cmd
    : NORMAL
      { $$ = make_simple_stmt(ST_NORMAL); }
    ;

cure_cmd
    : CURE
      { $$ = make_simple_stmt(ST_CURE); }
    ;

condition
    : operand comp_op operand
      { $$ = make_condition($1, $2, $3); }
    ;

operand
    : LIFE
      { $$ = make_var_expr(VAR_LIFE); }
    | ATTACK
      { $$ = make_var_expr(VAR_ATTACK); }
    | ENEMY_LIFE
      { $$ = make_var_expr(VAR_ENEMY_LIFE); }
    | ENEMY_ATTACK
      { $$ = make_var_expr(VAR_ENEMY_ATTACK); }
    | NUMBER
      { $$ = make_number_expr($1); }
    ;

comp_op
    : GT   { $$ = OP_GT;  }
    | LT   { $$ = OP_LT;  }
    | EQ   { $$ = OP_EQ;  }
    | GEQ  { $$ = OP_GEQ; }
    | LEQ  { $$ = OP_LEQ; }
    ;

%%

/* --------- Implementação da AST + VM --------- */

/* Nós da AST */

struct Expr {
    int is_number;  /* 1 = NUMBER, 0 = variável */
    int value;      /* se is_number == 1 */
    int var;        /* se is_number == 0 (usa VAR_*) */
};

struct Condition {
    struct Expr *lhs;
    int          op;   /* usa OP_* */
    struct Expr *rhs;
};

struct Stmt {
    int kind;                 /* ST_* */
    struct Condition *cond;   /* IF / WHILE */
    struct StmtList *then_branch;
    struct StmtList *else_branch; /* só usado em IF */
};

struct StmtList {
    struct Stmt *stmt;
    struct StmtList *next;
};

/* ------- Construtores de nós ------- */

static struct Expr *make_number_expr(int v) {
    struct Expr *e = malloc(sizeof *e);
    if (!e) { perror("malloc"); exit(1); }
    e->is_number = 1;
    e->value = v;
    e->var = 0;
    return e;
}

static struct Expr *make_var_expr(int var) {
    struct Expr *e = malloc(sizeof *e);
    if (!e) { perror("malloc"); exit(1); }
    e->is_number = 0;
    e->value = 0;
    e->var = var;
    return e;
}

static struct Condition *make_condition(struct Expr *l, int op, struct Expr *r) {
    struct Condition *c = malloc(sizeof *c);
    if (!c) { perror("malloc"); exit(1); }
    c->lhs = l;
    c->op  = op;
    c->rhs = r;
    return c;
}

static struct Stmt *make_simple_stmt(int kind) {
    struct Stmt *s = malloc(sizeof *s);
    if (!s) { perror("malloc"); exit(1); }
    s->kind = kind;
    s->cond = NULL;
    s->then_branch = NULL;
    s->else_branch = NULL;
    return s;
}

static struct Stmt *make_if_stmt(struct Condition *cond,
                                 struct StmtList *tbranch,
                                 struct StmtList *ebranch) {
    struct Stmt *s = malloc(sizeof *s);
    if (!s) { perror("malloc"); exit(1); }
    s->kind = ST_IF;
    s->cond = cond;
    s->then_branch = tbranch;
    s->else_branch = ebranch;
    return s;
}

static struct Stmt *make_while_stmt(struct Condition *cond,
                                    struct StmtList *body) {
    struct Stmt *s = malloc(sizeof *s);
    if (!s) { perror("malloc"); exit(1); }
    s->kind = ST_WHILE;
    s->cond = cond;
    s->then_branch = body;
    s->else_branch = NULL;
    return s;
}

static struct StmtList *make_stmt_list(struct Stmt *stmt,
                                       struct StmtList *next) {
    struct StmtList *list = malloc(sizeof *list);
    if (!list) { perror("malloc"); exit(1); }
    list->stmt = stmt;
    list->next = next;
    return list;
}

static struct StmtList *append_stmt_list(struct StmtList *list,
                                         struct Stmt *stmt) {
    if (!list) return make_stmt_list(stmt, NULL);
    struct StmtList *p = list;
    while (p->next) p = p->next;
    p->next = make_stmt_list(stmt, NULL);
    return list;
}

/* ------- Execução ------- */

static int eval_expr(struct Expr *e) {
    if (e->is_number) {
        return e->value;
    } else {
        switch (e->var) {
            case VAR_LIFE:         return state.life;
            case VAR_ATTACK:       return state.attack;
            case VAR_ENEMY_LIFE:   return state.enemy_life;
            case VAR_ENEMY_ATTACK: return state.enemy_attack;
            default:               return 0;
        }
    }
}

static int eval_condition(struct Condition *c) {
    int l = eval_expr(c->lhs);
    int r = eval_expr(c->rhs);
    switch (c->op) {
        case OP_GT:  return l >  r;
        case OP_LT:  return l <  r;
        case OP_EQ:  return l == r;
        case OP_GEQ: return l >= r;
        case OP_LEQ: return l <= r;
        default:     return 0;
    }
}

static void exec_stmt(struct Stmt *s);

static void exec_stmt_list(struct StmtList *list) {
    for (; list != NULL; list = list->next) {
        exec_stmt(list->stmt);
    }
}

static void exec_stmt(struct Stmt *s) {
    switch (s->kind) {
        case ST_SPECIAL:
            printf("[VM] SPECIAL: dano forte!\n");
            state.enemy_life -= 2 * state.attack;
            break;

        case ST_NORMAL:
            printf("[VM] NORMAL: ataque simples.\n");
            state.enemy_life -= state.attack;
            break;

        case ST_CURE:
            printf("[VM] CURE: cura 10 de life.\n");
            state.life += 10;
            break;

        case ST_IF:
            if (eval_condition(s->cond)) {
                exec_stmt_list(s->then_branch);
            } else if (s->else_branch) {
                exec_stmt_list(s->else_branch);
            }
            break;

        case ST_WHILE:
            while (eval_condition(s->cond)) {
                exec_stmt_list(s->then_branch);
            }
            break;
    }
}

/* ------- Erro de sintaxe ------- */

void yyerror(const char *s) {
    fprintf(stderr, "Erro de sintaxe: %s\n", s);
}
