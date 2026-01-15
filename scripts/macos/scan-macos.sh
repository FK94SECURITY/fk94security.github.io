#!/bin/bash
# ============================================
# VIGÍA - Security Scanner for macOS
# https://github.com/fk94security/vigia
#
# Analiza la configuración de seguridad de tu Mac
# y genera un score de 0 a 100.
# ============================================

VERSION="1.0.0"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Contadores
TOTAL_CHECKS=0
PASSED_CHECKS=0

# Array para resultados JSON
declare -a RESULTS

add_result() {
    local category="$1"
    local name="$2"
    local status="$3"
    local description="$4"
    local how_to_fix="$5"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [ "$status" = "pass" ]; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi

    RESULTS+=("{\"category\":\"$category\",\"name\":\"$name\",\"status\":\"$status\",\"description\":\"$description\",\"fix\":\"$how_to_fix\"}")
}

# Banner
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║   ██╗   ██╗██╗ ██████╗ ██╗ █████╗                        ║"
echo "║   ██║   ██║██║██╔════╝ ██║██╔══██╗                       ║"
echo "║   ██║   ██║██║██║  ███╗██║███████║                       ║"
echo "║   ╚██╗ ██╔╝██║██║   ██║██║██╔══██║                       ║"
echo "║    ╚████╔╝ ██║╚██████╔╝██║██║  ██║                       ║"
echo "║     ╚═══╝  ╚═╝ ╚═════╝ ╚═╝╚═╝  ╚═╝                       ║"
echo "║                                                           ║"
echo "║   Security Scanner for macOS v${VERSION}                      ║"
echo "║   Analizando tu configuración de seguridad...             ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ============================================
# 1. FILEVAULT (Encriptación de disco)
# ============================================
echo -e "${BLUE}[1/10]${NC} Verificando FileVault..."

FILEVAULT_STATUS=$(fdesetup status 2>/dev/null)
if echo "$FILEVAULT_STATUS" | grep -q "FileVault is On"; then
    echo -e "  ${GREEN}✓${NC} FileVault activado - Tu disco está encriptado"
    add_result "encryption" "FileVault" "pass" "Tu disco está encriptado. Si te roban la Mac, no pueden leer tus archivos." ""
else
    echo -e "  ${RED}✗${NC} FileVault DESACTIVADO - Tus archivos no están protegidos"
    add_result "encryption" "FileVault" "fail" "Tu disco NO está encriptado. Cualquiera puede leer tus archivos si tiene acceso físico." "Preferencias del Sistema > Privacidad y Seguridad > FileVault > Activar"
fi

# ============================================
# 2. FIREWALL
# ============================================
echo -e "${BLUE}[2/10]${NC} Verificando Firewall..."

FIREWALL_STATUS=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null)
if echo "$FIREWALL_STATUS" | grep -q "enabled"; then
    echo -e "  ${GREEN}✓${NC} Firewall activado - Bloqueando conexiones no autorizadas"
    add_result "network" "Firewall" "pass" "El firewall bloquea conexiones entrantes no autorizadas." ""
else
    echo -e "  ${RED}✗${NC} Firewall DESACTIVADO - Tu Mac acepta cualquier conexión"
    add_result "network" "Firewall" "fail" "Sin firewall, cualquier app puede recibir conexiones de internet." "Preferencias del Sistema > Red > Firewall > Activar"
fi

# ============================================
# 3. GATEKEEPER
# ============================================
echo -e "${BLUE}[3/10]${NC} Verificando Gatekeeper..."

GATEKEEPER_STATUS=$(spctl --status 2>/dev/null)
if echo "$GATEKEEPER_STATUS" | grep -q "assessments enabled"; then
    echo -e "  ${GREEN}✓${NC} Gatekeeper activado - Solo apps verificadas"
    add_result "system" "Gatekeeper" "pass" "Solo podés instalar apps verificadas por Apple." ""
else
    echo -e "  ${RED}✗${NC} Gatekeeper DESACTIVADO - Podés instalar malware fácilmente"
    add_result "system" "Gatekeeper" "fail" "Podés instalar apps de cualquier origen, incluyendo malware." "sudo spctl --master-enable"
fi

# ============================================
# 4. ACTUALIZACIONES AUTOMÁTICAS
# ============================================
echo -e "${BLUE}[4/10]${NC} Verificando actualizaciones automáticas..."

AUTO_UPDATE=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled 2>/dev/null)

if [ "$AUTO_UPDATE" = "1" ]; then
    echo -e "  ${GREEN}✓${NC} Actualizaciones automáticas activadas"
    add_result "system" "Auto-Update" "pass" "macOS busca actualizaciones de seguridad automáticamente." ""
else
    echo -e "  ${YELLOW}!${NC} Actualizaciones automáticas desactivadas"
    add_result "system" "Auto-Update" "warn" "No se buscan actualizaciones automáticamente." "Preferencias del Sistema > General > Actualización de software"
fi

# ============================================
# 5. REMOTE LOGIN (SSH)
# ============================================
echo -e "${BLUE}[5/10]${NC} Verificando Remote Login (SSH)..."

SSH_LISTENING=$(netstat -an 2>/dev/null | grep "\.22 " | grep -i listen)
if [ -z "$SSH_LISTENING" ]; then
    echo -e "  ${GREEN}✓${NC} SSH desactivado - Nadie puede conectarse remotamente"
    add_result "network" "SSH" "pass" "Nadie puede conectarse remotamente a tu Mac por SSH." ""
else
    echo -e "  ${YELLOW}!${NC} SSH ACTIVADO - Conexiones remotas permitidas"
    add_result "network" "SSH" "warn" "Alguien podría conectarse remotamente si tiene tus credenciales." "Preferencias del Sistema > Compartir > Remote Login OFF"
fi

# ============================================
# 6. COMPARTIR PANTALLA
# ============================================
echo -e "${BLUE}[6/10]${NC} Verificando Compartir Pantalla..."

SCREEN_SHARING=$(netstat -an 2>/dev/null | grep "\.5900 " | grep -i listen)
if [ -z "$SCREEN_SHARING" ]; then
    echo -e "  ${GREEN}✓${NC} Compartir Pantalla desactivado"
    add_result "network" "Screen Sharing" "pass" "Nadie puede ver tu pantalla remotamente." ""
else
    echo -e "  ${YELLOW}!${NC} Compartir Pantalla ACTIVADO"
    add_result "network" "Screen Sharing" "warn" "Alguien podría ver tu pantalla remotamente." "Preferencias del Sistema > Compartir > Screen Sharing OFF"
fi

# ============================================
# 7. FIND MY MAC
# ============================================
echo -e "${BLUE}[7/10]${NC} Verificando Find My Mac..."

FIND_MY=$(nvram -p 2>/dev/null | grep -i "fmm-mobileme-token")
if [ -n "$FIND_MY" ]; then
    echo -e "  ${GREEN}✓${NC} Find My Mac activado - Podés ubicar tu Mac si te la roban"
    add_result "device" "Find My Mac" "pass" "Podés ubicar o borrar tu Mac remotamente si te la roban." ""
else
    echo -e "  ${YELLOW}!${NC} Find My Mac desactivado"
    add_result "device" "Find My Mac" "warn" "Si te roban la Mac, no vas a poder ubicarla." "Preferencias del Sistema > Apple ID > iCloud > Find My Mac"
fi

# ============================================
# 8. SIP (System Integrity Protection)
# ============================================
echo -e "${BLUE}[8/10]${NC} Verificando SIP..."

SIP_STATUS=$(csrutil status 2>/dev/null)
if echo "$SIP_STATUS" | grep -q "enabled"; then
    echo -e "  ${GREEN}✓${NC} SIP activado - Sistema protegido contra modificaciones"
    add_result "system" "SIP" "pass" "El sistema está protegido contra modificaciones maliciosas." ""
else
    echo -e "  ${RED}✗${NC} SIP DESACTIVADO - Sistema vulnerable"
    add_result "system" "SIP" "fail" "El sistema puede ser modificado por malware." "Reiniciar en Recovery Mode > csrutil enable"
fi

# ============================================
# 9. CONTRASEÑA DESPUÉS DE SLEEP
# ============================================
echo -e "${BLUE}[9/10]${NC} Verificando contraseña después de sleep..."

ASK_FOR_PASSWORD=$(defaults read com.apple.screensaver askForPassword 2>/dev/null)
ASK_DELAY=$(defaults read com.apple.screensaver askForPasswordDelay 2>/dev/null)

if [ "$ASK_FOR_PASSWORD" = "1" ] && [ "$ASK_DELAY" = "0" ]; then
    echo -e "  ${GREEN}✓${NC} Contraseña requerida inmediatamente"
    add_result "access" "Password After Sleep" "pass" "Tu Mac pide contraseña inmediatamente al despertar." ""
elif [ "$ASK_FOR_PASSWORD" = "1" ]; then
    echo -e "  ${YELLOW}!${NC} Contraseña con delay"
    add_result "access" "Password After Sleep" "warn" "Hay un delay antes de pedir contraseña." "Preferencias > Pantalla de bloqueo > Requerir contraseña: Inmediatamente"
else
    echo -e "  ${RED}✗${NC} NO se requiere contraseña después de sleep"
    add_result "access" "Password After Sleep" "fail" "Cualquiera puede usar tu Mac cuando se despierta." "Preferencias > Pantalla de bloqueo > Requerir contraseña: Inmediatamente"
fi

# ============================================
# 10. CUENTA DE INVITADO
# ============================================
echo -e "${BLUE}[10/10]${NC} Verificando cuenta de invitado..."

GUEST_ENABLED=$(defaults read /Library/Preferences/com.apple.loginwindow GuestEnabled 2>/dev/null)
if [ "$GUEST_ENABLED" = "0" ]; then
    echo -e "  ${GREEN}✓${NC} Cuenta de invitado desactivada"
    add_result "access" "Guest Account" "pass" "No hay cuenta de invitado que pueda ser explotada." ""
else
    echo -e "  ${YELLOW}!${NC} Cuenta de invitado ACTIVADA"
    add_result "access" "Guest Account" "warn" "La cuenta de invitado podría ser usada para acceder." "Preferencias > Usuarios > Invitado > Desactivar"
fi

# ============================================
# CALCULAR SCORE
# ============================================
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"

if [ $TOTAL_CHECKS -gt 0 ]; then
    SCORE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
else
    SCORE=0
fi

# Color y mensaje según score
if [ $SCORE -ge 80 ]; then
    SCORE_COLOR=$GREEN
    SCORE_MSG="Excelente"
    SCORE_DESC="Tu Mac está bien protegida."
elif [ $SCORE -ge 60 ]; then
    SCORE_COLOR=$YELLOW
    SCORE_MSG="Regular"
    SCORE_DESC="Hay cosas que deberías mejorar."
else
    SCORE_COLOR=$RED
    SCORE_MSG="Necesita atención"
    SCORE_DESC="Tu Mac tiene problemas de seguridad importantes."
fi

echo ""
echo -e "  TU SECURITY SCORE: ${SCORE_COLOR}${SCORE}/100${NC} - ${SCORE_MSG}"
echo ""
echo -e "  ${SCORE_DESC}"
echo ""
echo -e "  Checks pasados: ${GREEN}${PASSED_CHECKS}${NC} / ${TOTAL_CHECKS}"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"

# Generar JSON
JSON_RESULTS=$(IFS=,; echo "${RESULTS[*]}")
JSON_OUTPUT="{\"score\":${SCORE},\"passed\":${PASSED_CHECKS},\"total\":${TOTAL_CHECKS},\"checks\":[${JSON_RESULTS}]}"

echo "$JSON_OUTPUT" > /tmp/vigia_scan_results.json

echo ""
echo -e "Resultados guardados en: ${CYAN}/tmp/vigia_scan_results.json${NC}"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "  ¿Querés mejorar tu score automáticamente?"
echo -e "  Ejecutá: ${GREEN}./harden-macos.sh${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BLUE}Powered by FK94 Security${NC}"
echo -e "  ${BLUE}https://fk94security.com${NC}"
echo ""
