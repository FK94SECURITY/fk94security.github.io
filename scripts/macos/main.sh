#!/bin/bash
#===============================================================================
#
#  ███████╗██╗  ██╗ █████╗ ██╗  ██╗    ███████╗███████╗ ██████╗██╗   ██╗██████╗ ██╗████████╗██╗   ██╗
#  ██╔════╝██║ ██╔╝██╔══██╗██║  ██║    ██╔════╝██╔════╝██╔════╝██║   ██║██╔══██╗██║╚══██╔══╝╚██╗ ██╔╝
#  █████╗  █████╔╝ ╚██████║███████║    ███████╗█████╗  ██║     ██║   ██║██████╔╝██║   ██║    ╚████╔╝
#  ██╔══╝  ██╔═██╗  ╚═══██║╚════██║    ╚════██║██╔══╝  ██║     ██║   ██║██╔══██╗██║   ██║     ╚██╔╝
#  ██║     ██║  ██╗ █████╔╝     ██║    ███████║███████╗╚██████╗╚██████╔╝██║  ██║██║   ██║      ██║
#  ╚═╝     ╚═╝  ╚═╝ ╚════╝      ╚═╝    ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝   ╚═╝      ╚═╝
#
#  macOS Security Hardening Tool
#  Version: 2.0.0
#  https://fk94security.com
#
#===============================================================================
#
#  USAGE:
#    ./main.sh [OPTIONS]
#
#  OPTIONS:
#    -p, --profile PROFILE    Security profile: basic, recommended, paranoid
#    -a, --audit              Audit only mode (no changes)
#    -d, --dry-run            Show what would be done without making changes
#    -m, --modules MODULES    Run specific modules (comma-separated)
#    -q, --quiet              Minimal output
#    -h, --help               Show this help message
#
#  PROFILES:
#    basic       - Essential protections, maximum compatibility
#    recommended - Balanced security (default)
#    paranoid    - Maximum security for high-risk users
#
#  EXAMPLES:
#    ./main.sh                           # Run with default (recommended) profile
#    ./main.sh -p paranoid               # Run with paranoid profile
#    ./main.sh --audit                   # Audit only, no changes
#    ./main.sh --dry-run -p paranoid     # Preview paranoid changes
#    ./main.sh -m system,network         # Run only system and network modules
#
#===============================================================================

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
PROFILE="recommended"
AUDIT_ONLY=false
DRY_RUN=false
QUIET=false
SELECTED_MODULES=""
VERSION="2.0.0"

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_TOTAL=0

#===============================================================================
# SOURCE DEPENDENCIES
#===============================================================================

source "$SCRIPT_DIR/utils/colors.sh"
source "$SCRIPT_DIR/utils/helpers.sh"

#===============================================================================
# USAGE
#===============================================================================

show_help() {
    cat << 'EOF'
FK94 Security - macOS Hardening Tool

USAGE:
    ./main.sh [OPTIONS]

OPTIONS:
    -p, --profile PROFILE    Security profile (basic, recommended, paranoid)
    -a, --audit              Audit only mode - check without making changes
    -d, --dry-run            Preview changes without applying them
    -m, --modules MODULES    Run specific modules (comma-separated)
                             Available: system, network, access, privacy, lockdown
    -q, --quiet              Minimal output (errors and summary only)
    -h, --help               Show this help message
    -v, --version            Show version

PROFILES:
    basic       Essential protections, maximum compatibility
                - FileVault (prompt)
                - Firewall enabled
                - Basic privacy settings

    recommended Balanced security and usability (DEFAULT)
                - Everything in basic, plus:
                - FileVault enforced
                - Stealth mode firewall
                - Sharing services disabled
                - Enhanced privacy

    paranoid    Maximum security for high-risk users
                - Everything in recommended, plus:
                - Lockdown Mode (macOS 13+)
                - Block all incoming connections
                - Disable Bluetooth, AirDrop, Handoff
                - Strict Safari hardening
                - Disable IPv6

EXAMPLES:
    ./main.sh                           Run with recommended profile
    ./main.sh -p paranoid               Maximum security
    ./main.sh --audit                   Check security without changes
    ./main.sh --dry-run -p paranoid     Preview paranoid settings
    ./main.sh -m system,network         Run specific modules only

For more information: https://fk94security.com/docs/macos
EOF
}

show_version() {
    echo "FK94 Security macOS Hardening Tool v$VERSION"
    echo "https://fk94security.com"
}

#===============================================================================
# PARSE ARGUMENTS
#===============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--profile)
                PROFILE="$2"
                if [[ ! "$PROFILE" =~ ^(basic|recommended|paranoid)$ ]]; then
                    echo -e "${RED}Error: Invalid profile '$PROFILE'${NC}"
                    echo "Valid profiles: basic, recommended, paranoid"
                    exit 1
                fi
                shift 2
                ;;
            -a|--audit)
                AUDIT_ONLY=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -m|--modules)
                SELECTED_MODULES="$2"
                shift 2
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            *)
                echo -e "${RED}Error: Unknown option '$1'${NC}"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

#===============================================================================
# PREFLIGHT CHECKS
#===============================================================================

preflight_checks() {
    # Check if running on macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        echo -e "${RED}Error: This script is for macOS only${NC}"
        exit 1
    fi

    # Check macOS version
    local version=$(sw_vers -productVersion)
    local major=$(echo "$version" | cut -d. -f1)

    if [ "$major" -lt 11 ]; then
        echo -e "${YELLOW}Warning: This script is optimized for macOS 11+${NC}"
        echo "Some features may not work on macOS $version"
    fi

    # Check if running as root (warn, don't require)
    if [ "$EUID" -eq 0 ]; then
        echo -e "${YELLOW}Warning: Running as root. Some user-specific settings may not apply correctly.${NC}"
    fi

    # Check for required tools
    local required_tools=("defaults" "spctl" "fdesetup" "csrutil")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo -e "${RED}Error: Required tool '$tool' not found${NC}"
            exit 1
        fi
    done
}

#===============================================================================
# SHOW BANNER
#===============================================================================

show_banner() {
    if [ "$QUIET" = true ]; then
        return
    fi

    clear
    echo -e "${CYAN}"
    cat << 'EOF'
  ╔═══════════════════════════════════════════════════════════════════════════╗
  ║                                                                           ║
  ║   ███████╗██╗  ██╗ █████╗ ██╗  ██╗    ███████╗███████╗ ██████╗           ║
  ║   ██╔════╝██║ ██╔╝██╔══██╗██║  ██║    ██╔════╝██╔════╝██╔════╝           ║
  ║   █████╗  █████╔╝ ╚██████║███████║    ███████╗█████╗  ██║                ║
  ║   ██╔══╝  ██╔═██╗  ╚═══██║╚════██║    ╚════██║██╔══╝  ██║                ║
  ║   ██║     ██║  ██╗ █████╔╝     ██║    ███████║███████╗╚██████╗           ║
  ║   ╚═╝     ╚═╝  ╚═╝ ╚════╝      ╚═╝    ╚══════╝╚══════╝ ╚═════╝           ║
  ║                                                                           ║
  ║                   macOS Security Hardening Tool                           ║
  ╚═══════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    echo -e "  ${DIM}Version $VERSION | https://fk94security.com${NC}"
    echo ""
}

#===============================================================================
# SHOW CONFIGURATION
#===============================================================================

show_config() {
    if [ "$QUIET" = true ]; then
        return
    fi

    local profile_color=""
    case $PROFILE in
        basic)      profile_color="${GREEN}" ;;
        recommended) profile_color="${YELLOW}" ;;
        paranoid)   profile_color="${RED}" ;;
    esac

    echo -e "  ${BOLD}Configuration:${NC}"
    echo -e "  ├─ Profile:    ${profile_color}${PROFILE}${NC}"

    if [ "$AUDIT_ONLY" = true ]; then
        echo -e "  ├─ Mode:       ${CYAN}Audit Only${NC} (no changes will be made)"
    elif [ "$DRY_RUN" = true ]; then
        echo -e "  ├─ Mode:       ${CYAN}Dry Run${NC} (preview changes)"
    else
        echo -e "  ├─ Mode:       ${GREEN}Apply Changes${NC}"
    fi

    if [ -n "$SELECTED_MODULES" ]; then
        echo -e "  └─ Modules:    ${SELECTED_MODULES}"
    else
        echo -e "  └─ Modules:    all"
    fi

    echo ""

    # Confirmation for non-audit modes
    if [ "$AUDIT_ONLY" = false ] && [ "$DRY_RUN" = false ]; then
        echo -e "  ${YELLOW}This will modify system settings.${NC}"
        if ! confirm "Continue?"; then
            echo -e "\n  ${DIM}Cancelled by user${NC}"
            exit 0
        fi
    fi

    echo ""
}

#===============================================================================
# LOAD MODULES
#===============================================================================

load_modules() {
    local modules_dir="$SCRIPT_DIR/modules"

    # Source all modules
    source "$modules_dir/system.sh"
    source "$modules_dir/network.sh"
    source "$modules_dir/access.sh"
    source "$modules_dir/privacy.sh"
    source "$modules_dir/lockdown.sh"
}

#===============================================================================
# RUN MODULES
#===============================================================================

run_modules() {
    local modules_to_run=""

    if [ -n "$SELECTED_MODULES" ]; then
        modules_to_run="$SELECTED_MODULES"
    else
        modules_to_run="system,network,access,privacy,lockdown"
    fi

    IFS=',' read -ra MODULE_ARRAY <<< "$modules_to_run"

    for module in "${MODULE_ARRAY[@]}"; do
        module=$(echo "$module" | tr -d ' ')  # Trim whitespace
        case $module in
            system)
                module_system
                ;;
            network)
                module_network
                ;;
            access)
                module_access
                ;;
            privacy)
                module_privacy
                ;;
            lockdown)
                module_lockdown
                ;;
            *)
                log_warn "Unknown module: $module (skipping)"
                ;;
        esac
    done
}

#===============================================================================
# SHOW SUMMARY
#===============================================================================

show_summary() {
    echo ""
    log_header "SECURITY SUMMARY"

    local total=$((CHECKS_PASSED + CHECKS_FAILED))
    local score=0

    if [ "$total" -gt 0 ]; then
        score=$((CHECKS_PASSED * 100 / total))
    fi

    # Score color
    local score_color=""
    if [ "$score" -ge 80 ]; then
        score_color="${GREEN}"
    elif [ "$score" -ge 60 ]; then
        score_color="${YELLOW}"
    else
        score_color="${RED}"
    fi

    echo ""
    echo -e "  ${BOLD}Results:${NC}"
    echo -e "  ├─ ${GREEN}${CHECK} Passed:${NC}  $CHECKS_PASSED"
    echo -e "  ├─ ${RED}${CROSS} Failed:${NC}  $CHECKS_FAILED"
    echo -e "  └─ ${BOLD}Score:${NC}    ${score_color}${score}%${NC}"
    echo ""

    # Visual score bar
    local bar_length=40
    local filled=$((score * bar_length / 100))
    local empty=$((bar_length - filled))

    printf "  ["
    printf "${score_color}"
    for ((i=0; i<filled; i++)); do printf "█"; done
    printf "${DIM}"
    for ((i=0; i<empty; i++)); do printf "░"; done
    printf "${NC}] ${score_color}${score}%%${NC}\n"

    echo ""

    # Recommendations based on score
    if [ "$score" -ge 90 ]; then
        echo -e "  ${GREEN}Excellent!${NC} Your Mac is well secured."
    elif [ "$score" -ge 70 ]; then
        echo -e "  ${YELLOW}Good.${NC} Consider addressing the warnings above."
    elif [ "$score" -ge 50 ]; then
        echo -e "  ${YELLOW}Fair.${NC} Several security improvements recommended."
    else
        echo -e "  ${RED}Needs attention.${NC} Multiple security issues found."
    fi

    echo ""

    # Mode-specific messages
    if [ "$AUDIT_ONLY" = true ]; then
        echo -e "  ${DIM}Run without --audit to apply fixes${NC}"
    elif [ "$DRY_RUN" = true ]; then
        echo -e "  ${DIM}Run without --dry-run to apply changes${NC}"
    fi

    echo ""
    echo -e "  ${DIM}Report generated: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "  ${DIM}FK94 Security | https://fk94security.com${NC}"
    echo ""
}

#===============================================================================
# MAIN
#===============================================================================

main() {
    parse_args "$@"
    preflight_checks
    show_banner
    load_modules
    show_config
    run_modules
    show_summary
}

# Run
main "$@"
