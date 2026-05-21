# LiteLLM Gateway Deployment

*Read this in other languages: [Português](#português)*

This repository contains the configuration, environment setups, and daemon management script for **LiteLLM Proxy Server** on RHEL 8.10.

LiteLLM provides an OpenAI-compatible translation proxy for various model providers (Google Gemini, Anthropic Claude, OpenAI, Ollama, etc.).

---

## Contents of the Bundle

* **`config.yaml`**: The main configuration file defining the model list (e.g. Gemini), fallback settings, database routing, etc.
* **`litellm-control.sh`**: A production-grade controller script to manage LiteLLM in daemon mode (`start`, `stop`, `restart`, `status`, `logs`).
* **`.env`**: Portability file containing proxy settings (`HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY`) and API keys (e.g., `GOOGLE_API_KEY`).

---

## Installation & Usage

### 1. Requirements
* LiteLLM python package installed (e.g., `pip install litellm` or `pip install 'litellm[proxy]'`).
* Python 3.8+ compatibility.

### 2. Basic Execution using the daemon script
You can use the controller to manage the background daemon easily:

```bash
# Start LiteLLM daemon on port 4000
./litellm-control.sh start --port 4000

# Check status of the running daemon
./litellm-control.sh status

# Monitor the log file
./litellm-control.sh logs

# Stop the daemon
./litellm-control.sh stop
```

### 3. Placing as a System-wide Command (Optional)
To run `litellm` commands globally as any user on the system, you can symlink or copy this script to `/usr/local/bin`:

```bash
sudo cp /app/vt422387/litellm/litellm-control.sh /usr/local/bin/litellm-control
sudo chmod +x /usr/local/bin/litellm-control
```

Then simply manage the proxy using:
```bash
litellm-control start -p 4000
litellm-control status
litellm-control stop
```

---

<a name="português"></a>

# Gateway LiteLLM - Implantação e Controle

Este repositório contém os arquivos de configuração, variáveis de ambiente e scripts de controle de processo daemon para o **LiteLLM Proxy Server** em ambiente RHEL 8.10.

O LiteLLM provê uma API gateway compatível com o padrão OpenAI para traduzir requisições para diversos provedores de LLM (como Google Gemini, Anthropic Claude, OpenAI, Ollama, etc.).

---

## Conteúdo do Repositório

* **`config.yaml`**: Arquivo de definição de modelos (ex: Gemini 3.1 Pro), roteamento, chaves mestras e bancos de dados.
* **`litellm-control.sh`**: Script controlador de daemon completo para gerenciar o processo em plano de fundo (`start`, `stop`, `restart`, `status`, `logs`).
* **`.env`**: Arquivo com configurações de proxy corporativo da rede e chaves privadas (`GOOGLE_API_KEY`).

---

## Como Executar

Utilize o script de controle para gerenciar o servidor de forma limpa:

```bash
# Iniciar o servidor LiteLLM na porta 4000
./litellm-control.sh start --port 4000

# Verificar status do servidor ativo
./litellm-control.sh status

# Monitorar os logs em tempo real
./litellm-control.sh logs

# Parar o serviço
./litellm-control.sh stop
```

### Tornando o Comando Global (Opcional)
Para executar os comandos do proxy de qualquer lugar do sistema, instale o script no `/usr/local/bin`:

```bash
sudo cp /app/vt422387/litellm/litellm-control.sh /usr/local/bin/litellm-control
sudo chmod +x /usr/local/bin/litellm-control
```

E gerencie usando:
```bash
litellm-control start
litellm-control status
litellm-control stop
```
