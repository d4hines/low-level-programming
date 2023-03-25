section .data
exit_success equ 0

section .text

sum:
    ; function prologue - set up a new stack frame
    push ebp
    mov ebp, esp

    ; add the two integers together
    add eax, [ebp+8]
    ; function epilogue - restore ebp and return
    mov esp, ebp
    pop ebp
    ret

; Exit function
; Accepts an exit code and terminates the current process
; Exits with code specified in rdi
exit:
    mov rax, 60
    syscall

; String length function
; Accepts a pointer to a string and returns its length
; Returns length of string in rax
string_length:
    mov rax, 0
    cmp byte [rdi], 0 ; check for empty string
    je .end
    .loop:
        inc rax
        cmp byte [rdi+rax], 0
        jne .loop
    .end:
        ret

; Print string function
; Accepts a pointer to a null-terminated string and prints it to stdout
; Prints string specified in rdi
print_string:
    mov rax, 1
    mov rdi, 1
    mov rdx, rsi
    call string_length
    mov rsi, rdx
    mov rax, 1
    syscall
    ret

; Print character function
; Accepts a character code directly as its first argument and prints it to stdout
; Prints character specified in dil
print_char:
    mov rax, 1
    mov rdi, 1
    movzx rsi, dil
    mov rdx, 1
    syscall
    ret

%macro print_newline 0
    push 0xA
    call print_char
    add rsp, 8
%endmacro

print_uint:
    push rax
    push rbx
    push rcx
    push rdx

    mov rbx, 10
    xor rcx, rcx

.loop:
    xor rdx, rdx
    div rbx
    push rdx
    inc rcx
    or rax, rax
    jne .loop

    mov rsi, rsp
    mov rdx, rcx

.print_loop:
    movzx eax, byte [rsp]
    add eax, 0x30
    mov [rsi], al
    inc rsi
    pop rax
    dec rdx
    jnz .print_loop

    mov rax, 4
    mov rbx, 1
    int 0x80

    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret


%macro print_int 1
    ; print a signed 8-byte integer in decimal format
    push rax            ; save register state
    push rdi
    push rsi
    push rdx
    push rcx
    push r8
    push r9

    mov rsi, rsp        ; set rsi to the top of the stack

    mov rax, %1         ; move the integer into rax
    cmp rax, 0          ; check if the integer is negative
    jge .positive       ; if it's not negative, jump to .positive

    neg rax             ; negate the integer
    mov byte [rsi], '-' ; print the negative sign
    inc rsi             ; increment the pointer to the next character
.positive:
    xor rcx, rcx        ; set rcx to zero
    cmp rax, 0          ; check if the integer is zero
    jne .divide         ; if it's not zero, jump to .divide

    mov byte [rsi], '0' ; otherwise, print a single zero
    inc rsi             ; increment the pointer to the next character
    jmp .print          ; jump to .print
.divide:
    cmp rax, 0          ; check if the integer is zero
    je .print           ; if it's zero, jump to .print

    mov r8, 10          ; set r8 to ten
    cqo                 ; convert rax to quadword
    idiv r8             ; divide rax by 10
    add dl, 48          ; convert the remainder to ASCII
    mov byte [rsi+rcx], dl ; store the remainder in the buffer
    inc rcx             ; increment the character count
    jmp .divide         ; jump back to .divide
.print:
    mov r9, rsi         ; set r9 to the top of the stack
    cmp byte [r9], '-'  ; check if the integer is negative
    je .end             ; if it is negative, jump to .end

    dec rsi             ; otherwise, decrement the pointer
.end:
    mov rax, 1          ; system call for write
    mov rdi, 1          ; file handle 1 is stdout
    sub rsi, r9         ; calculate the length of the string
    mov rdx, rsi        ; set rdx to the length of the string
    syscall             ; invoke operating system to do the write

    ; restore register state
    pop r9
    pop r8
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    pop rax
%endmacro


; Read one character from stdin and return it.
; If the end of input stream occurs, return 0.
read_char:
    mov rax, 0           ; set rax to 0 to signal end of input stream
    mov rdi, 0           ; set rdi to stdin file descriptor
    mov rsi, rsp         ; set rsi to point to a buffer on the stack
    mov rdx, 1           ; read 1 byte only
    syscall              ; invoke the read system call
    cmp rax, 0           ; check if end of input stream occurred
    jle .done            ; jump if so
    movzx rax, byte [rsp]; move the read byte into rax
.done:
    ret

; Accepts a buffer address and size as arguments.
; Reads next word from stdin (skipping whitespaces into buffer).
; Stops and returns 0 if word is too big for the buffer specified;
; otherwise returns a buffer address.
; This function should null-terminate the accepted string.
read_word:
    push rbp             ; save the base pointer
    mov rbp, rsp         ; set the base pointer to the current stack position
    mov rax, 0           ; set rax to 0 to signal word not found
    mov rdi, 0           ; set rdi to stdin file descriptor
    mov rsi, rsp         ; set rsi to point to a buffer on the stack
    mov rdx, rbp-rsi     ; set rdx to the buffer length
    xor rcx, rcx         ; set rcx to 0
    call skip_whitespace ; skip any leading whitespace
    cmp byte [rsp], 0    ; check for end of input stream
    je .done             ; jump if so
    mov rax, rsp         ; set rax to the buffer address
    mov rcx, rdx         ; save the buffer length
    xor rdx, rdx         ; set rdx to 0
    call read_char       ; read the first character of the word
    movzx rbx, al        ; move the read byte into rbx
.loop:
    cmp byte [rsp+rdx], ' ' ; check if the current character is a whitespace
    je .null_terminate  ; jump if so
    cmp byte [rsp+rdx], 0   ; check for end of input stream
    je .null_terminate     ; jump if so
    inc rdx                ; increment the buffer position
    cmp rdx, rcx           ; check if the buffer is full
    jge .done              ; jump if so
    call read_char         ; read the next character
    movzx rsi, al          ; move the read byte into rsi
    mov rdi, rbx           ; move the previous byte into rdi
    xor rbx, rbx           ; set rbx to 0
    lea rcx, [rax+rdi*2]   ; set rcx to rax + rdi * 2
    sub rcx, '0'*2         ; subtract the ASCII code for '0'
    cmp rdi, '-'           ; check for negative sign
    cmovl rcx, rbx         ; set rcx to 0 if negative sign detected
    imul rbx, 10           ; multiply rbx by 10
    add rbx, rcx           ; add the digit to rbx
    movzx rcx, rsi         ; move the read byte


parse_uint:
    xor rax, rax        ; initialize number to 0
    xor rdx, rdx        ; initialize characters count to 0
.loop:
    ; get the next character
    movzx ecx, byte [rdi+rdx]
    cmp ecx, 0          ; check if end of string
    je .end
    cmp ecx, '0'        ; check if character is a digit
    jb .end
    cmp ecx, '9'
    ja .end
    ; add digit to number
    imul rax, 10
    sub ecx, '0'
    add rax, rcx
    ; increment characters count and continue loop
    inc rdx
    jmp .loop
.end:
    ret


parse_int:
    xor rax, rax        ; clear rax
    xor rdx, rdx        ; clear rdx
    mov rcx, [rdi]      ; load first char from string
    cmp rcx, '-'        ; check if negative sign
    je .negative        ; jump to negative branch if true
    cmp rcx, '+'        ; check if positive sign
    je .positive        ; jump to positive branch if true
.parse_digits:
    cmp rcx, '0'        ; check if digit
    jl .end_parse       ; jump to end_parse branch if not
    cmp rcx, '9'        ; check if digit
    jg .end_parse       ; jump to end_parse branch if not
    mov r8, rax         ; save previous value of rax
    shl rax, 3          ; multiply rax by 8
    shl r8, 1           ; multiply previous value of rax by 2
    add rax, r8         ; add both results
    sub rcx, '0'        ; convert char to int
    add rax, rcx        ; add to rax
    inc rdx             ; increment rdx
    mov rcx, [rdi+rdx]  ; load next char from string
    jmp .parse_digits   ; jump back to parse_digits branch
.positive:
    inc rdx             ; increment rdx
    mov rcx, [rdi+rdx]  ; load next char from string
    jmp .parse_digits   ; jump back to parse_digits branch
.negative:
    inc rdx             ; increment rdx
    mov rcx, [rdi+rdx]  ; load next char from string
    jmp .parse_digits   ; jump back to parse_digits branch
.end_parse:
    test rax, rax       ; check if negative
    js .negative_end    ; jump to negative_end branch if true
.positive_end:
    ret                 ; return from function
.negative_end:
    neg rax             ; negate result
    ret                 ; return from function


string_equals:
    ; set up parameters
    mov rdi, [rsp + 8] ; first string
    mov rsi, [rsp + 16] ; second string

.loop:
    ; compare current characters
    cmp byte [rdi], [rsi]
    jne .not_equal

    ; check for end of strings
    cmp byte [rdi], 0
    je .equal

    ; move to next character
    inc rdi
    inc rsi
    jmp .loop

.equal:
    ; strings are equal
    mov rax, 1
    ret

.not_equal:
    ; strings are not equal
    xor rax, rax
    ret

