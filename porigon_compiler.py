import sys
import re
from abc import ABC, abstractmethod
from typing import Any
import os


pokemons = ["Pikachu" , "Charizard" , "Bulbasaur" , "Blastoise" , "Eevee" ,
                  "Gengar" , "Snorlax" , "Lucario" , "Greninja" , "Sceptile" , "Infernape" , 
                  "Lapras" , "Drapion" , "Rhydon" , "Talonflame" , "Alakazam" , "Mewtwo" ,
                  "Heracross" , "Onix" , "Dragonite" , "Garchomp" , "Rayquaza" , "Zoroark" ,
                  "Gardevoir" , "Arceus"]

class Token:
    def __init__(self, kind, value):
        self.kind = kind
        self.value = value


class Lexer:
    def __init__(self, source, position):
        self.source = source
        self.position = position
        self.next = None

    def selectNext(self):
        while self.position < len(self.source) and self.source[self.position].isspace():
            self.position += 1

        if self.position >= len(self.source):
            self.next = Token("EOF", "")
            return

        c = self.source[self.position]

        if c == "<":
            if self.position + 1 < len(self.source) and self.source[self.position:self.position+2] == "<=":
                self.next = Token("LESS_EQUAL", "<=")
                self.position += 2
            else:
                self.next = Token("LESS", "<")
                self.position += 1
        elif c == ">":
            if self.position + 1 < len(self.source) and self.source[self.position:self.position+2] == ">=":
                self.next = Token("GREATER_EQUAL", ">=")
                self.position += 2
            else:
                self.next = Token("GREATER", ">")
                self.position += 1
        elif c == "=":
            self.next = Token("EQUAL", "=")
            self.position += 1
        elif c == ":":
            self.next = Token("COLON", ":")
            self.position += 1
        elif c.isdigit():
            num = ""
            while self.position < len(self.source) and self.source[self.position].isdigit():
                num += self.source[self.position]; self.position += 1
            self.next = Token("INT", num)
        elif c.isalpha() or c == "_":
            ident = ""
            while (self.position < len(self.source)
                   and (self.source[self.position].isalnum() or self.source[self.position] == "_")):
                ident += self.source[self.position]; self.position += 1
            if ident == "pick":
                self.next = Token("PICK", ident)
            elif ident == "start":
                self.next = Token("START", ident)
            elif ident == "end":
                self.next = Token("END", ident)
            elif ident == "if":
                self.next = Token("IF", ident)
            elif ident == "else":
                self.next = Token("ELSE", ident)
            elif ident == "while":
                self.next = Token("WHILE", ident)
            elif ident == "special":
                self.next = Token("SPECIAL", ident)
            elif ident == "normal":
                self.next = Token("NORMAL", ident)
            elif ident == "cure":
                self.next = Token("CURE", ident)
            elif ident == "life":
                self.next = Token("LIFE", ident)
            elif ident == "attack":
                self.next = Token("ATTACK", ident)
            elif ident == "enemy_life":
                self.next = Token("ENEMY_LIFE", ident)
            elif ident == "enemy_attack":
                self.next = Token("ENEMY_ATTACK", ident)
            elif ident in pokemons:
                self.next = Token("POKEMON", ident)
            else:
                raise Exception(f"Identificador inválido")
        else:
            raise Exception(f"não existe essa caracter no alfabeto dessa linguagem")
        
class Parser:
    lex: Lexer = None

    @staticmethod
    def parse_condition():
        if (Parser.lex.next.kind != "LIFE" 
            and  Parser.lex.next.kind != "ATTACK"
            and Parser.lex.next.kind != "ENEMY_LIFE" 
            and Parser.lex.next.kind != "ENEMY_ATTACK" 
            and Parser.lex.next.kind != "INT") :
                raise Exception(f"experado um dos atributos")
        left = Parser.lex.next.value
        Parser.lex.selectNext()
        if (Parser.lex.next.kind != "LESS" 
            and Parser.lex.next.kind != "LESS_EQUAL" 
            and Parser.lex.next.kind != "GREATER" 
            and Parser.lex.next.kind != "GREATER_EQUAL" 
            and Parser.lex.next.kind != "EQUAL"):
               raise Exception(f"experando operando")
        op = Parser.lex.next.value
        Parser.lex.selectNext()
        if (Parser.lex.next.kind != "LIFE" and 
            Parser.lex.next.kind != "ATTACK" and 
            Parser.lex.next.kind != "ENEMY_LIFE" and 
            Parser.lex.next.kind != "ENEMY_ATTACK" and
            Parser.lex.next.kind != "INT"):
                raise Exception(f"experando operando")
        right= Parser.lex.next.value
        Parser.lex.selectNext()
        return {"type": "Cond", "op": op, "left": left, "right": right}

    @staticmethod
    def parsewhile():
        if Parser.lex.next.kind != "WHILE":
          raise Exception(f"esperado WHILE, encontrado {Parser.lex.next.kind}")
        Parser.lex.selectNext()  # consome IF

        cond = Parser.parse_condition()
        if Parser.lex.next.kind != "COLON":
          raise Exception("esperado ':' depois da condição do while")
        Parser.lex.selectNext()  # consome ':'

        while_body = Parser.parse_stmt_list(stop_tokens={"END"})

        if Parser.lex.next.kind != "END":
            raise Exception("esperado 'end' para fechar o while")
        Parser.lex.selectNext()  # consome END
         
        return {"type": "While", "cond": cond, "body" : while_body}
    



    @staticmethod
    def parseif():
    # espera estar com lookahead = IF
      if Parser.lex.next.kind != "IF":
        raise Exception(f"esperado IF, encontrado {Parser.lex.next.kind}")
      Parser.lex.selectNext()  # consome IF

    # condição: <operand> <comp_op> <operand>
      cond  = Parser.parse_condition()

    # ':' inicia o bloco THEN
      if Parser.lex.next.kind != "COLON":
          raise Exception("esperado ':' depois da condição do if")
      Parser.lex.selectNext()  # consome ':'

    # THEN: consome 1..N statements até encontrar ELSE ou END
      then_body = Parser.parse_stmt_list(stop_tokens={"ELSE", "END"})

    # ELSE é opcional: se vier, consome ':' e o bloco; senão, segue para END
      else_body = []
      if Parser.lex.next.kind == "ELSE":
          Parser.lex.selectNext()  # consome ELSE
          if Parser.lex.next.kind != "COLON":
             raise Exception("esperado ':' depois de else")
          Parser.lex.selectNext()  # consome ':'
        # ELSE: consome até END
          else_body = Parser.parse_stmt_list(stop_tokens={"END"})

    # fecha o if com END
      if Parser.lex.next.kind != "END":
         raise Exception("esperado 'end' para fechar o if")
      Parser.lex.selectNext()  # consome END

      return {"type": "If", "cond": cond, "then": then_body, "else": else_body}
        

    @staticmethod
    def parse_stmt_list(stop_tokens=None):
   
        if stop_tokens is None:
           stop_tokens = {"END"}

        FIRST_STMT = {"IF", "WHILE", "SPECIAL", "NORMAL", "CURE"}

    # Exige pelo menos 1 statement
        if Parser.lex.next.kind not in FIRST_STMT:
           raise Exception("esperado início de <stmt> (IF/WHILE/SPECIAL/NORMAL/CURE)")

        stmts = []

    # Consome enquanto for início de <stmt>
        while Parser.lex.next.kind not in stop_tokens:
           if Parser.lex.next.kind in FIRST_STMT:
              stmts.append(Parser.parse_statmnet())
           else:
            # Se não é início de stmt nem token de parada, é erro
                raise Exception(f"token inesperado em <stmt_list>: {Parser.lex.next.kind}")

        return stmts


    @staticmethod
    def parse_statmnet():
        if Parser.lex.next.kind == "IF":
            return Parser.parseif()
        elif Parser.lex.next.kind == "WHILE":
            return Parser.parsewhile()
        elif Parser.lex.next.kind == "SPECIAL":
            Parser.lex.selectNext()
            return {"type": "Special"}
        elif Parser.lex.next.kind == "NORMAL":
            Parser.lex.selectNext()
            return {"type": "normal"}
        elif Parser.lex.next.kind == "CURE":
            Parser.lex.selectNext()
            return {"type": "cure"}
        else:
             raise Exception(f"esperado início de <stmt> (IF/WHILE/SPECIAL/NORMAL/CURE)")



    @staticmethod
    def parse_pick():
        if Parser.lex.next.kind != "PICK":
            raise Exception(f"não foi usado a palavra pick para escolher pokemon")
        Parser.lex.selectNext()
        if Parser.lex.next.kind != "POKEMON":
            got = Parser.lex.next.kind
            raise Exception(f"precisa dizer o nome do pokemon")
        name = Parser.lex.next.value  # captura o nome do pokémon
        Parser.lex.selectNext()       # consome POKEMON

        return {"type": "Pick", "name": name}
        


    @staticmethod
    def parse_program():
        pick_node = Parser.parse_pick()
        if Parser.lex.next.kind != "START":
            raise Exception(f"é necessario dar o start")
        Parser.lex.selectNext()
        body = Parser.parse_stmt_list(stop_tokens={"END"})
        if Parser.lex.next.kind != "END":
            raise Exception(f"é necessario terminar a partida")
        Parser.lex.selectNext()
        if Parser.lex.next.kind != "EOF":
            raise Exception(f"ha tokens no final do programa")
        return {"type": "Program", "pick": pick_node, "body": body}
        
    @staticmethod
    def run(source):
        Parser.lex = Lexer(source, 0)
        Parser.lex.selectNext()  # inicializa o primeiro token
        tree = Parser.parse_program()
        print("AST gerada com sucesso!")
        print(tree)
        return tree
        

def main():
    if len(sys.argv) != 2:
        print("Uso: python3 main.py arquivo.ts")
        sys.exit(1)

    arquivo = sys.argv[1]
    try:
        with open(arquivo, "r", encoding="utf-8") as f:
            codigo = f.read().strip()
    except FileNotFoundError:
        print(f"Erro: arquivo '{arquivo}' não encontrado.")
        sys.exit(1)
           
    try:
        Parser.run(codigo)
    except Exception as e:
        print(f"Erro: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()