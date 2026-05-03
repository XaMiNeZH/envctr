# Task Repartition

Project: envctr
Team size: 4
Deadline: 14/05/2026 23:59:59
Start date: 04/05/2026

---

## Team Overview

| Member | Role | Linux level | GitHub handle |
|---|---|---|---|
| Ahmed (you) | Lead architect | Advanced | @XaMiNeZH |
| Teammate 2 | Backend systems | Intermediate | TBD |
| Teammate 3 (the girl) | Frontend/docs | Beginner — motivated | TBD |
| Teammate 4 | Testing/examples | Beginner | TBD |

---

## 10-Day Timeline

```
Day 01 (04/05) — Repo setup, shared foundations, everyone reads the spec
Day 02 (05/05) — Core infrastructure: logger, errors, option parsing
Day 03 (06/05) — Fingerprint engine + C helpers
Day 04 (07/05) — Docker backend + lock.sh
Day 05 (08/05) — chroot backend + qemu backend skeleton
Day 06 (09/05) — drift.sh + explain.sh (Mistral)
Day 07 (10/05) — Test scenarios + example projects
Day 08 (11/05) — Integration testing, bug fixes
Day 09 (12/05) — PDF report + PPTX slide
Day 10 (13/05) — Final review, ZIP packaging, submission
```

---

## Person 1 — Ahmed (Lead Architect)

**Owns:** `envctr` (main script), `core/errors.sh`, `helpers/fork_helper.c`,
`helpers/thread_helper.c`, `backends/qemu.sh`, integration, PR reviews

**Why:** You designed the idea. You have Docker/QEMU experience from Docker-OSX.
You are the only one who can own the C helpers and QEMU backend confidently.
You also review every PR before merge to `dev`.

### Day 1-2

- Set up the GitHub repo structure (all folders, empty files, .gitignore)
- Write `VERSION`, `CHANGELOG.md`, push initial commit tagged `v0.1.0`
- Write the main `envctr` script skeleton:
  - Shebang, set -e, set -o pipefail
  - Source all core files
  - `getopts` option parsing loop for `-h -f -t -s -l -r -b -p -e`
  - Long option parsing loop for `--drift --from-lock --restore --update-lock --dry-run --export --no-provision`
  - Mandatory parameter check for `-p` (die 101 if missing)
  - Mode variable: `MODE="sequential"` default, overridden by `-s/-f/-t`
  - Route to correct execution mode after option parsing
- Write `core/errors.sh`:
  - All 13 error codes as variables (`ERR_UNKNOWN_OPT=100`, etc.)
  - `die()` function: log ERROR, call `show_help()`, exit with code
  - `show_help()` function: full man-page style documentation to stdout
  - `check_root()` function: `[[ $EUID -ne 0 ]] && die 111`

### Day 3

- Write `helpers/fork_helper.c`:
  - Accepts array of service provision commands as arguments
  - Forks one child per service using `fork()`
  - Each child runs its provision command via `execl("/bin/bash", ...)`
  - Parent collects all PIDs and waits with `waitpid()`
  - Returns 0 only if all children exit 0
  - Compile target: `helpers/fork_helper`
- Write `helpers/thread_helper.c`:
  - Accepts array of service provision commands as arguments
  - Spawns one pthread per service
  - Each thread runs its command via `system()`
  - All threads joined before return
  - Returns 0 only if all threads complete without error
  - Compile target: `helpers/thread_helper`
  - Compile with `-lpthread`
- Update `Makefile` or add compile instructions to `envctr` startup check

### Day 5

- Write `backends/qemu.sh`:
  - Check `/dev/kvm` accessible, die 108 if not
  - Boot minimal Linux VM via `qemu-system-x86_64` with KVM acceleration
  - Wait for SSH to be ready on localhost:2222
  - Mount project directory via virtfs or sshfs
  - Configure port forwarding
  - Write VM state to lockfile
  - Cleanup on exit

### Day 8

- Integration testing across all three scenarios
- Fix any cross-file bugs
- Review all PRs and merge to `main`
- Verify log format is exactly correct in all outputs
- Verify `-r` destroys environment and resets config correctly

---

## Person 2 — Teammate (Intermediate Linux)

**Owns:** `core/fingerprint.sh`, `backends/docker.sh`, `core/lock.sh`

**Why:** Fingerprinting and Docker are the most technically demanding Bash
parts after the C helpers. This person has enough Linux background to handle
regex-heavy Bash and Docker API calls.

### Day 2-3

Write `core/logger.sh` first — everyone depends on it:
- `log_message()` function takes two args: `TYPE` (INFOS or ERROR) and `MSG`
- Gets timestamp via `date +"%Y-%m-%d-%H-%M-%S"`
- Gets username via `whoami`
- Formats: `$TIMESTAMP : $USER : $TYPE : $MSG`
- Outputs via `echo "$LINE" | tee -a "$LOG_FILE"`
- Creates `$LOG_DIR` if it does not exist
- `LOG_FILE="$LOG_DIR/history.log"` — default `/var/log/envctr/history.log`

**This function must be working and pushed before anyone else writes a single
line of feature code.** Every other file calls `log_message()`.

### Day 3-4

Write `core/fingerprint.sh`:
- `fingerprint()` function takes project directory as argument
- Check for `Dockerfile` first — if exists, read it directly and skip inference
- Detect runtime from manifest files using `grep`, `awk`, `sed`:
  - `package.json` → Node.js, extract version from `engines.node`
  - `requirements.txt` / `pyproject.toml` → Python
  - `Makefile` + `*.c` → C/C++
  - `pom.xml` / `build.gradle` → Java
  - `Cargo.toml` → Rust
  - `go.mod` → Go
- Detect services from config files:
  - `knexfile.js`, `database.yml`, `alembic.ini` → database type
  - `redis` in any config → Redis
- Detect ports by scanning `.env` files with regex `PORT=([0-9]+)`
- Detect required env var names from `.env.example`
- Export all findings as variables: `DETECTED_RUNTIME`, `DETECTED_SERVICES`,
  `DETECTED_PORTS`, `DETECTED_ENV_VARS`
- Call `log_message "INFOS" "Fingerprinting complete -- detected: $DETECTED_RUNTIME"`

### Day 4

Write `backends/docker.sh`:
- `provision_docker()` function
- Check `docker` binary exists, die 112 if not
- Check Docker daemon running (`docker info`), die 104 if not
- Pull or build base image from detected runtime
- `docker network create envctr-net` if not exists
- Start service containers with correct port bindings and volume mounts
- Wait for containers to be healthy
- Call `log_message` at each step

Write `core/lock.sh`:
- `generate_lock()` — writes `envctr.lock` from detected/provisioned state
- `parse_lock()` — reads `envctr.lock` into variables
- `lock_exists()` — returns 0 if lockfile present and valid
- Format must match spec exactly (INI-style sections)

---

## Person 3 — Teammate (Beginner, motivated)

**Owns:** `core/drift.sh`, `core/explain.sh`, `backends/chroot.sh`, `docs/`

**Why:** Drift detection is algorithmically clear (read lock, read live state,
diff field by field) and does not require deep Linux knowledge. The chroot
backend is well-documented and simpler than Docker or QEMU. Docs are critical
and require care and writing ability.

### Day 2

Read and understand:
- `envctr_project_specification.md` completely
- `MINI_PROJET_REQUIREMENTS_TRACKER.md` completely
- `USAGE.md` completely
- The project PDF guidelines

This person must understand the full picture before writing a line.

### Day 3-4

Write `backends/chroot.sh`:
- `provision_chroot()` function
- Check `debootstrap` available
- Create jail directory at `$CHROOT_BASE_DIR/$PROJECT_NAME`
- Run `debootstrap` to create minimal filesystem (or use pre-built tarball)
- Install detected runtime inside jail via `chroot $JAIL_DIR apt-get install ...`
- Bind-mount project directory into jail
- Write jail path to lockfile
- Clean up on exit or `-r`

### Day 5-6

Write `core/drift.sh`:
- `detect_drift()` function takes project directory as argument
- Call `parse_lock()` to load declared state
- Query live environment for each field:
  - Docker: `docker inspect`, `docker ps`, `pip list` or `npm list`
  - Compare each field to lockfile value
- Classify each difference:
  - BREAKING: runtime version mismatch, missing service
  - WARNING: port change, manually installed package
  - INFO: env var added but not in original lock
- Print formatted drift report to stdout and log
- Exit with code 109 if any drift found

Write `core/explain.sh`:
- `explain_drift()` takes the drift report as input
- Check `MISTRAL_API_KEY` is set, log error 110 and return if not
- Check Mistral API reachable via `curl -s`, log error 110 and return if not
- Build JSON payload with drift report as user message
- Call `curl -s -X POST https://api.mistral.ai/v1/chat/completions` with API key header
- Parse response and print explanation
- Log `log_message "INFOS" "Mistral explanation received"`

### Day 7

Create `examples/flask-simple/`:
- `app.py` — minimal Flask hello world
- `requirements.txt` — flask==3.0.0
- No database, no external services
- Must be fingerprinted cleanly by `core/fingerprint.sh`

Update all docs in `docs/`:
- Keep `USAGE.md`, `TEST_SCENARIOS.md`, `VERSIONING.md` up to date as
  implementation changes
- Write the `-h` help text that will go inside `show_help()` — Linux man-page
  style, plain text, clear sections

---

## Person 4 — Teammate (Beginner)

**Owns:** Test scripts, example projects (node-api, microservices-monorepo),
final submission packaging

**Why:** Test scripts and example projects are well-specified, require basic
Bash knowledge, and have clear success criteria. This person can work from
the test scenario document without needing to understand the full codebase.

### Day 2

Read:
- `TEST_SCENARIOS.md` completely
- `USAGE.md` — the quick start and common commands sections
- Study how PipePilot's `tests/test_light.sh` is structured as a reference

### Day 3-4

Create `examples/node-api/`:
- `package.json` with `engines.node = "18"`, no build script
- `index.js` — minimal Express server on port 3000
- `knexfile.js` — PostgreSQL connection config (localhost:5432)
- `.env.example` — `DATABASE_URL`, `REDIS_URL`, `PORT`, `JWT_SECRET`
- Must fingerprint as: node 18, postgresql, redis

### Day 5-6

Create `examples/microservices-monorepo/`:
- 6 app service subdirectories (mix of Node and Python)
- Each with its own `package.json` or `requirements.txt`
- Top-level README explaining the monorepo structure
- Must fingerprint as: monorepo with 8 services total

### Day 7

Write test scripts:

`tests/test_light.sh`:
- Create temp dir, copy `examples/flask-simple/` into it
- Run `envctr -s -b chroot -p $TMPDIR/flask-simple`
- Verify lockfile was created
- Verify log entries exist in `/var/log/envctr/history.log`
- Verify exit code 0
- Clean up temp dir

`tests/test_medium.sh`:
- Create temp dir, copy `examples/node-api/` into it
- Run `envctr -f -b docker -p $TMPDIR/node-api`
- Verify lockfile captures postgresql and redis
- Verify 3 fork processes were reported in log
- Verify exit code 0

`tests/test_heavy.sh`:
- Create temp dir, copy `examples/microservices-monorepo/` into it
- Run `envctr -t -b docker -p $TMPDIR/microservices-monorepo`
- Verify all 8 services provisioned
- Verify thread completion reported in log
- Run drift detection after
- Verify exit code 0

`tests/run_all.sh`:
- Runs all three in sequence
- Reports PASS/FAIL for each
- Exits 0 only if all pass

### Day 9

Package final submission:
- `TeamID-devoir-shell.pdf` — collect from Person 3's report draft
- `TeamID-devoir-shell.pptx` — collect from Ahmed's slide
- All scripts with correct permissions (`chmod +x`)
- Create `TeamID-devoir-shell.zip` with correct structure

---

## Shared Responsibilities

### GitHub workflow (everyone)

- Create a feature branch for every task: `feature/logger`, `feature/fingerprint`, etc.
- Commit frequently with clear messages: `feat: add log_message() with tee output`
- Open a PR into `dev` when the feature is ready
- Ahmed reviews and merges

### Communication (everyone)

- WhatsApp group for daily status updates
- Post a message every evening: what you finished, what is blocked
- If blocked for more than 2 hours, post immediately — do not wait

### Commit message format

```
feat: <what was added>
fix: <what was fixed>
docs: <documentation update>
test: <test script added or updated>
chore: <setup, config, packaging>
```

---

## Critical Path

These items block everything else. They must be done first, in order:

1. **Ahmed** — repo structure, all empty files, first commit pushed
2. **Person 2** — `core/logger.sh` with `log_message()` working and pushed
3. **Ahmed** — `core/errors.sh` with `die()` and `show_help()` working
4. **Ahmed** — `envctr` main script option parsing working

Only after these four items are done can anyone else begin their features.
Estimated time for the critical path: end of Day 2.

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| QEMU backend too complex in time | Medium | Low | QEMU is owned by Ahmed; Docker and chroot are enough for all three test scenarios. QEMU is a bonus. |
| Beginner teammates blocked | High | Medium | Person 3 and Person 4 tasks are designed to not require understanding of the full system. If blocked, Ahmed unblocks immediately. |
| Mistral API key issue | Low | Low | Feature degrades gracefully. Not in critical path. |
| C helper compilation fails on teammate machines | Medium | Medium | Ahmed compiles and commits the binaries. Teammates don't need to compile. |
| Log format not exact | Medium | High | Person 2 writes `logger.sh` first and Ahmed reviews it before anyone else uses it. |
| Time runs out before PDF/PPTX | Medium | High | Person 3 starts the report outline on Day 7 alongside test writing. Do not leave to Day 9. |
