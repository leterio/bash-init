#!/bin/bash
#
# Leveled log helpers for interactive shells and sourced scripts.

export LOG_LEVEL="${LOG_LEVEL:-3}"

# shellcheck disable=SC1091
source use-module colors

function log_set_trace()   { export LOG_LEVEL=5; }
function log_set_debug()   { export LOG_LEVEL=4; }
function log_set_info()    { export LOG_LEVEL=3; }
function log_set_success() { export LOG_LEVEL=2; }
function log_set_warn()    { export LOG_LEVEL=1; }
function log_set_error()   { export LOG_LEVEL=0; }
function log_set_off()     { export LOG_LEVEL=-1; }

function log_trace()   { if (( LOG_LEVEL >= 5 )) && [[ $# -gt 0 ]]; then echo -e "${C_TRACE}$*${C_CLEAR}"   >&2; fi; }
function log_debug()   { if (( LOG_LEVEL >= 4 )) && [[ $# -gt 0 ]]; then echo -e "${C_DEBUG}$*${C_CLEAR}"   >&2; fi; }
function log_info()    { if (( LOG_LEVEL >= 3 )) && [[ $# -gt 0 ]]; then echo -e "$*"                       >&2; fi; }
function log_success() { if (( LOG_LEVEL >= 2 )) && [[ $# -gt 0 ]]; then echo -e "${C_SUCCESS}$*${C_CLEAR}" >&2; fi; }
function log_warn()    { if (( LOG_LEVEL >= 1 )) && [[ $# -gt 0 ]]; then echo -e "${C_WARN}$*${C_CLEAR}"    >&2; fi; }
function log_error()   { if (( LOG_LEVEL >= 0 )) && [[ $# -gt 0 ]]; then echo -e "${C_ERROR}$*${C_CLEAR}"   >&2; fi; }
