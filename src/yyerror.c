/* As funcoes de erro e aviso do montador */
/* $Id: yyerror.c,v 1.6 1999/01/25 22:57:21 andre Exp $ */

#include "yyerror.h"
#include <stdio.h> 

extern int parser_lineno; /* mantida por parser.y (baseado na saida do flex em
			     yylineno) */

int yyerror (const char* string_erro)
{
  fprintf(stdout, "** erro ");
  return erro(1, parser_lineno, string_erro);
}

int erro (const int pars_call, const int lineno, const char* string_erro)
{
  if (!pars_call) fprintf(stdout, "** erro ");
  if (lineno > 0) fprintf(stdout, "na linha %d, ", lineno);
  fprintf(stdout, "%s\n", string_erro);
  return ERROR_RETURN;
}

int aviso (const int lineno, const char* mesg)
{
  fprintf(stdout, "!! aviso <linha %d>: (%s)\n", lineno, mesg);
  return WARNING_RETURN;
}
