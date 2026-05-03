# Changelog

All notable envctr changes are tracked here.
Format follows the spirit of Keep a Changelog.
Versions use semantic numbering from `VERSION`.

---

## [Unreleased]

### Planned

- Core Bash orchestrator (`envctr`)
- Option parsing with `getopts`
- `core/logger.sh` with exact log format
- `core/errors.sh` with `die()` and `show_help()`
- `helpers/fork_helper.c` — real fork() provisioning
- `helpers/thread_helper.c` — real pthreads provisioning
- `core/fingerprint.sh` — stack detection engine
- `backends/docker.sh` — Docker provisioning
- `backends/chroot.sh` — chroot jail provisioning
- `backends/qemu.sh` — QEMU/KVM provisioning
- `core/lock.sh` — lockfile generation and parsing
- `core/drift.sh` — drift detection and classification
- `core/explain.sh` — Mistral API drift explanation
- Three test scenario scripts
- Example projects for light, medium, and heavy scenarios

---

## [0.1.0] - 2026-05-03

### Added

- Initial repository setup
- Project specification document
- Requirements tracker mapped to PDF guidelines
- README with full project description
- Architecture design finalized
- Task distribution completed
- Versioning and changelog infrastructure
- Branch strategy defined
