/* Ola emacs, isto aqui e' -*-c-*- */
/* $Id: coding.c,v 1.11 1999/02/01 23:01:37 andre Exp $ */

#include "oursym.h"
#include "ourline.h"
#include "coding.h"
#include "yyerror.h"
#include "init.h"
#include "ourstr.h"
#include <string.h>
#include <stdlib.h>

/* o invisivel */
int strcasecmp(const char* s1, const char* s2);

/* marcadores de regiao */
byte_t* inicio_do_codigo(byte_t*); /* marca o inicio da area de codigo */
byte_t* fim_do_codigo(byte_t*); /* marca o fim da area de codigo */

/* alocadores especializados */
byte_t* aloque_dados (byte_t*);
byte_t* aloque_simbolo (simbolo_t*, byte_t*);
byte_t* aloque_codigo (byte_t*);
byte_t* aloque_rotina (rotina_t*, byte_t*);

/* para a resolucao de enderecos */
int resolva_enderecos_na_linha (linha_t*);
word_t resolva_operando (operando_t*, const int);
operando_t* escolha_op (linha_t*);

/* fancy writting */
void escreva_com_mnemonicos(FILE*, byte_t*);

/* calcula os tamanhos de rotinas, simbolos e do programa final em si */
int verifica_espaco_necessario(FILE*);
int tamanho_da_rotina(const rotina_t*);
int tamanho_da_area_de_codigo(void);
int tamanho_do_simbolo(const simbolo_t*);
int tamanho_da_area_de_dados(void);
int tamanho_total(void);

/* aloca todos os dados do programa - so pode ser chamada 1 vez */
byte_t* aloque_dados (byte_t* last_free)
{
  simbolo_t* primo = insira_simbolo(NULL);
  simbolo_t* it;
  
  for(it = primo; it != NULL; it = it->proximo) 
    last_free = aloque_simbolo(it, last_free);

  return last_free;
}

/* aloca um simbolo qualquer no arquivo de saida */
byte_t* aloque_simbolo (simbolo_t* este, byte_t* last_free)
{
  int idx;

  switch (este->qualidade) {
  case EQU: /* Constantes terao 16 bits */
  case WORD:
    last_free -= (2 * este->npos); /* reduz o contador de espaco para vars */

    /* atribui o endereco da variavel a propria */
    este->endereco_word = (word_t*)(last_free + 1);

    /* testa e corrige valores */
    for(idx = 0; idx < este->npos; ++idx) {
      long temp = este->valor[idx] & 0xffff;
      if ( este->valor[idx] != temp ) {
	/* tem mais que 16 bits, truncando */
	aviso(este->lineno, "(coding.c) vou truncar simbolo...");
	fprintf(stdout,"...truncando para %lxH\n", temp);
	este->valor[idx] = temp;
      }
    }
    
    /* coloca os valores nas posicoes devidas */
    for(idx = 0; idx < este->npos; ++idx)
      este->endereco_word[idx] = este->valor[idx]; /* pega os 2 LSB's de cara
						      pois a maquina e' little
						      endian ja'. */

    este->endereco_byte = NULL;
    break;

  case BYTE_PTR: /* ja organizado para implementar vetor de ponteiros */
  case WORD_PTR: /* ambos tem size == 2 */
    last_free -= (2 * este->npos); /* reduz o contador de espaco para vars */

    /* atribui o endereco da variavel a propria */
    este->endereco_word = (word_t*)(last_free + 1);

    for(idx = 0; idx < este->npos; ++idx) {
      dword_t address;
      if ( este->apontado->endereco_byte == NULL )
	address = (dword_t)este->apontado->endereco_word;
      else
	address = (dword_t)este->apontado->endereco_byte;

      address -= (dword_t)inicio_do_codigo(NULL);
      address += ORIGIN_OF_CODE;

      este->endereco_word[idx] = (word_t)(address & 0xffff);
    }

    este->endereco_byte = NULL;
    break;

  case BYTE: /* ok para vetores */
    last_free -= (este->npos);
    este->endereco_byte = (byte_t*)(last_free + 1);

    for (idx = 0; idx < este->npos; ++idx) {
      long temp = este->valor[idx] & 0xff;
      if ( este->valor[idx] != temp ) {
	/* tem mais que 8 bits, truncando */
	aviso(este->lineno, "(coding.c) vou truncar simbolo...");
	fprintf(stdout,"...truncando para %lxH\n", temp);
	este->valor[idx] = temp;
      }
    }

    for(idx = 0; idx < este->npos; ++idx)
      este->endereco_byte[idx] = este->valor[idx]; /* pega o 1o. LSB */

    este->endereco_word = NULL;
    break;

  case NAOREC:
  default:
    erro(0, este->lineno, 
	 "(coding.c) tipos de dados nao implementados: dword e qword");
    return NULL;
  }

  return last_free;
}

/* aloca todos os dados do programa */
byte_t* aloque_codigo (byte_t* first_free)
{
  rotina_t* prima = nova_rotina(NULL, 0);
  rotina_t* it;
  
  for(it = prima; it != NULL; it = it->proxima)
    first_free = aloque_rotina(it, first_free);
  
  return first_free;
} 

byte_t* aloque_rotina (rotina_t* esta, byte_t* first_free)
{
  linha_t* it;
  int jt;

  esta->posicao = first_free;
  for(it = esta->primeira; it != NULL; it = it->proxima) /* todas as linhas */
    {
      it->posicao = first_free;
      first_free += tamanho_da_instrucao(it->instrucao); /* atualiza ptr */
      for(jt=0; jt < (it->instrucao)->bytes_de_codigo; ++jt)
	it->posicao[jt] = (it->instrucao)->codigo[jt];
    }

  return first_free;
}

byte_t* inicio_do_codigo(byte_t* new)
{
  static byte_t* l = NULL;
  if ( new != NULL && l == NULL) l = new;
  return l;
}

byte_t* fim_do_codigo(byte_t* new)
{
  static byte_t* l = NULL;
  if ( new != NULL && l == NULL) l = new;
  return l;
}

/* a funcao que aloca main esta separada das demais pois e' necessaria a
   realocacao das outras rotinas e variaveis. */
byte_t* codifique (FILE* erros)
{
  if (verifica_espaco_necessario(erros) == 0) {
    erro(0, -1, "=> sobrecarga de instrucoes e simbolos");
    return NULL;
  }

  /* os ponteiros tem que estar adjacentes neste momento */
  if ( aloque_codigo(inicio_do_codigo(NULL)) !=
       aloque_dados(fim_do_codigo(NULL)) +1 )
    {
      erro(0, - 1, "=> algo nao vai bem por aqui. diagnosticos:");
      fprintf(stderr, " inicio do codigo = %p\n", inicio_do_codigo(NULL));
      fprintf(stderr, " fim do codigo    = %p\n", fim_do_codigo(NULL));
      free(inicio_do_codigo(NULL));
      return NULL;
    }

  return inicio_do_codigo(NULL); /* ok, resolvido */
}

/* verifica se o espaco sugerido e' suficiente, caso nao, aborta. Se for,
   aloca o espaco necessario para todo o programa e retorna ponteiro */
int verifica_espaco_necessario(FILE* erros)
{
  int total = tamanho_total();
  byte_t* begin;
  byte_t* end;

  if (total > (SIZE_OF_DOT_COM - ORIGIN_OF_CODE) ) {
    /* Oops! */
    int main_size = tamanho_da_rotina(nova_rotina("main",0));
    int outras = tamanho_da_area_de_codigo() - main_size;
    int simbolos = tamanho_da_area_de_dados();

    fprintf(erros, "!! AVISO: Re-dimensione o seu codigo, ");
    fprintf(erros, "eis aqui um sumario:\n");
    fprintf(erros, "!! Rotina principal (main): %d bytes\n", main_size);
    fprintf(erros, "!! Outras rotinas: %d bytes\n", outras);
    fprintf(erros, "!! Simbolos: %d bytes\n", simbolos);
    fprintf(erros, "!! -------------------->> Total: %d bytes\n", total);
    return 0;
  }

  begin = malloc (total * sizeof(byte_t));
  inicio_do_codigo(begin);
  end = begin + total - 1;
  fim_do_codigo(end);
  
  return 1;
}

/* esta funcao aqui resolve todos os rotulos existentes no programa, retorna
   NULL caso tenha resolvido todos os enderecos ou a primeira linha de codigo
   nao resolvida */
linha_t* resolva_enderecos(void)
{
  rotina_t* it;
  for (it = nova_rotina(NULL, 0); it != NULL; it = it->proxima) {
    linha_t* linha_it;
    for (linha_it = it->primeira;
	 linha_it != NULL;
	 linha_it = linha_it->proxima)
      if (resolva_enderecos_na_linha(linha_it) == 0) return linha_it;
  }
  return NULL;
}

/* resolve todos os enderecos em uma linha de codigo, retorna 0 caso nao
   consiga resolver os enderecos desta linha */
int resolva_enderecos_na_linha (linha_t* l)
{
  operando_t* op = escolha_op(l);
  address_t temp;
  short indice;
  arg_t* ait;

  if (op == NULL) return 1; /* nada a resolver */
  
  temp = resolva_operando(op, l->lineno);

  switch (op->tipo) {
  case TIPO_SIMBOLO:
  case TIPO_ENDERECO:
  case TIPO_APONTADO_SIMB:
  case TIPO_ENDERECO_VAR:
      temp += ORIGIN_OF_CODE; /* corrige endereco */
      break;

  case TIPO_PROCEDIMENTO:
  case TIPO_ROTULO: /* tenho que ver se a instrucao nao usa deslocamento ao
		       inves de endereco do rotulo e ajustar. Testo os 2
		       operandos pois confio que resolva_operando() fez o
		       trabalho que devia. */
    if (op != NULL)
      ait = (l->op1==op)?l->instrucao->argumento[0]:l->instrucao->argumento[1];

    /* se ait1 ou ait2 forem nao nulos comparamos com ARG_DESLOC, senao
       colocamos falso... */
    if ( (ait != NULL)? ait->tipo : ARG_WORD == ARG_DESLOC8 ||
	 (ait != NULL)? ait->tipo : ARG_WORD == ARG_DESLOC16 ) {
      temp -= (long)(l->posicao + tamanho_da_instrucao(l->instrucao)
		     - inicio_do_codigo(NULL));
    }

    else temp += ORIGIN_OF_CODE;
    break;

  default: /* nao faz nada */
    break;
  }
    

  /* meu endereco pode ter 3 variantes: 1 byte|reg_ajustado, rotulo
     ou 1 palavra */

  switch(op->tipo) {
  case TIPO_BYTE:
  case TIPO_APONTADO_REG_AJUST:
    if ( (temp & 0xff) != temp) {
      /* testa para ver se temp nao e maior que 1 byte. */
      aviso(l->lineno, "(coding.c) truncando byte");
      temp = temp & 0xff;
    }

    indice = tamanho_da_instrucao(l->instrucao) - 1;
    l->posicao[indice] = temp & 0xff;
    break;

  case TIPO_ROTULO: /* tenho que testar se o argumento e'8 ou 16 bits... */
    if ( (ait == NULL)? ARG_WORD : ait->tipo == ARG_DESLOC8 ) {
      if ( ((temp & 0xff) != temp) && ((temp & 0xff00) != 0xff00) ) {
	/* testa para ver se temp nao e maior que 1 byte. */
	aviso(l->lineno, "(coding.c) truncando deslocamento de 8 bits");
	temp = temp & 0xff;
      }

      indice = tamanho_da_instrucao(l->instrucao) - 1;
      l->posicao[indice] = temp & 0xff;
    }

    else { /* nao ha verificacao para deslocamentos de 16 bits */
      indice = tamanho_da_instrucao(l->instrucao) - 2; 
      /* 2 == sizeof(address) */
      l->posicao[indice] = temp & 0xff;
      l->posicao[indice+1] = (temp & 0xff00) >> 8;
    }
    break;

  default:
    indice = tamanho_da_instrucao(l->instrucao) - 2; 
    /* 2 == sizeof(address) */
    l->posicao[indice] = temp & 0xff;
    l->posicao[indice+1] = (temp & 0xff00) >> 8;
    break;
  }

  return 1;
}

/* escolhe o operando que vai ser usado para a resolucao de enderecos. Isto na
   realidade e', de certa forma, uma forma deselegante de abordar o problema de
   que na realidade somente 1 operando pode ser um endereco, porem, o tempo
   urge... */
operando_t* escolha_op (linha_t* l)
{
  if (l->op1 != NULL) {
    switch(l->op1->tipo) {
    case TIPO_ROTULO:
    case TIPO_SIMBOLO:
    case TIPO_PROCEDIMENTO:
    case TIPO_ENDERECO:
    case TIPO_BYTE:
    case TIPO_WORD:
    case TIPO_ENDERECO_VAR:
    case TIPO_APONTADO_SIMB:
    case TIPO_APONTADO_REG_AJUST:
      return l->op1;
      break;
      
    default:
      break;
    }
  }
  
  if (l->op2 != NULL) {
    switch(l->op2->tipo) {
    case TIPO_ROTULO:
    case TIPO_SIMBOLO:
    case TIPO_PROCEDIMENTO:
    case TIPO_ENDERECO:
    case TIPO_BYTE:
    case TIPO_WORD:
    case TIPO_ENDERECO_VAR:
    case TIPO_APONTADO_SIMB:
    case TIPO_APONTADO_REG_AJUST:
      return l->op2;
      break;
      
    default:
      break;
    }
  }
  
  return NULL;
}

/* Dado um operando, retorna o endereco relativo do rotulo, simbolo ou
   procedimento */
word_t resolva_operando (operando_t* op, const int lineno)
{
  byte_t* actual;

  switch (op->tipo) {
  case TIPO_ROTULO:
    if ((actual = procure_rotulo(op->prop.nome)) == NULL) {
      char* mesg = concatena("(coding.c) simbolo inexistente -> ",
			     op->prop.nome); 
      erro(0, lineno, mesg);
      free(mesg);
      exit(0);
    }
    break;
    
  case TIPO_SIMBOLO:
  case TIPO_APONTADO_SIMB:
  case TIPO_ENDERECO_VAR:

    switch( (op->prop.simbolo)->qualidade) {
    case EQU:
    case WORD:
    case BYTE_PTR:
    case WORD_PTR:
      actual = (byte_t*)(op->prop.simbolo)->endereco_word + sizeof(word_t) *
	op->indice; 
      break;

    case BYTE:
      actual = (op->prop.simbolo)->endereco_byte + op->indice;
      break;

    default:
      break;
    }
    break;

  case TIPO_PROCEDIMENTO:
    actual = (op->prop.rotina)->posicao;
    break;

  case TIPO_ENDERECO: /* tenho que verificar se nao extrapola a rotina */
    if ( op->prop.endereco >= ORIGIN_OF_CODE && op->prop.endereco <=
	 ORIGIN_OF_CODE + tamanho_total() ) /* e' valido */
      return op->prop.endereco;

    else {
      erro(0, lineno, "(coding.c) endereco fora de escopo");
      exit(0);
    }

  case TIPO_BYTE: /* o byte ja' foi verificado pelo scanner e pelo parser. So
		     preciso tomar cuidado para nao alocar uma palavra ao inves
		     de um unico byte... */
    return op->prop.valor;

  case TIPO_APONTADO_REG_AJUST:
    return op->indice;

  case TIPO_WORD: /* a palavra ja' foi verificada pelo scanner e pelo parser */
    return op->prop.valor;

  default:
    erro(0, lineno,"(coding.c) simbolo inexistente");
  }

  /* esta soma nao pode ser maior que 16 bits, jamais */
  return (address_t)(actual - inicio_do_codigo(NULL));
}

/* finalmente, escreve o arquivo de saida usando como fonte de dados a stream
   de bytes. A origem do codigo e' ignorada neste momento. */ 
void escreva_dot_com(FILE* out, byte_t* stream)
{
  long length = fim_do_codigo(NULL) - inicio_do_codigo(NULL) + 1;
  
  /* se a saida for para stdout ou stderr tem que ser explicativa */
  if (out == stdout || out == stderr) {
    escreva_com_mnemonicos(out, stream);
    return;
  }

  /* nesta aqui tudo vale... */
  if (EOF == fwrite(stream, sizeof(byte_t), length, out)) {
    yyerror("(coding.c): Nao pude escrever no arquivo de saida");
    return;
  }
  else
    fprintf(stderr, "(coding.c): Escrita final bem sucedida\n");

  return;
}

/* escreve codigos na tela com linha e mnemonicos. Muito simples: o codigo esta
 organizado em main, outras rotinas, simbolos (do final para o meio), comecando
 no final. So tenho que escrever os mnemonicos e colocar o codigo do lado. */
void escreva_com_mnemonicos(FILE* out, byte_t* stream)
{
  rotina_t* rot_it; /* iterador para rotinas */
  simbolo_t* s_it; /* iterador para simbolos */
  byte_t* pos = stream;

  /* primeiro as rotinas */
  fprintf(out, "\n ** Analise de Codigo / Depuracao **\n");
  fprintf(out,   " -----------------------------------\n\n");
  for (rot_it = nova_rotina(NULL, 0); rot_it != NULL; rot_it = rot_it->proxima)
    pos = imprima_rotina_com_codigos(out, rot_it, pos);
 
  /* agora os simbolos */
  for (s_it = insira_simbolo(NULL); s_it != NULL; s_it = s_it->proximo)
    imprima_simbolo_com_posicao(out, s_it);

  fprintf(out, "\n");
}

int tamanho_da_instrucao(const inst_t* esta)
{
  int temp = 0;
  temp += esta->adc_byte;
  return (esta->bytes_de_codigo + temp);
}

int tamanho_da_rotina(const rotina_t* esta)
{
  linha_t* it;
  int temp = 0;
  
  for (it = esta->primeira; it != NULL; it = it->proxima)
    temp += tamanho_da_instrucao(it->instrucao);
    
  return temp;
}

int tamanho_da_area_de_codigo(void)
{
  rotina_t* it;
  int temp = 0;
  
  for (it = nova_rotina(NULL, 0); it != NULL; it = it->proxima)
    temp += tamanho_da_rotina(it);

  return temp;
}

/* calcula o tamanho de cada simbolo declarado. Esta adaptado para lidar com
   vetores tambem */
int tamanho_do_simbolo(const simbolo_t* este)
{
  switch(este->qualidade) {
  case BYTE:    
    return este->npos;
    
  case EQU:
  case WORD:
  case BYTE_PTR:
  case WORD_PTR:
    return 2 * este->npos;
    
  case DOUBLEWORD:
    return 4 * este->npos;
    
  case QUADWORD:
    return 8 * este->npos;
    
  default:
    return 0;
  }
}

int tamanho_da_area_de_dados(void)
{
  simbolo_t* it;
  int temp = 0;
  
  for(it = insira_simbolo(NULL); it != NULL; it = it->proximo)
    temp += tamanho_do_simbolo(it);

  return temp;
}

int tamanho_total(void)
{
  return tamanho_da_area_de_dados() + tamanho_da_area_de_codigo();
}
