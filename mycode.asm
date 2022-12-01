org 100h

; call
push ip

; call far

;movsw = A5
 
push ip ;XXXXh
push cs ;XXXXh

1000
XXA5; 16^4 - 16^2

1000
A5XX; 16^2

10A50 ; CS = 100A0 > ;10000 - 100A0 = !
;0x100 * 0x100 

05XXX

;100A5XXX
;10010
;0XX95



CS = 10010
IP = 0XX95

A5

XXA3

push ip
=
push XXA5

mov ah, 0
int 16h
ret

include magshimim.inc