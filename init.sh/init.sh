#!/bin/bash
#
# Load every init stage script under BASH_INIT.
#
# Stages:
#   00-09  Environment
#   10-19  Commands and integrations
#   20-29  Network
#   30-89  Unused
#   90-99  Finalization

if [[ -z "${BASH_INIT:-}" ]]; then
  echo "BASH_INIT is not set" >&2
  return 1
fi

# Drop stale load marks from a previous interactive session / reinit so
# modules are sourced again and their functions are redefined.
unset LOADED_MODULES

#######################################
# Print an epoch timestamp in milliseconds.
# Outputs:
#   Milliseconds since epoch. Falls back to second precision * 1000
#   when date does not support %3N.
#######################################
function _init_now_ms() {
  local stamp
  stamp="$(date +%s%3N 2>/dev/null)" || true
  if [[ "${stamp}" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "${stamp}"
    return
  fi
  printf '%s\n' "$(($(date +%s) * 1000))"
}

START_TIME="$(_init_now_ms)"

echo "Starting ..."

for sh in "${BASH_INIT}/"*_init_*.sh; do
  [[ -e "${sh}" ]] || continue
  echo "Running script: ${sh##*/}"
  # shellcheck disable=SC1090
  if ! source "${sh}"; then
    echo -e "${C_ERROR:-}Failed to run ${sh##*/}${C_CLEAR:-}" >&2
  fi
done

echo -e "${C_GREEN:-}Started in $(( $(_init_now_ms) - START_TIME ))ms${C_CLEAR:-}"

unset START_TIME
unset -f _init_now_ms
