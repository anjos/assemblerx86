/* Ola emacs, este arquivo e' um codigo em -*-c-*- */

/* $Id: oursym.c,v 1.9 1999/01/25 22:57:20 andre Exp $ */

#include <string.h>
#include <stdlib.h>
#include "oursym.h"
#include "ourstr.h"
#include "yyerror.h"
#include "coding.h"

/* o invisivel */
int strcasecmp(const char *s1, const char *s2); /* semi-standard */
void imprima_simbolo_basico (FILE*, simbolo_t*);
extern int parser_lineno;
/* fim do invisivel */

/* retorna (simbolo_t*)NULL caso nao ache nada */
simbolo_t* procure_simbolo (const char* chave)
{
  simbolo_t* iterador = insira_simbolo(NULL); /* pega tabela */

  /* no caso da tabela estar vazia */
  if (iterador == NULL) return NULL;
 
  while ( iterador != NULL ) {
    if (iterador->nome != NULL )
      if (strcmp(chave, iterador->nome) == 0) return iterador;
    iterador = iterador->proximo;
  }
  
  /* se chegou aqui e' porque nao achou o simbolo */
  return NULL;
}

simbolo_t* declare_simbolo (char* nome,
			    const TIPO_QUALIFICADOR qual,
			    const vetor_t* valores)
{
  simbolo_t* temp = (simbolo_t*) malloc (sizeof(simbolo_t));

  if (qual == QUADWORD) {
    erro(0, parser_lineno, "(oursym.c) tipo quadword nao implementado");
    free(temp); /* libera ponteiro inicializado */
    return (simbolo_t*)NULL;
  }

  /* ok, vou retornar o simbolo */
  temp->qualidade = qual;
  temp->npos = valores->nval;
  temp->nome = nome;
  temp->valor = valores->value;
  temp->proximo = NULL;
  temp->endereco_byte = NULL;
  temp->endereco_word = NULL;
  temp->apontado = NULL;
  temp->lineno = parser_lineno; /* guarda o numero da linha da declaracao */

  return insira_simbolo(temp);
}

simbolo_t* declare_ponteiro (char* nome, simbolo_t* apontado, 
			     const TIPO_QUALIFICADOR qual)
{
  simbolo_t* temp = (simbolo_t*) malloc (sizeof(simbolo_t));

  /* ok, vou retornar o simbolo */
  if (qual == BYTE) temp->qualidade = BYTE_PTR;
  else if (qual == WORD) temp->qualidade = WORD_PTR;
  else {
    erro(0, parser_lineno, "(oursym.c) tipo nao implementado");
    return NULL;
  }

  temp->npos = 1;
  temp->nome = nome;
  temp->valor = 0;
  temp->proximo = NULL;
  temp->endereco_byte = NULL;
  temp->endereco_word = NULL;
  temp->apontado = apontado;
  temp->lineno = parser_lineno; /* guarda o numero da linha da declaracao */
  return insira_simbolo(temp);
}

TIPO_QUALIFICADOR strtoqual (const char* chave)
{
  if (strcasecmp(chave, "equ") == 0) return EQU;
  else 
    switch (chave[1]) {
    case 'b':
    case 'B':
      return BYTE;

    case 'w': 
    case 'W':
      return WORD;

    case 'd':
    case 'D': /* double-word */
      return DOUBLEWORD;

    case 'q':
    case 'Q': /* quad-word */
      return QUADWORD;

    }

  return NAOREC;
}

void free_simbolo (simbolo_t* s)
{
  while (s != NULL) {
    simbolo_t* proximo = s->proximo; /* vou perder ponteiro */
    if ( s->nome != NULL) free(s->nome);
    free(s);
    s = proximo;
  }
}

void imprima_simbolo (FILE* f, simbolo_t* s)
{
  fprintf(f, "\"oursym\" ");
  imprima_simbolo_basico(f,s);
  fprintf(f, "\n");
}

void imprima_simbolo_com_posicao (FILE* f, simbolo_t* s)
{
  byte_t* address = (s->endereco_byte == NULL)? (byte_t*)s->endereco_word:
    (byte_t*)s->endereco_byte;
  int isbyte = (s->endereco_byte == NULL)?0:1;

  imprima_simbolo_basico(f,s);
  if (isbyte) fprintf(f, " valor = %02XH ", *address);
  else fprintf(f, " valor = %04XH ", *((word_t*)address) );
  fprintf(f, "/ pos = %04XH", address -inicio_do_codigo(NULL) +ORIGIN_OF_CODE);
  fprintf(f, "\n");
  return;
}

void imprima_simbolo_basico (FILE* f, simbolo_t* s)
{
  fprintf(f, "linha %d, ", s->lineno);
  switch (s->qualidade) {
  case EQU:
    fprintf(f, "const (word-size) \"%s(%d)\"", s->nome, s->npos);
    break;

  case BYTE:
    fprintf(f, "var (byte) \"%s(%d)\"", s->nome, s->npos);
    break;

  case BYTE_PTR:
    fprintf(f, "var (byte-ptr) \"%s -> %s\"", s->nome, s->apontado->nome);
    break;

  case WORD:
    fprintf(f, "var (word) \"%s(%d)\"", s->nome, s->npos);
    break;

  case WORD_PTR:
    fprintf(f, "var (word-ptr) \"%s -> %s\"", s->nome, s->apontado->nome);
    break;

  case NAOREC:
    fprintf(f, "algo deu errado, simbolo nao reconhecido encontrado");
    break;

  default:
    fprintf(f, "var \"%s(%d)\"", s->nome, s->npos);
    break;
  }
  
  return;
}

simbolo_t* insira_simbolo (simbolo_t* novo)
{
  static simbolo_t* tabela = NULL; /* inicializados somente 1 vez */
  static simbolo_t* ultimo;

  if (novo == NULL) return tabela; /* retorna a tabela */

  if ( tabela == NULL ) {
    tabela = novo;
    ultimo = tabela;
    return tabela;
  }

  else {
    if ( procure_simbolo(novo->nome) != NULL ) {
      erro(0, novo->lineno, "(oursym.c) simbolo repetido");
      return NULL;
    }
    /* se chegou aqui e' porque nao tem simbolo repetido */
    ultimo->proximo = novo;
    ultimo = ultimo->proximo;
    return ultimo;
  }
}

