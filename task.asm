SSG SEGMENT PARA STACK 'STACK'
    DB 64 DUP (?)
SSG ENDS

DSG SEGMENT PARA PUBLIC 'DATA'
    MSG_GET_X DB 'X = $'
    MSG_GET_Y DB 'Y = $'
    MSG_OVERFLOW DB 'OVERFLOW!$'
    MSG_WRONG_DATA DB 'WRONG DATA!$'
    MSG_DIV_ZERO DB 'ZERO DEVIDE!$'

    X DW ?
    Y DW ?
    Z DW ?
    Z_SUB DW ?
    ISNEG DB 0
    BUFFER_X DB 7, ?, 7 DUP(?)
    BUFFER_Y DB 7, ?, 7 DUP(?)
    TEN DW 10
DSG ENDS

CSG SEGMENT PARA PUBLIC "CODE"
    MAIN PROC FAR
        ASSUME CS:CSG, DS:DSG, SS:SSG
        PUSH DS
        XOR AX, AX
        PUSH AX
        MOV AX, DSG
        MOV DS, AX
            
        CALL INPUT
        CALL CHECKNUMS
        
        CMP X, 0
        JL FUNC2            ;35X^2 + 8X             x < 0
        CMP X, 10
        JG FUNC3            ;(10-X)^2               x > 10
        MOV AX, X
        CMP AX, Y      
        JNE FUNC1           ;(15X-1)/(Y(X-Y))       0 <= x <= 10  y!=x
        JMP WRONG_DATA

        FUNC1:              ;(15X-1)/(Y(X-Y))
            MOV BX, Y
            SUB AX, BX
            JO OVERFLOW 
            IMUL BX         ;Y(X-Y)
            JO OVERFLOW
            TEST AX, AX
            JZ DIV_ZERO
            MOV Z, AX

            MOV AX, X
            MOV BX, 15
            IMUL BX
            JO OVERFLOW
            SUB AX, 1       ;15X-1
            JO OVERFLOW

            XOR DX, DX
            IDIV Z          ;(15X-1)/(Y(X-Y))
            MOV Z, AX
            MOV Z_SUB, DX
            JMP FINISH

        FUNC2:              ;35X^2 + 8X
            MOV AX, X
            IMUL AX
            JO OVERFLOW
            MOV BX, 35
            IMUL BX
            JO OVERFLOW
            MOV Z, AX       ;35X^2

            MOV AX, X
            MOV BX, 8
            IMUL BX         ;8X
            JO OVERFLOW
            ADD Z, AX       ;35X^2 + 8X
            JO OVERFLOW
            JMP FINISH

        FUNC3:              ;(10-X)^2
            MOV AX, 10
            SUB AX, X
            JO OVERFLOW
            IMUL AX
            JO OVERFLOW
            MOV Z, AX
            JMP FINISH
        
        WRONG_DATA:
            LEA DX, MSG_WRONG_DATA
            JMP ERROR
        OVERFLOW:
            LEA DX, MSG_OVERFLOW
            JMP ERROR
        DIV_ZERO:
            LEA DX, MSG_DIV_ZERO
            JMP ERROR
        FINISH:
            CALL OUTPUT
            RET
    MAIN ENDP
    
    CHECKNUMS PROC NEAR 
        XOR AX, AX
        LEA SI, BUFFER_X+1
        MOV CL, [SI]
        INC SI
        CALL CHECK_SIGN
        CALL CHECK_SYMBOLS
        CMP ISNEG, 0
        JE END_CHECK_X
        NEG AX
        END_CHECK_X:
            MOV X, AX
            MOV ISNEG, 0
        
        XOR AX, AX
        LEA SI, BUFFER_Y+1
        MOV CL, [SI]
        INC SI
        CALL CHECK_SIGN
        CALL CHECK_SYMBOLS
        CMP ISNEG, 0
        JE END_CHECK_Y
        NEG AX
        END_CHECK_Y:
            MOV Y, AX
        RET

        CHECK_SIGN:
        MOV BL, [SI]
        CMP BL, '-'
        JNE FINAL
        INC SI
        MOV ISNEG, 1
        DEC CX
        FINAL:
        RET
        
        CHECK_SYMBOLS:
        IMUL TEN
        JO OVERFLOW
        MOV BL, [SI]
        CMP BL, '0'
        JB WRONG_DATA
        CMP BL, '9'
        JA WRONG_DATA
        SUB BL, '0'
        ADD AX, BX
        JNO INC_FOR_NEXT
        CMP ISNEG, 0
        JE OVERFLOW
        CMP AX, 32768
        JE OVERFLOW
        INC_FOR_NEXT:
            INC SI
            LOOP CHECK_SYMBOLS
        RET
    CHECKNUMS ENDP

    ERROR PROC NEAR
        MOV AH, 9
        INT 21H
        MOV AX, 4C00H
        INT 21H
        CALL NEXTLINE
    ERROR ENDP

    INPUT PROC NEAR
        MOV AH, 9
        LEA DX, MSG_GET_X
        INT 21H
        MOV AH, 10
        LEA DX, BUFFER_X
        INT 21H
        CALL NEXTLINE

        MOV AH, 9
        LEA DX, MSG_GET_Y
        INT 21h
        MOV AH, 10
        LEA DX, BUFFER_Y
        INT 21H
        CALL NEXTLINE
        RET

        NEXTLINE:
        MOV AH, 2
        MOV DL, 10          ; ASCII [10]/[AH] - NEW LINE
        INT 21H
        RET
    INPUT ENDP

    OUTPUT PROC NEAR
        MOV AX, Z
        TEST AX, AX
        JNS SET_BASIC
        MOV AL, '-'
        INT 29H
        NEG Z
        MOV AX, Z

        SET_BASIC:
            XOR CX, CX
        STACKING:
            XOR DX, DX
            DIV TEN 
            ADD DL, '0'     ;'8' -> SCII CODE
            PUSH DX
            INC CX
            TEST AX, AX
            JNZ STACKING
        UNSTACKING:
            POP AX
            INT 29H
            LOOP UNSTACKING
        
        MOV AX, Z_SUB
        TEST AX, AX
        JZ ISZERO
        STACKING_SUB:
            XOR DX, DX
            DIV TEN
            ADD DL, '0'
            PUSH DX
            INC CX
            TEST AX, AX
            JNZ STACKING_SUB
        MOV AL, '('
        INT 29H
        UNSTACKING_SUB:
            POP AX
            INT 29H
            LOOP UNSTACKING_SUB
        MOV AL, ')'
        INT 29H
        ISZERO:
            CALL NEXTLINE
            RET
    OUTPUT ENDP

CSG ENDS
END MAIN