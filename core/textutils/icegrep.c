/**
 * icegrep - Search for patterns in files for IceNet-OS
 *
 * A simple grep implementation
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int grep_file(const char *filename, const char *pattern,
                    int show_filename, int show_line_numbers,
                    int invert_match, int ignore_case) {
    FILE *f;
    char line[4096];
    int line_num = 0;
    int found = 0;

    if (strcmp(filename, "-") == 0) {
        f = stdin;
    } else {
        f = fopen(filename, "r");
        if (!f) {
            perror(filename);
            return 0;
        }
    }

    /* Simple case-insensitive comparison if needed */
    char *pattern_lower = NULL;
    if (ignore_case) {
        pattern_lower = strdup(pattern);
        for (char *p = pattern_lower; *p; p++) {
            if (*p >= 'A' && *p <= 'Z') {
                *p = *p + ('a' - 'A');
            }
        }
    }

    while (fgets(line, sizeof(line), f)) {
        line_num++;

        /* Remove newline */
        char *nl = strchr(line, '\n');
        if (nl) *nl = '\0';

        /* Check for pattern match */
        int match;
        if (ignore_case) {
            char *line_lower = strdup(line);
            for (char *p = line_lower; *p; p++) {
                if (*p >= 'A' && *p <= 'Z') {
                    *p = *p + ('a' - 'A');
                }
            }
            match = (strstr(line_lower, pattern_lower) != NULL);
            free(line_lower);
        } else {
            match = (strstr(line, pattern) != NULL);
        }

        /* Invert match if requested */
        if (invert_match) {
            match = !match;
        }

        if (match) {
            if (show_filename) {
                printf("%s:", filename);
            }
            if (show_line_numbers) {
                printf("%d:", line_num);
            }
            printf("%s\n", line);
            found = 1;
        }
    }

    if (ignore_case && pattern_lower) {
        free(pattern_lower);
    }

    if (f != stdin) {
        fclose(f);
    }

    return found;
}

int main(int argc, char *argv[]) {
    const char *pattern = NULL;
    int show_line_numbers = 0;
    int invert_match = 0;
    int ignore_case = 0;
    int file_count = 0;
    char *files[256];

    /* Parse options */
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-n") == 0) {
            show_line_numbers = 1;
        } else if (strcmp(argv[i], "-v") == 0) {
            invert_match = 1;
        } else if (strcmp(argv[i], "-i") == 0) {
            ignore_case = 1;
        } else if (strcmp(argv[i], "--help") == 0) {
            printf("Usage: %s [OPTION]... PATTERN [FILE]...\n", argv[0]);
            printf("Search for PATTERN in each FILE.\n");
            printf("  -n    print line numbers\n");
            printf("  -v    invert match (select non-matching lines)\n");
            printf("  -i    ignore case\n");
            return 0;
        } else if (!pattern) {
            pattern = argv[i];
        } else if (file_count < 256) {
            files[file_count++] = argv[i];
        }
    }

    if (!pattern) {
        fprintf(stderr, "Usage: %s [OPTION]... PATTERN [FILE]...\n", argv[0]);
        return 1;
    }

    int show_filename = (file_count > 1);
    int found = 0;

    if (file_count == 0) {
        /* Read from stdin */
        found = grep_file("-", pattern, 0, show_line_numbers,
                         invert_match, ignore_case);
    } else {
        for (int i = 0; i < file_count; i++) {
            found |= grep_file(files[i], pattern, show_filename,
                             show_line_numbers, invert_match, ignore_case);
        }
    }

    return found ? 0 : 1;
}
