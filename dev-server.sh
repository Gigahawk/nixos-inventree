#!/usr/bin/env bash

cleanup() {
  echo "Killing child processes"
  kill 0
}

trap cleanup EXIT
trap 'exit 130' INT  # Ctrl+C
trap 'exit 143' TERM # kill (default SIGTERM)

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
SRV_ROOT="$SCRIPT_DIR/.scratch/dev-server"
STATIC_ROOT="$SRV_ROOT/static"
MEDIA_ROOT="$SRV_ROOT/media"
BACKUP_DIR="$SRV_ROOT/backup"
DB_NAME="$SRV_ROOT/db.sqlite"
CONFIG_FILE="$SRV_ROOT/config.yaml"
PLUGIN_DIR="$SRV_ROOT/plugins"
PLUGIN_FILE="$SRV_ROOT/plugins.txt"

mkdir -p "$SRV_ROOT"

export INVENTREE_STATIC_ROOT="$STATIC_ROOT"
export INVENTREE_MEDIA_ROOT="$MEDIA_ROOT"
export INVENTREE_BACKUP_DIR="$BACKUP_DIR"
export INVENTREE_CONFIG_FILE="$CONFIG_FILE"
export INVENTREE_PLUGIN_DIR="$PLUGIN_DIR"
export INVENTREE_PLUGIN_FILE="$PLUGIN_FILE"

export INVENTREE_DB_ENGINE="sqlite3"
export INVENTREE_DB_NAME="$DB_NAME"
export INVENTREE_SITE_URL="http://localhost:8000"

export INVENTREE_DEBUG="True"
export INVENTREE_PLUGINS_ENABLED="True"
export INVENTREE_LOG_LEVEL="INFO"

export INVENTREE_ADMIN_ENABLED="True"
export INVENTREE_ADMIN_USER="admin"
export INVENTREE_ADMIN_PASSWORD="admin"
export INVENTREE_ADMIN_EMAIL="admin@localhost"

echo "=== Running migrations ==="
inventree-invoke migrate

# echo "=== Installing plugins ==="
# inventree-invoke plugins

echo "=== Starting worker in background ==="
inventree-cluster &

echo "=== Starting server ==="
inventree-server
