#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

int main(int argc, char *argv[])
{
    pid_t *pids;
    int count = 0;
    int success = 1;

    if (argc < 2) {
        return 0;
    }

    pids = calloc((size_t)(argc - 1), sizeof(pid_t));
    if (pids == NULL) {
        perror("calloc");
        return 1;
    }

    for (int i = 1; i < argc; i++) {
        pid_t pid = fork();

        if (pid < 0) {
            perror("fork");
            success = 0;
            continue;
        }

        if (pid == 0) {
            execl("/bin/bash", "bash", "-c", argv[i], NULL);
            perror("execl");
            _exit(127);
        }

        pids[count++] = pid;
    }

    for (int i = 0; i < count; i++) {
        int status = 0;

        if (waitpid(pids[i], &status, 0) < 0) {
            perror("waitpid");
            success = 0;
            continue;
        }

        if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) {
            success = 0;
        }
    }

    free(pids);
    return success ? 0 : 1;
}
