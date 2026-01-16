#===============================================================================
# FK94 Security - Windows Hardening
# Module: System Security
#
# Covers: Windows Defender, BitLocker, UAC, Updates, Secure Boot
#===============================================================================

function Invoke-SystemModule {
    param(
        [string]$Profile = "recommended",
        [bool]$AuditOnly = $false,
        [bool]$DryRun = $false
    )

    Write-Header "SYSTEM SECURITY"

    Test-WindowsDefender -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
    Test-BitLocker -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
    Test-UAC -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
    Test-WindowsUpdates -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
    Test-SecureBoot -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
}

#===============================================================================
# WINDOWS DEFENDER
#===============================================================================

function Test-WindowsDefender {
    param(
        [string]$Profile,
        [bool]$AuditOnly,
        [bool]$DryRun
    )

    Write-SubHeader "Windows Defender"

    try {
        $defenderStatus = Get-MpComputerStatus -ErrorAction Stop

        # Real-time protection
        if ($defenderStatus.RealTimeProtectionEnabled) {
            Write-Success "Real-time protection is enabled"
            Add-Check $true
        } else {
            Write-Fail "Real-time protection is DISABLED"
            Add-Check $false

            if (-not $AuditOnly) {
                if (Request-Confirmation "Enable real-time protection?") {
                    Invoke-SecurityCommand "Set-MpPreference -DisableRealtimeMonitoring `$false" "Real-time protection enabled" -DryRun $DryRun
                }
            }
        }

        # Cloud protection
        if ($defenderStatus.MAPSReporting -ne 0) {
            Write-Success "Cloud-delivered protection is enabled"
            Add-Check $true
        } else {
            Write-Warning "Cloud-delivered protection is disabled"
            Add-Check $false
        }

        # Behavior monitoring
        if ($defenderStatus.BehaviorMonitorEnabled) {
            Write-Success "Behavior monitoring is enabled"
            Add-Check $true
        } else {
            Write-Warning "Behavior monitoring is disabled"
            Add-Check $false

            if (-not $AuditOnly -and $Profile -ne "basic") {
                Invoke-SecurityCommand "Set-MpPreference -DisableBehaviorMonitoring `$false" "Behavior monitoring enabled" -DryRun $DryRun
            }
        }

        # Signature age
        $sigAge = (Get-Date) - $defenderStatus.AntivirusSignatureLastUpdated
        if ($sigAge.Days -le 7) {
            Write-Success "Virus definitions are current ($($sigAge.Days) days old)"
            Add-Check $true
        } else {
            Write-Warning "Virus definitions are $($sigAge.Days) days old"
            Add-Check $false
        }

        # Tamper protection
        if ($defenderStatus.TamperProtectionSource -eq "ATP") {
            Write-Success "Tamper protection is enabled"
            Add-Check $true
        } else {
            Write-Info "Tamper protection status: $($defenderStatus.TamperProtectionSource)"
        }

    } catch {
        Write-Warning "Could not check Windows Defender status"
        Write-Info "Windows Defender may not be installed or accessible"
    }
}

#===============================================================================
# BITLOCKER
#===============================================================================

function Test-BitLocker {
    param(
        [string]$Profile,
        [bool]$AuditOnly,
        [bool]$DryRun
    )

    Write-SubHeader "BitLocker (Disk Encryption)"

    try {
        $systemDrive = $env:SystemDrive
        $bitlocker = Get-BitLockerVolume -MountPoint $systemDrive -ErrorAction Stop

        if ($bitlocker.ProtectionStatus -eq "On") {
            Write-Success "BitLocker is enabled on $systemDrive"
            Write-Info "Encryption: $($bitlocker.EncryptionPercentage)% complete"
            Add-Check $true
        } elseif ($bitlocker.VolumeStatus -eq "EncryptionInProgress") {
            Write-Warning "BitLocker encryption in progress ($($bitlocker.EncryptionPercentage)%)"
            Add-Check $true
        } else {
            Write-Fail "BitLocker is NOT enabled on $systemDrive"
            Write-Info "Risk: Data can be accessed if device is stolen"
            Add-Check $false

            if (-not $AuditOnly -and $Profile -ne "basic") {
                Write-Info "BitLocker requires TPM and admin privileges to enable"
                Write-Info "Enable via: Control Panel > BitLocker Drive Encryption"
            }
        }

        # Check for recovery key backup
        $keyProtectors = $bitlocker.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }
        if ($keyProtectors) {
            Write-Success "Recovery key is configured"
        } else {
            Write-Warning "No recovery key found - backup recommended"
        }

    } catch {
        Write-Warning "Could not check BitLocker status"
        Write-Info "BitLocker may not be available on this Windows edition"
    }
}

#===============================================================================
# UAC (User Account Control)
#===============================================================================

function Test-UAC {
    param(
        [string]$Profile,
        [bool]$AuditOnly,
        [bool]$DryRun
    )

    Write-SubHeader "User Account Control (UAC)"

    $uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

    # Check if UAC is enabled
    $enableLUA = Get-RegistryValue -Path $uacPath -Name "EnableLUA" -Default 0

    if ($enableLUA -eq 1) {
        Write-Success "UAC is enabled"
        Add-Check $true
    } else {
        Write-Fail "UAC is DISABLED - CRITICAL RISK"
        Write-Info "Risk: Malware can run with admin privileges without prompt"
        Add-Check $false

        if (-not $AuditOnly) {
            if (Request-Confirmation "Enable UAC?") {
                Set-RegistryValue -Path $uacPath -Name "EnableLUA" -Value 1 -DryRun $DryRun
                Write-Warning "Restart required for UAC changes"
            }
        }
    }

    # Check UAC level
    $consentPrompt = Get-RegistryValue -Path $uacPath -Name "ConsentPromptBehaviorAdmin" -Default 5
    $secureDesktop = Get-RegistryValue -Path $uacPath -Name "PromptOnSecureDesktop" -Default 1

    $targetLevel = Get-ProfileValue -Key "uac_level" -Profile $Profile -Default "default"

    if ($secureDesktop -eq 1 -and $consentPrompt -eq 2) {
        Write-Success "UAC set to maximum (always notify)"
        Add-Check $true
    } elseif ($secureDesktop -eq 1 -and $consentPrompt -eq 5) {
        Write-Success "UAC set to default level"
        Add-Check $true

        if ($targetLevel -eq "always" -and -not $AuditOnly) {
            if (Request-Confirmation "Increase UAC to maximum?") {
                Set-RegistryValue -Path $uacPath -Name "ConsentPromptBehaviorAdmin" -Value 2 -DryRun $DryRun
            }
        }
    } else {
        Write-Warning "UAC is set to a lower security level"
        Add-Check $false
    }

    # Admin Approval Mode
    $adminApproval = Get-RegistryValue -Path $uacPath -Name "FilterAdministratorToken" -Default 0

    if ($Profile -eq "paranoid") {
        if ($adminApproval -eq 1) {
            Write-Success "Admin Approval Mode is enabled"
            Add-Check $true
        } else {
            Write-Warning "Admin Approval Mode for built-in Administrator is disabled"
            Add-Check $false

            if (-not $AuditOnly) {
                Set-RegistryValue -Path $uacPath -Name "FilterAdministratorToken" -Value 1 -DryRun $DryRun
            }
        }
    }
}

#===============================================================================
# WINDOWS UPDATES
#===============================================================================

function Test-WindowsUpdates {
    param(
        [string]$Profile,
        [bool]$AuditOnly,
        [bool]$DryRun
    )

    Write-SubHeader "Windows Updates"

    # Check for pending updates
    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $pendingUpdates = $updateSearcher.Search("IsInstalled=0").Updates

        if ($pendingUpdates.Count -eq 0) {
            Write-Success "No pending updates"
            Add-Check $true
        } else {
            Write-Warning "$($pendingUpdates.Count) updates pending"

            # Check for critical updates
            $critical = $pendingUpdates | Where-Object { $_.MsrcSeverity -eq "Critical" }
            if ($critical) {
                Write-Fail "$($critical.Count) CRITICAL updates pending"
                Add-Check $false
            } else {
                Add-Check $false
            }
        }
    } catch {
        Write-Info "Could not check for pending updates"
    }

    # Check automatic updates setting
    $auPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"
    $auEnabled = Get-RegistryValue -Path $auPath -Name "AUOptions" -Default 0

    if ($auEnabled -ge 3) {
        Write-Success "Automatic updates are enabled"
        Add-Check $true
    } else {
        Write-Warning "Automatic updates may be disabled"
        Add-Check $false
    }

    # Check last update time
    $lastUpdate = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1
    if ($lastUpdate) {
        $daysSince = ((Get-Date) - $lastUpdate.InstalledOn).Days
        if ($daysSince -le 30) {
            Write-Success "System was updated $daysSince days ago"
        } else {
            Write-Warning "Last update was $daysSince days ago"
        }
    }
}

#===============================================================================
# SECURE BOOT
#===============================================================================

function Test-SecureBoot {
    param(
        [string]$Profile,
        [bool]$AuditOnly,
        [bool]$DryRun
    )

    Write-SubHeader "Secure Boot"

    try {
        $secureBoot = Confirm-SecureBootUEFI -ErrorAction Stop

        if ($secureBoot) {
            Write-Success "Secure Boot is enabled"
            Add-Check $true
        } else {
            Write-Fail "Secure Boot is DISABLED"
            Write-Info "Risk: Bootkit malware can load before Windows"
            Write-Info "Enable in BIOS/UEFI settings"
            Add-Check $false
        }
    } catch {
        Write-Info "Could not determine Secure Boot status"
        Write-Info "System may be using legacy BIOS"
    }

    # Check UEFI mode
    try {
        $firmware = Get-ItemPropertyValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State" -Name "UEFISecureBootEnabled" -ErrorAction Stop
        if ($firmware -eq 1) {
            Write-Success "UEFI mode with Secure Boot"
        }
    } catch {
        Write-Info "Running in legacy BIOS mode"
    }
}

Export-ModuleMember -Function Invoke-SystemModule
