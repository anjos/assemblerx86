/* Ola emacs, isto aqui e' -*-c-*- */
/* $Id: yyparser.y,v 1.5 1999/02/01 23:01:40 andre Exp $ */

/* Os "includes" e diretivas inicias em C */
%{
#include <math.h>
#include <string.h>
#include <stdio.h>
#include "oursym.h" /* acha e insere simbolos (variaveis) */
#include "ourline.h"
#include "yyerror.h"
#include "init.h" /* as instrucoes e registradores */
#include "coding.h" /* para as rotinas de codificacao */
#include "ourstr.h" /* para concatena() */

/* Os prototipos nao declarados */
int yylex(void);
int strcasecmp(const char *s1, const char *s2);

/* a variavel global para o controle do numero da linha */
int parser_lineno = 1; 

/* a saida de dados */
extern FILE* file_dot_com;
extern int DEPURA;
%}

/* Agora os tipos de "tokens" aceitaveis */
%union {
  char* palavra; /* string */
  long inteiro;
  simbolo_t* simb; /* simbolo */
  rotina_t* rotina; /* uma rotina */
  reg_t* reg; /* um registrador */
  grinst_t* grupo_inst; /* uma instrucao */
  linha_t* lin; /* uma linha */
  operando_t* op; /* um operando */
  vetor_t* vet; /* um vetor de inicializacao */
  TIPO_QUALIFICADOR qual; /* um qualificador */
}

/* As tokens, sem associacao, precedencia aumenta de cima para baixo */
%token '+' /* soma */
%token '&' /* endereco de */
%token '\n' /* reduz o conjunto anterior */
%token ':' /* separar rotulos e instrucoes */
%token ',' /* separar registradores e enderecos - somente 1 por linha */
%token '(' ')'
%token '[' ']'
%token '|' /* indicador que nova linha e' continuacao desta */ 

%token <inteiro> FIM_DE_ARQUIVO

%token <palavra> PARSER_PALAVRA
%token <palavra> PARSER_INSTRUCAO
%token <reg> PARSER_REGISTRADOR
%token <palavra> PARSER_DADOQUALIFIC
%token <inteiro> PARSER_OP_PTR
%token <inteiro> PARSER_OP_OFFSET
%token <inteiro> PARSER_OP_TYPE
%token <inteiro> PARSER_OP_LENGTH
%token <inteiro> PARSER_OP_SIZE
%token <simb> PARSER_SIMBOLO_DECLARADO
%token <inteiro> PARSER_INTEIRO
%token <inteiro> PARSER_DUP
%token <inteiro> PARSER_INDICE
%token <inteiro> PARSER_NEAR
%token <inteiro> PARSER_DECLARE
%token <palavra> PARSER_STRING_DE_NUMEROS

%token <rotina> PARSER_PROCEDIMENTO
%token <palavra> PARSER_PROC_BEGIN
%token <palavra> PARSER_PROC_END

/* *******************************
   Os tipos de grupamentos validos
   ******************************* */

/* 1. Para a area de codigo */
%type <lin> sentenca /* uma frase com '\n' no final */
%type <lin> dado /* um dado foi declarado */
%type <lin> codigo /* uma linha de codigo valido foi declarado */
%type <lin> frase /* uma linha de instrucao na area de codigo */
%type <grupo_inst> grupo_instrucao /* um grupo caracteristico de instrucoes.*/
%type <palavra> rotulo /* um rotulo para a instrucao */
%type <op> operando /* um operando */

/* 2. Para a area de dados */
%type <simb> declaracao /* a declaracao de constantes e variaveis */
%type <simb> variavel /* para quando uma variavel e' detectada */
%type <qual> qualificador /* um qualificador para declaracao de dados */
%type <inteiro> clone /* a base para duplicacao de vetores */
%type <inteiro> indice /* indice de vetores */
%type <vet> inicializacao /* para a inicializacao com valores */

/* 3. Procedimentos */
%type <palavra> proc_begin /* marca o inicio de um procedimento */
%type <palavra> proc_end /* marca o fim de um procedimento */
%type <palavra> prototipo /* a declaracao de um prototipo */

/* 4. Uso geral */
%type <palavra> termo /* uma string nao analizada */
%type <inteiro> numero /* um numero qq */
%type <inteiro> valor /* um valor extraido por operadores SIZE, TYPE ou LENGTH 
		       */ 
%type <reg> registrador
%type <inteiro> endereco_estatico /* um numero cercado de []'s */

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
entrada: entrada sentenca;
entrada: entrada dado;
entrada: entrada codigo;

/* como somente aqui a marca de fim-de-arquivo e' processada, situacoes onde o
   fim de arquivo se encontra na ultima linha podem causar um erro inesperado
*/ 
entrada: entrada FIM_DE_ARQUIVO
/* tenho que executar todas as funcoes de codificacao restantes aqui */
{
  byte_t* dot_com = codifique(stderr);
  linha_t* linha;

  if (dot_com == NULL) {
    erro(0, -1, "=> nao foi possivel codificar o arquivo fonte");
    YYABORT;
  }

  if ( (linha = resolva_enderecos()) != NULL) {
    erro(0, linha->lineno, "(parser) nao posso resolver endereco na linha");
    fprintf(stderr, " >> ");
    imprima_linha(stderr, linha);
    YYERROR; 
  }
  escreva_dot_com(file_dot_com, dot_com);

  fprintf(stderr, "(parser) feito.\n");
  YYACCEPT; /* happy end */
}

/* 1. As instrucoes na area de codigo
   ---------------------------------- */
codigo: frase '\n'
{
  if ( $1 != NULL ) {
    $$ = insira_linha($1, rotina_atual(NULL));
    /* se $1 == NULL, lembre-se que a funcao retorna um ponteiro para a
       1a. linha da rotina, sem inserir nada. */

    if (DEPURA) imprima_linha(stderr, $$);
  }
  ++parser_lineno;

};

dado: declaracao '\n'
/* Ok, aproveitamos este grupo aqui para alocar um simbolo no final do arquivo
   de saida.*/
{
  if (DEPURA) imprima_simbolo(stderr, $1);
  ++parser_lineno;
};

sentenca: prototipo '\n'
{
  if (DEPURA) fprintf(stdout, "!! nova rotina %s\n", $1);
  ++parser_lineno;
};

sentenca: proc_begin '\n'
{
  if (DEPURA) fprintf(stdout, "!! nova rotina %s\n", $1);
  ++parser_lineno;
};

sentenca: proc_end '\n'
{
  if (DEPURA) fprintf(stdout, "!! fim da rotina %s\n", $1);
  ++parser_lineno;
};

frase: rotulo frase
{
  $$ = $2; /* re-passa os dados acumulados */
  $$->rotulo = $1;
};

frase: /* vazia */ { $$ = (linha_t*)NULL; };

frase: grupo_instrucao operando ',' operando
{
  arg_t* arg1 = op2arg($2);
  arg_t* arg2 = op2arg($4);

  $$ = (linha_t*) malloc(sizeof(linha_t));
  $$->rotulo = NULL;
  $$->narg = 2;
  $$->op1 = $2;
  $$->op2 = $4;
  $$->proxima = NULL;
  $$->rotina = NULL;
  $$->lineno = parser_lineno;

  if ( ($$->instrucao = ache_instrucao_em_grupo($1, arg1, arg2)) == NULL ) {
    /* se argumento for do tipo word, posso tentar byte tambem */
    if ($4->tipo == TIPO_WORD) {
      if ( ($4->prop.valor & 0xff) == $4->prop.valor ) { /*testa */
	$4->tipo = TIPO_BYTE;
	arg2->tipo = ARG_BYTE;
      }
      if ( ($$->instrucao = ache_instrucao_em_grupo($1, arg1, arg2))==NULL ) {
	char* mesg = concatena("(parser.y) sintaxe incorreta para ",
			       maiusculas($1->nome));
	erro(0, parser_lineno, mesg);
	fprintf(stderr, " >> ");
	free(mesg);
	free_linha($$);
	free(arg1);
	free(arg2);
	YYERROR;
      }
    }
    else {
      char* mesg = concatena("(parser.y) sintaxe incorreta para ",
			     maiusculas($1->nome));
      erro(0, parser_lineno, mesg);
      fprintf(stderr, " >> ");
      free(mesg);
      free_linha($$);
      free(arg1);
      free(arg2);
      YYERROR;
    }
  }

  free(arg1);
  free(arg2);
};

frase: grupo_instrucao operando
{
  arg_t* arg = op2arg($2);

  $$ = (linha_t*) malloc(sizeof(linha_t));
  $$->rotulo = NULL;
  $$->narg = 1;
  $$->op1 = $2;
  $$->op2 = NULL;
  $$->proxima = NULL;
  $$->rotina = NULL;
  $$->lineno = parser_lineno;

  if ( ($$->instrucao = ache_instrucao_em_grupo($1, arg, NULL)) == NULL ) {

    /* se argumento for do tipo word, posso tentar byte tambem */
    if ($2->tipo == TIPO_WORD) {
      if ( ($2->prop.valor & 0xff) == $2->prop.valor ) { /*testa */
	$2->tipo = TIPO_BYTE;
	arg->tipo = ARG_BYTE;
      }
      if ( ($$->instrucao = ache_instrucao_em_grupo($1, arg, NULL)) == NULL ) {
	char* mesg = concatena("(parser.y) sintaxe incorreta para ",
			       maiusculas($1->nome));
	erro(0, parser_lineno, mesg);
	fprintf(stderr, " >> ");
	free(mesg);
	free_linha($$);
	free(arg);
	YYERROR;
      }
    }

    else {
      char* mesg = concatena("(parser.y) sintaxe incorreta para ",
			     maiusculas($1->nome));
      erro(0, parser_lineno, mesg);
      fprintf(stderr, " >> ");
      free(mesg);
      free_linha($$);
      free(arg);
      YYERROR;
    }
  }

  free(arg);

};

frase: grupo_instrucao
{
  $$ = (linha_t*) malloc(sizeof(linha_t));
  $$->rotulo = NULL;
  $$->narg = 0;
  $$->op1 = NULL;  
  $$->op2 = NULL;
  $$->proxima = NULL;
  $$->rotina = NULL;
  $$->lineno = parser_lineno;
  
  if ( ($$->instrucao = ache_instrucao_em_grupo($1, NULL, NULL)) == NULL ) {
    char* mesg = concatena("(parser.y) sintaxe incorreta para ",
			   maiusculas($1->nome));
    erro(0, parser_lineno, mesg);
    fprintf(stderr, " >> ");
    free(mesg);
    free_linha($$);
    YYERROR;
  }
};

rotulo: termo ':'
{
  $$ = $1;
}

grupo_instrucao: PARSER_INSTRUCAO
{
  $$ = yylval.grupo_inst;
}

/* ********************** */
/* um operando poder ser: */
/* ********************** */

/* a) registrador */
operando: registrador
{
  $$ = (operando_t*) malloc (sizeof(operando_t));
  $$->prop.registrador = $1;
  strcpy($$->prop.nome, yylval.palavra);
  $$->tipo = TIPO_REGISTRADOR;
  $$->lineno = parser_lineno;
  $$->indice = 0;
};

/* b) endereco - max de 16 bits, pois estamos dentro de um segmento */
operando: endereco_estatico
{
  int x = ($1 >> 16);
  if ( x != 0) {
    erro(0, parser_lineno, "(parser.y) erro: endereco > que 16 bits");
    YYERROR;
  }

  $$ = (operando_t*) malloc (sizeof(operando_t));
  $$->prop.endereco = $1;
  $$->tipo = TIPO_ENDERECO;
  $$->lineno = parser_lineno;
  $$->indice = 0;
};

/* c) variavel ou constante */
operando: variavel
{
  $$ = (operando_t*) malloc (sizeof(operando_t));
  $$->prop.simbolo = $1;
  $$->tipo = TIPO_SIMBOLO;
  $$->indice = 0;
  $$->lineno = parser_lineno;
};

/* c.1) vetores, na realidade um sub-caso de c) */
operando: variavel indice
{
  $$ = (operando_t*) malloc (sizeof(operando_t));
  $$->prop.simbolo = $1;
  $$->tipo = TIPO_SIMBOLO;
  $$->indice = $2;
  $$->lineno = parser_lineno;

  /* testando "range" do vetor */
  if (($2) < 0 || ($2) + 1 > $$->prop.simbolo->npos) {
    erro(0, parser_lineno, "(parser.y) indice fora de margem");
    YYERROR;
  }
};

/* d) um procedimento, no caso da instrucao ser um call */
operando: PARSER_PROCEDIMENTO
{
  $$ = (operando_t*) malloc (sizeof(operando_t));
  $$->prop.rotina = yylval.rotina;
  $$->tipo = TIPO_PROCEDIMENTO;
  $$->lineno = parser_lineno;
  $$->indice = 0;
};

/* e) um rotulo declarado ou nao, que sera averiguado no fim do programa */
operando: termo
{
  $$ = (operando_t*) malloc (sizeof(operando_t));
  $$->prop.nome = $1;
  $$->tipo = TIPO_ROTULO;
  $$->lineno = parser_lineno;
  $$->indice = 0;
};

/* f) um numero dado */
operando: numero
{
  const int x = ($1 >> 16);
  if (x != 0) { /* maior que 16 bits... */
    erro(0, parser_lineno, "(parser.y) erro: numero indicado > que 16 bits");
    YYERROR;
  }

  $$ = (operando_t*) malloc (sizeof(operando_t));
  $$->prop.valor = $1;
  $$->tipo = TIPO_WORD; /* recebe o beneficio da duvida: byte ou word? */
  $$->lineno = parser_lineno;
  $$->indice = 0;
};

/* g) um valor extraido por um operador LENGTH, SIZE ou TYPE */
operando: valor
{
  const int x = ($1 >> 8);
  if (x != 0) { /* maior que 8 bits */
    erro(0, parser_lineno, "(parser.y) erro: numero indicado > que 8 bits");
    YYERROR;
  }

  $$ = (operando_t*) malloc (sizeof(operando_t));
  $$->prop.valor = $1;
  $$->tipo = TIPO_WORD; /* recebe o beneficio da duvida: byte ou word? */
  $$->lineno = parser_lineno;    
  $$->indice = 0;
};

/* h) endereco apontado por variavel */
operando: '[' variavel ']'
{
  /* verifica se tamanho da variavel ta legal */
  if ( $2->qualidade != WORD && $2->qualidade != EQU && $2->qualidade !=
       WORD_PTR ) {
    char* temp = concatena("(parser.y) tamanho incorreto para variavel ", 
			   $2->nome);
    erro(0, parser_lineno, temp);
    free(temp);
  }

  /* a verificao de validade de area apontada nao pode ser feita aqui pois 
     o valor e' dinamico, i.e., retirado on-line */

  $$ = (operando_t*) malloc (sizeof(operando_t));
  $$->prop.simbolo = $2;
  $$->tipo = TIPO_APONTADO_SIMB;
  $$->lineno = parser_lineno;
  $$->indice = 0;
};

/* i) endereco apontado por registrador */
operando: '[' registrador ']'
{
  /* a verificao de validade de area apontada nao pode ser feita aqui pois 
     o valor e' dinamico, i.e., retirado on-line */

  $$ = (operando_t*) malloc (sizeof(operando_t));
  $$->prop.registrador = $2;
  $$->tipo = TIPO_APONTADO_REG;
  $$->lineno = parser_lineno;
  $$->indice = 0;
};

/* j) endereco apontado por registrador com ajuste */
operando: '[' registrador '+' numero ']'
{
  /* a verificao de validade de area apontada nao pode ser feita aqui pois 
     o valor e' dinamico, i.e., retirado on-line */

  $$ = (operando_t*) malloc (sizeof(operando_t));
  $$->prop.registrador = $2;
  $$->indice = $4;
  $$->tipo = TIPO_APONTADO_REG_AJUST;
  $$->lineno = parser_lineno;
};

/* k) endereco de uma variavel qq */
operando: PARSER_OP_OFFSET variavel /* por exemplo */
{
  $$ = (operando_t*) malloc (sizeof(operando_t));
  $$->prop.simbolo = $2;
  $$->tipo = TIPO_ENDERECO_VAR;
  $$->lineno = parser_lineno;
  $$->indice = 0;
};

/* l) endereco de uma variavel qq */
operando: '&' variavel /* mesma coisa da letra k) */
{
  $$ = (operando_t*) malloc (sizeof(operando_t));
  $$->prop.simbolo = $2;
  $$->tipo = TIPO_ENDERECO_VAR;
  $$->lineno = parser_lineno;  
  $$->indice = 0;
};

/* 2. As diretivas na area de dados/codigo
   --------------------------------------- */

declaracao: termo qualificador inicializacao /* uma variavel ou constante */
{
  if ( ($$ = declare_simbolo($1, $2, $3)) == NULL ) {
    erro(0, parser_lineno, "(parser.y) Nao posso alocar novo simbolo");
    YYERROR;
  }
  /* Ok, posso liberar $3 */
  free($3);
};

/* isto fica um caso a parte nas declaracoes */
declaracao: termo qualificador numero clone
{
  int it;
  vetor_t* temp = (vetor_t*) malloc (sizeof(vetor_t));
  temp->value = (int*) malloc ($3 * sizeof(int));
  for(it = $3; it > 0; --it) temp->value[it-1] = $4;
  temp->nval = $3;
  
  if ( ($$ = declare_simbolo($1, $2, temp)) == NULL ) {
    erro(0, parser_lineno, "(parser) Nao posso alocar novo simbolo");
    YYERROR;
  }

  free(temp);
};

declaracao: termo qualificador PARSER_OP_PTR variavel
{
  if ( ($$ = declare_ponteiro($1, $4, $2)) == NULL ) {
    erro(0, parser_lineno, "(parser) Nao posso alocar novo simbolo");
    YYERROR;
  }  
};

declaracao: termo PARSER_OP_OFFSET variavel
{
  if ( ($$ = declare_ponteiro($1, $3, WORD)) == NULL ) {
    erro(0, parser_lineno, "(parser) Nao posso alocar novo simbolo");
    YYERROR;
  }
};

variavel: PARSER_SIMBOLO_DECLARADO
{
  $$ = yylval.simb;
};

qualificador: PARSER_DADOQUALIFIC /* representa um qualificador para dados */
{
  $$ = yylval.qual;
};

clone: PARSER_DUP '(' numero ')'
{
  $$ = $3;
};

/* Os tipos "valor" na realidade representam a solucao de uma operacao usando
   SIZE, TYPE ou LENGTH. Podem ser distinguidos do tipo "numero" por esta
   caracteristica. Embora possamos coloca-los numa mesma categoria, prefirimos
   por separa-los. */

/* o tipo da variavel, 1 para byte, 2 para word ou const */
valor: PARSER_OP_TYPE variavel
{
  if ($2->qualidade == EQU || $2->qualidade == WORD_PTR ||
      $2->qualidade == BYTE_PTR) $$ = WORD;
  else $$ = $2->qualidade;
};

/* o numero de posicoes da variavel em questao */
valor: PARSER_OP_LENGTH variavel
{
  $$ = $2->npos;
};

/* o tamanho total ocupado em memoria */
valor: PARSER_OP_SIZE variavel
{
  if ($2->qualidade == EQU || $2->qualidade == WORD_PTR ||
      $2->qualidade == BYTE_PTR) $$ = WORD * $2->npos;
  else $$ = $2->qualidade * $2->npos;
};

/* O processo de inicializacao de vetores com numeros ao inves de indice/dup */
inicializacao: numero
{  
  $$ = (vetor_t*) malloc (sizeof(vetor_t));
  $$->value = (int*) malloc (sizeof(int));
  $$->value[0] = $1; /* se a inicializacao for vazia, comece com zero */
  $$->nval = 1;
};

inicializacao: valor
{  
  $$ = (vetor_t*) malloc (sizeof(vetor_t));
  $$->value = (int*) malloc (sizeof(int));
  $$->value[0] = $1; /* se a inicializacao for vazia, comece com zero */
  $$->nval = 1;
};

/* para casos onde a inicializacao e' feita atraves de uma frase do tipo
   'Universidade Federal do Rio de Janeiro' */
inicializacao: PARSER_STRING_DE_NUMEROS
{
  int it;
  char* este = yylval.palavra;
  $$ = (vetor_t*) malloc (sizeof(vetor_t));
  $$->nval = strlen(este);
  $$->value = (int*) malloc (strlen(este) * sizeof(int));
  for(it=0; it < $$->nval; ++it) $$->value[it] = (int)este[it];
};

/* para o caso de mais de um numero separado por virgulas */
inicializacao: inicializacao ',' numero
{
  $$ = $1;
  $$->value = (int*) realloc ($$->value, ($$->nval+1) * sizeof(int));
  $$->value[$$->nval++] = $3;
};

/* para o caso de mais de um valor separado por virgulas */
inicializacao: inicializacao ',' valor
{
  $$ = $1;
  $$->value = (int*) realloc ($$->value, ($$->nval+1) * sizeof(int));
  $$->value[$$->nval++] = $3;
};

inicializacao: inicializacao ',' PARSER_STRING_DE_NUMEROS
{
  int it;
  char* este = yylval.palavra;
  $$ = $1;
  $$->value =(int*) realloc($$->value, ($$->nval+strlen(este))*sizeof(int));
  for(it=0; it < strlen(este); ++it)
    $$->value[$$->nval++] = (int)este[it];
};

inicializacao: inicializacao '|' '\n' PARSER_DADOQUALIFIC PARSER_STRING_DE_NUMEROS
{
  int it;
  char* este = yylval.palavra;
  $$ = $1;
  $$->value =(int*) realloc($$->value, ($$->nval+strlen(este))*sizeof(int));
  for(it=0; it < strlen(este); ++it)
    $$->value[$$->nval++] = (int)este[it];
  ++parser_lineno;
};

inicializacao: inicializacao '|' '\n'  PARSER_DADOQUALIFIC numero
{
  $$ = $1;
  $$->value = (int*) realloc ($$->value, ($$->nval+1) * sizeof(int));
  $$->value[$$->nval++] = $5;
  ++parser_lineno;
};

inicializacao: inicializacao '|' '\n'  PARSER_DADOQUALIFIC valor
{
  $$ = $1;
  $$->value = (int*) realloc ($$->value, ($$->nval+1) * sizeof(int));
  $$->value[$$->nval++] = $5;
  ++parser_lineno;
};

/* a referencia de vetores por um numero, indicando indice */
indice: '(' numero ')'
{
  $$ = $2;
};

/* 3. Procedimentos
   ---------------- */

prototipo: PARSER_DECLARE termo
{
  /* cria espaco para nova rotina */
  rotina_t* tmp = nova_rotina($2, parser_lineno); 
  if ( tmp == NULL ) YYERROR; /* aborta se nao conseguir... */
  $$ = $2;
}

proc_begin: termo PARSER_PROC_BEGIN  PARSER_NEAR /* inicia novo procedimento */
{
  /* cria espaco para nova rotina */
  rotina_t* tmp = nova_rotina($1, parser_lineno); 

  if ( tmp == NULL ) YYERROR; /* aborta se nao conseguir... */
  rotina_atual($1); /* pula para container da nova rotina */
  $$ = $1;
};

proc_begin: PARSER_PROCEDIMENTO PARSER_PROC_BEGIN PARSER_NEAR
/* inicia novo procedimento declarado */
{
  /* cria espaco para nova rotina */
  rotina_t* tmp = nova_rotina(yylval.rotina->nome, parser_lineno); 

  if ( tmp == NULL ) YYERROR; /* aborta se nao conseguir... */
  rotina_atual(yylval.rotina->nome); /* pula para container da nova rotina */
  $$ = yylval.rotina->nome;
};

proc_begin: PARSER_PROCEDIMENTO PARSER_PROC_BEGIN /* inicia novo procedimento,
						     declarado */
{
  /* cria espaco para nova rotina */
  rotina_t* tmp = nova_rotina(yylval.rotina->nome, parser_lineno); 

  if ( tmp == NULL ) YYERROR; /* aborta se nao conseguir... */
  rotina_atual(yylval.rotina->nome); /* pula para container da nova rotina */
  $$ = yylval.rotina->nome;
};

proc_begin: termo PARSER_PROC_BEGIN /* inicia novo procedimento */
{
  /* cria espaco para nova rotina */
  rotina_t* tmp = nova_rotina($1, parser_lineno); 

  if ( tmp == NULL ) YYERROR; /* aborta se nao conseguir... */
  rotina_atual($1); /* pula para container da nova rotina */
  $$ = $1;
};

proc_end: PARSER_PROCEDIMENTO PARSER_PROC_END /* fecha, proc ja existente */
{
  if (yylval.rotina != rotina_atual(NULL)) { /* posso fazer isto pois 
						PROC_END nao altera yylval!! */
    char* mesg = concatena("(parser.y) erro: a rotina aberta e' ",
			   (rotina_atual(NULL))->nome);
    erro(0, parser_lineno, mesg);
    free(mesg);
    YYERROR;
  }

  /* verifica se procedimento tem RET no final */
  if ( strcasecmp(yylval.rotina->ultima->instrucao->nome, "ret") != 0) {
    char* mesg = concatena("(parser) erro: faltando \"RET\" em rotina ",
			   yylval.rotina->nome);
    erro(0, parser_lineno, mesg);
    YYERROR;
  }

  /* imprime a rotina antes de trocar pela rotina principal */
  if (DEPURA) imprima_rotina(stderr, rotina_atual(NULL) );

  /* volta a rotina principal */
  rotina_atual("main"); /* volta para o container principal */
  $$ = yylval.rotina->nome;

};

/* 4. Uso Geral
   ------------ */

/* o que fazer com a palavra: pegar a string em yylval e alocar um espaco
   especial para esta palavra, antes que yylex() sobrescreva-a */
termo: PARSER_PALAVRA
{
  $$ = (char*) malloc(strlen(yylval.palavra) + 1);
  strcpy($$, yylval.palavra); /* ok, palavra salva! */
};

registrador: PARSER_REGISTRADOR
{
  $$ = yylval.reg;
}

endereco_estatico: '[' numero ']' { $$ = $2; };

numero: PARSER_INTEIRO
{
  $$ = yylval.inteiro;
};

%%
