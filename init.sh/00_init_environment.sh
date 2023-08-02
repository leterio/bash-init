#!/bin/bash
# init.sh/00_init_environment.sh
# Este script provê as constantes básicas para o shell e demais scripts

# PS1_with_git_on_root
# Ajusta o formato padrão do prompt para incluir a informação da branch atual apenas na raíz do repositório
function PS1_with_git_on_root() {
    export PS1='\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;96m\]$([[ -d '.git' ]] && { unalias git; __git_ps1; })\[\033[00m\] \$ '
}

# PS1_with_git
# Ajusta o formato padrão do prompt para incluir a informação da branch atual
function PS1_with_git() {
    export PS1='\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;96m\]$(unalias git; __git_ps1)\[\033[00m\] \$ '
}

PS1_with_git
