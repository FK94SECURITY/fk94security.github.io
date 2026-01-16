#===============================================================================
# FK94 Security - Windows Hardening
# Module: Network Security
#
# Covers: Firewall, Remote Desktop, SMB, Network Services
#===============================================================================

function Invoke-NetworkModule {
    param(
        [string]$Profile = "recommended",
        [bool]$AuditOnly = $false,
        [bool]$DryRun = $false
    )

    Write-Header "NETWORK SECURITY"

    Test-Firewall -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
    Test-RemoteDesktop -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
    Test-SMB -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
    Test-NetworkServices -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
}

#===============================================================================
# WINDOWS FIREWALL
#===============================================================================

function Test-Firewall {
    param(
        [string]$Profile,
        [bool]$AuditOnly,
        [bool]$DryRun
    )

    Write-SubHeader "Windows Firewall"

    $profiles = @("Domain", "Private", "Public")

    foreach ($fwProfile in $profiles) {
        try {
            $status = Get-NetFirewallProfile -Name $fwProfile -ErrorAction Stop

            if ($status.Enabled) {
                Write-Success "$fwProfile profile firewall is enabled"
                Add-Check $true
            } else {
                Write-Fail "$fwProfile profile firewall is DISABLED"
                Add-Check $false

                if (-not $AuditOnly) {
                    if (Request-Confirmation "Enable $fwProfile firewall?") {
                        Invoke-SecurityCommand "Set-NetFirewallProfile -Name $fwProfile -Enabled True" "$fwProfile firewall enabled" -DryRun $DryRun
                    }
                }
            }

            # Check default actions
            if ($status.DefaultInboundAction -eq "Block") {
                Write-Success "$fwProfile: Inbound connections blocked by default"
            } else {
                Write-Warning "$fwProfile: Inbound connections allowed by default"

                if (-not $AuditOnly -and $Profile -ne "basic") {
                    Invoke-SecurityCommand "Set-NetFirewallProfile -Name $fwProfile -DefaultInboundAction Block" "Inbound blocked" -DryRun $DryRun
                }
            }
        } catch {
            Write-Warning "Could not check $fwProfile firewall status"
        }
    }

    # Check for logging
    try {
        $logging = Get-NetFirewallProfile -Name Domain | Select-Object -ExpandProperty LogFileName
        if ($logging) {
            Write-Success "Firewall logging is configured"
        } else {
            Write-Info "Firewall logging may not be enabled"

            if (-not $AuditOnly -and $Profile -eq "paranoid") {
                Write-Info "Consider enabling firewall logging for security monitoring"
            }
        }
    } catch {
        # Logging check failed, non-critical
    }
}

#===============================================================================
# REMOTE DESKTOP
#===============================================================================

function Test-RemoteDesktop {
    param(
        [string]$Profile,
        [bool]$AuditOnly,
        [bool]$DryRun
    )

    Write-SubHeader "Remote Desktop"

    $rdpPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
    $rdpDisabled = Get-RegistryValue -Path $rdpPath -Name "fDenyTSConnections" -Default 0

    $shouldDisable = Get-ProfileValue -Key "disable_remote_desktop" -Profile $Profile -Default $false

    if ($rdpDisabled -eq 1) {
        Write-Success "Remote Desktop is disabled"
        Add-Check $true
    } else {
        if ($shouldDisable) {
            Write-Fail "Remote Desktop is ENABLED"
            Write-Info "Risk: Attackers can attempt to brute force RDP"
            Add-Check $false

            if (-not $AuditOnly) {
                if (Request-Confirmation "Disable Remote Desktop?") {
                    Set-RegistryValue -Path $rdpPath -Name "fDenyTSConnections" -Value 1 -DryRun $DryRun
                    Write-Success "Remote Desktop disabled"
                }
            }
        } else {
            Write-Info "Remote Desktop is enabled (allowed per profile)"

            # Check NLA requirement
            $nlaPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
            $nla = Get-RegistryValue -Path $nlaPath -Name "UserAuthentication" -Default 0

            if ($nla -eq 1) {
                Write-Success "Network Level Authentication (NLA) is required"
                Add-Check $true
            } else {
                Write-Warning "NLA is not required - security risk"
                Add-Check $false

                if (-not $AuditOnly) {
                    Set-RegistryValue -Path $nlaPath -Name "UserAuthentication" -Value 1 -DryRun $DryRun
                    Write-Success "NLA enabled"
                }
            }
        }
    }
}

#===============================================================================
# SMB (File Sharing)
#===============================================================================

function Test-SMB {
    param(
        [string]$Profile,
        [bool]$AuditOnly,
        [bool]$DryRun
    )

    Write-SubHeader "SMB (File Sharing)"

    # Check SMBv1 (should be disabled)
    try {
        $smb1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction Stop

        if ($smb1.State -eq "Disabled") {
            Write-Success "SMBv1 is disabled (good - vulnerable protocol)"
            Add-Check $true
        } else {
            Write-Fail "SMBv1 is ENABLED - SECURITY RISK"
            Write-Info "SMBv1 is vulnerable to WannaCry and other exploits"
            Add-Check $false

            if (-not $AuditOnly) {
                if (Request-Confirmation "Disable SMBv1?") {
                    Invoke-SecurityCommand "Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart" "SMBv1 disabled" -DryRun $DryRun
                    Write-Warning "Restart required to complete SMBv1 removal"
                }
            }
        }
    } catch {
        # Try alternative method
        try {
            $smb1Server = Get-SmbServerConfiguration | Select-Object -ExpandProperty EnableSMB1Protocol
            if (-not $smb1Server) {
                Write-Success "SMBv1 server is disabled"
                Add-Check $true
            } else {
                Write-Fail "SMBv1 server is enabled"
                Add-Check $false

                if (-not $AuditOnly) {
                    Invoke-SecurityCommand "Set-SmbServerConfiguration -EnableSMB1Protocol `$false -Force" "SMBv1 disabled" -DryRun $DryRun
                }
            }
        } catch {
            Write-Warning "Could not check SMBv1 status"
        }
    }

    # Check SMB signing
    try {
        $smbConfig = Get-SmbServerConfiguration

        if ($smbConfig.RequireSecuritySignature) {
            Write-Success "SMB signing is required"
            Add-Check $true
        } else {
            Write-Warning "SMB signing is not required"
            Add-Check $false

            if (-not $AuditOnly -and $Profile -ne "basic") {
                if (Request-Confirmation "Require SMB signing?") {
                    Invoke-SecurityCommand "Set-SmbServerConfiguration -RequireSecuritySignature `$true -Force" "SMB signing required" -DryRun $DryRun
                }
            }
        }

        # Check encryption (Windows 10+)
        if ($smbConfig.EncryptData) {
            Write-Success "SMB encryption is enabled"
            Add-Check $true
        } else {
            Write-Info "SMB encryption is not enabled"

            if (-not $AuditOnly -and $Profile -eq "paranoid") {
                if (Request-Confirmation "Enable SMB encryption?") {
                    Invoke-SecurityCommand "Set-SmbServerConfiguration -EncryptData `$true -Force" "SMB encryption enabled" -DryRun $DryRun
                }
            }
        }
    } catch {
        Write-Warning "Could not check SMB configuration"
    }
}

#===============================================================================
# NETWORK SERVICES
#===============================================================================

function Test-NetworkServices {
    param(
        [string]$Profile,
        [bool]$AuditOnly,
        [bool]$DryRun
    )

    Write-SubHeader "Network Services"

    # Check for unnecessary services
    $riskyServices = @(
        @{Name = "RemoteRegistry"; Desc = "Remote Registry"}
        @{Name = "Telnet"; Desc = "Telnet"}
        @{Name = "SNMP"; Desc = "SNMP Service"}
        @{Name = "SSDPSRV"; Desc = "SSDP Discovery"}
        @{Name = "upnphost"; Desc = "UPnP Device Host"}
    )

    foreach ($svc in $riskyServices) {
        try {
            $service = Get-Service -Name $svc.Name -ErrorAction Stop

            if ($service.Status -eq "Running") {
                Write-Warning "$($svc.Desc) is running"
                Add-Check $false

                if (-not $AuditOnly -and $Profile -ne "basic") {
                    if (Request-Confirmation "Stop and disable $($svc.Desc)?") {
                        Invoke-SecurityCommand "Stop-Service -Name $($svc.Name) -Force; Set-Service -Name $($svc.Name) -StartupType Disabled" "$($svc.Desc) disabled" -DryRun $DryRun
                    }
                }
            } elseif ($service.StartType -ne "Disabled") {
                Write-Info "$($svc.Desc) is stopped but not disabled"
            } else {
                Write-Success "$($svc.Desc) is disabled"
                Add-Check $true
            }
        } catch {
            Write-Success "$($svc.Desc) is not installed"
            Add-Check $true
        }
    }

    # Check Wi-Fi Sense (Windows 10)
    if (Test-IsWindows11 -eq $false) {
        $wifiSensePath = "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config"
        $wifiSense = Get-RegistryValue -Path $wifiSensePath -Name "AutoConnectAllowedOEM" -Default 0

        if ($wifiSense -eq 0) {
            Write-Success "Wi-Fi Sense is disabled"
            Add-Check $true
        } else {
            Write-Warning "Wi-Fi Sense is enabled"
            Add-Check $false

            if (-not $AuditOnly) {
                Set-RegistryValue -Path $wifiSensePath -Name "AutoConnectAllowedOEM" -Value 0 -DryRun $DryRun
            }
        }
    }

    # Check network location awareness
    Write-Info "Check network profiles via Control Panel > Network and Sharing Center"
}

Export-ModuleMember -Function Invoke-NetworkModule
