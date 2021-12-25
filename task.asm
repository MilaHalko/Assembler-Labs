SSG SEGMENT PARA STACK 'STACK'
    DB 64 DUP (?)
SSG ENDS

DSG SEGMENT PARA PUBLIC 'DATA'
    BUFFER DB 7, 0, 7 DUP(?)
    NUM DW ?
    ISNEG DB 0
    ISERROR DB 0
    TEN DW 10

    MSG_INPUT DB 'Write number (-32768;32767) (3640 is max to get result x * 9): $'
    MSG_ERR   DB 'Wrong number!$'
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
        CALL CHECKNUM
        CALL CALCULATE
        CALL OUTPUT
        RET
    MAIN ENDP
    
    INPUT PROC NEAR
        MOV AH, 9
        LEA DX, MSG_INPUT
        INT 21H

        MOV AH, 10
        LEA DX, BUFFER
        INT 21H
        RET
    INPUT ENDP
    
    CHECKNUM PROC NEAR 
        XOR AX, AX
        LEA SI, BUFFER+1
        MOV CL, [SI]
        INC SI
        
        XOR BX, BX
        MOV BL, [SI]
        CMP BL, '-'
        JNE CHECK_SYMBOL
        INC SI
        MOV ISNEG, 1
        DEC CX

        CHECK_SYMBOL:
            IMUL TEN
            JO ERROR

            MOV BL, [SI]
            CMP BL, '0'
            JB ERROR
            CMP BL, '9'
            JA ERROR
            
            SUB BL, '0'
            ADD AX, BX
            JNC INC_FOR_NEXT
            CMP ISNEG, 0
            JE ERROR
            CMP AX, 32768
            JE ERROR

            INC_FOR_NEXT:
                INC SI
                LOOP CHECK_SYMBOL
        
        CMP ISNEG, 0
        JE END_CHECK
        NEG AX
        END_CHECK:
            MOV NUM, AX
        RET
    CHECKNUM ENDP

    CALCULATE PROC NEAR     ;NUM*9
        MOV AX, NUM
        MOV BX, 9
        IMUL BX
        JO ERROR
        MOV NUM, AX
        RET
    CALCULATE ENDP

    OUTPUT PROC NEAR 
        CALL NEXTLINE
        CMP ISNEG, 0
        JE SET_BASIC
        MOV AL, '-'
        INT 29H
        NEG NUM

        SET_BASIC:
            MOV AX, NUM
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
        RET
    OUTPUT ENDP
    
    NEXTLINE PROC NEAR
        MOV AH, 2
        MOV DL, 10          ; ASCII [10]/[AH] - NEW LINE
        INT 21H
        RET
    NEXTLINE ENDP
    
    ERROR PROC NEAR
        CALL NEXTLINE
        MOV AH, 9
        LEA DX, MSG_ERR
        INT 21H
        MOV AX, 4C00H       ;ЗАВЕРШЕНИЕ ПРОГИ
        INT 21H
        RET
    ERROR ENDP

CSG ENDS
END MAIN