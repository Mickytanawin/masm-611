option	M510
.model	small
.stack	100h
.data
CR	equ	0dh
LF	equ	0ah
ques	d	'?', CR, LF, '$'
newl	db	CR, LF, '$'
ans	db	"THE SUM OF A AND B IS X", CR, LF, '$'
.code
main	proc
	mov	ax, @data
	mov	ds, ax ; init DS
	mov	ah, 9
	lea	dx, ques
	int	21h ; printf("%s", ques)
	mov	ah, 1
	int	21h ; scanf("%c", &al)
	mov	ans + 11, al ; ans[11] = al
	mov	ans + 22, al ; ans[22] = al
	mov	ah, 1
	int	21h ; scanf("%c", &al)
	mov	ans + 17, al ; ans[17] = al
	add	ans + 22, al ; ans[22] += al
	sub	ans + 22, '0' ; ans[22] -= '0'
	mov	ah, 9
	lea	dx, ans
	int	21h ; printf("%s", ans)
	mov	ah, 4ch
	int	21h ; return
main	endp
	end	main