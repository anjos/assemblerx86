/* Ola emacs, este arquivo e' um codigo em -*-c-*- */
/* Define tabela de simbolos e funcoes para usar com o parser */

/* $Id: oursym.h,v 1.7 1999/01/25 22:57:17 andre Exp $ */

#ifndef _OURSYM_H
#define _OURSYM_H

#include <stdlib.h>
#include <stdio.h>
#include "whatis.h"

/* os tipos de simbolos */
typedef enum {EQU=0, BYTE=1, WORD=2, 
	      DOUBLEWORD=4, QUADWORD=8, 
	      NAOREC=10, WORD_PTR=11, BYTE_PTR=12} TIPO_QUALIFICADOR;

/* um contador de simbolos */
typedef struct vetor_t {
  int* value;
  int nval;
} vetor_t;

/* As constantes definidas pelo identificador EQU, embora declaradas aqui nao
   sao verificadas durante a compilacao por nao possuirmos instrucoes que
   necessitem tal. Instrucoes que demandariam verificao seriam do tipo
   MNEMONICO SIMBOLO [OPERANDO], onde o "SIMBOLO" em questao e' alterado pela
   operacao. Dai que se torna indiferente o uso de constantes ou simbolos do
   tipo "WORD" neste montador. */

/* assumimos que todas as variaveis terao 8 ou 16 bits */

/* o que e' um simbolo */
typedef struct simbolo_t {
  TIPO_QUALIFICADOR qualidade;
  int npos;
  char* nome;
  int* valor; /* pode ser tambem o valor de todos os elementos de vetores */
  byte_t* endereco_byte;
  word_t* endereco_word;
  struct simbolo_t* proximo;
  struct simbolo_t* apontado;
  int lineno;
} simbolo_t;

/* as funcoes */

simbolo_t* insira_simbolo (simbolo_t*);

/* aloca um novo simbolo tipo variavel ou constante */
simbolo_t* declare_simbolo (char*, const TIPO_QUALIFICADOR, const vetor_t*);
simbolo_t* declare_ponteiro (char*, simbolo_t*, const TIPO_QUALIFICADOR);

/* esta retorna o simbolo, case o ache. Senao, retorna NULL */
simbolo_t* procure_simbolo (const char*);

/* converte uma string em um qualificador */
TIPO_QUALIFICADOR strtoqual (const char*);

/* desaloca simbolos de uma lista concatenada por ponteiros */
void free_simbolo (simbolo_t*);

/* imprime um simbolo */
void imprima_simbolo (FILE*, simbolo_t*);
void imprima_simbolo_com_posicao (FILE*, simbolo_t*);

#endif /* _OURSYM_H */












