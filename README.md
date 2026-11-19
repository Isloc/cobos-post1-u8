# Post 8 – Operaciones con cadenas y aritmética: NASM sobre DOSBox

Repositorio de la actividad de Arquitectura de Computadores (UFPS). Autora: Isabella Cobos Lizarazo (código 1152507, GitHub Isloc).

Todos los programas se ensamblaron con NASM 2.16.03 dentro de DOSBox 0.74-3 (`nasm -f bin archivo.asm -o archivo.com`) y se ejecutaron allí mismo. Cada captura de la carpeta `capturas/` proviene de esa sesión real.

## Estructura

```
parte1/  post1, post1c, post1d, post1e  (.asm + .com)   cadenas
parte2/  post2, post2b, post2c, post2d  (.asm + .com)   aritmética
capturas/  evidencias de DOSBox (nombre = punto de control_orden_descripción)
```

## Parte 1 – Instrucciones de cadena

Las instrucciones de cadena (MOVSB/MOVSW, CMPSB, SCASB, LODSB, STOSB) trabajan con los registros SI (origen, segmento DS) y DI (destino, segmento ES), y el prefijo REP/REPE/REPNE las repite usando CX como contador. La bandera de dirección DF decide el sentido: con `CLD` (DF=0) SI y DI se incrementan tras cada elemento, de modo que la cadena se recorre hacia direcciones altas; con `STD` (DF=1) se decrementan. Todos los programas emplean `CLD` antes de operar, y el volcado de DEBUG muestra `UP` (DF=0) tras cada copia.

| Programa | Rutina | Resultado observado |
|---|---|---|
| `post1` | `REP MOVSB` copia "HOLA, MUNDO!" (13 bytes); luego `MOVSW` copia de a dos bytes más `MOVSB` para el byte impar; `REPE CMPSB` verifica la copia | SI−origen=13, DI−destino=13, CX=0, DF=0; la verificación informa cadenas iguales |
| `post1c` | `REPNE SCASB` busca un carácter en una cadena de 28 bytes | 'd' hallado en la posición 13 (CX restante=14); 'z' no encontrado (CX llega a 0 sin ZF) |
| `post1d` | `REPE CMPSB` compara cadenas | primera diferencia en el índice 5 (CX restante=2); caso con terminador nulo y bucle manual |
| `post1e` | bucle `LODSB` / `CMP 'a'..'z'` / `SUB AL,20h` / `STOSB` | "hola, mundo!" → "HOLA, MUNDO!" |

## Parte 2 – Aritmética

| Programa | Contenido | Resultado observado |
|---|---|---|
| `post2` | `ADD`+`ADC` y `SUB`+`SBB` de 32 bits sobre pares de registros; suma de 48 bits con `ADC` en bucle | 0001FFFF+00010001=00030000; 00030000−00010001=0001FFFF; 48 bits → 0002:0000:0000 |
| `post2b` | `DAA` y `DAS` sobre BCD empaquetado | 47h+38h → 85 (sin DAA 7Fh); 99h+01h → 00 con CF=1; 73h−28h → 45 (sin DAS 4Bh) |
| `post2c` | calculadora de un dígito con `MUL` y `DIV` | 7×8=56; 9/3=3; 5/0 → "División por cero." sin que el programa se interrumpa |
| `post2d` | `AAA` y `AAS` sobre BCD desempaquetado | 7+8 → AH:AL=01:05 (15); 13−8 → 05 |

**Byte de acarreo.** `ADC` suma además el valor de CF y `SBB` resta además CF (préstamo). Con ellos la palabra baja se opera con `ADD`/`SUB`, que deja el acarreo o préstamo en CF, y la palabra alta con `ADC`/`SBB`, que lo absorbe. Así se obtienen resultados de 32 bits (y de 48 en el bucle) con registros de 16. Las instrucciones `INC`, `DEC` y `LOOP` no modifican CF, por lo que pueden usarse entre dos `ADC` del bucle sin romper la cadena de acarreo.

**Ajuste BCD.** Tras sumar o restar dos bytes BCD, el resultado binario es incorrecto cuando un nibble supera 9. `DAA`/`DAS` corrigen un byte con dos dígitos decimales empaquetados (47h+38h da 7Fh y DAA lo lleva a 85h). `AAA`/`AAS` corrigen un byte con un solo dígito desempaquetado (0Fh se convierte en AH:AL=01:05) y propagan el acarreo decimal a AH.

**Lógica de la calculadora.** El programa lee dos dígitos ASCII con INT 21h/AH=01h, resta 30h para obtener su valor, lee el operador y bifurca. Para `*` usa `MUL` (AX=AL×operando) y para `/` usa `DIV` tras comprobar que el divisor no es cero; en ese caso muestra el mensaje de error y no ejecuta la división, evitando la excepción de división. El resultado se imprime dividiendo repetidamente entre 10 (rutina `imprimir_ax`); en la multiplicación se muestra además la separación decenas/unidades con `AAM`.

## Decisiones técnicas

### Parte 1 – Decisión 1: `REP MOVSB` frente a un bucle manual `LODSB`/`STOSB`

Para copiar la cadena se eligió `REP MOVSB` porque una sola instrucción hace lo que el bucle manual hace con cinco o seis: lee el byte de DS:SI, lo escribe en ES:DI, avanza ambos índices según DF y decrementa CX hasta cero. Con eso desaparecen el salto condicional, la comparación del contador y el riesgo de olvidar un `INC` o `DEC`. En el microcódigo de los procesadores x86 las operaciones con prefijo REP están además optimizadas, de modo que en copias largas resultan más rápidas que un bucle escrito instrucción por instrucción. El bucle manual con `LODSB` y `STOSB` se reservó para `post1e`, donde sí hace falta intervenir en cada byte (convertir a mayúscula antes de guardarlo), cosa que `MOVSB` no permite porque copia de memoria a memoria sin pasar por AL. La regla aplicada fue: copia pura, `REP MOVSB`; copia con transformación, `LODSB`/`STOSB`. La evidencia está en `p1_cp1_*` (SI, DI y CX tras la copia, con DEBUG) y en `p1_cp5_*`, que muestra el bucle manual funcionando.

### Parte 1 – Decisión 2: CX fijo en `REPE CMPSB`/`REPNE SCASB` frente a revisar el terminador nulo

El prefijo `REPE CMPSB` o `REPNE SCASB` obliga a conocer de antemano cuántos bytes examinar, porque CX es el único criterio de parada además de ZF. La ventaja es la velocidad y la simplicidad: no hace falta código de control por cada carácter. El inconveniente quedó demostrado en el tercer caso de `post1d`: con `corta db "NASM",0,"AAA"` y `larga db "NASM",0,"BBB"`, un CX de 8 compara también los bytes que siguen al terminador y concluye "Diferentes", aunque ambas cadenas, vistas como texto terminado en cero, son idénticas. En el cuarto caso, un bucle manual con `LODSB` que se detiene al encontrar el byte 0 informa correctamente "Iguales". Por eso se usó CX fijo cuando la longitud es una constante conocida (`LARGO`, `LONGCAD`) y la comprobación manual del terminador cuando las cadenas pueden diferir en longitud real. La captura `p1_cp4_b_cmpsb_ejecucion.png` muestra ambos comportamientos.

### Parte 2 – Decisión 3: `DAA`/`DAS` frente a `AAA`/`AAS`

La elección depende del formato BCD de los datos. `DAA` y `DAS` ajustan AL cuando contiene dos dígitos decimales empaquetados (nibble alto y bajo), así que se usaron en `post2b` para sumas como 47h+38h=85h. `AAA` y `AAS` suponen un solo dígito por byte (0 a 9 en el nibble bajo, nibble alto en cero) y dejan el acarreo decimal en AH, por lo que son adecuadas cuando se opera con dígitos ASCII leídos del teclado y desempaquetados, como en `post2d`. Aplicar la instrucción equivocada produce resultados erróneos: la demostración de `post2d` muestra `AAA` sobre el empaquetado 47h+38h=7Fh, que deja AH:AL=01:05 en lugar de 85, y `DAA` sobre 07h+08h=0Fh, que sí da 15. Además, `AAA`/`AAS` leen AH, y durante el desarrollo se encontró que, si no se inicializa explícitamente, AH conserva el valor de la llamada INT 21h anterior y el ajuste imprime un resultado equivocado. Evidencia: `p2_cp3_*`, `p2_cp4_*` y `p2_cp6_*`.

### Parte 2 – Decisión 4: precisión fija con `ADC` frente a una cadena de `ADC` en bucle

Para sumar 32 bits bastan dos instrucciones, `ADD` en la parte baja y `ADC` en la alta, sin bucle, sin contador y con todo el valor en registros; es la opción más corta y rápida, pero queda atada al ancho elegido. Para el caso de 48 bits, o cualquier tamaño que no se conozca al escribir el programa, se implementó en `post2` una cadena de `ADC` dentro de un bucle sobre arreglos de palabras: el primer elemento se suma con `ADD`, que no depende de un acarreo previo, y los demás con `ADC`. Esto exige no alterar CF entre iteraciones, y por eso el bucle usa solo `INC` y `LOOP`, que no lo modifican, en lugar de `ADD SI,2`, que lo sobrescribiría. El bucle tiene mayor costo por iteración, pero escala a cualquier longitud cambiando únicamente CX. La regla adoptada fue precisión fija cuando el ancho es conocido y bucle cuando puede variar. Evidencia: `p2_cp1_*` y `p2_cp2_*`, con la salida de 32 y 48 bits y los registros en DEBUG tras `ADC` y `SBB`.

## Puntos de control y capturas

| Punto | Capturas |
|---|---|
| P1-CP1 MOVSB | `p1_cp1_a_compila_post1`, `p1_cp1_b_movsb_ejecucion`, `p1_cp1_c_debug_tras_rep_movsb` |
| P1-CP2 MOVSW | `p1_cp2_a_movsw_ejecucion`, `p1_cp2_b_debug_tras_movsw` |
| P1-CP3 SCASB (hallado y 'z' no hallado) | `p1_cp3_a_compila_post1c`, `p1_cp3_b_scasb_hallado_y_no_hallado` |
| P1-CP4 CMPSB | `p1_cp4_a_compila_post1d`, `p1_cp4_b_cmpsb_ejecucion` |
| P1-CP5 LODSB/STOSB | `p1_cp5_a_compila_post1e`, `p1_cp5_b_lodsb_stosb_mayusculas` |
| P1-CP6 decisiones 1 y 2 | `p1_cp1_c_debug_tras_rep_movsb`, `p1_cp5_b_lodsb_stosb_mayusculas`, `p1_cp4_b_cmpsb_ejecucion` |
| P2-CP1 ADC | `p2_cp1_a_compila_post2`, `p2_cp1_b_adc_sbb_ejecucion`, `p2_cp1_c_debug_tras_adc` |
| P2-CP2 SBB | `p2_cp1_b_adc_sbb_ejecucion`, `p2_cp2_a_debug_tras_sbb` |
| P2-CP3 DAA | `p2_cp3_a_compila_post2b`, `p2_cp3_b_daa_das_ejecucion` |
| P2-CP4 DAS | `p2_cp3_b_daa_das_ejecucion`, `p2_cp4_a_das_resultado` |
| P2-CP5 calculadora (7×8, 9/3, división por cero) | `p2_cp5_a_compila_post2c`, `p2_cp5_b_mul_7x8`, `p2_cp5_c_div_9entre3`, `p2_cp5_d_div_por_cero` |
| P2-CP6 AAA/AAS | `p2_cp6_a_compila_post2d`, `p2_cp6_b_aaa_aas_ejecucion` |
| P2-CP7 decisiones 3 y 4 | `p2_cp6_b_aaa_aas_ejecucion` (demostraciones DAA/AAA), `p2_cp1_b_adc_sbb_ejecucion` (32 y 48 bits) |

Las capturas de los puntos de decisión reutilizan las ejecuciones que respaldan cada argumento; no se produjeron capturas distintas para ellos.

## Desviaciones respecto al código de la guía

- `dup(...)` no existe en NASM: se usó `times N db 0`.
- `LONG` es palabra reservada y la etiqueta `pOp` se interpreta como la instrucción `POP`: se renombraron a `LARGO` y `pOper`.
- La función 09h de INT 21h imprime hasta `$`: se agregaron terminadores `$` a las cadenas mostradas.
- En `post1c` la guía anuncia la posición 4; en la ejecución real la primera 'd' está en el índice 13 (base 0), y se imprime en decimal de dos cifras.
- En `post1d` la diferencia aparece en el índice 5 (sexto carácter), no en el quinto como indica el texto de la guía.
- En `post2d` se inicializa AH antes de `AAA`/`AAS`. La primera versión de la demostración con `DAA` mostró AL=75 por un CF heredado de `AAS`; se corrigió reiniciando AL con `mov al,DIG_7 / add al,DIG_8 / daa`, y las capturas corresponden a la versión corregida.
- Se añadieron extras no pedidos: caso de riesgo y bucle manual en `post1d`, suma de 48 bits en `post2`, separación `AAM` en `post2c`.
- DOSBox carga el teclado `es`: para escribir `*` se cambió a `keyb us` y para `/` a `keyb sp` durante la ejecución de la calculadora.
- Los binarios `.com` incluidos son los generados en esa sesión de DOSBox.
