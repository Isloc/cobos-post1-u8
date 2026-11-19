; post2b.asm - DAA y DAS: suma y resta BCD empaquetada
; Compilar: nasm -f bin post2b.asm -o post2b.com
;
; BCD empaquetado: dos digitos decimales por byte, uno por nibble.
; DAA corrige AL despues de ADD; DAS corrige AL despues de SUB. Ambas miran el
; nibble bajo (o AF) y el nibble alto (o CF) y suman/restan 6 donde haga falta.

[BITS 16]
ORG 100h

BCD_A       EQU 47h             ; "47"
BCD_B       EQU 38h             ; "38"
BCD_X       EQU 73h             ; "73"
BCD_Y       EQU 28h             ; "28"
BCD_P       EQU 99h             ; "99"
BCD_U       EQU 01h             ; "01"

section .text
start:
    ; ---- Checkpoint 3: 47 + 38 = 85 con DAA ----
    mov  al, BCD_A
    add  al, BCD_B              ; AL = 7Fh (no es BCD valido)
    mov  [sinAjuste], al
    daa                         ; AL = 85h
    mov  [resultado], al

    mov  dx, msgSuma
    call imprimir
    mov  al, [resultado]
    call imprimir_hex8          ; los nibbles de un BCD se leen directamente en hex
    mov  dx, crlf
    call imprimir
    mov  dx, msgSin
    call imprimir
    mov  al, [sinAjuste]
    call imprimir_hex8
    mov  dx, crlf
    call imprimir

    ; ---- 99 + 01 = 00 con CF=1 (acarreo al siguiente byte BCD) ----
    mov  al, BCD_P
    add  al, BCD_U              ; AL = 9Ah
    daa                         ; AL = 00h, CF = 1
    pushf
    pop  bx
    mov  [resultado], al
    mov  dx, msg99
    call imprimir
    mov  al, [resultado]
    call imprimir_hex8
    mov  dx, msgCF
    call imprimir
    mov  ax, bx
    and  ax, 1
    call imprimir_ax
    mov  dx, crlf
    call imprimir

    ; ---- Checkpoint 4: 73 - 28 = 45 con DAS ----
    mov  al, BCD_X
    sub  al, BCD_Y              ; AL = 4Bh (no es BCD valido)
    mov  [sinAjuste], al
    das                         ; AL = 45h
    cmp  al, 45h
    jne  .errDas
    mov  dx, msgDas
    call imprimir
    mov  al, 45h
    call imprimir_hex8
    mov  dx, msgSin2
    call imprimir
    mov  al, [sinAjuste]
    call imprimir_hex8
    mov  dx, crlf
    call imprimir
    jmp  .caso2
.errDas:
    mov  dx, msgErrDas
    call imprimir

    ; ---- 20 - 01 = 19 con DAS (el nibble bajo 0 - 1 produce Fh) ----
.caso2:
    mov  al, 20h
    sub  al, 01h                ; AL = 1Fh (nibble bajo Fh > 9)
    mov  [sinAjuste], al
    das                         ; AL = 19h, CF = 0
    pushf
    pop  bx
    mov  [resultado], al
    mov  dx, msg20
    call imprimir
    mov  al, [sinAjuste]
    call imprimir_hex8
    mov  dx, msgCon
    call imprimir
    mov  al, [resultado]
    call imprimir_hex8
    mov  dx, msgCF
    call imprimir
    mov  ax, bx
    and  ax, 1
    call imprimir_ax
    mov  dx, crlf
    call imprimir

    mov  ah, 4Ch
    xor  al, al
    int  21h

; ---------------------------------------------------------------
imprimir:                       ; DX = cadena terminada en $
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
    add  dl, 30h
    mov  ah, 02h
    int  21h
    loop .digitos
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret

imprimir_hex8:                  ; AL en hexadecimal (2 digitos); conserva registros
    push ax
    push cx
    push dx
    mov  dh, al
    mov  cl, 4
    shr  al, cl
    call nibble
    mov  al, dh
    and  al, 0Fh
    call nibble
    pop  dx
    pop  cx
    pop  ax
    ret

imprimir_hex16:                 ; AX en hexadecimal (4 digitos)
    push ax
    mov  al, ah
    call imprimir_hex8
    pop  ax
    call imprimir_hex8
    ret

nibble:                         ; AL (0-15) -> caracter hexadecimal
    add  al, 30h
    cmp  al, 39h
    jbe  .p
    add  al, 7
.p:
    mov  dl, al
    mov  ah, 02h
    int  21h
    ret

section .data
resultado   db 0
sinAjuste   db 0
msgSuma     db "BCD suma: $"
msgSin      db "  Sin DAA el resultado seria: $"
msg99       db "99h + 01h con DAA: AL=$"
msgDas      db "DAS OK: $"
msgSin2     db "  sin DAS: $"
msg20       db "20h - 01h: sin DAS AL=$"
msgCon      db ", con DAS AL=$"
msgCF       db "  CF=$"
msgErrDas   db "Error en DAS.", 0Dh, 0Ah, "$"
crlf        db 0Dh, 0Ah, "$"
