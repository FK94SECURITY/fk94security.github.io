#===============================================================================
# FK94 Security - Windows Hardening
# Module: Privacy & Data Protection
#
# Covers: Telemetry, Cortana, Location, Advertising, App permissions
#===============================================================================

function Invoke-PrivacyModule {
    param(
        [string]$Profile = "recommended",
        [bool]$AuditOnly = $false,
        [bool]$DryRun = $false
    )

    Write-Header "PRIVACY & DATA PROTECTION"

    Test-Telemetry -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
    Test-Cortana -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
    Test-Advertising -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
    Test-Location -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
    Test-ActivityHistory -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
}

#===============================================================================
# TELEMETRY
#===============================================================================

function Test-Telemetry {
    param(
        [string]$Profile,
        [bool]$AuditOnly,
        [bool]$DryRun
    )

    Write-SubHeader "Windows Telemetry"

    $telemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    $telemetryLevel = Get-RegistryValue -Path $telemetryPath -Name "AllowTelemetry" -Default 3

    # Telemetry levels: 0=Security, 1=Basic, 2=Enhanced, 3=Full
    $levels = @{
        0 = "Security (Enterprise only)"
        1 = "Basic"
        2 = "Enhanced"
        3 = "Full"
    }

    $currentLevel = $levels[$telemetryLevel]
    Write-Info "Current telemetry level: $currentLevel"

    $shouldDisable = Get-ProfileValue -Key "disable_telemetry" -Profile $Profile -Default $false

    if ($telemetryLevel -le 1) {
        Write-Success "Telemetry is set to minimal ($currentLevel)"
        Add-Check $true
    } else {
        Write-Warning "Telemetry is set to $currentLevel"
        Add-Check $false

        if (-not $AuditOnly -and $shouldDisable) {
            if (Request-Confirmation "Reduce telemetry to Basic?") {
                Set-RegistryValue -Path $telemetryPath -Name "AllowTelemetry" -Value 1 -DryRun $DryRun
                Write-Success "Telemetry set to Basic"
            }
        }
    }

    # Disable telemetry services in paranoid mode
    if ($Profile -eq "paranoid") {
        $telemetryServices = @("DiagTrack", "dmwappushservice")

        foreach ($svcName in $telemetryServices) {
            try {
                $svc = Get-Service -Name $svcName -ErrorAction Stop

                if ($svc.Status -eq "Running") {
                    Write-Warning "$svcName service is running"
                    Add-Check $false

                    if (-not $AuditOnly) {
                        if (Request-Confirmation "Disable $svcName service?") {
                            Invoke-SecurityCommand "Stop-Service -Name $svcName -Force; Set-Service -Name $svcName -StartupType Disabled" "$svcName disabled" -DryRun $DryRun
                        }
                    }
                } else {
                    Write-Success "$svcName service is not running"
                    Add-Check $true
                }
            } catch {
                Write-Success "$svcName service not found"
            }
        }
    }

    # Check scheduled tasks for telemetry
    try {
        $tasks = Get-ScheduledTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\*" -ErrorAction SilentlyContinue

        if ($tasks) {
            $enabledTasks = $tasks | Where-Object { $_.State -eq "Ready" }
            if ($enabledTasks) {
                Write-Warning "CEIP scheduled tasks are enabled"
                Add-Check $false
            } else {
                Write-Success "CEIP scheduled tasks are disabled"
                Add-Check $true
            }
        }
    } catch {
        # Non-critical
    }
}

#===============================================================================
# CORTANA
#===============================================================================

function Test-Cortana {
    param(
        [string]$Profile,
        [bool]$AuditOnly,
        [bool]$DryRun
    )

    Write-SubHeader "Cortana"

    $shouldDisable = Get-ProfileValue -Key "disable_cortana" -Profile $Profile -Default $false

    # Windows 10
    $cortanaPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    $cortanaAllowed = Get-RegistryValue -Path $cortanaPath -Name "AllowCortana" -Default 1

    # Windows 11 (Cortana is less integrated)
    if (Test-IsWindows11) {
        Write-Info "Windows 11: Cortana is a separate app with limited integration"

        # Check if Cortana app is installed
        try {
            $cortanaApp = Get-AppxPackage -Name "Microsoft.549981C3F5F10" -ErrorAction Stop
            if ($cortanaApp) {
                Write-Info "Cortana app is installed"

                if ($shouldDisable -and -not $AuditOnly) {
                    if (Request-Confirmation "Remove Cortana app?") {
                        Invoke-SecurityCommand "Get-AppxPackage -Name 'Microsoft.549981C3F5F10' | Remove-AppxPackage" "Cortana removed" -DryRun $DryRun
                    }
                }
            }
        } catch {
            Write-Success "Cortana app is not installed"
            Add-Check $true
        }
    } else {
        # Windows 10
        if ($cortanaAllowed -eq 0) {
            Write-Success "Cortana is disabled"
            Add-Check $true
        } else {
            if ($shouldDisable) {
                Write-Warning "Cortana is enabled"
                Add-Check $false

                if (-not $AuditOnly) {
                    if (Request-Confirmation "Disable Cortana?") {
                        Set-RegistryValue -Path $cortanaPath -Name "AllowCortana" -Value 0 -DryRun $DryRun
                        Set-RegistryValue -Path $cortanaPath -Name "AllowSearchToUseLocation" -Value 0 -DryRun $DryRun
                        Write-Success "Cortana disabled"
                    }
                }
            } else {
                Write-Info "Cortana is enabled (allowed per profile)"
            }
        }
    }
}

#===============================================================================
# ADVERTISING ID
#===============================================================================

function Test-Advertising {
    param(
        [string]$Profile,
        [bool]$AuditOnly,
        [bool]$DryRun
    )

    Write-SubHeader "Advertising & Tracking"

    # Advertising ID
    $adPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    $adEnabled = Get-RegistryValue -Path $adPath -Name "Enabled" -Default 1

    if ($adEnabled -eq 0) {
        Write-Success "Advertising ID is disabled"
        Add-Check $true
    } else {
        Write-Warning "Advertising ID is enabled"
        Add-Check $false

        if (-not $AuditOnly) {
            if (Request-Confirmation "Disable Advertising ID?") {
                Set-RegistryValue -Path $adPath -Name "Enabled" -Value 0 -DryRun $DryRun
                Write-Success "Advertising ID disabled"
            }
        }
    }

    # Tailored experiences
    $tailoredPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy"
    $tailored = Get-RegistryValue -Path $tailoredPath -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Default 1

    if ($tailored -eq 0) {
        Write-Success "Tailored experiences are disabled"
        Add-Check $true
    } else {
        Write-Warning "Tailored experiences are enabled"
        Add-Check $false

        if (-not $AuditOnly) {
            Set-RegistryValue -Path $tailoredPath -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0 -DryRun $DryRun
        }
    }

    # Feedback frequency
    $feedbackPath = "HKCU:\SOFTWARE\Microsoft\Siuf\Rules"
    $feedback = Get-RegistryValue -Path $feedbackPath -Name "NumberOfSIUFInPeriod" -Default -1

    if ($feedback -eq 0) {
        Write-Success "Feedback requests are disabled"
        Add-Check $true
    } else {
        Write-Info "Consider disabling feedback prompts in Settings"
    }
}

#===============================================================================
# LOCATION
#===============================================================================

function Test-Location {
    param(
        [string]$Profile,
        [bool]$AuditOnly,
        [bool]$DryRun
    )

    Write-SubHeader "Location Services"

    $locationPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
    $locationValue = Get-RegistryValue -Path $locationPath -Name "Value" -Default "Allow"

    if ($locationValue -eq "Deny") {
        Write-Success "Location services are disabled system-wide"
        Add-Check $true
    } else {
        Write-Info "Location services are enabled"
        Write-Info "Manage per-app permissions in Settings > Privacy > Location"

        if ($Profile -eq "paranoid" -and -not $AuditOnly) {
            if (Request-Confirmation "Disable location services system-wide?") {
                Set-RegistryValue -Path $locationPath -Name "Value" -Value "Deny" -Type String -DryRun $DryRun
                Write-Success "Location services disabled"
            }
        }
    }

    # Check location history
    if ($Profile -ne "basic") {
        Write-Info "Review location history in Settings > Privacy > Location"
    }
}

#===============================================================================
# ACTIVITY HISTORY
#===============================================================================

function Test-ActivityHistory {
    param(
        [string]$Profile,
        [bool]$AuditOnly,
        [bool]$DryRun
    )

    Write-SubHeader "Activity History"

    $activityPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"

    # Publish user activities
    $publishActivities = Get-RegistryValue -Path $activityPath -Name "PublishUserActivities" -Default 1

    if ($publishActivities -eq 0) {
        Write-Success "Activity publishing to Microsoft is disabled"
        Add-Check $true
    } else {
        Write-Warning "Activity publishing to Microsoft is enabled"
        Add-Check $false

        if (-not $AuditOnly -and $Profile -ne "basic") {
            if (Request-Confirmation "Disable activity publishing?") {
                Set-RegistryValue -Path $activityPath -Name "PublishUserActivities" -Value 0 -DryRun $DryRun
            }
        }
    }

    # Upload user activities
    $uploadActivities = Get-RegistryValue -Path $activityPath -Name "UploadUserActivities" -Default 1

    if ($uploadActivities -eq 0) {
        Write-Success "Activity upload is disabled"
        Add-Check $true
    } else {
        Write-Warning "Activity upload is enabled"
        Add-Check $false

        if (-not $AuditOnly -and $Profile -ne "basic") {
            Set-RegistryValue -Path $activityPath -Name "UploadUserActivities" -Value 0 -DryRun $DryRun
        }
    }

    # Timeline (Windows 10)
    if (-not (Test-IsWindows11)) {
        $timelinePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        $timeline = Get-RegistryValue -Path $timelinePath -Name "EnableActivityFeed" -Default 1

        if ($timeline -eq 0) {
            Write-Success "Timeline is disabled"
            Add-Check $true
        } else {
            Write-Info "Timeline is enabled"

            if ($Profile -eq "paranoid" -and -not $AuditOnly) {
                Set-RegistryValue -Path $timelinePath -Name "EnableActivityFeed" -Value 0 -DryRun $DryRun
            }
        }
    }
}

Export-ModuleMember -Function Invoke-PrivacyModule
