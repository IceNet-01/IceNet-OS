/**
 * IceNet-OS Init System
 *
 * A minimal, fast init system designed for IceNet-OS.
 * Features:
 * - Fast parallel service startup
 * - Simple service dependency management
 * - Process supervision and restart
 * - Clean shutdown handling
 *
 * Copyright (c) 2025 IceNet-01
 * Licensed under MIT
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/mount.h>
#include <sys/reboot.h>
#include <signal.h>
#include <fcntl.h>
#include <errno.h>
#include <dirent.h>

#define VERSION "0.1.0"
#define SERVICE_DIR "/etc/icenet/services"
#define MAX_SERVICES 128
#define MAX_DEPS 16

typedef enum {
    SERVICE_STOPPED,
    SERVICE_STARTING,
    SERVICE_RUNNING,
    SERVICE_FAILED
} service_state_t;

typedef struct {
    char name[64];
    char exec[256];
    char *args[32];
    char deps[MAX_DEPS][64];
    int dep_count;
    pid_t pid;
    service_state_t state;
    int respawn;
    int respawn_count;
} service_t;

static service_t services[MAX_SERVICES];
static int service_count = 0;
static volatile sig_atomic_t shutdown_requested = 0;

/* Forward declarations */
static void setup_signals(void);
static void mount_filesystems(void);
static void load_services(void);
static void start_service(service_t *svc);
static void stop_all_services(void);
static void signal_handler(int sig);
static int check_dependencies(service_t *svc);

/**
 * Main init process
 */
int main(int argc, char *argv[]) {
    printf("IceNet-Init v%s starting...\n", VERSION);

    /* We must be PID 1 */
    if (getpid() != 1) {
        fprintf(stderr, "Error: init must be run as PID 1\n");
        return 1;
    }

    /* Setup signal handlers */
    setup_signals();

    /* Mount essential filesystems */
    mount_filesystems();

    /* Load service definitions */
    load_services();

    /* Start services in order */
    printf("Starting services...\n");
    int started = 0;
    do {
        started = 0;
        for (int i = 0; i < service_count; i++) {
            if (services[i].state == SERVICE_STOPPED) {
                if (check_dependencies(&services[i])) {
                    start_service(&services[i]);
                    started++;
                }
            }
        }
    } while (started > 0);

    /* Main loop - monitor services */
    printf("IceNet-Init: System initialization complete\n");

    while (!shutdown_requested) {
        int status;
        pid_t pid = waitpid(-1, &status, WNOHANG);

        if (pid > 0) {
            /* A process exited, check if it was a service */
            for (int i = 0; i < service_count; i++) {
                if (services[i].pid == pid) {
                    printf("Service %s (PID %d) exited with status %d\n",
                           services[i].name, pid, WEXITSTATUS(status));

                    services[i].state = SERVICE_STOPPED;
                    services[i].pid = 0;

                    /* Respawn if configured */
                    if (services[i].respawn && services[i].respawn_count < 5) {
                        printf("Respawning service %s...\n", services[i].name);
                        services[i].respawn_count++;
                        sleep(1);
                        start_service(&services[i]);
                    } else if (services[i].respawn_count >= 5) {
                        printf("Service %s failed too many times, not respawning\n",
                               services[i].name);
                        services[i].state = SERVICE_FAILED;
                    }
                    break;
                }
            }
        }

        sleep(1);
    }

    /* Shutdown sequence */
    printf("\nIceNet-Init: Shutting down...\n");
    stop_all_services();

    /* Unmount filesystems */
    sync();
    umount("/proc");
    umount("/sys");
    umount("/dev");

    /* Reboot or halt */
    reboot(RB_POWER_OFF);

    return 0;
}

/**
 * Setup signal handlers
 */
static void setup_signals(void) {
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = signal_handler;
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGCHLD, &sa, NULL);
}

/**
 * Signal handler
 */
static void signal_handler(int sig) {
    switch (sig) {
        case SIGTERM:
        case SIGINT:
            shutdown_requested = 1;
            break;
        case SIGCHLD:
            /* Handled in main loop */
            break;
    }
}

/**
 * Mount essential filesystems
 */
static void mount_filesystems(void) {
    printf("Mounting filesystems...\n");

    /* Create mount points if they don't exist */
    mkdir("/proc", 0755);
    mkdir("/sys", 0755);
    mkdir("/dev", 0755);
    mkdir("/run", 0755);
    mkdir("/tmp", 0755);

    /* Mount virtual filesystems */
    if (mount("proc", "/proc", "proc", MS_NOSUID | MS_NOEXEC | MS_NODEV, NULL) < 0) {
        perror("Failed to mount /proc");
    }

    if (mount("sysfs", "/sys", "sysfs", MS_NOSUID | MS_NOEXEC | MS_NODEV, NULL) < 0) {
        perror("Failed to mount /sys");
    }

    if (mount("devtmpfs", "/dev", "devtmpfs", MS_NOSUID, "mode=0755") < 0) {
        perror("Failed to mount /dev");
    }

    if (mount("tmpfs", "/run", "tmpfs", MS_NOSUID | MS_NODEV, "mode=0755") < 0) {
        perror("Failed to mount /run");
    }

    if (mount("tmpfs", "/tmp", "tmpfs", MS_NOSUID | MS_NODEV, "mode=1777") < 0) {
        perror("Failed to mount /tmp");
    }

    printf("Filesystems mounted\n");
}

/**
 * Load service definitions from /etc/icenet/services
 */
static void load_services(void) {
    printf("Loading services from %s...\n", SERVICE_DIR);

    DIR *dir = opendir(SERVICE_DIR);
    if (!dir) {
        fprintf(stderr, "Warning: Could not open service directory: %s\n", SERVICE_DIR);
        return;
    }

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL && service_count < MAX_SERVICES) {
        if (entry->d_name[0] == '.')
            continue;

        char path[512];
        snprintf(path, sizeof(path), "%s/%s", SERVICE_DIR, entry->d_name);

        FILE *f = fopen(path, "r");
        if (!f)
            continue;

        service_t *svc = &services[service_count];
        memset(svc, 0, sizeof(service_t));
        strncpy(svc->name, entry->d_name, sizeof(svc->name) - 1);
        svc->state = SERVICE_STOPPED;

        char line[512];
        while (fgets(line, sizeof(line), f)) {
            /* Remove newline */
            line[strcspn(line, "\n")] = 0;

            /* Skip comments and empty lines */
            if (line[0] == '#' || line[0] == '\0')
                continue;

            /* Parse key=value */
            char *eq = strchr(line, '=');
            if (!eq)
                continue;

            *eq = '\0';
            char *key = line;
            char *value = eq + 1;

            if (strcmp(key, "exec") == 0) {
                strncpy(svc->exec, value, sizeof(svc->exec) - 1);
            } else if (strcmp(key, "depends") == 0) {
                strncpy(svc->deps[svc->dep_count], value,
                        sizeof(svc->deps[0]) - 1);
                svc->dep_count++;
            } else if (strcmp(key, "respawn") == 0) {
                svc->respawn = (strcmp(value, "yes") == 0);
            }
        }

        fclose(f);

        if (svc->exec[0] != '\0') {
            printf("  Loaded service: %s\n", svc->name);
            service_count++;
        }
    }

    closedir(dir);
    printf("Loaded %d services\n", service_count);
}

/**
 * Check if all dependencies for a service are running
 */
static int check_dependencies(service_t *svc) {
    for (int i = 0; i < svc->dep_count; i++) {
        int found = 0;
        for (int j = 0; j < service_count; j++) {
            if (strcmp(services[j].name, svc->deps[i]) == 0) {
                if (services[j].state != SERVICE_RUNNING) {
                    return 0;
                }
                found = 1;
                break;
            }
        }
        if (!found) {
            fprintf(stderr, "Warning: Dependency %s not found for service %s\n",
                    svc->deps[i], svc->name);
        }
    }
    return 1;
}

/**
 * Start a service
 */
static void start_service(service_t *svc) {
    printf("Starting service: %s\n", svc->name);

    svc->state = SERVICE_STARTING;

    pid_t pid = fork();
    if (pid < 0) {
        perror("fork");
        svc->state = SERVICE_FAILED;
        return;
    }

    if (pid == 0) {
        /* Child process - exec the service */
        /* Parse exec string into args */
        char *exec_copy = strdup(svc->exec);
        int arg_count = 0;
        char *token = strtok(exec_copy, " ");
        while (token && arg_count < 31) {
            svc->args[arg_count++] = token;
            token = strtok(NULL, " ");
        }
        svc->args[arg_count] = NULL;

        /* Execute */
        execvp(svc->args[0], svc->args);

        /* If we get here, exec failed */
        perror("execvp");
        exit(1);
    }

    /* Parent process */
    svc->pid = pid;
    svc->state = SERVICE_RUNNING;
}

/**
 * Stop all running services
 */
static void stop_all_services(void) {
    printf("Stopping all services...\n");

    /* Send SIGTERM to all services */
    for (int i = 0; i < service_count; i++) {
        if (services[i].state == SERVICE_RUNNING && services[i].pid > 0) {
            printf("  Stopping %s (PID %d)\n", services[i].name, services[i].pid);
            kill(services[i].pid, SIGTERM);
        }
    }

    /* Wait a bit for graceful shutdown */
    sleep(2);

    /* Send SIGKILL to any remaining processes */
    for (int i = 0; i < service_count; i++) {
        if (services[i].state == SERVICE_RUNNING && services[i].pid > 0) {
            printf("  Force killing %s (PID %d)\n", services[i].name, services[i].pid);
            kill(services[i].pid, SIGKILL);
        }
    }

    /* Wait for all children */
    while (waitpid(-1, NULL, WNOHANG) > 0);
}
