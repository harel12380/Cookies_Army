%define jmp_size 0x6300
%define gap 0x6000

; jmp end_of_code ; if you want to check what is the size of the code

; share the ax with the shared memory (the other player)
stosw
mov word [0], ax
;nop ; this is instead of the 'jmp start' opcode that will be in the final code
mov bx, ax

; only if attack zombies:
;write to the start of the code (bx) - the location of the trap code location (for the zombies)
;lea dx, [bx + trap] ; dx = bx + trap
;mov [bx], dx

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |copy the <copy> to the shared memory|
; move si to the location of the code to copy
lea si, [bx + copy]
xor di, di
; copy all the copy code to the shared memory
mov cl, (end_of_copy - copy) / 2 + 1
rep movsw ; copy all the copy code to the shared memory
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |switch segments|
push es
pop ds ; ds = shared memory
; es, ss = 0x1000
push cs
push cs
pop es
pop ss
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |set the first attack location + the sp location|
; set the first location for the call far to be at bx with value of (ax - <value>)
;TODO: check if can change this to one row 
mov byte al, 0xA2 ; set the low byte of al to A3 (A5 - 2) so when the loop overwrite itself it will be in the location of A5 (movsb opcode) 
mov bx, ax
; move the sp(stack pointer) to the location of the call far opcode + 200 (the amount of memory to attack before run away - can be changed) 
; NOTE: 0x400 = 1024 bytes which is the minimum distance between each players
lea sp, [bx - 0x400 + 0x8000 - 1 - 0x14A]
lea ax, [bx - 0x400]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |setup the location of the call far opcode inside the shared memory|
mov bx, 0xFC

; write the first location to the shared memory
mov [bx], ax
mov word [bx + 0x2], 0x0FFB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov si, (copy_second_part - copy)
mov ax, 0xDC29
les di, [bx]
movsw
movsw
sub di, 5
stosw
sub di, 4
stosw
add di, 3
dec byte [bx]
; for the movsw inside the copy

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; |setup last 'variables'|
mov ax, jmp_size ; ax = jmp size
mov dx, gap ; dx = attack size + jmp size
mov cl, (end_of_copy - copy) / 2
;lea cx, [bp + 1]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mov cl, 8
mov si, temp - copy
call far [bx]


copy: ; this part of the code will be copy to the shared memory (for re writing)
  movsw
  rep movsw
  sub word [bx], ax ; the size of the next attack
  ; add di, 0x100
  ; lea sp, [di + bx]
  sub sp, dx
  mov di, [bx]
  dec di
  mov cl, (end_of_copy - copy) / 2 - 0xC
  ; write the opcode <call far [bx]> to the next attack location
  mov si, copy_second_part - copy
movsw
  movsw

  xor si, si
  ; reset the cl & si for the next copy (cl for the movsw loop; si for the location in the memory of the copy's code)

  dec di
  dec di
  
  call far [bx]
  
  push ax
  push ax
  
  copy_second_part:
  push ax
  call far [bx]
  push ax

  temp:
  rep movsw
  add byte [bx], 2
  mov word [temp - copy], 0xff1f
  xor si, si
  mov cl, (copy_second_part - copy) / 2 - 1
  rep movsw
end_of_copy:
nop
; final registers:
; bp - the cx to put (the amount of movsw to do)
; bx - the location for the call far in shared memory - currently 0x2
; cx - the amount of times to do movsw
; dx - TODO: the amount of space between each attack
; ax - TODO: the amount of space between each call far
; si - the location of the opcodes in the shared memory (should be 0 at each start of attack)

; shared memory locations:
; 0 - sizeof(copy - end_of_copy) >> the opcodes for the instructions at the end of an attack
; 0x100 - 0x103  >> the next location in the war zone to attack (used with the register <BX>) for the first warrior
; 0x104 - 0x107  >> the next location in the war zone to attack (used with the register <BX>) for the second warrior
; 

trap: ; from here there is the code that the zombies will run

end_of_code: ; use to calculate the size of the code