#!/bin/bash

#===============================================================================
# FK94 Security - Linux Hardening Script
#
# Descripcion: Script para fortificar la seguridad de sistemas Linux
# Compatible: Ubuntu, Debian, Fedora, CentOS/RHEL
# Uso: sudo ./harden-linux.sh [--audit | --all]
#
# IMPORTANTE: Ejecutar con sudo
# IMPORTANTE: Hacer backup antes de ejecutar
#===============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables
LOG_FILE="$HOME/linux_hardening_$(date +%Y%m%d_%H%M%S).log"
AUDIT_ONLY=false
APPLY_ALL=false

#===============================================================================
# FUNCIONES AUXILIARES
#===============================================================================

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_success() { log "${GREEN}[✓]${NC} $1"; }
log_warning() { log "${YELLOW}[!]${NC} $1"; }
log_error() { log "${RED}[✗]${NC} $1"; }
log_info() { log "${BLUE}[i]${NC} $1"; }

log_header() {
    log "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    log "${BLUE}  $1${NC}"
    log "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"
}

confirm() {
    if [ "$APPLY_ALL" = true ]; then return 0; fi
    if [ "$AUDIT_ONLY" = true ]; then return 1; fi
    read -p "$(echo -e ${YELLOW}¿Aplicar este cambio? [y/N]:${NC} )" response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        DISTRO="rhel"
    else
        DISTRO="unknown"
    fi
    log_info "Distribucion detectada: $DISTRO $VERSION"
}

detect_package_manager() {
    if command -v apt &> /dev/null; then
        PKG_MANAGER="apt"
        PKG_UPDATE="apt update"
        PKG_INSTALL="apt install -y"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        PKG_UPDATE="dnf check-update"
        PKG_INSTALL="dnf install -y"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        PKG_UPDATE="yum check-update"
        PKG_INSTALL="yum install -y"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
        PKG_UPDATE="pacman -Sy"
        PKG_INSTALL="pacman -S --noconfirm"
    else
        log_error "No se pudo detectar el package manager"
        exit 1
    fi
    log_info "Package manager: $PKG_MANAGER"
}

show_banner() {
    echo -e "${BLUE}"
    echo "  _____ _  _____ _  _     ____                       _ _         "
    echo " |  ___| |/ / _ | || |   / ___|  ___  ___ _   _ _ __(_| |_ _   _ "
    echo " | |_  | ' | (_)| || |_  \___ \ / _ \/ __| | | | '__| | __| | | |"
    echo " |  _| | . \\__, |__   _|  ___) |  __| (__| |_| | |  | | |_| |_| |"
    echo " |_|   |_|\_\ /_/   |_|   |____/ \___|\___|\__,_|_|  |_|\__|\__, |"
    echo "                                                           |___/ "
    echo -e "${NC}"
    echo -e "${YELLOW}Linux Hardening Script${NC}"
    echo -e "https://github.com/fk94security/fk94_security"
    echo ""
}

#===============================================================================
# VERIFICACIONES INICIALES
#===============================================================================

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Este script requiere permisos de root"
        log_info "Ejecutar con: sudo $0"
        exit 1
    fi
}

#===============================================================================
# MODULO 1: ACTUALIZACIONES DEL SISTEMA
#===============================================================================

module_updates() {
    log_header "ACTUALIZACIONES DEL SISTEMA"

    log_info "Verificando actualizaciones disponibles..."

    case $PKG_MANAGER in
        apt)
            apt update 2>/dev/null
            UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo "0")
            ;;
        dnf|yum)
            UPDATES=$(dnf check-update 2>/dev/null | grep -c "^[a-zA-Z]" || echo "0")
            ;;
        pacman)
            UPDATES=$(pacman -Qu 2>/dev/null | wc -l)
            ;;
    esac

    if [ "$UPDATES" -gt 0 ]; then
        log_warning "Hay $UPDATES actualizaciones pendientes"

        if [ "$AUDIT_ONLY" = false ] && confirm; then
            log_info "Instalando actualizaciones..."
            case $PKG_MANAGER in
                apt) apt upgrade -y ;;
                dnf) dnf upgrade -y ;;
                yum) yum update -y ;;
                pacman) pacman -Syu --noconfirm ;;
            esac
            log_success "Actualizaciones instaladas"
        fi
    else
        log_success "Sistema actualizado"
    fi
}

#===============================================================================
# MODULO 2: FIREWALL (UFW/firewalld)
#===============================================================================

module_firewall() {
    log_header "FIREWALL"

    # Detectar firewall disponible
    if command -v ufw &> /dev/null; then
        FIREWALL="ufw"
        FW_STATUS=$(ufw status | head -1)
    elif command -v firewall-cmd &> /dev/null; then
        FIREWALL="firewalld"
        FW_STATUS=$(firewall-cmd --state 2>/dev/null || echo "not running")
    else
        FIREWALL="none"
    fi

    log_info "Firewall detectado: $FIREWALL"
    log_info "Estado: $FW_STATUS"

    if [ "$FIREWALL" = "none" ]; then
        log_warning "No hay firewall instalado"

        if [ "$AUDIT_ONLY" = false ] && confirm; then
            log_info "Instalando UFW..."
            $PKG_INSTALL ufw
            FIREWALL="ufw"
        else
            return
        fi
    fi

    case $FIREWALL in
        ufw)
            if [[ "$FW_STATUS" != *"active"* ]]; then
                log_warning "UFW no esta activo"

                if [ "$AUDIT_ONLY" = false ] && confirm; then
                    # Configurar reglas basicas
                    ufw default deny incoming
                    ufw default allow outgoing
                    ufw allow ssh

                    # Habilitar
                    echo "y" | ufw enable
                    log_success "UFW habilitado con reglas por defecto"
                fi
            else
                log_success "UFW esta activo"
            fi
            ;;

        firewalld)
            if [[ "$FW_STATUS" != "running" ]]; then
                log_warning "firewalld no esta corriendo"

                if [ "$AUDIT_ONLY" = false ] && confirm; then
                    systemctl start firewalld
                    systemctl enable firewalld
                    log_success "firewalld habilitado"
                fi
            else
                log_success "firewalld esta corriendo"
            fi
            ;;
    esac
}

#===============================================================================
# MODULO 3: SSH HARDENING
#===============================================================================

module_ssh() {
    log_header "SSH HARDENING"

    SSHD_CONFIG="/etc/ssh/sshd_config"

    if [ ! -f "$SSHD_CONFIG" ]; then
        log_info "SSH server no instalado"
        return
    fi

    # Verificar configuraciones actuales
    log_info "Configuracion actual de SSH:"

    ROOT_LOGIN=$(grep -E "^PermitRootLogin" $SSHD_CONFIG 2>/dev/null | awk '{print $2}' || echo "default")
    PASS_AUTH=$(grep -E "^PasswordAuthentication" $SSHD_CONFIG 2>/dev/null | awk '{print $2}' || echo "default")
    X11_FWD=$(grep -E "^X11Forwarding" $SSHD_CONFIG 2>/dev/null | awk '{print $2}' || echo "default")

    log_info "  PermitRootLogin: $ROOT_LOGIN"
    log_info "  PasswordAuthentication: $PASS_AUTH"
    log_info "  X11Forwarding: $X11_FWD"

    if [ "$AUDIT_ONLY" = true ]; then
        [ "$ROOT_LOGIN" != "no" ] && log_warning "PermitRootLogin deberia ser 'no'"
        [ "$X11_FWD" != "no" ] && log_warning "X11Forwarding deberia ser 'no'"
        return
    fi

    # Backup
    if confirm; then
        cp $SSHD_CONFIG "${SSHD_CONFIG}.backup.$(date +%Y%m%d)"
        log_success "Backup creado"
    fi

    # Deshabilitar root login
    if [ "$ROOT_LOGIN" != "no" ] && confirm; then
        sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' $SSHD_CONFIG
        if ! grep -q "^PermitRootLogin" $SSHD_CONFIG; then
            echo "PermitRootLogin no" >> $SSHD_CONFIG
        fi
        log_success "Root login deshabilitado"
    fi

    # Deshabilitar X11 Forwarding
    if [ "$X11_FWD" != "no" ] && confirm; then
        sed -i 's/^#*X11Forwarding.*/X11Forwarding no/' $SSHD_CONFIG
        if ! grep -q "^X11Forwarding" $SSHD_CONFIG; then
            echo "X11Forwarding no" >> $SSHD_CONFIG
        fi
        log_success "X11 Forwarding deshabilitado"
    fi

    # Configuraciones adicionales de seguridad
    log_info "Aplicando configuraciones adicionales..."
    if confirm; then
        # MaxAuthTries
        sed -i 's/^#*MaxAuthTries.*/MaxAuthTries 3/' $SSHD_CONFIG
        if ! grep -q "^MaxAuthTries" $SSHD_CONFIG; then
            echo "MaxAuthTries 3" >> $SSHD_CONFIG
        fi

        # ClientAliveInterval
        sed -i 's/^#*ClientAliveInterval.*/ClientAliveInterval 300/' $SSHD_CONFIG
        if ! grep -q "^ClientAliveInterval" $SSHD_CONFIG; then
            echo "ClientAliveInterval 300" >> $SSHD_CONFIG
        fi

        # Protocol 2 only (ya es default en versiones modernas)
        if ! grep -q "^Protocol 2" $SSHD_CONFIG; then
            echo "Protocol 2" >> $SSHD_CONFIG
        fi

        log_success "Configuraciones de SSH aplicadas"

        # Reiniciar SSH
        log_info "Reiniciando servicio SSH..."
        systemctl restart sshd 2>/dev/null || service ssh restart 2>/dev/null
        log_success "SSH reiniciado"
    fi
}

#===============================================================================
# MODULO 4: PERMISOS DE ARCHIVOS CRITICOS
#===============================================================================

module_permissions() {
    log_header "PERMISOS DE ARCHIVOS CRITICOS"

    # Archivos a verificar
    declare -A FILES
    FILES["/etc/passwd"]="644"
    FILES["/etc/shadow"]="640"
    FILES["/etc/group"]="644"
    FILES["/etc/gshadow"]="640"
    FILES["/etc/ssh/sshd_config"]="600"

    for FILE in "${!FILES[@]}"; do
        if [ -f "$FILE" ]; then
            EXPECTED="${FILES[$FILE]}"
            CURRENT=$(stat -c "%a" "$FILE" 2>/dev/null)

            if [ "$CURRENT" = "$EXPECTED" ]; then
                log_success "$FILE: $CURRENT (correcto)"
            else
                log_warning "$FILE: $CURRENT (deberia ser $EXPECTED)"

                if [ "$AUDIT_ONLY" = false ] && confirm; then
                    chmod $EXPECTED "$FILE"
                    log_success "$FILE: permisos corregidos"
                fi
            fi
        fi
    done

    # Verificar archivos world-writable
    log_info "Buscando archivos world-writable en /etc..."
    WW_FILES=$(find /etc -type f -perm -002 2>/dev/null | head -10)
    if [ -n "$WW_FILES" ]; then
        log_warning "Archivos world-writable encontrados:"
        echo "$WW_FILES" | while read f; do log_warning "  $f"; done
    else
        log_success "No hay archivos world-writable en /etc"
    fi
}

#===============================================================================
# MODULO 5: KERNEL HARDENING (sysctl)
#===============================================================================

module_kernel() {
    log_header "KERNEL HARDENING (sysctl)"

    SYSCTL_CONF="/etc/sysctl.d/99-security.conf"

    if [ "$AUDIT_ONLY" = true ]; then
        log_info "Verificando parametros del kernel..."
        log_info "  IP forwarding: $(sysctl -n net.ipv4.ip_forward)"
        log_info "  ICMP redirects: $(sysctl -n net.ipv4.conf.all.accept_redirects)"
        log_info "  SYN cookies: $(sysctl -n net.ipv4.tcp_syncookies)"
        return
    fi

    log_info "Configurando parametros de seguridad del kernel..."

    if confirm; then
        cat > $SYSCTL_CONF << 'EOF'
# FK94 Security - Kernel Hardening

# Disable IP forwarding
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Enable SYN cookies (protect against SYN flood)
net.ipv4.tcp_syncookies = 1

# Log Martian packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignore bogus ICMP errors
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Enable reverse path filtering
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Disable sending ICMP redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Randomize virtual address space
kernel.randomize_va_space = 2

# Restrict kernel pointer exposure
kernel.kptr_restrict = 2

# Restrict dmesg
kernel.dmesg_restrict = 1
EOF

        # Aplicar cambios
        sysctl -p $SYSCTL_CONF 2>/dev/null
        log_success "Parametros del kernel aplicados"
    fi
}

#===============================================================================
# MODULO 6: SERVICIOS INNECESARIOS
#===============================================================================

module_services() {
    log_header "SERVICIOS INNECESARIOS"

    # Servicios potencialmente innecesarios
    SERVICES=(
        "avahi-daemon"      # Multicast DNS
        "cups"              # Printing
        "rpcbind"           # RPC
        "nfs-server"        # NFS
        "vsftpd"            # FTP
        "telnet"            # Telnet
        "xinetd"            # Internet services daemon
    )

    for SERVICE in "${SERVICES[@]}"; do
        if systemctl is-active --quiet "$SERVICE" 2>/dev/null; then
            log_warning "$SERVICE esta corriendo"

            if [ "$AUDIT_ONLY" = false ]; then
                log_info "$SERVICE puede ser innecesario para un desktop/workstation"
                if confirm; then
                    systemctl stop "$SERVICE"
                    systemctl disable "$SERVICE"
                    log_success "$SERVICE deshabilitado"
                fi
            fi
        else
            log_success "$SERVICE no esta corriendo"
        fi
    done
}

#===============================================================================
# MODULO 7: AUDITING (auditd)
#===============================================================================

module_audit() {
    log_header "SISTEMA DE AUDITORIA (auditd)"

    if ! command -v auditctl &> /dev/null; then
        log_warning "auditd no esta instalado"

        if [ "$AUDIT_ONLY" = false ] && confirm; then
            log_info "Instalando auditd..."
            $PKG_INSTALL auditd 2>/dev/null || $PKG_INSTALL audit 2>/dev/null
        else
            return
        fi
    fi

    # Verificar estado
    if systemctl is-active --quiet auditd; then
        log_success "auditd esta corriendo"
    else
        log_warning "auditd no esta corriendo"

        if [ "$AUDIT_ONLY" = false ] && confirm; then
            systemctl start auditd
            systemctl enable auditd
            log_success "auditd habilitado"
        fi
    fi
}

#===============================================================================
# MODULO 8: PASSWORD POLICY
#===============================================================================

module_password() {
    log_header "POLITICA DE PASSWORDS"

    # Verificar configuracion actual
    if [ -f /etc/login.defs ]; then
        PASS_MAX=$(grep "^PASS_MAX_DAYS" /etc/login.defs | awk '{print $2}')
        PASS_MIN=$(grep "^PASS_MIN_DAYS" /etc/login.defs | awk '{print $2}')
        PASS_MIN_LEN=$(grep "^PASS_MIN_LEN" /etc/login.defs | awk '{print $2}')

        log_info "Configuracion actual:"
        log_info "  PASS_MAX_DAYS: $PASS_MAX"
        log_info "  PASS_MIN_DAYS: $PASS_MIN"
        log_info "  PASS_MIN_LEN: $PASS_MIN_LEN"
    fi

    if [ "$AUDIT_ONLY" = true ]; then
        return
    fi

    log_info "Configurando politica de passwords..."

    if confirm; then
        # Backup
        cp /etc/login.defs /etc/login.defs.backup.$(date +%Y%m%d) 2>/dev/null

        # Configurar
        sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
        sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/' /etc/login.defs
        sed -i 's/^PASS_MIN_LEN.*/PASS_MIN_LEN    12/' /etc/login.defs
        sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   14/' /etc/login.defs

        log_success "Politica de passwords configurada"
    fi
}

#===============================================================================
# MODULO 9: FAIL2BAN
#===============================================================================

module_fail2ban() {
    log_header "FAIL2BAN - Proteccion contra Brute Force"

    if ! command -v fail2ban-client &> /dev/null; then
        log_warning "fail2ban no esta instalado"

        if [ "$AUDIT_ONLY" = false ] && confirm; then
            log_info "Instalando fail2ban..."
            $PKG_INSTALL fail2ban
        else
            return
        fi
    fi

    # Verificar estado
    if systemctl is-active --quiet fail2ban; then
        log_success "fail2ban esta corriendo"
        JAILS=$(fail2ban-client status 2>/dev/null | grep "Jail list" || echo "No jails")
        log_info "Jails activos: $JAILS"
    else
        log_warning "fail2ban no esta corriendo"

        if [ "$AUDIT_ONLY" = false ] && confirm; then
            # Crear configuracion basica
            if [ ! -f /etc/fail2ban/jail.local ]; then
                cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF
            fi

            systemctl start fail2ban
            systemctl enable fail2ban
            log_success "fail2ban configurado y habilitado"
        fi
    fi
}

#===============================================================================
# MODULO 10: GENERAR REPORTE
#===============================================================================

generate_report() {
    log_header "GENERANDO REPORTE"

    REPORT_FILE="$HOME/security_audit_$(date +%Y%m%d_%H%M%S).txt"

    {
        echo "═══════════════════════════════════════════════════════════════"
        echo "  FK94 Security - Reporte de Auditoria Linux"
        echo "  Fecha: $(date)"
        echo "  Hostname: $(hostname)"
        echo "  Distro: $DISTRO $VERSION"
        echo "  Kernel: $(uname -r)"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""

        echo "▸ FIREWALL"
        if command -v ufw &> /dev/null; then
            ufw status verbose
        elif command -v firewall-cmd &> /dev/null; then
            firewall-cmd --list-all
        fi
        echo ""

        echo "▸ SSH"
        grep -E "^(PermitRootLogin|PasswordAuthentication|X11Forwarding)" /etc/ssh/sshd_config 2>/dev/null
        echo ""

        echo "▸ SERVICIOS CORRIENDO"
        systemctl list-units --type=service --state=running | head -20
        echo ""

        echo "▸ PUERTOS ABIERTOS"
        ss -tuln | head -20
        echo ""

        echo "▸ USUARIOS CON SHELL"
        grep -E "/bin/(bash|sh|zsh)" /etc/passwd
        echo ""

        echo "▸ ULTIMOS LOGINS"
        last -n 10
        echo ""

        echo "═══════════════════════════════════════════════════════════════"
        echo "  Reporte generado por FK94 Security"
        echo "  https://github.com/fk94security/fk94_security"
        echo "═══════════════════════════════════════════════════════════════"

    } > "$REPORT_FILE"

    log_success "Reporte guardado en: $REPORT_FILE"
}

#===============================================================================
# MENU PRINCIPAL
#===============================================================================

show_menu() {
    echo ""
    echo -e "${BLUE}Seleccionar modulo a ejecutar:${NC}"
    echo ""
    echo "  1) Actualizaciones del Sistema"
    echo "  2) Firewall (UFW/firewalld)"
    echo "  3) SSH Hardening"
    echo "  4) Permisos de Archivos"
    echo "  5) Kernel Hardening (sysctl)"
    echo "  6) Servicios Innecesarios"
    echo "  7) Sistema de Auditoria (auditd)"
    echo "  8) Politica de Passwords"
    echo "  9) Fail2ban"
    echo ""
    echo "  A) Ejecutar TODOS los modulos"
    echo "  R) Solo auditoria (generar reporte)"
    echo "  Q) Salir"
    echo ""
    read -p "$(echo -e ${YELLOW}Opcion:${NC} )" choice

    case $choice in
        1) module_updates ;;
        2) module_firewall ;;
        3) module_ssh ;;
        4) module_permissions ;;
        5) module_kernel ;;
        6) module_services ;;
        7) module_audit ;;
        8) module_password ;;
        9) module_fail2ban ;;
        [aA])
            APPLY_ALL=true
            run_all
            ;;
        [rR])
            AUDIT_ONLY=true
            run_all
            generate_report
            ;;
        [qQ])
            log_info "Saliendo..."
            exit 0
            ;;
        *)
            log_error "Opcion invalida"
            ;;
    esac

    show_menu
}

run_all() {
    module_updates
    module_firewall
    module_ssh
    module_permissions
    module_kernel
    module_services
    module_audit
    module_password
    module_fail2ban

    if [ "$AUDIT_ONLY" = false ]; then
        log_header "HARDENING COMPLETADO"
        log_success "Todos los modulos ejecutados"
        log_info "Log guardado en: $LOG_FILE"
        log_warning "Algunos cambios pueden requerir reinicio"
    fi
}

#===============================================================================
# MAIN
#===============================================================================

main() {
    show_banner
    check_root
    detect_distro
    detect_package_manager

    log_info "Log guardandose en: $LOG_FILE"

    case "${1:-}" in
        --all)
            APPLY_ALL=true
            run_all
            ;;
        --audit)
            AUDIT_ONLY=true
            run_all
            generate_report
            ;;
        --help|-h)
            echo "Uso: sudo $0 [opcion]"
            echo ""
            echo "Opciones:"
            echo "  --all     Ejecutar todos los modulos"
            echo "  --audit   Solo auditoria, no aplica cambios"
            echo "  --help    Mostrar esta ayuda"
            exit 0
            ;;
        *)
            show_menu
            ;;
    esac
}

main "$@"
