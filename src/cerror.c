/* As funcoes de erro e aviso do montador */
/* $Id: cerror.c,v 1.1 1999/01/25 22:57:18 andre Exp $ */

#include "cerror.h"
#include "yyerror.h"
#include <stdio.h> 

extern int cparser_lineno; /* mantida por cparser.y (baseado na saida do flex
			      em clineno) */

int cerror (const char* string_erro)
{
  fprintf(stdout, "** erro de config");
  return erro(1, cparser_lineno, string_erro);
}
