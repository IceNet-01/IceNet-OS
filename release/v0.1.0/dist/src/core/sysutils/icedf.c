/**
 * icedf - Disk space usage display for IceNet-OS
 *
 * Display filesystem disk space usage
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/statvfs.h>
#include <mntent.h>

static void print_filesystem(const char *device, const char *mount,
                            const char *type, int human_readable) {
    struct statvfs vfs;

    if (statvfs(mount, &vfs) != 0) {
        return;
    }

    unsigned long long total = vfs.f_blocks * vfs.f_frsize;
    unsigned long long used = (vfs.f_blocks - vfs.f_bfree) * vfs.f_frsize;
    unsigned long long available = vfs.f_bavail * vfs.f_frsize;
    int use_pct = 0;

    if (total > 0) {
        use_pct = (int)((used * 100) / total);
    }

    if (human_readable) {
        /* Human readable */
        const char *units = "BKMGT";
        int unit_idx_total = 0, unit_idx_used = 0, unit_idx_avail = 0;
        double d_total = total, d_used = used, d_avail = available;

        while (d_total >= 1024 && unit_idx_total < 4) {
            d_total /= 1024;
            unit_idx_total++;
        }
        while (d_used >= 1024 && unit_idx_used < 4) {
            d_used /= 1024;
            unit_idx_used++;
        }
        while (d_avail >= 1024 && unit_idx_avail < 4) {
            d_avail /= 1024;
            unit_idx_avail++;
        }

        printf("%-20s %-10s %6.1f%c %6.1f%c %6.1f%c %3d%% %s\n",
               device, type,
               d_total, units[unit_idx_total],
               d_used, units[unit_idx_used],
               d_avail, units[unit_idx_avail],
               use_pct, mount);
    } else {
        /* 1K blocks */
        printf("%-20s %-10s %10llu %10llu %10llu %3d%% %s\n",
               device, type,
               total / 1024,
               used / 1024,
               available / 1024,
               use_pct, mount);
    }
}

static void display_filesystems(int human_readable) {
    FILE *f = setmntent("/proc/mounts", "r");
    struct mntent *ent;

    if (!f) {
        perror("Cannot read /proc/mounts");
        return;
    }

    if (human_readable) {
        printf("%-20s %-10s %7s %7s %7s Use%% Mounted on\n",
               "Filesystem", "Type", "Size", "Used", "Avail");
    } else {
        printf("%-20s %-10s %10s %10s %10s Use%% Mounted on\n",
               "Filesystem", "Type", "1K-blocks", "Used", "Available");
    }

    while ((ent = getmntent(f)) != NULL) {
        /* Skip some virtual filesystems */
        if (strcmp(ent->mnt_type, "proc") == 0 ||
            strcmp(ent->mnt_type, "sysfs") == 0 ||
            strcmp(ent->mnt_type, "devtmpfs") == 0 ||
            strcmp(ent->mnt_type, "devpts") == 0 ||
            strcmp(ent->mnt_type, "cgroup") == 0 ||
            strcmp(ent->mnt_type, "cgroup2") == 0 ||
            strncmp(ent->mnt_fsname, "/dev/loop", 9) == 0) {
            continue;
        }

        print_filesystem(ent->mnt_fsname, ent->mnt_dir,
                        ent->mnt_type, human_readable);
    }

    endmntent(f);
}

int main(int argc, char *argv[]) {
    int human_readable = 0;

    /* Parse options */
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--human-readable") == 0) {
            human_readable = 1;
        } else if (strcmp(argv[i], "--help") == 0) {
            printf("Usage: %s [-h|--human-readable]\n", argv[0]);
            printf("Show disk space usage for mounted filesystems\n");
            printf("  -h, --human-readable  Print sizes in human readable format\n");
            return 0;
        }
    }

    display_filesystems(human_readable);
    return 0;
}
