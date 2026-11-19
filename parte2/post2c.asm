; post2c.asm - MUL y DIV: calculadora de un digito (con AAM para mostrar)
; Compilar: nasm -f bin post2c.asm -o post2c.com
;
; Lee dos digitos con INT 21h/AH=01h (eco), los convierte de ASCII a binario
; restando 30h y realiza * (MUL) o / (DIV). El resultado se muestra con una
; subrutina que divide repetidamente entre 10 (imprimir_ax). Para la
; multiplicacion (maximo 81) se muestra ademas el ajuste AAM, que separa el
; resultado en decenas (AH) y unidades (AL).

[BITS 16]
ORG 100h

OP_MUL      EQU '*'
OP_DIV      EQU '/'

section .text
start:
    ; Operando A
    mov  dx, pA
    call imprimir
    mov  ah, 01h
    int  21h
    sub  al, 30h
    mov  bl, al                 ; BL = A

    ; Operando B
    mov  dx, pB
    call imprimir
    mov  ah, 01h
    int  21h
    sub  al, 30h
    mov  cl, al                 ; CL = B

    ; Operador
    mov  dx, pOper
    call imprimir
    mov  ah, 01h
    int  21h
    mov  bh, al                 ; BH = operador

    mov  dx, msgR
    call imprimir

    cmp  bh, OP_MUL
    je   .mul
    cmp  bh, OP_DIV
    je   .div
    mov  dx, msgOpErr
    call imprimir
    jmp  .fin

.mul:
    mov  al, bl
    mul  cl                     ; AX = AL * CL (sin signo)
    push ax
    call imprimir_ax
    pop  ax
    aam                         ; AH = AX / 10 (decenas), AL = AX mod 10 (unidades)
    mov  bx, ax
    mov  dx, msgAam
    call imprimir
    mov  al, bh
    add  al, 30h
    mov  dl, al
    mov  ah, 02h
    int  21h
    mov  dl, ','
    mov  ah, 02h
    int  21h
    mov  al, bl
    add  al, 30h
    mov  dl, al
    mov  ah, 02h
    int  21h
    mov  dl, ']'
    mov  ah, 02h
    int  21h
    jmp  .fin

.div:
    cmp  cl, 0
    je   .divCero
    xor  ah, ah                 ; AX = A (division de 16 entre 8 bits)
    mov  al, bl
    div  cl                     ; AL = cociente, AH = resto
    xor  ah, ah
    call imprimir_ax
    jmp  .fin

.divCero:
    mov  dx, msgErr
    call imprimir

.fin:
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
pA          db "Primer operando (0-9): $"
pB          db 0Dh, 0Ah, "Segundo operando (0-9): $"
pOper         db 0Dh, 0Ah, "Operacion (* o /): $"
msgR        db 0Dh, 0Ah, "Resultado: $"
msgAam      db "  [AAM: decenas,unidades = $"
msgErr      db 0Dh, 0Ah, "Division por cero.$"
msgOpErr    db "Operacion no valida.$"
crlf        db 0Dh, 0Ah, "$"
