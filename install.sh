#!/bin/bash
#
# Install init-scripts into the local user environment.
#
# Usage (from anywhere):
#   /path/to/init-scripts/install.sh [-i install_dir] [-d dev_dir] [-p projects_dir]
#
# Defaults / overrides:
#   -i / INSTALL_DIR   →  ~/.local/bin
#   -d / DEV_DIR       →  ~/Development
#   -p / PROJECTS_DIR  →  <dev_dir>/Projects
#
# Copies repo bin/ → install_dir, repo init.sh/ → install_dir/init.sh,
# creates directories, and updates ~/.bashrc with a managed INIT block.

set -euo pipefail

install_init_scripts() {
  local INIT_BEGIN='# INIT (managed by init-scripts install.sh)'
  local INIT_END='# END INIT (managed by init-scripts install.sh)'

  usage() {
    cat >&2 <<EOF
Usage: install.sh [-i install_dir] [-d dev_dir] [-p projects_dir]

  -i  Install directory for bin/ and init.sh/ (default: \$INSTALL_DIR or ~/.local/bin)
  -d  Development root (default: \$DEV_DIR or ~/Development)
  -p  Projects root (default: \$PROJECTS_DIR or <dev_dir>/Projects)
EOF
    exit 1
  }

  #######################################
  # Expand leading ~ and resolve to an absolute path (directory may be created).
  # Arguments:
  #   Path (may be relative or start with ~).
  # Outputs:
  #   Absolute path on stdout.
  #######################################
  resolve_dir() {
    local path="$1"
    if [[ "${path}" == ~* ]]; then
      path="${HOME}${path:1}"
    fi
    mkdir -p "${path}"
    (cd -P "${path}" && pwd)
  }

  #######################################
  # Write or replace the managed INIT block in ~/.bashrc.
  # Arguments:
  #   install_dir, dev_dir, projects_dir, bash_init_dir
  #######################################
  update_bashrc() {
    local install_dir="$1"
    local dev_dir="$2"
    local projects_dir="$3"
    local bash_init_dir="$4"
    local bashrc="${HOME}/.bashrc"
    local block_file
    local tmp

    block_file="$(mktemp)"
    cat >"${block_file}" <<EOF
${INIT_BEGIN}
export DEV="${dev_dir}"
export PROJECTS="${projects_dir}"
export BASH_INIT="${bash_init_dir}"
export PATH="${install_dir}:\${PATH}"
source "\${BASH_INIT}/init.sh"
${INIT_END}
EOF

    if [[ ! -f "${bashrc}" ]]; then
      echo "Creating ${bashrc}" >&2
      cat "${block_file}" >"${bashrc}"
      rm -f "${block_file}"
      return
    fi

    tmp="$(mktemp)"
    if grep -qF "${INIT_BEGIN}" "${bashrc}"; then
      echo "Updating managed INIT block in ${bashrc}" >&2
      awk -v begin="${INIT_BEGIN}" -v end="${INIT_END}" -v block_file="${block_file}" '
        $0 == begin {
          while ((getline line < block_file) > 0) print line
          close(block_file)
          skip = 1
          next
        }
        $0 == end { skip = 0; next }
        !skip { print }
      ' "${bashrc}" >"${tmp}"
    else
      echo "Appending INIT block to ${bashrc}" >&2
      cat "${bashrc}" >"${tmp}"
      printf '\n' >>"${tmp}"
      cat "${block_file}" >>"${tmp}"
    fi
    rm -f "${block_file}"
    mv "${tmp}" "${bashrc}"
  }

  local repo_root
  local install_dir
  local dev_dir
  local projects_dir
  local bash_init_dir
  local opt

  repo_root="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  install_dir="${INSTALL_DIR:-${HOME}/.local/bin}"
  dev_dir="${DEV_DIR:-${HOME}/Development}"
  projects_dir="${PROJECTS_DIR:-}"

  OPTIND=1
  while getopts ':i:d:p:h' opt; do
    case "${opt}" in
      i) install_dir="${OPTARG}" ;;
      d) dev_dir="${OPTARG}" ;;
      p) projects_dir="${OPTARG}" ;;
      h) usage ;;
      *) usage ;;
    esac
  done
  shift $((OPTIND - 1))
  [[ $# -eq 0 ]] || usage

  if [[ -z "${projects_dir}" ]]; then
    projects_dir="${dev_dir}/Projects"
  fi

  if [[ ! -d "${repo_root}/bin" ]]; then
    echo -e "\033[31mMissing ${repo_root}/bin\033[0m" >&2
    exit 1
  fi
  if [[ ! -d "${repo_root}/init.sh" ]]; then
    echo -e "\033[31mMissing ${repo_root}/init.sh\033[0m" >&2
    exit 1
  fi

  install_dir="$(resolve_dir "${install_dir}")"
  dev_dir="$(resolve_dir "${dev_dir}")"
  projects_dir="$(resolve_dir "${projects_dir}")"
  bash_init_dir="${install_dir}/init.sh"

  echo "Repo:      ${repo_root}" >&2
  echo "Install:   ${install_dir}" >&2
  echo "DEV:       ${dev_dir}" >&2
  echo "PROJECTS:  ${projects_dir}" >&2
  echo "BASH_INIT: ${bash_init_dir}" >&2

  echo "Copying bin/ → ${install_dir}" >&2
  cp -a "${repo_root}/bin/." "${install_dir}/"
  chmod +x "${install_dir}/use-module" 2>/dev/null || true

  echo "Copying init.sh/ → ${bash_init_dir}" >&2
  rm -rf "${bash_init_dir}"
  mkdir -p "${bash_init_dir}"
  find "${repo_root}/init.sh" -maxdepth 1 -type f -exec cp -a {} "${bash_init_dir}/" \;

  update_bashrc "${install_dir}" "${dev_dir}" "${projects_dir}" "${bash_init_dir}"

  echo -e "\033[32mInstalled init-scripts\033[0m" >&2
  echo "Open a new terminal, or run: source ~/.bashrc" >&2
}

install_init_scripts "$@"
