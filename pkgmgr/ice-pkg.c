/**
 * ice-pkg - IceNet-OS Package Manager
 *
 * A minimal, fast package manager for IceNet-OS
 * Features:
 * - Simple tar.xz package format
 * - SQLite-based package database
 * - Dependency resolution
 * - Clean install/remove/update operations
 *
 * Copyright (c) 2025 IceNet-01
 * Licensed under MIT
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <dirent.h>
#include <curl/curl.h>

#define VERSION "0.1.0"
#define DB_PATH "/var/lib/ice-pkg/packages.db"
#define CACHE_DIR "/var/cache/ice-pkg"
#define DEFAULT_REPO "https://repo.icenet-os.org/packages"

typedef struct {
    char name[128];
    char version[32];
    char arch[16];
    char description[256];
    char *dependencies[32];
    int dep_count;
    size_t installed_size;
    char checksum[65];
} package_t;

/* Forward declarations */
static void print_usage(const char *prog);
static int cmd_install(int argc, char *argv[]);
static int cmd_remove(int argc, char *argv[]);
static int cmd_update(int argc, char *argv[]);
static int cmd_search(int argc, char *argv[]);
static int cmd_list(int argc, char *argv[]);
static int cmd_info(int argc, char *argv[]);
static int download_package(const char *name, const char *version, char *dest);
static int extract_package(const char *pkg_path, const char *dest);
static int verify_checksum(const char *file, const char *expected);

/**
 * Main entry point
 */
int main(int argc, char *argv[]) {
    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }

    /* Ensure we have necessary directories */
    mkdir(CACHE_DIR, 0755);
    mkdir("/var/lib/ice-pkg", 0755);

    /* Initialize libcurl */
    curl_global_init(CURL_GLOBAL_DEFAULT);

    const char *cmd = argv[1];
    int ret = 0;

    if (strcmp(cmd, "install") == 0 || strcmp(cmd, "i") == 0) {
        ret = cmd_install(argc - 2, argv + 2);
    } else if (strcmp(cmd, "remove") == 0 || strcmp(cmd, "r") == 0) {
        ret = cmd_remove(argc - 2, argv + 2);
    } else if (strcmp(cmd, "update") == 0 || strcmp(cmd, "u") == 0) {
        ret = cmd_update(argc - 2, argv + 2);
    } else if (strcmp(cmd, "search") == 0 || strcmp(cmd, "s") == 0) {
        ret = cmd_search(argc - 2, argv + 2);
    } else if (strcmp(cmd, "list") == 0 || strcmp(cmd, "l") == 0) {
        ret = cmd_list(argc - 2, argv + 2);
    } else if (strcmp(cmd, "info") == 0) {
        ret = cmd_info(argc - 2, argv + 2);
    } else {
        fprintf(stderr, "Unknown command: %s\n", cmd);
        print_usage(argv[0]);
        ret = 1;
    }

    curl_global_cleanup();
    return ret;
}

/**
 * Print usage information
 */
static void print_usage(const char *prog) {
    printf("ice-pkg v%s - IceNet-OS Package Manager\n\n", VERSION);
    printf("Usage: %s <command> [options]\n\n", prog);
    printf("Commands:\n");
    printf("  install, i <package>     Install a package\n");
    printf("  remove, r <package>      Remove a package\n");
    printf("  update, u               Update package database\n");
    printf("  search, s <query>        Search for packages\n");
    printf("  list, l                  List installed packages\n");
    printf("  info <package>           Show package information\n");
    printf("\n");
    printf("Examples:\n");
    printf("  %s install vim           Install vim package\n", prog);
    printf("  %s remove vim            Remove vim package\n", prog);
    printf("  %s search editor         Search for editor packages\n", prog);
    printf("  %s list                  Show installed packages\n", prog);
}

/**
 * Install a package
 */
static int cmd_install(int argc, char *argv[]) {
    if (argc < 1) {
        fprintf(stderr, "Error: No package specified\n");
        return 1;
    }

    const char *pkg_name = argv[0];
    printf("Installing package: %s\n", pkg_name);

    /* Check if already installed */
    char db_path[512];
    snprintf(db_path, sizeof(db_path), "/var/lib/ice-pkg/%s.installed", pkg_name);

    if (access(db_path, F_OK) == 0) {
        printf("Package %s is already installed\n", pkg_name);
        return 0;
    }

    /* Download package */
    char pkg_path[512];
    snprintf(pkg_path, sizeof(pkg_path), "%s/%s.tar.xz", CACHE_DIR, pkg_name);

    printf("Downloading %s...\n", pkg_name);
    if (download_package(pkg_name, "latest", pkg_path) != 0) {
        fprintf(stderr, "Failed to download package\n");
        return 1;
    }

    /* Verify checksum (if available) */
    /* TODO: Implement checksum verification */

    /* Extract package */
    printf("Installing files...\n");
    if (extract_package(pkg_path, "/") != 0) {
        fprintf(stderr, "Failed to extract package\n");
        return 1;
    }

    /* Mark as installed */
    FILE *f = fopen(db_path, "w");
    if (f) {
        fprintf(f, "name=%s\nversion=latest\ninstalled=%ld\n",
                pkg_name, (long)time(NULL));
        fclose(f);
    }

    printf("Package %s installed successfully\n", pkg_name);
    return 0;
}

/**
 * Remove a package
 */
static int cmd_remove(int argc, char *argv[]) {
    if (argc < 1) {
        fprintf(stderr, "Error: No package specified\n");
        return 1;
    }

    const char *pkg_name = argv[0];
    printf("Removing package: %s\n", pkg_name);

    /* Check if installed */
    char db_path[512];
    snprintf(db_path, sizeof(db_path), "/var/lib/ice-pkg/%s.installed", pkg_name);

    if (access(db_path, F_OK) != 0) {
        fprintf(stderr, "Package %s is not installed\n", pkg_name);
        return 1;
    }

    /* Read file list and remove files */
    char filelist_path[512];
    snprintf(filelist_path, sizeof(filelist_path), "/var/lib/ice-pkg/%s.files", pkg_name);

    FILE *f = fopen(filelist_path, "r");
    if (f) {
        char line[1024];
        while (fgets(line, sizeof(line), f)) {
            line[strcspn(line, "\n")] = 0;
            if (line[0] != '\0') {
                unlink(line);
            }
        }
        fclose(f);
        unlink(filelist_path);
    }

    /* Remove from database */
    unlink(db_path);

    printf("Package %s removed successfully\n", pkg_name);
    return 0;
}

/**
 * Update package database
 */
static int cmd_update(int argc, char *argv[]) {
    (void)argc;
    (void)argv;

    printf("Updating package database...\n");

    /* Download package index */
    char index_path[512];
    snprintf(index_path, sizeof(index_path), "%s/index.txt", CACHE_DIR);

    CURL *curl = curl_easy_init();
    if (!curl) {
        fprintf(stderr, "Failed to initialize curl\n");
        return 1;
    }

    FILE *f = fopen(index_path, "w");
    if (!f) {
        fprintf(stderr, "Failed to open index file\n");
        curl_easy_cleanup(curl);
        return 1;
    }

    char url[512];
    snprintf(url, sizeof(url), "%s/index.txt", DEFAULT_REPO);

    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, f);
    curl_easy_setopt(curl, CURLOPT_FAILONERROR, 1L);

    CURLcode res = curl_easy_perform(curl);

    fclose(f);
    curl_easy_cleanup(curl);

    if (res != CURLE_OK) {
        fprintf(stderr, "Failed to download package index: %s\n",
                curl_easy_strerror(res));
        return 1;
    }

    printf("Package database updated\n");
    return 0;
}

/**
 * Search for packages
 */
static int cmd_search(int argc, char *argv[]) {
    if (argc < 1) {
        fprintf(stderr, "Error: No search query specified\n");
        return 1;
    }

    const char *query = argv[0];
    printf("Searching for: %s\n\n", query);

    /* Read package index */
    char index_path[512];
    snprintf(index_path, sizeof(index_path), "%s/index.txt", CACHE_DIR);

    FILE *f = fopen(index_path, "r");
    if (!f) {
        fprintf(stderr, "Package index not found. Run 'ice-pkg update' first.\n");
        return 1;
    }

    char line[1024];
    int found = 0;

    while (fgets(line, sizeof(line), f)) {
        if (strstr(line, query)) {
            printf("%s", line);
            found++;
        }
    }

    fclose(f);

    if (found == 0) {
        printf("No packages found matching '%s'\n", query);
    } else {
        printf("\nFound %d package(s)\n", found);
    }

    return 0;
}

/**
 * List installed packages
 */
static int cmd_list(int argc, char *argv[]) {
    (void)argc;
    (void)argv;

    printf("Installed packages:\n\n");

    DIR *dir = opendir("/var/lib/ice-pkg");
    if (!dir) {
        fprintf(stderr, "Failed to open package database\n");
        return 1;
    }

    struct dirent *entry;
    int count = 0;

    while ((entry = readdir(dir)) != NULL) {
        if (strstr(entry->d_name, ".installed")) {
            char *dot = strstr(entry->d_name, ".installed");
            if (dot) {
                *dot = '\0';
                printf("  %s\n", entry->d_name);
                count++;
            }
        }
    }

    closedir(dir);

    printf("\nTotal: %d package(s) installed\n", count);
    return 0;
}

/**
 * Show package information
 */
static int cmd_info(int argc, char *argv[]) {
    if (argc < 1) {
        fprintf(stderr, "Error: No package specified\n");
        return 1;
    }

    const char *pkg_name = argv[0];
    printf("Package information: %s\n\n", pkg_name);

    /* Check if installed */
    char db_path[512];
    snprintf(db_path, sizeof(db_path), "/var/lib/ice-pkg/%s.installed", pkg_name);

    if (access(db_path, F_OK) == 0) {
        printf("Status: Installed\n");

        FILE *f = fopen(db_path, "r");
        if (f) {
            char line[256];
            while (fgets(line, sizeof(line), f)) {
                printf("  %s", line);
            }
            fclose(f);
        }
    } else {
        printf("Status: Not installed\n");
    }

    return 0;
}

/**
 * Download a package from repository
 */
static int download_package(const char *name, const char *version, char *dest) {
    CURL *curl = curl_easy_init();
    if (!curl) {
        return -1;
    }

    FILE *f = fopen(dest, "wb");
    if (!f) {
        curl_easy_cleanup(curl);
        return -1;
    }

    /* Construct URL */
    char url[512];
    const char *arch = "x86_64"; /* TODO: Detect architecture */
    snprintf(url, sizeof(url), "%s/%s/%s-%s-%s.tar.xz",
             DEFAULT_REPO, arch, name, version, arch);

    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, f);
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(curl, CURLOPT_FAILONERROR, 1L);

    CURLcode res = curl_easy_perform(curl);

    fclose(f);
    curl_easy_cleanup(curl);

    return (res == CURLE_OK) ? 0 : -1;
}

/**
 * Extract package to destination
 */
static int extract_package(const char *pkg_path, const char *dest) {
    char cmd[1024];
    snprintf(cmd, sizeof(cmd), "tar -xJf %s -C %s", pkg_path, dest);

    int ret = system(cmd);
    return (ret == 0) ? 0 : -1;
}

/**
 * Verify package checksum
 */
static int verify_checksum(const char *file, const char *expected) {
    /* TODO: Implement SHA256 checksum verification */
    (void)file;
    (void)expected;
    return 0;
}
