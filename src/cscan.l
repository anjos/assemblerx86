/* Ola emacs, isto e -*-c-*- */
/* $Id: cscan.l,v 1.4 1999/02/01 23:01:38 andre Exp $ */

%option nounput

%{ /* As diretivas de inclusao */
#include <stdio.h>
#include <string.h> /* Para strcpy() e outras */
#include "cwrap.h" /* A funcao wrapper */
#include "yywrap.h" /* para seta_espaco() */
#include "init.h" /* O que e' inst_t e reg_t */
#include "cparser.h"

/* para a contagem de linhas - aqui so conta quando o '\n' estiver depois de
   um comentario */
extern int cparser_lineno;
extern int DEPURA;
%}

/* A gramatica do analizador lexicografico para o arquivo de configuracao */
%%

0x[a-fA-F0-9]* { /* para numeros hexa */
  clval.inteiro = strtol(ctext, NULL, 16);
  if (DEPURA) fprintf(stdout, "(scanner-cfg) codigo(%lX)\n", clval.inteiro);
  return CPARSER_INTEIRO;
}

byte { 
  return CPARSER_BYTE;
}

word { /* palavra-chave */
  return CPARSER_WORD;
}

end { /* palavra-chave */
  return CPARSER_ENDERECO;
}

desloc8 { /* palavra-chave */
  return CPARSER_DESLOCAMENTO_8;
}

desloc16 { /* palavra-chave */
  return CPARSER_DESLOCAMENTO_16;
}

[a-z\_][a-z0-9]*\_*\-*[a-z0-9]* { /* qq palavra valida para o parser */
  /* algumas variaveis necessarias */
  reg_t* temp_reg;

  clval.palavra = seta_espaco(1); /* recupera o espaco reservado. A
				      inexistencia deste espaco pode levar
				      strcpy() a rejeitar a operacao ==
				      "core dump" */
  strcpy(clval.palavra, ctext);

  if ( (temp_reg = ache_registrador(clval.palavra)) != NULL ) {
    if (DEPURA) fprintf(stdout, "(scanner-cfg) registrador(%s)\n", ctext);
    clval.reg = temp_reg;
    return CPARSER_REGISTRADOR;
  }

  /* se chegou aqui e' porque e' nao e' registrador */
  if (DEPURA) fprintf(stdout, "(scanner-cfg) ");
  if (DEPURA) fprintf(stdout, "palavra(%s)\n", ctext);
  return CPARSER_PALAVRA;
}

[ \t]*   /* destroi espacos em branco */

\#[[:print:]\t]* { /* comeca comentario, elimino tudo depois */
  if (DEPURA) fprintf(stdout, "(scanner-cfg) comentario\n");
}

\, { /* separador de operadores */
  return ',';
}

\: { /* separador de codigo */
  return ':';
}

\n { /* fim-de-linha */
  return '\n';
}

\[ {
  return '[';
}

\] {
  return ']';
}

\+ { /* soma */
  return '+';
}

<<EOF>> {
  return CPARSER_FIM_DE_ARQUIVO; /* Ok, retorna que o arquivo chegou no final */
}

. { /* qq outra coisa */
   fprintf(stderr, "%d: erro de sintaxe -> \"%s\"\n", cparser_lineno, ctext);
   return 0; /* para quando encontra um erro */
  }





