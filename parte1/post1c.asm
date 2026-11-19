; post1c.asm - REPNE SCASB: buscar un caracter en una cadena
; Compilar: nasm -f bin post1c.asm -o post1c.com
;
; Busca 'd' (existe) y 'z' (no existe). Muestra la posicion base-0, el valor
; de CX restante y el flag DF.
;
; Cambios respecto a la guia:
;  - La longitud se calcula con etiquetas (cadenaFin - cadena), sin el nulo.
;  - La posicion se imprime como entero decimal. En "Arquitectura de
;    Computadores" la primera 'd' esta en el indice 13 (es la d de "de", tras
;    "Arquitectura " que tiene 13 caracteres); la guia mostraba 4 y solo
;    imprimia un digito, por lo que 13 saldria mal.

[BITS 16]
ORG 100h

section .text
start:
    mov  ax, ds
    mov  es, ax

    mov  al, 'd'
    call buscar
    mov  al, 'z'
    call buscar

    mov  ah, 4Ch
    xor  al, al
    int  21h

; buscar: AL = caracter a buscar
buscar:
    mov  [buscado], al
    cld                         ; DF=0: DI avanza
    mov  di, cadena
    mov  cx, LONGCAD
    repne scasb                 ; avanza DI mientras AL != [ES:DI] y CX > 0
    jne  .no_hallado            ; ZF=0 al terminar: se agoto CX sin coincidencia

    mov  bx, di
    sub  bx, cadena
    dec  bx                     ; DI quedo un byte despues del hallado
    mov  [resto], cx

    mov  dx, msgBus1
    call imprimir
    mov  dl, [buscado]
    mov  ah, 02h
    int  21h
    mov  dx, msgHall
    call imprimir
    mov  ax, bx
    call imprimir_ax
    mov  dx, msgCX
    call imprimir
    mov  ax, [resto]
    call imprimir_ax
    mov  dx, crlf
    call imprimir
    ret

.no_hallado:
    mov  dx, msgBus1
    call imprimir
    mov  dl, [buscado]
    mov  ah, 02h
    int  21h
    mov  dx, msgNoH
    call imprimir
    mov  dx, crlf
    call imprimir
    ret

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
cadena      db "Arquitectura de Computadores"
cadenaFin   db 0
LONGCAD     EQU cadenaFin - cadena      ; 28 caracteres, sin el nulo
buscado     db 0
resto       dw 0
msgBus1     db "Buscando '$"
msgHall     db "': hallado en posicion: $"
msgNoH      db "': No encontrado.$"
msgCX       db "  CX restante=$"
crlf        db 0Dh, 0Ah, "$"
