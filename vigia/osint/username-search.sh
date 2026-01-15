#!/bin/bash
# ============================================
# VIGÍA - Username Search Tool
# https://github.com/fk94security/vigia
#
# Busca un username en múltiples plataformas
# para verificar dónde existe esa cuenta.
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
FOUND=0
NOT_FOUND=0
ERROR=0

# Verificar que se pasó un username
if [ -z "$1" ]; then
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║   VIGÍA - Username Search Tool                            ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "Uso: ./username-search.sh <username>"
    echo ""
    echo "Ejemplo: ./username-search.sh johndoe"
    echo ""
    exit 1
fi

USERNAME="$1"

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
echo "║   Username Search Tool v${VERSION}                            ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "  Buscando: ${CYAN}${USERNAME}${NC}"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Función para verificar si el username existe
check_site() {
    local site_name="$1"
    local url="$2"
    local not_found_indicator="$3"

    printf "  %-20s " "$site_name"

    # Hacer request con timeout
    response=$(curl -s -L -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null)

    # También obtener el contenido para verificar indicadores
    content=$(curl -s -L --max-time 10 "$url" 2>/dev/null)

    if [ "$response" = "200" ]; then
        # Verificar si el contenido tiene el indicador de "no encontrado"
        if [ -n "$not_found_indicator" ] && echo "$content" | grep -qi "$not_found_indicator"; then
            echo -e "${YELLOW}No encontrado${NC}"
            NOT_FOUND=$((NOT_FOUND + 1))
        else
            echo -e "${GREEN}Encontrado${NC} → $url"
            FOUND=$((FOUND + 1))
        fi
    elif [ "$response" = "404" ]; then
        echo -e "${YELLOW}No encontrado${NC}"
        NOT_FOUND=$((NOT_FOUND + 1))
    elif [ "$response" = "000" ]; then
        echo -e "${RED}Error de conexión${NC}"
        ERROR=$((ERROR + 1))
    else
        echo -e "${YELLOW}No encontrado${NC} (HTTP $response)"
        NOT_FOUND=$((NOT_FOUND + 1))
    fi
}

# Lista de sitios para verificar
echo -e "${BLUE}Redes Sociales${NC}"
echo ""
check_site "Twitter/X" "https://twitter.com/${USERNAME}" "This account doesn't exist"
check_site "Instagram" "https://instagram.com/${USERNAME}" "Sorry, this page"
check_site "TikTok" "https://tiktok.com/@${USERNAME}" "Couldn't find this account"
check_site "Facebook" "https://facebook.com/${USERNAME}" "not available"
check_site "LinkedIn" "https://linkedin.com/in/${USERNAME}" "not found"
check_site "Pinterest" "https://pinterest.com/${USERNAME}" ""
check_site "Reddit" "https://reddit.com/user/${USERNAME}" "page not found"
check_site "Tumblr" "https://${USERNAME}.tumblr.com" "not found"

echo ""
echo -e "${BLUE}Desarrollo${NC}"
echo ""
check_site "GitHub" "https://github.com/${USERNAME}" ""
check_site "GitLab" "https://gitlab.com/${USERNAME}" "doesn't exist"
check_site "Bitbucket" "https://bitbucket.org/${USERNAME}" ""
check_site "Dev.to" "https://dev.to/${USERNAME}" ""
check_site "Stack Overflow" "https://stackoverflow.com/users/${USERNAME}" "Page not found"
check_site "CodePen" "https://codepen.io/${USERNAME}" ""
check_site "Replit" "https://replit.com/@${USERNAME}" ""
check_site "HackerRank" "https://hackerrank.com/${USERNAME}" "Page Not Found"

echo ""
echo -e "${BLUE}Gaming${NC}"
echo ""
check_site "Steam" "https://steamcommunity.com/id/${USERNAME}" "The specified profile could not be found"
check_site "Twitch" "https://twitch.tv/${USERNAME}" "Sorry. Unless you"
check_site "Xbox" "https://account.xbox.com/profile?gamertag=${USERNAME}" ""
check_site "Roblox" "https://www.roblox.com/users/profile?username=${USERNAME}" ""

echo ""
echo -e "${BLUE}Multimedia${NC}"
echo ""
check_site "YouTube" "https://youtube.com/@${USERNAME}" "This page isn"
check_site "Spotify" "https://open.spotify.com/user/${USERNAME}" ""
check_site "SoundCloud" "https://soundcloud.com/${USERNAME}" "We can't find"
check_site "Vimeo" "https://vimeo.com/${USERNAME}" ""
check_site "Flickr" "https://flickr.com/people/${USERNAME}" "Uh oh"
check_site "Medium" "https://medium.com/@${USERNAME}" "doesn't exist"

echo ""
echo -e "${BLUE}Otros${NC}"
echo ""
check_site "Gravatar" "https://en.gravatar.com/${USERNAME}" "Profile not found"
check_site "About.me" "https://about.me/${USERNAME}" ""
check_site "Keybase" "https://keybase.io/${USERNAME}" ""
check_site "Patreon" "https://patreon.com/${USERNAME}" "become a member"
check_site "PayPal" "https://paypal.me/${USERNAME}" ""
check_site "Telegram" "https://t.me/${USERNAME}" ""

# Resumen
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${GREEN}RESUMEN PARA: ${USERNAME}${NC}"
echo ""
echo -e "  ${GREEN}✓${NC} Encontrado en:     ${GREEN}${FOUND}${NC} sitios"
echo -e "  ${YELLOW}✗${NC} No encontrado en:  ${NOT_FOUND} sitios"
if [ $ERROR -gt 0 ]; then
    echo -e "  ${RED}!${NC} Errores:           ${ERROR}"
fi
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Guardar resultados
echo "Username: $USERNAME" > /tmp/vigia_osint_${USERNAME}.txt
echo "Fecha: $(date)" >> /tmp/vigia_osint_${USERNAME}.txt
echo "Encontrado en: $FOUND sitios" >> /tmp/vigia_osint_${USERNAME}.txt
echo "No encontrado: $NOT_FOUND sitios" >> /tmp/vigia_osint_${USERNAME}.txt

echo -e "  Resultados guardados en: ${CYAN}/tmp/vigia_osint_${USERNAME}.txt${NC}"
echo ""
echo -e "  ${BLUE}Powered by FK94 Security${NC}"
echo ""
