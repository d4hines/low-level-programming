section .data
message: db "hello world", 0
ten: dq 10

section .text
global _start

; Exit function
; Accepts an exit code and terminates the current process
; Exits with code specified in rdi
exit:
    xor rdi, rdi
    mov rax, 60
    syscall

; print_uint:
;     ; Save used registers
;     push rbx
;     push rcx
;     push rdx
;     push rsi

;     ; Prepare the stack to store ASCII digits
;     mov rcx, 10          ; Maximum number of decimal digits in a 32-bit unsigned integer
;     sub rsp, rcx         ; Allocate space on the stack for the ASCII digits
;     lea rbx, [rsp]       ; Set RBX to point to the top of the allocated space

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

; Function to reverse a string in place
; Argument: RDI -> pointer to the null-terminated string
reverse_string:
    ; example string: 'abc'
    ; Save the registers we'll modify
    push rsi
    push rcx
    push rdx

    ; Calculate the string length
    call string_length ; rax now contains the string length
    ; rax = 3

    ; Reverse the string
    dec rax ; adjust the length to account for 0-based index
    ; rax = 2
    mov rcx, rax ; rcx will store the end index
    xor rdx, rdx ; rdx will store the start index

    .reverse_loop:
        cmp rdx, rcx
        jge .done ; if start index >= end index, the reversal is done

        ; Swap characters at start and end index
        mov al, byte [rdi + rdx]
        mov bl, byte [rdi + rcx]
        mov byte [rdi + rdx], bl
        mov byte [rdi + rcx], al

        ; Update indices
        inc rdx
        dec rcx
        jmp .reverse_loop

    .done:
    ; Restore the registers and return
    pop rdx
    pop rcx
    pop rsi
    ret

print_uint:
    ; allocate 20 bytes on the stack - the maximum for a 64-bit uint
    ; let's pretend rsp = 1000
    sub rsp, 20 
    ; now rsp = 980
    mov rsi, rsp

    mov rax, rdi
    mov rcx, 0
    .loop:
        xor rdx, rdx
        div qword [ten] ; rax = quotiant, rdx = remainder
        add dl, '0' ; convert to ascii (dl is lower byte of rdx)
        mov byte [rsp+rcx], dl ; move remainder onto stack
        ; 980 = 9
        ; 981 = 1
        ; 982 =  2
        inc rcx
        test rax, rax
        jnz .loop
    mov byte [rsp+rcx], 0 ; add null char to terminate the string
    ; 983 = 4
    mov rdi, rsp 
    call reverse_string
    call print_string
    add rsp, 20 ; reset stack pointer
    ret

print_int:
    mov rax, rdi
    cqo
    xor rax, rdx       ; Complement RAX if negative, leave unchanged if positive or zero
    sub rax, rdx       ; Add 1 if RAX was negative, subtract 0 if positive or zero
    push rax

    test rdx, rdx      ; Check if RDX is non-zero (which means the original number was negative)
    jz .positive       ; If RDX is zero, the original number was positive, so jump to .positive

    ; If the original number was negative, print the '-' sign
    mov rdi, '-'
    call print_char

    .positive:
        pop rdi
        call print_uint
    ret

_start:
    ; WORKS!
    ; mov rdi, '99'
    ; call print_char
    ; call print_newline

    ; WORKS!
    ; mov rdi, message
    ; call print_string

    ; mov rdi, 98
    ; add rdi, '0'
    ; call print_char

    mov rdi, -1234     ; Move the signed integer -1234 into RAX
    call print_int
    
    call print_newline

    call exit
