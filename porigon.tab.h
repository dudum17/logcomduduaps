/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

#ifndef YY_YY_PORIGON_TAB_H_INCLUDED
# define YY_YY_PORIGON_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif
/* "%code requires" blocks.  */
#line 44 "porigon.y"

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

#line 82 "porigon.tab.h"

/* Token kinds.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    YYEMPTY = -2,
    YYEOF = 0,                     /* "end of file"  */
    YYerror = 256,                 /* error  */
    YYUNDEF = 257,                 /* "invalid token"  */
    PICK = 258,                    /* PICK  */
    START = 259,                   /* START  */
    END = 260,                     /* END  */
    IF = 261,                      /* IF  */
    ELSE = 262,                    /* ELSE  */
    WHILE = 263,                   /* WHILE  */
    SPECIAL = 264,                 /* SPECIAL  */
    NORMAL = 265,                  /* NORMAL  */
    CURE = 266,                    /* CURE  */
    LIFE = 267,                    /* LIFE  */
    ATTACK = 268,                  /* ATTACK  */
    ENEMY_LIFE = 269,              /* ENEMY_LIFE  */
    ENEMY_ATTACK = 270,            /* ENEMY_ATTACK  */
    GT = 271,                      /* GT  */
    LT = 272,                      /* LT  */
    EQ = 273,                      /* EQ  */
    GEQ = 274,                     /* GEQ  */
    LEQ = 275,                     /* LEQ  */
    COLON = 276,                   /* COLON  */
    NUMBER = 277                   /* NUMBER  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 78 "porigon.y"

    int ival;                 /* NUMBER, operadores, etc. */
    struct Expr      *expr;
    struct Condition *cond;
    struct Stmt      *stmt;
    struct StmtList  *stmt_list;

#line 129 "porigon.tab.h"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;


int yyparse (void);


#endif /* !YY_YY_PORIGON_TAB_H_INCLUDED  */
