/* Ola emacs, isto e -*-c-*- */ 
/* $Id: main.c,v 1.6 1999/01/29 19:52:38 andre Exp $ */

#include <stdio.h>
#include <unistd.h>
#include "init.h"
#include "ourline.h" /* A definicao do que e' uma linha */
#include "oursym.h" /* A definicao do que e' um simbolo */
#include "yywrap.h"
#include "yyerror.h"
#include "yyparser.h"

/* para o processamento de opcoes */
extern char *optarg;
extern int optind, opterr, optopt;

int getopt(int argc, char * const argv[], const char *optstring);

/* para a saida de dados */
FILE* file_dot_com = stdout;

/* Os prototipos e variaveis globais nao definidos nos cabecalhos */
extern int yyparse(void);
extern int cparse(void);
extern FILE* yyin;
extern FILE* cin;
extern int yydebug;
extern int cdebug;

/* Depura? */
int DEPURA = 0; /* 0 == nao depura, 1 == depura */

int main (int argc, char** argv)
{
  FILE* entrada = stdin;
  char* ins_filename = "config/instruc.cfg";
  FILE* ins_fileptr;
  char* reg_filename = "config/regist.cfg";
  FILE* reg_fileptr;

  int c;
  while ( (c = getopt(argc, argv, "a:i:r:o:hg")) != EOF) {
    switch (c) {
    case 'a': /* arquivo de entrada mudado ! */
      if ((entrada = fopen(optarg, "rt")) == NULL) {
	yyerror("Arquivo de entrada nao disponivel\n");
	return 0;
      }
      break;

    case 'i': /* arquivo de instrucoes mudado */
      ins_filename = (char*) malloc (strlen(optarg) +1);
      strcpy (ins_filename, optarg);
      break;

    case 'r':
      reg_filename = (char*) malloc (strlen(optarg) +1);
      strcpy (reg_filename, optarg);
      break;

    case 'o':
      if ((file_dot_com = fopen(optarg, "wb")) == NULL) {
	yyerror("Arquivo de saida nao disponivel\n");
	return 0;
      }
      break;

    case 'g':
      DEPURA = 1;
      break;
      
    case 'h':
    default:
      fprintf(stdout, "uso: %s [opcoes]\n", argv[0]);
      fprintf(stdout, "-a arquivo_de_entrada (default: stdin)\n");
      fprintf(stdout, "-i arquivo_de_instrucoes ");
      fprintf(stdout, "(default: %s)\n", ins_filename);
      fprintf(stdout, "-r arquivo_de_registradores ");
      fprintf(stdout, "(default: %s)\n", reg_filename);
      fprintf(stdout, "-o arquivo_de_saida (default: stdout)\n");
      fprintf(stdout, "-g <ativa depuracao>\n");
      fprintf(stdout, "-h \"esta ajuda\"\n");
      return(0);
    }
    
  }

  /* abre os arquivos de com a configuracao inicial */

  /* os registradores */
  if ((reg_fileptr = fopen(reg_filename, "rt")) == NULL) {
    yyerror("Arquivo de registradores nao disponivel\n");
    return 0;
  }

  /* as instrucoes */
  if ((ins_fileptr = fopen(ins_filename, "rt")) == NULL) {
    yyerror("Arquivo de instrucoes nao disponivel\n");
    return 0;
  }

  yyin = entrada; /* seta o arquivo de entrada a ser compilado */
  cin = ins_fileptr; /* seta o arquivo de instrucoes */

  yylval.palavra = seta_espaco(0); /* max chars == 50 */

  /* yydebug = 1; ativa depurador do bison
     cdebug = 1; ativa depurador para o configurador */
  
  inicialize_registradores(reg_fileptr);

  if (cparse()) { /* inicializa instrucoes */
    fprintf(stderr, "(main.c) Nao posso inicializar\n");
    return 0;
  }

  yyparse(); /* monta arquivo de entrada */

  return 1;
}
