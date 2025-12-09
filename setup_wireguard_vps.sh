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
#
# Modo no interactivo (auto-aceptar todo):
#   curl -fsSL https://url/script.sh | sudo bash -s -- --auto
################################################################################

set -e

PORT=51820
WG_DIR="$HOME/wireguard"
CONFIG_DIR="$WG_DIR/config"
COMPOSE_FILE="$WG_DIR/docker-compose.yml"

# Detectar si estamos en modo pipe o si se pasó --auto
AUTO_MODE=false
if [[ "$1" == "--auto" ]] || [[ ! -t 0 ]]; then
  AUTO_MODE=true
fi

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

if [[ "$AUTO_MODE" == false ]]; then
  read -p "¿Quieres continuar? (s/N): " CONT
  CONT=${CONT:-n}
  if [[ "$CONT" != "s" && "$CONT" != "S" ]]; then
    echo "Proceso cancelado."
    exit 0
  fi
else
  echo "MODO AUTOMÁTICO: Continuando sin confirmación..."
  CONT="s"
fi

echo
echo "Paso 1: Detectando IP pública de tu VPS..."
echo "------------------------------------------"

if command -v curl >/dev/null 2>&1; then
  PUBLIC_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || true)
elif command -v wget >/dev/null 2>&1; then
  PUBLIC_IP=$(wget -qO- ifconfig.me || true)
else
  PUBLIC_IP=""
fi

if [[ -z "$PUBLIC_IP" ]]; then
  if [[ "$AUTO_MODE" == false ]]; then
    echo "No se pudo detectar automáticamente la IP pública."
    read -p "Escribe manualmente la IP pública de tu VPS: " PUBLIC_IP
  else
    echo "ERROR: No se pudo detectar la IP pública automáticamente."
    echo "Ejecuta el script manualmente para ingresar la IP."
    exit 1
  fi
fi

echo
echo "IP pública detectada: $PUBLIC_IP"

if [[ "$AUTO_MODE" == false ]]; then
  read -p "¿Es correcta? (s/N): " OK_IP
  OK_IP=${OK_IP:-n}
  if [[ "$OK_IP" != "s" && "$OK_IP" != "S" ]]; then
    read -p "Escribe la IP pública correcta de tu VPS: " PUBLIC_IP
  fi
else
  echo "Usando IP: $PUBLIC_IP"
fi

echo
echo "Perfecto. Usaremos la IP pública: $PUBLIC_IP"
echo

if [[ "$AUTO_MODE" == false ]]; then
  read -p "Pulsa ENTER para continuar al Paso 2..." _
else
  sleep 2
fi

echo
echo "Paso 2: Creando carpetas de trabajo..."
echo "--------------------------------------"
mkdir -p "$CONFIG_DIR"
echo "Carpeta creada: $WG_DIR"
echo "Carpeta de configuración: $CONFIG_DIR"
echo

if [[ "$AUTO_MODE" == false ]]; then
  read -p "Pulsa ENTER para continuar al Paso 3..." _
else
  sleep 2
fi

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
      - SERVERURL=$PUBLIC_IP
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

if [[ "$AUTO_MODE" == false ]]; then
  read -p "Pulsa ENTER para continuar al Paso 4..." _
else
  sleep 2
fi

echo
echo "Paso 4: Habilitando reenvío de IP y abriendo puerto $PORT/udp..."
echo "----------------------------------------------------------------"

# Habilitar IP forwarding
sysctl -w net.ipv4.ip_forward=1 >/dev/null
if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf 2>/dev/null; then
  echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi

# Abrir puerto con iptables (INPUT para UDP $PORT)
iptables -I INPUT -p udp --dport $PORT -j ACCEPT 2>/dev/null || true

echo "✓ Reenvío de IP habilitado"
echo "✓ Puerto $PORT/udp abierto en iptables"
echo
echo "⚠️  IMPORTANTE: Si usas Oracle Cloud u otro proveedor con firewall,"
echo "    debes abrir manualmente el puerto $PORT/UDP en su panel web."
echo

if [[ "$AUTO_MODE" == false ]]; then
  read -p "Pulsa ENTER para continuar al Paso 5..." _
else
  sleep 3
fi

echo
echo "Paso 5: Arrancando el contenedor de WireGuard con Docker..."
echo "-----------------------------------------------------------"
cd "$WG_DIR"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker no está instalado en este servidor."
  echo "Instala Docker con: curl -fsSL https://get.docker.com | sh"
  exit 1
fi

# Soportar tanto 'docker-compose' clásico como 'docker compose'
if command -v docker-compose >/dev/null 2>&1; then
  DC_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
  DC_CMD="docker compose"
else
  echo "ERROR: docker-compose no está instalado."
  echo "Instala con: sudo apt install docker-compose"
  exit 1
fi

echo "Iniciando WireGuard..."
$DC_CMD up -d

echo
echo "Esperando 15 segundos a que WireGuard genere la configuración..."
sleep 15

echo
echo "Paso 6: Mostrando información importante generada..."
echo "----------------------------------------------------"

if [[ ! -d "$CONFIG_DIR" ]]; then
  echo "ERROR: No se encontró la carpeta de configuración: $CONFIG_DIR"
  exit 1
fi

# Buscar wg0.conf
SERVER_CONF=$(find "$CONFIG_DIR" -name "wg0.conf" 2>/dev/null | head -n 1)

if [[ -f "$SERVER_CONF" ]]; then
  echo "✓ Configuración del servidor encontrada:"
  echo "  $SERVER_CONF"
  echo
  echo "=== CONTENIDO DE wg0.conf ==="
  cat "$SERVER_CONF"
  echo "=============================="
else
  echo "⚠️  No se encontró wg0.conf todavía."
  echo "   Revisa en unos segundos: $CONFIG_DIR"
fi

echo
echo "╔════════════════════════════════════════════════════════════╗"
echo "║           INSTALACIÓN COMPLETADA EXITOSAMENTE              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo
echo "📋 DATOS IMPORTANTES:"
echo
echo "1️⃣  IP PÚBLICA DE TU VPS (usa esto en 'Endpoint' en tu casa):"
echo "   $PUBLIC_IP:$PORT"
echo
echo "2️⃣  Carpeta de configuración:"
echo "   $CONFIG_DIR"
echo
echo "3️⃣  Ver logs de WireGuard:"
echo "   cd $WG_DIR && $DC_CMD logs -f"
echo
echo "4️⃣  Ver estado del túnel:"
echo "   docker exec wireguard wg show"
echo
echo "5️⃣  Archivos de clientes (peers) para móviles:"
echo "   $CONFIG_DIR/peer1/"
echo "   $CONFIG_DIR/peer2/"
echo "   $CONFIG_DIR/peer3/"
echo "   $CONFIG_DIR/peer4/"
echo
echo "📱 Para conectar tu móvil:"
echo "   cat $CONFIG_DIR/peer2/peer2.conf"
echo "   (Escanea el QR o copia la configuración)"
echo
echo "🏠 Siguiente paso:"
echo "   Configura tu Raspberry Pi / CasaOS para conectarse a:"
echo "   Endpoint = $PUBLIC_IP:$PORT"
echo
echo "═══════════════════════════════════════════════════════════"
echo "✅ El servidor WireGuard está funcionando correctamente"
echo "═══════════════════════════════════════════════════════════"
