/* Ola emacs, isto aqui e' -*-c-*- */

/* $Id: coding.h,v 1.5 1999/02/01 23:01:35 andre Exp $ */

#ifndef CODING_H
#define CODING_H

#define SIZE_OF_DOT_COM 65536
#define ORIGIN_OF_CODE 0x100

#include "whatis.h"
#include "ourline.h"
#include <stdio.h>

byte_t* codifique (FILE*);
linha_t* resolva_enderecos(void);
void escreva_dot_com(FILE*, byte_t*);
void escreva_com_mnemonicos(FILE*, byte_t*);

/* marcadores de regiao */
byte_t* inicio_do_codigo(byte_t*); /* marca o inicio da area de codigo */
byte_t* fim_do_codigo(byte_t*); /* marca o fim da area de codigo */

int tamanho_da_instrucao(const inst_t*);

#endif /* CODING_H */
