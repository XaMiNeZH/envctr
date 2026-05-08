<div align="center">

```
                                                    ,d                
                                                    88                
 ,adPPYba,  8b,dPPYba,   8b       d8   ,adPPYba,  MM88MMM  8b,dPPYba, 
a8P_____88  88P'   `"8a  `8b     d8'  a8"     ""    88     88P'   "Y8 
8PP"""""""  88       88   `8b   d8'   8b            88     88         
"8b,   ,aa  88       88    `8b,d8'    "8a,   ,aa    88,    88         
 `"Ybbd8"'  88       88      "8"       `"Ybbd8"'    "Y888  88         
```

**Project Fingerprinter, Lockfile Writer, Drift Detector, and Mistral Explainer**

[![License](https://img.shields.io/badge/license-MIT-blue?style=flat)](LICENSE)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS-lightgrey?style=flat)
![Shell](https://img.shields.io/badge/shell-Bash%205.0+-green?style=flat)
![Language](https://img.shields.io/badge/language-Bash%20%2F%20C-orange?style=flat)
![Backend Record](https://img.shields.io/badge/backend%20record-docker%20%7C%20qemu%20%7C%20chroot-informational?style=flat)
[![LLM](https://img.shields.io/badge/LLM-Mistral%20API-7C3AED?style=flat)](https://docs.mistral.ai/)

<br/>

> **envctr** fingerprints a project directory, writes an `envctr.lock` file, detects drift, and can explain drift through the Mistral API.

<br/>

---

</div>

## Table of Contents

- [Presentation](#presentation)
- [The Problem](#the-problem)
- [The Solution](#the-solution)
- [How It Works](#how-it-works)
- [Fingerprinting Engine](#fingerprinting-engine)
- [Backend Recording](#backend-recording)
- [The Lockfile](#the-lockfile)
- [Drift Detection](#drift-detection)
- [Drift Explanation with Mistral API](#drift-explanation-with-mistral-api)
- [Options and Features](#options-and-features)
- [Execution Modes](#execution-modes)
- [Error Handling](#error-handling)
- [Logging](#logging)
- [Compliance with Project Requirements](#compliance-with-project-requirements)
- [Test Scenarios](#test-scenarios)
- [Project Structure](#project-structure)
- [Configuration](#configuration)

---

## Presentation

`envctr` is a Bash CLI tool with small C helpers for parallel execution modes. Its scope is intentionally narrow:

1. **Fingerprint** a project directory using regex and file detection.
2. **Lock** the detected state into `envctr.lock`.
3. **Detect drift** by comparing the current fingerprint with the lockfile.
4. **Explain drift** by sending the drift report to the Mistral API.

The `-b` backend option is still accepted for `docker`, `qemu`, and `chroot`, but it is metadata only. envctr records the intended backend in the lockfile for documentation and team communication. It does not manage runtime isolation directly.

```bash
envctr [options] -b <backend> -p <project_directory>
```

---

## The Problem

Every software engineering team eventually hits the same wall. A developer clones a repository and spends hours making it run locally. The project requires a specific Node version, a system library that is not documented, a port configuration that conflicts with something else already running, or environment variables that were never written down because they worked on the original developer's machine.

This is not a minor inconvenience. It is a structural problem with real costs.

```text
Without envctr                           With envctr
---------------------------------------- ----------------------------------------
Read README and guess dependencies   --> envctr -b docker -p ./myproject
Install wrong runtime version        --> Stack fingerprinted from project files
Miss required env vars               --> Required variable names captured
Forget which ports are expected      --> Ports recorded in envctr.lock
Ask teammates what changed           --> Drift report shows the difference
Time lost: 4 to 8 hours per person   --> Time lost: a quick scan and compare
```

There is also a second layer to the problem: **drift**. Even after a project is documented once, the repository changes over time. Someone edits a port in `.env.example`, upgrades the runtime in `package.json`, adds a service config, or removes a required variable without updating the lockfile. The project may still work for one teammate but fail for another. envctr makes that drift visible.

---

## The Solution

envctr gives the team a lightweight state contract for a project directory.

**Fingerprint:** Scan files such as `package.json`, `requirements.txt`, `pyproject.toml`, `.env.example`, `Dockerfile`, `go.mod`, `Cargo.toml`, and service config files. Export detected runtime, services, ports, and environment variable names.

**Lock:** Write an `envctr.lock` file from the exported fingerprint variables. The lockfile captures the detected stack plus the selected backend label.

**Drift:** Run fingerprinting again later and compare the current result against `envctr.lock`. Differences are classified as `BREAKING`, `WARNING`, or `INFO`.

**Explain:** When requested, send the drift report to the Mistral API through `curl` and print a plain-language explanation. This is optional and never required for the raw drift report.

---

## How It Works

The tool operates in four sequential phases:

**Phase 1 - Fingerprinting**

envctr scans the project directory and identifies signals that describe the stack: language runtime files, dependency manifests, configuration files, environment variable examples, and port declarations. Existing Docker-related files may be read as project metadata, but envctr does not execute Docker commands as part of the simplified scope.

**Phase 2 - Locking and backend recording**

The chosen backend from `-b docker`, `-b qemu`, or `-b chroot` is recorded in `envctr.lock`. The backend value documents the team's intended environment strategy. No environment is created by envctr.

**Phase 3 - Drift detection**

On a drift run, envctr reads the existing lockfile, fingerprints the project again, and compares field by field. It reports changed runtime, services, ports, env vars, or backend metadata.

**Phase 4 - Explanation**

With `-e`, the structured drift report is sent to the Mistral API. If the API key is missing or the API is unreachable, envctr keeps the raw drift report and logs error code `110`.

---

## Fingerprinting Engine

The fingerprinting engine uses pattern matching, regular expressions, and file structure analysis to detect the project stack without manual input.

Detected languages and runtimes:

| Signal File | Detected Stack |
|---|---|
| `package.json` | Node.js, including `engines.node` when present |
| `requirements.txt` / `pyproject.toml` | Python |
| `Makefile` / `*.c` | C/C++ |
| `pom.xml` / `build.gradle` | Java |
| `Cargo.toml` | Rust |
| `go.mod` | Go |

Additional detected fields:

- **Services:** database and cache hints from files such as `knexfile.js`, `database.yml`, `alembic.ini`, and config text containing service names.
- **Ports:** `PORT=` values from `.env` or `.env.example`.
- **Environment variables:** required variable names from `.env.example`. Values are not stored.
- **Existing project metadata:** `Dockerfile` is read as a signal only.

---

## Backend Recording

The `-b` option is retained because it is useful team documentation. Accepted values are:

```text
docker
qemu
chroot
```

In the simplified scope, backend scripts are stubs. They log the selected backend and exit successfully. The backend is written to `envctr.lock` so teammates can see the intended external environment strategy, but envctr does not provision environments directly.

Example lockfile section:

```ini
[backend]
type = docker
```

---

## The Lockfile

The `envctr.lock` file is the artifact that makes the detected project state reviewable and repeatable. It is designed to be committed to version control.

```ini
# envctr.lock
# Generated by envctr on 2026-05-08-14-32-00
# Do not edit manually. Regenerate with: envctr -b docker -p .

[meta]
envctr_version = 1.0.0
project_name   = myapi
generated_at   = 2026-05-08-14-32-00
generated_by   = ahmed

[runtime]
language  = node
version   = 18
manager   = npm
lock_file = package-lock.json

[services]
postgresql = detected
redis      = detected

[ports]
app = 3000

[environment]
required_vars = DATABASE_URL, REDIS_URL, JWT_SECRET, PORT

[backend]
type = docker
```

The lockfile records what envctr detected. It does not claim that services were installed or started.

---

## Drift Detection

Drift detection compares the saved lockfile with a fresh fingerprint of the same project directory.

Example drift report:

```text
envctr drift report -- 2026-05-08-15-10-00
Project : myapi
Backend : docker
Status  : DRIFT DETECTED

BREAKING
  [runtime.version]  expected 18 -- found 20

WARNING
  [ports.app]        expected 3000 -- found 4000

INFO
  [environment]      ANALYTICS_KEY is present but was not in the lockfile

Resolution options:
  envctr -b docker -p .              regenerate lockfile after review
  envctr -b docker --drift -p .                inspect raw drift report
  envctr -b docker --drift -e -p .             explain report with Mistral API
```

Severity levels:

| Level | Meaning |
|---|---|
| `BREAKING` | The project will likely not run the same way, such as a runtime or required service change. |
| `WARNING` | Behavior may differ, such as a changed port or changed optional service hint. |
| `INFO` | The state changed but probably does not affect execution directly. |

---

## Drift Explanation with Mistral API

When `-e` is combined with `--drift`, envctr sends the drift report to the Mistral API and returns a plain-language explanation.

This feature is optional. envctr works without a Mistral API key. If `MISTRAL_API_KEY` is not set or the API call fails, envctr prints the raw drift report and logs error `110`.

Example:

```bash
envctr --drift -e -b docker -p ./myapi
```

Example output:

```text
--- raw drift ---
BREAKING  [runtime.version]  expected 18 -- found 20
WARNING   [ports.app]        expected 3000 -- found 4000

--- mistral explanation ---
The most important change is the Node runtime version. The lockfile says
the project was fingerprinted with Node 18, but the current project metadata
now points to Node 20. Review dependency compatibility before accepting this
change into the lockfile.

The port changed from 3000 to 4000. This is less severe, but teammates and
local proxy settings may need to be updated.
```

The LLM is invoked only on structured drift output. It is not used for fingerprinting, lockfile generation, or decision-making.

---

## Options and Features

```text
SYNOPSIS
    envctr [OPTIONS] -b <backend> -p <project_directory>

CORE OPTIONS
    -b <backend>          Backend label to record: docker, qemu, or chroot
    -p <directory>        Project directory to fingerprint

REQUIRED OPTIONS (per project guidelines)
    -h                    Display full program documentation
    -f                    Fork mode: run fingerprinting pipeline jobs through fork_helper.c
    -t                    Thread mode: run fingerprinting pipeline jobs through thread_helper.c
    -s                    Subshell mode: run the pipeline inside a Bash subshell
    -l <directory>        Custom log directory (default: /var/log/envctr)
    -r                    Reset defaults; admin-only guard remains enforced

ADDITIONAL OPTIONS
    -e                    Explain drift report through Mistral API
    --from-lock           Read an existing envctr.lock
    --drift               Compare current fingerprint against envctr.lock
    --update-lock         Update envctr.lock after reviewing drift
    --dry-run             Show what would be fingerprinted and locked
    --export              Export or print lockfile data for sharing
```

---

## Execution Modes

The three execution modes are preserved for the professor's required Bash/C behavior. They now run the fingerprinting, lock, and drift pipeline instead of environment provisioning work.

### Subshell (`-s`) - Light workload

The pipeline runs inside a Bash subshell. The parent shell state is not affected if a variable is exported or changed during fingerprinting.

```text
Parent shell (envctr)
    +-- (subshell) -> fingerprint -> lock -> optional drift
```

Use case: `examples/flask-simple`, a small Flask project used as a fingerprinting target.

### Fork (`-f`) - Medium workload

envctr uses the C fork helper to run independent fingerprinting jobs in child processes. For example, one child can scan runtime manifests while another scans ports and environment files. The parent waits and combines the results.

```text
Parent process (envctr)
    +-- fork() -> scan runtime manifests
    +-- fork() -> scan service hints
    +-- fork() -> scan ports and env vars
              parent waits -> lock -> optional drift
```

Use case: `examples/node-api`, a Node API fingerprinting target with service and env-var signals.

### Thread (`-t`) - Heavy workload

envctr uses the C pthread helper to parallelize fingerprinting jobs for larger repositories and monorepos. Threads share the process and are joined before lockfile generation or drift comparison.

```text
Single process (envctr + thread_helper)
    +-- Thread 1 -> scan service A
    +-- Thread 2 -> scan service B
    +-- Thread 3 -> scan service C
    +-- Thread 4 -> scan shared configs
                    joined -> lock -> optional drift
```

Use case: `examples/microservices-monorepo`, a multi-directory fingerprinting target.

### Performance comparison

| Mode | Scenario | Workload |
|---|---|---|
| `-s` Subshell | 1 small project | Minimal scan and lock |
| `-f` Fork | Standard API project | Parallel runtime/service/env scans |
| `-t` Threads | Monorepo | Parallel scans across subdirectories |

---

## Error Handling

Every error produces a specific exit code and automatically displays the program documentation.

| Code | Description |
|---|---|
| 100 | Unknown option |
| 101 | Mandatory parameter missing (`-b` or `-p`) |
| 102 | Project directory not found |
| 103 | Permission denied for an admin-only operation |
| 104 | Unsupported backend label |
| 105 | Fingerprinting failed; no recognizable stack detected |
| 106 | Lockfile not found or corrupted |
| 107 | Lockfile write failed or backend stub returned non-zero |
| 108 | Reserved for legacy backend availability checks |
| 109 | Drift detected; current fingerprint does not match lockfile |
| 110 | Mistral API unreachable or not configured; raw drift report shown |
| 111 | `-r` reset requires root privileges |
| 112 | Required helper script or binary not found |

```text
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

```text
yyyy-mm-dd-hh-mm-ss : username : INFOS : message
yyyy-mm-dd-hh-mm-ss : username : ERROR : message
```

### Example log output

```text
2026-05-08-14-32-00 : ahmed : INFOS : envctr started -- project: myapi -- backend: docker
2026-05-08-14-32-01 : ahmed : INFOS : Backend selected: docker -- recorded in lockfile
2026-05-08-14-32-02 : ahmed : INFOS : Fingerprinting complete -- detected: node 18, postgresql, redis
2026-05-08-14-32-03 : ahmed : INFOS : Lockfile written to ./envctr.lock
2026-05-08-14-35-00 : ahmed : ERROR : Code 109 -- drift detected in runtime.version
2026-05-08-14-35-01 : ahmed : INFOS : Sending drift report to Mistral API
2026-05-08-14-35-03 : ahmed : INFOS : Mistral explanation received in 2.1s
```

---

## Compliance with Project Requirements

### 3.2.1 - Real and original need

Development environment drift is a daily team problem. envctr's originality is the combination of regex/file-based project fingerprinting, a portable lockfile, drift classification, and optional Mistral API explanation in a Bash-native CLI with C helpers for fork and thread execution modes.

### 3.2.2 - Six mandatory options

`-h` `-f` `-t` `-s` `-l` `-r` are implemented in the planned CLI surface, with additional project options such as `-b`, `-p`, `-e`, `--from-lock`, `--drift`, `--update-lock`, `--dry-run`, and `--export`.

### 3.2.2 - Mandatory parameter

`-p <directory>` identifies the project directory. `-b <backend>` records backend intent in the lockfile.

### 3.2.2 - Unix/Linux commands used

`find`, `grep`, `awk`, `sed`, `tee`, `curl`, `diff`, `stat`, `wc`, `sort`, `uniq`, `file`, `env`, `chmod`, `mkdir`, `rm`, `cp`, `cat`, `echo`, `date`, `whoami`, `basename`, `dirname`

### 3.2.2 - Shell concepts

| Concept | Usage in envctr |
|---|---|
| Conditions | Option validation, project directory checks, lockfile existence, Mistral reachability |
| Loops | Iterating over detected files, services, ports, and lockfile fields |
| Functions | `fingerprint()`, `generate_lock()`, `parse_lock()`, `detect_drift()`, `explain_drift()`, `log_message()`, `die()` |
| Environment variables | `LOG_DIR`, `MISTRAL_API_KEY`, `MISTRAL_MODEL`, `MISTRAL_API_URL`, exported fingerprint variables |
| Regular expressions | Extracting runtime versions, port declarations, service hints, and env var names |
| File manipulation | Reading manifests, writing lockfile, reading config files, managing logs |
| Search and filters | `find`, `grep`, `awk`, `sed`, `sort`, `uniq` in the fingerprinting pipeline |
| Access control | `-r` remains admin-only |
| Pipes and filters | Scanning and normalizing project metadata through standard Unix filters |

### 3.2.3 - Error handling

Specific error codes are defined, and help is displayed after triggered errors. Error `110` degrades gracefully: Mistral failure never blocks the raw drift report.

### 3.2.4 - Three test scenarios

| Scenario | Description | Mode |
|---|---|---|
| Light | `flask-simple` fingerprint, lockfile write, and drift check | `-s` subshell |
| Medium | `node-api` fingerprint, lockfile write, and drift check | `-f` fork |
| Heavy | `microservices-monorepo` fingerprint, lockfile write, drift check, optional Mistral explanation | `-t` threads |

### 3.2.5 - Documentation

Simplified documentation is available through `-h`. Extended documentation and screenshots will be included in the final PDF report.

---

## Test Scenarios

### Scenario 1 - Light: `flask-simple` under subshell mode

```bash
envctr -b chroot -p ./examples/flask-simple -s
envctr --drift -s -b chroot -p ./examples/flask-simple
```

Expected behavior:

- Fingerprint a minimal Flask project.
- Write `envctr.lock`.
- Record `chroot` as the intended backend.
- Run drift comparison against the current project files.

### Scenario 2 - Medium: `node-api` under fork mode

```bash
envctr -b docker -p ./examples/node-api -f
envctr --drift -f -b docker -p ./examples/node-api
```

Expected behavior:

- Fingerprint Node runtime metadata, service hints, ports, and env vars.
- Use fork mode to parallelize fingerprinting jobs.
- Write `envctr.lock`.
- Record `docker` as the intended backend.
- Compare the fresh fingerprint with the lockfile.

### Scenario 3 - Heavy: `microservices-monorepo` under thread mode

```bash
envctr -b docker -p ./examples/microservices-monorepo -t
envctr --drift -e -t -b docker -p ./examples/microservices-monorepo
```

Expected behavior:

- Fingerprint multiple subdirectories in a monorepo.
- Use pthread mode to parallelize scanning work.
- Write `envctr.lock`.
- Record `docker` as the intended backend.
- Detect drift and optionally explain it with the Mistral API.

---

## Project Structure

```text
envctr/
|
+-- envctr                          <- Main script and CLI entry point
|
+-- core/
|   +-- fingerprint.sh              <- Stack detection using regex and file scans
|   +-- lock.sh                     <- Lockfile generation and parsing
|   +-- drift.sh                    <- Drift detection and reporting
|   +-- explain.sh                  <- Mistral API drift explanation
|   +-- logger.sh                   <- Shared logging function
|   +-- errors.sh                   <- Error codes and help display
|
+-- backends/
|   +-- docker.sh                   <- Stub: logs backend selection only
|   +-- qemu.sh                     <- Stub: logs backend selection only
|   +-- chroot.sh                   <- Stub: logs backend selection only
|
+-- helpers/
|   +-- fork_helper.c               <- Fork-based parallel fingerprinting helper
|   +-- thread_helper.c             <- Pthread-based parallel fingerprinting helper
|
+-- configs/
|   +-- default.conf                <- Default envctr configuration
|
+-- docs/
|   +-- USAGE.md
|   +-- TEST_SCENARIOS.md
|   +-- VERSIONING.md
|
+-- tests/
|   +-- run_all.sh
|   +-- test_light.sh
|   +-- test_medium.sh
|   +-- test_heavy.sh
|
+-- examples/
|   +-- flask-simple/               <- Light fingerprinting target
|   +-- node-api/                   <- Medium fingerprinting target
|   +-- microservices-monorepo/     <- Heavy fingerprinting target
|
+-- envctr.lock                     <- Example lockfile
+-- envctr.conf                     <- User configuration
+-- CHANGELOG.md
+-- VERSION
+-- README.md
+-- MINI_PROJET_REQUIREMENTS_TRACKER.md
+-- TASK_REPARTITION.md
+-- envctr_project_specification.md
```

---

## Configuration

Default configuration at `/etc/envctr/envctr.conf` or `configs/default.conf`:

```bash
LOG_DIR="/var/log/envctr"
MISTRAL_API_KEY=""
MISTRAL_MODEL="mistral-small-latest"
MISTRAL_API_URL="https://api.mistral.ai/v1/chat/completions"
```
