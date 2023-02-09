push ds
pop es

mov word [1234h], 8081h
nop
nop
mov word [1234h], 8085h
nop
nop
mov word [1234h], 8283h
nop
nop
mov word [1234h], 8383h
nop
nop
mov word [1234h], 8680h
nop
nop
mov word [1234h], 8681h
nop
nop
mov word [1234h], 8684h
nop
nop
mov word [1234h], 8685h
nop
nop
mov word [1234h], 8782h
nop
nop
mov word [1234h], 8783h

nothing:
jmp nothing
