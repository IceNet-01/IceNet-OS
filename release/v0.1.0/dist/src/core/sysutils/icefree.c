/**
 * icefree - Memory information display for IceNet-OS
 *
 * Display system memory usage information
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/sysinfo.h>

static void display_memory(int human_readable) {
    struct sysinfo si;

    if (sysinfo(&si) != 0) {
        perror("sysinfo");
        return;
    }

    /* Parse meminfo for more detailed stats */
    FILE *f = fopen("/proc/meminfo", "r");
    unsigned long mem_available = 0;
    unsigned long buffers = 0;
    unsigned long cached = 0;
    unsigned long swap_cached = 0;

    if (f) {
        char line[256];
        while (fgets(line, sizeof(line), f)) {
            if (strncmp(line, "MemAvailable:", 13) == 0) {
                sscanf(line, "MemAvailable: %lu", &mem_available);
                mem_available *= 1024;
            } else if (strncmp(line, "Buffers:", 8) == 0) {
                sscanf(line, "Buffers: %lu", &buffers);
                buffers *= 1024;
            } else if (strncmp(line, "Cached:", 7) == 0) {
                sscanf(line, "Cached: %lu", &cached);
                cached *= 1024;
            } else if (strncmp(line, "SwapCached:", 11) == 0) {
                sscanf(line, "SwapCached: %lu", &swap_cached);
                swap_cached *= 1024;
            }
        }
        fclose(f);
    }

    if (mem_available == 0)
        mem_available = si.freeram + buffers + cached;

    unsigned long used_mem = si.totalram - si.freeram;

    if (human_readable) {
        /* Human readable format */
        printf("              total        used        free      shared  buff/cache   available\n");

        printf("Mem:      ");
        printf("%9.1fG ", si.totalram / 1024.0 / 1024.0 / 1024.0);
        printf("%9.1fG ", used_mem / 1024.0 / 1024.0 / 1024.0);
        printf("%9.1fG ", si.freeram / 1024.0 / 1024.0 / 1024.0);
        printf("%9.1fG ", si.sharedram / 1024.0 / 1024.0 / 1024.0);
        printf("%9.1fG ", (buffers + cached) / 1024.0 / 1024.0 / 1024.0);
        printf("%9.1fG\n", mem_available / 1024.0 / 1024.0 / 1024.0);

        if (si.totalswap > 0) {
            unsigned long used_swap = si.totalswap - si.freeswap;
            printf("Swap:     ");
            printf("%9.1fG ", si.totalswap / 1024.0 / 1024.0 / 1024.0);
            printf("%9.1fG ", used_swap / 1024.0 / 1024.0 / 1024.0);
            printf("%9.1fG\n", si.freeswap / 1024.0 / 1024.0 / 1024.0);
        }
    } else {
        /* Default format (MB) */
        printf("              total        used        free      shared  buff/cache   available\n");

        printf("Mem:      ");
        printf("%9lu ", si.totalram / 1024 / 1024);
        printf("%9lu ", used_mem / 1024 / 1024);
        printf("%9lu ", si.freeram / 1024 / 1024);
        printf("%9lu ", si.sharedram / 1024 / 1024);
        printf("%9lu ", (buffers + cached) / 1024 / 1024);
        printf("%9lu\n", mem_available / 1024 / 1024);

        if (si.totalswap > 0) {
            unsigned long used_swap = si.totalswap - si.freeswap;
            printf("Swap:     ");
            printf("%9lu ", si.totalswap / 1024 / 1024);
            printf("%9lu ", used_swap / 1024 / 1024);
            printf("%9lu\n", si.freeswap / 1024 / 1024);
        }
    }
}

int main(int argc, char *argv[]) {
    int human_readable = 0;

    /* Parse options */
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--human") == 0) {
            human_readable = 1;
        } else if (strcmp(argv[i], "--help") == 0) {
            printf("Usage: %s [-h|--human]\n", argv[0]);
            printf("Display amount of free and used memory in the system\n");
            printf("  -h, --human   Show human readable output\n");
            return 0;
        }
    }

    display_memory(human_readable);
    return 0;
}
