# envctr Usage Guide

envctr follows standard Linux command-line syntax:

```bash
envctr [OPTIONS] -p <project_directory>
```

---

## Quick Start

Provision a project using Docker:

```bash
envctr -b docker -p ./myproject
```

Provision using the saved lockfile:

```bash
envctr --from-lock -b docker -p ./myproject
```

Run drift detection:

```bash
envctr --drift -p ./myproject
```

Run drift detection with Mistral explanation:

```bash
envctr --drift -e -p ./myproject
```

Display help:

```bash
envctr -h
```

---

## Mandatory Parameter

`-p <directory>` is always required. Absence triggers error 101 and displays
the full help automatically.

```bash
$ envctr -b docker
[ERROR 101] Mandatory parameter missing: -p <project_directory>

USAGE: envctr [options] -p <project_directory>
...
```

---

## Required Options

### -h — Help

Display full program documentation in the terminal.

```bash
envctr -h
```

### -s — Subshell mode

Run the full provisioning pipeline inside an isolated Bash subshell. If the
pipeline fails, the parent process is not affected. Suitable for light
workloads with a single service.

```bash
envctr -s -b chroot -p ./examples/flask-simple
```

The pipeline runs inside `( ... )`. If provisioning fails inside the subshell,
the parent shell continues and logs the failure.

### -f — Fork mode

Provision each detected service in an independent child process using `fork()`.
If one service fails, the others continue. The parent waits for all children
and reports aggregate results. Suitable for medium workloads with 3-5 services.

```bash
envctr -f -b docker -p ./examples/node-api
```

Internally calls `helpers/fork_helper` which uses `fork()` and `waitpid()` in C.

### -t — Thread mode

Provision all detected services simultaneously using pthreads. Lower memory
overhead than fork, higher concurrency. Suitable for heavy workloads with 6+
services or monorepos.

```bash
envctr -t -b docker -p ./examples/microservices-monorepo
```

Internally calls `helpers/thread_helper` compiled with `-lpthread`.

### -l — Custom log directory

Override the default log directory `/var/log/envctr`.

```bash
envctr -l /tmp/envctr-logs -b docker -p ./myproject
```

The log file is always named `history.log` inside the specified directory.

### -r — Reset and restore (root only)

Reset `envctr.conf` to factory defaults and destroy the provisioned environment
for the specified project. Requires root privileges.

```bash
sudo envctr -r -p ./myproject
```

Triggers error 111 if run without root:

```bash
$ envctr -r -p ./myproject
[ERROR 111] Reset requires root privileges. Run with sudo.
```

---

## Additional Options

### -b — Backend selection

Choose the isolation backend. Required for provisioning.

```bash
envctr -b docker -p ./myproject    # Docker containers
envctr -b qemu   -p ./myproject    # QEMU/KVM virtual machine
envctr -b chroot -p ./myproject    # chroot jail
```

### -e — Explain drift with Mistral

Combine with `--drift` to get a plain-language explanation of what broke and
why, via Mistral API. Requires `MISTRAL_API_KEY` in `envctr.conf`. Degrades
gracefully to raw report if API is unreachable (error 110).

```bash
envctr --drift -e -p ./myproject
```

### --from-lock

Skip fingerprinting and provision directly from an existing `envctr.lock` file.

```bash
envctr --from-lock -b docker -p ./myproject
```

### --drift

Compare the live environment against the lockfile. Classifies differences as
BREAKING, WARNING, or INFO.

```bash
envctr --drift -p ./myproject
```

### --restore

Re-provision from the lockfile after drift is detected.

```bash
envctr --restore -b docker -p ./myproject
```

### --update-lock

Update the lockfile to reflect the current live environment state.

```bash
envctr --update-lock -p ./myproject
```

### --dry-run

Show what would be provisioned without executing anything. Safe for testing.

```bash
envctr --dry-run -b docker -p ./myproject
```

### --export

Export the lockfile for sharing with teammates.

```bash
envctr --export -p ./myproject
```

### --no-provision

Skip provisioning entirely. Use only drift detection and backend abstraction.
For teams that already have Docker set up.

```bash
envctr --no-provision --drift -p ./myproject
```

---

## Backends in Detail

### Docker

Default for most projects. envctr builds or pulls the appropriate base image,
configures port bindings, mounts the project as a volume, and passes required
environment variables.

```
Host machine
    └── Docker container
            ├── Runtime (Node 18, Python 3.11, etc.)
            ├── Services (PostgreSQL, Redis)
            ├── Port bindings (3000:3000, 5432:5432)
            └── Volume mount (./project --> /app)
```

Requires `docker` to be installed and running.

### QEMU/KVM

For kernel-level isolation. Boots a full Linux VM via KVM, provisions it over
SSH, and mounts the project directory. Requires `/dev/kvm` to be accessible.

```
Host machine
    └── QEMU/KVM virtual machine (SSH on localhost:2222)
            ├── Own kernel — fully isolated from host
            ├── Project directory mounted via virtfs
            └── Port forwarding configured automatically
```

Requires `qemu-system-x86_64` and `/dev/kvm`.

### chroot

Lightest option. Creates an isolated filesystem using `debootstrap`, installs
the runtime inside, and binds the project directory. No external daemon needed.

```
Host machine
    └── chroot jail (/var/envctr/jails/projectname)
            ├── Isolated filesystem
            ├── Runtime installed inside jail
            └── Project directory bind-mounted
```

Requires `debootstrap` and root for mount operations.

---

## Logging

All output is written simultaneously to the terminal and to
`/var/log/envctr/history.log` via `tee`.

Format:

```
yyyy-mm-dd-hh-mm-ss : username : INFOS : message
yyyy-mm-dd-hh-mm-ss : username : ERROR : message
```

Example:

```
2026-05-03-14-32-00 : ahmed : INFOS : envctr started -- project: myapi -- backend: docker
2026-05-03-14-32-01 : ahmed : INFOS : Fingerprinting complete -- detected: node 18, postgresql, redis
2026-05-03-14-32-08 : ahmed : INFOS : PostgreSQL 15.3 container started on port 5432
2026-05-03-14-32-11 : ahmed : INFOS : Lockfile written to ./envctr.lock
2026-05-03-14-32-11 : ahmed : INFOS : Environment ready
2026-05-03-14-35-00 : ahmed : ERROR : Code 109 -- drift detected in runtime.version
```

---

## Error Reference

| Code | Meaning | Triggered by |
|---|---|---|
| 100 | Unknown option | Unrecognized flag passed |
| 101 | Mandatory parameter missing | `-p` not provided |
| 102 | Project directory not found | Path does not exist |
| 103 | Permission denied | Operation needs root |
| 104 | Backend not available | `docker`/`qemu` not installed |
| 105 | Fingerprinting failed | No recognizable stack found |
| 106 | Lockfile not found or corrupted | `--from-lock` with missing/invalid lockfile |
| 107 | Provisioning failed | Backend returned non-zero |
| 108 | KVM not available | `/dev/kvm` missing or inaccessible |
| 109 | Drift detected | `--drift` found mismatches |
| 110 | Mistral API unreachable | No connection or invalid key |
| 111 | Root required | `-r` without sudo |
| 112 | Backend binary not found | `docker` command missing |

Every error automatically displays the full `-h` help after the error message.

---

## Configuration File

Default location: `/etc/envctr/envctr.conf`

```bash
LOG_DIR="/var/log/envctr"
DEFAULT_BACKEND="docker"
DOCKER_NETWORK="envctr-net"
QEMU_SSH_PORT="2222"
CHROOT_BASE_DIR="/var/envctr/jails"
MISTRAL_API_KEY=""
MISTRAL_MODEL="mistral-small-latest"
MISTRAL_API_URL="https://api.mistral.ai/v1/chat/completions"
```

Set `MISTRAL_API_KEY` to enable drift explanation. Leave empty to disable.

---

## Compilation of C Helpers

```bash
gcc helpers/fork_helper.c -o helpers/fork_helper
gcc helpers/thread_helper.c -o helpers/thread_helper -lpthread
```

Both must be compiled before running envctr. The main script checks for the
compiled binaries at startup and exits with error 112 if they are missing.
