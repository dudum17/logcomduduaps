#include <stdio.h>

int yyparse(void);

int main(void) {
    printf("Digite um programa PokéWars (Ctrl+D para finalizar):\n\n");
    if (yyparse() == 0) {
        // Mensagem de sucesso já é impressa na ação de 'program'
    } else {
        printf("Falha na análise.\n");
    }
    return 0;
}
