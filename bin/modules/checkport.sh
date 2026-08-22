#!/bin/bash
#
# TCP/UDP connectivity probe using bash /dev/{tcp,udp} redirections.

# shellcheck disable=SC1091
source use-module colors logs

#######################################
# Probe whether a TCP or UDP port is reachable.
# Arguments:
#   Host or FQDN.
#   Port number.
#   Optional timeout (for example 3, 3s, 1m). Defaults to 3s.
#   Optional protocol: tcp or udp. Defaults to tcp.
# Outputs:
#   Writes reachability status to stdout.
# Returns:
#   0 if the port is open, 124 on timeout, non-zero otherwise.
#######################################
function checkport() {
  if [[ $# -lt 2 || $# -gt 4 ]]; then
    log_error "Usage: checkport <host> <port> [timeout] [tcp|udp]" >&2
    return 1
  fi

  if ! command -v timeout >/dev/null 2>&1; then
    log_error "timeout command not found"
    return 1
  fi

  local host="$1"
  local port="$2"
  local timeout="3s"
  local datagram="tcp"

  if [[ $# -ge 3 ]]; then
    if [[ "$3" == "tcp" || "$3" == "udp" ]]; then
      datagram="$3"
    elif [[ "$3" =~ ^[0-9]+([.][0-9]+)?[sm]?$ ]]; then
      timeout="$3"
      if [[ ! "${timeout}" =~ [sm]$ ]]; then
        timeout="${timeout}s"
      fi
    else
      log_error "Invalid timeout or protocol: $3"
      return 1
    fi
  fi

  if [[ $# -eq 4 ]]; then
    if [[ "$4" != "tcp" && "$4" != "udp" ]]; then
      log_error "Invalid protocol: $4"
      return 1
    fi
    datagram="$4"
  fi

  local outcode=0
  # Inner bash expands the env vars passed by env(1).
  # shellcheck disable=SC2016
  timeout "${timeout}" \
    env checkport_host="${host}" \
    checkport_port="${port}" \
    checkport_datagram="${datagram}" \
    bash -c 'cat < /dev/null > "/dev/${checkport_datagram}/${checkport_host}/${checkport_port}"' \
    >/dev/null 2>&1 || outcode=$?

  if [[ "${outcode}" -eq 0 ]]; then
    echo -e "${host}:${port} ${datagram} ${C_GREEN}Open${C_CLEAR}"
  elif [[ "${outcode}" -eq 124 ]]; then
    echo -e "${host}:${port} ${datagram} ${C_YELLOW}Timeout (${timeout})${C_CLEAR}"
  else
    echo -e "${host}:${port} ${datagram} ${C_RED}Closed${C_CLEAR}"
  fi
  return "${outcode}"
}
