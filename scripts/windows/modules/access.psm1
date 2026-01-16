#===============================================================================
# FK94 Security - Windows Hardening
# Module: Access Control
#
# Covers: User accounts, Guest, Password policies, Auto-login
#===============================================================================

function Invoke-AccessModule {
    param(
        [string]$Profile = "recommended",
        [bool]$AuditOnly = $false,
        [bool]$DryRun = $false
    )

    Write-Header "ACCESS CONTROL"

    Test-GuestAccount -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
    Test-AutoLogin -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
    Test-PasswordPolicy -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
    Test-LockScreen -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
    Test-AdminAccount -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
}

#===============================================================================
# GUEST ACCOUNT
#===============================================================================

function Test-GuestAccount {
    param(
        [string]$Profile,
        [bool]$AuditOnly,
        [bool]$DryRun
    )

    Write-SubHeader "Guest Account"

    try {
        $guest = Get-LocalUser -Name "Guest" -ErrorAction Stop

        if (-not $guest.Enabled) {
            Write-Success "Guest account is disabled"
            Add-Check $true
        } else {
            Write-Fail "Guest account is ENABLED"
            Write-Info "Risk: Provides unauthenticated access to the system"
            Add-Check $false

            if (-not $AuditOnly) {
                if (Request-Confirmation "Disable Guest account?") {
                    Invoke-SecurityCommand "Disable-LocalUser -Name 'Guest'" "Guest account disabled" -DryRun $DryRun
                }
            }
        }
    } catch {
        Write-Success "Guest account not found"
        Add-Check $true
    }
}

#===============================================================================
# AUTO-LOGIN
#===============================================================================

function Test-AutoLogin {
    param(
        [string]$Profile,
        [bool]$AuditOnly,
        [bool]$DryRun
    )

    Write-SubHeader "Auto-Login"

    $winlogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    $autoLogin = Get-RegistryValue -Path $winlogonPath -Name "AutoAdminLogon" -Default "0"
    $defaultUser = Get-RegistryValue -Path $winlogonPath -Name "DefaultUserName" -Default ""

    if ($autoLogin -eq "1" -and $defaultUser) {
        Write-Fail "Auto-login is ENABLED for: $defaultUser"
        Write-Info "Risk: Anyone can access this PC without password"
        Add-Check $false

        if (-not $AuditOnly) {
            if (Request-Confirmation "Disable auto-login?") {
                Set-RegistryValue -Path $winlogonPath -Name "AutoAdminLogon" -Value "0" -Type String -DryRun $DryRun
                # Also remove stored password
                Invoke-SecurityCommand "Remove-ItemProperty -Path '$winlogonPath' -Name 'DefaultPassword' -ErrorAction SilentlyContinue" "Auto-login disabled" -DryRun $DryRun
            }
        }
    } else {
        Write-Success "Auto-login is disabled"
        Add-Check $true
    }
}

#===============================================================================
# PASSWORD POLICY
#===============================================================================

function Test-PasswordPolicy {
    param(
        [string]$Profile,
        [bool]$AuditOnly,
        [bool]$DryRun
    )

    Write-SubHeader "Password Policy"

    try {
        # Export security policy
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile 2>$null | Out-Null

        $policy = Get-Content $tempFile -Raw

        # Minimum password length
        if ($policy -match "MinimumPasswordLength\s*=\s*(\d+)") {
            $minLength = [int]$Matches[1]
            if ($minLength -ge 12) {
                Write-Success "Minimum password length: $minLength characters"
                Add-Check $true
            } elseif ($minLength -ge 8) {
                Write-Warning "Minimum password length: $minLength characters (recommend 12+)"
                Add-Check $false
            } else {
                Write-Fail "Minimum password length: $minLength characters (too short)"
                Add-Check $false
            }
        }

        # Password complexity
        if ($policy -match "PasswordComplexity\s*=\s*(\d+)") {
            $complexity = [int]$Matches[1]
            if ($complexity -eq 1) {
                Write-Success "Password complexity is enabled"
                Add-Check $true
            } else {
                Write-Warning "Password complexity is disabled"
                Add-Check $false
            }
        }

        # Password history
        if ($policy -match "PasswordHistorySize\s*=\s*(\d+)") {
            $history = [int]$Matches[1]
            if ($history -ge 5) {
                Write-Success "Password history: $history passwords remembered"
                Add-Check $true
            } else {
                Write-Info "Password history: $history passwords"
            }
        }

        # Account lockout
        if ($policy -match "LockoutBadCount\s*=\s*(\d+)") {
            $lockout = [int]$Matches[1]
            if ($lockout -gt 0 -and $lockout -le 10) {
                Write-Success "Account lockout after $lockout failed attempts"
                Add-Check $true
            } elseif ($lockout -eq 0) {
                Write-Warning "Account lockout is disabled"
                Add-Check $false
            }
        }

        Remove-Item $tempFile -Force
    } catch {
        Write-Warning "Could not check password policy"
        Write-Info "Run 'secpol.msc' to review password policies manually"
    }
}

#===============================================================================
# LOCK SCREEN
#===============================================================================

function Test-LockScreen {
    param(
        [string]$Profile,
        [bool]$AuditOnly,
        [bool]$DryRun
    )

    Write-SubHeader "Lock Screen"

    # Check screen saver timeout and password
    $ssPath = "HKCU:\Control Panel\Desktop"

    $ssTimeout = Get-RegistryValue -Path $ssPath -Name "ScreenSaveTimeOut" -Default "0"
    $ssActive = Get-RegistryValue -Path $ssPath -Name "ScreenSaveActive" -Default "0"
    $ssSecure = Get-RegistryValue -Path $ssPath -Name "ScreenSaverIsSecure" -Default "0"

    if ($ssActive -eq "1" -and $ssSecure -eq "1") {
        Write-Success "Screen saver with password protection is enabled"

        $timeout = [int]$ssTimeout
        if ($timeout -gt 0 -and $timeout -le 900) {
            Write-Success "Screen saver timeout: $([math]::Floor($timeout/60)) minutes"
            Add-Check $true
        } elseif ($timeout -gt 900) {
            Write-Warning "Screen saver timeout: $([math]::Floor($timeout/60)) minutes (recommend 15 or less)"
            Add-Check $false
        }
    } else {
        Write-Warning "Screen saver password protection is not configured"
        Add-Check $false

        if (-not $AuditOnly) {
            Write-Info "Configure via Settings > Personalization > Lock screen"
        }
    }

    # Check require sign-in after sleep
    $powerPath = "HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51"

    try {
        $signInRequired = Get-RegistryValue -Path $powerPath -Name "ACSettingIndex" -Default -1

        if ($signInRequired -eq 1) {
            Write-Success "Sign-in required after sleep"
            Add-Check $true
        } else {
            Write-Info "Configure sign-in after sleep in Settings > Accounts > Sign-in options"
        }
    } catch {
        # Check won't fail if key doesn't exist
    }
}

#===============================================================================
# ADMINISTRATOR ACCOUNT
#===============================================================================

function Test-AdminAccount {
    param(
        [string]$Profile,
        [bool]$AuditOnly,
        [bool]$DryRun
    )

    Write-SubHeader "Administrator Account"

    # Check if built-in Administrator is disabled
    try {
        $admin = Get-LocalUser -Name "Administrator" -ErrorAction Stop

        if (-not $admin.Enabled) {
            Write-Success "Built-in Administrator account is disabled"
            Add-Check $true
        } else {
            Write-Warning "Built-in Administrator account is enabled"
            Write-Info "Risk: Target for brute force attacks"
            Add-Check $false

            if ($Profile -eq "paranoid" -and -not $AuditOnly) {
                if (Request-Confirmation "Disable built-in Administrator account?") {
                    Invoke-SecurityCommand "Disable-LocalUser -Name 'Administrator'" "Administrator disabled" -DryRun $DryRun
                }
            }
        }
    } catch {
        Write-Success "Built-in Administrator not found or inaccessible"
        Add-Check $true
    }

    # Check for renamed Administrator
    try {
        $admins = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop

        $adminCount = ($admins | Measure-Object).Count
        Write-Info "$adminCount users/groups in Administrators group"

        if ($adminCount -gt 3) {
            Write-Warning "Consider reducing number of administrator accounts"
        }
    } catch {
        Write-Warning "Could not enumerate Administrators group"
    }

    # Check for credential guard (paranoid)
    if ($Profile -eq "paranoid") {
        $cgPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
        $cgEnabled = Get-RegistryValue -Path $cgPath -Name "EnableVirtualizationBasedSecurity" -Default 0

        if ($cgEnabled -eq 1) {
            Write-Success "Credential Guard is enabled"
            Add-Check $true
        } else {
            Write-Warning "Credential Guard is not enabled"
            Write-Info "Credential Guard protects against pass-the-hash attacks"
            Add-Check $false
        }
    }
}

Export-ModuleMember -Function Invoke-AccessModule
