#!/bin/bash
# init.sh/00_init_environment.sh
# Este script provê as constantes básicas para o shell e demais scripts

export PS1='\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;96m\]$(unalias git; __git_ps1;)\[\033[00m\] \$ '
