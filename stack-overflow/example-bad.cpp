//gcc -g -fno-stack-protector -z execstack fix.c -o fix

#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <stdlib.h>
#include <strings.h>
#include <string.h>
#include <sys/types.h>
#include <pwd.h>
#include <unistd.h>

void bufferCopy( char * input, int inputLen, FILE * file )
{
  char input_buffer[1000];
  int i = 0;
  int c = 0;
    while ( (c = fgetc( file )) != EOF && i < inputLen - 2 )
      {
        input[i++] = c;
      }
  strcpy(input_buffer, input);
  printf( "You entered: %s\n", input_buffer );

}

int main(int argc, char const *argv[])
{
    char input[1000];
    int sockfd, newsockfd, portno, clilen, val = 1;
    struct sockaddr_in serv_addr, cli_addr;

    if (argc < 2) {
        fprintf(stderr,"ERROR, no port provided\n");
        exit(1);
    }

    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) printf("ERROR opening socket");

    portno = atoi(argv[1]);
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = INADDR_ANY;
    serv_addr.sin_port = htons(portno);
     setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &val, sizeof(val));
    if (bind(sockfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) < 0)
        printf("ERROR on binding");

    listen(sockfd,5);


    clilen = sizeof(cli_addr);
    newsockfd = accept(sockfd, (struct sockaddr *) &cli_addr, (socklen_t *) &clilen);
    if (newsockfd < 0)
        printf("ERROR on accept");
    else
        printf("newsockfd is %d\n", newsockfd);

    dup2(newsockfd, 0); // bind stdin
    dup2(newsockfd, 1); // bind stdout
    dup2(newsockfd, 2); // bind stderr


    bufferCopy( input, 0x1000, stdin );

    close(newsockfd);
    close(sockfd);
    return 0;
}


