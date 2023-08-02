#!/bin/bash
# init.sh/10_init_windows_integration.sh
# Este script provê funções para integração do WSL com o Windows

# Invoca corretamente o WSL (Win)
alias wsl="/mnt/c/windows/system32/wsl.exe"

# explorer
# [1] - Diretório a ser aberto
# Abre o MSExplorer no diretório solicitado
function explorer() {
    local target=$(wslpath -w "${1:-.}")
    log-info "Abrindo explorer ..."
    (/mnt/c/Windows/explorer.exe "$target" &) >/dev/null 2>&1
}

# code
# [1] - Diretório ou arquivo a ser aberto
# Abre o VSCode no windows utilizando os parametros informados
function code() {
    local vscodeBinArr=("/mnt/c/Program Files/Microsoft VS Code/Code.exe" "/mnt/c/Users/$(cmd.exe /C echo %USERNAME% | dos2unix | sed -z 's/\n//g')/AppData/Local/Programs/Microsoft VS Code/Code.exe")
    local vscodeBin=''
    for checkBin in "${vscodeBinArr[@]}"; do
        if [[ -f "$checkBin" ]]; then
            vscodeBin="$checkBin"
            break
        fi
    done
    if [[ ! -f "$vscodeBin" ]]; then
        log-error "Executável do VSCode não encontrado"
        return 1
    fi

    local target=
    if [[ $# -gt 0 ]]; then
        local target=$(wslpath -w "$1")
        shift
    fi

    log-info "Abrindo VSCode ..."
    ("$vscodeBin" -n "$target" &) >/dev/null 2>&1
}

# cdw
# 1 - Diretório em formato Windows
# Alterna de diretório utilizando o formato utilizado pelo Windows
#     Ex: cdw 'C:\\Users\\myUser\\Desktop'
function cdw() {
    [[ $# -ne 1 ]] && {
        log-error "Um caminho deve ser especificado"
        return 1
    }
    cd "$(wslpath "$1")"
}
