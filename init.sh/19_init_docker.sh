#!/bin/bash
# init.sh/19_init_docker.sh
# Este script só faz sentido quando houver um registry personalizado padrão

# docker-prune
# Efetua a limpeza de todos os dados sem uso no docker
function docker-prune() {
    docker system prune -fa
    docker volume prune -f
    docker network prune -f
}
