/* Ola emacs, isto e' -*-c-*- */
/* $Id: yywrap.c,v 1.3 1999/01/04 23:42:45 andre Exp $ */

#include "yywrap.h"
#include <stdlib.h>

int yywrap (void)
{
  return 1;
}

/* Esta funcao e' responsavel por alocar espaco para yylval (string
   somente). Este espaco deve ser calculado de acordo com o numero maximo de
   bytes que tal variavel podera' ocupar. Este sera' o maior dos possiveis
   campos da uniao:

   typedef union {
     char* palavra;          -> max length = ??, guessing 50 chars = 50 bytes
     int inteiro;            -> max length = 4 bytes
     simbolo_t* simb;
     linha_t* lin;   
     operando_t* op;
   } YYSTYPE; 

   Nao consideraremos os outros casos, pois o parser nao os utiliza. Vejamos
   ainda que entre diferentes chamadas de strcpy(yylval.palvra, xxx) e'
   possivel que se perca o endereco alocado inicialmente. Isto pode ser
   resolvido chamando-se a funcao aloca_espaco() de novo. */

char* seta_espaco (const int condicao) /* 0 = inicio; >0, executando */ 
{
  static char* s_endereco;
  if (condicao == 0) s_endereco = (char*) malloc (51 * sizeof(char));
  return s_endereco;
}
