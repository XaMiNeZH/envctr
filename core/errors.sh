#!/bin/bash

ERR_UNKNOWN_OPT=100
ERR_MISSING_PARAM=101
ERR_DIR_NOT_FOUND=102
ERR_PERMISSION_DENIED=103
ERR_UNSUPPORTED_BACKEND=104
ERR_FINGERPRINT_FAILED=105
ERR_LOCKFILE_INVALID=106
ERR_PROVISION_FAILED=107
ERR_LEGACY_BACKEND_CHECK=108
ERR_DRIFT_DETECTED=109
ERR_MISTRAL_UNREACHABLE=110
ERR_RESET_NO_ROOT=111
ERR_REQUIRED_HELPER_NOT_FOUND=112

ERR_BACKEND_UNAVAILABLE="$ERR_UNSUPPORTED_BACKEND"
ERR_KVM_UNAVAILABLE="$ERR_LEGACY_BACKEND_CHECK"
ERR_BACKEND_NOT_FOUND="$ERR_REQUIRED_HELPER_NOT_FOUND"

error_message() {
    local code="$1"

    case "$code" in
        "$ERR_UNKNOWN_OPT")
            printf '%s\n' "unknown option"
            ;;
        "$ERR_MISSING_PARAM")
            printf '%s\n' "missing required parameter"
            ;;
        "$ERR_DIR_NOT_FOUND")
            printf '%s\n' "project directory not found"
            ;;
        "$ERR_PERMISSION_DENIED")
            printf '%s\n' "permission denied"
            ;;
        "$ERR_UNSUPPORTED_BACKEND")
            printf '%s\n' "unsupported backend label"
            ;;
        "$ERR_FINGERPRINT_FAILED")
            printf '%s\n' "fingerprint failed"
            ;;
        "$ERR_LOCKFILE_INVALID")
            printf '%s\n' "lockfile not found or invalid"
            ;;
        "$ERR_PROVISION_FAILED")
            printf '%s\n' "lockfile write failed or backend stub failed"
            ;;
        "$ERR_LEGACY_BACKEND_CHECK")
            printf '%s\n' "legacy backend availability check reserved"
            ;;
        "$ERR_DRIFT_DETECTED")
            printf '%s\n' "drift detected"
            ;;
        "$ERR_MISTRAL_UNREACHABLE")
            printf '%s\n' "Mistral API unreachable"
            ;;
        "$ERR_RESET_NO_ROOT")
            printf '%s\n' "reset requires root privileges"
            ;;
        "$ERR_REQUIRED_HELPER_NOT_FOUND")
            printf '%s\n' "required helper script or binary not found"
            ;;
        *)
            printf '%s\n' "unknown error"
            ;;
    esac
}

show_help() {
    cat <<'EOF'
ENVCTR(1)                    User Commands                    ENVCTR(1)

NAME
       envctr - environment controller for reproducible Linux project runtimes

SYNOPSIS
       envctr [options] -b <backend> -p <project_directory>

DESCRIPTION
       envctr fingerprints a project directory, writes an envctr.lock file,
       and can later compare current project metadata against the lockfile to
       detect drift.

       The execution pipeline is:

              Fingerprint -> Provision -> Lock -> Drift Detection

REQUIRED OPTIONS
       -b <backend>
              Record backend intent in the lockfile. Supported values are
              docker, qemu, and chroot.

       -p <project_directory>
              Select the project directory to inspect.

GENERAL OPTIONS
       -h
              Display this help page and exit.

       -l <dir>
              Write history.log to the selected directory instead of the
              default /var/log/envctr directory.

       -e
              Explain a drift report in plain language when the explanation
              module and Mistral API credentials are available.

EXECUTION MODES
       The default mode is sequential execution.

       -s
              Run the pipeline inside a Bash subshell.

       -f
              Run helper work through helpers/fork_helper. The helper creates
              one child process per command with fork(2).

       -t
              Run helper work through helpers/thread_helper. The helper
              creates one POSIX thread per command.

STATE AND LOCKFILE OPTIONS
       --from-lock
              Restore environment settings from an existing envctr.lock file.

       --update-lock
              Regenerate envctr.lock after a successful pipeline run.

       --drift
              Compare the live environment against envctr.lock and report
              differences.

       --restore
              Reserved for lockfile-based restoration workflows.

       --dry-run
              Print and log the planned actions without backend recording.

       --export
              Export the detected environment metadata when the export module
              is available.

       --no-provision
              Fingerprint and lock the project without recording backend work.

RESET OPTION
       -r
              Reset envctr.conf to defaults. This option requires root
              privileges.

BACKENDS
       docker
              Metadata label for teams that intend to use Docker externally.

       qemu
              Metadata label for teams that intend to use QEMU externally.

       chroot
              Metadata label for teams that intend to use chroot externally.

ERROR CODES
       100    Unknown option.
       101    Missing required parameter.
       102    Project directory not found.
       103    Permission denied.
       104    Unsupported backend label.
       105    Fingerprinting failed.
       106    Lockfile not found or invalid.
       107    Lockfile write failed or backend stub returned non-zero.
       108    Reserved for legacy backend availability checks.
       109    Drift detected.
       110    Mistral API unreachable.
       111    Reset requires root privileges.
       112    Required helper script or binary not found.

EXAMPLES
       envctr -s -b chroot -p ./examples/flask-simple
              Run a light project in subshell mode with the chroot backend.

       envctr -f -b docker -p ./examples/node-api
              Fingerprint a medium project with fork-based helper execution.

       envctr -t -b docker -p ./examples/microservices-monorepo
              Fingerprint a heavy project with pthread helper execution.

       envctr --drift -e -b docker -p ./myproject
              Detect drift and request a plain-language explanation.

       envctr --dry-run --no-provision -b docker -p ./myproject
              Inspect the project and show planned actions without starting
              containers or virtual machines.

FILES
       /var/log/envctr/history.log
              Default log file.

       envctr.lock
              Project environment lockfile generated in the project root.

       envctr.conf
              Local envctr configuration file.

EXIT STATUS
       envctr exits with 0 on success. On failure it exits with one of the
       documented error codes and displays this help page.

ENVCTR(1)
EOF
}

die() {
    local code="$1"
    local message

    message="$(error_message "$code")"
    log_message "ERROR" "$message" || true
    show_help
    exit "$code"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        die "$ERR_RESET_NO_ROOT"
    fi
}
