# 🔐 Guía Completa: Túnel VPN WireGuard bajo CGNAT

## 📋 Índice
- [¿Qué es esto y para qué sirve?](#qué-es-esto-y-para-qué-sirve)
- [¿Qué necesitas?](#qué-necesitas)
- [Entendiendo el problema CGNAT](#entendiendo-el-problema-cgnat)
- [Instalación en el VPS (Servidor)](#instalación-en-el-vps-servidor)
- [Instalación en Casa (Raspberry Pi/CasaOS)](#instalación-en-casa-raspberry-picasaos)
- [Conectar tu móvil u otros dispositivos](#conectar-tu-móvil-u-otros-dispositivos)
- [Verificar que funciona](#verificar-que-funciona)
- [Solución de problemas](#solución-de-problemas)
- [Comandos útiles](#comandos-útiles)
- [Recursos adicionales](#recursos-adicionales)
- [Preguntas frecuentes](#preguntas-frecuentes)
- [Tips y buenas prácticas](#-tips-y-buenas-prácticas)
- [Changelog](#-changelog)
- [Contribuir](#-contribuir)
- [Licencia](#-licencia)

---

## 🎯 ¿Qué es esto y para qué sirve?

Este tutorial te permite **acceder a tus aplicaciones y servicios de casa desde cualquier lugar** del mundo, incluso si tu proveedor de internet usa CGNAT (no puedes abrir puertos).

**Ejemplos de uso:**
- Acceder a tu Home Assistant desde el trabajo
- Ver tus cámaras de seguridad en vacaciones
- Conectarte a tu NAS estés donde estés
- Usar tus aplicaciones self-hosted remotamente

**¿Cómo funciona?**
Usas un servidor externo (VPS) como "puente" entre internet y tu casa. Tu casa se conecta al servidor, y tú te conectas al servidor para llegar a casa.

---

## 📦 ¿Qué necesitas?

### Hardware
- ✅ Un servidor en casa (Raspberry Pi, Orange Pi, PC viejo, o servidor con CasaOS)
- ✅ Un VPS (servidor externo) con IP pública — **[Puedes conseguir uno GRATIS](https://www.youtube.com/watch?v=ejemplo)**

### Software (se instalará automáticamente)
- Docker
- Docker Compose
- WireGuard

### Conocimientos
- ❌ **NO** necesitas ser programador
- ❌ **NO** necesitas saber de redes
- ✅ Solo saber copiar y pegar comandos

---

## 🔍 Entendiendo el problema CGNAT

### ¿Qué es CGNAT?

CGNAT (Carrier Grade NAT) es cuando tu proveedor de internet **comparte tu IP pública con otros usuarios**. Esto significa que:

- ❌ No puedes abrir puertos  
- ❌ No puedes crear VPN tradicionales  
- ❌ No puedes acceder directamente a tu casa desde internet  

### ¿Cómo saber si estás bajo CGNAT?

#### Método 1: Comparar IPs (5 minutos)

1. **Busca tu IP pública en Google:**
   - Abre Google y busca: `cuál es mi IP`
   - Anota la IP que te muestra (ejemplo: `203.45.67.89`)
2. **Entra a tu router:**
   - Abre tu navegador y ve a: `http://192.168.1.1` (o `192.168.0.1`)
   - Usuario/contraseña: normalmente está en una etiqueta detrás del router
   - Si no funciona, prueba: `admin`/`admin` o `user`/`user`
3. **Busca la sección "Internet" o "WAN":**
   - Mira la IP que aparece ahí
4. **Compara las IPs:**
   - ✅ Si son **iguales** → NO estás bajo CGNAT (puedes usar un método más simple)
   - ❌ Si son **diferentes** → Estás bajo CGNAT (este tutorial es para ti)

#### Método 2: Llamar a tu operadora (2 minutos)

Llama y pregunta: _"¿Estoy bajo CGNAT? ¿Puedo tener una IP pública?"_

**Nota:** Si te piden pagar extra por una IP pública, no es necesario. Este tutorial es gratuito.

---

## 🖥️ Instalación en el VPS (Servidor)

### Paso 1: Conseguir un VPS gratis

Si no tienes un VPS, consigue uno gratis con Oracle Cloud:
- **[Tutorial completo aquí](https://www.youtube.com/watch?v=ejemplo)**

### Paso 2: Instalar requisitos previos

Conéctate a tu VPS por SSH y ejecuta:

Actualizar el sistema:
```bash
sudo apt update && sudo apt upgrade -y
```
Instalar Docker:
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```
Verificar que Docker funciona:
```bash
docker --version
docker compose version
```

**Salida esperada:**
```text
Docker version 24.0.7, build afdd53b
Docker Compose version v2.23.0
```

### Paso 3: Ejecutar el instalador automático

Descargar el script de instalación:
```bash
wget https://raw.githubusercontent.com/davidrumbaut620/Setup-WIREGUARD-VPS/refs/heads/main/setup_wireguard_vps.sh
```
Dar permisos de ejecución:
```bash
chmod +x setup_wireguard_vps.sh
```
Ejecutarlo:
```bash
sudo ./setup_wireguard_vps.sh
```

**O en una sola línea:**
```bash
curl -fsSL https://raw.githubusercontent.com/davidrumbaut620/Setup-WIREGUARD-VPS/refs/heads/main/setup_wireguard_vps.sh | sudo bash
```

### Paso 4: Seguir las instrucciones del instalador

El script te irá guiando paso a paso:

1. **Detectará tu IP pública automáticamente**
   - Te preguntará si es correcta
   - Si no, puedes escribirla manualmente
2. **Creará las carpetas necesarias**
   - `~/wireguard/`
   - `~/wireguard/config/`
3. **Abrirá el puerto 51820/UDP**
   - Automáticamente con `iptables`
4. **Levantará el contenedor Docker**
   - Esperará a que WireGuard genere la configuración
5. **Te mostrará información importante:**
   - Tu IP pública
   - Ubicación de los archivos de configuración
   - Comandos útiles

### Paso 5: Configurar el firewall (IMPORTANTE para Oracle Cloud)

Si usas **Oracle Cloud**, debes abrir el puerto manualmente:

1. Ve a tu instancia en Oracle Cloud Console
2. Clic en tu instancia > **Virtual Cloud Network (VCN)**
3. Selecciona tu subnet > **Security Lists**
4. **Add Ingress Rules** (Agregar reglas de entrada)

**Configuración de la regla:**

| Campo | Valor |
| --- | --- |
| Source Type | CIDR |
| Source CIDR | `0.0.0.0/0` |
| IP Protocol | UDP |
| Source Port Range | All |
| Destination Port Range | `51820` |

5. Clic en **Add Ingress Rules**

### Paso 6: Anotar información importante

El script te mostrará al final:

```text
=== RESUMEN DE DATOS IMPORTANTES ===
1) IP PÚBLICA DE TU VPS (para usar en 'Endpoint' en tu casa): 203.45.67.89:51820
2) Carpeta de configuración de WireGuard en el VPS: /root/wireguard/config
```

**📝 ANOTA ESTA IP, LA NECESITARÁS MÁS TARDE**

### Paso 7: Obtener las claves del servidor

Ver la configuración del servidor:
```bash
cd ~/wireguard/config
cat wg0.conf
```

**📝 Busca y anota:**
- `PublicKey` (Clave pública del VPS)
- `PrivateKey` (Clave privada del VPS)

---

## 🏠 Instalación en Casa (Raspberry Pi/CasaOS)

### Opción A: Raspberry Pi / Linux con Docker

#### Paso 1: Conectarte a tu Raspberry Pi

Desde tu ordenador, conéctate por SSH:
```bash
ssh pi@192.168.1.X  # Reemplaza X con la IP de tu Raspberry
```

**¿No sabes cuál es la IP de tu Raspberry?**

- **Método 1: Desde el router**
  - Entra a tu router (`192.168.1.1`)
  - Busca "Dispositivos conectados" o "DHCP Clients"
  - Busca tu Raspberry Pi
- **Método 2: Escanear la red**
  - En tu ordenador (Linux/Mac):
    ```bash
    sudo nmap -sn 192.168.1.0/24
    ```
  - En Windows: descarga Advanced IP Scanner

#### Paso 2: Instalar Docker (si no lo tienes)

Instalar Docker:
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```
Agregar tu usuario al grupo docker:
```bash
sudo usermod -aG docker $USER
```
Reiniciar para aplicar cambios:
```bash
sudo reboot
```

#### Paso 3: Crear estructura de carpetas

Crear carpeta de trabajo:
```bash
mkdir -p ~/wireguard/config/wg0
cd ~/wireguard
```

#### Paso 4: Crear `docker-compose.yml`

Editar el archivo:
```bash
nano docker-compose.yml
```

Pega este contenido:
```yaml
version: "3.8"
services:
  wireguard:
    image: lscr.io/linuxserver/wireguard:arm64-v1.0.20210914
    container_name: wireguard
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Miami
    volumes:
      - ./config:/config
      - /lib/modules:/lib/modules
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
      - net.ipv4.ip_forward=1
    restart: unless-stopped
    network_mode: host
```

**Guardar:** `Ctrl + X`, luego `Y`, luego `Enter`

**Nota:** Si tu Raspberry no es ARM64, usa: `lscr.io/linuxserver/wireguard:latest`

#### Paso 5: Generar claves para la Raspberry

Instalar herramientas de WireGuard (si no las tienes):
```bash
sudo apt update
sudo apt install wireguard-tools -y
```
Generar claves:
```bash
cd ~/wireguard/config
wg genkey | tee privatekey | wg pubkey > publickey
```
Ver las claves:
```bash
echo "Clave privada:"
cat privatekey

echo "\nClave pública:"
cat publickey
```

**📝 ANOTA ESTAS DOS CLAVES**

#### Paso 6: Obtener configuración del primer peer del VPS

En tu VPS, ejecuta:
```bash
cd ~/wireguard/config
cat peer1/peer1.conf
```
Copia TODO el contenido.

#### Paso 7: Crear configuración de la Raspberry

En tu Raspberry:
```bash
nano ~/wireguard/config/wg0/wg0.conf
```

Pega el contenido copiado del VPS y **modifica** estos campos:
```ini
[Interface]
Address = 10.69.69.2/24
PrivateKey = <PEGA_AQUI_LA_CLAVE_PRIVADA_DE_TU_RASPBERRY>
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = <PEGA_AQUI_LA_CLAVE_PUBLICA_DEL_VPS>
PresharedKey = <MANTÉN_LA_QUE_VINO_DEL_VPS>
Endpoint = <IP_PUBLICA_VPS>:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

**Ejemplo con datos reales:**
```ini
[Interface]
Address = 10.69.69.2/24
PrivateKey = yDhN9vK3mP8wX2...
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = zL4kP9mN7xR5...
PresharedKey = aB3cD4eF5gH6...
Endpoint = 203.45.67.89:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

**Guardar:** `Ctrl + X`, luego `Y`, luego `Enter`

#### Paso 8: Actualizar configuración del VPS

En tu VPS, edita la configuración para agregar la Raspberry:
```bash
cd ~/wireguard/config
nano wg0.conf
```

Busca la sección `[Peer]` y actualiza:
```ini
[Peer]
# Raspberry Pi
PublicKey = <PEGA_AQUI_LA_CLAVE_PUBLICA_DE_TU_RASPBERRY>
AllowedIPs = 10.69.69.2/32, 192.168.1.0/24
PersistentKeepalive = 25
```

> Nota: Cambia `192.168.1.0/24` si tu red local usa otro rango (ejemplo: `192.168.0.0/24` o `10.0.0.0/24`).

Guardar y reiniciar el contenedor:
```bash
cd ~/wireguard
docker compose restart
```

#### Paso 9: Iniciar WireGuard en la Raspberry

En la Raspberry:
```bash
cd ~/wireguard
# Habilitar IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
# Iniciar el contenedor
docker compose up -d
# Ver los logs para verificar
docker compose logs -f
```

**Salida esperada:**
```text
wireguard | [✓] WireGuard interface is up
wireguard | [✓] Connected to peer
```

---

### Opción B: CasaOS (con interfaz gráfica)

#### Paso 1: Acceder a CasaOS

Abre tu navegador y ve a: `http://IP-DE-TU-CASAOS` (ejemplo: `http://192.168.1.100`)

#### Paso 2: Instalar WireGuard desde App Store

1. Ve a **App Store**
2. Busca **WireGuard**
3. Clic en **Install**
4. Espera a que termine la instalación

#### Paso 3: Acceder a Files (Archivos)

1. En CasaOS, abre **Files**
2. Navega a: `/DATA/AppData/wireguard/config`
3. Crea una carpeta llamada `wg0` (si no existe)

#### Paso 4: Crear archivo de configuración

1. Dentro de `/DATA/AppData/wireguard/config/wg0/`
2. Clic en **New File** (Nuevo archivo)
3. Nombre: `wg0.conf`

#### Paso 5: Obtener configuración del VPS

En tu VPS (por SSH):
```bash
cd ~/wireguard/config
cat peer1/peer1.conf
```
Copia TODO el contenido.

#### Paso 6: Pegar y modificar configuración

En el archivo `wg0.conf` de CasaOS, pega el contenido y modifica:
```ini
[Interface]
Address = 10.69.69.2/24
PrivateKey = <GENERA_UNA_CLAVE_PRIVADA_NUEVA>
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = <CLAVE_PUBLICA_DEL_VPS>
PresharedKey = <MANTÉN_LA_QUE_VINO>
Endpoint = <IP_PUBLICA_VPS>:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

Para generar una clave privada nueva en CasaOS:
```bash
wg genkey
```

#### Paso 7: Actualizar el VPS con la clave pública de CasaOS

Genera la clave pública desde la privada:
```bash
echo "TU_CLAVE_PRIVADA" | wg pubkey
```

Luego, en tu VPS, actualiza `wg0.conf`:
```bash
cd ~/wireguard/config
nano wg0.conf
```
Agrega en `[Peer]`:
```ini
PublicKey = <CLAVE_PUBLICA_DE_CASAOS>
AllowedIPs = 10.69.69.2/32, 192.168.1.0/24
```
Reinicia:
```bash
docker compose restart
```

#### Paso 8: Reiniciar WireGuard en CasaOS

1. Ve a **Applications** en CasaOS
2. Busca **WireGuard**
3. Clic en **Restart**

---

## 📱 Conectar tu móvil u otros dispositivos

### Paso 1: Instalar WireGuard en tu móvil

- **Android:** [Google Play Store](https://play.google.com/store/apps/details?id=com.wireguard.android)
- **iOS:** [App Store](https://apps.apple.com/app/wireguard/id1441195209)

### Paso 2: Obtener código QR

En tu VPS:
```bash
cd ~/wireguard/config
ls peer*
```

Verás carpetas: `peer1`, `peer2`, `peer3`, `peer4`.

Para ver el QR del `peer2` (el primero suele ser para la Raspberry):
```bash
cat peer2/peer2.png
```

O ver la configuración en texto:
```bash
cat peer2/peer2.conf
```

### Paso 3: Escanear QR desde el móvil

1. Abre WireGuard en tu móvil
2. Toca el botón **+** (más)
3. Selecciona **Escanear código QR**
4. Escanea el código QR que aparece en la terminal

Si no puedes ver el QR directamente:

- **Opción A: Copiar manualmente**
  ```bash
  cat peer2/peer2.conf
  ```
  Copia el contenido y en el móvil selecciona **Crear desde archivo o archivo**
- **Opción B: Usar SFTP**
  1. Descarga [FileZilla](https://filezilla-project.org/) o [WinSCP](https://winscp.net/)
  2. Conéctate a tu VPS por SFTP
  3. Descarga `peer2/peer2.png`
  4. Escanea la imagen desde tu móvil

### Paso 4: Activar la conexión

1. En WireGuard móvil, activa el túnel
2. Verás un icono de llave en la barra superior
3. ¡Ya estás conectado!

---

## ✅ Verificar que funciona

### Prueba 1: Verificar IP pública

Con la VPN **DESACTIVADA**:
```text
1) Abre el navegador en tu móvil
2) Busca en Google: "cuál es mi IP"
3) Anota la IP (ejemplo: 100.50.30.20)
```

Con la VPN **ACTIVADA**:
```text
1) Activa WireGuard en tu móvil
2) Busca de nuevo: "cuál es mi IP"
3) Debería mostrar la IP de tu VPS (ejemplo: 203.45.67.89)
```

✅ Si la IP cambió, funciona correctamente.

### Prueba 2: Acceder a tu red local

Con la VPN activada, intenta acceder a un servicio de tu casa:
```text
http://192.168.1.50
```
(Reemplaza con la IP de tu Raspberry Pi o cualquier dispositivo local.)

✅ Si carga tu servicio, todo funciona perfectamente.

### Prueba 3: Verificar el túnel desde el VPS

En tu VPS:
```bash
docker exec wireguard wg show
```

Deberías ver algo así:
```text
interface: wg0
public key: zL4kP9mN7xR5...
private key: (hidden)
listening port: 51820

peer: yDhN9vK3mP8wX2...  # Tu Raspberry
endpoint: 89.45.123.67:54321
allowed ips: 10.69.69.2/32, 192.168.1.0/24
latest handshake: 30 seconds ago
transfer: 2.50 MiB received, 1.20 MiB sent

peer: aB3cD4eF5gH6...  # Tu móvil
endpoint: 78.123.45.89:12345
allowed ips: 10.69.69.3/32
latest handshake: 5 seconds ago
transfer: 512 KiB received, 256 KiB sent
```

✅ Si ves "latest handshake" con tiempos recientes, está conectado.

---

## 🔧 Solución de problemas

### El túnel no se establece

**Síntomas:** La VPN se conecta pero no tienes acceso a nada.

**Solución 1: Verificar puerto UDP en el VPS**
```bash
sudo iptables -L -n | grep 51820
# Si no aparece:
sudo iptables -I INPUT -p udp --dport 51820 -j ACCEPT
```

**Solución 2: Verificar firewall de Oracle Cloud**
- Ve a tu instancia en Oracle Cloud Console
- Virtual Cloud Network > Security Lists
- Verifica que el puerto 51820/UDP está abierto

**Solución 3: Verificar logs**
```bash
# En el VPS
cd ~/wireguard
docker compose logs -f
# En la Raspberry
cd ~/wireguard
docker compose logs -f
```

### No puedo acceder a mi red local (192.168.1.X)

**Problema:** La VPN conecta pero no puedes acceder a `192.168.1.50`.

**Solución 1: Verificar AllowedIPs en el VPS**
```bash
cd ~/wireguard/config
nano wg0.conf
```
Asegúrate de que en `[Peer]` (Raspberry) está:
```ini
AllowedIPs = 10.69.69.2/32, 192.168.1.0/24
```

**Solución 2: Verificar IP forwarding**
```bash
sudo sysctl net.ipv4.ip_forward
# Debería mostrar: net.ipv4.ip_forward = 1
# Si muestra 0:
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
```

**Solución 3: Verificar que tu red local es realmente 192.168.1.0/24**
```bash
# En tu ordenador
ipconfig    # Windows
ip addr     # Linux/Mac
```
Si tu red es diferente (ejemplo: `192.168.0.0/24` o `10.0.0.0/24`), actualiza el `wg0.conf` del VPS.

### La conexión se cae constantemente

**Solución: Aumentar PersistentKeepalive**
```bash
nano ~/wireguard/config/wg0/wg0.conf
```
Cambia:
```ini
PersistentKeepalive = 25
```
A:
```ini
PersistentKeepalive = 30
```
Reinicia:
```bash
docker compose restart
```

### Error: "Docker not found"

Instalar Docker:
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```
Verificar:
```bash
docker --version
```

### Error: "Permission denied" al ejecutar Docker

Agregar tu usuario al grupo docker:
```bash
sudo usermod -aG docker $USER
```
Reiniciar sesión o reiniciar:
```bash
sudo reboot
```

### El móvil se conecta pero no funciona nada

**Verifica que el peer del móvil tiene AllowedIPs correcto**

En el archivo del peer (ejemplo: `peer2.conf`):
```ini
AllowedIPs = 0.0.0.0/0
```
**NO debe ser:**
```ini
AllowedIPs = 10.69.69.0/24  # ❌ INCORRECTO para clientes móviles
```

---

## 🛠️ Comandos útiles

Ver estado de WireGuard (VPS o Raspberry):
```bash
docker exec wireguard wg show
```

Ver logs en tiempo real:
```bash
cd ~/wireguard
docker compose logs -f
```

Reiniciar WireGuard:
```bash
cd ~/wireguard
docker compose restart
```

Detener WireGuard:
```bash
cd ~/wireguard
docker compose down
```

Iniciar WireGuard:
```bash
cd ~/wireguard
docker compose up -d
```

Ver configuración actual:
```bash
# VPS
cat ~/wireguard/config/wg0.conf
# Raspberry
cat ~/wireguard/config/wg0/wg0.conf
```

Agregar más dispositivos (peers):
```bash
# En el VPS, edita docker-compose.yml
cd ~/wireguard
nano docker-compose.yml
# Cambia:
#   PEERS=4   # Aumenta este número
# A:
#   PEERS=6   # Por ejemplo
# Reinicia:
docker compose up -d --force-recreate
```
Se generarán nuevos peers (`peer5`, `peer6`, etc.).

Ver todos los QR codes:
```bash
cd ~/wireguard/config
for i in peer*/peer*.png; do echo "=== $i ==="; cat "$i"; echo ""; done
```

Verificar que el puerto está abierto (VPS):
```bash
sudo netstat -tulpn | grep 51820
# Debería mostrar:
# udp 0.0.0.0:51820 0.0.0.0:* LISTEN docker-proxy
```

Resetear todo y empezar de nuevo:
```bash
# En el VPS:
cd ~/wireguard
docker compose down
rm -rf config/
docker compose up -d

# En la Raspberry:
cd ~/wireguard
docker compose down
rm -rf config/
# Volver a crear la configuración manualmente
```

---

## 📚 Recursos adicionales

- **Documentación oficial WireGuard:** https://www.wireguard.com/
- **Imagen Docker linuxserver/wireguard:** https://docs.linuxserver.io/images/docker-wireguard
- **Comunidad r/WireGuard:** https://www.reddit.com/r/WireGuard/
- **Tutorial VPS gratuito Oracle Cloud:** [Enlace]

---

## ❓ Preguntas frecuentes

### ¿Es seguro?

Sí. WireGuard usa criptografía de última generación (Curve25519, ChaCha20, Poly1305). Es más seguro y moderno que OpenVPN o IPsec.

### ¿Afecta la velocidad de internet?

Muy poco. WireGuard es extremadamente eficiente. El cuello de botella será la velocidad de tu VPS, no WireGuard.

### ¿Puedo usar esto para ver Netflix de otro país?

Sí, si tu VPS está en otro país, aparecerás como si estuvieras allí. Pero el objetivo principal de este tutorial es acceder a tu casa.

### ¿Cuántos dispositivos puedo conectar?

Por defecto el script configura 4 peers (dispositivos). Puedes aumentarlo editando `PEERS=` en el `docker-compose.yml` del VPS.

### ¿Funciona con cualquier aplicación?

Sí. Una vez conectado a la VPN, es como si estuvieras físicamente en tu casa. Todas las apps funcionan normalmente.

### ¿Qué pasa si mi Raspberry se apaga?

No podrás acceder a tu red local hasta que vuelva a encenderse y reconecte la VPN. Los demás dispositivos (móvil) podrán conectarse al VPS pero no acceder a tu casa.

### ¿Puedo tener múltiples redes detrás del mismo VPS?

Sí. Puedes configurar múltiples Raspberry Pi en diferentes casas, todas conectadas al mismo VPS. Solo usa IPs diferentes (`10.69.69.3`, `10.69.69.4`, etc.).

### ¿Esto funciona con IPv6?

Este tutorial usa IPv4. WireGuard soporta IPv6 pero requiere configuración adicional.

### ¿Puedo usar un dominio en vez de una IP?

Sí. En el campo `Endpoint`, puedes poner `midominio.com:51820` en vez de la IP, siempre que el dominio apunte a tu VPS.

### ¿Necesito renovar algo o pagar mensualmente?

No. Una vez configurado, funciona indefinidamente sin costos adicionales (si usas un VPS gratuito como Oracle Cloud Free Tier).

---

## 💡 Tips y buenas prácticas

### Seguridad

1. **Cambia las claves periódicamente** (cada 6–12 meses)
2. **No compartas los QR codes** con nadie
3. **Usa contraseñas fuertes** en tu VPS y Raspberry
4. **Actualiza regularmente:**
   ```bash
   docker compose pull
   docker compose up -d
   ```

### Rendimiento

1. **Elige un VPS cercano geográficamente** para menor latencia
2. **Desactiva la VPN** cuando estés en casa (no es necesaria)
3. **Monitoriza el uso** del VPS para no exceder los límites gratuitos

### Respaldo

1. **Guarda una copia de los archivos de configuración:**
   ```bash
   # En el VPS
   cd ~/wireguard
   tar -czf wireguard-backup-$(date +%Y%m%d).tar.gz config/
   ```
2. **Guarda los QR codes de tus dispositivos móviles** (captura de pantalla)

### Monitorización

Instala **Portainer** para gestionar Docker visualmente:
```bash
docker volume create portainer_data
docker run -d -p 9000:9000 --name portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data portainer/portainer-ce
```
Accede a `http://IP-VPS:9000` para ver todos tus contenedores.

---

## 🎉 ¡Felicidades!

Si has llegado hasta aquí y todo funciona, ahora puedes:

- ✅ Acceder a tu casa desde cualquier lugar del mundo  
- ✅ Evitar las limitaciones de CGNAT  
- ✅ Proteger tu conexión con cifrado moderno  
- ✅ Gestionar tus servicios self-hosted remotamente  

**¡Disfruta de tu nueva libertad digital!** 🚀

---

## 📝 Changelog

- **v1.0** (Diciembre 2025): Primera versión de la documentación
  - Script automático para VPS
  - Soporte para Raspberry Pi y CasaOS
  - Guía completa de troubleshooting

---

## 🤝 Contribuir

¿Encontraste un error o tienes una mejora?

- **GitHub:** [davidrumbaut620/Setup-WIREGUARD-VPS](https://github.com/davidrumbaut620/Setup-WIREGUARD-VPS)
- **Issues:** [Reportar problema](https://github.com/davidrumbaut620/Setup-WIREGUARD-VPS/issues)

---

## 📄 Licencia

Este tutorial es de uso libre. Puedes compartirlo, modificarlo y distribuirlo libremente.

**Créditos:** David Rumbaut — [Fivel.ink](https://fivel.ink)

---

**Última actualización:** Diciembre 9, 2025
