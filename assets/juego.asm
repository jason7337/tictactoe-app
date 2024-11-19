; Programa de TicTacToe optimizado para el emulador
org 100h

JMP INICIO

; --- Datos y mensajes ---
MSG_TITULO      DB 13,10,'=== TIC TAC TOE ===',13,10,'$'
MSG_TURNO       DB 13,10,'Turno del Jugador $'
MSG_JUGADOR1    DB '1 (X)',13,10,'$'
MSG_JUGADOR2    DB '2 (O)',13,10,'$'
MSG_ENTRADA     DB 'Ingrese posicion (1-9): $'
MSG_INVALIDO    DB 13,10,'Movimiento invalido!',13,10,'$'
MSG_GANADOR     DB 13,10,'!!! JUGADOR $'
MSG_GANA        DB ' GANA !!!',13,10,'$'
MSG_EMPATE      DB 13,10,'!!! EMPATE !!!',13,10,'$'
MSG_NUEVA_LINEA DB 13,10,'$'

; Tablero con formato optimizado
TABLERO DB ' 1 | 2 | 3 ',13,10
        DB '---+---+---',13,10
        DB ' 4 | 5 | 6 ',13,10
        DB '---+---+---',13,10
        DB ' 7 | 8 | 9 ',13,10,'$'

TURNO_ACTUAL DB 1    ; 1 = Jugador 1 (X), 2 = Jugador 2 (O)

; --- Inicio del programa ---
INICIO:
    ; Mostrar título
    MOV AH, 09h
    MOV DX, OFFSET MSG_TITULO
    INT 21h
    
MAIN_LOOP:
    ; Mostrar tablero
    CALL MOSTRAR_TABLERO
    
    ; Mostrar turno actual
    CALL MOSTRAR_TURNO
    
    ; Solicitar y procesar movimiento
    CALL PROCESAR_MOVIMIENTO
    
    ; Verificar si hay ganador
    CALL VERIFICAR_GANADOR
    CMP AL, 1
    JE HAY_GANADOR
    
    ; Verificar empate
    CALL VERIFICAR_EMPATE
    CMP AL, 1
    JE HAY_EMPATE
    
    ; Cambiar turno y continuar
    CALL CAMBIAR_TURNO
    JMP MAIN_LOOP

; --- Rutinas principales ---
MOSTRAR_TABLERO:
    MOV AH, 09h
    MOV DX, OFFSET MSG_NUEVA_LINEA
    INT 21h
    MOV DX, OFFSET TABLERO
    INT 21h
    RET

MOSTRAR_TURNO:
    MOV AH, 09h
    MOV DX, OFFSET MSG_TURNO
    INT 21h
    
    MOV AL, [TURNO_ACTUAL]
    CMP AL, 1
    JE MOSTRAR_J1
    MOV DX, OFFSET MSG_JUGADOR2
    JMP MOSTRAR_MENSAJE_TURNO
MOSTRAR_J1:
    MOV DX, OFFSET MSG_JUGADOR1
MOSTRAR_MENSAJE_TURNO:
    INT 21h
    RET

PROCESAR_MOVIMIENTO:
    ; Mostrar prompt
    MOV AH, 09h
    MOV DX, OFFSET MSG_ENTRADA
    INT 21h
    
    ; Leer entrada
    MOV AH, 01h
    INT 21h
    
    ; Convertir ASCII a número (1-9)
    SUB AL, '0'
    
    ; Validar entrada (1-9)
    CMP AL, 1
    JL MOVIMIENTO_INVALIDO
    CMP AL, 9
    JG MOVIMIENTO_INVALIDO
    
    ; Convertir número a índice en el tablero
    CALL CONVERTIR_A_INDICE
    
    ; Verificar si la casilla está ocupada
    CALL VERIFICAR_CASILLA
    CMP AL, 0
    JE MOVIMIENTO_INVALIDO
    
    ; Realizar movimiento
    CALL REALIZAR_MOVIMIENTO
    RET

MOVIMIENTO_INVALIDO:
    MOV AH, 09h
    MOV DX, OFFSET MSG_INVALIDO
    INT 21h
    JMP PROCESAR_MOVIMIENTO

CONVERTIR_A_INDICE:
    ; Entrada: AL = número (1-9)
    ; Salida: BX = índice en el tablero
    DEC AL          ; Convertir 1-9 a 0-8
    MOV AH, 0
    MOV BL, 4       ; Cada casilla está separada por 4 caracteres
    MUL BL
    MOV BX, AX
    ADD BX, OFFSET TABLERO
    ADD BX, 1       ; Ajustar por el espacio inicial
    RET

VERIFICAR_CASILLA:
    ; Entrada: BX = posición en el tablero
    ; Salida: AL = 1 si está libre, 0 si está ocupada
    MOV AL, [BX]
    CMP AL, 'X'
    JE CASILLA_OCUPADA
    CMP AL, 'O'
    JE CASILLA_OCUPADA
    MOV AL, 1
    RET
CASILLA_OCUPADA:
    MOV AL, 0
    RET

REALIZAR_MOVIMIENTO:
    MOV AL, [TURNO_ACTUAL]
    CMP AL, 1
    JE PONER_X
    MOV BYTE PTR [BX], 'O'
    JMP FIN_MOVIMIENTO
PONER_X:
    MOV BYTE PTR [BX], 'X'
FIN_MOVIMIENTO:
    RET

VERIFICAR_GANADOR:
    ; Implementación de verificación de victoria
    ; (Horizontal, vertical y diagonal)
    MOV AL, 0  ; Por ahora retornamos sin ganador
    RET

VERIFICAR_EMPATE:
    ; Verifica si quedan movimientos posibles
    MOV AL, 0  ; Por ahora retornamos sin empate
    RET

CAMBIAR_TURNO:
    MOV AL, [TURNO_ACTUAL]
    CMP AL, 1
    JE CAMBIAR_A_J2
    MOV BYTE PTR [TURNO_ACTUAL], 1
    RET
CAMBIAR_A_J2:
    MOV BYTE PTR [TURNO_ACTUAL], 2
    RET

HAY_GANADOR:
    MOV AH, 09h
    MOV DX, OFFSET MSG_GANADOR
    INT 21h
    MOV AL, [TURNO_ACTUAL]
    ADD AL, '0'
    MOV AH, 02h
    MOV DL, AL
    INT 21h
    MOV AH, 09h
    MOV DX, OFFSET MSG_GANA
    INT 21h
    JMP FIN

HAY_EMPATE:
    MOV AH, 09h
    MOV DX, OFFSET MSG_EMPATE
    INT 21h
    JMP FIN

FIN:
    MOV AH, 4Ch
    INT 21h

ret