/* Ola emacs, este arquivo e' um codigo em -*-c-*- */

/* $Id: ourline.c,v 1.12 1999/01/27 03:23:37 andre Exp $ */

#include <string.h>
#include <stdlib.h>
#include "ourline.h"
#include "ourstr.h"
#include "yyerror.h"
#include "coding.h"

/* o invisivel */
int strcasecmp(const char *s1, const char *s2);
void imprima_op(FILE*, const operando_t*);
byte_t* procure_rotulo_rotina(const char*, const rotina_t*);

extern int parser_lineno;

rotina_t* nova_rotina(char* nome, const int lineno)
{
  static rotina_t* main = NULL;
  static rotina_t* ultima;
  rotina_t* temp;
  
  if (main == NULL) { /* cria espaco para main */
      main = (rotina_t*) malloc (sizeof(rotina_t));
      main->nome = "main";
      main->primeira = NULL;
      main->ultima = NULL;
      main->proxima = NULL;
      ultima = main;
  }

  if (nome == NULL || nome == "main" ) return main; 

  /* se chegou aqui e' porque ja existe pelo menos 1 rotina (main) */
  if ( (temp = procure_rotina(nome)) != NULL ) {
    char* mesg = concatena("(ourline.c) Reabrindo rotina para escrita -> ",
			   temp->nome);
    aviso(lineno, mesg);
    free(mesg);
    return temp; /* para o caso de se declarar rotinas */
  }

  ultima->proxima = (rotina_t*) malloc (sizeof(rotina_t));
  ultima = ultima->proxima;
  ultima->nome = nome;
  ultima->primeira = NULL;
  ultima->ultima = NULL;
  ultima->proxima = NULL;
  return ultima;
}

rotina_t* procure_rotina(const char* chave)
{
  rotina_t* iterador = nova_rotina((char*)NULL, 0);

  if ( iterador == NULL ) return NULL; /* previne trabalho desnecessario */

  while(iterador != NULL) {
    if ( strcasecmp(iterador->nome, chave) == 0 ) return iterador;
    iterador = iterador->proxima;
  }
  return NULL; /* se chegou ate aqui e' porque nao encontrou */
}

void imprima_linha(FILE* out, const linha_t* l)
{
  if (l == NULL) return; /* faz nada */

  fprintf(out, "\"ourline\" linha %d, ", l->lineno);

  if (l->rotulo != NULL) fprintf(out, "%s: ", l->rotulo);

  fprintf(out, "%s", maiusculas((l->instrucao)->nome) );

  if (l->op1 != NULL) {
    fprintf(out, " "); /* separador */
    imprima_op(out, l->op1);
  }

  if ( l->op2 != NULL) {
    fprintf(out, ", "); /* separador */
    imprima_op(out, l->op2);
  }
  
  fprintf(out, "\n");
}

byte_t* imprima_linha_com_codigos(FILE* out, const linha_t* l, byte_t* stream)
{
  int it = tamanho_da_instrucao(l->instrucao);
  int counter;

  if (l == NULL) return stream; /* faz nada */

  fprintf(out, "linha %d, ", l->lineno);

  if (l->rotulo != NULL) fprintf(out, "%s: ", l->rotulo);

  fprintf(out, "%s", maiusculas((l->instrucao)->nome) );

  if (l->op1 != NULL) {
    fprintf(out, " "); /* separador */
    imprima_op(out, l->op1);
  }

  if ( l->op2 != NULL) {
    fprintf(out, ", "); /* separador */
    imprima_op(out, l->op2);
  }
  
  fprintf(out, " (codigo: ");
  counter = 0;
  while (it-- != 0) fprintf(out, "%02X",*(stream+counter++));
  fprintf(out, ") inicio em %04XH\n", stream - inicio_do_codigo(NULL)
	  + ORIGIN_OF_CODE);

  return (stream + tamanho_da_instrucao(l->instrucao));
}

void imprima_op (FILE* out, const operando_t* op)
{
  switch(op->tipo) {

  case TIPO_ENDERECO:
    fprintf(out, "endereco estatico(%04lXH)", op->prop.endereco );
    break;

  case TIPO_SIMBOLO:
    if ( (op->prop.simbolo)->qualidade == EQU )  fprintf(out, "const ");
    else fprintf(out, "var ");

    fprintf(out, "%s[%d]", (op->prop.simbolo)->nome, op->indice);
    break;

  case TIPO_REGISTRADOR:
    fprintf(out, "%s", (op->prop.registrador)->nome);
    break;

  case TIPO_PROCEDIMENTO:
    fprintf(out, "proc(%s)", (op->prop.rotina)->nome);
    break;

  case TIPO_ROTULO:
    fprintf(out, "rotulo(%s)", op->prop.nome);
    break;

  case TIPO_WORD:
    fprintf(out, "dw(%lxH)", op->prop.valor);
    break;

  case TIPO_BYTE:
    fprintf(out, "db(%lxH)", op->prop.valor);
    break;

  case TIPO_APONTADO_SIMB:
    fprintf(out, "[%s]", op->prop.simbolo->nome);
    break;

  case TIPO_APONTADO_REG:
    fprintf(out, "[%s]", op->prop.registrador->nome);
    break;

  case TIPO_APONTADO_REG_AJUST:
    fprintf(out, "[%s + %xH]", op->prop.registrador->nome,
	    op->indice);
    break;

  case TIPO_ENDERECO_VAR:
    fprintf(out, "endereco de %s", op->prop.simbolo->nome);
    break;

  }

}

void free_linha(linha_t* l)
{
  if (l == NULL) return; /* volta! */
  if (l->rotulo != NULL) free(l->rotulo);

  if (l->op1 == NULL) return; /* nao verifica op2... */
  if ((l->op1)->tipo == TIPO_REGISTRADOR) free((l->op1)->prop.nome);
  free (l->op1);

  if (l->op2 == NULL) return;
  if ((l->op2)->tipo == TIPO_REGISTRADOR) free((l->op2)->prop.nome);
  free (l->op2);

  return;
}

void free_rotina(linha_t* p)
{
  if (p->proxima != NULL) free_rotina(p->proxima);
  free_linha(p);
  free(p);
}

linha_t* insira_linha(linha_t* l, rotina_t* rotina)
{
  rotina_t* r = rotina;

  /* se o programador nao especificou a rotina, esta sera' a rotina atual, mas
     no caso desta nao existir, "main" deve ser criada e retornada. */
  if ( (r = rotina_atual(NULL)) == NULL )  r = rotina_atual("main");

  if ( l == NULL ) return r->primeira;

  l->rotina = r; /* marca a rotina da linha para orientacao futura */
  
  if ( r->primeira == NULL ) /* e' a 1a. */ {
    r->primeira = l;
    (r->primeira)->proxima = NULL;
    r->ultima = r->primeira;
  }

  else {
    (r->ultima)->proxima = l;
    r->ultima = (r->ultima)->proxima;
    (r->ultima)->proxima = NULL;
  }
  
  return r->ultima;
}

void imprima_rotina(FILE* out, rotina_t* r)
{
  linha_t* iterador = r->primeira;
  if (iterador == NULL) return;

  fprintf(out, "\n>> INICIO de proc \"%s\"\n", r->nome);
  while (iterador != NULL) {
    imprima_linha(out, iterador);
    iterador = iterador->proxima;
  }
  fprintf(out, ">> FIM de proc \"%s\"\n\n", r->nome);

  return;
}

byte_t* imprima_rotina_com_codigos(FILE* out, rotina_t* r, byte_t* stream)
{
  linha_t* iterador = r->primeira;
  byte_t* pos = stream;

  if (iterador == NULL) return stream;

  fprintf(out, "\n>> INICIO de proc \"%s\" na posicao %XH\n", r->nome,
	  pos - inicio_do_codigo(NULL) + ORIGIN_OF_CODE);
  while (iterador != NULL) {
    pos = imprima_linha_com_codigos(out, iterador, pos);
    iterador = iterador->proxima;
  }
  fprintf(out, ">> FIM de proc \"%s\"\n\n", r->nome);

  return pos;
}

rotina_t* rotina_atual(char* nova)
{
  static rotina_t* r = NULL;
  if (nova != NULL) r = procure_rotina(nova);
  return r;
}

byte_t* procure_rotulo(const char* chave)
{
  rotina_t* iterador = nova_rotina((char*)NULL, 0); /* retorna main */

  if ( chave == NULL) return NULL;

  while(iterador != NULL) {
    byte_t* it;
    if ( ( it = procure_rotulo_rotina(chave, iterador)) != NULL ) return it;
    iterador = iterador->proxima;
  }

  return NULL; /* se chegou ate aqui e' porque nao encontrou */  
}

byte_t* procure_rotulo_rotina(const char* chave, const rotina_t* r)
{
  linha_t* it = r->primeira;

  while(it != NULL) {
    if ( it->rotulo != NULL && strcasecmp(chave, it->rotulo) == 0) 
      return it->posicao;
    it = it->proxima;
  }
  
  return NULL;
}

