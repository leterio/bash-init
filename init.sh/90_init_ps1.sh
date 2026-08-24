#!/bin/bash
#
# Assemble PS1 from PS1_FRAGMENTS, substitute {{PS1_*}} placeholders, then
# unset those flags so they do not leak into the interactive environment.
# debian_chroot is set by Debian/Ubuntu bashrc when present.
# shellcheck disable=SC2016,SC2034,SC2154
PS1_FRAGMENTS=(
  '\[\e]0;\u@\h: \w\a\]'                 # window title
  '${debian_chroot:+($debian_chroot)}'   # chroot (empty at prompt if unset)
  '\[\033[01;32m\]\u@\h\[\033[00m\]: '   # user@host:
  '\[\033[01;34m\]\w'                    # cwd
  '{{PS1_GIT}}'                          # git (omitted when unset)
  '\[\033[00m\] \$ '                     # prompt
)

#######################################
# Build PS1 from PS1_FRAGMENTS and drop public placeholder variables.
# Globals:
#   PS1
#   PS1_FRAGMENTS
#   _PS1_FRAGMENTS
#######################################
function ps1_apply() {
  local fragment name value placeholder
  local -a built=()
  local -a placeholders=()

  if [[ ${#PS1_FRAGMENTS[@]} -gt 0 ]]; then
    _PS1_FRAGMENTS=("${PS1_FRAGMENTS[@]}")
  fi

  for fragment in "${_PS1_FRAGMENTS[@]}"; do
    while [[ "${fragment}" =~ \{\{([A-Za-z_][A-Za-z0-9_]*)\}\} ]]; do
      name="${BASH_REMATCH[1]}"
      if [[ -n "${!name+x}" ]]; then
        value="${!name}"
      else
        value=""
      fi
      placeholder="{{${name}}}"
      fragment="${fragment//"${placeholder}"/"${value}"}"
      placeholders+=("${name}")
    done
    if [[ -n "${fragment}" ]]; then
      built+=("${fragment}")
    fi
  done

  local IFS=''
  export PS1="${built[*]}"

  for name in "${placeholders[@]}"; do
    unset -v "${name}"
  done
  unset -v PS1_FRAGMENTS
}

ps1_apply
