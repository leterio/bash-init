#!/bin/bash
#
# Everyday interactive commands, aliases, and working-directory helpers.

if is_macos; then
  alias ls='ls -GA'
  alias ll='ls -GalF'
else
  alias ls='ls --color=auto -A'
  alias ll='ls --color=auto -alF'
fi

alias reinit='source ~/.bashrc'

function dev() {
  cd "${DEV}" || return 1
}

#######################################
# Change to a project directory under PROJECTS.
# Arguments:
#   Optional project name or substring. With no argument, cd to the
#   projects root.
# Returns:
#   0 on success or when multiple matches are listed, 1 when none match.
#######################################
function proj() {
  local proj_name="${1:-}"
  local projects_root="${PROJECTS}"

  if [[ -z "${proj_name}" ]]; then
    cd "${projects_root}" || return 1
    return 0
  fi

  if [[ -d "${projects_root}/${proj_name}" ]]; then
    cd "${projects_root}/${proj_name}" || return 1
    return 0
  fi

  local -a projects=()
  readarray -t projects < <(
    find "${projects_root}" -mindepth 1 -maxdepth 1 -type d \
      | sed "s#${projects_root}/##g" \
      | grep -a -- "${proj_name}" || true
  )

  if [[ ${#projects[@]} -eq 0 ]]; then
    log_error "No project matched \"${proj_name}\""
    return 1
  fi

  if [[ ${#projects[@]} -eq 1 ]]; then
    cd "${projects_root}/${projects[0]}" || return 1
    return 0
  fi

  local project
  for project in "${projects[@]}"; do
    if [[ "${project}" == "${proj_name}" ]]; then
      cd "${projects_root}/${project}" || return 1
      return 0
    fi
  done

  log_info "Multiple projects matched \"${proj_name}\":"
  for project in "${projects[@]}"; do
    log_info "  - ${project}"
  done
  return 0
}

#######################################
# Change to a scratch working directory under DEV/wd, creating it if needed.
# Arguments:
#   Optional subdirectory name.
# Returns:
#   0 on success, 1 if the path exists and is not a directory.
#######################################
function wd() {
  local target_directory="${DEV}/wd"
  local custom_wd="${1:-}"

  if [[ -n "${custom_wd}" ]]; then
    target_directory="${target_directory}/${custom_wd}"
  fi

  if [[ -e "${target_directory}" && ! -d "${target_directory}" ]]; then
    log_error "Path exists and is not a directory: ${target_directory}"
    return 1
  fi

  if [[ ! -d "${target_directory}" ]]; then
    mkdir -p "${target_directory}" || return 1
  fi

  cd "${target_directory}" || return 1
}

if has_command apt; then
  #######################################
  # Update the Debian/Ubuntu package set with apt.
  # Returns:
  #   0 when every apt step succeeds, non-zero otherwise.
  #######################################
  function apt_upgrade() {
    if ! has_command apt; then
      log_error "apt is not available"
      return 1
    fi

    local log_file='/tmp/apt-upgrade.log'
    : >"${log_file}"

    log_info 'Updating package lists ...'
    # Redirect as the user; sudo only wraps apt.
    # shellcheck disable=SC2024
    if ! sudo apt update >"${log_file}" 2>&1; then
      log_error 'apt update failed'
      cat "${log_file}" >&2
      return 1
    fi

    log_info 'Upgrading packages ...'
    # shellcheck disable=SC2024
    if ! sudo apt dist-upgrade -y --no-install-recommends \
      >>"${log_file}" 2>&1; then
      log_error 'apt dist-upgrade failed'
      cat "${log_file}" >&2
      return 1
    fi

    log_info 'Removing unused packages ...'
    # shellcheck disable=SC2024
    if ! sudo apt autoremove --purge -y >>"${log_file}" 2>&1; then
      log_error 'apt autoremove failed'
      cat "${log_file}" >&2
      return 1
    fi

    log_info 'Cleaning package cache ...'
    # shellcheck disable=SC2024
    if ! sudo apt autoclean -y >>"${log_file}" 2>&1; then
      log_error 'apt autoclean failed'
      cat "${log_file}" >&2
      return 1
    fi

    log_success 'Done'
  }
fi
