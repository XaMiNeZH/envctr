#!/bin/bash

ERR_UNKNOWN_OPT=100
ERR_MISSING_PARAM=101
ERR_DIR_NOT_FOUND=102
ERR_PERMISSION_DENIED=103
ERR_BACKEND_UNAVAILABLE=104
ERR_FINGERPRINT_FAILED=105
ERR_LOCKFILE_INVALID=106
ERR_PROVISION_FAILED=107
ERR_KVM_UNAVAILABLE=108
ERR_DRIFT_DETECTED=109
ERR_MISTRAL_UNREACHABLE=110
ERR_RESET_NO_ROOT=111
ERR_BACKEND_NOT_FOUND=112

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
        "$ERR_BACKEND_UNAVAILABLE")
            printf '%s\n' "backend unavailable"
            ;;
        "$ERR_FINGERPRINT_FAILED")
            printf '%s\n' "fingerprint failed"
            ;;
        "$ERR_LOCKFILE_INVALID")
            printf '%s\n' "lockfile not found or invalid"
            ;;
        "$ERR_PROVISION_FAILED")
            printf '%s\n' "provisioning failed"
            ;;
        "$ERR_KVM_UNAVAILABLE")
            printf '%s\n' "KVM unavailable"
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
        "$ERR_BACKEND_NOT_FOUND")
            printf '%s\n' "backend binary not found"
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
       envctr fingerprints a project directory, provisions an isolated runtime,
       writes an envctr.lock file, and can later compare the live environment
       against the lockfile to detect drift.

       The execution pipeline is:

              Fingerprint -> Provision -> Lock -> Drift Detection

REQUIRED OPTIONS
       -b <backend>
              Select the isolation backend. Supported values are docker, qemu,
              and chroot.

       -p <project_directory>
              Select the project directory to inspect and provision.

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
              Run service provisioning commands through helpers/fork_helper.
              The helper creates one child process per command with fork(2).

       -t
              Run service provisioning commands through helpers/thread_helper.
              The helper creates one POSIX thread per command.

STATE AND LOCKFILE OPTIONS
       --from-lock
              Restore environment settings from an existing envctr.lock file.

       --update-lock
              Regenerate envctr.lock after a successful pipeline run.

       --drift
              Compare the live environment against envctr.lock and report
              differences.

       --restore
              Restore the environment from lockfile state when the selected
              backend supports restoration.

       --dry-run
              Print and log the planned actions without provisioning.

       --export
              Export the detected environment metadata when the export module
              is available.

       --no-provision
              Fingerprint and lock the project without starting backend
              resources.

RESET OPTION
       -r
              Reset envctr.conf to defaults and destroy provisioned resources.
              This option requires root privileges.

BACKENDS
       docker
              Uses Docker containers and the envctr-net network. This backend
              is suitable for common application stacks and service containers.

       qemu
              Uses QEMU/KVM to boot a full virtual machine with its own Linux
              kernel. KVM access is required for accelerated execution.

       chroot
              Uses a Linux chroot jail. This backend is useful on minimal
              systems where Docker is unavailable.

ERROR CODES
       100    Unknown option.
       101    Missing required parameter.
       102    Project directory not found.
       103    Permission denied.
       104    Backend unavailable.
       105    Fingerprinting failed.
       106    Lockfile not found or invalid.
       107    Provisioning failed.
       108    KVM unavailable.
       109    Drift detected.
       110    Mistral API unreachable.
       111    Reset requires root privileges.
       112    Backend binary not found.

EXAMPLES
       envctr -s -b chroot -p ./examples/flask-simple
              Run a light project in subshell mode with the chroot backend.

       envctr -f -b docker -p ./examples/node-api
              Provision a medium project with fork-based parallel execution.

       envctr -t -b docker -p ./examples/microservices-monorepo
              Provision a heavy multi-service project with pthread execution.

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
