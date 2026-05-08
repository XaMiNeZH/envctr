# envctr - Project Specification

Version: 1.0.0
Status: Active
Last updated: 2026-05-08

---

## 1. Project Identity

| Field | Value |
|---|---|
| Tool name | `envctr` |
| Full name | Environment Controller |
| Main script | `envctr` |
| Language | Bash 5.0+ / C helpers |
| Course | Theorie des Systemes d'Exploitation & SE Windows/Unix/Linux |
| Institution | ENSET Mohammedia - Universite Hassan II de Casablanca |
| Deadline | 14/05/2026 23:59:59 |

---

## 2. Problem Statement

Development projects often depend on implicit state: runtime versions, service expectations, ports, and environment variables. This information is scattered across manifests, config files, examples, and source code. When the documentation and the project files drift apart, teammates lose time debugging setup differences.

envctr solves this by turning the current project state into a lockfile and comparing future project state against that lockfile.

The simplified scope is explicit:

1. Fingerprint a project directory.
2. Write a lockfile.
3. Detect drift.
4. Explain drift through the Mistral API.

---

## 3. Solution Overview

envctr operates in four phases:

```text
Fingerprint -> Lock -> Drift -> Explain
```

**Fingerprint:** Scan the project directory using regex and file structure analysis to detect runtime, services, ports, and required environment variable names.

**Lock:** Write `envctr.lock` from the exported fingerprint variables and the selected backend label.

**Drift:** Run fingerprinting again and compare current values against the lockfile. Differences are classified as `BREAKING`, `WARNING`, or `INFO`.

**Explain:** Optionally send the drift report to the Mistral API with `curl` and print a plain-language explanation.

The `-b` backend option accepts `docker`, `qemu`, and `chroot`, but those values are metadata only. They document intended external environment strategy in the lockfile.

---

## 4. Core Requirements from Project PDF

These items remain required.

### 4.1 Mandatory Options

| Option | Required behavior |
|---|---|
| `-h` | Display detailed program documentation in terminal |
| `-f` | Fork execution through the C fork helper |
| `-t` | Thread execution through the C pthread helper |
| `-s` | Subshell execution with `( ... )` |
| `-l <dir>` | Specify custom log directory |
| `-r` | Reset default parameters; admin-only guard |

The `-f` and `-t` helpers now run fingerprinting pipeline work in parallel. They do not perform environment setup.

### 4.2 Mandatory Parameter

`-p <directory>` identifies the project directory. Absence triggers error `101` and displays help.

`-b <backend>` records backend intent in the lockfile.

### 4.3 Logging

- Log file: `history.log`
- Default path: `/var/log/envctr/history.log`
- Output must go to terminal and log simultaneously.
- Format exactly: `yyyy-mm-dd-hh-mm-ss : username : INFOS : message`
- Format exactly: `yyyy-mm-dd-hh-mm-ss : username : ERROR : message`

### 4.4 Error Handling

- Every handled error must have a unique code.
- Help must display automatically after every triggered error.
- Codes `100` and `101` are required minimums.
- Error `110` is used when Mistral explanation is unavailable.

### 4.5 Shell Concepts Required

Conditions, loops, functions, environment variables, regular expressions, file manipulation, search/filtering, access control, pipes, and filters.

### 4.6 Test Scenarios

Three scenarios are required:

- Light: subshell mode with `examples/flask-simple`.
- Medium: fork mode with `examples/node-api`.
- Heavy: thread mode with `examples/microservices-monorepo`.

Each scenario demonstrates fingerprinting, lockfile generation, and drift detection.

### 4.7 Execution Syntax

```bash
envctr [options] -b <backend> -p <project_directory>
```

---

## 5. Architecture

```text
envctr                          <- Main script. Parses options and orchestrates phases.
|
+-- core/
|   +-- fingerprint.sh          <- Detects stack from project files using regex
|   +-- lock.sh                 <- Generates and parses envctr.lock
|   +-- drift.sh                <- Compares current fingerprint to lockfile
|   +-- explain.sh              <- Calls Mistral API to explain drift report
|   +-- logger.sh               <- log_message() function, shared by all
|   +-- errors.sh               <- Error codes, die(), show_help()
|
+-- backends/
|   +-- docker.sh               <- Stub: logs selected backend
|   +-- qemu.sh                 <- Stub: logs selected backend
|   +-- chroot.sh               <- Stub: logs selected backend
|
+-- helpers/
|   +-- fork_helper.c           <- Forks fingerprinting jobs
|   +-- thread_helper.c         <- Runs fingerprinting jobs with pthreads
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
+-- MINI_PROJET_REQUIREMENTS_TRACKER.md
+-- TASK_REPARTITION.md
+-- envctr_project_specification.md
+-- VERSION
```

### Phase 1 - Fingerprinting

`core/fingerprint.sh` scans project files and exports normalized variables describing runtime, services, ports, and environment variable names.

### Phase 2 - Backend Recording

Backend recording: the chosen backend is recorded in the lockfile. No containers or VMs are started.

The backend scripts in `backends/` are stubs. Their only job is to log the selected backend and return success.

### Phase 3 - Lockfile

`core/lock.sh` writes `envctr.lock` from the exported fingerprint variables. It also records the selected backend label.

### Phase 4 - Drift and Explain

`core/drift.sh` reads the lockfile, runs fingerprinting again, compares fields, and prints a severity-classified report. `core/explain.sh` can send that report to the Mistral API and print a plain-language explanation.

---

## 6. Error Codes

| Code | Description |
|---|---|
| 100 | Unknown option |
| 101 | Mandatory parameter missing |
| 102 | Project directory not found |
| 103 | Permission denied for admin-only operation |
| 104 | Unsupported backend label |
| 105 | Fingerprinting failed; no recognizable stack detected |
| 106 | Lockfile not found or corrupted |
| 107 | Lockfile write failed or backend stub returned non-zero |
| 108 | Reserved for legacy backend availability checks |
| 109 | Drift detected; current fingerprint does not match lockfile |
| 110 | Mistral API unreachable or not configured |
| 111 | `-r` reset requires root privileges |
| 112 | Required helper script or binary not found |

---

## 7. Configuration

Default at `/etc/envctr/envctr.conf` or `configs/default.conf`:

```bash
LOG_DIR="/var/log/envctr"
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
version   = 18
manager   = npm

[services]
postgresql = detected
redis      = detected

[ports]
app = 3000

[environment]
required_vars = DATABASE_URL, REDIS_URL, JWT_SECRET

[backend]
type = docker
```

---

## 9. Compliance Checklist

| Requirement | Status | Notes |
|---|---|---|
| Main Bash script | Met | In PR #3, pending merge |
| At least one mandatory parameter | Met | `-p <directory>` in PR #3, pending merge |
| Six mandatory options | Met | `-h -f -t -s -l -r` in PR #3, pending merge |
| `-h` help | Met | `show_help()` in PR #3, pending merge |
| `-f` fork | Met | `fork_helper.c` in PR #3, pending merge |
| `-t` thread | Met | `thread_helper.c` in PR #3, pending merge |
| `-s` subshell | Met | In PR #3, pending merge |
| `-l` log dir | Met | In PR #3, pending merge |
| `-r` reset, root only | Met | Admin guard in PR #3, pending merge |
| Logger | Met | Merged in PR #1 |
| Fingerprint | Met | `core/fingerprint.sh` in PR #2, pending merge |
| Lock | Planned | `core/lock.sh` |
| Drift | Planned | `core/drift.sh` |
| Explain | Planned | `core/explain.sh` with Mistral API |
| Backend scripts | Planned | Stubs record intended backend only |
| Conditions | Met | Option and error handling in PR #3 |
| Loops | Met | Fingerprint scanning in PR #2 |
| Functions | Met | Logger merged; CLI/fingerprint/errors in PR #2/#3 |
| Environment variables | Planned | Mistral config and exported fingerprint variables |
| Regular expressions | Met | `core/fingerprint.sh` in PR #2 |
| File manipulation | Planned | Logging met; lockfile read/write planned |
| Search and filtering | Met | `core/fingerprint.sh` in PR #2 |
| Access control | Met | `-r` admin guard in PR #3 |
| Pipes and filters | Met | Logger merged; fingerprint pipeline in PR #2 |
| Log to terminal + file simultaneously | Met | `core/logger.sh`, merged in PR #1 |
| Log path `/var/log/envctr/history.log` | Met | `core/logger.sh`, merged in PR #1 |
| Log format exact match | Met | `core/logger.sh`, merged in PR #1 |
| Error codes | Met | `core/errors.sh` in PR #3, pending merge |
| Help after every error | Met | `die()` in PR #3, pending merge |
| Light scenario | Planned | `tests/test_light.sh`; `flask-simple`; fingerprint + lock + drift |
| Medium scenario | Planned | `tests/test_medium.sh`; `node-api`; fingerprint + lock + drift |
| Heavy scenario | Planned | `tests/test_heavy.sh`; `microservices-monorepo`; fingerprint + lock + drift |
| External C scripts | Met | `fork_helper.c`, `thread_helper.c` in PR #3, pending merge |
| PDF report | Missing | `TeamID-devoir-shell.pdf` |
| PPTX one slide | Missing | `TeamID-devoir-shell.pptx` |
| ZIP submission | Missing | `TeamID-devoir-shell.zip` |
