;;; Trabalho 2 de software 1
;;; $Id: window.asm,v 1.2 1999/02/01 22:57:50 andre Exp $

;;; As variaveis do programa
first   db      ' ',0 |
	db      ' ',0 |
	db      ' ',0 |
	db      '          Universidade Federal do Rio de Janeiro',0 |
	db      ' ',0 |
	db      '                   Software I - DEL 485',0 |
	db      '                    Segundo  Trabalho',0 |
	db      ' ',0 |
	db      '                 Programacao em Assembler',0 |
	db      ' ',0 |
	db      '                   Montador: Trabalho1',0 |
	db      0,0
authors db      ' Programadores: ',0 |
	db      ' ',0 |
	db      '           Andre Rabello dos Anjos',0 |
	db      '           mail : Andre.dos.Anjos@cern.ch',0 |
	db      ' ',0 |
	db      '           Marcos Peixoto Carrao',0 |
	db      '           mail : mpc@minerva.del.ufrj.br',0 |
	db      ' ',0 |
	db      '           Marcus Andre da Cruz Loureiro',0 |
	db      '           mail : marcus@skydome.net',0 |
	db      ' ',0 |
	db      '           Moises Araujo Silva',0 |
	db      '           mail : moises_rj@yahoo.com',0 |
	db      ' ',0 |
	db      '                 Tecle Algo Para Comecar!',0 |
	db      0,0
menu_options    db      ' File  ' |
		db      ' Edit  ' |
		db      ' Options  ' |
		db      ' Help ',0 |
		db      0,0
menu_file       db      '  New',0 |
		db      '  Open',0 |
		db      '  Close',0 |
		db      '  Quit',0 |
		db      0,0
menu_edit       db      '  Undo',0 |
		db      '  Copy',0 |
		db      '  Paste',0 |
		db      '  Date',0 |
		db      0,0
menu_opt        db      '  Color',0 |
		db      '  Default',0 |
		db      '  Printer',0 |
		db      '  Invert',0 |
		db      0,0
menu_help       db      '  Contents',0 |
		db      '  Index',0 |
		db      '  Commands',0 |
		db      '  About',0 |
		db      0,0

buffer  dw 1000 dup(0FFFFh)

;;; O stack, ultimo a ser declarado, ficando no meio
stack_top	dw	0h	; o topo da pilha fica depois de stack_base
stack_base	dw	1024 dup(0h); o vetor de dados

;;; Ja podemos setar o stack..., mas antes facamos um JMP para a posicao
;;; inicial, como diz Moises...
;;; JMP _begin_main

_begin_main:	mov sp, offset stack_top
		
;;; Declaracoes iniciais dos procedimentos

declare _background
declare _clearscreen
declare _clearwindow
declare _displaybox
declare _displaytext
declare _exit
declare _gotoxy
declare _hilightline
declare _restorew
declare _scankey
declare _storew
declare _waitkey

declare _apres
declare _inic
declare _tempo

declare  _file_menu
declare  _edit_menu
declare  _opt_menu
declare  _help_menu
declare  _arrows
	
;;; +==========+
;;;  suport.asm
;;; +==========+	

;+------------------------------------------------+
_background	proc	near
; Parametros    : x1 -> [bp + 04h]
;                 y1 -> [bp + 06h]
;                 x2 -> [bp + 08h]
;                 y2 -> [bp + 0A]
; Retorno       : Nenhum
; Proposito     : Fill a Window (x1,y1)-(x2,y2)
;                with  a pattern character.
;+------------------------------------------------+

push bp
mov bp,sp
push ax
push bx
push cx
push dx
mov dh,[bp + 04h]
mov dl,[bp + 06h]
mov ch, 00h
mov cl,[bp + 0ah]
sub cl,dl ; numero de colunas      
inc cx
mov bx,0017h
mov al,1ch; define um simbolo para o fundo

linefill:	mov ah,02h      ;posiciona cursor
		int 10h
		mov ah,09h      ;escreve simbolo
		int 10h
		cmp dh,[bp + 08h]
		inc dh
		jnz linefill

pop dx
pop cx
pop bx
pop ax
pop bp
ret
_background endp

;+----------------------------------+
_clearscreen   proc     near 
; Parametros    : Nenhum 
; Retorno       : Nenhum 
; Proposito     : Limpar Tela 
;+----------------------------------+ 

push ax
push bx
push cx
push dx
mov ax,0600h; Funcao Scroll Window Up - 06h 
mov bh,07h; Modo VGA
mov cx,0000h ; Ponto inicial (0,0)
mov dx,184fh ; Scroll 25 linhas(00h ate 18h) e 80 Colunas(00h ate 4fh)
int 10h
pop dx
pop cx
pop bx
pop ax
ret
_clearscreen endp

;+-----------------------------------------------------+
_clearwindow  proc     near 
; Parametros    : x1 -> [bp + 04h] 
;                 y1 -> [bp + 06h] 
;                 x2 -> [bp + 08h] 
;                 y2 -> [bp + 0Ah] 
; Retorno       : Nenhum 
; Proposito     : Clear Window (x1,y1)-(x2,y2) 
;+-----------------------------------------------------+ 
push bp
mov bp,sp
push ax
push bx
push cx
push dx

mov ch,[bp + 04h] ; linha inicial
mov cl,[bp + 06h] ; coluna inicial
mov dh,[bp + 08h] ; linha final
mov dl,[bp + 0ah] ; coluna final
xor al,al       ; Scroll all lines
mov ah,06h
mov bh,07h
int 10h         ; Funcao Scroll Window Up - 06h

pop dx
pop cx
pop bx
pop ax
pop bp

ret
_clearwindow endp

;+-----------------------------------------------------+
_displaybox    proc     near 
; Parametros    : x1 -> [bp + 04h] 
;                 y1 -> [bp + 06h] 
;                 x2 -> [bp + 08h] 
;                 y2 -> [bp + 0Ah] 
; Retorno       : Nenhum 
; Proposito     : Plot Box   (x1,y1)-(x2,y2) 
;+-----------------------------------------------------+ 
push bp
mov bp,sp
push ax
push bx
push cx
push dx

mov dh,[bp + 04h]; linha inicial
mov dl,[bp + 06h]; coluna inicial
mov cl,[bp + 0ah]; coluna final
mov ch,00h;
sub cl,dl       ; cl = numero de colunas
inc cl
mov bx,0007h
mov ax,02dbh
int 10h
mov ah,09h
int 10h
push cx
bar1:   inc dh
	mov cl,01h
	mov ah,02h
	int 10h
	mov ah,09h
	int 10h
	cmp dh,[bp + 08]
	jnz bar1
pop cx
dec cl
mov dh,[bp + 08h]
mov dl,[bp + 06h]
inc dl
mov ah,02h
int 10h
mov ah,09h
int 10h
mov dh,[bp + 04h]
mov dl,[bp + 0ah]
mov ah,02h
int 10h
mov cl,01h
mov ah,09h
bar2:   inc dh
	mov ah,02h
	int 10h
	mov ah,09h
	int 10h
	push cx
	mov cl,[bp + 08h]
	dec cl
	cmp dh,cl
	pop cx
	jnz bar2
pop dx
pop cx
pop bx
pop ax
pop bp
ret
_displaybox endp


;+----------------------------------------------------------+ 
_displaytext    proc   near
; Parametros    : Ptr -> [bp + 04h] 
;               Pointer to data text with EOL := 0 
;               and ETX :=  0,0 control. 
; 
; Retorno       : Nenhum 
; Proposito     : Display an ASCII text with left 
;               margin alignment. 
;+----------------------------------------------------------+ 
push bp
mov bp,sp
push ax
push bx
push cx
push dx
push si
mov si,[bp + 04h]
; pega a posicao do cursor
xor bx,bx
mov ah,03h
int 10h
; dh = linha de onde esta o cursor
; dl = coluna de onde esta o cursor
push dx

mov bx,0007h
	
tx_pulo:mov ah,02h
	int 10h

	mov al,[si]
	inc si

	mov cx,1h
	mov ah,09h
	int 10h

	inc dl
	mov cl,[si]
	cmp cl,0h
	jnz tx_pulo

pop dx
inc si
inc dh
push dx
mov cl,[si]
cmp cl,0h
jnz tx_pulo

pop dx

pop si
pop dx
pop cx
pop bx
pop ax
pop bp

ret
_displaytext endp

;+----------------------------------+
_exit   proc    near
; Parametros    : Nenhum 
; Retorno       : Nenhum 
; Proposito     : Sair do programa 
; Para terminar Programas utiliza-se
; a INT 21,4c
;+----------------------------------+ 
call _clearscreen
mov ax,4c00h
int 21h
ret
_exit endp

;+-----------------------------------------------------+
_gotoxy   proc          near 
; Parametros    : x1 -> [bp + 04h] 
;                 y1 -> [bp + 06h] 
; Retorno       : Nenhum 
; Proposito     : Go to Screen Position (x1,y1) 
;                                    (row,column)
;+-----------------------------------------------------+ 
push bp
mov bp,sp
push ax
push bx
push cx
push dx
mov dh,[bp + 04h]
mov dl,[bp + 06h]
mov ah,02h
mov bh,00h
int 10h
pop dx
pop cx
pop bx
pop ax
pop bp
ret
_gotoxy endp

;+-------------------------------------------------------+ 
_hilightline    proc   near 
; Parametros    : x1 -> bp+04h 
;                y1 -> bp+06h 
;                y2 -> bp+08h 
;                SW -> bp+0Ah 
;Toggle between normal and reverse mode : 
;       SW = 0  normal 
;       SW = 1  reverse 
; Retorno     : Nenhum 
; Proposito   : Hilight option for line segments. 
;+---------------------------------------------------------+ 
push bp
mov bp,sp
push ax
push bx
push cx
push dx

; toggle ( normal / reverse ) mode
mov dx,[bp + 0ah]
cmp dx,1h
jz  reverso
mov bx,0007h
jmp cont
	
reverso: mov bx,0070h

cont:	 mov dh,[bp + 04h]
	 mov dl,[bp + 06h]
	 mov cx,1h

pulo:	mov ah,02h      ; posiciona cursor
	int 10h

	mov ah,08h
	int 10h

	mov ah,09h
	int 10h

	inc dl
	cmp dl,[bp + 08h]
	jna pulo

pop dx
pop cx
pop bx
pop ax
pop bp

ret
_hilightline endp

;+---------------------------------------------------------+ 
_restorew proc         near 
; Parametros    : x1 -> bp+04h 
;                y1 -> bp+06h 
;                x2 -> bp+08h 
;                y2 -> bp+0Ah 
; Retorno       : Nenhum 
; Proposito     : Restore  Window (x1,y1)-(x2,y2) 
;                from a memomy array. 
;+--------------------------------------------------------+ 
push bp
mov bp,sp
push ax
push bx
push cx
push dx

mov bx,offset buffer
push bx
mov cx,1h
mov dh,[bp + 04h]

linha:	mov dl,[bp + 06h]

coluna:	xor bx,bx
	mov ah,02h
	int 10h
	
	pop bx
	mov ax,[bx]
	inc bx
	inc bx
	push bx

	xor bx,bx
	mov bl,ah
	mov ah,09h
	int 10h

	inc dl
	cmp dl,[bp + 0ah]
	jna coluna

	inc dh
	cmp dh,[bp + 08h]
	jna linha

pop bx
	
pop dx
pop cx
pop bx
pop ax
pop bp

ret
_restorew endp


;+----------------------------------------------------------+ 
_scankey   proc         near 
; Parametros : Nenhum 
; Retorno       : AX -> Scan Code corresponding to the last keystroke. 
; Proposito     : Keyboard character capture. 
;+---------------------------------------------------------+
push bx
mov bx,ax
mov ah,1h
int 16h
jz naotemcarac
xor ax,ax
int 16h
pop bx
ret

naotemcarac:	mov ax,bx
		pop bx
		ret

_scankey endp

;+-----------------------------------------------------+ 
_storew proc    near 
; Parametros    : x1 -> bp+04h 
;                y1 -> bp+06h 
;                x2 -> bp+08h 
;                y2 -> bp+0Ah 
; Retorno     : Nenhum 
; Proposito   : Store   Window (x1,y1)-(x2,y2) 
;              into a memomy array. 
;+-----------------------------------------------------+ 
push bp
mov bp,sp
push ax
push bx
push cx
push dx

;posiciona cursor
mov cx, offset buffer
mov dh,[bp + 04h]

st_linha:	mov dl,[bp + 06h]

st_coluna:	xor bx,bx
		mov ah,02h
		int 10h

		mov ah,08h
		int 10h
		mov bx,cx
		mov [bx],ax
		inc cx
		inc cx

		inc dl
		cmp dl,[bp + 0ah]
		jna st_coluna

		inc dh
		cmp dh,[bp + 08h]
		jna st_linha

pop dx
pop cx
pop bx
pop ax
pop bp

ret
_storew endp

;+----------------------------------------------------------+ 
_waitkey   proc         near 
; Parametros : Nenhum 
; Retorno       : ax -> tecla pressionada 
; Proposito     : Espera teclar algo. 
;+---------------------------------------------------------+
push    bx
xor     ax,ax
xor     bx,bx
	
NoPressed:      call    _scankey
		cmp     ax,bx   
		jz      NoPressed
	
pop     bx
ret

_waitkey         endp

;;; +==========+
;;;  procs.asm
;;; +==========+	

;+---------------------------------------------------+
_tempo  proc
; Parametros: 	Nenhum
; Retorno:	Nenhum
; Proposito:	Rotina de delay
;+----------------------------------------------------+	
push ax
push bx
push cx
push dx
mov ah,2ch
int 21h
mov bh,dh
add bh, +08h
mov cx,0000h
push cx
mede:   int 21h
	cmp dh,bh
        jnz max_loop
        jz saida
	
max_loop:	pop cx
		inc cx
		cmp cx,65535
		push cx
		jnz mede

saida:  pop cx
	pop ax
	pop bx
	pop cx
	pop dx
	ret

_tempo endp

;+----------------------------------------------------+
_inic proc
; Parametros: 	Nenhum
; Retorno:	Nenhum
; Proposito:	Apresentar telas iniciais do Programa
;+----------------------------------------------------+	
push ax
mov     ax,004fh
push    ax
mov     ax,0018h
push    ax
mov     ax,0000h
push    ax
push    ax
call    _background
add     sp,+08h
call    _apres
pop ax
ret

_inic endp

;+------------------------------------------------------+
_apres    proc  near
; Parametros: 	Nenhum
; Retorno:	Nenhum
; Proposito:	Preparar tela para apresentacao de texto
;+------------------------------------------------------+	
;       Clear window
;       Display displaybox

push ax
mov     ax,0047h
push    ax
mov     ax,0015h
push    ax
mov     ax,0008h
push    ax
mov     ax,0003h
push    ax
call    _clearwindow
call    _displaybox
add     sp,+08h

;       Display Text at (x,y)

mov     ax,000bh   
push    ax
mov     ax,0005h
push    ax
call    _gotoxy
add     sp,+04
pop ax
ret
_apres  endp

;;; +==========+
;;;  main.asm
;;; +==========+	

;+----------------------------------------------------+
_file_menu proc
; Parametros: 	Nenhum
; Retorno:	dx = tecla selecionada dentro do menu
; Proposito:	Abrir opcao "File"
;+----------------------------------------------------+	
push ax
push bx
mov ax,0007h
push ax
mov ax,0004h
push ax
mov ax,0000h
push ax
mov ax,0001h
push ax
call _storew
call _clearwindow
mov ax,0000h; coluna
push ax
mov ax,0001h; linha
push ax
call _gotoxy
mov bx,offset menu_file
push bx
call _displaytext
push ax
mov ax,0007h
push ax
mov ax,0000h
push ax
mov ax,0001h
push ax
call _hilightline
call _arrows
add sp,+22
pop bx
pop ax
ret
_file_menu endp

;+----------------------------------------------------+
_edit_menu proc
; Parametros: 	Nenhum
; Retorno:	dx = tecla selecionada dentro do menu
; Proposito:	Abrir opcao "Edit"
;+----------------------------------------------------+	
push ax
push bx
mov ax,000eh
push ax
mov ax,0004h
push ax
mov ax,0007h
push ax
mov ax,0001h
push ax
call _storew
call _clearwindow
mov ax,0007h; coluna
push ax
mov ax,0001h; linha
push ax
call _gotoxy
mov bx,offset menu_edit
push bx
call _displaytext
push ax
mov ax,000eh
push ax
mov ax,0007h
push ax
mov ax,0001h
push ax
call _hilightline
call _arrows
add sp,+22
pop bx
pop ax
ret
_edit_menu endp

;+----------------------------------------------------+
_opt_menu proc
; Parametros: 	Nenhum
; Retorno:	dx = tecla selecionada dentro do menu
; Proposito:	Abrir opcao "Options"
;+----------------------------------------------------+	
push ax
push bx
mov ax,0017h
push ax
mov ax,0004h
push ax
mov ax,000eh
push ax
mov ax,0001h
push ax

call _storew
call _clearwindow
mov ax,000eh; coluna
push ax
mov ax,0001h; linha
push ax
call _gotoxy
mov bx,offset menu_opt
push bx
call _displaytext
push ax
mov ax,0017h
push ax
mov ax,000eh
push ax
mov ax,0001h
push ax
call _hilightline
call _arrows
add sp,+22
pop bx
pop ax
ret
_opt_menu endp

;+--------------------------------------------------------+
_help_menu proc
; Parametros: 	Nenhum
; Retorno:	dx = tecla selecionada dentro do menu
; Proposito:	Abrir opcao "Help" e chamar o procedimento
; de controle de menu( _arrows )
;+--------------------------------------------------------+	
push ax
push bx
mov ax,0022h
push ax
mov ax,0004h
push ax
mov ax,0018h
push ax
mov ax,0001h
push ax
call _storew
call _clearwindow
mov ax,0018h; coluna
push ax
mov ax,0001h; linha
push ax
call _gotoxy
mov bx,offset menu_help
push bx
call _displaytext
push ax
mov ax,0022h
push ax
mov ax,0018h
push ax
mov ax,0001h
push ax
call _hilightline
call _arrows
add sp,+22
pop bx
pop ax
ret
_help_menu endp

;+---------------------------------------------------------+
_arrows proc
; Parametros: 	_Parametros do procedimento _hilightline
;			x1 -> bp+04h 
;                	y1 -> bp+06h 
;                	y2 -> bp+08h 
;                	SW -> bp+0Ah
;		_Parametros do _restorew
;			x1 -> bp+12h 
;               	y1 -> bp+14h 
;               	x2 -> bp+16h 
;               	y2 -> bp+18h  
; Retorno:	dx = tecla selecionada dentro do menu
; Proposito:	Controlar a movimentacao dentro dos menus
;+---------------------------------------------------------+	
push bp
mov bp,sp
key:    call _waitkey
	cmp ax,1c0dh
	jz bye
	cmp ax,5000h
	jz down_arrow
	cmp ax,4800h
	jz up_arrow
	cmp ax,4d00h
	jz right_arrow
	cmp ax,4b00h
	jz left_arrow
	cmp ax,011bh
	jz saindo
	jnz key
saindo: mov dx,ax
	jmp restore
bye:    mov bx,[bp + 04h]
	cmp bx,0004h
	jnz key
	mov bx,[bp + 06h]
	cmp bx,0000h
	jz saindo
	cmp bx,0018h
	jz about_test
	jmp key
up_arrow:       mov ax,[bp + 04h]
		cmp ax,0001h
		jz giro2
		mov cx,ax
		dec cx
back_up:        mov [bp + 04h],cx
		mov bx,0000h
		push bx
		mov bx,[bp + 08h]
		push bx
		mov bx,[bp + 06h]
		push bx
		push ax
		call _hilightline
		add sp,+08
		mov bx,0001h
		push bx
		sub sp,+04
		push cx
		call _hilightline
		add sp,+08
		jmp key
giro:           mov cx,0001h
		jmp back_down
giro2:          mov cx,0004h
		jmp back_up
right_arrow:    mov dx,ax
		jmp restore
left_arrow:     mov dx,ax
		jmp restore
down_arrow:     mov ax,[bp + 04h]
		cmp ax,0004h
		jz giro
		mov cx,ax
		inc cx
back_down:      mov [bp + 04h],cx
		mov bx,0000h
		push bx
		mov bx,[bp + 08h]
		push bx
		mov bx,[bp + 06h]
		push bx
		push ax
		call _hilightline
		add sp,+08
		mov bx,0001h
		push bx
		sub sp,+04
		push cx
		call _hilightline
		add sp,+08 
		jmp key
about_test:	push ax
		mov     ax,000bh   
		push    ax
		mov     ax,0005h
		push    ax
		call    _gotoxy
		add     sp,+04
		mov ax,offset authors
		push ax
		call _displaytext
		add	sp,+02
		call _waitkey
		mov     ax,0045h
		push    ax
		mov     ax,0013h
		push    ax
		mov     ax,000ah
		push    ax
		mov     ax,0005h
		push    ax
		call    _clearwindow
		add sp,+08
		pop ax
		jmp key

restore:        mov ax,[bp + 18h]
		push ax
		mov ax,[bp + 16h]
		push ax
		mov ax,[bp + 14h]
		push ax
		mov ax,[bp + 12h]
		push ax
		call _restorew
		add sp,+8
		pop bp
		ret
_arrows endp

	
;;; Ok, agora vamos retomar a rotina principal...

	call    _clearscreen	; limpa a tela
	call    _inic		; inicializa
	mov     bx,offset first
	push    bx
	call    _displaytext	;  escreve o nome do trabalho
	add     sp,+02h
	call    _tempo
	call    _inic
	mov     bx,offset authors
	push    bx
	call    _displaytext	;  escreve quem fez
	add     sp,+02h
	call    _waitkey	;  espera teclar algo
	mov     ax,0045h
	push    ax
	mov     ax,0013h
	push    ax
	mov     ax,000ah
	push    ax
	mov     ax,0005h
	push    ax
	call    _clearwindow	;  limpa a janela para comecar
	mov     bx,offset menu_options
	push    bx
	mov     ax,0000h   
	push    ax
	push    ax
	call    _gotoxy		; vai para a posicao (0,0) - canto esquerdo
	add     sp,+04
	call    _displaytext	;  ok, poe as opcoes
	add     sp,+02h

; Varredura do teclado

tecle:  mov ax,0000h
	call    _waitkey

; test_0 = 'alt+q'
; Se o usuario teclar 'alt+q', termina o programa

test_0: cmp ax,1000h
	jz fim

;test_1 = 'alt+f'

test_1: cmp ax,2100h
	jnz test_2
	call _file_menu

;Verificacao se dentro do menu "file" o usuario acionou as setas para
;direita(4d00h), esquerda(4b00h), ou enter(1c0dh) na opcao Quit

	cmp dx,4d00h
	jz dir_1
	cmp dx,4b00h
	jz esq_1
	cmp dx,1c0dh
	jz fim
	jmp tecle

fim:    call _exit

; Se a seta para a esquerda for teclada dentro do menu "file"
; este sera fechado e o menu "help" sera aberto
esq_1:  mov ax,2300h
	jmp test_4

; Se a seta para a direita for teclada dentro do menu "file"
; este sera fechado e o menu "edit" sera aberto

dir_1:  mov ax,1200h    

test_2: cmp ax,1200h
	jnz test_3
	call _edit_menu
	cmp dx,4d00h
	jz dir_2
	cmp dx,4b00h
	jz esq_2
	jmp tecle
esq_2:  mov ax,2100h
	jmp test_1
dir_2:  mov ax,1800h    

test_3: cmp ax,1800h
	jnz test_4
	call _opt_menu
	cmp dx,4d00h
	jz dir_3
	cmp dx,4b00h
	jz esq_3
	jmp tecle
esq_3:  mov ax,1200h
	jmp test_2
dir_3:  mov ax,2300h    

test_4: cmp ax,2300h
	jnz tecle
	call _help_menu
	cmp dx,4d00h
	jz dir_4
	cmp dx,4b00h
	jz esq_4
	jmp tecle
esq_4:  mov ax,1800h
	jmp test_3
dir_4:  mov ax,2100h
	jmp test_1
       
;;; main endp	; nao precisa, pois esta implicito...









