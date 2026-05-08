# Test Scenarios

The required scenarios demonstrate fingerprinting, lockfile generation, and
drift detection across the three execution modes. Backends are metadata labels
only and are recorded in `envctr.lock`.

Run all scenarios:

```bash
bash tests/run_all.sh
```

The scripts copy example projects into `tests/tmp/`, set a temporary `LOG_DIR`,
run `envctr`, verify lockfile and drift output, and clean up.

## Light: Flask Simple

```bash
bash tests/test_light.sh
```

Expected command shape:

```bash
envctr -s -b chroot -p ./examples/flask-simple
envctr --drift -s -b chroot -p ./examples/flask-simple
```

This scenario verifies Python fingerprinting through `requirements.txt`,
subshell mode, chroot backend metadata recording, lockfile generation, and a
clean no-drift comparison.

## Medium: Node API

```bash
bash tests/test_medium.sh
```

Expected command shape:

```bash
envctr -f -b docker -p ./examples/node-api
envctr --drift -f -b docker -p ./examples/node-api
```

This scenario verifies Node fingerprinting through `package.json`, PostgreSQL
and Redis service hints, fork helper execution, Docker backend metadata
recording, lockfile generation, and a clean no-drift comparison.

## Heavy: Microservices Monorepo

```bash
bash tests/test_heavy.sh
```

Expected command shape:

```bash
envctr -t -b docker -p ./examples/microservices-monorepo
envctr --drift -t -b docker -p ./examples/microservices-monorepo
```

This scenario verifies a larger repository shape, thread helper execution,
Docker backend metadata recording, lockfile generation, and a clean no-drift
comparison.

## Drift Demonstration

To demonstrate drift manually, generate a lockfile, edit a project signal such
as `.env.example` or `package.json`, then rerun:

```bash
envctr --drift -b docker -p ./examples/node-api
```

Expected drift output is severity-classified with `BREAKING`, `WARNING`, and
`INFO` sections when matching fields changed.
