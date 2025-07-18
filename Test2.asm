; 660510654
; Tanawin Thongbai
; Lab03_1
; 204231 Sec 002

OPTION M510
.MODEL SMALL
.STACK 100H
.DATA
bslashR EQU 13
bslashN EQU 10
new_line DB bslashR, bslashN, '$'
.CODE
main PROC
    MOV AX, @DATA ; Initialize
    MOV DS, AX
    MOV BH, -128 ; i
    MOV BL, 0 ; cnt
while_le_ed:
    CMP BH, -1 ; while(BH <= ed)
    JG while_done
    MOV AH, 2 ; printf("%c", BH)
    MOV DL, BH
    INT 21H
    INC BH
    INC BL
    CMP BL, 10 ; if(BL == per_line)
    JNE else_cnt
    MOV AH, 9 ; printf("%s", new_line)
    LEA DX, new_line
    INT 21H
    MOV BL, 0
    JMP fi_cnt
else_cnt:
    MOV AH, 2 ; printf("%c", ' ')
    MOV DL, ' '
    INT 21H
fi_cnt:
    JMP while_le_ed
while_done:
    MOV AH, 9 ; printf("%s", new_line)
    LEA DX, new_line
    INT 21H
    MOV AH, 4CH ; return
    INT 21H
main ENDP
    END main
