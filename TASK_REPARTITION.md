# Task Repartition

Project: envctr
Team size: 4
Deadline: 14/05/2026 23:59:59
Start date: 04/05/2026

---

## Team Overview

| Member                | Role             | Linux level  | GitHub handle  |
| --------------------- | ---------------- | ------------ | -------------- |
| EZ-ZAHERY Ahmed Amine | Lead architect   | Advanced     | @XaMiNeZH      |
| Marwa MACHACH         | Backend systems  | Advanced     | @marwamachach  |
| ALAMI Yassine         | Frontend/docs    | Intermediate | @Yassine-Al    |
| Hicham AZENKOUK       | Testing/examples | Beginner     | @aazenkouk-dev |

---

## Days 1-3 History

```text
Day 01 (04/05) - Repo setup, shared foundations, everyone reads the spec
Day 02 (05/05) - Core infrastructure: logger, errors, option parsing
Day 03 (06/05) - Fingerprint engine + C helpers
```

Completed or pending-review history:

- `core/logger.sh` is met and merged in PR #1.
- `core/fingerprint.sh` is met in PR #2 and pending merge.
- `envctr`, `core/errors.sh`, `helpers/fork_helper.c`, and `helpers/thread_helper.c` are met in PR #3 and pending merge.
- Project scope was simplified to fingerprint, lock, drift, and Mistral explanation only.

---

## Remaining Timeline

```text
Day 04 (07/05) - Review PR #2 and PR #3, backend stubs, scope cleanup
Day 05 (08/05) - lock.sh implementation and drift.sh start
Day 06 (09/05) - drift.sh completion and explain.sh implementation
Day 07 (10/05) - Example projects and test scripts
Day 08 (11/05) - Integration testing, bug fixes, final CLI verification
Day 09 (12/05) - PDF report and PPTX slide
Day 10 (13/05) - Final review, ZIP packaging, submission rehearsal
```

---

## Person 1 - XaMiNeZH (Lead Architect)

**Owns:** PR reviews, `envctr` integration, backend stubs, final technical review

**Day 4 onward tasks:**

1. Review and merge PR #2 for `core/fingerprint.sh`.
2. Review and merge PR #3 for `envctr`, `core/errors.sh`, `helpers/fork_helper.c`, and `helpers/thread_helper.c`.
3. Implement `backends/docker.sh`, `backends/qemu.sh`, and `backends/chroot.sh` as stubs:
   - Each script logs the selected backend.
   - Each script exits `0`.
   - No script performs backend setup.
4. Update the main `envctr` script only if needed after the simplified scope:
   - `-b` records backend intent in `envctr.lock`.
   - `-f` and `-t` run fingerprinting pipeline work through the C helpers.
   - No provisioning path remains in the CLI flow.
5. Run integration checks after `lock.sh`, `drift.sh`, and `explain.sh` are merged.
6. Validate that log format and error behavior remain compliant with the professor requirements.

---

## Person 2 - marwamachach (Backend systems)

**Owns:** `core/fingerprint.sh` final fixes and `core/lock.sh`

**Day 4 onward tasks:**

1. Fix PR #2 inline review comments.
2. Confirm `fingerprint()` exports stable variables for:
   - detected runtime
   - detected runtime version
   - detected services
   - detected ports
   - detected environment variable names
   - detected project metadata
3. Implement `core/lock.sh`.
4. `core/lock.sh` must generate `envctr.lock` from the exported variables of `fingerprint()`.
5. Lockfile must include:
   - `[meta]`
   - `[runtime]`
   - `[services]`
   - `[ports]`
   - `[environment]`
   - `[backend]`
6. The `[backend]` section records the selected backend label only.
7. Add a parser function if needed by `core/drift.sh`.

---

## Person 3 - Yassine-Al (Core drift and explain)

**Owns:** `core/drift.sh`, `core/explain.sh`

**Day 4 onward tasks:**

1. Implement `core/drift.sh`.
2. `core/drift.sh` must:
   - read `envctr.lock`
   - run `fingerprint()` again on the project directory
   - compare lockfile fields against current fingerprint fields
   - print a report classified as `BREAKING`, `WARNING`, or `INFO`
3. Suggested classification:
   - `BREAKING`: runtime language/version changes, removed required service, removed required env var
   - `WARNING`: port changes, added service hints, backend metadata changes
   - `INFO`: added env var names, added optional metadata, timestamp-only changes
4. Implement `core/explain.sh`.
5. `core/explain.sh` must:
   - take the drift report as input
   - require `MISTRAL_API_KEY`
   - use `curl` to call `MISTRAL_API_URL`
   - default `MISTRAL_MODEL` to `mistral-small-latest`
   - print the explanation returned by the API
   - degrade gracefully with error `110` when explanation is unavailable

---

## Person 4 - aazenkouk-dev (Testing/examples)

**Owns:** Example projects and test scripts

**Day 4 onward tasks:**

1. Create `examples/flask-simple/`:
   - minimal Flask app
   - `requirements.txt`
   - no external service requirement
   - used by the light test
2. Create `examples/microservices-monorepo/`:
   - 6 subdirectories
   - mix of small Node/Python service metadata
   - top-level README or manifest if useful for fingerprinting
   - used by the heavy test
3. Keep `examples/node-api/` as the medium fingerprinting target if it already exists; otherwise create a minimal version after the two required examples.
4. Write `tests/test_light.sh`:
   - runs `envctr -s -b chroot -p ./examples/flask-simple`
   - verifies `envctr.lock` exists
   - runs drift detection
5. Write `tests/test_medium.sh`:
   - runs `envctr -f -b docker -p ./examples/node-api`
   - verifies lockfile content for Node, ports, env vars, and backend label
   - runs drift detection
6. Write `tests/test_heavy.sh`:
   - runs `envctr -t -b docker -p ./examples/microservices-monorepo`
   - verifies lockfile content across subdirectories
   - runs drift detection and optional explanation when `MISTRAL_API_KEY` is set
7. Write `tests/run_all.sh`:
   - runs light, medium, and heavy tests
   - reports `PASS` or `FAIL`
   - exits non-zero if any scenario fails

---

## Shared Responsibilities

### GitHub workflow

- Create a feature branch for every task.
- Commit frequently with clear messages:

```text
feat: add lockfile generation
feat: add drift comparison
feat: add mistral drift explanation
test: add simplified scope scenarios
docs: update final report materials
```

- Open PRs into `dev`.
- XaMiNeZH reviews before merge.

### Communication

- Post a daily status update.
- Report blockers immediately if blocked for more than 2 hours.
- Keep the simplified scope visible in every PR: no direct environment setup.

---

## Critical Path

1. Merge PR #2 and PR #3.
2. Stub backend scripts.
3. Implement `core/lock.sh`.
4. Implement `core/drift.sh`.
5. Implement `core/explain.sh`.
6. Add examples and tests.
7. Write PDF/PPTX and package ZIP.

The lockfile format is the main dependency. Drift and tests should not finalize until `core/lock.sh` is stable.

---

## Risk Register

| Risk | Likelihood | Impact | Priority | Mitigation |
|---|---|---|---|---|
| PR #2 or PR #3 merge delay | Medium | High | High | Ahmed reviews immediately and requests only blocking fixes. |
| Lockfile format changes late | Medium | High | High | Marwa publishes format early; Person 3 and Person 4 build against it. |
| Time pressure on PDF/PPTX | High | High | High | Start report and slide outline before final code freeze; collect screenshots during tests. |
| Mistral API key issue | Low | Low | Medium | `core/explain.sh` degrades gracefully and raw drift report remains valid. |
| C helper compilation fails on teammate machines | Medium | Medium | Medium | Ahmed verifies compile steps and documents fallback behavior. |
| Log format not exact | Medium | High | High | Keep `core/logger.sh` unchanged after PR #1 unless a compliance bug is found. |
| Beginner teammate blocked on tests | High | Medium | Medium | Provide exact expected lockfile fields and one working sample test first. |
