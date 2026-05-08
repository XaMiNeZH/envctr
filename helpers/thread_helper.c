#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <string.h>

typedef struct {
    char *cmd;
    int result;
    int started;
} thread_arg_t;

static void *run_command(void *data)
{
    thread_arg_t *arg = data;

    arg->result = system(arg->cmd);
    return NULL;
}

int main(int argc, char *argv[])
{
    pthread_t *threads;
    thread_arg_t *args;
    int success = 1;

    if (argc < 2) {
        return 0;
    }

    threads = calloc((size_t)(argc - 1), sizeof(pthread_t));
    args = calloc((size_t)(argc - 1), sizeof(thread_arg_t));
    if (threads == NULL || args == NULL) {
        perror("calloc");
        free(threads);
        free(args);
        return 1;
    }

    for (int i = 0; i < argc - 1; i++) {
        int rc;

        args[i].cmd = argv[i + 1];
        args[i].result = 1;
        args[i].started = 0;

        rc = pthread_create(&threads[i], NULL, run_command, &args[i]);
        if (rc != 0) {
            fprintf(stderr, "pthread_create: %s\n", strerror(rc));
            success = 0;
            continue;
        }

        args[i].started = 1;
    }

    for (int i = 0; i < argc - 1; i++) {
        int rc;

        if (!args[i].started) {
            continue;
        }

        rc = pthread_join(threads[i], NULL);
        if (rc != 0) {
            fprintf(stderr, "pthread_join: %s\n", strerror(rc));
            success = 0;
            continue;
        }

        if (args[i].result != 0) {
            success = 0;
        }
    }

    free(threads);
    free(args);
    return success ? 0 : 1;
}
