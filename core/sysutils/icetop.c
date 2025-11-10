/**
 * icetop - Process monitor for IceNet-OS
 *
 * A minimal top-like utility for monitoring system processes
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/types.h>
#include <sys/sysinfo.h>
#include <time.h>

#define MAX_PROCESSES 1024

typedef struct {
    int pid;
    char comm[256];
    char state;
    unsigned long utime;
    unsigned long stime;
    unsigned long vsize;
    long rss;
    float cpu_usage;
} process_info_t;

/* Read process information */
static int read_process_info(int pid, process_info_t *info) {
    char path[256];
    FILE *f;

    snprintf(path, sizeof(path), "/proc/%d/stat", pid);
    f = fopen(path, "r");
    if (!f)
        return -1;

    fscanf(f, "%d %s %c %*d %*d %*d %*d %*d %*u %*u %*u %*u %*u %lu %lu %*d %*d %*d %*d %*d %*d %*u %lu %ld",
           &info->pid, info->comm, &info->state,
           &info->utime, &info->stime, &info->vsize, &info->rss);

    fclose(f);

    /* Remove parentheses from comm */
    if (info->comm[0] == '(') {
        memmove(info->comm, info->comm + 1, strlen(info->comm));
        char *p = strchr(info->comm, ')');
        if (p) *p = '\0';
    }

    return 0;
}

/* Display system info */
static void display_header(void) {
    struct sysinfo si;
    FILE *f;
    char line[256];
    double load[3];

    sysinfo(&si);

    /* Get load average */
    f = fopen("/proc/loadavg", "r");
    if (f) {
        fscanf(f, "%lf %lf %lf", &load[0], &load[1], &load[2]);
        fclose(f);
    }

    /* Calculate uptime */
    int days = si.uptime / 86400;
    int hours = (si.uptime % 86400) / 3600;
    int minutes = (si.uptime % 3600) / 60;

    /* Clear screen */
    printf("\033[2J\033[H");

    printf("IceNet-OS System Monitor\n");
    printf("Uptime: %d days, %d:%02d\n", days, hours, minutes);
    printf("Load average: %.2f, %.2f, %.2f\n", load[0], load[1], load[2]);
    printf("Tasks: %d total\n", si.procs);
    printf("Memory: %lu MB total, %lu MB free, %lu MB used\n",
           si.totalram / 1024 / 1024,
           si.freeram / 1024 / 1024,
           (si.totalram - si.freeram) / 1024 / 1024);
    printf("\n");

    printf("  PID USER      %%CPU %%MEM    VSZ   RSS STAT COMMAND\n");
}

/* Compare processes by CPU usage */
static int compare_cpu(const void *a, const void *b) {
    const process_info_t *pa = a;
    const process_info_t *pb = b;
    return (pb->cpu_usage > pa->cpu_usage) ? 1 : -1;
}

/* Display top processes */
static void display_top(int iterations) {
    process_info_t processes[MAX_PROCESSES];
    int proc_count;

    for (int iter = 0; iter < iterations || iterations == 0; iter++) {
        DIR *dir = opendir("/proc");
        if (!dir) {
            perror("opendir /proc");
            return;
        }

        proc_count = 0;
        struct dirent *entry;

        while ((entry = readdir(dir)) != NULL && proc_count < MAX_PROCESSES) {
            if (entry->d_name[0] >= '0' && entry->d_name[0] <= '9') {
                int pid = atoi(entry->d_name);
                if (read_process_info(pid, &processes[proc_count]) == 0) {
                    proc_count++;
                }
            }
        }
        closedir(dir);

        /* Sort by CPU usage */
        qsort(processes, proc_count, sizeof(process_info_t), compare_cpu);

        /* Display */
        display_header();

        /* Show top 20 processes */
        int display_count = proc_count < 20 ? proc_count : 20;
        for (int i = 0; i < display_count; i++) {
            process_info_t *p = &processes[i];

            /* Get username */
            char username[32] = "root";
            char path[256];
            struct stat st;
            snprintf(path, sizeof(path), "/proc/%d", p->pid);
            if (stat(path, &st) == 0) {
                if (st.st_uid == 0)
                    strcpy(username, "root");
                else
                    snprintf(username, sizeof(username), "%d", st.st_uid);
            }

            /* Calculate memory percentage */
            struct sysinfo si;
            sysinfo(&si);
            float mem_pct = (float)(p->rss * 4096) / si.totalram * 100.0;

            printf("%5d %-8s %4.1f %4.1f %6lu %5ld %c    %s\n",
                   p->pid,
                   username,
                   p->cpu_usage,
                   mem_pct,
                   p->vsize / 1024,
                   p->rss * 4,
                   p->state,
                   p->comm);
        }

        if (iterations == 0 || iter < iterations - 1)
            sleep(2);
    }
}

int main(int argc, char *argv[]) {
    int iterations = 0; /* 0 = infinite */

    /* Parse options */
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-n") == 0 && i + 1 < argc) {
            iterations = atoi(argv[++i]);
        } else if (strcmp(argv[i], "-h") == 0) {
            printf("Usage: %s [-n iterations]\n", argv[0]);
            printf("  -n NUM  Number of iterations (default: infinite)\n");
            return 0;
        }
    }

    display_top(iterations);
    return 0;
}
