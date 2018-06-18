#include <stdlib.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>
#include <sys/wait.h>
#include <sys/socket.h>
#include <resolv.h>
#include <arpa/inet.h>
#include <pthread.h>

#define PANIC(msg)  { perror(msg); exit(-1); }

void* echo_handler(void* client_fd)
{   char line[01000];
    int bytes_read;
    int client = *(int *)client_fd;

    bytes_read = recv(client, line, 1000, 0);
    send(client, line, bytes_read, 0);
    close(client);

    return client_fd;
}

int main(void)
{
    int sd;
    struct sockaddr_in addr;

    if ( (sd = socket(PF_INET, SOCK_STREAM, 0)) < 0 ) PANIC("Socket");

    addr.sin_family = AF_INET;
    addr.sin_port = htons(9999);
    addr.sin_addr.s_addr = INADDR_ANY;

    if ( bind(sd, (struct sockaddr*)&addr, sizeof(addr)) != 0 ) PANIC("Bind");
    if ( listen(sd, 20) != 0 ) PANIC("Listen");

    while (1)
    {
        int client, addr_size = sizeof(addr);
        pthread_t child;

        client = accept(sd, (struct sockaddr *) &addr, (socklen_t *) &addr_size);
        printf("Connected: %s:%d\n", inet_ntoa(addr.sin_addr), ntohs(addr.sin_port));
        if ( pthread_create(&child, NULL, echo_handler, &client) != 0 )
            perror("Thread creation");
        else
            pthread_detach(child);  /* disassociate from parent */
    }

    return 0;
}