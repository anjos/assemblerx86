/* Ola emacs, este arquivo e' um codigo em -*-c-*- */

/* $Id: init.h,v 1.6 1999/02/01 23:01:36 andre Exp $ */

#ifndef INIT_HEADER_H
#define INIT_HEADER_H

#include "whatis.h"

struct operando_t;

/* tipos sao: a. word; b. byte; c. endereco podendo ser um endereco estatico ou
   um simbolo declarado; d. endereco apontado por registrador; e. endereco
   apontado por endereco estatico ou simbolo declarado; f. endereco apontado
   por registrador ajustado */
typedef enum {ARG_WORD, ARG_BYTE, ARG_END, ARG_DESLOC8, ARG_DESLOC16, 
	      ARG_REG, ARG_PTD_REG, ARG_PTD_END, 
	      ARG_PTD_REG_ADJ} TIPO_ARGUMENTO;

typedef struct reg_t { /* o tipo registrador */
  char* nome;
  char* apelido; /* aceita referencias a ('e' + nome) */
  struct reg_t* proximo;
} reg_t;

typedef struct arg_t { /* o tipo argumento */
  TIPO_ARGUMENTO tipo;
  reg_t* registrador;
} arg_t;

typedef struct inst_t { /* o tipo instrucao */
  char* nome; /* aponta para nome do grupo */
  int narg;
  arg_t* argumento[2];
  int adc_byte; /* adicione byte `a instrucao 0=false; 1=byte; 2=word */
  byte_t* codigo; /* o codigo a ser colocado no arquivo de saida */
  int bytes_de_codigo; /* no. de bytes de codigo total */
  struct inst_t* proxima; /* a proxima instrucao do mesmo grupo */
} inst_t;

typedef struct grinst_t { /* o tipo grupo de instrucoes */
  char* nome;
  inst_t* primeira;
  inst_t* ultima;
  struct grinst_t* proximo;
} grinst_t;

/* para lidar com registradores */
reg_t* registradores (void); /* retorna o 1o. registrador alocado */
reg_t* inicialize_registradores (FILE*);
reg_t* ache_registrador (const char*); /* acha um registrador indicado por 
					 chave */

/* para lidar com as instrucoes e grupos de instrucoes */
/* *************************************************** */

grinst_t* novo_grupo_de_instrucoes (const char*); /* retorna o grupo de
						     instrucoes indicado por
						     chave ou cria novo grupo
						  */ 
inst_t* nova_instrucao (grinst_t*); /* cria nova instrucao no grupo de
				       instrucoes */
grinst_t* ache_grupo_de_instrucoes (const char*); /* retorna o grupo de
						     instrucoes indicado por
						     chave */
inst_t* ache_instrucao_em_grupo (const grinst_t*, const arg_t*, const arg_t*);
int compare_argumentos(const arg_t*, const arg_t*);
arg_t* escolha_argumento(arg_t*, arg_t*);
arg_t* op2arg(const struct operando_t*);

#endif /* INIT_HEADER_H */
