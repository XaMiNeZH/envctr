<div align="center">

```
███████╗███╗   ██╗██╗   ██╗ ██████╗████████╗██████╗ 
██╔════╝████╗  ██║██║   ██║██╔════╝╚══██╔══╝██╔══██╗
█████╗  ██╔██╗ ██║██║   ██║██║        ██║   ██████╔╝
██╔══╝  ██║╚██╗██║╚██╗ ██╔╝██║        ██║   ██╔══██╗
███████╗██║ ╚████║ ╚████╔╝ ╚██████╗   ██║   ██║  ██║
╚══════╝╚═╝  ╚═══╝  ╚═══╝   ╚═════╝   ╚═╝   ╚═╝  ╚═╝
```

**Reproducible Developer Environment Provisioner & Drift Detector**

[![License](https://img.shields.io/badge/license-MIT-blue?style=flat)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS-lightgrey?style=flat)]()
[![Shell](https://img.shields.io/badge/shell-Bash%205.0+-green?style=flat)]()
[![Language](https://img.shields.io/badge/language-Bash%20%2F%20C-orange?style=flat)]()
[![Backends](https://img.shields.io/badge/backends-Docker%20%7C%20QEMU(KVM)%20%7C%20chroot-informational?style=flat)]()


<br/>

> **envctr** — fingerprint your project, provision the environment, lock the state, detect drift before it becomes a 2am incident.

<br/>

---

</div>

## Table of Contents

- [Presentation](#presentation)
- [The Problem](#the-problem)
- [The Solution](#the-solution)
- [How It Works](#how-it-works)
- [Fingerprinting Engine](#fingerprinting-engine)
- [Isolation Backends](#isolation-backends)
- [The Lockfile](#the-lockfile)
- [Drift Detection](#drift-detection)
- [Options and Features](#options-and-features)
- [Execution Modes](#execution-modes)
- [Error Handling](#error-handling)
- [Logging](#logging)
- [Compliance with Project Requirements](#compliance-with-project-requirements)
- [Test Scenarios](#test-scenarios)
- [Project Structure](#project-structure)

---

## Presentation

**envctr** is a command-line tool written in Bash and C that solves one of the most persistent and underestimated problems in software engineering: the inability to reproduce a development environment reliably across machines and teammates.

It fingerprints a project directory, provisions a clean and isolated environment using the available backend (Docker, QEMU/KVM, or chroot), locks the environment state into a portable lockfile, and continuously detects when that environment has drifted from its original specification.

```
envctr [options] -b <backend> -p <project_directory>
```

---

## The Problem

Every software engineering team eventually hits the same wall. A developer clones a repository and spends hours — sometimes days — making it run locally. The project requires a specific Node version, a system library that is not documented, a port configuration that conflicts with something else already running, or a database version that is one major release behind what is installed. No one wrote it down because it worked on the original developer's machine.

This is not a minor inconvenience. It is a structural problem with real costs.

```
Without envctr                           With envctr
---------------------------------------- ----------------------------------------
Read README and guess dependencies   --> envctr -b docker -p ./myproject
Install wrong Node version           --> Environment detected and provisioned
Conflict with existing global tools  --> Lockfile generated automatically
Ask teammates what version they use  --> Teammates run one command, same result
Manually configure ports and env     --> Drift detected if anyone changes anything
Time lost : 4 to 8 hours per person  --> Time lost : under 60 seconds
```

There is also a second layer to the problem that no existing tool addresses well: **drift**. Even after an environment is set up correctly, it silently degrades over time. A developer installs a package manually inside the container. Someone changes a port in the config without updating the lockfile. A dependency gets updated globally and breaks the pinned version. The environment works on one machine and fails on another, again, even though everyone thought it was fixed.

---

## The Solution

envctr addresses both problems in a single tool.

**Provisioning:** It reads the project directory, identifies the stack automatically, selects the appropriate isolation backend, and builds the environment without any manual configuration. The developer does not need to know how Docker networking works or how to configure QEMU. envctr handles it.

**Locking:** After provisioning, it writes an `envctr.lock` file that captures the exact state of the environment — runtimes, dependencies, ports, environment variables, base image. Any teammate can take that lockfile, run envctr, and get an identical environment.

**Drift detection:** envctr can be run at any point after provisioning to compare the live environment state against the lockfile. If anything has changed — a package was added, a config was modified, a port was reassigned — it reports the delta with severity levels and suggests a resolution.

---

## How It Works

The tool operates in four sequential phases:

**Phase 1 — Fingerprinting**
envctr scans the project directory and identifies all signals that indicate what the project needs: language runtime files, dependency manifests, configuration files, Dockerfiles if they exist, environment variable files, and port declarations. From these signals it builds an internal dependency graph.

**Phase 2 — Provisioning**
Using the dependency graph and the chosen backend, envctr provisions the environment. If Docker is available and chosen, it builds or pulls the appropriate image and starts a container with the correct port bindings, volume mounts, and environment variables. If QEMU/KVM is chosen, it boots a lightweight virtual machine over SSH. If chroot is chosen, it sets up an isolated filesystem with the detected runtimes.

**Phase 3 — Locking**
Once the environment is running and verified, envctr writes `envctr.lock` to the project root. This file is committed to version control and serves as the single source of truth for the environment.

**Phase 4 — Drift detection**
On subsequent runs with the `--drift` flag, envctr inspects the live environment and diffs it against the lockfile. Differences are classified by severity: breaking changes (wrong runtime version, missing required service), warnings (manually installed packages, changed ports), and informational (cosmetic config changes).

---

## Fingerprinting Engine

The fingerprinting engine is the core of envctr. It uses pattern matching, regex, and file structure analysis to detect the project stack without any user input.

Detected languages and runtimes:

| Signal File | Detected Stack |
|---|---|
| `package.json` | Node.js — extracts `engines.node` field for version pinning |
| `requirements.txt` / `pyproject.toml` | Python — detects version from `.python-version` or `pyproject.toml` |
| `Makefile` / `*.c` / `*.h` | C/C++ — detects compiler flags and build targets |
| `pom.xml` / `build.gradle` | Java — extracts Java version from compiler plugin config |
| `Cargo.toml` | Rust — reads `edition` and `rust-version` fields |
| `go.mod` | Go — reads `go` directive for version |
| `Gemfile` | Ruby — reads `ruby` version declaration |
| `composer.json` | PHP — reads `require.php` for version |

Beyond runtimes, the fingerprinting engine also detects:

- **Services**: database config files (`knexfile.js`, `database.yml`, `alembic.ini`) indicate PostgreSQL, MySQL, MongoDB, Redis needs
- **Ports**: scans `.env` files, config files, and source files for port declarations using regex
- **Environment variables**: reads `.env.example` or `.env.development` to extract required variable names (not values)
- **System dependencies**: detects `apt`, `brew`, or `yum` install commands in scripts or Dockerfiles

---

## Isolation Backends

envctr supports three isolation backends, chosen with `-b`. The choice depends on the level of isolation needed and the resources available on the host machine.

### Docker

The default for most projects. envctr builds or pulls an appropriate base image, configures port bindings, mounts the project directory as a volume so code changes are reflected immediately, and passes the required environment variables. The container is named after the project directory for easy reference.

```
Host machine
    └── Docker container
            ├── Runtime (Node 18, Python 3.11, etc.)
            ├── Services (PostgreSQL, Redis)
            ├── Port bindings (3000:3000, 5432:5432)
            └── Volume mount (./project --> /app)
```

### QEMU/KVM

For projects that need full OS-level isolation — testing Linux-specific behavior, working with kernel modules, simulating production server environments. envctr boots a minimal Linux VM over KVM, provisions it via SSH, and exposes the project directory over a network mount. Access is through SSH on a forwarded port.

```
Host machine
    └── QEMU/KVM virtual machine (SSH on localhost:2222)
            ├── Full Linux environment
            ├── Project directory mounted via sshfs or virtfs
            ├── Services running natively inside VM
            └── Port forwarding configured automatically
```

This backend requires KVM to be available (`/dev/kvm`) and is the most resource-intensive option. It is the right choice when Docker's shared kernel is not sufficient.

### Chroot

The lightest option. envctr creates an isolated filesystem using `debootstrap` or an existing base tarball, copies the project into it, and executes commands inside via `chroot`. No virtualization overhead, no daemon required. Suitable for simple projects with minimal system dependencies.

```
Host machine
    └── chroot jail (/var/envctr/jails/projectname)
            ├── Isolated filesystem
            ├── Runtime installed inside jail
            └── Project directory bind-mounted
```

---

## The Lockfile

The `envctr.lock` file is the artifact that makes environments reproducible. It is generated automatically after provisioning and is designed to be committed to version control.

```
# envctr.lock
# Generated by envctr on 2026-05-01-14-32-00
# Do not edit manually. Regenerate with: envctr -b docker -p . --lock

[meta]
envctr_version = 1.0.0
project_name   = myapi
generated_at   = 2026-05-01-14-32-00
generated_by   = ahmed

[runtime]
language  = node
version   = 18.17.1
manager   = npm
lock_file = package-lock.json

[services]
postgresql = 15.3
redis      = 7.2.1

[ports]
app      = 3000
postgres = 5432
redis    = 6379

[environment]
required_vars = DATABASE_URL, REDIS_URL, JWT_SECRET, PORT

[backend]
type       = docker
base_image = node:18-alpine
volumes    = ./:/app
```

A teammate who clones the repository and finds this lockfile runs:

```
envctr --from-lock -b docker
```

envctr reads the lockfile, provisions the exact same environment, and the project runs.

---

## Drift Detection

Drift detection is what separates envctr from a simple provisioning script. Environments degrade silently. envctr makes drift visible before it becomes a production incident.

When run with the `--drift` flag, envctr inspects the live environment and compares every field in the lockfile against the current state.

Example drift report:

```
envctr drift report -- 2026-05-03-09-15-00
Project : myapi
Backend : docker
Status  : DRIFT DETECTED

BREAKING
  [runtime.version]  expected 18.17.1 -- found 20.1.0
  [services.redis]   expected 7.2.1   -- found NOT RUNNING

WARNING
  [ports.app]        expected 3000    -- found 4000
  [packages]         manually installed: axios@1.6.0 (not in package-lock.json)

INFO
  [environment]      JWT_SECRET is set but was not present in original lock

Resolution options:
  envctr --restore     re-provision from lockfile
  envctr --update-lock update lockfile to reflect current state
```

Drift is classified into three levels. Breaking means the project will likely not run correctly. Warning means behavior may differ from the locked state. Info means no functional impact but the state has diverged.

---

## Options and Features

```
SYNOPSIS
    envctr [OPTIONS] -b <backend> -p <project_directory>

MANDATORY OPTIONS
    -b <backend>          Isolation backend: docker, qemu, or chroot
    -p <directory>        Project directory to fingerprint and provision

REQUIRED OPTIONS (per project guidelines)
    -h                    Display full program documentation
    -f                    Fork mode: provision each service in an independent child process
    -t                    Thread mode: parallel provisioning via pthreads (C helper)
    -s                    Subshell mode: lightweight isolated execution without full backend
    -l <directory>        Custom log directory (default: /var/log/envctr)
    -r                    Reset and destroy provisioned environment (requires root)

ADDITIONAL OPTIONS
    --from-lock           Provision directly from existing envctr.lock
    --drift               Run drift detection against the lockfile
    --restore             Re-provision from lockfile after drift is detected
    --update-lock         Update lockfile to reflect current live environment state
    --dry-run             Show what would be provisioned without executing
    --export              Export the lockfile for sharing with teammates
```

---

## Execution Modes

The three execution modes control how envctr provisions and manages the environment internally. They map to the light, medium, and heavy workload scenarios required by the project.

### Subshell (-s) — Light workload

The provisioning runs in an isolated Bash subshell. The parent process is not affected if something fails inside. Suitable for single-service projects with minimal dependencies.

```
Parent shell (envctr)
    └── (subshell) --> fingerprint --> provision chroot --> verify --> done
```

Use case: a simple Python Flask app with no external services.

### Fork (-f) — Medium workload

envctr forks a child process for each service that needs to be provisioned. The database, the backend runtime, and the cache layer each get their own child process. If one fails, the others continue. The parent waits for all children and reports aggregate results.

```
Parent process (envctr)
    ├── fork() --> provision PostgreSQL container --> done
    ├── fork() --> provision Redis container      --> done
    └── fork() --> provision Node runtime         --> done
              (all running concurrently, parent waits)
```

Use case: a Node.js API with PostgreSQL and Redis.

### Thread (-t) — Heavy workload

For large projects with many services or monorepos with multiple sub-projects, envctr uses a C helper with pthreads to provision everything in parallel threads within the same process. Lower overhead than fork, higher concurrency.

```
Single process (envctr + thread_helper)
    ├── Thread 1 --> provision service A
    ├── Thread 2 --> provision service B
    ├── Thread 3 --> provision service C
    ├── Thread 4 --> install dependencies for sub-project 1
    └── Thread 5 --> install dependencies for sub-project 2
                    (all simultaneous, joined at completion)
```

Use case: a microservices monorepo with 5 to 10 independent services.

### Performance comparison

| Mode | Scenario | Estimated time | Resources |
|---|---|---|---|
| `-s` Subshell | 1 service, simple project | ~5s | Minimal |
| `-f` Fork | 3-5 services, standard project | ~15s | Moderate |
| `-t` Threads | 10+ services, monorepo | ~25s | Optimized |
| No parallelism | 10+ services, sequential | ~120s | — |

---

## Error Handling

Every error produces a specific exit code and automatically displays the program documentation.

| Code | Description |
|---|---|
| 100 | Unknown option |
| 101 | Mandatory parameter missing (`-b` or `-p`) |
| 102 | Project directory not found |
| 103 | Permission denied (operation requires root) |
| 104 | Backend not available on this machine |
| 105 | Fingerprinting failed — no recognizable stack detected |
| 106 | Lockfile not found or corrupted |
| 107 | Provisioning failed — backend returned non-zero exit |
| 108 | KVM not available (`/dev/kvm` missing or inaccessible) |
| 109 | Drift detected — environment does not match lockfile |

```
$ envctr -p ./myproject
[ERROR 101] Mandatory parameter missing: -b <backend>
            Specify one of: docker, qemu, chroot

USAGE: envctr [options] -b <backend> -p <project_directory>
...
```

---

## Logging

All output is redirected simultaneously to the terminal and to `/var/log/envctr/history.log` using `tee`.

### Format

```
yyyy-mm-dd-hh-mm-ss : username : INFOS : message
yyyy-mm-dd-hh-mm-ss : username : ERROR : message
```

### Example log output

```
2026-05-01-14-32-00 : ahmed : INFOS : envctr started -- project: myapi -- backend: docker
2026-05-01-14-32-01 : ahmed : INFOS : Fingerprinting complete -- detected: node 18, postgresql, redis
2026-05-01-14-32-02 : ahmed : INFOS : Pulling base image node:18-alpine
2026-05-01-14-32-08 : ahmed : INFOS : PostgreSQL 15.3 container started on port 5432
2026-05-01-14-32-09 : ahmed : INFOS : Redis 7.2.1 container started on port 6379
2026-05-01-14-32-10 : ahmed : INFOS : Node runtime provisioned -- project mounted at /app
2026-05-01-14-32-11 : ahmed : INFOS : Lockfile written to ./envctr.lock
2026-05-01-14-32-11 : ahmed : INFOS : Environment ready
2026-05-01-14-35-00 : ahmed : ERROR : Code 109 -- drift detected in runtime.version
```

---

## Compliance with Project Requirements

### 3.2.1 — Real and original need
Reproducing development environments is a daily problem for every software engineering team. No existing command-line tool combines fingerprinting, multi-backend provisioning, lockfile generation, and drift detection in a single Bash-native program.

### 3.2.2 — Six mandatory options
`-h` `-f` `-t` `-s` `-l` `-r` plus additional options `--from-lock` `--drift` `--restore` `--dry-run` `--export`

### 3.2.2 — Mandatory parameter
`-b <backend>` and `-p <directory>` are both required. Absence of either triggers error 101.

### 3.2.2 — Unix/Linux commands used
`find`, `grep`, `awk`, `sed`, `tee`, `tar`, `ssh`, `curl`, `docker`, `qemu-system-x86_64`, `chroot`, `debootstrap`, `diff`, `stat`, `wc`, `sort`, `uniq`, `file`, `env`, `chmod`, `chown`

### 3.2.2 — Shell concepts

| Concept | Usage in envctr |
|---|---|
| Conditions | Backend availability checks, root privilege verification, lockfile existence |
| Loops | Iterating over detected services, processing multiple project directories |
| Functions | `fingerprint()`, `provision()`, `lock()`, `detect_drift()`, `log_message()`, `check_root()` |
| Environment variables | `ENVCTR_BACKEND`, `ENVCTR_LOG_DIR`, `ENVCTR_DEFAULT_BASE` |
| Regular expressions | Extracting versions from manifest files, detecting port declarations, validating lockfile format |
| File manipulation | Reading manifests, writing lockfile, managing log files, bind-mounts |
| Search and archiving | `find` for project scanning, `tar` for environment snapshots |
| Access control | `-r` restricted to root, chroot requires elevated privileges |
| Pipes and filters | `find . -name "*.json" \| grep -v node_modules \| xargs grep "engines"` |

### 3.2.3 — Error handling
9 specific error codes with automatic help display after each error.

### 3.2.4 — Three test scenarios

| Scenario | Description | Mode |
|---|---|---|
| Light | Single Python Flask app, no external services, chroot backend | `-s` subshell |
| Medium | Node.js API with PostgreSQL and Redis, Docker backend | `-f` fork |
| Heavy | Microservices monorepo with 8 services, Docker backend, full drift detection run | `-t` threads |

### 3.2.5 — Documentation
Simplified version accessible via `-h`. Extended version in the PDF report with screenshots, lockfile examples, and drift detection output from each test scenario.

---

## Test Scenarios

### Scenario 1 — Light (subshell)

```bash
envctr -b chroot -p ./examples/flask-simple -s
# Single Python 3.11 Flask application
# No external services
# Expected time: ~5 seconds
```

### Scenario 2 — Medium (fork)

```bash
envctr -b docker -p ./examples/node-api -f
# Node 18 backend + PostgreSQL 15 + Redis 7
# Each service provisioned in its own child process
# Expected time: ~15 seconds
```

### Scenario 3 — Heavy (threads + drift detection)

```bash
envctr -b docker -p ./examples/microservices-monorepo -t
# 8 independent services provisioned in parallel
# Followed by: envctr --drift -p ./examples/microservices-monorepo
# Full drift report generated
# Expected time: ~25 seconds provisioning, ~5 seconds drift scan
```

---

## Project Structure

```
envctr/
|
+-- envctr.sh                          <- Main script (entry point)
|
+-- core/
|   +-- fingerprint.sh                 <- Stack detection and dependency graph
|   +-- lock.sh                        <- Lockfile generation and parsing
|   +-- drift.sh                       <- Drift detection and reporting
|   +-- logger.sh                      <- Shared logging function
|   +-- errors.sh                      <- Error codes and help display
|
+-- backends/
|   +-- docker.sh                      <- Docker provisioning logic
|   +-- qemu.sh                        <- QEMU/KVM provisioning via SSH
|   +-- chroot.sh                      <- Chroot jail provisioning
|
+-- helpers/
|   +-- fork_helper.c                  <- Fork-based parallel provisioning
|   +-- thread_helper.c                <- Pthread-based parallel provisioning
|
+-- examples/
|   +-- flask-simple/                  <- Light scenario: Python Flask, no services
|   +-- node-api/                      <- Medium scenario: Node + PostgreSQL + Redis
|   +-- microservices-monorepo/        <- Heavy scenario: 8 services
|
+-- envctr.lock                        <- Example lockfile
+-- envctr.conf                        <- Default configuration
+-- README.md                          <- This file
```

---

## Configuration

Default configuration at `/etc/envctr/envctr.conf`:

```
LOG_DIR          = /var/log/envctr
DEFAULT_BACKEND  = docker
DOCKER_NETWORK   = envctr-net
QEMU_SSH_PORT    = 2222
CHROOT_BASE_DIR  = /var/envctr/jails
```

---
