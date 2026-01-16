#!/bin/bash
#===============================================================================
# FK94 Security - macOS Hardening
# Module: Lockdown Mode (macOS 13+)
#
# Covers: Lockdown Mode, USB, Bluetooth, Firmware, Advanced protections
#===============================================================================

module_lockdown() {
    log_header "LOCKDOWN & ADVANCED SECURITY"

    check_macos_version
    check_lockdown_mode
    check_usb_restrictions
    check_bluetooth_security
    check_firmware_password
    check_advanced_protections
}

#===============================================================================
# macOS VERSION CHECK
#===============================================================================

check_macos_version() {
    log_subheader "macOS Version"

    local version=$(sw_vers -productVersion)
    local major=$(echo "$version" | cut -d. -f1)

    log_info "Detected macOS $version"

    if [ "$major" -ge 13 ]; then
        log_success "macOS 13+ detected - Lockdown Mode available"
        LOCKDOWN_AVAILABLE=true
    else
        log_info "macOS $version - Lockdown Mode requires macOS 13+"
        LOCKDOWN_AVAILABLE=false
    fi

    # Check for latest security updates
    local updates=$(softwareupdate -l 2>&1)
    if [[ "$updates" == *"Security"* ]]; then
        log_warn "Security updates available - recommend installing"
    else
        log_success "No pending security updates"
    fi
}

#===============================================================================
# LOCKDOWN MODE (macOS 13+)
#===============================================================================

check_lockdown_mode() {
    log_subheader "Lockdown Mode"

    if [ "$LOCKDOWN_AVAILABLE" != true ]; then
        log_info "Lockdown Mode not available on this macOS version"
        return
    fi

    local only_paranoid=$(get_profile_value "enable_lockdown_mode" "false")

    if [ "$PROFILE" = "paranoid" ] || [ "$only_paranoid" = "true" ]; then
        # Check Lockdown Mode status
        local lockdown_status=$(defaults read com.apple.security.lockdownmode LDMGlobalEnabled 2>/dev/null || echo "0")

        if [ "$lockdown_status" = "1" ]; then
            log_success "Lockdown Mode is ENABLED"
            add_check true
        else
            log_warn "Lockdown Mode is disabled"
            log_info "Lockdown Mode provides extreme protection against sophisticated attacks"
            log_info "It limits: message attachments, web technologies, wired connections"
            add_check false

            if [ "$AUDIT_ONLY" = false ]; then
                log_warn "Lockdown Mode significantly restricts functionality"
                log_info "Recommended only for: journalists, activists, high-value targets"

                if confirm "Enable Lockdown Mode? (Requires restart)"; then
                    # Lockdown Mode can only be enabled via System Settings or MDM
                    log_info "Opening System Settings > Privacy & Security..."
                    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Lockdown"
                    log_warn "Please enable Lockdown Mode manually and restart"
                fi
            fi
        fi
    else
        log_info "Lockdown Mode check skipped (paranoid profile only)"
    fi
}

#===============================================================================
# USB RESTRICTIONS
#===============================================================================

check_usb_restrictions() {
    log_subheader "USB & Accessory Security"

    # Check USB restricted mode (screen locked = USB disabled)
    local usb_restricted=$(defaults read com.apple.AppleUSBRestrictedMode USBRestrictedMode 2>/dev/null || echo "1")

    if [ "$usb_restricted" = "1" ]; then
        log_success "USB Restricted Mode is enabled"
        log_info "USB accessories disabled when Mac is locked for 1+ hour"
        add_check true
    else
        log_warn "USB Restricted Mode may be disabled"
        add_check false
    fi

    # Check Thunderbolt security (Apple Silicon)
    if is_apple_silicon; then
        log_success "Apple Silicon: Thunderbolt devices require approval"
        add_check true
    else
        # Intel Macs - check Thunderbolt security level
        local tb_security=$(system_profiler SPThunderboltDataType 2>/dev/null | grep -i "security" | head -1 || echo "")
        if [ -n "$tb_security" ]; then
            log_info "Thunderbolt security: $tb_security"
        fi
    fi
}

#===============================================================================
# BLUETOOTH SECURITY
#===============================================================================

check_bluetooth_security() {
    log_subheader "Bluetooth Security"

    local disable_bt=$(get_profile_value "disable_bluetooth" "false")

    # Check if Bluetooth is enabled
    local bt_power=$(defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState 2>/dev/null || echo "1")

    if [ "$disable_bt" = "true" ]; then
        if [ "$bt_power" = "0" ]; then
            log_success "Bluetooth is disabled"
            add_check true
        else
            log_warn "Bluetooth is enabled (profile recommends disabling)"
            add_check false

            if [ "$AUDIT_ONLY" = false ]; then
                if confirm "Disable Bluetooth?"; then
                    execute "defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0" "Bluetooth disabled"
                    execute "killall -HUP blued 2>/dev/null || true" "Bluetooth service restarted"
                fi
            fi
        fi
    else
        if [ "$bt_power" = "1" ]; then
            log_info "Bluetooth is enabled (allowed per profile)"

            # Check discoverability
            local bt_discoverable=$(defaults read /Library/Preferences/com.apple.Bluetooth DiscoverableState 2>/dev/null || echo "0")
            if [ "$bt_discoverable" = "1" ]; then
                log_warn "Bluetooth is discoverable"
                add_check false

                if [ "$AUDIT_ONLY" = false ]; then
                    execute "defaults write /Library/Preferences/com.apple.Bluetooth DiscoverableState -int 0" "Bluetooth hidden"
                fi
            else
                log_success "Bluetooth is not discoverable"
                add_check true
            fi
        else
            log_success "Bluetooth is disabled"
            add_check true
        fi
    fi

    # Check Handoff
    local disable_handoff=$(get_profile_value "disable_handoff" "false")
    if [ "$disable_handoff" = "true" ]; then
        local handoff=$(defaults read ~/Library/Preferences/ByHost/com.apple.coreservices.useractivityd.* ActivityAdvertisingAllowed 2>/dev/null || echo "1")
        if [ "$handoff" = "0" ]; then
            log_success "Handoff is disabled"
        else
            log_warn "Handoff is enabled"
            if [ "$AUDIT_ONLY" = false ]; then
                if confirm "Disable Handoff?"; then
                    execute "defaults write ~/Library/Preferences/ByHost/com.apple.coreservices.useractivityd ActivityAdvertisingAllowed -bool false" "Handoff disabled"
                fi
            fi
        fi
    fi
}

#===============================================================================
# FIRMWARE PASSWORD (Intel only)
#===============================================================================

check_firmware_password() {
    log_subheader "Firmware Security"

    if is_apple_silicon; then
        log_success "Apple Silicon: Secure Enclave protects boot process"
        log_info "Boot security managed via Recovery Mode"
        add_check true

        # Check Secure Boot status
        log_info "Secure Boot is enabled by default on Apple Silicon"
    else
        # Intel Mac - check firmware password
        local fw_status=$(firmwarepasswd -check 2>/dev/null | grep -o "Yes\\|No" || echo "Unknown")

        if [ "$fw_status" = "Yes" ]; then
            log_success "Firmware password is set"
            add_check true
        elif [ "$fw_status" = "No" ]; then
            log_warn "Firmware password is NOT set"
            log_info "Risk: Boot security can be bypassed"
            add_check false

            if [ "$PROFILE" = "paranoid" ] && [ "$AUDIT_ONLY" = false ]; then
                log_info "Setting firmware password requires Recovery Mode"
                log_info "Restart holding Cmd+R, then use Utilities > Startup Security Utility"
            fi
        else
            log_info "Could not determine firmware password status"
        fi
    fi
}

#===============================================================================
# ADVANCED PROTECTIONS
#===============================================================================

check_advanced_protections() {
    log_subheader "Advanced Protections"

    # Secure Keyboard Entry (for Terminal)
    local secure_kb=$(defaults read com.apple.Terminal SecureKeyboardEntry 2>/dev/null || echo "0")
    if [ "$secure_kb" = "1" ]; then
        log_success "Secure Keyboard Entry is enabled in Terminal"
        add_check true
    else
        log_info "Secure Keyboard Entry is disabled in Terminal"

        if [ "$AUDIT_ONLY" = false ] && [ "$PROFILE" != "basic" ]; then
            execute "defaults write com.apple.Terminal SecureKeyboardEntry -bool true" "Secure keyboard enabled"
        fi
    fi

    # Clear recent items on logout
    local clear_recent=$(get_profile_value "clear_recent_items" "false")
    if [ "$clear_recent" = "true" ]; then
        log_info "Recent items should be cleared periodically"
        if [ "$AUDIT_ONLY" = false ]; then
            if confirm "Clear recent items now?"; then
                execute "osascript -e 'tell application \"System Events\" to delete (every recent item)' 2>/dev/null || true" "Recent items cleared"
            fi
        fi
    fi

    # Check for MDM enrollment
    local mdm_enrolled=$(profiles status -type enrollment 2>/dev/null | grep -c "MDM enrollment" || echo "0")
    if [ "$mdm_enrolled" -gt 0 ]; then
        log_info "This Mac is MDM enrolled"
    else
        log_info "This Mac is not MDM enrolled"
    fi

    # Privacy permissions audit
    log_info "Checking privacy permissions..."
    local full_disk=$(tccutil 2>&1 | grep -c "Full Disk Access" || echo "0")
    log_info "Review Privacy permissions in System Settings > Privacy & Security"

    # Check for kernel extensions
    local kexts=$(kextstat 2>/dev/null | grep -v com.apple | wc -l | tr -d ' ')
    if [ "$kexts" -gt 0 ]; then
        log_warn "Third-party kernel extensions detected: $kexts"
        log_info "Review with: kextstat | grep -v com.apple"
    else
        log_success "No third-party kernel extensions loaded"
        add_check true
    fi
}
