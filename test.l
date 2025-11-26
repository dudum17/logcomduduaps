cd "/c/Users/DUDU/OneDrive/Documentos/insper/logica da computação/logcomduduaps"

cat > test.l << 'EOF'
%{
#include <stdio.h>
%}

%%

[0-9]+      { printf("NUM\n"); }
[ \t\r\n]+  { /* ignora */ }
.           { /* outro char */ }

%%

int yywrap(void) {
    return 1;
}
EOF
