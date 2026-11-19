; post2d.asm - AAA y AAS: ajuste de BCD desempaquetado (un digito por byte)
; Compilar: nasm -f bin post2d.asm -o post2d.com
;
; AAA ajusta AL tras una suma: si el nibble bajo > 9 (o AF=1) suma 6 a AL,
; incrementa AH y pone a cero el nibble alto de AL. AAS hace lo equivalente
; tras una resta (resta 6, decrementa AH).
;
; Cambio respecto a la guia: AAA e AAS modifican AH, asi que AH debe cargarse
; antes de la operacion (la guia lo dejaba con 09h/02h de la llamada a INT
; 21h anterior, y el resultado salia 0Ah en vez de 01).

[BITS 16]
ORG 100h

DIG_7       EQU 07h
DIG_8       EQU 08h
DIG_3       EQU 03h

section .text
start:
    ; ---- Suma desempaquetada con AAA: 7 + 8 = 15 ----
    mov  dx, msgSuma
    call imprimir
    mov  ah, 0                  ; AH = decenas iniciales
    mov  al, DIG_7
    add  al, DIG_8              ; AL = 0Fh (no es digito desempaquetado valido)
    mov  [antes], al
    aaa                         ; AL = 05h, AH = 01h, CF = 1
    mov  [resAH], ah
    mov  [resAL], al
    mov  dl, [resAH]
    add  dl, 30h
    mov  ah, 02h
    int  21h                    ; decena
    mov  dl, [resAL]
    add  dl, 30h
    mov  ah, 02h
    int  21h                    ; unidad
    mov  dx, msgDetalle
    call imprimir
    mov  al, [antes]
    call imprimir_hex8
    mov  dx, msgAAA
    call imprimir
    mov  al, [resAH]
    call imprimir_hex8
    mov  dl, ':'
    mov  ah, 02h
    int  21h
    mov  al, [resAL]
    call imprimir_hex8
    mov  dx, cierra
    call imprimir

    ; ---- Resta desempaquetada con AAS: 13 - 8 = 5 ----
    mov  dx, msgResta
    call imprimir
    mov  ah, 01h                ; "13": AH = 1 (decena), AL = 3 (unidad)
    mov  al, DIG_3
    sub  al, DIG_8              ; AL = FBh (hubo prestamo)
    mov  [antes], al
    aas                         ; AL = 05h, AH = 00h, CF = 1
    mov  [resAH], ah
    mov  [resAL], al
    cmp  byte [resAH], 0
    je   .sinDecena
    mov  dl, [resAH]
    add  dl, 30h
    mov  ah, 02h
    int  21h
.sinDecena:
    mov  dl, [resAL]
    add  dl, 30h
    mov  ah, 02h
    int  21h
    mov  dx, msgDetalle
    call imprimir
    mov  al, [antes]
    call imprimir_hex8
    mov  dx, msgAAS
    call imprimir
    mov  al, [resAH]
    call imprimir_hex8
    mov  dl, ':'
    mov  ah, 02h
    int  21h
    mov  al, [resAL]
    call imprimir_hex8
    mov  dx, cierra
    call imprimir

    ; ---- Demostraciones para la decision tecnica ----
    ; (a) DAA (en vez de AAA) sobre el resultado desempaquetado 7 + 8 = 0Fh
    mov  al, DIG_7
    add  al, DIG_8              ; AL = 0Fh, CF = 0, AF = 0
    daa                         ; AL = 15h: ajusta los dos nibbles, AH no cambia
    mov  [resAL], al
    mov  dx, msgDemoA
    call imprimir
    mov  al, [resAL]
    call imprimir_hex8
    mov  dx, crlf
    call imprimir

    ; (b) AAA sobre un byte empaquetado: 47h + 38h = 7Fh
    mov  ah, 0
    mov  al, 47h
    add  al, 38h
    aaa                         ; destruye el nibble alto (las decenas)
    mov  [resAH], ah
    mov  [resAL], al
    mov  dx, msgDemoB
    call imprimir
    mov  al, [resAH]
    call imprimir_hex8
    mov  dl, ':'
    mov  ah, 02h
    int  21h
    mov  al, [resAL]
    call imprimir_hex8
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
antes       db 0
resAH       db 0
resAL       db 0
msgSuma     db "AAA: 7 + 8 = $"
msgResta    db "AAS: 13 - 8 = $"
msgDetalle  db "   (AL antes del ajuste=$"
msgAAA      db "h; tras AAA AH:AL=$"
msgAAS      db "h; tras AAS AH:AL=$"
msgDemoA    db "Demo: DAA sobre 07h+08h=0Fh deja AL=$"
msgDemoB    db "Demo: AAA sobre el empaquetado 47h+38h=7Fh deja AH:AL=$"
cierra      db ")", 0Dh, 0Ah, "$"
crlf        db 0Dh, 0Ah, "$"
