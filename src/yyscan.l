/* Ola emacs, isto e -*-c-*- */
/* $Id: yyscan.l,v 1.5 1999/02/01 23:01:40 andre Exp $ */

%option nounput

%{ /* As diretivas de inclusao */
#include <stdio.h>
#include <string.h> /* Para strcpy() e outras */
#include "ourline.h" /* A definicao do que e' uma linha de codigo e rotinas */
#include "oursym.h" /* A definicao do que e' um simbolo alocavel */
#include "yyparser.h" /* As definicoes do Bison */
#include "yywrap.h" /* A funcao wrapper */
#include "init.h" /* O que e' inst_t e reg_t */

/* para a contagem de linhas - aqui so conta quando o '\n' estiver depois de
   um comentario */
extern int parser_lineno;
extern int DEPURA;
%}

/* A gramatica do analizador lexicografico */
%%

[+-]?(0[Xx])[a-fA-F0-9]+ { /* Para hexadecimais no formato 0xN... ou 0X...  */
  yylval.inteiro = strtol(yytext, NULL, 16); 
  if (DEPURA) fprintf(stdout, "(scanner) inteiro(%lxh)\n", yylval.inteiro);
  return PARSER_INTEIRO;
}

[+-]?[0-9]+ { /* Para numeros decimais */
  yylval.inteiro = strtol(yytext, NULL, 10);
  if (DEPURA) fprintf(stdout, "(scanner) inteiro(%lxh)\n", yylval.inteiro);
  return PARSER_INTEIRO;
}

\'[a-zA-Z0-9 \_\t\:\@\\.\-\!]+\' { /* frase entre aspas */
  yylval.palavra = seta_espaco(1);
  strncpy(yylval.palavra, (yytext+1), yyleng);
  yylval.palavra[yyleng - 2] = yylval.palavra[yyleng - 1]; 
  if (DEPURA) fprintf(stdout, "(scanner) init string - \'%s\'\n",
		      yylval.palavra);
  return PARSER_STRING_DE_NUMEROS;
}

declare {
  /* declaracao de prototipos */
  if (DEPURA) fprintf(stdout, "(scanner) DECLARE\n");
  return PARSER_DECLARE;
}

dup {
  /* indicacao para a duplicacao de dados em vetores */
  if (DEPURA) fprintf(stdout, "(scanner) DUP\n");
  return PARSER_DUP;
}
  
equ|db|dw|dd|dq { /* os tipos de dado */

  yylval.qual = strtoqual(yytext);
  if (DEPURA) fprintf(stdout, "(scanner) tipo de dado(%s)\n", yytext);
  return PARSER_DADOQUALIFIC;

}

proc { /* inicio de novo procedimento */
  return PARSER_PROC_BEGIN;
}

endp { /* fim de procedimento */
  return PARSER_PROC_END;
}

near { /* so para compatibilidade */
  return PARSER_NEAR;
}

ptr {
  if (DEPURA) fprintf(stdout, "(scanner) operador(%s)\n", yytext);
  return PARSER_OP_PTR;
}

offset {
  if (DEPURA) fprintf(stdout, "(scanner) operador(%s)\n", yytext);
  return PARSER_OP_OFFSET;  
}

size {
  if (DEPURA) fprintf(stdout, "(scanner) operador(%s)\n", yytext);
  return PARSER_OP_SIZE;
}

length {
  if (DEPURA) fprintf(stdout, "(scanner) operador(%s)\n", yytext);
  return PARSER_OP_LENGTH;
}

type {
  if (DEPURA) fprintf(stdout, "(scanner) operador(%s)\n", yytext);
  return PARSER_OP_TYPE;
} 

[a-z\_][a-z0-9]*\_*\-*[a-z0-9]* { /* qq palavra valida para o parser */
  /* algumas variaveis necessarias */
  simbolo_t* temp_simb;
  grinst_t* temp_inst;
  rotina_t* temp_rot;
  reg_t* temp_reg;

  yylval.palavra = seta_espaco(1); /* recupera o espaco reservado. A
				      inexistencia deste espaco pode levar
				      strcpy() a rejeitar a operacao ==
				      "core dump" */
  strcpy(yylval.palavra, yytext);

  if ( (temp_inst = ache_grupo_de_instrucoes(yylval.palavra)) != NULL) {
    if (DEPURA) fprintf(stdout, "(scanner) instrucao(%s)\n", yytext);
    yylval.grupo_inst = temp_inst;
    return PARSER_INSTRUCAO;
  }

  if ( (temp_reg = ache_registrador(yylval.palavra)) != NULL ) {
    if (DEPURA) fprintf(stdout, "(scanner) registrador(%s)\n", yytext);
    yylval.reg = temp_reg;
    return PARSER_REGISTRADOR;
  }

  if ( (temp_simb = procure_simbolo(yylval.palavra)) != NULL ) {
    yylval.simb = temp_simb;
    if (DEPURA) fprintf(stdout, "(scanner) simbolo(%s)\n", yylval.simb->nome);
    return PARSER_SIMBOLO_DECLARADO;
  }

  if ( (temp_rot = procure_rotina(yylval.palavra)) != NULL) {
    if (DEPURA) fprintf(stdout, "(scanner) rotina(%s)\n", temp_rot->nome);
    yylval.rotina = temp_rot;
    return PARSER_PROCEDIMENTO;
  }

  /* se chegou aqui e' porque e' nao e' instrucao nem registrador */
  if (DEPURA) fprintf(stdout, "(scanner) ");
  if (DEPURA) fprintf(stdout, "palavra(%s)\n", yytext);
  return PARSER_PALAVRA;
}

[+-]?[a-fA-F0-9]*[hH] { /* para numeros hexa no formato NNN...H ou NNN...h */
  yylval.inteiro = strtol(yytext, NULL, 16); /* converte ate achar o 'h' */
  if (DEPURA) fprintf(stdout, "(scanner) inteiro(%lxh)\n", yylval.inteiro);
  return PARSER_INTEIRO;
}

[ \t]*   /* destroi espacos em branco */

\;\t*[[:print:]\t]* { /* comeca comentario, elimino tudo depois */
  if (DEPURA) fprintf(stdout, "(scanner) comentario\n");
}

\, { /* separador de operadores ou elementos de vetores */
  return ',';
}

\: { /* separador de rotulo */
  return ':';
}

\n { /* fim-de-linha */
  return '\n';
}

\( { /* inicio de endereco */
  return '(';
}

\) { /* fim de endereco */
  return ')';
}

\[ { /* inicio de valor para vetores */
  return '[';
}

\] { /* fim de valor para vetores */
  return ']';
}

\+ { /* soma */
  return '+';
}

\& { /* endereco de */
  return '&';
}

\| { /* continuacao */
  return '|';
}

<<EOF>> {
  return FIM_DE_ARQUIVO; /* Ok, retorna que o arquivo chegou no final */
}

. { /* qq outra coisa */
   fprintf(stderr, "%d: erro de sintaxe -> \"%s\"\n", parser_lineno, yytext);
   return 0; /* para quando encontra um erro */
  }





