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

dumb dw 0h
SSseg dw 1024 dup(0h)

; Definicao da pilha
	mov     ax, SSseg
	mov     ss, ax
	mov     sp, offset dumb
	
call _clearscreen
int 21h
