#!/bin/bash
#===============================================================================
# FK94 Security - macOS Hardening
# Utils: Helper functions
#===============================================================================

# Source colors
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"

#===============================================================================
# LOGGING
#===============================================================================

log() {
    echo -e "$1" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "$1"
}

log_success() {
    log "  ${TICK} $1"
}

log_fail() {
    log "  ${CROSS} $1"
}

log_warn() {
    log "  ${WARN} $1"
}

log_info() {
    log "  ${INFO} $1"
}

log_action() {
    log "  ${ARROW} $1"
}

log_header() {
    log ""
    log "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BOLD}  $1${NC}"
    log "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log ""
}

log_subheader() {
    log ""
    log "${CYAN}  ▸ $1${NC}"
    log ""
}

#===============================================================================
# DRY RUN SUPPORT
#===============================================================================

execute() {
    local cmd="$1"
    local description="$2"

    if [ "$DRY_RUN" = true ]; then
        log_info "${DIM}[DRY-RUN]${NC} Would execute: $cmd"
        return 0
    fi

    if eval "$cmd" 2>/dev/null; then
        [ -n "$description" ] && log_success "$description"
        return 0
    else
        [ -n "$description" ] && log_fail "$description"
        return 1
    fi
}

#===============================================================================
# CONFIRMATION
#===============================================================================

confirm() {
    if [ "$APPLY_ALL" = true ] || [ "$DRY_RUN" = true ]; then
        return 0
    fi

    local prompt="${1:-Apply this change?}"
    read -p "$(echo -e "  ${YELLOW}$prompt [y/N]:${NC} ")" response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

#===============================================================================
# SYSTEM CHECKS
#===============================================================================

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_fail "This script requires administrator privileges"
        log_info "Run with: sudo $0"
        exit 1
    fi
}

check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        log_fail "This script is for macOS only"
        exit 1
    fi
}

get_macos_version() {
    sw_vers -productVersion
}

get_macos_major() {
    sw_vers -productVersion | cut -d. -f1
}

is_macos_13_or_later() {
    local major=$(get_macos_major)
    [ "$major" -ge 13 ]
}

is_apple_silicon() {
    [[ "$(uname -m)" == "arm64" ]]
}

#===============================================================================
# PROFILE HELPERS
#===============================================================================

get_profile_value() {
    local key="$1"
    local default="$2"

    case "$PROFILE" in
        paranoid)
            case "$key" in
                firewall_stealth) echo "true" ;;
                disable_ssh) echo "true" ;;
                disable_sharing) echo "true" ;;
                disable_bluetooth) echo "true" ;;
                disable_airdrop) echo "true" ;;
                disable_siri) echo "true" ;;
                safari_hardening) echo "strict" ;;
                *) echo "$default" ;;
            esac
            ;;
        recommended)
            case "$key" in
                firewall_stealth) echo "true" ;;
                disable_ssh) echo "true" ;;
                disable_sharing) echo "true" ;;
                disable_bluetooth) echo "false" ;;
                disable_airdrop) echo "false" ;;
                disable_siri) echo "false" ;;
                safari_hardening) echo "moderate" ;;
                *) echo "$default" ;;
            esac
            ;;
        basic)
            case "$key" in
                firewall_stealth) echo "false" ;;
                disable_ssh) echo "false" ;;
                disable_sharing) echo "false" ;;
                disable_bluetooth) echo "false" ;;
                disable_airdrop) echo "false" ;;
                disable_siri) echo "false" ;;
                safari_hardening) echo "minimal" ;;
                *) echo "$default" ;;
            esac
            ;;
        *)
            echo "$default"
            ;;
    esac
}

#===============================================================================
# SCORING
#===============================================================================

declare -g TOTAL_CHECKS=0
declare -g PASSED_CHECKS=0

add_check() {
    local passed="$1"
    ((TOTAL_CHECKS++))
    [ "$passed" = true ] && ((PASSED_CHECKS++))
}

get_score() {
    if [ "$TOTAL_CHECKS" -eq 0 ]; then
        echo "0"
    else
        echo "$((PASSED_CHECKS * 100 / TOTAL_CHECKS))"
    fi
}

get_score_color() {
    local score=$(get_score)
    if [ "$score" -ge 80 ]; then
        echo "$GREEN"
    elif [ "$score" -ge 60 ]; then
        echo "$YELLOW"
    else
        echo "$RED"
    fi
}
