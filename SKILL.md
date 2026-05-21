---
name: litellm-service-monitor
description: Gerenciamento do ciclo de vida do LiteLLM Proxy (inicialização, logs, status, parada e monitoramento do serviço via daemon controller).
category: devops
---

# LiteLLM Gateway & Service Monitor

Este skill fornece instruções e comandos para gerenciar a execução em segundo plano (modo Daemon) do LiteLLM Proxy neste ambiente. O script completo de produção está disponível em `/usr/local/bin/litellm-control`.

## Estrutura do Projeto
- **Script Wrapper Global:** `/usr/local/bin/litellm-control` (executável por qualquer usuário, linkado ao script original).
- **Código Fonte e Configurações:** `/app/vt422387/litellm`
- **Arquivo de Configuração (YAML):** `/app/vt422387/litellm/config.yaml`
- **Arquivo de Variáveis de Ambiente:** `/app/vt422387/litellm/.env`
- **Logs de Console/Stdout:** `/app/vt422387/litellm/logs/litellm-stdout.log`
- **Arquivo de PID:** `/app/vt422387/litellm/litellm.pid`

## Comandos Disponíveis

O wrapper `litellm-control` simplifica todo o ciclo de vida do proxy de modelos:

### 1. Iniciar o Servidor (`start`)
Inicia o servidor LiteLLM em segundo plano por padrão (modo daemon):
```bash
litellm-control start
```
- **Porta Personalizada:** Se você quiser iniciar em uma porta diferente da padrão (`4000`), use a opção `-p` ou `--port`:
  ```bash
  litellm-control start -p 4001
  ```
- **Host de Ligação:** Por padrão, liga-se a `127.0.0.1`. Se necessário, use `-h` ou `--host` para definir o bind host:
  ```bash
  litellm-control start -h 127.0.0.1
  ```
- **Modo Foreground:** Útil para debugar ou ver mensagens de inicialização diretamente no console ativo:
  ```bash
  litellm-control start --foreground
  ```

### 2. Verificar Status (`status`)
Verifica se o servidor do LiteLLM está ativo para o seu usuário atual, identificando o PID e a porta que está em escuta:
```bash
litellm-control status
```

### 3. Visualizar Logs (`logs`)
Exibe as últimas linhas de log capturadas do stdout/stderr do LiteLLM:
```bash
litellm-control logs
```
- **Acompanhamento em Tempo Real (Follow):** Para monitorar as requisições em tempo real à medida que ocorrem, passe a opção `-f` ou `--follow`:
  ```bash
  litellm-control logs -f
  ```
- **Limitar Quantidade de Linhas:** É possível passar qualquer argumento do comando `tail` (ex: `-n 200` para mostrar as últimas 200 linhas):
  ```bash
  litellm-control logs -n 200
  ```

### 4. Reiniciar o Servidor (`restart`)
Para aplicar alterações no arquivo `config.yaml` ou `.env`, reinicie o serviço facilmente:
```bash
litellm-control restart
```

### 5. Parar o Servidor (`stop`)
Para interromper o serviço e liberar as portas ocupadas:
```bash
litellm-control stop
```

## Solução de Problemas & Ajustes Corporativos (V.tal)

### Erros de Proxy (403 Forbidden / Prisma Engine Startup Crash)
Em ambientes corporativos rígidos com interceptação SSL e proxies de segurança, o LiteLLM pode falhar ao inicializar devido a conexões locais de loopback serem interceptadas pelo proxy externo.
- Certifique-se de que o seu `.env` ou variáveis do sistema contenham o bypass para localhost:
  ```bash
  export NO_PROXY="localhost,127.0.0.1,::1"
  export no_proxy="localhost,127.0.0.1,::1"
  ```

### Limpeza de Estado Travado
Se a máquina ou sessão sofrer uma queda repentina e o comando `status` ou `start` acusar que o serviço está rodando de forma errônea, limpe o arquivo de PID manualmente:
```bash
rm -f /app/vt422387/litellm/litellm.pid
```
