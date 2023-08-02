#!/bin/bash
# init.sh/10_init_commands.sh
# Este script provê funções e comandos básicos para uso do terminal

# Listagens
alias ls='ls --color=auto -A'
alias ll='ls --color=auto -alF'

# Reinicia a configuração (BASH)
alias reinit='source ~/.bashrc'

# CDs
alias dev="cd $DEV"
alias proj="cd $DEV/Projetos"

# proj
# *: Nome do projeto
# Comando para alternar para o diretório de um projeto, buscando nos diretórios de projeto
function proj() {
    local projName=${1:-''}
    if [[ "$projName" == "" ]]; then
        cd "$DEV/Projetos"
        return 0
    fi

    if [[ -d "$DEV/Projetos/$projName" ]]; then
        cd "$DEV/Projetos/$projName"
        return 0
    fi

    readarray -t projects < <(find $DEV/Projetos -mindepth 1 -maxdepth 2 -type d | sed "s#$DEV/Projetos/##g" | grep -a "$projName")
    if [[ ${#projects[@]} -eq 0 ]]; then
        log-error "Nenhum projeto encontrado com a expressão \"$projName\""
        return 1
    fi

    if [[ ${#projects[@]} -eq 1 ]]; then
        cd "$DEV/Projetos/${projects[0]}"
        return 0
    fi

    for project in "${projects[@]}"; do
        if [[ "$project" == "$projName" ]]; then
            cd "$DEV/Projetos/$project"
            return 0
        fi
    done

    log-info "Mais de um projeto encontrado com a expressão \"$projName\":"
    for project in "${projects[@]}"; do
        log-info "  - $project"
    done
}

# wd
# [1] - Nome adicional para o diretório de trabalho
# Alterna para um diretório de trabalho temporário
# O diretório é criado caso não exista
function wd() {
    local targetDirectory="${DEV}/wd"
    local customWD="$1"
    [[ -z "$customWD" ]] && targetDirectory="${targetDirectory}/${customWD}"
    [[ ! -d "$targetDirectory" ]] && {
        [[ -f "$targetDirectory" ]] && rm -rf "$targetDirectory"
        mkdir "$targetDirectory"
    }
    cd "$targetDirectory"
}

# apt-upgrade
# Atualiza o sistema.
# Apenas faz sentido quando utilizado com WSL
function apt-upgrade() {
    local LOG_FILE='/tmp/apt-upgrade.log'

    log-info 'Atualizando repositórios ...'
    sudo bash -c "apt update > '${LOG_FILE}' 2>&1 || { log-error 'Ocorreu um erro\!'; cat '${LOG_FILE}'; return 1; }"

    log-info 'Atualizando sistema ...'
    sudo bash -c "apt dist-upgrade -y --no-install-recommends >> '${LOG_FILE}' 2>&1 || { log-error 'Ocorreu um erro\!'; cat '${LOG_FILE}'; return 1; }"

    log-info 'Removendo pacotes desnecessários ...'
    sudo bash -c "apt autoremove --purge -y >> '${LOG_FILE}' 2>&1 || { log-error 'Ocorreu um erro!'; cat '${LOG_FILE}'; return 1; }"

    log-info 'Limpando pacotes antigos ...'
    sudo bash -c "apt autoclean -y >> '${LOG_FILE}' 2>&1 || { log-error 'Ocorreu um erro!'; cat '${LOG_FILE}'; return 1; }"

    log-success 'Finalizado'
}
