#!/bin/bash
#===============================================================================
# FK94 Security - macOS Hardening
# Module: Network Security
#
# Covers: Firewall, Sharing services, Remote access, IPv6
#===============================================================================

module_network() {
    log_header "NETWORK SECURITY"

    check_firewall
    check_sharing_services
    check_remote_access
    check_ipv6
}

#===============================================================================
# FIREWALL
#===============================================================================

check_firewall() {
    log_subheader "Firewall"

    local fw_state=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -o "enabled\|disabled")
    local stealth=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode 2>/dev/null | grep -o "enabled\|disabled")
    local logging=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getloggingmode 2>/dev/null | grep -o "on\|off")

    # Firewall state
    if [ "$fw_state" = "enabled" ]; then
        log_success "Firewall is enabled"
        add_check true
    else
        log_fail "Firewall is DISABLED"
        log_info "Risk: Incoming connections are not filtered"
        add_check false

        if [ "$AUDIT_ONLY" = false ]; then
            if confirm "Enable firewall?"; then
                execute "/usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on" "Firewall enabled"
            fi
        fi
    fi

    # Stealth mode
    local want_stealth=$(get_profile_value "firewall_stealth" "true")
    if [ "$stealth" = "enabled" ]; then
        log_success "Stealth mode is enabled"
        add_check true
    else
        if [ "$want_stealth" = "true" ]; then
            log_warn "Stealth mode is disabled"
            log_info "Stealth mode hides your Mac from network scans"
            add_check false

            if [ "$AUDIT_ONLY" = false ]; then
                if confirm "Enable stealth mode?"; then
                    execute "/usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on" "Stealth mode enabled"
                fi
            fi
        else
            log_info "Stealth mode is disabled (OK for basic profile)"
            add_check true
        fi
    fi

    # Logging
    if [ "$logging" = "on" ]; then
        log_success "Firewall logging is enabled"
    else
        log_info "Firewall logging is disabled"
        if [ "$AUDIT_ONLY" = false ] && [ "$PROFILE" != "basic" ]; then
            execute "/usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode on" "Firewall logging enabled"
        fi
    fi

    # Block all incoming (paranoid only)
    if [ "$PROFILE" = "paranoid" ]; then
        local block_all=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getblockall 2>/dev/null | grep -o "enabled\|disabled")
        if [ "$block_all" = "enabled" ]; then
            log_success "Block all incoming connections is enabled"
            add_check true
        else
            log_warn "Block all incoming is disabled (paranoid profile recommends enabling)"
            add_check false

            if [ "$AUDIT_ONLY" = false ]; then
                if confirm "Block ALL incoming connections? (May break some apps)"; then
                    execute "/usr/libexec/ApplicationFirewall/socketfilterfw --setblockall on" "Block all enabled"
                fi
            fi
        fi
    fi
}

#===============================================================================
# SHARING SERVICES
#===============================================================================

check_sharing_services() {
    log_subheader "Sharing Services"

    local should_disable=$(get_profile_value "disable_sharing" "true")

    # Screen Sharing
    local screen_sharing=$(launchctl list 2>/dev/null | grep -c "com.apple.screensharing" || echo "0")
    if [ "$screen_sharing" = "0" ]; then
        log_success "Screen Sharing is disabled"
        add_check true
    else
        log_warn "Screen Sharing is enabled"
        add_check false

        if [ "$AUDIT_ONLY" = false ] && [ "$should_disable" = "true" ]; then
            if confirm "Disable Screen Sharing?"; then
                execute "launchctl disable system/com.apple.screensharing" "Screen Sharing disabled"
            fi
        fi
    fi

    # File Sharing
    local file_sharing=$(launchctl list 2>/dev/null | grep -c "com.apple.smbd" || echo "0")
    if [ "$file_sharing" = "0" ]; then
        log_success "File Sharing (SMB) is disabled"
        add_check true
    else
        log_warn "File Sharing (SMB) is enabled"
        add_check false
    fi

    # Printer Sharing
    local printer_sharing=$(cupsctl 2>/dev/null | grep -c "_share_printers=1" || echo "0")
    if [ "$printer_sharing" = "0" ]; then
        log_success "Printer Sharing is disabled"
        add_check true
    else
        log_warn "Printer Sharing is enabled"
        add_check false
    fi

    # AirDrop
    local disable_airdrop=$(get_profile_value "disable_airdrop" "false")
    if [ "$disable_airdrop" = "true" ]; then
        log_info "AirDrop should be disabled per profile"
        if [ "$AUDIT_ONLY" = false ]; then
            if confirm "Disable AirDrop?"; then
                execute "defaults write com.apple.NetworkBrowser DisableAirDrop -bool true" "AirDrop disabled"
            fi
        fi
    else
        log_info "AirDrop allowed per profile"
    fi

    # Bluetooth Sharing
    local bt_sharing=$(defaults -currentHost read com.apple.Bluetooth PrefKeyServicesEnabled 2>/dev/null || echo "0")
    if [ "$bt_sharing" = "0" ]; then
        log_success "Bluetooth Sharing is disabled"
        add_check true
    else
        log_warn "Bluetooth Sharing is enabled"
        add_check false

        if [ "$AUDIT_ONLY" = false ]; then
            execute "defaults -currentHost write com.apple.Bluetooth PrefKeyServicesEnabled -bool false" "Bluetooth Sharing disabled"
        fi
    fi
}

#===============================================================================
# REMOTE ACCESS
#===============================================================================

check_remote_access() {
    log_subheader "Remote Access"

    local should_disable_ssh=$(get_profile_value "disable_ssh" "true")

    # Remote Login (SSH)
    local ssh_status=$(systemsetup -getremotelogin 2>/dev/null | grep -o "On\|Off" || echo "Off")
    if [ "$ssh_status" = "Off" ]; then
        log_success "Remote Login (SSH) is disabled"
        add_check true
    else
        if [ "$should_disable_ssh" = "true" ]; then
            log_warn "Remote Login (SSH) is enabled"
            log_info "Risk: Attackers can attempt to brute force SSH"
            add_check false

            if [ "$AUDIT_ONLY" = false ]; then
                if confirm "Disable Remote Login (SSH)?"; then
                    execute "systemsetup -setremotelogin off" "SSH disabled"
                fi
            fi
        else
            log_info "SSH is enabled (allowed per profile)"
            add_check true
        fi
    fi

    # Remote Apple Events
    local rae_status=$(systemsetup -getremoteappleevents 2>/dev/null | grep -o "On\|Off" || echo "Off")
    if [ "$rae_status" = "Off" ]; then
        log_success "Remote Apple Events is disabled"
        add_check true
    else
        log_warn "Remote Apple Events is enabled"
        add_check false

        if [ "$AUDIT_ONLY" = false ]; then
            if confirm "Disable Remote Apple Events?"; then
                execute "systemsetup -setremoteappleevents off" "Remote Apple Events disabled"
            fi
        fi
    fi

    # Remote Management
    local ard_status=$(systemsetup -getremotemanagement 2>/dev/null | grep -o "On\|Off" || echo "Off")
    if [ "$ard_status" = "Off" ]; then
        log_success "Remote Management is disabled"
        add_check true
    else
        log_warn "Remote Management (ARD) is enabled"
        add_check false
    fi
}

#===============================================================================
# IPv6
#===============================================================================

check_ipv6() {
    log_subheader "IPv6 Configuration"

    local disable_ipv6=$(get_profile_value "disable_ipv6" "false")

    if [ "$disable_ipv6" = "true" ]; then
        # Get all network services
        local services=$(networksetup -listallnetworkservices 2>/dev/null | tail -n +2)

        while IFS= read -r service; do
            local ipv6_status=$(networksetup -getinfo "$service" 2>/dev/null | grep "IPv6:" | awk '{print $2}')
            if [ "$ipv6_status" = "Off" ]; then
                log_success "IPv6 disabled on: $service"
            else
                log_warn "IPv6 enabled on: $service"

                if [ "$AUDIT_ONLY" = false ]; then
                    if confirm "Disable IPv6 on $service?"; then
                        execute "networksetup -setv6off '$service'" "IPv6 disabled on $service"
                    fi
                fi
            fi
        done <<< "$services"
    else
        log_info "IPv6 check skipped (not required for this profile)"
    fi
}
