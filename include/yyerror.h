/* Ola emacs, isto e' -*-c-*- */
/* $Id: yyerror.h,v 1.3 1999/01/15 17:41:51 andre Exp $ */

#ifndef HEADER_YYERROR
#define HEADER_YYERROR

#define ERROR_RETURN 0
#define WARNING_RETURN 1

int yyerror (const char*);
int erro (const int, const int, const char*);
int aviso (const int, const char*);

#endif /* HEADER_YYERROR */
