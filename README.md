# BASH INIT

Coleção de scripts para auxiliar no uso do terminal.

Pensado para uso com WSL, mas pode ser ajustado e usado em VMs, na sua máquina ou GITBash.

## Ativando

Para ativar, edite o script de inicialização do Bash (`.bashrc`) em seu diretório de usuário.

Ao final do arquivo, insira o conteúdo:

```shell
export DEV="SEU DIRETÓRIO DE DESNVOLVIMENTO"   # Ex: ~/dev
export SCRIPTS="DIRETÓRIO DE SCRIPTS"          # Ex: $DEV/Scripts
export BASH_INIT="DIRETÓRIO DESTE REPOSITÓRIO" # Ex: $SCRIPTS/bash-init
find "$SCRIPTS/bin" -type f -exec chmod +x {} \;
find "$BASH_INIT/bin" -type f -exec chmod +x {} \;
export PATH=$SCRIPTS/bin:$BASH_INIT/bin:$PATH
. $BASH_INIT/init.sh/init.sh
```

## Conteúdo

### bin

Contém scripts utilzáveis por outros scripts (PATH)

### bin/modules

Contém módulos utilizaveis no shell e, caso importados, podem ser utilizados em scripts

### init.sh

Contém scripts que configuram o shell no momento da inicialização.

## Estágios do init.sh

- 00 - 09: Inicialização do ambiente
  - 00_init_environment.sh - Configura variáveis de ambiente
  - 01_init_base_modules.sh - Inicia os módulos básicos para o ambiente
- 10 - 19: Comandos e integração
  - 10_init_commands.sh - Inicializa as funções e aliases utilitários
  - 10_init_windows_integration.sh - Inicializa as funções e aliases para integração com ferramentas Windows
- 20 - 29: Configuração de rede
  - Nenhum script pré-configurado
- 90 - 99: Finalização do ambiente
    - Nenhum script pré-configurado

