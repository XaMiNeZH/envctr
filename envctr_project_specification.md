# envctr — Project Specification

Version: 1.0.0
Status: Active
Last updated: 2026-05-03

---

## 1. Project Identity

| Field | Value |
|---|---|
| Tool name | `envctr` |
| Full name | Environment Controller |
| Main script | `envctr` |
| Language | Bash 5.0+ / C (pthreads helper) |
| Course | Théorie des Systèmes d'Exploitation & SE Windows/Unix/Linux |
| Institution | ENSET Mohammedia — Université Hassan II de Casablanca |
| Deadline | 14/05/2026 23:59:59 |

---

## 2. Problem Statement

Every software engineering team eventually hits the same wall. A developer
clones a repository and spends hours making it run locally. The project requires
a specific Node version, a system library that is not documented, a port that
conflicts with something already running, or a database version nobody wrote
down because it worked on the original developer's machine.

Docker partially solves this for projects that already have a Dockerfile. But it
does not solve three specific problems:

**Kernel-level isolation.** Docker shares the host kernel. If a project requires
testing against a specific kernel version or working with kernel modules, Docker
is not sufficient. QEMU/KVM boots a full virtual machine with its own kernel.

**Machines without Docker.** On locked-down university machines, some CI
environments, or minimal setups, Docker is not available. chroot is a pure
Linux primitive that works anywhere.

**Silent container mutation.** Docker has no mechanism to detect when a running
container's state no longer matches its Dockerfile. A developer who runs
`docker exec` and manually installs a package creates invisible drift. envctr
detects this.

---

## 3. Solution Overview

envctr is a command-line tool that operates in four phases:

```
Fingerprint --> Provision --> Lock --> Drift Detection
```

**Fingerprint:** Scan the project directory using regex and file structure
analysis to detect the stack, runtimes, services, ports, and environment
variables needed. If a Dockerfile already exists, read it directly.

**Provision:** Using the detected stack and the chosen backend (Docker,
QEMU/KVM, or chroot), build and start the isolated environment automatically.

**Lock:** Write `envctr.lock` to the project root capturing the exact
environment state. This file is committed to version control.

**Drift Detection:** On subsequent runs with `--drift`, compare the live
environment against the lockfile. Classify differences as BREAKING, WARNING,
or INFO. Optionally explain the drift report in plain language via Mistral API.

---

## 4. Core Requirements from Project PDF

These are non-negotiable. Every item below must be met exactly as stated.

### 4.1 Mandatory options

| Option | Required behavior |
|---|---|
| `-h` | Display detailed program documentation in terminal |
| `-f` | Fork execution — each service provisioned in an independent child process via `fork()` |
| `-t` | Thread execution — parallel provisioning via real pthreads C helper |
| `-s` | Subshell execution — pipeline runs inside `( ... )` subshell |
| `-l <dir>` | Specify custom log directory |
| `-r` | Reset envctr.conf to defaults and destroy provisioned environment — root only |

### 4.2 Mandatory parameter

`-p <directory>` is required. Absence triggers error 101 and displays help.

### 4.3 Logging

- Log file: `history.log`
- Default path: `/var/log/envctr/history.log`
- All stdout and stderr must be redirected simultaneously to terminal AND log
- Format exactly: `yyyy-mm-dd-hh-mm-ss : username : INFOS : message`
- Format exactly: `yyyy-mm-dd-hh-mm-ss : username : ERROR : message`

### 4.4 Error handling

- Every error must have a unique code
- Help must display automatically after every triggered error
- Codes 100 (unknown option) and 101 (missing parameter) are required minimums

### 4.5 Shell concepts required

Conditions, loops, functions, environment variables, regular expressions,
file manipulation, search/archive/compression, access control, pipes and
filters.

### 4.6 Test scenarios

Three scenarios required: light (subshell), medium (fork), heavy (threads).

### 4.7 Execution syntax

```
envctr [options] -p <project_directory>
```

---

## 5. Architecture

```
envctr                          <- Main script. Entry point. Parses options,
|                                  orchestrates all phases, manages logging.
|
+-- core/
|   +-- fingerprint.sh          <- Detects stack from project files using regex
|   +-- lock.sh                 <- Generates and parses envctr.lock
|   +-- drift.sh                <- Compares live environment to lockfile
|   +-- explain.sh              <- Calls Mistral API to explain drift report
|   +-- logger.sh               <- log_message() function, shared by all
|   +-- errors.sh               <- Error codes, die(), show_help()
|
+-- backends/
|   +-- docker.sh               <- Docker provisioning logic
|   +-- qemu.sh                 <- QEMU/KVM provisioning via SSH
|   +-- chroot.sh               <- chroot jail provisioning
|
+-- helpers/
|   +-- fork_helper.c           <- Forks one child process per service
|   +-- thread_helper.c         <- pthreads parallel provisioning
|
+-- configs/
|   +-- default.conf            <- Default envctr configuration
|
+-- examples/
|   +-- flask-simple/           <- Light scenario project
|   +-- node-api/               <- Medium scenario project
|   +-- microservices-monorepo/ <- Heavy scenario project
|
+-- tests/
|   +-- run_all.sh
|   +-- test_light.sh
|   +-- test_medium.sh
|   +-- test_heavy.sh
|
+-- docs/
|   +-- USAGE.md
|   +-- TEST_SCENARIOS.md
|   +-- VERSIONING.md
|
+-- envctr.lock                 <- Example lockfile for documentation
+-- envctr.conf                 <- User configuration
+-- CHANGELOG.md
+-- README.md
```

---

## 6. Error Codes

| Code | Description |
|---|---|
| 100 | Unknown option |
| 101 | Mandatory parameter missing (`-p`) |
| 102 | Project directory not found |
| 103 | Permission denied — operation requires root |
| 104 | Backend not available on this machine |
| 105 | Fingerprinting failed — no recognizable stack detected |
| 106 | Lockfile not found or corrupted |
| 107 | Provisioning failed — backend returned non-zero exit |
| 108 | KVM not available (`/dev/kvm` inaccessible) |
| 109 | Drift detected — environment does not match lockfile |
| 110 | Mistral API unreachable — drift explanation unavailable, raw report shown |
| 111 | `-r` reset requires root privileges |
| 112 | Backend binary not found (`docker`, `qemu-system-x86_64`, etc.) |

---

## 7. Configuration

Default at `/etc/envctr/envctr.conf` or `configs/default.conf`:

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

---

## 8. Lockfile Format

```ini
# envctr.lock
# Generated by envctr on yyyy-mm-dd-hh-mm-ss
# Do not edit manually.

[meta]
envctr_version = 1.0.0
project_name   = myproject
generated_at   = yyyy-mm-dd-hh-mm-ss
generated_by   = username

[runtime]
language  = node
version   = 18.17.1
manager   = npm

[services]
postgresql = 15.3
redis      = 7.2.1

[ports]
app      = 3000
postgres = 5432
redis    = 6379

[environment]
required_vars = DATABASE_URL, REDIS_URL, JWT_SECRET

[backend]
type       = docker
base_image = node:18-alpine
volumes    = ./:/app
```

---

## 9. Compliance Checklist

| Requirement | Status | Notes |
|---|---|---|
| Main Bash script | Planned | `envctr` |
| At least one mandatory parameter | Planned | `-p <directory>` |
| Six mandatory options | Planned | `-h -f -t -s -l -r` |
| `-h` help | Planned | `show_help()` in `core/errors.sh` |
| `-f` fork | Planned | `fork_helper.c` via `fork()` + `waitpid()` |
| `-t` thread | Planned | `thread_helper.c` via `pthreads` |
| `-s` subshell | Planned | `( ... )` subshell wrapper |
| `-l` log dir | Planned | Overrides `LOG_DIR` |
| `-r` restore (root only) | Planned | Resets `envctr.conf` + destroys environment |
| Admin privilege check | Planned | `[[ $EUID -ne 0 ]]` for `-r` |
| Conditions | Planned | Backend checks, root check, lockfile existence |
| Loops | Planned | Service iteration, fingerprint scan |
| Functions | Planned | `fingerprint()`, `provision()`, `lock()`, `detect_drift()`, `log_message()` |
| Environment variables | Planned | `ENVCTR_BACKEND`, `ENVCTR_LOG_DIR`, `ENVCTR_DEFAULT_BASE` |
| Regular expressions | Planned | Version extraction from manifests, port detection |
| File manipulation | Planned | Lockfile R/W, log management, bind-mounts |
| Search and archiving | Planned | `find` for scanning, `tar` for snapshots |
| Access control | Planned | `-r` root-only, chroot privileges |
| Pipes and filters | Planned | Stack fingerprinting pipeline |
| Log to terminal + file simultaneously | Planned | `tee -a /var/log/envctr/history.log` |
| Log path `/var/log/envctr/history.log` | Planned | Default in `configs/default.conf` |
| Log format exact match | Planned | `yyyy-mm-dd-hh-mm-ss : username : INFOS : message` |
| Error codes | Planned | 13 codes defined |
| Help after every error | Planned | `die()` always calls `show_help()` |
| Light scenario | Planned | `tests/test_light.sh` — subshell, chroot, Flask |
| Medium scenario | Planned | `tests/test_medium.sh` — fork, Docker, Node+Postgres |
| Heavy scenario | Planned | `tests/test_heavy.sh` — threads, Docker, 8 services |
| External C scripts | Planned | `fork_helper.c`, `thread_helper.c` |
| PDF report | Pending | `TeamID-devoir-shell.pdf` |
| PPTX one slide | Pending | `TeamID-devoir-shell.pptx` |
| ZIP submission | Pending | `TeamID-devoir-shell.zip` |
