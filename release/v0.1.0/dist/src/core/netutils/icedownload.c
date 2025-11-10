/**
 * icedownload - Simple HTTP/HTTPS download utility for IceNet-OS
 *
 * A minimal wget/curl alternative
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>

/* Write callback for curl */
static size_t write_data(void *ptr, size_t size, size_t nmemb, FILE *stream) {
    return fwrite(ptr, size, nmemb, stream);
}

/* Progress callback */
static int progress_callback(void *clientp, curl_off_t dltotal, curl_off_t dlnow,
                             curl_off_t ultotal, curl_off_t ulnow) {
    (void)clientp;
    (void)ultotal;
    (void)ulnow;

    if (dltotal > 0) {
        double progress = (double)dlnow / (double)dltotal * 100.0;
        printf("\rDownloading: %.1f%% (%lld / %lld bytes)",
               progress, (long long)dlnow, (long long)dltotal);
        fflush(stdout);
    }

    return 0;
}

/* Download file */
static int download_file(const char *url, const char *output, int verbose) {
    CURL *curl;
    FILE *fp;
    CURLcode res;

    curl_global_init(CURL_GLOBAL_DEFAULT);
    curl = curl_easy_init();

    if (!curl) {
        fprintf(stderr, "Failed to initialize curl\n");
        return 1;
    }

    /* Open output file */
    fp = fopen(output, "wb");
    if (!fp) {
        fprintf(stderr, "Cannot open output file: %s\n", output);
        curl_easy_cleanup(curl);
        return 1;
    }

    /* Set curl options */
    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_data);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(curl, CURLOPT_FAILONERROR, 1L);

    if (verbose) {
        curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0L);
        curl_easy_setopt(curl, CURLOPT_XFERINFOFUNCTION, progress_callback);
    }

    /* Perform download */
    if (verbose)
        printf("Downloading %s...\n", url);

    res = curl_easy_perform(curl);

    if (verbose)
        printf("\n");

    if (res != CURLE_OK) {
        fprintf(stderr, "Download failed: %s\n", curl_easy_strerror(res));
        fclose(fp);
        unlink(output);
        curl_easy_cleanup(curl);
        return 1;
    }

    /* Get file size */
    curl_off_t size = 0;
    curl_easy_getinfo(curl, CURLINFO_SIZE_DOWNLOAD_T, &size);

    if (verbose)
        printf("Downloaded %lld bytes to %s\n", (long long)size, output);

    fclose(fp);
    curl_easy_cleanup(curl);
    curl_global_cleanup();

    return 0;
}

int main(int argc, char *argv[]) {
    const char *url = NULL;
    const char *output = NULL;
    int verbose = 1;

    /* Parse options */
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-q") == 0 || strcmp(argv[i], "--quiet") == 0) {
            verbose = 0;
        } else if (strcmp(argv[i], "-O") == 0 && i + 1 < argc) {
            output = argv[++i];
        } else if (argv[i][0] != '-') {
            url = argv[i];
        }
    }

    if (!url) {
        fprintf(stderr, "Usage: %s [options] <url>\n", argv[0]);
        fprintf(stderr, "Options:\n");
        fprintf(stderr, "  -O <file>   Output filename\n");
        fprintf(stderr, "  -q, --quiet Quiet mode\n");
        return 1;
    }

    /* Generate output filename if not specified */
    char default_output[256];
    if (!output) {
        const char *slash = strrchr(url, '/');
        if (slash && slash[1]) {
            output = slash + 1;
        } else {
            snprintf(default_output, sizeof(default_output), "index.html");
            output = default_output;
        }
    }

    return download_file(url, output, verbose);
}
