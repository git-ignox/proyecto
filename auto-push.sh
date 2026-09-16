#!/bin/bash

# Configuración de entorno básica
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

PROJECT_DIR="/Users/ignox/Desktop/proyecto"
LOG_FILE="$PROJECT_DIR/auto-push.log"

# Asegurar que estamos en el directorio del proyecto
cd "$PROJECT_DIR" || {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Error: No se pudo acceder a $PROJECT_DIR" >> "$LOG_FILE"
    exit 1
}

# Agregar todos los cambios
git add .

# Verificar si hay cambios preparados (staged)
if ! git diff --cached --quiet; then
    FECHA=$(date '+%Y-%m-%d %H:%M:%S')
    git commit -m "Actualización automática: $FECHA" >> "$LOG_FILE" 2>&1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Commit realizado con éxito." >> "$LOG_FILE"
fi

# Verificar si la rama local está por delante de origin/main o si hay cambios pendientes por subir
git fetch origin main >> "$LOG_FILE" 2>&1

LOCAL=$(git rev-parse HEAD 2>/dev/null)
REMOTE=$(git rev-parse origin/main 2>/dev/null)

if [ "$LOCAL" != "$REMOTE" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Hay cambios pendientes. Haciendo git push origin main..." >> "$LOG_FILE"
    git push origin main >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Push completado con éxito." >> "$LOG_FILE"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Error al hacer push." >> "$LOG_FILE"
    fi
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Repositorio al día. Nada que subir." >> "$LOG_FILE"
fi
