/* Ola emacs, este arquivo e' um codigo em **c** */
/* Define tabela de linhas, para o montador */

/* $Id */

#ifndef _OURLINE_H
#define _OURLINE_H

#include <stdlib.h>
#include <stdio.h>
#include <oursym.h>
#include "init.h"
#include "whatis.h"

typedef enum {TIPO_ENDERECO=0, TIPO_REGISTRADOR=1, 
	      TIPO_SIMBOLO=2, TIPO_PROCEDIMENTO=3, 
	      TIPO_ROTULO=4, TIPO_BYTE=5, TIPO_WORD=6,
              TIPO_APONTADO_SIMB=7, TIPO_APONTADO_REG=8,
              TIPO_APONTADO_REG_AJUST=9, 
	      TIPO_ENDERECO_VAR=10} TIPO_DE_OPERANDO;

struct rotina_t; /* para quebrar dependencias */

typedef struct operando_t {
  TIPO_DE_OPERANDO tipo;
  union {
    char* nome;
    long endereco;
    long valor;
    reg_t* registrador;
    simbolo_t* simbolo;
    struct rotina_t* rotina;
  } prop;
  int indice; /* para vetores ou ajustes em valores de registradores */
  int lineno; /* para erros e avisos, a posicao onde foi declarado */
} operando_t;

typedef struct linha_t {
  char* rotulo;
  byte_t* posicao; /* a posicao de memoria onde esta linha se encontra */
  inst_t* instrucao;
  int narg;
  operando_t* op1;
  operando_t* op2;
  struct linha_t* proxima;
  struct rotina_t* rotina;
  int lineno;
} linha_t;

/* as rotinas definem estruturas de codigo isoladas das demais. O conceito de
   variavel local nao foi executado aqui. Assim sendo, variaveis alocadas ou
   declaradas em qsq rotinas se tornam globais. A solucao deste problema e'
   alocar um espaco para cada variavel local em listas de simbolos separados
   que seriam pertinentes somente `a rotina. */
typedef struct rotina_t {
  char* nome;
  byte_t* posicao; /* a posicao de memoria onde esta rotina se encontra */
  linha_t* primeira;
  linha_t* ultima;
  struct rotina_t* proxima;
} rotina_t;

void imprima_linha(FILE*, const linha_t*);
byte_t* imprima_linha_com_codigos(FILE*, const linha_t*, byte_t*);
void free_linha(linha_t*);
void free_rotina(linha_t*);
linha_t* insira_linha(linha_t*, rotina_t*);
rotina_t* nova_rotina(char*, const int);
void imprima_rotina(FILE*, rotina_t*);
byte_t* imprima_rotina_com_codigos(FILE*, rotina_t*, byte_t*);
rotina_t* rotina_atual(char*);
rotina_t* procure_rotina(const char*);
byte_t* procure_rotulo(const char*); /* procura rotulo nas rotinas */

#endif /* _OURLINE_H */




