#!/bin/bash
# init.sh/init.sh

# Este script é responsável por inicializar o ambiente, chamando os demais scripts de inicialização

# Estágios
# 00 - 09: Inicialização do ambiente
# 10 - 19: Comandos e integração
# 20 - 29: Configuração de rede
# 30 - 89: SEM USO
# 90 - 99: Finalização do ambiente

# Autoexec
START_TIME=$(date +%s%3N)

echo "Iniciando ..."

for sh in $BASH_INIT/init.sh/*_init_*.sh; do
    [[ -e "$sh" ]] || continue
    echo "Executando script: $(sed 's#.*\/##g' <<< $sh)"
    . $sh
    if [[ $? -ne 0 ]]; then
        echo -e "${C_ERROR}Falhou ao executar \!\!\!${C_CLEAR}"
    fi
done

echo -e "${C_GREEN}Kernel iniciado a `awk '{print $1*1000}' /proc/uptime`ms${C_CLEAR}"
echo -e "${C_GREEN}Iniciado em $(( $(date +%s%3N) - $START_TIME ))ms\033${C_CLEAR}"

unset START_TIME
