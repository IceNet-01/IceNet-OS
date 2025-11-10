/**
 * icels - List directory contents for IceNet-OS
 *
 * A simple ls implementation
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <pwd.h>
#include <grp.h>
#include <time.h>
#include <unistd.h>

/* Format permissions string */
static void format_perms(mode_t mode, char *buf) {
    buf[0] = S_ISDIR(mode) ? 'd' : S_ISLNK(mode) ? 'l' : '-';
    buf[1] = (mode & S_IRUSR) ? 'r' : '-';
    buf[2] = (mode & S_IWUSR) ? 'w' : '-';
    buf[3] = (mode & S_IXUSR) ? 'x' : '-';
    buf[4] = (mode & S_IRGRP) ? 'r' : '-';
    buf[5] = (mode & S_IWGRP) ? 'w' : '-';
    buf[6] = (mode & S_IXGRP) ? 'x' : '-';
    buf[7] = (mode & S_IROTH) ? 'r' : '-';
    buf[8] = (mode & S_IWOTH) ? 'w' : '-';
    buf[9] = (mode & S_IXOTH) ? 'x' : '-';
    buf[10] = '\0';
}

/* Format file size */
static void format_size(off_t size, char *buf, int human) {
    if (human) {
        const char *units = " KMGT";
        int unit = 0;
        double dsize = size;

        while (dsize >= 1024 && unit < 4) {
            dsize /= 1024;
            unit++;
        }

        if (unit == 0)
            snprintf(buf, 16, "%lld", (long long)size);
        else
            snprintf(buf, 16, "%.1f%c", dsize, units[unit]);
    } else {
        snprintf(buf, 16, "%lld", (long long)size);
    }
}

/* List files in long format */
static void list_long(const char *path, int show_all, int human) {
    DIR *dir;
    struct dirent *entry;
    struct stat st;
    char fullpath[1024];

    dir = opendir(path);
    if (!dir) {
        perror(path);
        return;
    }

    while ((entry = readdir(dir)) != NULL) {
        if (!show_all && entry->d_name[0] == '.')
            continue;

        snprintf(fullpath, sizeof(fullpath), "%s/%s", path, entry->d_name);

        if (lstat(fullpath, &st) < 0) {
            perror(fullpath);
            continue;
        }

        /* Permissions */
        char perms[12];
        format_perms(st.st_mode, perms);
        printf("%s ", perms);

        /* Links */
        printf("%3ld ", (long)st.st_nlink);

        /* Owner */
        struct passwd *pw = getpwuid(st.st_uid);
        if (pw)
            printf("%-8s ", pw->pw_name);
        else
            printf("%-8d ", st.st_uid);

        /* Group */
        struct group *gr = getgrgid(st.st_gid);
        if (gr)
            printf("%-8s ", gr->gr_name);
        else
            printf("%-8d ", st.st_gid);

        /* Size */
        char size_buf[16];
        format_size(st.st_size, size_buf, human);
        printf("%8s ", size_buf);

        /* Modification time */
        char time_buf[32];
        struct tm *tm = localtime(&st.st_mtime);
        strftime(time_buf, sizeof(time_buf), "%b %d %H:%M", tm);
        printf("%s ", time_buf);

        /* Filename */
        printf("%s", entry->d_name);

        /* Link target if symlink */
        if (S_ISLNK(st.st_mode)) {
            char link[1024];
            ssize_t len = readlink(fullpath, link, sizeof(link) - 1);
            if (len > 0) {
                link[len] = '\0';
                printf(" -> %s", link);
            }
        }

        printf("\n");
    }

    closedir(dir);
}

/* List files in simple format */
static void list_simple(const char *path, int show_all) {
    DIR *dir;
    struct dirent *entry;

    dir = opendir(path);
    if (!dir) {
        perror(path);
        return;
    }

    while ((entry = readdir(dir)) != NULL) {
        if (!show_all && entry->d_name[0] == '.')
            continue;

        printf("%s\n", entry->d_name);
    }

    closedir(dir);
}

int main(int argc, char *argv[]) {
    int long_format = 0;
    int show_all = 0;
    int human = 0;
    const char *path = ".";

    /* Parse options */
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-l") == 0) {
            long_format = 1;
        } else if (strcmp(argv[i], "-a") == 0) {
            show_all = 1;
        } else if (strcmp(argv[i], "-h") == 0) {
            human = 1;
        } else if (strcmp(argv[i], "-la") == 0 || strcmp(argv[i], "-al") == 0) {
            long_format = 1;
            show_all = 1;
        } else if (argv[i][0] != '-') {
            path = argv[i];
        }
    }

    if (long_format) {
        list_long(path, show_all, human);
    } else {
        list_simple(path, show_all);
    }

    return 0;
}
