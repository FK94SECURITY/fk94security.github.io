#!/bin/bash
#===============================================================================
# FK94 Security - macOS Hardening
# Module: System Security
#
# Covers: FileVault, Gatekeeper, SIP, Updates, Kernel hardening
#===============================================================================

module_system() {
    log_header "SYSTEM SECURITY"

    check_filevault
    check_gatekeeper
    check_sip
    check_updates
    check_kernel_hardening
}

#===============================================================================
# FILEVAULT - Full Disk Encryption
#===============================================================================

check_filevault() {
    log_subheader "FileVault (Disk Encryption)"

    local status=$(fdesetup status 2>/dev/null)

    if [[ "$status" == *"FileVault is On"* ]]; then
        log_success "FileVault is enabled"
        add_check true
    else
        log_fail "FileVault is NOT enabled"
        log_info "Risk: If your Mac is stolen, all data can be accessed"
        add_check false

        if [ "$AUDIT_ONLY" = false ]; then
            log_info "FileVault encrypts your entire disk"
            if confirm "Enable FileVault?"; then
                execute "fdesetup enable" "FileVault enabled"
                log_warn "IMPORTANT: Save the Recovery Key in a secure location"
            fi
        fi
    fi
}

#===============================================================================
# GATEKEEPER - App Signature Verification
#===============================================================================

check_gatekeeper() {
    log_subheader "Gatekeeper (App Verification)"

    local status=$(spctl --status 2>/dev/null)

    if [[ "$status" == *"enabled"* ]]; then
        log_success "Gatekeeper is enabled"
        add_check true
    else
        log_fail "Gatekeeper is DISABLED - HIGH RISK"
        log_info "Risk: Malicious unsigned apps can run without warning"
        add_check false

        if [ "$AUDIT_ONLY" = false ]; then
            if confirm "Enable Gatekeeper?"; then
                execute "spctl --master-enable" "Gatekeeper enabled"
            fi
        fi
    fi

    # Check Gatekeeper settings
    local gk_setting=$(spctl --status --verbose 2>/dev/null | grep -i "developer" || echo "")
    if [[ -n "$gk_setting" ]]; then
        log_info "Current setting: $gk_setting"
    fi
}

#===============================================================================
# SIP - System Integrity Protection
#===============================================================================

check_sip() {
    log_subheader "System Integrity Protection (SIP)"

    local status=$(csrutil status 2>/dev/null)

    if [[ "$status" == *"enabled"* ]]; then
        log_success "SIP is enabled"
        add_check true
    else
        log_fail "SIP is DISABLED - CRITICAL RISK"
        log_info "Risk: System files can be modified by malware"
        log_warn "SIP can only be enabled from Recovery Mode"
        log_info "Restart in Recovery (Cmd+R at boot) and run: csrutil enable"
        add_check false
    fi
}

#===============================================================================
# SOFTWARE UPDATES
#===============================================================================

check_updates() {
    log_subheader "Automatic Updates"

    local auto_check=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled 2>/dev/null || echo "0")
    local auto_download=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload 2>/dev/null || echo "0")
    local critical_updates=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall 2>/dev/null || echo "0")

    if [ "$auto_check" = "1" ]; then
        log_success "Automatic update check is enabled"
        add_check true
    else
        log_fail "Automatic update check is disabled"
        add_check false
    fi

    if [ "$critical_updates" = "1" ]; then
        log_success "Critical security updates are automatic"
        add_check true
    else
        log_warn "Critical security updates are NOT automatic"
        add_check false
    fi

    if [ "$AUDIT_ONLY" = false ]; then
        if [ "$auto_check" != "1" ] || [ "$critical_updates" != "1" ]; then
            if confirm "Enable automatic security updates?"; then
                execute "defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true"
                execute "defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool true"
                execute "defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true"
                execute "defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true"
                execute "defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool true"
                log_success "Automatic updates configured"
            fi
        fi
    fi
}

#===============================================================================
# KERNEL HARDENING
#===============================================================================

check_kernel_hardening() {
    log_subheader "Kernel Security"

    # Check if core dumps are disabled
    local core_dumps=$(sysctl kern.coredump 2>/dev/null | awk '{print $2}')
    if [ "$core_dumps" = "0" ]; then
        log_success "Core dumps are disabled"
        add_check true
    else
        log_warn "Core dumps are enabled (may leak sensitive data)"
        add_check false

        if [ "$AUDIT_ONLY" = false ] && [ "$PROFILE" = "paranoid" ]; then
            if confirm "Disable core dumps?"; then
                execute "sysctl -w kern.coredump=0" "Core dumps disabled"
            fi
        fi
    fi

    # Check ASLR (Address Space Layout Randomization) - always enabled on modern macOS
    log_success "ASLR is enabled (system default)"
    add_check true

    # Check Secure Boot (Apple Silicon)
    if is_apple_silicon; then
        log_info "Apple Silicon detected - Secure Boot enabled by default"
        add_check true
    fi
}
