# Construtor de codigo
#
# $Id: Makefile,v 1.8 1999/01/25 22:57:09 andre Exp $

# Arquivos
CPP_DIR = include
LIB_DIR = lib
OBJ_DIR = obj
SRC_DIR = src

PROG_NAME = x

SRC_FILES = ourline.c oursym.c yyerror.c yywrap.c init.c coding.c ourstr.c \
	    cerror.c cwrap.c
SRC = $(SRC_FILES:%=$(SRC_DIR)/%)
OBJ = $(SRC:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o)
MAIN_SRC = $(SRC_DIR)/main.c
MAIN_OBJ = $(MAIN_SRC:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o)

YACC_DIR = $(SRC_DIR)
YACC_GRAM = $(YACC_DIR:%=%/yyparser.y) $(YACC_DIR:%=%/cparser.y)
YACC_SRC = $(YACC_GRAM:%.y=%.c)
YACC_OBJ = $(YACC_GRAM:$(SRC_DIR)/%.y=$(OBJ_DIR)/%.o)

LEX_DIR = $(SRC_DIR)
LEX_GRAM = $(SRC_DIR:%=%/yyscan.l) $(SRC_DIR:%=%/cscan.l)
LEX_SRC = $(LEX_GRAM:%.l=%.c)
LEX_OBJ = $(LEX_GRAM:$(SRC_DIR)/%.l=$(OBJ_DIR)/%.o)

# Macros
AR = ar
ARFLAGS = -vru

CC = gcc
CFLAGS = -g -ansi -Wall -pedantic -Wcast-qual
CPPFLAGS = -I./$(CPP_DIR)
LDFLAGS = -L./lib
ARCHIVES = -ldep -lm

YACC = bison
YFLAGS = -d -t

LEX = flex
LEXFLAGS = -i -8

RM = rm -f
AR = ar
ARFLAGS = -csvru

# Algumas regras gerais

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

# As regras de construcao

all: montador

montador: $(LEX_OBJ) $(YACC_OBJ) $(MAIN_OBJ) dep
	$(CC) $(CFLAGS) $(LDFLAGS) $(LEX_OBJ) $(YACC_OBJ) $(MAIN_OBJ) \
	$(ARCHIVES) -o $(PROG_NAME)

$(YACC_SRC):
	$(YACC) $(YFLAGS) -p $(@:src/%parser.c=%) $(@:%.c=%.y) -o $@
	mv $(@:%.c=%.h) $(CPP_DIR)

$(LEX_SRC): $(YACC_SRC)
	$(LEX) $(LEXFLAGS) -P$(@:src/%scan.c=%) -o$@ $(@:%.c=%.l)

dep: $(LIB_DIR)/libdep.a

$(LIB_DIR)/libdep.a: $(YACC_SRC) $(OBJ)
	$(AR) $(ARFLAGS) $@ $(OBJ)

clean: cleanscan
	$(RM) $(YACC_OBJ) $(YACC_SRC) \
	$(YACC_SRC:$(SRC_DIR)/%.c=$(CPP_DIR)/%.h)

cleandep:
	$(RM) $(OBJ) $(LIB_DIR)/*.a

cleanscan:
	$(RM) $(LEX_OBJ) $(LEX_SRC) $(PROG_NAME) */*~ *~ core

cleanpars:
	$(RM) $(YACC_OBJ) $(YACC_SRC) \
	$(YACC_SRC:$(SRC_DIR)/%.c=$(CPP_DIR)/%.h) \
	$(PROG_NAME) */*~ *~ core

restart: clean
	$(RM) $(LIB_DIR)/*.a $(OBJ) $(MAIN_OBJ)

