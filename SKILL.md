---
name: litellm
description: Gerenciamento do ciclo de vida e configuração do LiteLLM Proxy Gateway (start, stop, status, logs).
category: devops
---

# LiteLLM Proxy Gateway Management

Este skill fornece instruções e comandos para gerenciar o LiteLLM Proxy Gateway neste ambiente. Ele simplifica a execução do proxy que integra chaves de modelo (como Google Gemini) a interfaces compatíveis com a OpenAI (como o AionUi ou o Hermes WebUI).

## Estrutura do Projeto
- **Diretório de Configuração/Estado:** `/app/vt422387/litellm` (ou `/opt/litellm`)
- **Script Controlador Daemon:** `litellm-control.sh` (executável local ou global via link simbólico)
- **Arquivo de Configuração:** `config.yaml`
- **Variáveis de Ambiente:** `.env` (contendo proxies e chaves de API como `GOOGLE_API_KEY`)
- **Logs de Execução:** `logs/litellm-stdout.log`

## Comandos Disponíveis

O script controlador `litellm-control.sh` gerencia o ciclo de vida do serviço:

### 1. Iniciar o Servidor (`start`)
Inicia o LiteLLM em segundo plano (modo daemon) por padrão:
```bash
./litellm-control.sh start
```
- **Porta Personalizada:** Se quiser forçar uma porta específica (padrão `4000`), use o parâmetro `-p`:
  ```bash
  ./litellm-control.sh start -p 4001
  ```
- **Host Personalizado:** Por padrão, o proxy escuta em `0.0.0.0` para permitir acesso público de outras máquinas da rede. Se precisar restringir a escuta apenas localmente (por exemplo, `127.0.0.1`), use `-h` ou `--host`:
  ```bash
  ./litellm-control.sh start -h 127.0.0.1
  ```
- **Expondo Publicamente em uma Porta Livre (Multi-Instâncias):** Para disponibilizar o LiteLLM para outras máquinas da rede sem conflito com a instância de localhost principal, crie um arquivo de controle separado para evitar colisões de PID (como `litellm-public-control.sh`). 
  
  O script de controle padrão (`litellm-control.sh`) gerencia apenas uma única instância por diretório e trava se o arquivo `litellm.pid` já existir. Para rodar instâncias paralelas (uma local e outra pública), crie um script espelho alterando as seguintes variáveis no cabeçalho:
  ```bash
  DEFAULT_PORT="4001"
  DEFAULT_HOST="0.0.0.0"
  PID_FILE="${LITELLM_DIR}/litellm-public.pid"
  LOG_FILE="${LOG_DIR}/litellm-public-stdout.log"
  ```
  Isso permite gerenciar a instância pública de forma totalmente independente:
  ```bash
  /app/vt422387/litellm/litellm-public-control.sh start
  ```
- **Modo Foreground:** Útil para ver logs em tempo real na tela e debugar a conexão:
  ```bash
  ./litellm-control.sh start --foreground
  ```

### 2. Verificar Status (`status`)
Verifica se o servidor LiteLLM está rodando, mostrando seu PID e porta ativa:
```bash
./litellm-control.sh status
```

### 3. Visualizar Logs (`logs`)
Exibe os logs consolidados de saída (`stdout` e `stderr`) do serviço:
```bash
./litellm-control.sh logs
```
- **Acompanhamento em Tempo Real (Follow):** Use `-f` ou `--follow` para monitorar novas requisições e eventos do LiteLLM em tempo real:
  ```bash
  litellm-control logs -f
  ```
- **Argumentos de Tail Personalizados:** Quaisquer argumentos adicionais passados ao comando serão encaminhados diretamente ao `tail` interno do script (ex: mostrar as últimas 200 linhas de logs):
  ```bash
  litellm-control logs -n 200
  ```

### 4. Parar o Servidor (`stop`)
Encerra o servidor LiteLLM em execução com segurança, limpando os arquivos de controle:
```bash
./litellm-control.sh stop
```

### 5. Reiniciar o Servidor (`restart`)
Para e inicia o serviço novamente, aplicando novas configurações do `config.yaml` ou `.env`:
```bash
./litellm-control.sh restart
```

---

## Execução Global (Instalação no Sistema)
Para tornar o controlador acessível globalmente a partir de qualquer diretório, prefira criar um link simbólico (`ln -sf`) em vez de copiar o arquivo (`cp`). O uso de link simbólico garante que quaisquer modificações ou atualizações feitas no script dentro do repositório Git local reflitam instantaneamente no comando global, sem a necessidade de recópia manual.

Evite usar `litellm-proxy` como nome do arquivo de controle global, pois ele conflita diretamente com o binário nativo do LiteLLM instalado via pip (`~/.local/bin/litellm-proxy`), que tem precedência na variável `$PATH` do usuário.

```bash
sudo ln -sf /app/vt422387/litellm/litellm-control.sh /usr/local/bin/litellm-control
sudo chmod +x /usr/local/bin/litellm-control
```

Após isso, você poderá executar os comandos de forma simples de qualquer diretório:
```bash
litellm-control start
litellm-control status
litellm-control stop
```

---

## LiteLLM Admin UI (Interface Web)
A **LiteLLM Admin UI** não é um serviço separado; ela é integrada e servida de forma nativa pelo próprio processo do LiteLLM Proxy (quando configurada com um banco de dados relacional como PostgreSQL no `config.yaml`).

* **Acesso:** Fica disponível automaticamente na mesma porta configurada, no subcaminho `/ui` (ex: `http://127.0.0.1:4000/ui`).
* **Credenciais de Acesso (Master Key / Password):**
  * Para fazer login ou fazer requisições administrativas na UI, utilize a **Master Key** do LiteLLM como token/senha.
  * No LiteLLM local (daemon), a chave está em `/app/vt422387/litellm/config.yaml` sob `general_settings -> master_key`.
  * Na stack Docker Compose, ela está definida em `/home/vt422387/hermes-stack-vtal/.env` sob `MASTER_KEY` (e injetada via `LITELLM_MASTER_KEY` no arquivo `docker-compose.yml`).
* **Ciclo de vida:** Ao utilizar o controlador `litellm-control`, você está controlando tanto as conexões de API quanto a interface web do painel administrativo conjuntamente. Ao parar ou reiniciar o proxy, a UI seguirá as mesmas ações.

---

## Templates (Docker Stack)
A skill possui templates em `templates/` com a configuração completa e isolada do Docker Compose para rodar o LiteLLM com banco próprio, integrado ao Hermes e WebUI e contornando o proxy corporativo:
- `templates/hermes-stack-docker-compose.yml`

## Solução de Problemas (Troubleshooting)

### Falha ao iniciar por Porta Ocupada
Se o script acusar erro de porta ocupada, verifique qual processo está escutando na porta desejada:
```bash
ss -tulnp | grep -E "4000"
```
Caso queira liberar a porta, use:
```bash
kill $(lsof -t -i:4000)
```

### Configurações de Proxy Corporativo
O LiteLLM requer acesso externo para bater nas APIs de nuvem (ex: Google, Anthropic). Certifique-se de que as variáveis `HTTP_PROXY` e `HTTPS_PROXY` estejam configuradas corretamente no arquivo `.env` localizado no diretório de execução para evitar erros de conexão de rede ou erros 403.

### Erro de Download do Prisma Engine (Offline/Ambiente Restrito)
Em ambientes corporativos rígidos com interceptação SSL e proxies de segurança, o LiteLLM pode falhar ou demorar muito para iniciar devido a tentativas frustradas do Prisma Client de baixar binários do motor de consulta/migração em `https://binaries.prisma.sh` (erro: `unable to get local issuer certificate`).
- **Solução:** Baixe previamente os binários do `query-engine` e `schema-engine` compatíveis com sua arquitetura (ou copie de um diretório existente), dê permissão de execução (`chmod +x`) e configure as seguintes variáveis no seu arquivo `.env`:
  ```env
  PRISMA_QUERY_ENGINE_BINARY=/home/vt422387/prisma-binaries/query-engine
  PRISMA_SCHEMA_ENGINE_BINARY=/home/vt422387/prisma-binaries/schema-engine
  DISABLE_SCHEMA_UPDATE=true
  ```
  Isso desativa qualquer tentativa de download externo do Prisma, acelerando drasticamente o tempo de inicialização do LiteLLM Proxy e evitando falhas de conexão de rede locais. Não envolva os caminhos com aspas duplas no arquivo .env (ex: PRISMA_QUERY_ENGINE_BINARY=/caminho/real), pois isso pode causar erros de importação local no Python e forçar downloads indevidos do Prisma pela rede, falhando o processo todo.

### Falso-Negativo de Inicialização por Demora de Migração do Banco
Se o LiteLLM estiver configurado com banco relacional (ex: PostgreSQL), ele aplicará migrações de banco na inicialização. Em caso de registros duplicados nas tabelas (ex: índices ou tags de *health-check* que quebram `UNIQUE INDEX`), o Prisma pode entrar num loop infinito de tentativas de *rollbacks* e comparações (diffs) de schema a cada inicialização, bloqueando o startup do proxy. Isso pode causar falsos-negativos (timeouts de scripts de health-check/start dizendo que o serviço não subiu na porta) e inflar os processos ocultos do banco de dados.

- **Solução (Contenção Rápida):** Utilize `DISABLE_SCHEMA_UPDATE=true` no arquivo `.env` para pular a rotina de schema e subir o serviço mais rápido.
- **Solução Definitiva:** Exclua manualmente as entradas corrompidas e duplicadas das tabelas no banco de dados para destravar as migrações. Exemplo prático de deduplicação (mantendo apenas uma cópia) usando `ctid` no PostgreSQL para a tabela `LiteLLM_DailyTagSpend`:
  ```sql
  DELETE FROM "LiteLLM_DailyTagSpend" a USING "LiteLLM_DailyTagSpend" b WHERE a.ctid < b.ctid AND a.tag = b.tag;
  ```
- Se o script de controle continuar reportando erro de porta mas o processo aparecer como ativo logo em seguida no `status`, aumente o tempo limite (timeout) do loop de verificação de saúde no script de controle `litellm-control.sh` para `90` iterações de `1s` (ou superior), conforme implementado e verificado na prática para lidar com as inicializações lentas do Prisma.

