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
