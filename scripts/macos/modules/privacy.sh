#!/bin/bash
#===============================================================================
# FK94 Security - macOS Hardening
# Module: Privacy & Data Protection
#
# Covers: Telemetry, Analytics, Siri, Safari, Finder, Location
#===============================================================================

module_privacy() {
    log_header "PRIVACY & DATA PROTECTION"

    check_analytics
    check_siri
    check_safari
    check_finder
    check_spotlight
}

#===============================================================================
# ANALYTICS & TELEMETRY
#===============================================================================

check_analytics() {
    log_subheader "Analytics & Telemetry"

    # Apple Analytics
    local diag_enabled=$(defaults read /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit 2>/dev/null || echo "1")
    if [ "$diag_enabled" = "0" ]; then
        log_success "Apple diagnostics sharing is disabled"
        add_check true
    else
        log_warn "Apple diagnostics sharing is enabled"
        add_check false

        if [ "$AUDIT_ONLY" = false ]; then
            if confirm "Disable Apple diagnostics sharing?"; then
                execute "defaults write /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit -bool false" "Diagnostics disabled"
            fi
        fi
    fi

    # Ad tracking
    local ad_tracking=$(defaults read com.apple.AdLib allowApplePersonalizedAdvertising 2>/dev/null || echo "1")
    if [ "$ad_tracking" = "0" ]; then
        log_success "Personalized ads are disabled"
        add_check true
    else
        log_warn "Personalized ads are enabled"
        add_check false

        if [ "$AUDIT_ONLY" = false ]; then
            if confirm "Disable personalized advertising?"; then
                execute "defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false" "Personalized ads disabled"
            fi
        fi
    fi

    # Siri analytics
    local siri_analytics=$(defaults read com.apple.assistant.support "Siri Data Sharing Opt-In Status" 2>/dev/null || echo "1")
    if [ "$siri_analytics" = "2" ]; then
        log_success "Siri analytics is disabled"
        add_check true
    else
        log_warn "Siri analytics is enabled"
        add_check false

        if [ "$AUDIT_ONLY" = false ]; then
            if confirm "Disable Siri analytics?"; then
                execute "defaults write com.apple.assistant.support 'Siri Data Sharing Opt-In Status' -int 2" "Siri analytics disabled"
            fi
        fi
    fi
}

#===============================================================================
# SIRI
#===============================================================================

check_siri() {
    log_subheader "Siri"

    local disable_siri=$(get_profile_value "disable_siri" "false")

    if [ "$disable_siri" = "true" ]; then
        local siri_enabled=$(defaults read com.apple.assistant.support "Assistant Enabled" 2>/dev/null || echo "1")
        if [ "$siri_enabled" = "0" ]; then
            log_success "Siri is disabled"
            add_check true
        else
            log_warn "Siri is enabled (profile recommends disabling)"
            add_check false

            if [ "$AUDIT_ONLY" = false ]; then
                if confirm "Disable Siri?"; then
                    execute "defaults write com.apple.assistant.support 'Assistant Enabled' -bool false" "Siri disabled"
                fi
            fi
        fi
    else
        log_info "Siri check skipped (allowed per profile)"
    fi
}

#===============================================================================
# SAFARI HARDENING
#===============================================================================

check_safari() {
    log_subheader "Safari Privacy"

    local hardening_level=$(get_profile_value "safari_hardening" "moderate")

    # Show full URL
    local show_full_url=$(defaults read com.apple.Safari ShowFullURLInSmartSearchField 2>/dev/null || echo "0")
    if [ "$show_full_url" = "1" ]; then
        log_success "Safari shows full URL"
        add_check true
    else
        log_info "Safari truncates URL (phishing risk)"

        if [ "$AUDIT_ONLY" = false ]; then
            execute "defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true" "Full URL enabled"
        fi
    fi

    # Fraudulent website warning
    local fraud_warning=$(defaults read com.apple.Safari WarnAboutFraudulentWebsites 2>/dev/null || echo "0")
    if [ "$fraud_warning" = "1" ]; then
        log_success "Fraudulent website warnings enabled"
        add_check true
    else
        log_warn "Fraudulent website warnings disabled"
        add_check false

        if [ "$AUDIT_ONLY" = false ]; then
            execute "defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true" "Fraud warnings enabled"
        fi
    fi

    # Search suggestions
    if [ "$hardening_level" != "minimal" ]; then
        local search_sugg=$(defaults read com.apple.Safari SuppressSearchSuggestions 2>/dev/null || echo "0")
        if [ "$search_sugg" = "1" ]; then
            log_success "Search suggestions disabled"
            add_check true
        else
            log_info "Search suggestions enabled (queries sent to Apple)"

            if [ "$AUDIT_ONLY" = false ] && [ "$hardening_level" = "strict" ]; then
                if confirm "Disable Safari search suggestions?"; then
                    execute "defaults write com.apple.Safari SuppressSearchSuggestions -bool true"
                    execute "defaults write com.apple.Safari UniversalSearchEnabled -bool false"
                    log_success "Search suggestions disabled"
                fi
            fi
        fi
    fi

    # AutoFill (strict mode only)
    if [ "$hardening_level" = "strict" ]; then
        log_info "Checking AutoFill settings (strict mode)..."

        local autofill_cc=$(defaults read com.apple.Safari AutoFillCreditCardData 2>/dev/null || echo "1")
        if [ "$autofill_cc" = "0" ]; then
            log_success "Credit card autofill is disabled"
        else
            log_warn "Credit card autofill is enabled"

            if [ "$AUDIT_ONLY" = false ]; then
                if confirm "Disable credit card autofill?"; then
                    execute "defaults write com.apple.Safari AutoFillCreditCardData -bool false" "CC autofill disabled"
                fi
            fi
        fi
    fi

    # Pop-ups
    local popups=$(defaults read com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically 2>/dev/null || echo "1")
    if [ "$popups" = "0" ]; then
        log_success "Pop-ups are blocked"
        add_check true
    else
        log_info "Pop-ups are allowed"

        if [ "$AUDIT_ONLY" = false ]; then
            execute "defaults write com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically -bool false" "Pop-ups blocked"
        fi
    fi
}

#===============================================================================
# FINDER
#===============================================================================

check_finder() {
    log_subheader "Finder Security"

    # Show file extensions
    local show_ext=$(defaults read NSGlobalDomain AppleShowAllExtensions 2>/dev/null || echo "0")
    if [ "$show_ext" = "1" ]; then
        log_success "File extensions are visible"
        add_check true
    else
        log_warn "File extensions are hidden (malware disguise risk)"
        add_check false

        if [ "$AUDIT_ONLY" = false ]; then
            if confirm "Show all file extensions?"; then
                execute "defaults write NSGlobalDomain AppleShowAllExtensions -bool true" "File extensions visible"
            fi
        fi
    fi

    # Extension change warning
    local ext_warning=$(defaults read com.apple.finder FXEnableExtensionChangeWarning 2>/dev/null || echo "0")
    if [ "$ext_warning" = "1" ]; then
        log_success "Extension change warning is enabled"
        add_check true
    else
        log_info "Extension change warning is disabled"

        if [ "$AUDIT_ONLY" = false ]; then
            execute "defaults write com.apple.finder FXEnableExtensionChangeWarning -bool true" "Extension warning enabled"
        fi
    fi

    # Disable .DS_Store on network drives
    local ds_network=$(defaults read com.apple.desktopservices DSDontWriteNetworkStores 2>/dev/null || echo "0")
    if [ "$ds_network" = "1" ]; then
        log_success ".DS_Store disabled on network drives"
        add_check true
    else
        log_info ".DS_Store created on network drives"

        if [ "$AUDIT_ONLY" = false ]; then
            execute "defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true" ".DS_Store network disabled"
        fi
    fi
}

#===============================================================================
# SPOTLIGHT
#===============================================================================

check_spotlight() {
    log_subheader "Spotlight Privacy"

    local disable_spotlight_sugg=$(get_profile_value "disable_spotlight_suggestions" "false")

    if [ "$disable_spotlight_sugg" = "true" ]; then
        local spotlight_sugg=$(defaults read com.apple.lookup.shared LookupSuggestionsDisabled 2>/dev/null || echo "0")
        if [ "$spotlight_sugg" = "1" ]; then
            log_success "Spotlight suggestions are disabled"
            add_check true
        else
            log_warn "Spotlight sends queries to Apple"

            if [ "$AUDIT_ONLY" = false ]; then
                if confirm "Disable Spotlight suggestions?"; then
                    execute "defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true" "Spotlight suggestions disabled"
                fi
            fi
        fi
    else
        log_info "Spotlight suggestions check skipped (allowed per profile)"
    fi
}
