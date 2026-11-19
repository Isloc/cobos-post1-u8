; post1d.asm - REPE CMPSB: comparar cadenas
; Compilar: nasm -f bin post1d.asm -o post1d.com
;
; Casos 1 y 2: los de la guia (cadenas de igual longitud conocida, CX=8).
; Caso 3: demuestra el riesgo de un CX fijo mayor que la cadena: dos cadenas
;         "NASM" iguales hasta el nulo, pero con bytes distintos despues de el.
;         Con CX=8 REPE CMPSB lee mas alla del nulo y las reporta distintas.
; Caso 4: la misma comparacion con un bucle manual LODSB que se detiene en el
;         primer nulo; las reporta iguales.

[BITS 16]
ORG 100h

section .text
start:
    mov  ax, ds
    mov  es, ax

    ; ---- Caso 1: cad1 vs cad2 (iguales) ----
    mov  si, cad1
    mov  di, cad2
    mov  cx, 8
    cld
    repe cmpsb
    je   .iguales1
    mov  dx, msgDif
    jmp  .imp1
.iguales1:
    mov  dx, msgIg
.imp1:
    call imprimir
    mov  dx, crlf
    call imprimir

    ; ---- Caso 2: cad1 vs cad3 (diferentes) ----
    mov  si, cad1
    mov  di, cad3
    mov  cx, 8
    cld
    repe cmpsb
    je   .iguales2
    mov  dx, msgDif
    call imprimir
    mov  dx, crlf
    call imprimir
    ; SI queda un byte despues del primer elemento distinto
    mov  dx, msgPos
    call imprimir
    mov  ax, si
    sub  ax, cad1
    dec  ax
    call imprimir_ax
    mov  dx, msgCX
    call imprimir
    mov  ax, cx
    call imprimir_ax
    mov  dx, crlf
    call imprimir
    jmp  .caso3
.iguales2:
    mov  dx, msgIg
    call imprimir
    mov  dx, crlf
    call imprimir

    ; ---- Caso 3: CX fijo mayor que la cadena corta ----
.caso3:
    mov  dx, msgC3
    call imprimir
    mov  si, corta
    mov  di, larga
    mov  cx, 8                  ; mas que los 5 bytes de "NASM",0
    cld
    repe cmpsb
    je   .iguales3
    mov  dx, msgDif
    jmp  .imp3
.iguales3:
    mov  dx, msgIg
.imp3:
    call imprimir
    mov  dx, crlf
    call imprimir

    ; ---- Caso 4: bucle manual con LODSB que termina en el nulo ----
    mov  dx, msgC4
    call imprimir
    mov  si, corta
    mov  di, larga
    cld
.bucle:
    lodsb                       ; AL = [DS:SI], SI avanza
    mov  bl, [es:di]
    inc  di
    cmp  al, bl
    jne  .distintas
    test al, al                 ; ambos son el nulo: fin de las dos cadenas
    jnz  .bucle
    mov  dx, msgIg
    jmp  .imp4
.distintas:
    mov  dx, msgDif
.imp4:
    call imprimir
    mov  dx, crlf
    call imprimir

    mov  ah, 4Ch
    xor  al, al
    int  21h

imprimir:
    mov  ah, 09h
    int  21h
    ret

imprimir_ax:
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
cad1        db "NASM x86", 0
cad2        db "NASM x86", 0
cad3        db "NASM ARM", 0
corta       db "NASM", 0, "AAA"         ; basura distinta tras el nulo
larga       db "NASM", 0, "BBB"
msgIg       db "Iguales.$"
msgDif      db "Diferentes.$"
msgPos      db "  Primera diferencia en la posicion (base-0): $"
msgCX       db "  CX restante=$"
msgC3       db "Caso 3 (REPE CMPSB, CX=8 sobre 'NASM',0): $"
msgC4       db "Caso 4 (bucle LODSB hasta el nulo):       $"
crlf        db 0Dh, 0Ah, "$"
