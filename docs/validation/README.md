# Validation Evidence

This directory contains sanitized terminal captures from the final `envctr`
validation run before the `dev` branch was merged into `main` for `v1.0.0`.

Local machine details were redacted from the captures:

- the WSL username is shown as `<user>`
- the local checkout path is shown as `<repo>`

## Environment

- Platform: WSL Ubuntu on Windows
- Release branch flow: `dev` -> `main`
- Release PR: <https://github.com/XaMiNeZH/envctr/pull/10>
- Release tag: `v1.0.0`

## Checks Captured

1. [`01-help.png`](screenshots/01-help.png) - `./envctr -h`
2. [`02-error-101.png`](screenshots/02-error-101.png) - missing `-p` error handling
3. [`03-light-scenario.png`](screenshots/03-light-scenario.png) - light scenario with `-s`
4. [`04-medium-scenario.png`](screenshots/04-medium-scenario.png) - medium scenario with `-f`
5. [`05-heavy-scenario.png`](screenshots/05-heavy-scenario.png) - heavy scenario with `-t`
6. [`06-flask-lockfile.png`](screenshots/06-flask-lockfile.png) - Flask lockfile format
7. [`07-history-log.png`](screenshots/07-history-log.png) - `history.log` format
8. [`08-run-all-results.png`](screenshots/08-run-all-results.png) - full suite result summary

## Result

The final validation passed:

- C helpers compiled successfully with `gcc`
- help and error handling smoke tests passed
- light, medium, and heavy manual scenarios exited `0`
- immediate drift detection reported no drift
- `bash tests/run_all.sh` reported `3 passed, 0 failed`
- `bash -n` syntax checks passed for all scripts
- log lines matched `yyyy-mm-dd-hh-mm-ss : username : INFOS|ERROR : message`
- `-r` correctly exited with error `111` for a non-root user
