
section .text

; Exit function
; Accepts an exit code and terminates the current process
; Exits with code specified in rdi
exit:
    mov rax, 60
    syscall


print_string
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

print_char
  
  push rbx


