- 11. What does `xor rdi, rdi` do?
  - any string of bytes xor itself is zero'd out
  - https://stackoverflow.com/questions/1396527/what-is-the-purpose-of-xoring-a-register-with-itself
    - Apparently this is slightly faster
- 12. What is the program return code?
  - it's 0 according to my shell.
  - it's whatever is in `rdi`
    - e.g. if I replace with `mov rdi, 1` , exit code is 1
- 13. What is the first argument of the `exit` system call?
  - ditto

  pd