#!/bin/bash
#===============================================================================
# FK94 Security - macOS Hardening
# Module: Access Control
#
# Covers: Lock screen, Password policies, Login settings, Guest account
#===============================================================================

module_access() {
    log_header "ACCESS CONTROL"

    check_lock_screen
    check_login_settings
    check_guest_account
    check_sudo_config
}

#===============================================================================
# LOCK SCREEN
#===============================================================================

check_lock_screen() {
    log_subheader "Lock Screen"

    # Password after sleep
    local ask_password=$(defaults read com.apple.screensaver askForPassword 2>/dev/null || echo "0")
    local ask_delay=$(defaults read com.apple.screensaver askForPasswordDelay 2>/dev/null || echo "999")

    if [ "$ask_password" = "1" ] && [ "$ask_delay" = "0" ]; then
        log_success "Password required immediately after sleep"
        add_check true
    elif [ "$ask_password" = "1" ]; then
        log_warn "Password required but with ${ask_delay}s delay"
        add_check false

        if [ "$AUDIT_ONLY" = false ]; then
            if confirm "Set password to require immediately?"; then
                execute "defaults write com.apple.screensaver askForPasswordDelay -int 0" "Password delay set to 0"
            fi
        fi
    else
        log_fail "Password NOT required after sleep - HIGH RISK"
        log_info "Risk: Anyone can access your Mac when it wakes up"
        add_check false

        if [ "$AUDIT_ONLY" = false ]; then
            if confirm "Require password immediately after sleep?"; then
                execute "defaults write com.apple.screensaver askForPassword -int 1"
                execute "defaults write com.apple.screensaver askForPasswordDelay -int 0"
                log_success "Password required immediately"
            fi
        fi
    fi

    # Screen saver timeout
    local ss_timeout=$(defaults -currentHost read com.apple.screensaver idleTime 2>/dev/null || echo "0")
    if [ "$ss_timeout" -gt 0 ] && [ "$ss_timeout" -le 300 ]; then
        log_success "Screen saver activates after ${ss_timeout}s"
        add_check true
    elif [ "$ss_timeout" -gt 300 ]; then
        log_warn "Screen saver timeout is ${ss_timeout}s (recommended: 300s or less)"
        add_check false
    else
        log_warn "Screen saver may not be configured"
        add_check false
    fi

    # Lock screen message (for lost Mac)
    if [ "$PROFILE" = "paranoid" ] || [ "$PROFILE" = "recommended" ]; then
        local lock_msg=$(defaults read /Library/Preferences/com.apple.loginwindow LoginwindowText 2>/dev/null || echo "")
        if [ -n "$lock_msg" ]; then
            log_success "Lock screen message is set"
        else
            log_info "Consider adding contact info to lock screen"

            if [ "$AUDIT_ONLY" = false ]; then
                read -p "$(echo -e "  ${YELLOW}Enter lock screen message (or leave empty):${NC} ")" new_msg
                if [ -n "$new_msg" ]; then
                    execute "defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText '$new_msg'" "Lock message set"
                fi
            fi
        fi
    fi
}

#===============================================================================
# LOGIN SETTINGS
#===============================================================================

check_login_settings() {
    log_subheader "Login Settings"

    # Auto-login
    local auto_login=$(defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || echo "")
    if [ -z "$auto_login" ]; then
        log_success "Auto-login is disabled"
        add_check true
    else
        log_fail "Auto-login is enabled for: $auto_login"
        log_info "Risk: Anyone can access this Mac without password"
        add_check false

        if [ "$AUDIT_ONLY" = false ]; then
            if confirm "Disable auto-login?"; then
                execute "defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || true" "Auto-login disabled"
            fi
        fi
    fi

    # Show password hints
    local show_hints=$(defaults read /Library/Preferences/com.apple.loginwindow RetriesUntilHint 2>/dev/null || echo "3")
    if [ "$show_hints" = "0" ]; then
        log_success "Password hints are disabled"
        add_check true
    else
        log_warn "Password hints may be shown after $show_hints attempts"
        add_check false

        if [ "$AUDIT_ONLY" = false ] && [ "$PROFILE" != "basic" ]; then
            if confirm "Disable password hints?"; then
                execute "defaults write /Library/Preferences/com.apple.loginwindow RetriesUntilHint -int 0" "Password hints disabled"
            fi
        fi
    fi

    # Show user list at login
    local show_users=$(defaults read /Library/Preferences/com.apple.loginwindow SHOWFULLNAME 2>/dev/null || echo "0")
    if [ "$show_users" = "1" ]; then
        log_success "Login shows name+password fields (not user list)"
        add_check true
    else
        log_info "Login shows list of users (attackers can see usernames)"

        if [ "$AUDIT_ONLY" = false ] && [ "$PROFILE" = "paranoid" ]; then
            if confirm "Hide user list at login? (Show name+password fields instead)"; then
                execute "defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true" "User list hidden"
            fi
        fi
    fi
}

#===============================================================================
# GUEST ACCOUNT
#===============================================================================

check_guest_account() {
    log_subheader "Guest Account"

    local guest_enabled=$(defaults read /Library/Preferences/com.apple.loginwindow GuestEnabled 2>/dev/null || echo "0")

    if [ "$guest_enabled" = "0" ]; then
        log_success "Guest account is disabled"
        add_check true
    else
        log_warn "Guest account is enabled"
        log_info "Risk: Provides access without credentials"
        add_check false

        if [ "$AUDIT_ONLY" = false ]; then
            if confirm "Disable guest account?"; then
                execute "defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false" "Guest account disabled"
            fi
        fi
    fi
}

#===============================================================================
# SUDO CONFIGURATION
#===============================================================================

check_sudo_config() {
    log_subheader "Sudo Security"

    # Check sudo timeout
    local sudo_timeout=$(sudo -n cat /etc/sudoers 2>/dev/null | grep "timestamp_timeout" | awk -F= '{print $2}' || echo "default")

    if [ "$sudo_timeout" = "0" ]; then
        log_success "Sudo requires password every time"
        add_check true
    else
        log_info "Sudo caches credentials (default behavior)"

        if [ "$PROFILE" = "paranoid" ] && [ "$AUDIT_ONLY" = false ]; then
            log_info "Paranoid profile recommends requiring sudo password every time"
            log_warn "This requires modifying /etc/sudoers (advanced)"
        fi
    fi

    # Check if touch ID is enabled for sudo
    if [ -f /etc/pam.d/sudo_local ]; then
        if grep -q "pam_tid.so" /etc/pam.d/sudo_local 2>/dev/null; then
            log_success "Touch ID for sudo is enabled"
        fi
    else
        log_info "Touch ID for sudo is not configured"
        log_info "Can be enabled by creating /etc/pam.d/sudo_local"
    fi
}
