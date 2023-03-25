section .data
message: db "hello world", 0

section .text
global _start

; Exit function
; Accepts an exit code and terminates the current process
; Exits with code specified in rdi
exit:
    xor rdi, rdi
    mov rax, 60
    syscall

print_uint:
    ; Save used registers
    push rbx
    push rcx
    push rdx
    push rsi

    ; Prepare the stack to store ASCII digits
    mov rcx, 10          ; Maximum number of decimal digits in a 32-bit unsigned integer
    sub rsp, rcx         ; Allocate space on the stack for the ASCII digits
    lea rbx, [rsp]       ; Set RBX to point to the top of the allocated space

    ; Convert the number to its ASCII representation
; .convert_to_ascii:
;     xor rdx, rdx         ; Clear RDX
;     div qword [ten]      ; Divide RAX by 10, result in RAX, remainder in RDX
;     add dl, '0'          ; Convert the remainder to ASCII
;     dec rcx              ; Decrease the digit count
;     mov [rbx+rcx], dl    ; Store the ASCII digit on the stack

;     mov rdi, dl
;     call print_char
;     call print_newline

;     test rax, rax        ; Check if the quotient is zero
;     jnz .convert_to_ascii ; If not, continue conversion

;     ; Set RSI to the start of the converted digits
;     lea rsi, [rbx + rcx]

.print_number:
    ; Check if we have printed all digits
    lea rdx, [rbx + 10]
    cmp rsi, rdx
    je .done

    ; Call print_char for each digit
    movzx rdi, byte [rsi] ; Load the ASCII digit as zero-extended byte in RDI
    call print_char

    inc rsi           ; Move to the next digit in the buffer
    inc rcx
    jmp .print_number

.done:
    ; Restore used registers and return
    lea rsp, [rbx + 10] ; Restore the stack pointer
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

; prints char in rdi
print_char:
    push rdi
    mov rax, 1 ; write syscall
    mov rdi, 1 ; stdout

    mov   rsi, rsp ; the buffer is the stack pointer
    mov rdx, 1 ; bytes to write
    syscall

    pop rbx ; just any ol' register
    ret

print_newline:
    mov rdi, 0xA
    call print_char
    ret

string_length:
  mov rax, 0
  cmp byte [rdi], 0
  je .end
  .loop:
    inc rax
    cmp byte [rdi+rax], 0
    jne .loop
  .end:
    ret

print_string:
  push rbx
  mov rbx, rdi ; save a pointer to the string
  call string_length ; calls on string given as arg to this function
  mov rsi, rbx ; pointer to start of string
  mov rdx, rax ; length of string
  mov rax, 1
  mov rdi, 1
  syscall
  pop rbx
  ret

_start:
    ; WORKS!
    ; mov rdi, '99'
    ; call print_char
    ; call print_newline

    ; WORKS!
    ; mov rdi, message
    ; call print_string
    call print_newline

    call exit

section .data
    ten dq 10

