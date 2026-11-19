; post1e.asm - LODSB + STOSB: copia con transformacion a mayusculas
; Compilar: nasm -f bin post1e.asm -o post1e.com
;
; REP MOVSB mueve bytes sin inspeccionarlos; para transformar cada caracter
; durante la copia se usa un bucle manual: LODSB carga AL desde DS:SI (SI
; avanza), se resta 20h si AL esta entre 'a' y 'z', y STOSB lo guarda en
; ES:DI (DI avanza). DF=0 mediante CLD.
;
; Cambios respecto a la guia: TIMES en lugar de "dup" y cadena terminada en '$'.

[BITS 16]
ORG 100h

LARGO        EQU 13

section .text
start:
    mov  ax, ds
    mov  es, ax

    mov  dx, msgOri
    call imprimir
    mov  dx, origen
    call imprimir
    mov  dx, crlf
    call imprimir

    mov  si, origen
    mov  di, destino
    mov  cx, LARGO
    cld

.bucle:
    lodsb                       ; AL = [DS:SI], SI avanza automaticamente
    cmp  al, 'a'
    jb   .escribir              ; AL < 'a': no es minuscula
    cmp  al, 'z'
    ja   .escribir              ; AL > 'z': no es minuscula
    sub  al, 20h                ; 'a'-'z' -> 'A'-'Z'
.escribir:
    stosb                       ; [ES:DI] = AL, DI avanza automaticamente
    loop .bucle

    mov  dx, msgCop
    call imprimir
    mov  dx, destino
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

section .data
origen      db "hola, mundo!$"
destino     times LARGO db 0
msgOri      db "Origen:        $"
msgCop      db "Transformado: $"
crlf        db 0Dh, 0Ah, "$"
