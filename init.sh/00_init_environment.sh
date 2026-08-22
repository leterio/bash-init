#!/bin/bash
#
# Host detection helpers.

#######################################
# Return 0 when the current host is WSL.
# Returns:
#   0 on WSL, 1 otherwise.
#######################################
function is_wsl() {
  [[ -n "${WSL_DISTRO_NAME:-}" ]] && return 0
  [[ -r /proc/sys/kernel/osrelease ]] \
    && grep -qi 'microsoft' /proc/sys/kernel/osrelease \
    && return 0
  return 1
}

#######################################
# Return 0 when the current host is macOS.
#######################################
function is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

#######################################
# Return 0 when the current host is Linux.
#######################################
function is_linux() {
  [[ "$(uname -s)" == "Linux" ]]
}

#######################################
# Return 0 when the process is running inside a Docker container.
#######################################
function is_docker() {
  [[ -f /.dockerenv ]]
}

#######################################
# Return 0 when a command is available on PATH.
# Arguments:
#   Command name.
#######################################
function has_command() {
  command -v "${1}" >/dev/null 2>&1
}
