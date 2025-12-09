#!/bin/bash

################################################################################
# Script de instalación guiada de WireGuard (Servidor VPS, con Docker)
# - Detecta IP pública automáticamente
# - Crea carpeta ./wireguard y docker-compose.yml
# - Abre puerto 51820/UDP con iptables
# - Lanza el contenedor y genera configuración
# - Muestra datos importantes en pantalla (IP, claves, etc.)
#
# Uso:
#   chmod +x setup_wireguard_vps.sh
#   sudo ./setup_wireguard_vps.sh
################################################################################

set -e

PORT=51820
WG_DIR="$HOME/wireguard"
CONFIG_DIR="$WG_DIR/config"
COMPOSE_FILE="$WG_DIR/docker-compose.yml"

clear
echo "============================================================"
echo "  INSTALADOR GUIADO DE WIREGUARD EN TU VPS (MODO SENCILLO)  "
echo "============================================================"
echo
echo "Este script va a hacer en tu VPS (servidor externo):"
echo "  1) Detectar tu IP pública"
echo "  2) Crear la carpeta 'wireguard' con la configuración"
echo "  3) Crear un docker-compose.yml para WireGuard"
echo "  4) Abrir el puerto UDP $PORT con iptables"
echo "  5) Levantar el contenedor y generar configuración"
echo "  6) Mostrarte la información necesaria para conectar tu casa"
echo
read -p "¿Quieres continuar? (s/N): " CONT
CONT=${CONT:-n}
if [[ "$CONT" != "s" && "$CONT" != "S" ]]; then
  echo "Proceso cancelado."
  exit 0
fi

echo
echo "Paso 1: Detectando IP pública de tu VPS..."
echo "------------------------------------------"

if command -v curl >/dev/null 2>&1; then
  PUBLIC_IP=$(curl -s ifconfig.me || true)
elif command -v wget >/dev/null 2>&1; then
  PUBLIC_IP=$(wget -qO- ifconfig.me || true)
else
  PUBLIC_IP=""
fi

if [[ -z "$PUBLIC_IP" ]]; then
  echo "No se pudo detectar automáticamente la IP pública."
  read -p "Escribe manualmente la IP pública de tu VPS: " PUBLIC_IP
fi

echo
echo "Hemos detectado esta IP pública: $PUBLIC_IP"
read -p "¿Es correcta? (s/N): " OK_IP
OK_IP=${OK_IP:-n}
if [[ "$OK_IP" != "s" && "$OK_IP" != "S" ]]; then
  read -p "Escribe la IP pública correcta de tu VPS: " PUBLIC_IP
fi

echo
echo "Perfecto. Usaremos la IP pública: $PUBLIC_IP"
echo
read -p "Pulsa ENTER para continuar al Paso 2..." _

echo
echo "Paso 2: Creando carpetas de trabajo..."
echo "--------------------------------------"
mkdir -p "$CONFIG_DIR"
echo "Carpeta creada: $WG_DIR"
echo "Carpeta de configuración: $CONFIG_DIR"
echo
read -p "Pulsa ENTER para continuar al Paso 3..." _

echo
echo "Paso 3: Creando docker-compose.yml para WireGuard..."
echo "----------------------------------------------------"

cat > "$COMPOSE_FILE" <<EOF
version: '3.8'
services:
  wireguard:
    image: lscr.io/linuxserver/wireguard:latest
    container_name: wireguard
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - SERVERPORT=$PORT
      - PEERS=4
      - PEERDNS=1.1.1.1
      - INTERNAL_SUBNET=10.69.69.0
    volumes:
      - ./config:/config
      - /lib/modules:/lib/modules
    ports:
      - $PORT:$PORT/udp
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
      - net.ipv4.ip_forward=1
    restart: unless-stopped
EOF

echo "Archivo docker-compose.yml creado en: $COMPOSE_FILE"
echo
read -p "Pulsa ENTER para continuar al Paso 4..." _

echo
echo "Paso 4: Habilitando reenvío de IP y abriendo puerto $PORT/udp..."
echo "----------------------------------------------------------------"

# Habilitar IP forwarding
sysctl -w net.ipv4.ip_forward=1 >/dev/null
if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf 2>/dev/null; then
  echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi

# Abrir puerto con iptables (INPUT para UDP $PORT)
iptables -I INPUT -p udp --dport $PORT -j ACCEPT || true

echo "Se ha habilitado el reenvío de IP y se ha abierto el puerto $PORT/udp."
echo "OJO: Si tu proveedor (Oracle, etc.) tiene firewall propio, tendrás que"
echo "abrir también el puerto $PORT/udp allí manualmente."
echo
read -p "Pulsa ENTER para continuar al Paso 5..." _

echo
echo "Paso 5: Arrancando el contenedor de WireGuard con Docker..."
echo "-----------------------------------------------------------"
cd "$WG_DIR"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker no está instalado en este servidor."
  echo "Instala Docker y vuelve a ejecutar este script."
  exit 1
fi

if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
  echo "ERROR: docker-compose no está instalado."
  echo "Instala docker-compose o Docker con 'docker compose' y vuelve a ejecutar este script."
  exit 1
fi

# Soportar tanto 'docker-compose' clásico como 'docker compose'
if command -v docker-compose >/dev/null 2>&1; then
  DC_CMD="docker-compose"
else
  DC_CMD="docker compose"
fi

$DC_CMD up -d

echo
echo "Esperando unos segundos a que WireGuard genere la configuración..."
sleep 10

echo
echo "Paso 6: Mostrando información importante generada..."
echo "----------------------------------------------------"

if [[ ! -d "$CONFIG_DIR" ]]; then
  echo "ERROR: No se encontró la carpeta de configuración: $CONFIG_DIR"
  exit 1
fi

SERVER_CONF="$CONFIG_DIR/wg0.conf"

if [[ ! -f "$SERVER_CONF" ]]; then
  # linuxserver/wireguard suele generar los peers en subcarpetas
  SERVER_CONF_ALT=$(find "$CONFIG_DIR" -maxdepth 2 -name "wg0.conf" | head -n 1)
  if [[ -n "$SERVER_CONF_ALT" ]]; then
    SERVER_CONF="$SERVER_CONF_ALT"
  fi
fi

if [[ -f "$SERVER_CONF" ]]; then
  echo "Se ha encontrado el archivo de configuración del servidor:"
  echo "  $SERVER_CONF"
else
  echo "AVISO: No se encontró wg0.conf aún. Puede que el contenedor tarde"
  echo "unos segundos más en generarlo. Revisa luego en:"
  echo "  $CONFIG_DIR"
fi

echo
echo "=== RESUMEN DE DATOS IMPORTANTES ==="
echo
echo "1) IP PÚBLICA DE TU VPS (para usar en 'Endpoint' en tu casa):"
echo "   $PUBLIC_IP:$PORT"
echo
echo "2) Carpeta de configuración de WireGuard en el VPS:"
echo "   $CONFIG_DIR"
echo
echo "3) Para ver el estado de WireGuard (como usuario avanzado):"
echo "   cd $WG_DIR"
echo "   $DC_CMD logs -f"
echo
echo "4) Los ficheros de cliente (peers) para móviles u otros equipos"
echo "   se encuentran en subcarpetas dentro de:"
echo "   $CONFIG_DIR"
echo "   (por ejemplo peer1, peer2, etc.)"
echo
echo "A partir de aquí, en tu dispositivo de casa (Raspberry, CasaOS, etc.),"
echo "deberás crear una configuración de cliente WireGuard que apunte a:"
echo
echo "   Endpoint = $PUBLIC_IP:$PORT"
echo
echo "y usar la clave pública del servidor/peer correspondiente."
echo
echo "El servidor WireGuard en tu VPS ya está listo."
echo
echo "Proceso completado."
echo "============================================================"
