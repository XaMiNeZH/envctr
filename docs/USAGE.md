# envctr Usage Guide

```bash
envctr [options] -b <backend> -p <project_directory>
```

`envctr` fingerprints a project directory, writes `envctr.lock`, detects drift,
and can explain drift through the Mistral API. The backend option is metadata
only; `docker`, `qemu`, and `chroot` document the intended external strategy in
the lockfile and do not start containers, virtual machines, or chroot jails.

## Quick Start

```bash
envctr -b docker -p ./examples/node-api
envctr --drift -b docker -p ./examples/node-api
envctr --drift -e -b docker -p ./examples/node-api
```

## Required Parameters

`-p <directory>` identifies the project directory. Missing `-p` returns `101`
and displays help.

`-b <backend>` records backend intent. Supported values are `docker`, `qemu`,
and `chroot`. Unsupported labels return `104`.

## Mandatory Options

| Option | Behavior |
|---|---|
| `-h` | Display help and exit |
| `-f` | Run helper work through the C `fork_helper` |
| `-t` | Run helper work through the C `thread_helper` |
| `-s` | Run the pipeline in a Bash subshell |
| `-l <dir>` | Write `history.log` in a custom log directory |
| `-r` | Reset defaults; requires root and returns `111` without root |

## Additional Options

| Option | Behavior |
|---|---|
| `-e` | Explain a drift report through Mistral when used with `--drift` |
| `--from-lock` | Parse an existing lockfile before running |
| `--update-lock` | Regenerate `envctr.lock` after fingerprinting |
| `--drift` | Compare the current fingerprint with `envctr.lock` |
| `--restore` | Reserved for lockfile restoration workflows |
| `--dry-run` | Log planned actions without backend recording |
| `--export` | Reserved for export workflows |
| `--no-provision` | Skip backend stub logging |

## Examples

Light scenario:

```bash
envctr -s -b chroot -p ./examples/flask-simple
envctr --drift -s -b chroot -p ./examples/flask-simple
```

Medium scenario:

```bash
envctr -f -b docker -p ./examples/node-api
envctr --drift -f -b docker -p ./examples/node-api
```

Heavy scenario:

```bash
envctr -t -b docker -p ./examples/microservices-monorepo
envctr --drift -t -b docker -p ./examples/microservices-monorepo
```

## Logging

Logs are written to the terminal and to `history.log` using `tee -a`.

```text
yyyy-mm-dd-hh-mm-ss : username : INFOS : message
yyyy-mm-dd-hh-mm-ss : username : ERROR : message
```

The default log path is `/var/log/envctr/history.log`. Use `-l <dir>` or set
`LOG_DIR` to write somewhere else.

## Error Reference

| Code | Meaning |
|---|---|
| `100` | Unknown option |
| `101` | Mandatory parameter missing |
| `102` | Project directory not found |
| `103` | Permission denied for admin-only operation |
| `104` | Unsupported backend label |
| `105` | Fingerprinting failed; no recognizable stack detected |
| `106` | Lockfile not found or corrupted |
| `107` | Lockfile write failed or backend stub returned non-zero |
| `108` | Reserved for legacy backend availability checks |
| `109` | Drift detected; current fingerprint does not match lockfile |
| `110` | Mistral API unreachable or not configured |
| `111` | `-r` reset requires root privileges |
| `112` | Required helper script or binary not found |

## Configuration

`envctr` loads `configs/default.conf` and then repo-local `envctr.conf` when
present.

```bash
LOG_DIR="/var/log/envctr"
MISTRAL_API_KEY=""
MISTRAL_MODEL="mistral-small-latest"
MISTRAL_API_URL="https://api.mistral.ai/v1/chat/completions"
```

## C Helpers

Compile helpers before using `-f` or `-t`:

```bash
gcc helpers/fork_helper.c -o helpers/fork_helper
gcc helpers/thread_helper.c -o helpers/thread_helper -lpthread
```
