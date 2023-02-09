mov cx, 0xA
do_nothing:
loop do_nothing
mov bx, [8582h]
add byte [bx + 1Ch], 0x2
mov word [8582h], 0cccch