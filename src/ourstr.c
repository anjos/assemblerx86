/* Ola emacs, isto aqui e' -*-c-*- */
/* $Id: ourstr.c,v 1.2 1999/01/25 22:57:20 andre Exp $ */

#include "ourstr.h"
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

/* aloca espaco para uma 3a. string e coloca nela o conteudo 
   das 2 outras. FICA A SEU ENCARGO FAZER UM FREE() NA STRING
   RESULTANTE!! */
char* concatena (char* s1, const char* s2) 
{
  char* dest = malloc (strlen(s1) + strlen(s2) + 1);
  strcpy(dest, s1);
  return strcat(dest, s2);
}

char* maiusculas (char* s)
{
  int max;
  for (max = strlen(s); max > 0; --max) s[max-1] = toupper(s[max-1]);
  return s;
}

char* minusculas (char* s)
{
  int max;
  for (max = strlen(s); max > 0; --max) s[max-1] = tolower(s[max-1]);
  return s;
}

char* itoa (int i)
{
  int digit;
  int counter = 0;
  char* str = NULL;
  while (i > 0) {
    if (str == NULL) str = malloc (sizeof(char)); /* cuidado extra para
						     diferentes implementacoes
						     de realloc */
    else str = realloc(str, counter * sizeof(char));
    str = realloc(str, counter+1);
    digit = i%10; /* pega o ultimo digito */
    i /= 10; /* corta o ultimo digito */
    str[counter++] = '0' + digit;
  }

  return str;
}

      
    
    
    
