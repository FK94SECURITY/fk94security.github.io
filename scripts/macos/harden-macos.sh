#!/bin/bash

#===============================================================================
# FK94 Security - macOS Hardening Script
#
# Descripción: Script para fortificar la seguridad de macOS
# Uso: sudo ./harden-macos.sh [--all | --audit | módulo específico]
#
# IMPORTANTE: Ejecutar con sudo para cambios del sistema
# IMPORTANTE: Hacer backup antes de ejecutar
#===============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
LOG_FILE="$HOME/Desktop/macos_hardening_$(date +%Y%m%d_%H%M%S).log"
AUDIT_ONLY=false
APPLY_ALL=false

#===============================================================================
# FUNCIONES AUXILIARES
#===============================================================================

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_success() {
    log "${GREEN}[✓]${NC} $1"
}

log_warning() {
    log "${YELLOW}[!]${NC} $1"
}

log_error() {
    log "${RED}[✗]${NC} $1"
}

log_info() {
    log "${BLUE}[i]${NC} $1"
}

log_header() {
    log "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    log "${BLUE}  $1${NC}"
    log "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"
}

confirm() {
    if [ "$APPLY_ALL" = true ]; then
        return 0
    fi
    read -p "$(echo -e ${YELLOW}¿Aplicar este cambio? [y/N]:${NC} )" response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

check_status() {
    if [ $? -eq 0 ]; then
        log_success "$1"
    else
        log_error "$1 - Falló"
    fi
}

#===============================================================================
# VERIFICACIONES INICIALES
#===============================================================================

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Este script requiere permisos de administrador."
        log_info "Ejecutar con: sudo $0"
        exit 1
    fi
}

check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "Este script es solo para macOS"
        exit 1
    fi

    OS_VERSION=$(sw_vers -productVersion)
    log_info "macOS versión: $OS_VERSION"
}

show_banner() {
    echo -e "${BLUE}"
    echo "  _____ _  _____ _  _     ____                       _ _         "
    echo " |  ___| |/ / _ | || |   / ___|  ___  ___ _   _ _ __(_| |_ _   _ "
    echo " | |_  | ' | (_)| || |_  \___ \ / _ \/ __| | | | '__| | __| | | |"
    echo " |  _| | . \\__, |__   _|  ___) |  __| (__| |_| | |  | | |_| |_| |"
    echo " |_|   |_|\_\ /_/   |_|   |____/ \___|\___|\\__,_|_|  |_|\\__|\\__, |"
    echo "                                                           |___/ "
    echo -e "${NC}"
    echo -e "${YELLOW}macOS Hardening Script${NC}"
    echo -e "Documentación: https://github.com/fk94security/fk94_security"
    echo ""
}

#===============================================================================
# MÓDULO 1: FILEVAULT (Encriptación de Disco)
#===============================================================================

module_filevault() {
    log_header "FILEVAULT - Encriptación de Disco"

    # Verificar estado actual
    FV_STATUS=$(fdesetup status)
    log_info "Estado actual: $FV_STATUS"

    if [[ "$FV_STATUS" == *"FileVault is On"* ]]; then
        log_success "FileVault ya está habilitado"
        return 0
    fi

    if [ "$AUDIT_ONLY" = true ]; then
        log_warning "FileVault NO está habilitado - RECOMENDADO ACTIVAR"
        return 1
    fi

    log_warning "FileVault NO está habilitado"
    log_info "FileVault encripta todo el disco, protegiendo datos si roban el equipo"

    if confirm; then
        log_info "Habilitando FileVault..."
        log_warning "IMPORTANTE: Guardar la Recovery Key en un lugar seguro"
        fdesetup enable
        check_status "FileVault habilitado"
    else
        log_info "FileVault no modificado"
    fi
}

#===============================================================================
# MÓDULO 2: FIREWALL
#===============================================================================

module_firewall() {
    log_header "FIREWALL - Protección de Red"

    # Verificar estado actual
    FW_STATUS=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -o "enabled\|disabled")
    log_info "Estado actual del Firewall: $FW_STATUS"

    if [ "$FW_STATUS" = "enabled" ]; then
        log_success "Firewall ya está habilitado"
    else
        if [ "$AUDIT_ONLY" = true ]; then
            log_warning "Firewall NO está habilitado - RECOMENDADO ACTIVAR"
        else
            log_warning "Firewall NO está habilitado"
            if confirm; then
                /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
                check_status "Firewall habilitado"
            fi
        fi
    fi

    # Verificar stealth mode
    STEALTH=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode 2>/dev/null | grep -o "enabled\|disabled")
    log_info "Stealth Mode: $STEALTH"

    if [ "$STEALTH" != "enabled" ]; then
        if [ "$AUDIT_ONLY" = true ]; then
            log_warning "Stealth Mode NO está habilitado"
        else
            log_info "Stealth Mode hace que tu Mac no responda a pings/scans"
            if confirm; then
                /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
                check_status "Stealth Mode habilitado"
            fi
        fi
    else
        log_success "Stealth Mode ya está habilitado"
    fi

    # Habilitar logging
    if [ "$AUDIT_ONLY" = false ]; then
        log_info "Habilitando logging del firewall..."
        /usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode on 2>/dev/null
        check_status "Firewall logging habilitado"
    fi
}

#===============================================================================
# MÓDULO 3: GATEKEEPER Y SIP
#===============================================================================

module_gatekeeper() {
    log_header "GATEKEEPER & SIP - Protección de Sistema"

    # Verificar Gatekeeper
    GK_STATUS=$(spctl --status 2>/dev/null)
    log_info "Gatekeeper: $GK_STATUS"

    if [[ "$GK_STATUS" == *"enabled"* ]]; then
        log_success "Gatekeeper está habilitado"
    else
        if [ "$AUDIT_ONLY" = true ]; then
            log_error "Gatekeeper está DESHABILITADO - RIESGO ALTO"
        else
            log_error "Gatekeeper está DESHABILITADO"
            log_info "Gatekeeper previene la ejecución de apps no firmadas"
            if confirm; then
                spctl --master-enable
                check_status "Gatekeeper habilitado"
            fi
        fi
    fi

    # Verificar SIP
    SIP_STATUS=$(csrutil status 2>/dev/null)
    log_info "SIP: $SIP_STATUS"

    if [[ "$SIP_STATUS" == *"enabled"* ]]; then
        log_success "System Integrity Protection está habilitado"
    else
        log_error "SIP está DESHABILITADO - RIESGO CRÍTICO"
        log_warning "SIP solo se puede habilitar desde Recovery Mode"
        log_info "Reiniciar en Recovery (Cmd+R) y ejecutar: csrutil enable"
    fi
}

#===============================================================================
# MÓDULO 4: CONFIGURACIÓN DE PANTALLA DE BLOQUEO
#===============================================================================

module_lockscreen() {
    log_header "PANTALLA DE BLOQUEO - Configuración de Seguridad"

    if [ "$AUDIT_ONLY" = true ]; then
        log_info "Verificando configuración de pantalla de bloqueo..."
        # Solo mostrar estado actual
        LOCK_DELAY=$(defaults read com.apple.screensaver askForPasswordDelay 2>/dev/null || echo "no configurado")
        log_info "Delay para pedir password: $LOCK_DELAY segundos"
        return
    fi

    log_info "Configurando password requerido inmediatamente al despertar..."
    if confirm; then
        # Requerir password inmediatamente
        defaults write com.apple.screensaver askForPassword -int 1
        defaults write com.apple.screensaver askForPasswordDelay -int 0
        check_status "Password inmediato configurado"
    fi

    log_info "Configurando mensaje en pantalla de bloqueo (info de contacto)..."
    read -p "$(echo -e ${YELLOW}Mensaje para pantalla de bloqueo \(dejar vacío para omitir\):${NC} )" lock_message
    if [ -n "$lock_message" ]; then
        defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "$lock_message"
        check_status "Mensaje de bloqueo configurado"
    fi
}

#===============================================================================
# MÓDULO 5: DESHABILITAR SERVICIOS INNECESARIOS
#===============================================================================

module_services() {
    log_header "SERVICIOS - Deshabilitar Servicios Innecesarios"

    # Remote Login (SSH)
    SSH_STATUS=$(systemsetup -getremotelogin 2>/dev/null | grep -o "On\|Off")
    log_info "Remote Login (SSH): $SSH_STATUS"

    if [ "$SSH_STATUS" = "On" ]; then
        if [ "$AUDIT_ONLY" = true ]; then
            log_warning "Remote Login está habilitado - considerar deshabilitar si no se usa"
        else
            log_warning "Remote Login está habilitado"
            log_info "SSH permite acceso remoto a tu Mac"
            if confirm; then
                systemsetup -setremotelogin off
                check_status "Remote Login deshabilitado"
            fi
        fi
    else
        log_success "Remote Login ya está deshabilitado"
    fi

    # Remote Apple Events
    RAE_STATUS=$(systemsetup -getremoteappleevents 2>/dev/null | grep -o "On\|Off")
    log_info "Remote Apple Events: $RAE_STATUS"

    if [ "$RAE_STATUS" = "On" ]; then
        if [ "$AUDIT_ONLY" = true ]; then
            log_warning "Remote Apple Events está habilitado"
        else
            if confirm; then
                systemsetup -setremoteappleevents off
                check_status "Remote Apple Events deshabilitado"
            fi
        fi
    else
        log_success "Remote Apple Events ya está deshabilitado"
    fi

    # Bluetooth Sharing
    if [ "$AUDIT_ONLY" = false ]; then
        log_info "Deshabilitando Bluetooth Sharing..."
        if confirm; then
            defaults -currentHost write com.apple.Bluetooth PrefKeyServicesEnabled -bool false 2>/dev/null || true
            check_status "Bluetooth Sharing deshabilitado"
        fi
    fi
}

#===============================================================================
# MÓDULO 6: PRIVACIDAD
#===============================================================================

module_privacy() {
    log_header "PRIVACIDAD - Configuración de Privacidad"

    if [ "$AUDIT_ONLY" = false ]; then
        log_info "Deshabilitando envío de datos de diagnóstico a Apple..."
        if confirm; then
            defaults write /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit -bool false 2>/dev/null || true
            check_status "Datos de diagnóstico deshabilitados"
        fi

        log_info "Deshabilitando Siri analytics..."
        if confirm; then
            defaults write com.apple.assistant.support "Siri Data Sharing Opt-In Status" -int 2 2>/dev/null || true
            check_status "Siri analytics deshabilitado"
        fi

        log_info "Deshabilitando personalización de ads..."
        if confirm; then
            defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false 2>/dev/null || true
            check_status "Personalización de ads deshabilitada"
        fi
    else
        log_info "Modo auditoría - verificar manualmente en System Settings > Privacy"
    fi
}

#===============================================================================
# MÓDULO 7: SAFARI HARDENING
#===============================================================================

module_safari() {
    log_header "SAFARI - Hardening del Navegador"

    if [ "$AUDIT_ONLY" = true ]; then
        log_info "Verificar manualmente en Safari > Settings > Privacy"
        return
    fi

    log_info "Configurando Safari para mayor privacidad..."

    if confirm; then
        # Prevenir cross-site tracking
        defaults write com.apple.Safari WebKitPreferences.storageBlockingPolicy -int 1 2>/dev/null || true

        # No enviar search queries a Apple
        defaults write com.apple.Safari UniversalSearchEnabled -bool false 2>/dev/null || true
        defaults write com.apple.Safari SuppressSearchSuggestions -bool true 2>/dev/null || true

        # Mostrar URL completa
        defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true 2>/dev/null || true

        # Deshabilitar auto-fill
        defaults write com.apple.Safari AutoFillFromAddressBook -bool false 2>/dev/null || true
        defaults write com.apple.Safari AutoFillCreditCardData -bool false 2>/dev/null || true
        defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false 2>/dev/null || true

        # Bloquear pop-ups
        defaults write com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically -bool false 2>/dev/null || true

        # Warn about fraudulent websites
        defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true 2>/dev/null || true

        check_status "Safari hardening aplicado"
    fi
}

#===============================================================================
# MÓDULO 8: FINDER SECURITY
#===============================================================================

module_finder() {
    log_header "FINDER - Configuración de Seguridad"

    if [ "$AUDIT_ONLY" = true ]; then
        log_info "Verificando configuración de Finder..."
        SHOW_EXT=$(defaults read NSGlobalDomain AppleShowAllExtensions 2>/dev/null || echo "no configurado")
        log_info "Mostrar extensiones de archivo: $SHOW_EXT"
        return
    fi

    log_info "Mostrando todas las extensiones de archivo..."
    log_info "Esto ayuda a identificar archivos maliciosos disfrazados"

    if confirm; then
        defaults write NSGlobalDomain AppleShowAllExtensions -bool true
        check_status "Extensiones de archivo visibles"
    fi

    log_info "Mostrando advertencia antes de cambiar extensión..."
    if confirm; then
        defaults write com.apple.finder FXEnableExtensionChangeWarning -bool true
        check_status "Advertencia de extensión habilitada"
    fi

    log_info "Deshabilitando .DS_Store en network shares..."
    if confirm; then
        defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
        check_status ".DS_Store en red deshabilitado"
    fi
}

#===============================================================================
# MÓDULO 9: ACTUALIZACIONES AUTOMÁTICAS
#===============================================================================

module_updates() {
    log_header "ACTUALIZACIONES - Configuración de Updates"

    if [ "$AUDIT_ONLY" = true ]; then
        log_info "Verificar en System Settings > General > Software Update"
        AUTO_UPDATE=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled 2>/dev/null || echo "no configurado")
        log_info "Auto check for updates: $AUTO_UPDATE"
        return
    fi

    log_info "Habilitando actualizaciones automáticas de seguridad..."

    if confirm; then
        # Check for updates automatically
        defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

        # Download updates automatically
        defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool true

        # Install system data files and security updates automatically
        defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
        defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true

        # Auto update apps from App Store
        defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool true

        check_status "Actualizaciones automáticas configuradas"
    fi
}

#===============================================================================
# MÓDULO 10: AUDIT / REPORTE
#===============================================================================

generate_report() {
    log_header "GENERANDO REPORTE DE SEGURIDAD"

    REPORT_FILE="$HOME/Desktop/security_audit_$(date +%Y%m%d_%H%M%S).txt"

    {
        echo "═══════════════════════════════════════════════════════════════"
        echo "  FK94 Security - Reporte de Auditoría macOS"
        echo "  Fecha: $(date)"
        echo "  Equipo: $(hostname)"
        echo "  macOS: $(sw_vers -productVersion)"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""

        echo "▸ FILEVAULT"
        fdesetup status
        echo ""

        echo "▸ FIREWALL"
        /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
        /usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode
        echo ""

        echo "▸ GATEKEEPER"
        spctl --status
        echo ""

        echo "▸ SIP (System Integrity Protection)"
        csrutil status
        echo ""

        echo "▸ REMOTE LOGIN (SSH)"
        systemsetup -getremotelogin 2>/dev/null || echo "No disponible"
        echo ""

        echo "▸ REMOTE APPLE EVENTS"
        systemsetup -getremoteappleevents 2>/dev/null || echo "No disponible"
        echo ""

        echo "▸ FIND MY MAC"
        nvram -x -p 2>/dev/null | grep -q "fmm-mobileme-token" && echo "Find My: Habilitado" || echo "Find My: No verificable desde terminal"
        echo ""

        echo "═══════════════════════════════════════════════════════════════"
        echo "  Reporte generado por FK94 Security"
        echo "  https://github.com/fk94security/fk94_security"
        echo "═══════════════════════════════════════════════════════════════"

    } > "$REPORT_FILE"

    log_success "Reporte guardado en: $REPORT_FILE"
    open "$REPORT_FILE"
}

#===============================================================================
# MENÚ PRINCIPAL
#===============================================================================

show_menu() {
    echo ""
    echo -e "${BLUE}Seleccionar módulo a ejecutar:${NC}"
    echo ""
    echo "  1) FileVault (Encriptación de disco)"
    echo "  2) Firewall"
    echo "  3) Gatekeeper & SIP"
    echo "  4) Pantalla de Bloqueo"
    echo "  5) Servicios (SSH, Remote Events)"
    echo "  6) Privacidad"
    echo "  7) Safari Hardening"
    echo "  8) Finder Security"
    echo "  9) Actualizaciones Automáticas"
    echo ""
    echo "  A) Ejecutar TODOS los módulos"
    echo "  R) Solo auditoría (no aplica cambios)"
    echo "  Q) Salir"
    echo ""
    read -p "$(echo -e ${YELLOW}Opción:${NC} )" choice

    case $choice in
        1) module_filevault ;;
        2) module_firewall ;;
        3) module_gatekeeper ;;
        4) module_lockscreen ;;
        5) module_services ;;
        6) module_privacy ;;
        7) module_safari ;;
        8) module_finder ;;
        9) module_updates ;;
        [aA])
            APPLY_ALL=true
            run_all_modules
            ;;
        [rR])
            AUDIT_ONLY=true
            run_all_modules
            generate_report
            ;;
        [qQ])
            log_info "Saliendo..."
            exit 0
            ;;
        *)
            log_error "Opción inválida"
            show_menu
            ;;
    esac

    show_menu
}

run_all_modules() {
    module_filevault
    module_firewall
    module_gatekeeper
    module_lockscreen
    module_services
    module_privacy
    module_safari
    module_finder
    module_updates

    if [ "$AUDIT_ONLY" = false ]; then
        log_header "HARDENING COMPLETADO"
        log_success "Todos los módulos ejecutados"
        log_info "Log guardado en: $LOG_FILE"
        log_warning "Algunos cambios requieren reiniciar para aplicarse"
    fi
}

#===============================================================================
# MAIN
#===============================================================================

main() {
    show_banner
    check_macos
    check_root

    log_info "Log guardándose en: $LOG_FILE"
    log_info "Fecha: $(date)"

    # Parsear argumentos
    case "${1:-}" in
        --all)
            APPLY_ALL=true
            run_all_modules
            ;;
        --audit)
            AUDIT_ONLY=true
            run_all_modules
            generate_report
            ;;
        --help|-h)
            echo "Uso: sudo $0 [opción]"
            echo ""
            echo "Opciones:"
            echo "  --all     Ejecutar todos los módulos sin confirmación"
            echo "  --audit   Solo auditoría, no aplica cambios"
            echo "  --help    Mostrar esta ayuda"
            echo ""
            echo "Sin argumentos: Menú interactivo"
            exit 0
            ;;
        *)
            show_menu
            ;;
    esac
}

main "$@"
