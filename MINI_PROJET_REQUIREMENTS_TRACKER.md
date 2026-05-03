# Mini Projet Requirements Tracker

Audit date: 2026-05-03
Project: envctr
Main script: `envctr`

Legend:
- `Met` — implemented and verified
- `Planned` — designed, not yet implemented
- `Partial` — implemented but not fully compliant
- `Missing` — not found, must be added before submission

---

## Overall Status

envctr is in pre-implementation phase. Architecture is designed, task
distribution is complete, and all technical decisions are finalized. This
tracker will be updated after each implementation milestone.

---

## 1. Project Objective

| Requirement | Status | Evidence | Notes |
|---|---|---|---|
| Automate standard Unix/Linux processes | Planned | `envctr_project_specification.md` | Automates fingerprinting, provisioning, locking, drift detection |
| Address a real user need for developers or sysadmins | Planned | `README.md` | Dev environment reproducibility and drift detection |
| Main shell script deliverable | Planned | `envctr` | Main Bash CLI, entry point |
| PDF report `TeamID-devoir-shell.pdf` | Missing | — | Due before 14/05/2026 |
| One-slide PPTX `TeamID-devoir-shell.pptx` | Missing | — | Due before 14/05/2026 |
| ZIP `TeamID-devoir-shell.zip` | Missing | — | Due before 14/05/2026 |

---

## 2. Script Technical Requirements

| Requirement | Status | Evidence | Notes |
|---|---|---|---|
| Developed primarily in Bash | Planned | `envctr`, `core/*.sh`, `backends/*.sh` | All orchestration in Bash |
| May call external Bash or C scripts | Planned | `helpers/fork_helper.c`, `helpers/thread_helper.c` | C helpers for fork and pthreads |
| Unix/Linux commands | Planned | See section 2.1 | Full list below |
| Conditions | Planned | Backend checks, root check, lockfile existence | `if`, `case`, `[[ ]]` |
| Loops | Planned | Service iteration, file scanning | `for`, `while` |
| Functions | Planned | `fingerprint()`, `provision()`, `lock()`, `detect_drift()`, `log_message()`, `die()`, `show_help()`, `check_root()` | All in dedicated files |
| Environment variables | Planned | `ENVCTR_BACKEND`, `ENVCTR_LOG_DIR`, `ENVCTR_DEFAULT_BASE`, `MISTRAL_API_KEY` | Sourced from `configs/default.conf` |
| Regular expressions | Planned | Version extraction from manifests, port detection, lockfile validation | Used in `core/fingerprint.sh` |
| File manipulation | Planned | Lockfile read/write, log management, bind-mounts | `mkdir`, `rm`, `cp`, `tee` |
| Archiving and compression | Planned | `tar` for environment snapshots | In `core/lock.sh` |
| Access control | Planned | `-r` root-only via `[[ $EUID -ne 0 ]]` | In `core/errors.sh` |
| Pipes and filters | Planned | `find . -name "*.json" \| grep -v node_modules \| xargs grep "engines"` | In `core/fingerprint.sh` |
| At least one mandatory parameter | Planned | `-p <directory>` | Absence triggers error 101 |

### 2.1 Unix/Linux Commands Used

`find`, `grep`, `awk`, `sed`, `tee`, `tar`, `ssh`, `curl`, `docker`,
`qemu-system-x86_64`, `chroot`, `debootstrap`, `diff`, `stat`, `wc`, `sort`,
`uniq`, `file`, `env`, `chmod`, `chown`, `mkdir`, `rm`, `cp`, `cat`, `echo`,
`date`, `whoami`, `id`

---

## 3. Mandatory Options

| Option | Required meaning | Status | Implementation | Notes |
|---|---|---|---|---|
| `-h` | Help / full documentation | Planned | `show_help()` in `core/errors.sh` | Displays to terminal on `-h` and after every error |
| `-f` | Fork execution | Planned | `helpers/fork_helper.c` compiled to `helpers/fork_helper` | Real `fork()` + `waitpid()` in C — not background jobs |
| `-t` | Thread execution | Planned | `helpers/thread_helper.c` compiled with `-lpthread` | Real pthreads — not background job simulation |
| `-s` | Subshell execution | Planned | `( envctr_pipeline )` in `envctr` | Wraps full pipeline in subshell |
| `-l <dir>` | Custom log directory | Planned | Overrides `LOG_DIR` variable | Validates directory exists or creates it |
| `-r` | Reset defaults, admin only | Planned | Resets `envctr.conf` to defaults, destroys provisioned environment | `[[ $EUID -ne 0 ]]` enforced — triggers error 111 if not root |

**Note on `-t`:** The project PDF requires thread execution. This is implemented
using a real C pthreads helper, not Bash background job simulation. This is the
correct interpretation of the requirement.

**Note on `-r`:** The project PDF states "reset default parameters, admin only."
In envctr, this means restoring `envctr.conf` to factory defaults and destroying
the provisioned environment for the specified project. This matches the
professor's intent.

---

## 4. Logging

| Requirement | Status | Evidence | Notes |
|---|---|---|---|
| STDOUT and STDERR to terminal AND log simultaneously | Planned | `tee -a "$LOG_FILE"` in `core/logger.sh` | All output through `log_message()` |
| Log file named `history.log` | Planned | `LOG_FILE="$LOG_DIR/history.log"` | Set in `core/logger.sh` |
| Default path `/var/log/envctr/history.log` | Planned | `configs/default.conf` | `LOG_DIR="/var/log/envctr"` |
| Log format `yyyy-mm-dd-hh-mm-ss : username : INFOS : message` | Planned | `core/logger.sh` | Exact match, no deviation |
| Log format `yyyy-mm-dd-hh-mm-ss : username : ERROR : message` | Planned | `core/logger.sh` | Exact match, no deviation |

---

## 5. Error Handling

| Requirement | Status | Evidence | Notes |
|---|---|---|---|
| Handles incorrect usage | Planned | `die()` in `core/errors.sh` | Catches unknown options, missing params, failed operations |
| Specific error codes | Planned | 13 codes defined in `core/errors.sh` | See specification |
| Code 100 — unknown option | Planned | `die 100` | First check in option parsing |
| Code 101 — missing mandatory parameter | Planned | `die 101` | Checked after `getopts` |
| Help displayed after every triggered error | Planned | `die()` always calls `show_help()` before exit | No exceptions |

---

## 6. Test Scenarios

| Requirement | Status | Evidence | Notes |
|---|---|---|---|
| Standard syntax `program [options] [parameter]` | Planned | `envctr [options] -p <directory>` | Follows Linux convention |
| Light scenario | Planned | `tests/test_light.sh` | Subshell, chroot, single Python Flask app |
| Medium scenario | Planned | `tests/test_medium.sh` | Fork, Docker, Node + PostgreSQL + Redis |
| Heavy scenario | Planned | `tests/test_heavy.sh` | Threads, Docker, 8-service monorepo |
| Subshell evaluation | Planned | `test_light.sh` uses `-s` | Clear subshell demonstration |
| Fork evaluation | Planned | `test_medium.sh` uses `-f` | Each service in its own child process |
| Thread evaluation | Planned | `test_heavy.sh` uses `-t` | Real pthreads C helper |

---

## 7. Documentation

| Requirement | Status | Notes |
|---|---|---|
| Internal `-h` documentation | Planned | `show_help()` — Linux man-page style |
| Extended PDF report | Missing | Must include screenshots from all three test scenarios |
| Report covers all directive specifications | Missing | Map each feature to its PDF section number |
| Report includes concrete usage examples | Missing | Normal, subshell, fork, thread |
| One-slide PPTX | Missing | 180-second pitch — one slide only |
| Demo plan for 5-minute demonstration | Missing | Script the demo sequence |

---

## Recommended Actions Before Submission

**Priority 1 — Core compliance (Days 1-6):**
1. Implement `core/logger.sh` with exact log format first — all teammates depend on it
2. Implement `core/errors.sh` with `die()` calling `show_help()` always
3. Implement `helpers/fork_helper.c` and `helpers/thread_helper.c`
4. Implement option parsing with `getopts` in `envctr`
5. Implement `-r` with `[[ $EUID -ne 0 ]]` check

**Priority 2 — Feature implementation (Days 4-8):**
1. `core/fingerprint.sh` — stack detection
2. `backends/docker.sh`, `backends/chroot.sh`, `backends/qemu.sh`
3. `core/lock.sh` — lockfile generation and parsing
4. `core/drift.sh` — drift detection
5. `core/explain.sh` — Mistral API integration

**Priority 3 — Testing and submission (Days 8-10):**
1. Three test scenario scripts
2. PDF report with screenshots
3. One-slide PPTX
4. Final ZIP packaging

---

## Current Verdict

envctr is architecturally sound and fully planned. All professor requirements
are mapped to specific implementation targets. No requirement is missing from
the design. Execution starts immediately on Day 1.
