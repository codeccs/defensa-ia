#!/usr/bin/env bash
# Instalador del Lab Defensa IA para Kali Linux (y Debian/Ubuntu)
# Uso:  ./instalar.sh            -> instala Docker si falta y arranca el lab
#       LLM_MODELO=qwen2.5:7b ./instalar.sh   -> usa otro modelo
set -e
cd "$(dirname "$0")"

echo "== Lab Defensa IA: instalación =="

# 1. Docker
if ! command -v docker >/dev/null 2>&1; then
  echo "-> Instalando Docker..."
  sudo apt update
  sudo apt install -y docker.io docker-compose
fi
sudo systemctl enable --now docker >/dev/null 2>&1 || true

# 2. ¿Hace falta sudo para usar Docker?
if docker info >/dev/null 2>&1; then DOCKER="docker"; else DOCKER="sudo docker"; fi

# 3. docker compose (v2) o docker-compose
if $DOCKER compose version >/dev/null 2>&1; then
  COMPOSE="$DOCKER compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE="sudo docker-compose"; [ "$DOCKER" = "docker" ] && COMPOSE="docker-compose"
else
  echo "-> Instalando docker-compose..."
  sudo apt install -y docker-compose
  COMPOSE="sudo docker-compose"; [ "$DOCKER" = "docker" ] && COMPOSE="docker-compose"
fi

# 4. Arrancar
echo "-> Construyendo y arrancando contenedores (la primera vez descarga el modelo, ~2 GB)..."
$COMPOSE up -d --build

# 5. Esperar a que el lab responda
PUERTO="${LAB_PUERTO:-8000}"
echo -n "-> Esperando a que el lab esté listo"
for i in $(seq 1 360); do
  if curl -s "http://localhost:${PUERTO}/api/salud" >/dev/null 2>&1; then
    echo
    echo "== Listo: abre http://localhost:${PUERTO} =="
    command -v xdg-open >/dev/null 2>&1 && xdg-open "http://localhost:${PUERTO}" >/dev/null 2>&1 &
    exit 0
  fi
  if [ $((i % 12)) -eq 0 ]; then
    echo; echo "   (sigue descargando el modelo... último estado:)"
    $COMPOSE logs --tail 1 modelo 2>/dev/null | tail -1
    echo -n "   "
  fi
  echo -n "."
  sleep 5
done
echo
echo "El lab no respondió en 30 minutos. Revisa: $COMPOSE ps  y  $COMPOSE logs"
exit 1
