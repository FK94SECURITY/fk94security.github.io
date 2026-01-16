#!/bin/bash
#===============================================================================
# FK94 Security - macOS Hardening
# Audit & Compliance Checks
#
# Generates detailed security audit reports
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/colors.sh"
source "$SCRIPT_DIR/utils/helpers.sh"

#===============================================================================
# AUDIT REPORT GENERATION
#===============================================================================

generate_audit_report() {
    local output_file="${1:-$HOME/Desktop/fk94_security_audit_$(date +%Y%m%d_%H%M%S).txt}"

    {
        echo "==============================================================================="
        echo "FK94 Security - macOS Security Audit Report"
        echo "==============================================================================="
        echo ""
        echo "Generated: $(date)"
        echo "Hostname:  $(hostname)"
        echo "macOS:     $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
        echo "Hardware:  $(sysctl -n hw.model 2>/dev/null || echo 'Unknown')"
        echo ""
        echo "==============================================================================="
        echo "SYSTEM SECURITY"
        echo "==============================================================================="
        echo ""

        # FileVault
        echo "[FileVault]"
        fdesetup status 2>/dev/null || echo "Could not check FileVault status"
        echo ""

        # SIP
        echo "[System Integrity Protection]"
        csrutil status 2>/dev/null || echo "Could not check SIP status"
        echo ""

        # Gatekeeper
        echo "[Gatekeeper]"
        spctl --status 2>/dev/null || echo "Could not check Gatekeeper status"
        echo ""

        # Secure Boot (Apple Silicon)
        if is_apple_silicon; then
            echo "[Secure Boot]"
            echo "Apple Silicon: Secure Boot enabled by default"
        fi
        echo ""

        echo "==============================================================================="
        echo "NETWORK SECURITY"
        echo "==============================================================================="
        echo ""

        # Firewall
        echo "[Application Firewall]"
        /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null
        /usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode 2>/dev/null
        /usr/libexec/ApplicationFirewall/socketfilterfw --getblockall 2>/dev/null
        echo ""

        # SSH
        echo "[Remote Login (SSH)]"
        systemsetup -getremotelogin 2>/dev/null || echo "Could not check SSH status"
        echo ""

        # Sharing Services
        echo "[Sharing Services]"
        echo "Screen Sharing: $(launchctl list 2>/dev/null | grep -c 'screensharing' && echo 'Enabled' || echo 'Disabled')"
        echo "File Sharing:   $(launchctl list 2>/dev/null | grep -c 'smbd' && echo 'Enabled' || echo 'Disabled')"
        echo ""

        echo "==============================================================================="
        echo "ACCESS CONTROL"
        echo "==============================================================================="
        echo ""

        # Auto-login
        echo "[Auto-Login]"
        local auto_login=$(defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || echo "Disabled")
        echo "Auto-login: $auto_login"
        echo ""

        # Guest Account
        echo "[Guest Account]"
        local guest=$(defaults read /Library/Preferences/com.apple.loginwindow GuestEnabled 2>/dev/null || echo "0")
        [ "$guest" = "1" ] && echo "Guest account: Enabled" || echo "Guest account: Disabled"
        echo ""

        # Password Policy
        echo "[Password Requirements]"
        defaults read com.apple.screensaver askForPassword 2>/dev/null && echo "Password on wake: Enabled" || echo "Password on wake: Check manually"
        echo ""

        echo "==============================================================================="
        echo "PRIVACY"
        echo "==============================================================================="
        echo ""

        # Analytics
        echo "[Apple Analytics]"
        local diag=$(defaults read /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit 2>/dev/null || echo "Unknown")
        [ "$diag" = "0" ] && echo "Diagnostics sharing: Disabled" || echo "Diagnostics sharing: Enabled"
        echo ""

        # Location Services
        echo "[Location Services]"
        local location=$(defaults read /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd.* LocationServicesEnabled 2>/dev/null || echo "Unknown")
        echo "Location Services: $location"
        echo ""

        echo "==============================================================================="
        echo "INSTALLED SECURITY SOFTWARE"
        echo "==============================================================================="
        echo ""

        # Check for common security tools
        echo "[Security Software]"
        [ -d "/Library/Sophos Anti-Virus" ] && echo "- Sophos Anti-Virus detected"
        [ -d "/Library/Application Support/Malwarebytes" ] && echo "- Malwarebytes detected"
        [ -d "/Applications/1Password.app" ] && echo "- 1Password detected"
        [ -d "/Applications/Bitwarden.app" ] && echo "- Bitwarden detected"
        [ -d "/Applications/Little Snitch.app" ] && echo "- Little Snitch detected"
        [ -d "/Applications/Lulu.app" ] && echo "- Lulu detected"
        [ -d "/Applications/Oversight.app" ] && echo "- Oversight detected"
        echo ""

        echo "==============================================================================="
        echo "KERNEL EXTENSIONS"
        echo "==============================================================================="
        echo ""

        echo "[Third-Party Kernel Extensions]"
        kextstat 2>/dev/null | grep -v com.apple | grep -v "Kext" || echo "None found"
        echo ""

        echo "==============================================================================="
        echo "END OF REPORT"
        echo "==============================================================================="

    } > "$output_file"

    echo "Audit report saved to: $output_file"
}

#===============================================================================
# CIS BENCHMARK CHECK
#===============================================================================

check_cis_benchmark() {
    echo "CIS Benchmark compliance check..."
    echo ""

    local passed=0
    local failed=0
    local skipped=0

    # CIS 1.1 - Install Updates
    echo "[CIS 1.1] Verify all Apple provided software is current"
    local updates=$(softwareupdate -l 2>&1)
    if [[ "$updates" == *"No new software available"* ]]; then
        echo "  PASS: System is up to date"
        ((passed++))
    else
        echo "  FAIL: Updates available"
        ((failed++))
    fi

    # CIS 1.2 - Enable Auto Update
    echo "[CIS 1.2] Enable Auto Update"
    local auto_check=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled 2>/dev/null || echo "0")
    if [ "$auto_check" = "1" ]; then
        echo "  PASS: Auto update check enabled"
        ((passed++))
    else
        echo "  FAIL: Auto update check disabled"
        ((failed++))
    fi

    # CIS 2.1 - Bluetooth
    echo "[CIS 2.1] Turn off Bluetooth if not needed"
    local bt=$(defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState 2>/dev/null || echo "1")
    if [ "$bt" = "0" ]; then
        echo "  PASS: Bluetooth disabled"
        ((passed++))
    else
        echo "  INFO: Bluetooth enabled (check if needed)"
        ((skipped++))
    fi

    # CIS 2.4 - Screen Sharing
    echo "[CIS 2.4] Disable Screen Sharing"
    local ss=$(launchctl list 2>/dev/null | grep -c "screensharing")
    if [ "$ss" = "0" ]; then
        echo "  PASS: Screen Sharing disabled"
        ((passed++))
    else
        echo "  FAIL: Screen Sharing enabled"
        ((failed++))
    fi

    # CIS 2.5 - File Sharing
    echo "[CIS 2.5] Disable File Sharing"
    local fs=$(launchctl list 2>/dev/null | grep -c "smbd")
    if [ "$fs" = "0" ]; then
        echo "  PASS: File Sharing disabled"
        ((passed++))
    else
        echo "  FAIL: File Sharing enabled"
        ((failed++))
    fi

    # CIS 2.7 - Remote Login
    echo "[CIS 2.7] Disable Remote Login"
    local ssh_status=$(systemsetup -getremotelogin 2>/dev/null | grep -o "On\\|Off")
    if [ "$ssh_status" = "Off" ]; then
        echo "  PASS: Remote Login (SSH) disabled"
        ((passed++))
    else
        echo "  FAIL: Remote Login (SSH) enabled"
        ((failed++))
    fi

    # CIS 3.1 - FileVault
    echo "[CIS 3.1] Enable FileVault"
    local fv=$(fdesetup status 2>/dev/null)
    if [[ "$fv" == *"FileVault is On"* ]]; then
        echo "  PASS: FileVault enabled"
        ((passed++))
    else
        echo "  FAIL: FileVault not enabled"
        ((failed++))
    fi

    # CIS 3.3 - Gatekeeper
    echo "[CIS 3.3] Enable Gatekeeper"
    local gk=$(spctl --status 2>/dev/null)
    if [[ "$gk" == *"enabled"* ]]; then
        echo "  PASS: Gatekeeper enabled"
        ((passed++))
    else
        echo "  FAIL: Gatekeeper disabled"
        ((failed++))
    fi

    # CIS 3.4 - Firewall
    echo "[CIS 3.4] Enable Firewall"
    local fw=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -o "enabled\\|disabled")
    if [ "$fw" = "enabled" ]; then
        echo "  PASS: Firewall enabled"
        ((passed++))
    else
        echo "  FAIL: Firewall disabled"
        ((failed++))
    fi

    # CIS 5.1.1 - Secure Screensaver
    echo "[CIS 5.1.1] Require password to wake from sleep"
    local pw=$(defaults read com.apple.screensaver askForPassword 2>/dev/null || echo "0")
    if [ "$pw" = "1" ]; then
        echo "  PASS: Password required after sleep"
        ((passed++))
    else
        echo "  FAIL: Password not required after sleep"
        ((failed++))
    fi

    # CIS 6.1.3 - Guest Account
    echo "[CIS 6.1.3] Disable Guest Account"
    local guest=$(defaults read /Library/Preferences/com.apple.loginwindow GuestEnabled 2>/dev/null || echo "0")
    if [ "$guest" = "0" ]; then
        echo "  PASS: Guest account disabled"
        ((passed++))
    else
        echo "  FAIL: Guest account enabled"
        ((failed++))
    fi

    # Summary
    echo ""
    echo "==============================================================================="
    echo "CIS Benchmark Summary"
    echo "==============================================================================="
    echo "Passed:  $passed"
    echo "Failed:  $failed"
    echo "Skipped: $skipped"
    local total=$((passed + failed))
    if [ "$total" -gt 0 ]; then
        local score=$((passed * 100 / total))
        echo "Score:   ${score}%"
    fi
}

#===============================================================================
# QUICK SECURITY CHECK
#===============================================================================

quick_check() {
    echo -e "${BOLD}Quick Security Check${NC}"
    echo "===================="
    echo ""

    # Critical checks only
    local issues=0

    # FileVault
    local fv=$(fdesetup status 2>/dev/null)
    if [[ "$fv" == *"FileVault is On"* ]]; then
        echo -e "${GREEN}${CHECK}${NC} FileVault: Enabled"
    else
        echo -e "${RED}${CROSS}${NC} FileVault: DISABLED"
        ((issues++))
    fi

    # SIP
    local sip=$(csrutil status 2>/dev/null)
    if [[ "$sip" == *"enabled"* ]]; then
        echo -e "${GREEN}${CHECK}${NC} SIP: Enabled"
    else
        echo -e "${RED}${CROSS}${NC} SIP: DISABLED"
        ((issues++))
    fi

    # Gatekeeper
    local gk=$(spctl --status 2>/dev/null)
    if [[ "$gk" == *"enabled"* ]]; then
        echo -e "${GREEN}${CHECK}${NC} Gatekeeper: Enabled"
    else
        echo -e "${RED}${CROSS}${NC} Gatekeeper: DISABLED"
        ((issues++))
    fi

    # Firewall
    local fw=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -o "enabled\\|disabled")
    if [ "$fw" = "enabled" ]; then
        echo -e "${GREEN}${CHECK}${NC} Firewall: Enabled"
    else
        echo -e "${RED}${CROSS}${NC} Firewall: DISABLED"
        ((issues++))
    fi

    # Password on wake
    local pw=$(defaults read com.apple.screensaver askForPassword 2>/dev/null || echo "0")
    if [ "$pw" = "1" ]; then
        echo -e "${GREEN}${CHECK}${NC} Password on wake: Enabled"
    else
        echo -e "${RED}${CROSS}${NC} Password on wake: DISABLED"
        ((issues++))
    fi

    echo ""
    if [ "$issues" -eq 0 ]; then
        echo -e "${GREEN}All critical security features enabled!${NC}"
    else
        echo -e "${RED}$issues critical issues found!${NC}"
        echo "Run './main.sh' to fix them."
    fi
}

#===============================================================================
# MAIN
#===============================================================================

case "${1:-quick}" in
    quick)
        quick_check
        ;;
    full)
        generate_audit_report "$2"
        ;;
    cis)
        check_cis_benchmark
        ;;
    *)
        echo "Usage: $0 [quick|full|cis] [output_file]"
        echo ""
        echo "  quick  - Quick security check (default)"
        echo "  full   - Generate full audit report"
        echo "  cis    - CIS Benchmark compliance check"
        ;;
esac
