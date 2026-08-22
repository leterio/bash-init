#!/bin/bash
#
# Git helpers for interactive shells.

# Require git. Skip when it is missing so the rest of init can continue.
if ! has_command git; then
  return 0
fi

PS1_GIT='\[\033[01;96m\]$(declare -F __git_ps1 >/dev/null && __git_ps1)'

if is_wsl; then
  # git.exe is often faster on NTFS-backed WSL paths.
  alias lgit='/usr/bin/git'
  alias wgit='git.exe'
  function git_use_wsl() { alias git='/usr/bin/git'; }
  function git_use_win() { alias git='git.exe'; }
  git_use_win
fi

alias gst='git status -uall'

#######################################
# Compact commit graph for the current repository.
#######################################
function git_log() {
  git log --oneline --graph "$@"
}
alias gclog='git_log'

#######################################
# Compact commit graph for the current branch plus extra revisions.
# Arguments:
#   Extra revisions or git log options.
#######################################
function git_log_branch() {
  local current
  current="$(git rev-parse --abbrev-ref HEAD)"
  git log --oneline --graph "${current}" "$@"
}
alias gclogb='git_log_branch'

#######################################
# git diff that ignores whitespace noise.
#######################################
function git_diff() {
  git diff \
    --ignore-space-at-eol \
    --ignore-space-change \
    --ignore-all-space \
    --ignore-blank-lines \
    --word-diff=plain \
    "$@"
}

#######################################
# git show that ignores whitespace noise.
#######################################
function git_show() {
  git show \
    --ignore-space-at-eol \
    --ignore-space-change \
    --ignore-all-space \
    --ignore-blank-lines \
    --word-diff=plain \
    "$@"
}

#######################################
# Delete every local branch except the current one.
#######################################
function git_remove_other_branches() {
  local current branch
  current="$(git rev-parse --abbrev-ref HEAD)"
  while IFS= read -r branch; do
    [[ -z "${branch}" || "${branch}" == "${current}" ]] && continue
    git branch -D "${branch}"
  done < <(git branch --format='%(refname:short)')
}

#######################################
# List git repositories under a directory, skipping common build trees.
# Arguments:
#   Root directory to search.
# Outputs:
#   Repository paths, one per line.
#######################################
function _git_find_repos() {
  local current_dir="$1"
  find "${current_dir}" \
    -type d \( -name src -o -name target -o -name .settings -o -name .github \) \
    -prune -o \
    -type d -name '.git' -print \
    | sed 's#/.git##; s#^\./##'
}

#######################################
# Fast-forward every local branch that tracks a remote.
# Arguments:
#   Optional repository directory. Defaults to the current directory.
# Returns:
#   1 if the path is not a git repository.
#######################################
function git_pull_all() {
  local directory="${1:-.}"
  if [[ ! -d "${directory}/.git" ]]; then
    log_error "Not a git repository: ${directory}"
    return 1
  fi

  local remotes
  remotes="$(git -C "${directory}" remote)"
  if [[ -z "${remotes}" ]]; then
    log_error "No remotes configured"
    return 1
  fi

  log_info "Remotes: ${C_BOLD}${remotes}${C_CLEAR}"

  local current_local_branch
  current_local_branch="$(git -C "${directory}" rev-parse --abbrev-ref HEAD)"
  log_info "Current branch: ${C_BOLD}${current_local_branch}${C_CLEAR}"

  local remote remote_url mapping local_branch remote_branch rb
  local alb arb commits_behind commits_ahead
  while IFS= read -r remote; do
    [[ -z "${remote}" ]] && continue
    remote_url="$(git -C "${directory}" remote get-url "${remote}")"
    log_info "Updating remote ${C_BOLD}${remote}${C_CLEAR} (${remote_url})"
    if ! git -C "${directory}" remote update "${remote}"; then
      log_error "Failed to update remote ${remote}"
      continue
    fi

    while IFS= read -r mapping; do
      [[ -z "${mapping}" ]] && continue
      local_branch="${mapping%% *}"
      remote_branch="${mapping#* }"
      if [[ -z "${remote_branch}" || "${remote_branch}" != "${remote}/"* ]]; then
        continue
      fi
      rb="${remote_branch#"${remote}"/}"
      alb="refs/heads/${local_branch}"
      arb="refs/remotes/${remote}/${rb}"
      commits_behind="$(
        git -C "${directory}" rev-list --count "${alb}..${arb}" 2>/dev/null || echo 0
      )"
      commits_ahead="$(
        git -C "${directory}" rev-list --count "${arb}..${alb}" 2>/dev/null || echo 0
      )"

      if (( commits_behind > 0 )); then
        if (( commits_ahead > 0 )); then
          log_info "${C_RED}${local_branch}${C_CLEAR}: ${commits_behind} <-- ${remote}/${rb} --> ${commits_ahead}. ${C_ERROR}Cannot fast-forward${C_CLEAR}."
        elif [[ "${local_branch}" == "${current_local_branch}" ]]; then
          log_info "${C_CYAN}${local_branch}${C_CLEAR}: ${commits_behind} <-- ${remote}/${rb}. Fast-forwarding."
          if ! git -C "${directory}" merge -q "${arb}"; then
            log_error "Failed to fast-forward ${local_branch}"
          fi
        else
          log_info "${C_CYAN}${local_branch}${C_CLEAR}: ${commits_behind} <-- ${remote}/${rb}. Resetting local branch."
          if ! git -C "${directory}" branch -l -f "${local_branch}" -t "${arb}"; then
            log_error "Failed to reset ${local_branch}"
          fi
        fi
      fi
    done < <(git -C "${directory}" for-each-ref \
      --format='%(refname:short) %(upstream:short)' refs/heads)
  done <<< "${remotes}"

  log_success "Done"
}
alias gfall='git_pull_all'

#######################################
# Run git_pull_all on every git repository under the current directory.
#######################################
function git_pull_all_recursive() {
  local current_dir
  current_dir="$(pwd -P)"
  log_info "Looking for repositories in \"${current_dir}\" ..."

  local -a repositories=()
  readarray -t repositories < <(_git_find_repos "${current_dir}")

  if [[ ${#repositories[@]} -eq 0 ]]; then
    log_error "No repositories found."
    return 0
  fi

  log_info "${C_BOLD}${#repositories[@]}${C_CLEAR} repositories found"

  local repository rel
  for repository in "${repositories[@]}"; do
    [[ -z "${repository}" ]] && continue
    rel="${repository#"${current_dir}"/}"
    echo
    log_info "${C_BOLD}${rel}${C_CLEAR}: Updating repository"
    git_pull_all "${repository}" | sed "s#^#${C_BOLD}${rel}${C_CLEAR}: #g"
  done

  echo
  log_success "Update finished!"
}
alias gfallr='git_pull_all_recursive'

#######################################
# Interactively stage, revert, or inspect unstaged files.
# Arguments:
#   Optional -D to include deleted files.
#   Optional paths passed to git status.
# Returns:
#   1 when there are no unstaged files.
#######################################
function git_index() {
  local ignore_deleted=true
  if [[ "${1:-}" == "-D" ]]; then
    ignore_deleted=false
    shift
  fi

  local -a unstaged_ops=()
  local -a unstaged_files=()
  local line xy file worktree

  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    xy="${line:0:2}"
    file="${line:3}"
    worktree="${xy:1:1}"

    if [[ "${xy}" == "??" ]]; then
      unstaged_ops+=("new file")
      unstaged_files+=("${file}")
    elif [[ "${worktree}" == "M" ]]; then
      unstaged_ops+=("modified")
      unstaged_files+=("${file}")
    elif [[ "${worktree}" == "D" ]]; then
      unstaged_ops+=("deleted")
      unstaged_files+=("${file}")
    fi
  done < <(git status --porcelain --untracked-files=all "$@")

  local count="${#unstaged_files[@]}"
  if (( count == 0 )); then
    log_error "No unstaged files."
    return 1
  fi

  log_info "${C_BOLD}${count}${C_CLEAR} unstaged file(s)."

  local idx operation op sure display_idx
  for (( idx = 0; idx < count; idx++ )); do
    operation="${unstaged_ops[idx]}"
    file="${unstaged_files[idx]}"
    display_idx=$((idx + 1))
    while :; do
      case "${operation}" in
        deleted)
          if [[ "${ignore_deleted}" == true ]]; then
            log_info "${C_BOLD}${display_idx}${C_CLEAR}/${C_BOLD}${count}${C_CLEAR} - ${C_BOLD}${C_RED}DELETED${C_CLEAR}: ${C_RED}${file}${C_CLEAR}. Skipping ..."
            break
          fi
          log_info "${C_BOLD}${display_idx}${C_CLEAR}/${C_BOLD}${count}${C_CLEAR} - ${C_BOLD}${C_RED}DELETED${C_CLEAR}: ${C_RED}${file}${C_CLEAR}"
          ;;
        modified)
          log_info "${C_BOLD}${display_idx}${C_CLEAR}/${C_BOLD}${count}${C_CLEAR} - ${C_BOLD}${C_YELLOW}MODIFIED${C_CLEAR}: ${C_YELLOW}${file}${C_CLEAR}"
          ;;
        "new file")
          log_info "${C_BOLD}${display_idx}${C_CLEAR}/${C_BOLD}${count}${C_CLEAR} - ${C_BOLD}${C_GREEN}ADDED${C_CLEAR}: ${C_GREEN}${file}${C_CLEAR}"
          ;;
      esac

      log_info "(${C_BOLD}A${C_CLEAR})ccept; (${C_BOLD}I${C_CLEAR})gnore; (${C_BOLD}R${C_CLEAR})evert/Delete; (${C_BOLD}C${C_CLEAR})ompare; (${C_BOLD}E${C_CLEAR})dit; (${C_BOLD}S${C_CLEAR})tatus"
      read -r -n1 -p "-> " op
      echo
      case "${op^^}" in
        A)
          git add -- "${file}"
          break
          ;;
        I)
          log_warn "Ignored."
          break
          ;;
        R)
          log_info "Revert/delete this file? (${C_BOLD}Y${C_CLEAR})es; (${C_BOLD}N${C_CLEAR})o"
          read -r -n1 -p "-> " sure
          echo
          if [[ "${sure^^}" == "Y" ]]; then
            if [[ "${operation}" == "new file" ]]; then
              rm -- "${file}"
            else
              git checkout -- "${file}"
            fi
          fi
          break
          ;;
        C)
          clear
          git_diff -- "${file}"
          ;;
        E)
          "${EDITOR:-vi}" "${file}"
          ;;
        S)
          clear
          git status -uall
          echo "------------------------------------------------------------------------"
          ;;
        *)
          log_error "Invalid option."
          ;;
      esac
    done
  done
}

#######################################
# Switch every nested git repository to a branch and pull.
# Arguments:
#   Target branch name.
# Returns:
#   1 if the branch name is missing.
#######################################
function git_switch_all() {
  local target_branch="${1:-}"
  if [[ -z "${target_branch}" ]]; then
    log_error "Target branch must be specified"
    return 1
  fi

  local current_dir
  current_dir="$(pwd -P)"
  log_info "Looking for repositories in \"${current_dir}\" ..."

  local -a repositories=()
  readarray -t repositories < <(_git_find_repos "${current_dir}")

  if [[ ${#repositories[@]} -eq 0 ]]; then
    log_warn "No repositories found."
    return 0
  fi

  log_info "${C_BOLD}${#repositories[@]}${C_CLEAR} repositories found"

  local repository rel
  for repository in "${repositories[@]}"; do
    [[ -z "${repository}" ]] && continue
    rel="${repository#"${current_dir}"/}"
    log_info "${C_BOLD}${rel}${C_CLEAR}: Switching to ${C_BOLD}${target_branch}${C_CLEAR} ..."
    if ! git -C "${repository}" checkout "${target_branch}"; then
      log_error "Failed to switch branch"
      continue
    fi
    log_info "${C_BOLD}${rel}${C_CLEAR}: Updating repository ..."
    if ! git -C "${repository}" pull; then
      log_error "Failed to update branch"
      continue
    fi
  done

  log_success "Update finished!"
}
