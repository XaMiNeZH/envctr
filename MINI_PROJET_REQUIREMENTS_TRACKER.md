# Mini Projet Requirements Tracker

Audit date: 2026-05-08
Project: envctr
Main script: `envctr`

Legend:

- `Met` - implemented or completed in the referenced PR
- `Planned` - required and assigned, not implemented yet
- `Missing` - required deliverable not found yet

---

## Overall Status

envctr has been simplified to four features only:

1. Fingerprint a project directory.
2. Write `envctr.lock`.
3. Detect drift between the lockfile and the current fingerprint.
4. Explain drift through the Mistral API.

The backend option `-b` remains in the CLI, but it only records intended backend metadata in the lockfile. Backend scripts are stubs and do not implement Docker, QEMU, or chroot setup.

---

## 1. Project Objective

| Requirement | Status | Evidence | Notes |
|---|---|---|---|
| Automate standard Unix/Linux processes | Planned | `envctr_project_specification.md` | Automates fingerprinting, lockfile generation, drift detection, and optional explanation |
| Address a real user need for developers or sysadmins | Planned | `README.md` | Captures project state and detects documentation drift |
| Main shell script deliverable | Met | `envctr` | Met in PR #3, pending merge |
| PDF report `TeamID-devoir-shell.pdf` | Missing | - | Due before 14/05/2026 |
| One-slide PPTX `TeamID-devoir-shell.pptx` | Missing | - | Due before 14/05/2026 |
| ZIP `TeamID-devoir-shell.zip` | Missing | - | Due before 14/05/2026 |

---

## 2. Script Technical Requirements

| Requirement | Status | Evidence | Notes |
|---|---|---|---|
| Developed primarily in Bash | Met | `envctr`, `core/*.sh`, `backends/*.sh` | Main script and shell modules are covered in PR #3; logger merged in PR #1 |
| May call external Bash or C scripts | Met | `helpers/fork_helper.c`, `helpers/thread_helper.c` | Met in PR #3, pending merge |
| `core/logger.sh` | Met | `core/logger.sh` | Merged in PR #1 |
| `core/fingerprint.sh` | Met | `core/fingerprint.sh` | In PR #2, pending merge |
| `core/errors.sh` | Met | `core/errors.sh` | In PR #3, pending merge |
| Main `envctr` script | Met | `envctr` | In PR #3, pending merge |
| `helpers/fork_helper.c` | Met | `helpers/fork_helper.c` | In PR #3, pending merge |
| `helpers/thread_helper.c` | Met | `helpers/thread_helper.c` | In PR #3, pending merge |
| `core/lock.sh` | Planned | `core/lock.sh` | Generates `envctr.lock` from exported fingerprint variables |
| `core/drift.sh` | Planned | `core/drift.sh` | Compares lockfile fields against current fingerprint |
| `core/explain.sh` | Planned | `core/explain.sh` | Calls Mistral API with drift report input |
| Backend scripts | Planned | `backends/*.sh` | Simplified stubs; record intended backend only |
| Unix/Linux commands | Planned | See section 2.1 | Final list depends on lock, drift, and explain implementations |
| Conditions | Met | `envctr`, `core/errors.sh` | Option checks and error flow in PR #3, pending merge |
| Loops | Met | `core/fingerprint.sh` | Fingerprint scans in PR #2, pending merge |
| Functions | Met | `core/*.sh` | Logger merged; fingerprint/errors/main functions pending merge |
| Environment variables | Planned | `configs/default.conf`, exported fingerprint variables | Mistral config kept; fingerprint exports in PR #2 |
| Regular expressions | Met | `core/fingerprint.sh` | In PR #2, pending merge |
| File manipulation | Planned | `core/lock.sh`, `core/drift.sh`, `core/logger.sh` | Logging met; lock/drift planned |
| Search and filtering | Met | `core/fingerprint.sh` | In PR #2, pending merge |
| Access control | Met | `core/errors.sh`, `envctr` | `-r` admin check in PR #3, pending merge |
| Pipes and filters | Met | `core/fingerprint.sh`, `core/logger.sh` | Logger uses `tee`; fingerprint pipeline in PR #2 |
| At least one mandatory parameter | Met | `envctr` | `-p <directory>` in PR #3, pending merge |

### 2.1 Unix/Linux Commands Used

Current and planned command set:

`find`, `grep`, `awk`, `sed`, `tee`, `curl`, `diff`, `stat`, `wc`, `sort`,
`uniq`, `file`, `env`, `chmod`, `mkdir`, `rm`, `cp`, `cat`, `echo`, `date`,
`whoami`, `basename`, `dirname`

Docker, QEMU, and chroot are not implementation dependencies in the simplified scope. Their names may appear only as backend labels recorded in the lockfile.

---

## 3. Mandatory Options

| Option | Required meaning | Status | Implementation | Notes |
|---|---|---|---|---|
| `-h` | Help / full documentation | Met | `show_help()` in `core/errors.sh` | In PR #3, pending merge |
| `-f` | Fork execution | Met | `helpers/fork_helper.c` | In PR #3, pending merge; runs fingerprinting pipeline work |
| `-t` | Thread execution | Met | `helpers/thread_helper.c` | In PR #3, pending merge; runs fingerprinting pipeline work |
| `-s` | Subshell execution | Met | `( envctr_pipeline )` in `envctr` | In PR #3, pending merge |
| `-l <dir>` | Custom log directory | Met | Overrides `LOG_DIR` | In PR #3, pending merge |
| `-r` | Reset defaults, admin only | Met | `check_root()` guard | In PR #3, pending merge |

**Note on `-f` and `-t`:** The C helpers remain part of the project. They now support parallel fingerprinting pipeline execution, not service provisioning.

**Note on `-b`:** `-b docker`, `-b qemu`, and `-b chroot` are accepted as backend intent labels. They are recorded in `envctr.lock` only.

---

## 4. Logging

| Requirement | Status | Evidence | Notes |
|---|---|---|---|
| STDOUT and STDERR to terminal AND log simultaneously | Met | `tee -a "$LOG_FILE"` in `core/logger.sh` | Merged in PR #1 |
| Log file named `history.log` | Met | `LOG_FILE="$LOG_DIR/history.log"` | Merged in PR #1 |
| Default path `/var/log/envctr/history.log` | Met | `core/logger.sh` | Merged in PR #1 |
| Log format `yyyy-mm-dd-hh-mm-ss : username : INFOS : message` | Met | `core/logger.sh` | Exact format in PR #1 |
| Log format `yyyy-mm-dd-hh-mm-ss : username : ERROR : message` | Met | `core/logger.sh` | Exact format in PR #1 |

---

## 5. Error Handling

| Requirement | Status | Evidence | Notes |
|---|---|---|---|
| Handles incorrect usage | Met | `die()` in `core/errors.sh` | In PR #3, pending merge |
| Specific error codes | Met | `core/errors.sh` | In PR #3, pending merge |
| Code 100 - unknown option | Met | `die 100` | In PR #3, pending merge |
| Code 101 - missing parameter | Met | `die 101` | In PR #3, pending merge |
| Help displayed after every triggered error | Met | `die()` calls `show_help()` | In PR #3, pending merge |

---

## 6. Core Feature Status

| Feature | Status | Evidence | Notes |
|---|---|---|---|
| Fingerprint | Met | `core/fingerprint.sh` | In PR #2, pending merge |
| Lock | Planned | `core/lock.sh` | To be implemented after PR #2 merge |
| Drift | Planned | `core/drift.sh` | To be implemented after lockfile format is stable |
| Explain | Planned | `core/explain.sh` | Mistral API via `curl`; depends on drift report |
| Backend recording | Planned | `backends/*.sh` | Stubs log backend selection and exit `0` |

---

## 7. Test Scenarios

| Requirement | Status | Evidence | Notes |
|---|---|---|---|
| Standard syntax `program [options] [parameter]` | Met | `envctr [options] -b <backend> -p <directory>` | In PR #3, pending merge |
| Light scenario | Planned | `tests/test_light.sh` | `flask-simple`; fingerprint + lock + drift under `-s` |
| Medium scenario | Planned | `tests/test_medium.sh` | `node-api`; fingerprint + lock + drift under `-f` |
| Heavy scenario | Planned | `tests/test_heavy.sh` | `microservices-monorepo`; fingerprint + lock + drift under `-t` |
| Aggregate test runner | Planned | `tests/run_all.sh` | Runs light, medium, and heavy tests |
| Subshell evaluation | Planned | `test_light.sh` | Demonstrates `-s` |
| Fork evaluation | Planned | `test_medium.sh` | Demonstrates `-f` and fork helper |
| Thread evaluation | Planned | `test_heavy.sh` | Demonstrates `-t` and pthread helper |

---

## 8. Documentation and Submission

| Requirement | Status | Notes |
|---|---|---|
| Internal `-h` documentation | Met | In PR #3, pending merge |
| `README.md` | Met | Updated for simplified scope |
| `envctr_project_specification.md` | Met | Updated for simplified scope |
| `TASK_REPARTITION.md` | Met | Updated for remaining work |
| Extended PDF report | Missing | Must include screenshots from the simplified test scenarios |
| One-slide PPTX | Missing | 180-second pitch, one slide only |
| Demo plan for 5-minute demonstration | Planned | Should use light, medium, and heavy tests |
| Final ZIP | Missing | Must include final scripts, PDF, PPTX, and required structure |

---

## Recommended Actions Before Submission

**Priority 1 - Merge current work:**

1. Review and merge PR #2 for `core/fingerprint.sh`.
2. Review and merge PR #3 for `envctr`, `core/errors.sh`, and C helpers.
3. Replace backend files with stubs that only log backend selection.

**Priority 2 - Implement remaining simplified scope:**

1. Implement `core/lock.sh`.
2. Implement `core/drift.sh`.
3. Implement `core/explain.sh`.
4. Wire the final pipeline in `envctr` after PR #2 and PR #3 are merged.

**Priority 3 - Testing and submission:**

1. Create `examples/flask-simple/`.
2. Create `examples/microservices-monorepo/`.
3. Write `tests/test_light.sh`, `tests/test_medium.sh`, `tests/test_heavy.sh`, and `tests/run_all.sh`.
4. Prepare PDF report, PPTX slide, and ZIP submission.

---

## Current Verdict

The project is partially implemented and the scope is now clear. Logger is merged, fingerprinting and CLI infrastructure are in pending PRs, and the remaining work is focused on lockfile generation, drift comparison, Mistral explanation, tests, and final submission documents.
