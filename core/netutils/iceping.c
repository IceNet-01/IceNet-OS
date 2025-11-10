/**
 * iceping - Simple ICMP ping utility for IceNet-OS
 *
 * A minimal ping implementation for network connectivity testing
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/ip_icmp.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <errno.h>
#include <sys/time.h>
#include <signal.h>

#define PACKET_SIZE 64
#define MAX_WAIT_TIME 1

static volatile int running = 1;
static int packets_sent = 0;
static int packets_received = 0;

/* Calculate checksum */
static unsigned short checksum(void *b, int len) {
    unsigned short *buf = b;
    unsigned int sum = 0;
    unsigned short result;

    for (sum = 0; len > 1; len -= 2)
        sum += *buf++;
    if (len == 1)
        sum += *(unsigned char *)buf;
    sum = (sum >> 16) + (sum & 0xFFFF);
    sum += (sum >> 16);
    result = ~sum;
    return result;
}

/* Signal handler */
static void sigint_handler(int sig) {
    (void)sig;
    running = 0;
}

/* Ping a host */
static int ping(const char *host, int count) {
    struct sockaddr_in addr;
    struct hostent *hname;
    struct icmp *icmp_hdr;
    char packet[PACKET_SIZE];
    int sockfd;
    int i;

    /* Resolve hostname */
    if ((hname = gethostbyname(host)) == NULL) {
        fprintf(stderr, "Unknown host: %s\n", host);
        return 1;
    }

    /* Create socket */
    if ((sockfd = socket(AF_INET, SOCK_RAW, IPPROTO_ICMP)) < 0) {
        perror("socket");
        fprintf(stderr, "Note: iceping requires root privileges\n");
        return 1;
    }

    /* Set timeout */
    struct timeval tv;
    tv.tv_sec = MAX_WAIT_TIME;
    tv.tv_usec = 0;
    setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

    /* Setup address */
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr = *(struct in_addr *)hname->h_addr;

    printf("PING %s (%s) %d bytes of data\n",
           host, inet_ntoa(addr.sin_addr), PACKET_SIZE);

    /* Send pings */
    for (i = 0; i < count && running; i++) {
        struct timeval start, end;
        double elapsed;

        /* Build ICMP packet */
        memset(packet, 0, sizeof(packet));
        icmp_hdr = (struct icmp *)packet;
        icmp_hdr->icmp_type = ICMP_ECHO;
        icmp_hdr->icmp_code = 0;
        icmp_hdr->icmp_id = getpid();
        icmp_hdr->icmp_seq = i;
        icmp_hdr->icmp_cksum = 0;
        icmp_hdr->icmp_cksum = checksum(packet, PACKET_SIZE);

        /* Send packet */
        gettimeofday(&start, NULL);
        if (sendto(sockfd, packet, PACKET_SIZE, 0,
                   (struct sockaddr *)&addr, sizeof(addr)) <= 0) {
            perror("sendto");
            continue;
        }
        packets_sent++;

        /* Receive reply */
        char recv_buf[1024];
        struct sockaddr_in recv_addr;
        socklen_t addr_len = sizeof(recv_addr);
        int n = recvfrom(sockfd, recv_buf, sizeof(recv_buf), 0,
                        (struct sockaddr *)&recv_addr, &addr_len);

        gettimeofday(&end, NULL);

        if (n > 0) {
            elapsed = (end.tv_sec - start.tv_sec) * 1000.0 +
                     (end.tv_usec - start.tv_usec) / 1000.0;
            packets_received++;

            struct ip *ip_hdr = (struct ip *)recv_buf;
            struct icmp *recv_icmp = (struct icmp *)(recv_buf + (ip_hdr->ip_hl << 2));

            printf("%d bytes from %s: icmp_seq=%d ttl=%d time=%.1f ms\n",
                   n - (ip_hdr->ip_hl << 2),
                   inet_ntoa(recv_addr.sin_addr),
                   recv_icmp->icmp_seq,
                   ip_hdr->ip_ttl,
                   elapsed);
        } else {
            printf("Request timeout for icmp_seq %d\n", i);
        }

        if (i < count - 1 && running)
            sleep(1);
    }

    close(sockfd);

    /* Print statistics */
    printf("\n--- %s ping statistics ---\n", host);
    printf("%d packets transmitted, %d received, %.0f%% packet loss\n",
           packets_sent, packets_received,
           ((packets_sent - packets_received) / (float)packets_sent) * 100.0);

    return 0;
}

int main(int argc, char *argv[]) {
    int count = 4;
    const char *host;

    if (argc < 2) {
        fprintf(stderr, "Usage: %s <host> [-c count]\n", argv[0]);
        return 1;
    }

    host = argv[1];

    /* Parse options */
    for (int i = 2; i < argc; i++) {
        if (strcmp(argv[i], "-c") == 0 && i + 1 < argc) {
            count = atoi(argv[++i]);
        }
    }

    signal(SIGINT, sigint_handler);

    return ping(host, count);
}
