/* Ola emacs, isto e' -*-c-*- */
/* $Id: cwrap.c,v 1.1 1999/01/25 22:57:19 andre Exp $ */

#include "cwrap.h"
#include <stdlib.h>

int cwrap (void)
{
  return 1;
}

/* Esta funcao e' responsavel por alocar espaco para clval (string
   somente). Este espaco deve ser calculado de acordo com o numero maximo de
   bytes que tal variavel podera' ocupar. Este sera' o maior dos possiveis
   campos da uniao:

   typedef union {
     char* palavra;          -> max length = ??, guessing 50 chars = 50 bytes
     int inteiro;            -> max length = 4 bytes
     simbolo_t* simb;
     linha_t* lin;   
     operando_t* op;
   } CSTYPE; 

   Nao consideraremos os outros casos, pois o parser nao os utiliza. Vejamos
   ainda que entre diferentes chamadas de strcpy(clval.palvra, xxx) e'
   possivel que se perca o endereco alocado inicialmente. Isto pode ser
   resolvido chamando-se a funcao aloca_espaco() de novo. */
