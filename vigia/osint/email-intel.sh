#!/bin/bash
# ============================================
# VIGÍA - Email Intelligence Tool
# https://github.com/fk94security/vigia
#
# Analiza la exposición de un email:
# - Breaches conocidos
# - Cuentas asociadas
# - Información pública
# ============================================

VERSION="1.0.0"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Verificar email
if [ -z "$1" ]; then
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║   VIGÍA - Email Intelligence Tool                         ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "Uso: ./email-intel.sh <email>"
    echo ""
    echo "Ejemplo: ./email-intel.sh juan@gmail.com"
    echo ""
    exit 1
fi

EMAIL="$1"

# Extraer username del email (parte antes del @)
USERNAME=$(echo "$EMAIL" | cut -d@ -f1)
DOMAIN=$(echo "$EMAIL" | cut -d@ -f2)

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
echo "║   Email Intelligence Tool v${VERSION}                         ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "  Analizando: ${CYAN}${EMAIL}${NC}"
echo -e "  Username:   ${USERNAME}"
echo -e "  Dominio:    ${DOMAIN}"
echo ""

# Crear archivo de reporte
REPORT_FILE="/tmp/vigia_email_intel_$(echo $EMAIL | tr '@.' '_').txt"
echo "========================================" > "$REPORT_FILE"
echo "VIGÍA - Email Intelligence Report" >> "$REPORT_FILE"
echo "========================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "Email: $EMAIL" >> "$REPORT_FILE"
echo "Fecha: $(date)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# ============================================
# 1. VERIFICAR EN HAVE I BEEN PWNED
# ============================================
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}[1/5] VERIFICANDO BREACHES (Have I Been Pwned)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "=== BREACHES ===" >> "$REPORT_FILE"

# Usar k-anonymity API (gratis, sin API key)
# Calculamos SHA-1 del email y usamos los primeros 5 caracteres
# Nota: Esta es la API de passwords, para emails se necesita API key
# Vamos a simular con una verificación básica

# Verificación simplificada - la API completa requiere API key
echo -e "  ${YELLOW}!${NC} Para verificar breaches completos, visitá:"
echo -e "  ${CYAN}https://haveibeenpwned.com/account/${EMAIL}${NC}"
echo ""
echo "Verificar en: https://haveibeenpwned.com/account/${EMAIL}" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# También verificar en otras fuentes
echo -e "  Otras fuentes para verificar manualmente:"
echo -e "  • ${CYAN}https://dehashed.com${NC} (requiere cuenta)"
echo -e "  • ${CYAN}https://intelx.io${NC} (búsqueda gratuita limitada)"
echo -e "  • ${CYAN}https://leak-lookup.com${NC}"
echo ""

# ============================================
# 2. BUSCAR GRAVATAR
# ============================================
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}[2/5] BUSCANDO GRAVATAR (Foto de perfil global)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "=== GRAVATAR ===" >> "$REPORT_FILE"

# Calcular MD5 del email para Gravatar
EMAIL_MD5=$(echo -n "$EMAIL" | md5)
GRAVATAR_URL="https://gravatar.com/avatar/${EMAIL_MD5}?d=404"

response=$(curl -s -o /dev/null -w "%{http_code}" "$GRAVATAR_URL" 2>/dev/null)

if [ "$response" = "200" ]; then
    echo -e "  ${GREEN}✓${NC} Gravatar encontrado"
    echo -e "  ${CYAN}https://gravatar.com/${EMAIL_MD5}${NC}"
    echo ""
    echo -e "  ${MAGENTA}→ La persona tiene una foto de perfil asociada a este email${NC}"
    echo -e "  ${MAGENTA}  que se usa en WordPress, GitHub, y otros sitios.${NC}"
    echo "Gravatar: ENCONTRADO - https://gravatar.com/${EMAIL_MD5}" >> "$REPORT_FILE"
else
    echo -e "  ${YELLOW}✗${NC} No tiene Gravatar"
    echo "Gravatar: No encontrado" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"
echo ""

# ============================================
# 3. BUSCAR CUENTAS ASOCIADAS (por username)
# ============================================
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}[3/5] BUSCANDO CUENTAS CON USERNAME: ${USERNAME}${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "=== CUENTAS POSIBLES (username: ${USERNAME}) ===" >> "$REPORT_FILE"

FOUND_ACCOUNTS=()

check_account() {
    local site="$1"
    local url="$2"

    response=$(curl -s -L -o /dev/null -w "%{http_code}" --max-time 8 "$url" 2>/dev/null)

    if [ "$response" = "200" ]; then
        printf "  ${GREEN}✓${NC} %-15s %s\n" "$site" "$url"
        FOUND_ACCOUNTS+=("$site: $url")
        echo "$site: $url" >> "$REPORT_FILE"
    fi
}

# Verificar sitios comunes
check_account "GitHub" "https://github.com/${USERNAME}"
check_account "Twitter" "https://twitter.com/${USERNAME}"
check_account "Instagram" "https://instagram.com/${USERNAME}"
check_account "LinkedIn" "https://linkedin.com/in/${USERNAME}"
check_account "Facebook" "https://facebook.com/${USERNAME}"
check_account "YouTube" "https://youtube.com/@${USERNAME}"
check_account "Reddit" "https://reddit.com/user/${USERNAME}"
check_account "Medium" "https://medium.com/@${USERNAME}"
check_account "Pinterest" "https://pinterest.com/${USERNAME}"
check_account "TikTok" "https://tiktok.com/@${USERNAME}"

echo ""

if [ ${#FOUND_ACCOUNTS[@]} -eq 0 ]; then
    echo -e "  ${YELLOW}No se encontraron cuentas con este username${NC}"
    echo "No se encontraron cuentas" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# ============================================
# 4. INFORMACIÓN DEL DOMINIO DEL EMAIL
# ============================================
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}[4/5] ANALIZANDO DOMINIO: ${DOMAIN}${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "=== DOMINIO: ${DOMAIN} ===" >> "$REPORT_FILE"

# Verificar si es un dominio personal o corporativo
if [[ "$DOMAIN" == "gmail.com" || "$DOMAIN" == "hotmail.com" || "$DOMAIN" == "yahoo.com" || "$DOMAIN" == "outlook.com" || "$DOMAIN" == "icloud.com" || "$DOMAIN" == "live.com" ]]; then
    echo -e "  ${BLUE}Tipo:${NC} Email personal (proveedor público)"
    echo "Tipo: Email personal (proveedor público)" >> "$REPORT_FILE"
else
    echo -e "  ${BLUE}Tipo:${NC} Posible email corporativo/personalizado"
    echo "Tipo: Email corporativo/personalizado" >> "$REPORT_FILE"
    echo ""
    echo -e "  ${MAGENTA}→ Este dominio podría revelar:${NC}"
    echo -e "    • Empresa donde trabaja"
    echo -e "    • Sitio web personal"
    echo -e "    • Organización a la que pertenece"
    echo ""
    echo -e "  Verificar: ${CYAN}https://${DOMAIN}${NC}"
fi
echo "" >> "$REPORT_FILE"
echo ""

# ============================================
# 5. GOOGLE DORKS SUGERIDOS
# ============================================
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}[5/5] GOOGLE DORKS PARA INVESTIGACIÓN MANUAL${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "=== GOOGLE DORKS ===" >> "$REPORT_FILE"

echo -e "  Copiá y pegá estas búsquedas en Google:"
echo ""
echo -e "  ${CYAN}\"${EMAIL}\"${NC}"
echo -e "  → Busca el email exacto en toda la web"
echo ""
echo -e "  ${CYAN}\"${USERNAME}\" site:tripadvisor.com${NC}"
echo -e "  → Reviews de viajes (revelan destinos, fechas)"
echo ""
echo -e "  ${CYAN}\"${USERNAME}\" site:yelp.com${NC}"
echo -e "  → Reviews de restaurantes/negocios (ubicación)"
echo ""
echo -e "  ${CYAN}\"${USERNAME}\" site:google.com/maps${NC}"
echo -e "  → Reviews en Google Maps"
echo ""
echo -e "  ${CYAN}\"${USERNAME}\" filetype:pdf${NC}"
echo -e "  → Documentos PDF con ese nombre"
echo ""
echo -e "  ${CYAN}\"${EMAIL}\" filetype:xls OR filetype:csv${NC}"
echo -e "  → Listas filtradas con el email"
echo ""

echo "\"${EMAIL}\"" >> "$REPORT_FILE"
echo "\"${USERNAME}\" site:tripadvisor.com" >> "$REPORT_FILE"
echo "\"${USERNAME}\" site:yelp.com" >> "$REPORT_FILE"
echo "\"${USERNAME}\" site:google.com/maps" >> "$REPORT_FILE"
echo "\"${USERNAME}\" filetype:pdf" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# ============================================
# RESUMEN Y ANÁLISIS DE RIESGO
# ============================================
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}RESUMEN DE EXPOSICIÓN${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "=== RESUMEN ===" >> "$REPORT_FILE"

echo -e "  ${MAGENTA}¿Qué puede hacer un atacante con esta info?${NC}"
echo ""
echo -e "  1. ${RED}Phishing personalizado${NC}"
echo -e "     Emails falsos mencionando sitios donde tenés cuenta"
echo ""
echo -e "  2. ${RED}Ingeniería social${NC}"
echo -e "     Usar info de reviews/redes para ganar confianza"
echo ""
echo -e "  3. ${RED}Password spraying${NC}"
echo -e "     Probar passwords comunes en todas las cuentas encontradas"
echo ""
echo -e "  4. ${RED}Credential stuffing${NC}"
echo -e "     Si un password fue filtrado, probarlo en otros sitios"
echo ""

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}RECOMENDACIONES${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${GREEN}✓${NC} Usar password único para cada sitio"
echo -e "  ${GREEN}✓${NC} Activar 2FA en todas las cuentas"
echo -e "  ${GREEN}✓${NC} Revisar y borrar reviews que revelen patrones"
echo -e "  ${GREEN}✓${NC} Usar email aliases para registros (SimpleLogin, Firefox Relay)"
echo -e "  ${GREEN}✓${NC} Configurar alertas en haveibeenpwned.com"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Reporte guardado en: ${CYAN}${REPORT_FILE}${NC}"
echo ""
echo -e "  ${BLUE}Powered by FK94 Security${NC}"
echo -e "  ${BLUE}https://fk94security.com${NC}"
echo ""
