#!/bin/bash
#
# WSL helpers that call Windows binaries (Explorer, VS Code, wslpath).

# Windows integration is WSL-only.
if ! is_wsl; then
  return 0
fi

alias wsl='/mnt/c/windows/system32/wsl.exe'

#######################################
# Open Windows Explorer at a path (defaults to the current directory).
# Arguments:
#   Optional path to open.
#######################################
function explorer() {
  local target
  target="$(wslpath -w "${1:-.}")"
  log_info "Opening Explorer ..."
  # Explorer.exe often exits 1 even on success.
  (/mnt/c/Windows/explorer.exe "${target}" &) >/dev/null 2>&1
}

#######################################
# Open Windows VS Code, converting the first existing path with wslpath.
# Arguments:
#   Optional path and extra Code.exe arguments.
# Returns:
#   1 if Code.exe cannot be found.
#######################################
function code() {
  local win_user
  win_user="$(cmd.exe /C 'echo %USERNAME%' 2>/dev/null | tr -d '\r\n')"

  local -a vscode_bin_arr=(
    '/mnt/c/Program Files/Microsoft VS Code/Code.exe'
    "/mnt/c/Users/${win_user}/AppData/Local/Programs/Microsoft VS Code/Code.exe"
  )
  local vscode_bin=''
  local check_bin
  for check_bin in "${vscode_bin_arr[@]}"; do
    if [[ -f "${check_bin}" ]]; then
      vscode_bin="${check_bin}"
      break
    fi
  done

  if [[ ! -f "${vscode_bin}" ]]; then
    log_error "VS Code executable not found"
    return 1
  fi

  local -a vscode_args=()
  if [[ $# -gt 0 ]]; then
    if [[ -e "$1" ]]; then
      vscode_args+=("$(wslpath -w "$1")")
      shift
    fi
    vscode_args+=("$@")
  fi

  log_info "Opening VS Code ..."
  ("${vscode_bin}" -n "${vscode_args[@]}" &) >/dev/null 2>&1
}

#######################################
# cd using a Windows-style path.
# Arguments:
#   Windows path, for example 'C:\Users\myUser\Desktop'.
# Returns:
#   1 if the path is missing.
#######################################
function cdw() {
  if [[ $# -ne 1 ]]; then
    log_error "A path must be specified"
    return 1
  fi
  cd "$(wslpath "$1")" || return 1
}
