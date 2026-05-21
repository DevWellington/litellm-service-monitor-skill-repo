#!/bin/bash
# LiteLLM Proxy Daemon Controller
# This script manages the LiteLLM Proxy process (start, stop, status, logs).
# It loads environments from .env and executes via the local python/litellm.

LITELLM_DIR="/app/vt422387/litellm"
LITELLM_BIN="/home/vt422387/.local/bin/litellm"
DEFAULT_PORT="4000"
DEFAULT_HOST="127.0.0.1"

# Automatically fallback to /opt/litellm if it exists and is preferred
if [ -d "/opt/litellm" ]; then
    LITELLM_DIR="/opt/litellm"
fi

CONFIG_FILE="${LITELLM_DIR}/config.yaml"
ENV_FILE="${LITELLM_DIR}/.env"
PID_FILE="${LITELLM_DIR}/litellm.pid"
LOG_DIR="${LITELLM_DIR}/logs"
LOG_FILE="${LOG_DIR}/litellm-stdout.log"

# Create directories
mkdir -p "$LOG_DIR"

show_help() {
    echo "LiteLLM Daemon - Controller"
    echo "Usage: $0 <action> [options]"
    echo ""
    echo "Actions:"
    echo "  start           Starts the LiteLLM server"
    echo "  stop            Stops the running LiteLLM server"
    echo "  status          Checks server status and port"
    echo "  logs            Displays server stdout and error logs"
    echo "  restart         Restarts the LiteLLM server"
    echo ""
    echo "Options for 'start':"
    echo "  -p, --port <port>   Specify the port (default: $DEFAULT_PORT)"
    echo "  -h, --host <host>   Specify the bind host (default: $DEFAULT_HOST)"
    echo "  --foreground        Start in foreground mode (keeps terminal attached)"
    echo ""
    echo "Options for 'logs':"
    echo "  Any tail options can be passed (e.g., -f to follow, -n 200)"
}

ACTION="$1"
if [ -z "$ACTION" ]; then
    show_help
    exit 0
fi
shift

# Parse options
PORT=""
HOST=""
FOREGROUND=false
OTHER_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -h|--host)
            HOST="$2"
            shift 2
            ;;
        --foreground)
            FOREGROUND=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            OTHER_ARGS+=("$1")
            shift
            ;;
    esac
done

# Defaults
if [ -z "$PORT" ]; then PORT="$DEFAULT_PORT"; fi
if [ -z "$HOST" ]; then HOST="$DEFAULT_HOST"; fi

# Function to load env variables from .env
load_env() {
    if [ -f "$ENV_FILE" ]; then
        echo "Carregando variáveis de ambiente do .env..."
        # Export all lines that are not comments
        export $(grep -v '^#' "$ENV_FILE" | xargs)
    else
        echo "Aviso: arquivo .env não encontrado em $ENV_FILE"
    fi
}

start_server() {
    # Check if already running
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" >/dev/null 2>&1; then
            echo "LiteLLM já está rodando (PID: $PID)."
            exit 1
        fi
        rm -f "$PID_FILE"
    fi

    # Verify if port is occupied
    if ss -tuln | grep -qE ":$PORT[[:space:]]" 2>/dev/null; then
        echo "Erro: A porta $PORT já está em uso neste servidor!"
        exit 1
    fi

    load_env

    # Run command
    CMD_ARGS=("--config" "$CONFIG_FILE" "--host" "$HOST" "--port" "$PORT")
    if [ ${#OTHER_ARGS[@]} -gt 0 ]; then
        CMD_ARGS+=("${OTHER_ARGS[@]}")
    fi

    echo "Iniciando LiteLLM em http://${HOST}:${PORT}..."
    if [ "$FOREGROUND" = true ]; then
        exec "$LITELLM_BIN" "${CMD_ARGS[@]}"
    else
        # Run in background
        nohup "$LITELLM_BIN" "${CMD_ARGS[@]}" > "$LOG_FILE" 2>&1 &
        BG_PID=$!
        
        # Verify success
        HEALTHY=false
        for i in {1..20}; do
            sleep 0.5
            if ! ps -p "$BG_PID" > /dev/null 2>&1; then
                break
            fi
            if ss -tuln | grep -qE ":$PORT[[:space:]]" 2>/dev/null; then
                HEALTHY=true
                break
            fi
        done

        if [ "$HEALTHY" = true ]; then
            echo "$BG_PID" > "$PID_FILE"
            echo "LiteLLM iniciado com sucesso! (PID: $BG_PID)"
            echo "Acesse em: http://${HOST}:${PORT}"
        else
            echo "Erro: LiteLLM falhou ao iniciar na porta $PORT."
            echo "Verifique os logs usando: $0 logs"
            exit 1
        fi
    fi
}

stop_server() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "Parando LiteLLM (PID: $PID)..."
            kill "$PID" 2>/dev/null
            sleep 1.5
            if ps -p "$PID" > /dev/null 2>&1; then
                echo "Processo não respondeu ao sinal SIGTERM, forçando SIGKILL..."
                kill -9 "$PID" 2>/dev/null
            fi
            echo "LiteLLM parado com sucesso."
        else
            echo "O processo com PID $PID não está ativo. Limpando arquivo de PID."
        fi
        rm -f "$PID_FILE"
    else
        # Fallback search by process name for the current user
        SERVER_PIDS=$(pgrep -u "$(whoami)" -f 'litellm.*--config')
        if [ -n "$SERVER_PIDS" ]; then
            echo "Parando processos do LiteLLM encontrados..."
            echo "$SERVER_PIDS" | xargs kill 2>/dev/null
            sleep 1
            echo "$SERVER_PIDS" | xargs kill -9 2>/dev/null
            echo "LiteLLM parado."
        else
            echo "Nenhum servidor LiteLLM ativo encontrado."
        fi
    fi
}

status_server() {
    SERVER_PID=""
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            SERVER_PID="$PID"
        fi
    fi

    if [ -z "$SERVER_PID" ]; then
        SERVER_PID=$(pgrep -u "$(whoami)" -f 'litellm.*--config' | head -n 1)
    fi

    if [ -n "$SERVER_PID" ]; then
        echo "Status: ATIVO (Rodando)"
        echo "PID: $SERVER_PID"
        # Find port
        BOUND_PORT=$(ss -tulnp 2>/dev/null | grep -E "pid=$SERVER_PID" | awk '{print $5}' | awk -F':' '{print $NF}' | head -n 1)
        if [ -n "$BOUND_PORT" ]; then
            echo "Porta: $BOUND_PORT"
        fi
    else
        echo "Status: INATIVO (Parado)"
    fi
}

show_logs() {
    if [ -f "$LOG_FILE" ]; then
        echo "=== LiteLLM Console Logs ($LOG_FILE) ==="
        FOLLOW=false
        for arg in "${OTHER_ARGS[@]}"; do
            if [ "$arg" = "-f" ] || [ "$arg" = "--follow" ]; then
                FOLLOW=true
            fi
        done

        if [ "$FOLLOW" = true ]; then
            tail -f -n 100 "$LOG_FILE"
        elif [ ${#OTHER_ARGS[@]} -gt 0 ]; then
            tail "${OTHER_ARGS[@]}" "$LOG_FILE"
        else
            tail -n 100 "$LOG_FILE"
        fi
    else
        echo "Nenhum log encontrado em $LOG_FILE"
    fi
}

case "$ACTION" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        stop_server
        sleep 1
        start_server
        ;;
    status)
        status_server
        ;;
    logs)
        show_logs
        ;;
    *)
        echo "Ação desconhecida: $ACTION"
        show_help
        exit 1
        ;;
esac
