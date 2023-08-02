#!/bin/bash
# init.sh/19_init_docker.sh
# Este script provê funções e comandos básicos para uso do docker

command -v docker 2>&1 >/dev/null || exit 0

# docker-prune
# Efetua a limpeza de todos os dados sem uso no docker
function docker-prune() {
    log-info "Prunning System ..."
    docker system prune -fa >/dev/null

    log-info "Prunning Volumes ..."
    docker volume prune -f >/dev/null

    log-info "Prunning networks ..."
    docker network prune -f >/dev/null
}
