; post1.asm - REP MOVSB y REP MOVSW: copia de cadenas
; Compilar: nasm -f bin post1.asm -o post1.com
;
; Paso 1: copia de 13 bytes con REP MOVSB.
; Paso 2: la misma copia con REP MOVSW (palabras) mas un MOVSB para el byte impar.
; Despues de cada REP se muestran SI, DI, CX y el flag DF para verificar su efecto.
;
; Cambios respecto a la guia: NASM no tiene "dup" (se usa TIMES) y la cadena
; termina en '$' (la funcion 09h de INT 21h imprime hasta el '$', no hasta el 0).

[BITS 16]
ORG 100h

LARGO        EQU 13              ; longitud de la cadena, incluido el '$'

section .text
start:
    ; Preparar ES = DS (en un .com todos los segmentos coinciden)
    mov  ax, ds
    mov  es, ax

    ; ---- Paso 1: REP MOVSB ----
    mov  si, origen
    mov  di, destino
    mov  cx, LARGO
    cld                         ; DF=0: SI y DI avanzan de direccion baja a alta
    rep  movsb
    mov  [regSI], si
    mov  [regDI], di
    mov  [regCX], cx
    pushf
    pop  ax
    mov  [regFL], ax

    mov  dx, msgCop
    call imprimir
    mov  dx, destino
    call imprimir
    mov  dx, crlf
    call imprimir
    call mostrar_registros

    ; ---- Paso 2: REP MOVSW + MOVSB para el byte sobrante ----
    mov  si, origen
    mov  di, destino2
    mov  cx, LARGO
    cld
    mov  ax, cx                 ; guardar la longitud total
    shr  cx, 1                  ; CX = LARGO / 2 palabras (6)
    rep  movsw                  ; copia 12 bytes
    and  ax, 1                  ; hay byte impar?
    jz   .copiado
    movsb                       ; copia el byte sobrante (posicion 12)
.copiado:
    mov  [regSI], si
    mov  [regDI], di
    mov  [regCX], cx
    pushf
    pop  ax
    mov  [regFL], ax

    mov  dx, msgCopW
    call imprimir
    mov  dx, destino2
    call imprimir
    mov  dx, crlf
    call imprimir
    call mostrar_registros

    ; ---- Verificacion: destino2 contra origen con REPE CMPSB ----
    mov  si, origen
    mov  di, destino2
    mov  cx, LARGO
    cld
    repe cmpsb
    jne  .distintos
    mov  dx, msgIgual
    jmp  .fin
.distintos:
    mov  dx, msgDist
.fin:
    call imprimir
    mov  ah, 4Ch
    xor  al, al
    int  21h

; ---------------------------------------------------------------
; mostrar_registros: SI y DI relativos al inicio de cada buffer, CX y DF
mostrar_registros:
    mov  dx, msgSI
    call imprimir
    mov  ax, [regSI]
    sub  ax, origen
    call imprimir_ax
    mov  dx, msgDI
    call imprimir
    mov  ax, [regDI]
    sub  ax, destino            ; destino2 queda LARGO bytes despues de destino
    cmp  ax, LARGO
    jbe  .di_ok
    sub  ax, LARGO
.di_ok:
    call imprimir_ax
    mov  dx, msgCX
    call imprimir
    mov  ax, [regCX]
    call imprimir_ax
    mov  dx, msgDF
    call imprimir
    mov  ax, [regFL]
    and  ax, 0400h              ; bit 10 = DF
    mov  cl, 10
    shr  ax, cl
    call imprimir_ax
    mov  dx, crlf
    call imprimir
    ret

imprimir:                       ; DX = cadena terminada en '$'
    mov  ah, 09h
    int  21h
    ret

imprimir_ax:                    ; AX como entero decimal sin signo
    push ax
    push bx
    push cx
    push dx
    mov  bx, 10
    xor  cx, cx
.divide:
    xor  dx, dx
    div  bx
    push dx
    inc  cx
    test ax, ax
    jnz  .divide
.digitos:
    pop  dx
    add  dl, '0'
    mov  ah, 02h
    int  21h
    loop .digitos
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret

section .data
origen      db "HOLA, MUNDO!$"          ; 13 bytes (el ultimo es '$')
destino     times LARGO db 0
destino2    times LARGO db 0
msgCop      db "Copiado: $"
msgCopW     db "Copiado con MOVSW: $"
msgSI       db "  SI-origen=$"
msgDI       db " DI-destino=$"
msgCX       db " CX=$"
msgDF       db " DF=$"
msgIgual    db "REPE CMPSB: destino2 igual a origen.", 0Dh, 0Ah, "$"
msgDist     db "REPE CMPSB: destino2 distinto de origen.", 0Dh, 0Ah, "$"
crlf        db 0Dh, 0Ah, "$"
regSI       dw 0
regDI       dw 0
regCX       dw 0
regFL       dw 0
