#!/bin/bash
# init.sh/19_init_git.sh
# Este script provê funções auxiliares para uso da ferramenta GIT

# Encaminha todas execuçõe do git para o git-for-windows (Lentidão relacionado as bordas do sistema de arquivos (EXT4 <> NTFS))
alias lgit="/usr/bin/git"
alias wgit="git.exe"
function git-use-wsl() { alias git="/usr/bin/git"; }
function git-use-win() { alias git="git.exe"; }

# Bug com o git-use-win usando quando root (PATH?)
# [[ $(id -u) -eq 0 ]] && git-use-wsl || git-use-win
git-use-win

# gst
# Lista todos os arquivos alterados na workspace.
alias gst='git status -uall'

# git-log / gclog
# Exibe a árvore dos commits (do mais novo ao antigo)
alias git-log='git log --oneline --graph'
alias gclog='git-log'

# git-log-branch / gclogb
# Exibe a estrutura da árvore do repositório, focando na branch atual + branchs informadas
function git-log-branch() { git log --oneline --graph $(git rev-parse --abbrev-ref HEAD) $@; }
alias gclogb='git-log-branch'

# git-diff
# Customiza a comparação do git
alias git-diff='git diff --ignore-space-at-eol --ignore-space-change --ignore-all-space --ignore-blank-lines --word-diff=plain'

# git-show
# Customiza a exibição do commit atual
alias git-show='git show --ignore-space-at-eol --ignore-space-change --ignore-all-space --ignore-blank-lines --word-diff=plain'

# git-remove-other-branches
# Remove todas demais branches do repositório (exceto a atual)
alias git-remove-other-branches='git branch | grep -v $(git rev-parse --abbrev-ref HEAD) | xargs git branch -D'

# git-pull-all / gfall
# Atualiza o repositório atual, atualizando todas as branches locais
function git-pull-all() {
    local DIRECTORY="${1:-.}"
    [[ ! -d "$DIRECTORY/.git" ]] && {
        error "Não é um repositório GIT"
        return 1
    }

    local REMOTES=$(git -C "${DIRECTORY}" remote | xargs -n1 echo)
    log-info "Remotes: ${C_BOLD}${REMOTES}${C_RESET}"

    local CURRENT_LOCAL_BRANCH=$(git -C "${DIRECTORY}" branch -l | awk '/^\*/{print $2}')
    log-info "Branch atual: ${C_BOLD}${CURRENT_LOCAL_BRANCH}${C_CLEAR}"

    # for all remotes
    while read REMOTE; do
        log-info "Atualizando remote ${C_BOLD}${REMOTE}${C_CLEAR} ($(git -C "${DIRECTORY}" remote get-url "${REMOTE}"))"
        git -C "${DIRECTORY}" remote update $REMOTE >/dev/null 2>&1

        # For all local branch that merges with any on this remote
        while read MERGES_WITH; do
            RB=$(echo "$MERGES_WITH" | cut -f1 -d" ")
            ARB="refs/remotes/$REMOTE/$RB"
            LB=$(echo "$MERGES_WITH" | cut -f2 -d" ")
            ALB="refs/heads/$LB"
            COMMITS_BEHIND=$(($(git -C "${DIRECTORY}" rev-list --count $ALB..$ARB 2>/dev/null) + 0))
            COMMITS_AHEAD=$(($(git -C "${DIRECTORY}" rev-list --count $ARB..$ALB 2>/dev/null) + 0))
            if [ "$COMMITS_BEHIND" -gt 0 ]; then
                if [ "$COMMITS_AHEAD" -gt 0 ]; then
                    log-info "${C_RED}${LB}${C_CLEAR}: ${COMMITS_BEHIND} <-- ${REMOTE}/${RB} --> ${COMMITS_AHEAD}. ${C_ERROR}O fast-forawrd não pode ser realizado${C_CLEAR}."
                elif [ "$LB" = "$CURRENT_LOCAL_BRANCH" ]; then
                    log-info "${C_CYAN}${LB}${C_CLEAR}: ${COMMITS_BEHIND} <-- ${REMOTE}/${RB}. Efetuando o fast-forward."
                    git -C "${DIRECTORY}" merge -q $ARB >/dev/null
                else
                    log-info "${C_CYAN}${LB}${C_CLEAR}: ${COMMITS_BEHIND} <-- ${REMOTE}/${RB}. Resetando a branch local."
                    git -C "${DIRECTORY}" branch -l -f $LB -t $ARB >/dev/null
                fi
            fi
        done <<<$(git -C "${DIRECTORY}" remote show "$REMOTE" -n | awk '/merges with remote/{print $5" "$1}')
    done <<<"$REMOTES"
    log-success "Concluído"
}
alias gfall='git-pull-all'

# git-pull-all-recursive / gfall
# Atualiza todos os repositórios nos subdiretórios do diretório atual
function git-pull-all-recursive() {
    local CURRENT_DIR="$(pwd -P)"
    log-info "Buscando repositórios em \"${CURRENT_DIR}\" ..."

    local IFS=$'\n'
    local REPOSITORIES=($(find "${CURRENT_DIR}" \
        -type d \( -name src -o -name target -o -name .settings -o -name .github \) -prune -o \
        -type d -name ".git" -print |
        sed 's#\/.git##g; s#\./##g'))
    unset IFS

    [[ ${#REPOSITORIES[@]} -eq 0 ]] && {
        error "Nenhum repositório encontrado."
        return 0
    }

    log-info "${C_BOLD}${#REPOSITORIES[@]}${C_CLEAR} repositórios encontrados"

    for REPOSITORY in "${REPOSITORIES[@]}"; do
        echo -e
        log-info "${C_BOLD}${REPOSITORY//$CURRENT_DIR\//}${C_CLEAR}: Atualizando repositório"
        git-pull-all "$REPOSITORY" | sed "s#^#$(echo -e ${C_BOLD})${REPOSITORY//$CURRENT_DIR\//}$(echo -e ${C_CLEAR}): #g"
    done

    echo -e
    log-success "Atualização finalizada!"
}
alias gfallr='git-pull-all-recursive'

# git-index
# Com base nos arquivos alterados, permite tomar decisões sobre os arquivos, manipulando o índice do git
function git-index() {
    local IGNORE_DELETED=true
    [[ "##$1" == "##-D" ]] && {
        IGNORE_DELETED=false
        shift
    }

    local UNSTAGED_FILES
    local IFS=$'\n'
    [[ $# -gt 0 ]] && UNSTAGED_FILES=($(git status $@ | grep -A1000 "not staged" | grep ": ")) ||
        UNSTAGED_FILES=($(git status | grep -A1000 "not staged" | grep ": "))
    unset IFS

    local UNSTAGED_FILES_COUNT=${#UNSTAGED_FILES[@]}
    if [ "$UNSTAGED_FILES_COUNT" -eq "0" ]; then
        log-error "Nenhum arquivo está fora do índice."
        return 1
    fi

    log-info "${C_BOLD}${UNSTAGED_FILES_COUNT}${C_CLEAR} arquivos não indexados."

    local CUR_IDX=1
    for CURRENT_FILE_ENTRY in "${UNSTAGED_FILES[@]}"; do
        local operation=$(echo $CURRENT_FILE_ENTRY | cut -d ":" -f1)
        local file=$(echo $CURRENT_FILE_ENTRY | cut -d ":" -f2 | awk '{$1=$1};1')
        while :; do
            if [ "$operation" == "deleted" ]; then
                if [ $IGNORE_DELETED == true ]; then
                    log-info "${C_BOLD}${CUR_IDX}${C_CLEAR}/${C_BOLD}${UNSTAGED_FILES_COUNT}${C_CLEAR} - Arquivo ${C_BOLD}${C_RED}DELETADO${C_CLEAR}: ${C_RED}${file}${C_CLEAR}. Ignorando ..."
                    break
                else
                    log-info "${C_BOLD}${CUR_IDX}${C_CLEAR}/${C_BOLD}${UNSTAGED_FILES_COUNT}${C_CLEAR} - Arquivo ${C_BOLD}${C_RED}DELETADO${C_CLEAR}: ${C_RED}${file}${C_CLEAR}"
                fi
            elif [ "$operation" == "modified" ]; then
                log-info "${C_BOLD}${CUR_IDX}${C_CLEAR}/${C_BOLD}${UNSTAGED_FILES_COUNT}${C_CLEAR} - Arquivo ${C_BOLD}${C_YELLOW}MODIFICADO${C_CLEAR}: ${C_YELLOW}${file}${C_CLEAR}"
            elif [ "$operation" == "new file" ]; then
                log-info "${C_BOLD}${CUR_IDX}${C_CLEAR}/${C_BOLD}${UNSTAGED_FILES_COUNT}${C_CLEAR} - Arquivo ${C_BOLD}${C_GREEN}ADICIONADO${C_CLEAR}: ${C_GREEN}${file}${C_CLEAR}"
            fi

            log-info "(${C_BOLD}A${C_CLEAR})ceitar; (${C_BOLD}I${C_CLEAR})gnorar; (${C_BOLD}R${C_CLEAR})everter/Deletar; (${C_BOLD}C${C_CLEAR})omparar; (${C_BOLD}E${C_CLEAR})ditar; (${C_BOLD}S${C_CLEAR})tatus"
            read -n1 -p "-> " op
            echo -e
            if [ "${op^^}" == "A" ]; then
                git add "$file"
                break
            elif [ "${op^^}" == "I" ]; then
                log-warn "Ignorado."
                break
            elif [ "${op^^}" == "R" ]; then
                log-info "Tem certeza que deseja reverter/deletar o arquivo? (${C_BOLD}S${C_CLEAR})im; (${C_BOLD}N${C_CLEAR})ão?"
                read -n1 -p "-> " sure
                echo -e
                if [ "${sure^^}" == "S" ]; then
                    if [ "$operation" == "new file" ]; then
                        rm "$file"
                    else
                        git checkout "$file"
                    fi
                fi
                break
            elif [ "${op^^}" == "C" ]; then
                clear
                git-diff "$file"
            elif [ "${op^^}" == "E" ]; then
                vi $file
            elif [ "${op^^}" == "S" ]; then
                clear
                git status -uall
                echo -e "------------------------------------------------------------------------"
            else
                log-error "Opção inválida."
            fi
        done

        CUR_IDX=$((${CUR_IDX} + 1))
    done
}

# git-switch-all
# Com base no diretório atual, altera a branch corrente de todos os repositórios
function git-switch-all() {
    local targetBranch="$1"
    [[ "${targetBranch}" == "" ]] && { log-error "A branch de destino deve ser especificada\!"; return 1; }

    local CURRENT_DIR="$(pwd -P)"
    log-info "Buscando repositórios em \"${CURRENT_DIR}\" ..."

    local IFS=$'\n'
    local REPOSITORIES=($(find "${CURRENT_DIR}" \
        -type d \( -name src -o -name target -o -name .settings -o -name .github \) -prune -o \
        -type d -name ".git" -print \
        | sed 's#\/.git##g; s#\./##g'))
    unset IFS
    
    [[ ${#REPOSITORIES[@]} -eq 0 ]] && { log-warn "Nenhum repositório encontrado."; return 0; }

    log-info "${C_BOLD}${#REPOSITORIES[@]}${C_CLEAR} repositórios encontrados"
    
    for REPOSITORY in "${REPOSITORIES[@]}"; do
        log-info "\n${C_BOLD}${REPOSITORY//$CURRENT_DIR\//}${C_CLEAR}: Alterando para a branch ${C_BOLD}${targetBranch}${C_CLEAR} ..."
        git -C "$REPOSITORY" checkout "${targetBranch}" >/dev/null || { log-error "Falhou ao alterar a branch\!\!"; continue; }
        log-info "\n${C_BOLD}${REPOSITORY//$CURRENT_DIR\//}${C_CLEAR}: Atualizando repositório ..."
        git -C "$REPOSITORY" pull                       >/dev/null || { log-error "Falhou ao atualizar a branch\!\!"; continue; }
    done

    log-success "\n${C_SUCCESS}Atualização finalizada!${C_CLEAR}"
}
alias gsw='git-switch-all'

# github-clone
# Clona qualquer repositório do GitHub
function github-clone() {
    repo="${1}"
    [[ "$repo" == "" ]] && { log-error "Informar o repositório"; return 1; }
    git clone "https://github.com/${repo}.git"
}