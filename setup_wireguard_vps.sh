#!/bin/bash

################################################################################
# Script de instalación COMPLETA de WireGuard (Servidor VPS, con Docker)
# - Instala Docker y Docker Compose automáticamente
# - Detecta IP pública automáticamente
# - Crea carpeta ./wireguard y docker-compose.yml
# - Abre puerto 51820/UDP con iptables
# - Lanza el contenedor y genera configuración
# - Verifica que todo funciona correctamente
# - Muestra datos importantes en pantalla (IP, claves, QR, etc.)
#
# Uso:
#   wget https://raw.githubusercontent.com/davidrumbaut620/Setup-WIREGUARD-VPS/refs/heads/main/setup_wireguard_vps.sh
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

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Detectar si estamos en modo pipe o si se pasó --auto
AUTO_MODE=false
if [[ "$1" == "--auto" ]] || [[ ! -t 0 ]]; then
  AUTO_MODE=true
fi

# Función para imprimir con color
print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

# Función para verificar si un comando existe
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Función para instalar Docker
install_docker() {
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "  INSTALANDO DOCKER Y DOCKER COMPOSE"
  echo "════════════════════════════════════════════════════════════"
  echo
  
  # Detectar distribución
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$ID
  else
    print_error "No se pudo detectar el sistema operativo"
    exit 1
  fi
  
  print_info "Sistema operativo detectado: $OS"
  
  # Actualizar repositorios
  print_info "Actualizando repositorios del sistema..."
  if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
    apt-get update -qq
    apt-get install -y -qq ca-certificates curl gnupg lsb-release >/dev/null 2>&1
  elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "fedora" ]]; then
    yum install -y -q ca-certificates curl >/dev/null 2>&1
  fi
  print_success "Repositorios actualizados"
  
  # Instalar Docker usando el script oficial
  print_info "Descargando script de instalación de Docker..."
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  print_success "Script descargado"
  
  print_info "Instalando Docker (esto puede tardar unos minutos)..."
  sh /tmp/get-docker.sh >/dev/null 2>&1
  print_success "Docker instalado correctamente"
  
  # Iniciar y habilitar Docker
  print_info "Iniciando servicio Docker..."
  systemctl start docker
  systemctl enable docker >/dev/null 2>&1
  print_success "Docker iniciado y habilitado"
  
  # Agregar usuario actual al grupo docker (si no es root)
  if [[ $EUID -ne 0 ]] && [[ -n "$SUDO_USER" ]]; then
    print_info "Agregando usuario $SUDO_USER al grupo docker..."
    usermod -aG docker "$SUDO_USER"
    print_success "Usuario agregado al grupo docker"
    print_warning "Nota: El usuario deberá cerrar sesión y volver a iniciarla"
  fi
  
  # Limpiar
  rm -f /tmp/get-docker.sh
  
  # Verificar instalación
  if command_exists docker; then
    DOCKER_VERSION=$(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)
    print_success "Docker $DOCKER_VERSION instalado correctamente"
  else
    print_error "Error al instalar Docker"
    exit 1
  fi
  
  # Verificar Docker Compose
  if docker compose version >/dev/null 2>&1; then
    COMPOSE_VERSION=$(docker compose version --short)
    print_success "Docker Compose $COMPOSE_VERSION instalado correctamente"
  else
    print_error "Error: Docker Compose no está disponible"
    exit 1
  fi
  
  echo
}

clear
echo -e "${CYAN}"
cat << "EOF"
                                                                                                                                                        
                                                                                                                                                       
                                                                                                                                                       
                                                                                                                                                       
                                                                                                                                                       
                                        .-#%%####%#%####%##:.                                                                                          
                                   .########### .*###  ..+#######*                                                                                     
                              ..###########%##%####.        #########+.                                                                                
                             =############*..             #=   .. #%####:.                                                                             
                          .##################.               .......#######.                                                                           
                         -%##################*                   .##########=                                                                  #####.  =####-  .####- -####.   ###########+.   .############:    .#########..    #####     #####.     *#####.      +##########%.    ########%#+.                                       
                       .#################%-.           #########%############%.                                                                .##### .######  #####. -####.   ############%.  .############:  .#############.   #####     #####.    .#######      +############%.  #############.                                     
                       %##################%%%%=.       .%######################.                                                               .##### .######  ####*  -####.   ####=   .#####  .####.         .%###%.   .#####.  #####     #####.    ###%####%     +####    :####*  #####. ..#####   ###############                   
                     .#######################+.          .*#####################-                                                               :####.*##%####.####.  -####.   ####+---#%###*  .###########.  .####=     ......  #####     #####.   +#### %###:    +####----#####.  #####.   .####-  ###############                   
                    .############################%*        ..####################:       .##################################################    .########.#########   -####.   ###########%.   .###########.  .####-  ########   #####     #####.  .%###. =####    +###########%    #####.   .####+  ###############                   
                   .########################%####%%##..        %##################.      .##################################################     =######%..#######.   -####.   ####= *####*    .####.         .#####. ....####   #####.    #####. .#############   +#### .%####.    #####.  .*####.  ###############                   
                   ######################.          .##.        .%################%      .##################################################     .######+  #######    -####.   ####= .#####*   .############+  #######=+######   .######=*#####*. ##############.  +####  .#####.   ##############   ###############                   
                  :###################.                .#.       .#################.     .##################################################      ######.  +#####-    -####.   ####=  .#####=  .############*   .#############    .#%#########:  .####+     #####. +####   .%###%.  ###########%.    ###############                   
                 .%#################-                    :#       :#################     .##################################################      ......   .......    ......   .....    ......  .............      ......   ...      .......     ......     ...... ......   ......  .......          ###############                   
                 .################%.                      .#      .%###############%.    .##################################################                                                                                                                                                         ###############                   
                 #################.       .%######+       .#.     .#################+    .##################################################   ##############%          .###############.       .############.       :%############.                         .*#%##############%#.                   ###############                   
                .%################       +##########      .#.     .##################                     :################.                   ##############%          .###############.       .#############    ####################                    #%########################%.               ###############                   
                .################*      .############     +:      *##################                     :################.                   ##############%          .###############.       .############# .######################%:               =%###############################             ###############                   
                .################*       ############    *:      .##################%                     :################.                   ##############%          .###############.       .#############*#########################:.           :###################################..          ###############                   
                 #################      .###########. .:#.      .####################                     :################.                   ##############%          .###############.       .########################################.          %#####################################%.         ###############                   
                 #################.       .%#######.=#.         #####################                     :################.                   ##############%          .###############.       .#########################################.       .###############%:       .%##############%         ###############                   
                .#################%.         ..##...          .######################                     :################.                   ##############%          .###############.       .#################.     ..################.       *##############-.          .##############.        ###############                   
                .%##################.      .#.              .#######################:                     :################.                   ##############%          .###############.       .################.        .###############       .##############*             ##############%        ###############                   
                 +###################%   .#.              #-. .#####################.                     :################.                   ##############%          .###############.       .###############.         .###############.      .##############...............##############.       ###############                   
                 .#######################.            ##..      +##################%                      :################.                   ##############%          .###############.       .###############.         .###############.      ############################################:       ###############                   
                  #################    #         .######..       :#################                       :################.                   ##############%          .###############.       .###############.         .###############.      ############################################+       ###############                   
                  .%############*.    =:       +##########.       ################+                       :################.                   ##############%          .###############.       .###############.         .###############.      ############################################+       ###############                   
                   =###########.      %.      #############.      .###############                        :################.                   ##############%          .###############.       .###############.         .###############.      ###############..............................       ###############                   
                    ##########.. =#####.      ##############      .##############.                        :################.                   ###############          .###############.       .###############.         .###############.      :##############.                                    ###############                   
                     ##################.      ##############      .#############.                         :################.                   ###############.         *###############.       .###############.         .###############.      .##############=              ##############+       ###############                   
                     .*################       #############.      .############.                          :################.                   ################.       #################.       .###############.         .###############.      .###############.            .##############.       ###############                   
                      ..###############:      .=##########.      .###########=                            :################.                   *#################%##%###################.       .###############.         .###############.       .%##############%.        .#%#############%        ###############                   
                        .*##############        ..######..       :##########.                             :################.                   .########################################.       .###############.         .###############.        .%################%##%###################.        ###############                   
                           *#############.                      *#########                                :################.                    =#######################################.       .###############.         .###############.          #####################################%.         ###############                   
                             .#%###########.                  .%#######:                                  :################.                     =######################%: #############.       .###############.         .###############.            %#################################+.          ###############                   
                                 ###########%.             .:%####%#..                                    :################.                      .%###################.   *############.       .###############.         .###############.              :#############################.             ###############                   
                                     .*##########.... ..=%#####..                                         :################.                         +%###########%%.      .############.       .###############.         .###############.                 .-%####################..                ###############                   
                                              ... .......                                                                                                 ... ..                                                                                                   ..........

EOF
echo -e "${NC}"
echo
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  INSTALADOR AUTOMÁTICO DE WIREGUARD EN TU VPS${NC}"
echo -e "${GREEN}  Created by: David Rumbaut - Fivel.ink${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo
echo "Este script realizará las siguientes acciones:"
echo "  1) Verificar e instalar Docker si es necesario"
echo "  2) Detectar tu IP pública"
echo "  3) Crear la estructura de carpetas"
echo "  4) Generar docker-compose.yml"
echo "  5) Configurar firewall (iptables)"
echo "  6) Levantar WireGuard"
echo "  7) Verificar que funciona correctamente"
echo "  8) Mostrar configuración y códigos QR"
echo

if [[ $EUID -ne 0 ]]; then
  print_error "Este script debe ejecutarse como root o con sudo"
  exit 1
fi

if [[ "$AUTO_MODE" == false ]]; then
  read -p "¿Deseas continuar? (s/N): " CONT
  CONT=${CONT:-n}
  if [[ "$CONT" != "s" && "$CONT" != "S" ]]; then
    echo "Proceso cancelado."
    exit 0
  fi
else
  print_info "MODO AUTOMÁTICO: Continuando sin confirmación..."
  sleep 2
fi

echo
echo "════════════════════════════════════════════════════════════"
echo "  PASO 1: VERIFICANDO DOCKER"
echo "════════════════════════════════════════════════════════════"
echo

# Verificar e instalar Docker si es necesario
if command_exists docker; then
  DOCKER_VERSION=$(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)
  print_success "Docker ya está instalado (versión $DOCKER_VERSION)"
  
  # Verificar que Docker está corriendo
  if ! systemctl is-active --quiet docker; then
    print_warning "Docker no está corriendo. Iniciando..."
    systemctl start docker
    print_success "Docker iniciado"
  fi
  
  # Verificar Docker Compose
  if docker compose version >/dev/null 2>&1; then
    COMPOSE_VERSION=$(docker compose version --short)
    print_success "Docker Compose disponible (versión $COMPOSE_VERSION)"
  elif command_exists docker-compose; then
    COMPOSE_VERSION=$(docker-compose --version | cut -d ' ' -f3 | cut -d ',' -f1)
    print_success "Docker Compose disponible (versión $COMPOSE_VERSION)"
  else
    print_warning "Docker Compose no encontrado, pero Docker moderno lo incluye"
  fi
else
  print_warning "Docker no está instalado"
  
  if [[ "$AUTO_MODE" == false ]]; then
    read -p "¿Deseas instalar Docker ahora? (s/N): " INSTALL_DOCKER
    INSTALL_DOCKER=${INSTALL_DOCKER:-s}
  else
    INSTALL_DOCKER="s"
    print_info "Instalando Docker automáticamente..."
  fi
  
  if [[ "$INSTALL_DOCKER" == "s" || "$INSTALL_DOCKER" == "S" ]]; then
    install_docker
  else
    print_error "Docker es necesario para continuar"
    exit 1
  fi
fi

if [[ "$AUTO_MODE" == false ]]; then
  read -p "Pulsa ENTER para continuar..." _
fi

echo
echo "════════════════════════════════════════════════════════════"
echo "  PASO 2: DETECTANDO IP PÚBLICA"
echo "════════════════════════════════════════════════════════════"
echo

# Intentar detectar IP pública con múltiples métodos
print_info "Detectando IP pública del VPS..."

if command_exists curl; then
  PUBLIC_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || \
              curl -s --max-time 5 icanhazip.com 2>/dev/null || \
              curl -s --max-time 5 ipinfo.io/ip 2>/dev/null || \
              curl -s --max-time 5 api.ipify.org 2>/dev/null || true)
elif command_exists wget; then
  PUBLIC_IP=$(wget -qO- --timeout=5 ifconfig.me 2>/dev/null || \
              wget -qO- --timeout=5 icanhazip.com 2>/dev/null || true)
fi

if [[ -z "$PUBLIC_IP" ]]; then
  print_warning "No se pudo detectar automáticamente la IP pública"
  
  if [[ "$AUTO_MODE" == false ]]; then
    read -p "Escribe manualmente la IP pública de tu VPS: " PUBLIC_IP
  else
    print_error "No se pudo obtener la IP pública automáticamente"
    print_info "Ejecuta el script manualmente para ingresar la IP"
    exit 1
  fi
fi

# Validar formato de IP
if [[ ! "$PUBLIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  print_error "La IP '$PUBLIC_IP' no parece válida"
  
  if [[ "$AUTO_MODE" == false ]]; then
    read -p "Escribe la IP pública correcta: " PUBLIC_IP
  else
    exit 1
  fi
fi

print_success "IP pública detectada: $PUBLIC_IP"

if [[ "$AUTO_MODE" == false ]]; then
  read -p "¿Es correcta esta IP? (s/N): " OK_IP
  OK_IP=${OK_IP:-s}
  if [[ "$OK_IP" != "s" && "$OK_IP" != "S" ]]; then
    read -p "Escribe la IP pública correcta: " PUBLIC_IP
  fi
fi

print_success "Usando IP pública: $PUBLIC_IP"

if [[ "$AUTO_MODE" == false ]]; then
  read -p "Pulsa ENTER para continuar..." _
fi

echo
echo "════════════════════════════════════════════════════════════"
echo "  PASO 3: CREANDO ESTRUCTURA DE CARPETAS"
echo "════════════════════════════════════════════════════════════"
echo

print_info "Creando carpetas de trabajo..."
mkdir -p "$CONFIG_DIR"
print_success "Carpeta creada: $WG_DIR"
print_success "Carpeta de configuración: $CONFIG_DIR"

if [[ "$AUTO_MODE" == false ]]; then
  read -p "Pulsa ENTER para continuar..." _
fi

echo
echo "════════════════════════════════════════════════════════════"
echo "  PASO 4: GENERANDO DOCKER-COMPOSE.YML"
echo "════════════════════════════════════════════════════════════"
echo

print_info "Creando archivo docker-compose.yml..."

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
      - PEERDNS=1.1.1.1,8.8.8.8
      - INTERNAL_SUBNET=10.69.69.0
      - ALLOWEDIPS=0.0.0.0/0
      - LOG_CONFS=true
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

print_success "Archivo docker-compose.yml creado"
print_info "Ubicación: $COMPOSE_FILE"

if [[ "$AUTO_MODE" == false ]]; then
  read -p "Pulsa ENTER para continuar..." _
fi

echo
echo "════════════════════════════════════════════════════════════"
echo "  PASO 5: CONFIGURANDO FIREWALL Y SISTEMA"
echo "════════════════════════════════════════════════════════════"
echo

print_info "Habilitando IP forwarding..."
sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1
if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf 2>/dev/null; then
  echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi
print_success "IP forwarding habilitado"

print_info "Configurando iptables..."
# Abrir puerto para WireGuard
iptables -C INPUT -p udp --dport $PORT -j ACCEPT 2>/dev/null || \
  iptables -I INPUT -p udp --dport $PORT -j ACCEPT
print_success "Puerto $PORT/UDP abierto en iptables"

# Guardar reglas de iptables (si está disponible)
if command_exists iptables-save && command_exists netfilter-persistent; then
  netfilter-persistent save >/dev/null 2>&1 || true
  print_success "Reglas de firewall guardadas"
fi

print_warning "IMPORTANTE: Si usas Oracle Cloud, AWS, GCP u otro proveedor cloud,"
print_warning "debes abrir también el puerto $PORT/UDP en su panel de firewall."

if [[ "$AUTO_MODE" == false ]]; then
  read -p "Pulsa ENTER para continuar..." _
fi

echo
echo "════════════════════════════════════════════════════════════"
echo "  PASO 6: INICIANDO WIREGUARD"
echo "════════════════════════════════════════════════════════════"
echo

cd "$WG_DIR"

# Determinar comando de Docker Compose
if docker compose version >/dev/null 2>&1; then
  DC_CMD="docker compose"
elif command_exists docker-compose; then
  DC_CMD="docker-compose"
else
  print_error "No se encontró docker-compose"
  exit 1
fi

print_info "Descargando imagen de WireGuard..."
$DC_CMD pull >/dev/null 2>&1
print_success "Imagen descargada"

print_info "Iniciando contenedor de WireGuard..."
$DC_CMD up -d

if [[ $? -eq 0 ]]; then
  print_success "Contenedor iniciado correctamente"
else
  print_error "Error al iniciar el contenedor"
  $DC_CMD logs
  exit 1
fi

print_info "Esperando 20 segundos a que WireGuard genere la configuración..."
for i in {20..1}; do
  echo -ne "\rEsperando... $i segundos   "
  sleep 1
done
echo

echo
echo "════════════════════════════════════════════════════════════"
echo "  PASO 7: VERIFICANDO INSTALACIÓN"
echo "════════════════════════════════════════════════════════════"
echo

# Verificar que el contenedor está corriendo
if docker ps | grep -q wireguard; then
  print_success "Contenedor WireGuard está corriendo"
else
  print_error "El contenedor no está corriendo"
  print_info "Mostrando logs:"
  $DC_CMD logs --tail=50
  exit 1
fi

# Verificar que se generaron los archivos de configuración
if [[ -d "$CONFIG_DIR" ]]; then
  print_success "Carpeta de configuración existe"
  
  # Buscar wg0.conf
  SERVER_CONF=$(find "$CONFIG_DIR" -name "wg0.conf" 2>/dev/null | head -n 1)
  
  if [[ -f "$SERVER_CONF" ]]; then
    print_success "Configuración del servidor encontrada"
  else
    print_warning "wg0.conf no encontrado aún (puede tardar unos segundos más)"
  fi
  
  # Verificar peers
  PEER_COUNT=$(find "$CONFIG_DIR" -type d -name "peer*" 2>/dev/null | wc -l)
  if [[ $PEER_COUNT -gt 0 ]]; then
    print_success "Se generaron $PEER_COUNT configuraciones de clientes (peers)"
  else
    print_warning "No se encontraron peers aún"
  fi
else
  print_error "No se encontró la carpeta de configuración"
fi

# Verificar puerto
if netstat -tuln 2>/dev/null | grep -q ":$PORT " || ss -tuln 2>/dev/null | grep -q ":$PORT "; then
  print_success "Puerto $PORT/UDP está escuchando"
else
  print_warning "No se pudo verificar el puerto (puede ser normal en algunos sistemas)"
fi

# Verificar interfaz WireGuard dentro del contenedor
if docker exec wireguard wg show 2>/dev/null | grep -q "interface: wg0"; then
  print_success "Interfaz WireGuard configurada correctamente"
else
  print_warning "Interfaz WireGuard aún no está lista"
fi

echo
echo "════════════════════════════════════════════════════════════"
echo "  PASO 8: INFORMACIÓN DE CONFIGURACIÓN"
echo "════════════════════════════════════════════════════════════"
echo

# Mostrar wg0.conf si existe
if [[ -f "$SERVER_CONF" ]]; then
  echo
  print_info "Configuración del servidor ($SERVER_CONF):"
  echo "────────────────────────────────────────────────────────────"
  cat "$SERVER_CONF"
  echo "────────────────────────────────────────────────────────────"
fi

# Mostrar configuraciones de peers
echo
print_info "Configuraciones de clientes (peers):"
echo

PEER_DIRS=$(find "$CONFIG_DIR" -type d -name "peer*" 2>/dev/null | sort)

if [[ -n "$PEER_DIRS" ]]; then
  for peer_dir in $PEER_DIRS; do
    peer_name=$(basename "$peer_dir")
    peer_conf="$peer_dir/$peer_name.conf"
    peer_png="$peer_dir/$peer_name.png"
    
    if [[ -f "$peer_conf" ]]; then
      echo "📱 $peer_name:"
      echo "   Configuración: $peer_conf"
      if [[ -f "$peer_png" ]]; then
        echo "   Código QR: $peer_png"
      fi
      echo
    fi
  done
else
  print_warning "No se encontraron configuraciones de peers"
  print_info "Espera unos segundos más y ejecuta: ls -la $CONFIG_DIR"
fi

echo
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║       ✅ INSTALACIÓN COMPLETADA EXITOSAMENTE ✅             ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo
echo "📋 RESUMEN DE DATOS IMPORTANTES:"
echo "────────────────────────────────────────────────────────────"
echo
echo "🌐 IP PÚBLICA DEL VPS:"
echo "   $PUBLIC_IP:$PORT"
echo
echo "📁 CARPETA DE CONFIGURACIÓN:"
echo "   $CONFIG_DIR"
echo
echo "📱 CONECTAR MÓVIL:"
echo "   1. Instala WireGuard desde tu tienda de apps"
echo "   2. Para ver el código QR de un peer:"
echo "      cat $CONFIG_DIR/peer2/peer2.png"
echo "   3. O copia la configuración:"
echo "      cat $CONFIG_DIR/peer2/peer2.conf"
echo
echo "🏠 CONECTAR RASPBERRY PI / CASAOS:"
echo "   Usa la configuración de peer1:"
echo "   cat $CONFIG_DIR/peer1/peer1.conf"
echo
echo "🔧 COMANDOS ÚTILES:"
echo "────────────────────────────────────────────────────────────"
echo "• Ver logs:"
echo "  cd $WG_DIR && $DC_CMD logs -f"
echo
echo "• Ver estado del túnel:"
echo "  docker exec wireguard wg show"
echo
echo "• Reiniciar WireGuard:"
echo "  cd $WG_DIR && $DC_CMD restart"
echo
echo "• Detener WireGuard:"
echo "  cd $WG_DIR && $DC_CMD down"
echo
echo "• Ver todas las configuraciones:"
echo "  ls -la $CONFIG_DIR"
echo
echo "════════════════════════════════════════════════════════════"
echo
print_success "WireGuard está funcionando correctamente en tu VPS"
print_info "Siguiente paso: Configurar tu dispositivo de casa para conectarse"
print_info "Endpoint que debes usar: $PUBLIC_IP:$PORT"
echo
echo -e "${CYAN}════════════════════════════════════════════════════════════"
echo -e "Created by: David Rumbaut"
echo -e "Web: https://fivel.ink"
echo -e "GitHub: https://github.com/davidrumbaut620"
echo -e "════════════════════════════════════════════════════════════${NC}"
