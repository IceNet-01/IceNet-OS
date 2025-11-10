/**
 * icecat - Concatenate and display files for IceNet-OS
 *
 * A simple cat implementation
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int cat_file(const char *filename, int show_line_numbers) {
    FILE *f;
    int c;
    int line_num = 1;
    int at_line_start = 1;

    if (strcmp(filename, "-") == 0) {
        f = stdin;
    } else {
        f = fopen(filename, "r");
        if (!f) {
            perror(filename);
            return 1;
        }
    }

    while ((c = fgetc(f)) != EOF) {
        if (show_line_numbers && at_line_start) {
            printf("%6d  ", line_num++);
            at_line_start = 0;
        }

        putchar(c);

        if (c == '\n') {
            at_line_start = 1;
        }
    }

    if (f != stdin) {
        fclose(f);
    }

    return 0;
}

int main(int argc, char *argv[]) {
    int show_line_numbers = 0;
    int ret = 0;

    if (argc < 2) {
        /* Read from stdin */
        return cat_file("-", 0);
    }

    /* Parse options and files */
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-n") == 0) {
            show_line_numbers = 1;
        } else if (strcmp(argv[i], "--help") == 0) {
            printf("Usage: %s [OPTION]... [FILE]...\n", argv[0]);
            printf("Concatenate FILE(s) to standard output.\n");
            printf("  -n    number all output lines\n");
            return 0;
        } else {
            ret |= cat_file(argv[i], show_line_numbers);
        }
    }

    return ret;
}
