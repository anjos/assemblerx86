/* Ola emacs, isto aqui e' -*-c-*- */
/* $Id: cparser.y,v 1.4 1999/02/01 23:01:38 andre Exp $ */

/* Os "includes" e diretivas inicias em C */
%{
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "cerror.h"
#include "yyerror.h" /* para erro() e aviso() */
#include "init.h" /* as instrucoes e registradores */
#include "ourstr.h" /* para concatena() */
#include "whatis.h" /* para byte_t* */

/* Os prototipos nao declarados */
int yylex(void);
int strcasecmp(const char *s1, const char *s2);

/* a variavel global para o controle do numero da linha */
int cparser_lineno = 1;

/* a variavel para controle de tamanho do codigo lido */
static int code_size = 0;
extern int DEPURA;
%}

/* Agora os tipos de sinais aceitaveis */
%union {
  char* palavra; /* string */
  long inteiro; /* um numero */
  byte_t* codigo; /* um pedaco de codigo */
  reg_t* reg; /* um registrador configurado */
  arg_t* arg; /* um argumento registrado */
  grinst_t* grupo_instrucao; /* um grupo de instrucoes segundo init.h */
  inst_t* instrucao; /* uma instrucao simples */
}

/* Os sinais, sem associacao, precedencia aumenta de cima para baixo */
%token '+' /* soma */
%token ':' /* o separador de instrucoes */
%token '\n' /* reduz o conjunto anterior */
%token ',' /* separar registradores e enderecos - somente 1 por linha */
%token '[' ']'

%token <inteiro> CPARSER_FIM_DE_ARQUIVO
%token <palavra> CPARSER_PALAVRA
%token <reg> CPARSER_REGISTRADOR
%token <inteiro> CPARSER_INTEIRO
%token <inteiro> CPARSER_BYTE
%token <inteiro> CPARSER_WORD
%token <inteiro> CPARSER_ENDERECO
%token <inteiro> CPARSER_DESLOCAMENTO_8
%token <Inteiro> CPARSER_DESLOCAMENTO_16

/* os tipos de sinais */
%type <reg> registrador
%type <codigo> asmcode
%type <grupo_instrucao> gr_instrucao
%type <instrucao> instrucao
%type <arg> argumento
%type <instrucao> linha


/* 
   **********************************************************************
   A Gramatica
   -----------
   obs: A identificacao destas regras so' se da' se os termos sao validos 
   para o analizador lexicografico.
   ********************************************************************** 
*/

%%
entrada: /* vazia */;
entrada: entrada linha;
entrada: entrada CPARSER_FIM_DE_ARQUIVO
/* o que fazer no final, talvez, somente dizer adeus... */
{
  fprintf(stderr, "(parser-cfg) feito.\n");
  YYACCEPT;
}

linha: /* vazia */ '\n' { $$ = NULL; ++cparser_lineno; }

/* ok, agora associamos a configuracao a um codigo. No final conto linha */
linha: instrucao ':' asmcode '\n'
{
  $$ = $1;
  $$->bytes_de_codigo = code_size;
  $$->codigo = $3;
  if (DEPURA) fprintf(stdout, "(parser-cfg) instrucao na linha %d aceita\n", 
		      cparser_lineno);
  ++cparser_lineno; /* tudo feito... */
}

/* *********************************************************** */
/* cada linha abaixo serve para configurar 1 tipo de instrucao */
/* *********************************************************** */

/* o que fazer
   1) verificar se o grupo de instrucoes existe. Caso nao, criar um novo grupo
   2) Caso sim, verificar se a instrucao ja nao existe no novo grupo. Se ja
   existir imprime mensagem aviso e continua;
   2) Caso nao, cria a instrucao no grupo em questao
   3) configura a instrucao de acordo com os parametros da linha de
   configuracao.
*/

/* ex: popf */
instrucao: gr_instrucao
{
  inst_t* esta;
  if ( (esta = ache_instrucao_em_grupo($1, NULL, NULL)) != NULL) {
    char* temp=concatena("(parser-cfg) sobrescrevendo codigo para instrucao ",
			 $1->nome);
    aviso(cparser_lineno, temp);
    free(temp);
    $$ = esta;
  }

  else {
    $$ = nova_instrucao($1);
    $$->nome = $1->nome;
    $$->narg = 0;
    $$->argumento[0] = NULL;
    $$->argumento[1] = NULL;
    $$->adc_byte = 0;
    $$->codigo = NULL;
    $$->bytes_de_codigo = 0;
    $$->proxima = NULL;
  }
  
};

/* ex: call bx ou jmp ax */
instrucao: gr_instrucao argumento
{
  inst_t* esta;
  if ( (esta = ache_instrucao_em_grupo($1, $2, NULL)) != NULL) {
    char* temp=concatena("(parser-cfg) sobrescrevendo codigo para instrucao ",
			 $1->nome);
    aviso(cparser_lineno, temp);
    free(temp);
    $$ = esta;
  }

  else {
    $$ = nova_instrucao($1);
    $$->nome = $1->nome;
    $$->narg = 1;
    $$->argumento[0] = $2;
    $$->argumento[1] = NULL;

    switch($2->tipo) {
    case ARG_WORD:
    case ARG_END:
    case ARG_PTD_END:
    case ARG_DESLOC16:
      $$->adc_byte = 2;
      break;
      
    case ARG_BYTE:
    case ARG_DESLOC8:
    case ARG_PTD_REG_ADJ:
      $$->adc_byte = 1;
      break;
      
    default:
      $$->adc_byte = 0;
      break;
    }

    $$->codigo = NULL;
    $$->bytes_de_codigo = 0;
    $$->proxima = NULL;
  }
}

/* ex: mov [ax], bx => mova o conteudo de bx para endereco apontador por ax */
instrucao: gr_instrucao argumento ',' argumento
{
  inst_t* esta;

  if ( (esta = ache_instrucao_em_grupo($1, $2, $4)) != NULL) {
    char* temp=concatena("(parser-cfg) sobrescrevendo codigo para instrucao ", 
			 $1->nome);
    aviso(cparser_lineno, temp);
    free(temp);
    $$ = esta;
  }

  else {
    arg_t* add;
    if ( (add = escolha_argumento($2, $4)) == NULL ) /* args incompativeis */
      {
	erro(0, cparser_lineno, "(parser-cfg) argumentos incompativeis");
	YYERROR;
      }
    
    $$ = nova_instrucao($1);
    $$->nome = $1->nome;
    $$->narg = 2;
    $$->argumento[0] = $2;
    $$->argumento[1] = $4;

    switch(add->tipo) {
    case ARG_WORD:
    case ARG_END:
    case ARG_DESLOC16:
    case ARG_PTD_END:
      $$->adc_byte = 2;
      break;
      
    case ARG_BYTE:
    case ARG_DESLOC8:
    case ARG_PTD_REG_ADJ:
      $$->adc_byte = 1;
      break;
      
    default:
      $$->adc_byte = 0;
      break;
    }

    $$->codigo = NULL;
    $$->bytes_de_codigo = 0;
    $$->proxima = NULL;
  }
}

/* Argumentos podem ser:
/* a) um registrador identificado pelo scanner */
argumento: registrador
{
  $$ = (arg_t*) malloc (sizeof(arg_t));
  $$->tipo = ARG_REG;
  $$->registrador = $1;
};

/* b) uma palavra chave: byte, word, end ou deslocamento */ 
argumento: CPARSER_BYTE
{ 
  $$ = (arg_t*) malloc (sizeof(arg_t));
  $$->tipo = ARG_BYTE;
  $$->registrador = NULL;
};

argumento: CPARSER_WORD
{
  $$ = (arg_t*) malloc (sizeof(arg_t));
  $$->tipo = ARG_WORD;
  $$->registrador = NULL;
};
  
argumento: CPARSER_ENDERECO
{
  $$ = (arg_t*) malloc (sizeof(arg_t));
  $$->tipo = ARG_END;
  $$->registrador = NULL;
};

argumento: CPARSER_DESLOCAMENTO_8
{ 
  $$ = (arg_t*) malloc (sizeof(arg_t));
  $$->tipo = ARG_DESLOC8;
  $$->registrador = NULL;
};

argumento: CPARSER_DESLOCAMENTO_16
{ 
  $$ = (arg_t*) malloc (sizeof(arg_t));
  $$->tipo = ARG_DESLOC16;
  $$->registrador = NULL;
};

argumento: '[' registrador ']'
{
  $$ = (arg_t*) malloc (sizeof(arg_t));
  $$->tipo = ARG_PTD_REG;
  $$->registrador = $2;
};

argumento: '[' registrador '+' ']'
{
  $$ = (arg_t*) malloc (sizeof(arg_t));
  $$->tipo = ARG_PTD_REG_ADJ;
  $$->registrador = $2;
};

argumento: '[' CPARSER_ENDERECO ']'
{
  $$ = (arg_t*) malloc (sizeof(arg_t));
  $$->tipo = ARG_PTD_END;
  $$->registrador = NULL;
};

/* ***************************************** */
/* Os sinais iniciais que devem ser tratados */
/* ***************************************** */

registrador: CPARSER_REGISTRADOR
{
  $$ = clval.reg;
};

/* o que fazer com a palavra: pegar a string em yylval e alocar um espaco
   especial para esta palavra, antes que yylex() sobrescreva-a */
gr_instrucao: CPARSER_PALAVRA
{
  $$ = novo_grupo_de_instrucoes(clval.palavra);
  if (DEPURA) fprintf(stderr, "(parser-cfg) novo grinst %s\n", $$->nome);
};

/* transforma os numeros lidos em codigos validos para serem apendicionados a
   instrucao. Os numero podem ter 1 ou no maximo 2 bytes. */
asmcode: CPARSER_INTEIRO
{
  if ( (clval.inteiro >> 16) != 0 ) {
    erro(0, cparser_lineno, "(parser-cfg) codigo ASM suspeito");
    YYERROR;
  }

  /* 1 byte */
  if ( (clval.inteiro >> 8) == 0) {
    byte_t* code = (byte_t*) malloc (sizeof(byte_t));
    code[0] = clval.inteiro & 0xff;
    $$ = code;
    code_size = 1;
  }
  
  /* 2 bytes */
  if ( (clval.inteiro >> 16) == 0 && (clval.inteiro >> 8) != 0) {
    byte_t* code = (byte_t*) malloc (2*sizeof(byte_t));
    code[1] = clval.inteiro & 0xff;
    code[0] = (clval.inteiro & 0xff00) >> 8;
    $$ = code;
    code_size = 2;
  }

  if (DEPURA) aviso(cparser_lineno, "(parser-cfg) codigo armazenado");

};

%%
