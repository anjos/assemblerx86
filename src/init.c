/* Ola emacs, este arquivo e' um codigo em -*-c-*- */

/* $Id: init.c,v 1.6 1999/02/01 23:01:39 andre Exp $ */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "ourstr.h"
#include "yyerror.h"
#include "init.h"
#include "ourline.h"

/* declaracoes da stdlib */
int strcasecmp(const char*, const char*);
char* strdup(const char*);

/* ********* */
/* Code Area */
/* ********* */

/* 1) Os registradores */
/* ******************* */

reg_t* registradores (void)
{
  return inicialize_registradores(NULL);
}

/* quem realmente inicializa os registradores usando o arquivo ja aberto. O
   trabalho e' feito sem a ajuda do Bison ou Flex, ja' que e' simples... */
reg_t* inicialize_registradores(FILE* in)
{  
  static reg_t* prima = (reg_t*) NULL; /* inicializado somente 1 vez */

  char* stemp;

  const int max_chars_per_reg = 6; /* 6 + NULL */
  reg_t* iterador = NULL;

  if ( prima != NULL ) return prima;

  if ( in == NULL ) {
    yyerror("(init.c) erro: Arquivo de registradores sem nome?\n");
    return NULL;
  }

  /* le os registradores validos e poe na tabela dinamica... */
  stemp = (char*) malloc (max_chars_per_reg * sizeof(char));
  while ( fscanf(in, "%s", stemp ) != EOF ) {
    if ( stemp[0] == '#' ) {
      while ( fgetc(in) != '\n' );
      continue; /* comentario */
    }

    if (iterador == NULL)
      iterador = (reg_t*) malloc (sizeof(reg_t));
    else {
      iterador->proximo = (reg_t*) malloc (sizeof(reg_t));
      iterador = iterador->proximo;
    }

    /* malloca espaco deixando uma casa para o 'e' e outra para o NULL */
    iterador->apelido = (char*) malloc (strlen(stemp)+2);
    iterador->apelido[0] = 'e';

    /* nome comeca da posicao [1], e' claro */
    iterador->nome = iterador->apelido + 1;
    strcpy(iterador->nome, stemp);

    iterador->proximo = (reg_t*)NULL;
    if (prima == NULL) prima = iterador; /* pega o end. do 1o. registrador */
  }

  return prima;
}

reg_t* ache_registrador(const char* chave)
{
  reg_t* tabela = registradores();
  while ( tabela != NULL) {
    if (strcasecmp (tabela->nome, chave) == 0 ||
	strcasecmp (tabela->apelido, chave) == 0) return tabela;
    tabela = tabela->proximo;
  }
  return NULL;
}

/* 2) As instrucoes */
/* **************** */

/* retorna o grupo de instrucoes correspondente a chave, caso nao a ache, re-
   torna um novo grupo tendo como nome, chave. */
grinst_t* novo_grupo_de_instrucoes(const char* chave)
{
  static grinst_t* primo = (grinst_t*)NULL;/* inicializado somente 1 vez */
  static grinst_t* ultimo;
  
  grinst_t* iterador;
  
  if (chave == NULL) return primo;

  if (primo == NULL) { /* se nao tem nada, aloca o 1o. */
    ultimo = primo = (grinst_t*) malloc (sizeof (grinst_t));
    ultimo->nome = (char*) malloc ( strlen(chave) + 1 );
    strcpy(ultimo->nome, chave);
    ultimo->primeira = NULL;
    ultimo->ultima = NULL;
    ultimo->proximo = NULL;
    return ultimo;
  }
  
  iterador = primo;
  while (iterador != NULL) { /* se tem algo, ve se ja tem o grupo "chave" */
    if ( strcasecmp(iterador->nome, chave) == 0 ) return iterador;
    iterador = iterador->proximo;
  }

  /* se nao tem, cria */
  ultimo->proximo = (grinst_t*) malloc (sizeof (grinst_t));
  ultimo = ultimo->proximo;
  ultimo->nome = (char*) malloc ( strlen(chave) + 1 );
  strcpy(ultimo->nome, chave);
  ultimo->primeira = NULL;
  ultimo->ultima = NULL;
  ultimo->proximo = NULL;
  return ultimo;
}

grinst_t* ache_grupo_de_instrucoes (const char* chave)
{
  grinst_t* it;
  for(it=novo_grupo_de_instrucoes(NULL); it != NULL; it=it->proximo)
    if (strcasecmp(it->nome, chave) == 0) return it;

  return NULL;
}

inst_t* nova_instrucao(grinst_t* grupo)
{
  inst_t* nova;

  if (grupo->primeira == NULL) { /* se nao tem nada, aloca o 1o. */
    nova = grupo->ultima = grupo->primeira = (inst_t*) malloc (sizeof(inst_t));
    nova->nome = grupo->nome; /* o nome da nova instrucao */
    nova->proxima = NULL; /* detalhes de operacao */
  }
  
  else {
    grupo->ultima->proxima = (inst_t*) malloc (sizeof(inst_t));
    nova = grupo->ultima = grupo->ultima->proxima;
    nova->nome = grupo->nome;
    nova->proxima = NULL;
  }

  return nova;
}

inst_t* ache_instrucao_em_grupo (const grinst_t* grupo, 
				 const arg_t* arg1, const arg_t* arg2)
{
  inst_t* it = grupo->primeira;

  while (it != NULL) {
    switch (it->narg) {
    case 0: /* caso basico, nao ha argumentos na instrucao */
      if (arg1 == NULL && arg2 == NULL) return it;
      break;
      
    case 1: /* 1 argumento somente */
      if (arg1 != NULL && arg2 == NULL)
	if (compare_argumentos(arg1, it->argumento[0])) return it;
      break;

    case 2: /* 2 args */
      if (arg1 != NULL && arg2 != NULL)
	if (compare_argumentos(arg1, it->argumento[0]) &&
	    compare_argumentos(arg2, (it->argumento[1]) )) return it;
      break;
    }
    
    it = it->proxima;
  }

  return NULL;
}

/* somente compara 2 argumentos retornando 1 para iguais e 0 para diferentes */
int compare_argumentos(const arg_t* arg1, const arg_t* arg2)
{
  switch(arg1->tipo) {
  case ARG_WORD:
  case ARG_BYTE:
  case ARG_PTD_END:
    if (arg2->tipo == arg1->tipo) return 1;
    break;

  case ARG_END:
    if (arg2->tipo == arg1->tipo || arg2->tipo == ARG_DESLOC8 ||
	arg2->tipo == ARG_DESLOC16) return 1;
    break;

  case ARG_DESLOC8:
  case ARG_DESLOC16:
    if (arg2->tipo == arg1->tipo || arg2->tipo == ARG_END) return 1;
    break;

  case ARG_REG:
  case ARG_PTD_REG:
  case ARG_PTD_REG_ADJ:
    if (arg1->tipo == arg2->tipo && arg1->registrador == arg2->registrador)
      return 1;
    break;
  }

  return 0;
}

arg_t* escolha_argumento(arg_t* arg1, arg_t* arg2)
{
  switch(arg1->tipo) {
  case ARG_WORD:
  case ARG_END:
  case ARG_PTD_END:
  case ARG_BYTE:
  case ARG_PTD_REG_ADJ:
    switch(arg2->tipo) {
    case ARG_WORD:
    case ARG_END:
    case ARG_PTD_END:
    case ARG_BYTE:
    case ARG_PTD_REG_ADJ:
      return NULL; /* incompativeis */

    default:
      return arg1; /* compativeis */
    }
    break; /* switch anterior */

  default:
    return arg2; /* compativeis */
  }
}

/* converte um operando num argumento para ser usado em comparacoes diretas.
   Memoria e' alocada, naturalmente. */
arg_t* op2arg(const operando_t* op)
{
  arg_t* este;

  switch(op->tipo) {
  case TIPO_BYTE:
    este = (arg_t*) malloc (sizeof(arg_t));
    este->tipo = ARG_BYTE;
    este->registrador = NULL;
    break;

  case TIPO_WORD:
  case TIPO_ENDERECO_VAR:
    este = (arg_t*) malloc (sizeof(arg_t));
    este->tipo = ARG_WORD;
    este->registrador = NULL;
    break;

  case TIPO_ENDERECO:
  case TIPO_SIMBOLO:
  case TIPO_ROTULO:
  case TIPO_PROCEDIMENTO:
    este = (arg_t*) malloc (sizeof(arg_t));
    este->tipo = ARG_END;
    este->registrador = NULL;
    break;

  case TIPO_REGISTRADOR:
    este = (arg_t*) malloc (sizeof(arg_t));
    este->tipo = ARG_REG;
    este->registrador = op->prop.registrador;
    break;

  case TIPO_APONTADO_REG:
    este = (arg_t*) malloc (sizeof(arg_t));
    este->tipo = ARG_PTD_REG;
    este->registrador = op->prop.registrador;
    break;

  case TIPO_APONTADO_REG_AJUST:
    este = (arg_t*) malloc (sizeof(arg_t));
    este->tipo = ARG_PTD_REG_ADJ;
    este->registrador = op->prop.registrador;
    break;

  case TIPO_APONTADO_SIMB:
    este = (arg_t*) malloc (sizeof(arg_t));
    este->tipo = ARG_PTD_END;
    este->registrador = NULL;
    break;

  }

  return este;
}


