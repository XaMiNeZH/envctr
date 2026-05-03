# Test Scenarios

The `tests/` directory contains the three scenarios required by the project
specification plus one extra scenario for drift detection demonstration. Each
test script creates its own isolated environment, so the repository stays clean
after tests finish.

All three required scenarios directly demonstrate the fork, subshell, and thread
execution modes. Each scenario is associated with a workload level as specified
in the project PDF.

---

## Scenario 1 — Light (Subshell)

```bash
./tests/test_light.sh
```

**Workload:** Light
**Execution mode:** `-s` subshell
**Backend:** chroot
**Project type:** Python Flask — single service, no database

What this tests:
- Fingerprint detection of a Python project via `requirements.txt`
- chroot backend provisioning from a clean state
- Full pipeline running inside an isolated Bash subshell `( ... )`
- Lockfile generation after successful provisioning
- Logging to `/var/log/envctr/history.log` with correct format
- Error handling when chroot directory already exists

Expected output:

```text
[FINGERPRINT] Detected: python 3.11 -- no external services
[PROVISION]   Backend: chroot
[PROVISION]   Mode: subshell
[LOCK]        Lockfile written: ./examples/flask-simple/envctr.lock
[OK]          Environment ready
```

Expected time: under 10 seconds

---

## Scenario 2 — Medium (Fork)

```bash
./tests/test_medium.sh
```

**Workload:** Medium
**Execution mode:** `-f` fork
**Backend:** Docker
**Project type:** Node.js API with PostgreSQL 15 and Redis 7

What this tests:
- Fingerprint detection of a Node project via `package.json`
- Detection of PostgreSQL from `knexfile.js` and Redis from config
- Docker backend provisioning
- Three child processes forked simultaneously via `fork_helper.c`:
  - Child 1: provisions PostgreSQL container
  - Child 2: provisions Redis container
  - Child 3: provisions Node runtime container
- Parent waits for all children with `waitpid()`
- Lockfile captures all three services
- Drift detection after manual change simulation

Expected output:

```text
[FINGERPRINT] Detected: node 18.17.1 -- services: postgresql, redis
[PROVISION]   Backend: docker
[PROVISION]   Mode: fork
[FORK]        PID 12341 -- provisioning postgresql
[FORK]        PID 12342 -- provisioning redis
[FORK]        PID 12343 -- provisioning node runtime
[FORK]        All child processes completed successfully
[LOCK]        Lockfile written: ./examples/node-api/envctr.lock
[OK]          Environment ready
```

Expected time: under 20 seconds

---

## Scenario 3 — Heavy (Threads)

```bash
./tests/test_heavy.sh
```

**Workload:** Heavy
**Execution mode:** `-t` threads
**Backend:** Docker
**Project type:** Microservices monorepo — 8 independent services

What this tests:
- Fingerprint detection across multiple sub-projects in a monorepo
- Docker backend with 8 simultaneous container provisions
- Real pthreads via `thread_helper.c` compiled with `-lpthread`
- Thread synchronization — all threads joined before lockfile is written
- Drift detection after heavy provisioning
- Mistral API drift explanation via `-e` flag

Services provisioned in parallel:
1. `api-gateway` — Node 18
2. `auth-service` — Python 3.11
3. `user-service` — Node 18
4. `product-service` — Python 3.11
5. `order-service` — Node 18
6. `notification-service` — Node 18
7. `postgresql` — version 15.3
8. `redis` — version 7.2.1

Expected output:

```text
[FINGERPRINT] Detected: monorepo -- 6 app services + 2 infrastructure services
[PROVISION]   Backend: docker
[PROVISION]   Mode: threads (8 threads)
[THREAD]      Thread 1 -- api-gateway
[THREAD]      Thread 2 -- auth-service
[THREAD]      Thread 3 -- user-service
[THREAD]      Thread 4 -- product-service
[THREAD]      Thread 5 -- order-service
[THREAD]      Thread 6 -- notification-service
[THREAD]      Thread 7 -- postgresql
[THREAD]      Thread 8 -- redis
[THREAD]      All threads joined successfully
[LOCK]        Lockfile written: ./examples/microservices-monorepo/envctr.lock
[OK]          Environment ready -- 8 services running
```

Followed by drift detection demonstration:

```bash
envctr --drift -e -p ./examples/microservices-monorepo
```

Expected time: under 40 seconds provisioning, under 10 seconds drift scan

---

## Extra Scenario — Drift Detection + Mistral Explanation

```bash
./tests/test_drift.sh
```

This scenario is not required by the project PDF but is included to demonstrate
the drift detection and Mistral API explanation features in isolation.

What this tests:
- Provision a small environment and generate a lockfile
- Simulate drift by manually mutating the environment
- Run `envctr --drift` and verify the report classifies changes correctly
- Run `envctr --drift -e` and verify Mistral API returns an explanation
- Run `envctr --restore` and verify the environment matches the lockfile again

Drift mutations simulated:
- Change Node runtime version (BREAKING)
- Stop Redis container (BREAKING)
- Change app port (WARNING)
- Manually install a package inside the container (WARNING)

---

## Run All Scenarios

```bash
./tests/run_all.sh
```

Runtime logs are written to `/var/log/envctr/history.log`. Test artifacts are
written to `tests/tmp/` and cleaned up after each run.

---

## Performance Comparison

| Mode | Scenario | Services | Expected time |
|---|---|---|---|
| `-s` Subshell | Light — chroot, Flask | 1 | ~8s |
| `-f` Fork | Medium — Docker, Node+DB | 3 | ~18s |
| `-t` Threads | Heavy — Docker, monorepo | 8 | ~35s |
| Sequential (no flag) | Heavy — Docker, monorepo | 8 | ~120s |

The sequential baseline in the heavy scenario demonstrates the performance gain
from thread parallelism — roughly 3x faster for 8 services.
