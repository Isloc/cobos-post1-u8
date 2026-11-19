; post2.asm - ADC y SBB: suma y resta de 32 bits (DX:AX) y suma de N palabras
; Compilar: nasm -f bin post2.asm -o post2.com
;
; Paso 1: A + B con ADD (parte baja) y ADC (parte alta). CF se propaga.
; Paso 2: A - B con SUB (parte baja) y SBB (parte alta). CF es el prestamo.
; Extra : suma de 48 bits (3 palabras) con un bucle: la primera palabra con
;         ADD y las demas con ADC; INC y LOOP no alteran CF, por lo que el
;         acarreo viaja de una palabra a la siguiente.

[BITS 16]
ORG 100h

section .text
start:
    ; ---- Paso 1: suma de 32 bits ----
    mov  ax, [aLo]
    mov  dx, [aHi]
    mov  bx, [bLo]
    mov  cx, [bHi]
    add  ax, bx                 ; FFFFh + 0001h = 0000h con CF=1
    pushf
    pop  si                     ; SI conserva los flags (bit 0 = CF)
    adc  dx, cx                 ; 0001h + 0001h + CF = 0003h
    mov  [resLo], ax
    mov  [resHi], dx

    cmp  ax, 0000h
    jne  .errSuma
    cmp  dx, 0003h
    jne  .errSuma
    mov  dx, msgSumaOk
    call imprimir
    mov  ax, [resHi]
    call imprimir_hex16
    mov  dl, ':'
    mov  ah, 02h
    int  21h
    mov  ax, [resLo]
    call imprimir_hex16
    mov  dx, msgCF
    call imprimir
    mov  ax, si
    and  ax, 1
    call imprimir_ax
    mov  dx, cierra
    call imprimir
    jmp  .resta
.errSuma:
    mov  dx, msgErrSuma
    call imprimir

    ; ---- Paso 2: resta de 32 bits ----
.resta:
    mov  ax, 0000h              ; parte baja de A = 0x00030000
    mov  dx, 0003h              ; parte alta de A
    mov  bx, 0001h              ; parte baja de B = 0x00010001
    mov  cx, 0001h              ; parte alta de B
    sub  ax, bx                 ; 0000h - 0001h = FFFFh con CF=1 (prestamo)
    pushf
    pop  si
    sbb  dx, cx                 ; 0003h - 0001h - CF = 0001h
    mov  [resLo], ax
    mov  [resHi], dx

    cmp  ax, 0FFFFh
    jne  .errResta
    cmp  dx, 0001h
    jne  .errResta
    mov  dx, msgRestaOk
    call imprimir
    mov  ax, [resHi]
    call imprimir_hex16
    mov  dl, ':'
    mov  ah, 02h
    int  21h
    mov  ax, [resLo]
    call imprimir_hex16
    mov  dx, msgCF
    call imprimir
    mov  ax, si
    and  ax, 1
    call imprimir_ax
    mov  dx, cierra
    call imprimir
    jmp  .extra
.errResta:
    mov  dx, msgErrResta
    call imprimir

    ; ---- Extra: suma de 48 bits (3 palabras) con bucle ADD + ADC ----
.extra:
    mov  si, numA
    mov  bx, numB
    mov  di, numR
    mov  ax, [si]
    add  ax, [bx]               ; primera palabra: no hay acarreo previo
    mov  [di], ax
    mov  cx, NPAL - 1           ; palabras restantes
.sumar:
    inc  si                     ; INC no modifica CF
    inc  si
    inc  bx
    inc  bx
    inc  di
    inc  di
    mov  ax, [si]               ; MOV no modifica CF
    adc  ax, [bx]               ; suma la palabra mas el acarreo anterior
    mov  [di], ax
    loop .sumar                 ; LOOP no modifica CF

    mov  dx, msgN
    call imprimir
    mov  ax, [numR + 4]
    call imprimir_hex16
    mov  dl, ':'
    mov  ah, 02h
    int  21h
    mov  ax, [numR + 2]
    call imprimir_hex16
    mov  dl, ':'
    mov  ah, 02h
    int  21h
    mov  ax, [numR]
    call imprimir_hex16
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
NPAL        EQU 3
; A = 0x0001FFFF = 131071;  B = 0x00010001 = 65537
aLo         dw 0FFFFh
aHi         dw 0001h
bLo         dw 0001h
bHi         dw 0001h
resLo       dw 0
resHi       dw 0
; numeros de 48 bits, palabra menos significativa primero:
; A = 0001:FFFF:FFFF   B = 0000:0000:0001
numA        dw 0FFFFh, 0FFFFh, 0001h
numB        dw 0001h, 0000h, 0000h
numR        dw 0, 0, 0
msgSumaOk   db "Suma OK: $"
msgErrSuma  db "Error en suma.", 0Dh, 0Ah, "$"
msgRestaOk  db "Resta OK: $"
msgErrResta db "Error en resta.", 0Dh, 0Ah, "$"
msgCF       db "  (CF tras la parte baja=$"
msgN        db "Suma 48 bits (ADD + ADC en bucle): $"
cierra      db ")", 0Dh, 0Ah, "$"
crlf        db 0Dh, 0Ah, "$"
