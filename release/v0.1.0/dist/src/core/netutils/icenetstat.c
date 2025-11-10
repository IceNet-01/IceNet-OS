/**
 * icenetstat - Network statistics tool for IceNet-OS
 *
 * Display network connections, routing tables, and interface statistics
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* Display network connections */
static void show_connections(void) {
    FILE *f;
    char line[512];

    printf("Active Internet connections\n");
    printf("Proto Recv-Q Send-Q Local Address           Foreign Address         State\n");

    /* TCP connections */
    f = fopen("/proc/net/tcp", "r");
    if (f) {
        fgets(line, sizeof(line), f); /* Skip header */
        while (fgets(line, sizeof(line), f)) {
            unsigned long local_addr, local_port;
            unsigned long remote_addr, remote_port;
            int state;

            sscanf(line, "%*d: %lx:%lx %lx:%lx %x",
                   &local_addr, &local_port,
                   &remote_addr, &remote_port,
                   &state);

            const char *state_str[] = {
                "ESTABLISHED", "SYN_SENT", "SYN_RECV",
                "FIN_WAIT1", "FIN_WAIT2", "TIME_WAIT",
                "CLOSE", "CLOSE_WAIT", "LAST_ACK",
                "LISTEN", "CLOSING"
            };

            printf("tcp   0      0      %lu.%lu.%lu.%lu:%-5lu   ",
                   (local_addr) & 0xFF, (local_addr >> 8) & 0xFF,
                   (local_addr >> 16) & 0xFF, (local_addr >> 24) & 0xFF,
                   local_port);

            printf("%lu.%lu.%lu.%lu:%-5lu   ",
                   (remote_addr) & 0xFF, (remote_addr >> 8) & 0xFF,
                   (remote_addr >> 16) & 0xFF, (remote_addr >> 24) & 0xFF,
                   remote_port);

            if (state >= 1 && state <= 11)
                printf("%s\n", state_str[state - 1]);
            else
                printf("UNKNOWN\n");
        }
        fclose(f);
    }

    /* UDP connections */
    f = fopen("/proc/net/udp", "r");
    if (f) {
        fgets(line, sizeof(line), f); /* Skip header */
        while (fgets(line, sizeof(line), f)) {
            unsigned long local_addr, local_port;
            unsigned long remote_addr, remote_port;

            sscanf(line, "%*d: %lx:%lx %lx:%lx",
                   &local_addr, &local_port,
                   &remote_addr, &remote_port);

            printf("udp   0      0      %lu.%lu.%lu.%lu:%-5lu   ",
                   (local_addr) & 0xFF, (local_addr >> 8) & 0xFF,
                   (local_addr >> 16) & 0xFF, (local_addr >> 24) & 0xFF,
                   local_port);

            printf("%lu.%lu.%lu.%lu:%-5lu\n",
                   (remote_addr) & 0xFF, (remote_addr >> 8) & 0xFF,
                   (remote_addr >> 16) & 0xFF, (remote_addr >> 24) & 0xFF,
                   remote_port);
        }
        fclose(f);
    }
}

/* Display routing table */
static void show_route(void) {
    FILE *f;
    char line[512];

    printf("Kernel IP routing table\n");
    printf("Destination     Gateway         Genmask         Flags Metric Ref    Use Iface\n");

    f = fopen("/proc/net/route", "r");
    if (!f) {
        perror("Cannot read routing table");
        return;
    }

    fgets(line, sizeof(line), f); /* Skip header */

    while (fgets(line, sizeof(line), f)) {
        char iface[32];
        unsigned long dest, gateway, mask, flags, metric;

        sscanf(line, "%s %lx %lx %lx %*d %*d %ld %lx",
               iface, &dest, &gateway, &flags, &metric, &mask);

        printf("%-15lu.%lu.%lu.%lu ",
               (dest) & 0xFF, (dest >> 8) & 0xFF,
               (dest >> 16) & 0xFF, (dest >> 24) & 0xFF);

        printf("%-15lu.%lu.%lu.%lu ",
               (gateway) & 0xFF, (gateway >> 8) & 0xFF,
               (gateway >> 16) & 0xFF, (gateway >> 24) & 0xFF);

        printf("%-15lu.%lu.%lu.%lu ",
               (mask) & 0xFF, (mask >> 8) & 0xFF,
               (mask >> 16) & 0xFF, (mask >> 24) & 0xFF);

        printf("%-5s %-6ld 0      0 %s\n",
               (flags & 1) ? "U" : "-", metric, iface);
    }

    fclose(f);
}

/* Display interface statistics */
static void show_interfaces(void) {
    FILE *f;
    char line[512];

    printf("Kernel Interface table\n");
    printf("Iface   MTU RX-OK RX-ERR RX-DRP RX-OVR TX-OK TX-ERR TX-DRP TX-OVR Flg\n");

    f = fopen("/proc/net/dev", "r");
    if (!f) {
        perror("Cannot read network interfaces");
        return;
    }

    /* Skip first two lines */
    fgets(line, sizeof(line), f);
    fgets(line, sizeof(line), f);

    while (fgets(line, sizeof(line), f)) {
        char iface[32];
        unsigned long rx_bytes, rx_packets, rx_errs, rx_drop, rx_fifo;
        unsigned long tx_bytes, tx_packets, tx_errs, tx_drop, tx_fifo;

        char *colon = strchr(line, ':');
        if (!colon) continue;

        *colon = ' ';
        sscanf(line, "%s %lu %lu %lu %lu %*u %*u %*u %*u "
                     "%lu %lu %lu %lu %*u %lu",
               iface, &rx_bytes, &rx_packets, &rx_errs, &rx_drop,
               &tx_bytes, &tx_packets, &tx_errs, &tx_drop, &tx_fifo);

        printf("%-7s 1500 %-5lu %-6lu %-6lu %-6lu %-5lu %-6lu %-6lu %-6lu BMU\n",
               iface, rx_packets, rx_errs, rx_drop, rx_fifo,
               tx_packets, tx_errs, tx_drop, tx_fifo);
    }

    fclose(f);
}

int main(int argc, char *argv[]) {
    int show_all = 0;
    int show_route_table = 0;
    int show_iface = 0;

    /* Parse options */
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-a") == 0) {
            show_all = 1;
        } else if (strcmp(argv[i], "-r") == 0) {
            show_route_table = 1;
        } else if (strcmp(argv[i], "-i") == 0) {
            show_iface = 1;
        } else {
            fprintf(stderr, "Usage: %s [-a] [-r] [-i]\n", argv[0]);
            fprintf(stderr, "  -a  Show all connections\n");
            fprintf(stderr, "  -r  Show routing table\n");
            fprintf(stderr, "  -i  Show network interfaces\n");
            return 1;
        }
    }

    /* Default: show connections */
    if (!show_route_table && !show_iface) {
        show_all = 1;
    }

    if (show_all) {
        show_connections();
    }

    if (show_route_table) {
        printf("\n");
        show_route();
    }

    if (show_iface) {
        printf("\n");
        show_interfaces();
    }

    return 0;
}
