<#
.SYNOPSIS
    FK94 Security - Windows Hardening Tool

.DESCRIPTION
    Comprehensive Windows security hardening toolkit based on CIS Benchmarks
    and industry best practices.

.PARAMETER Profile
    Security profile to use: basic, recommended (default), paranoid

.PARAMETER AuditOnly
    Check security without making any changes

.PARAMETER DryRun
    Preview changes without applying them

.PARAMETER Modules
    Run specific modules (comma-separated): system, network, access, privacy

.PARAMETER Quiet
    Minimal output (errors and summary only)

.EXAMPLE
    .\main.ps1
    Run with default (recommended) profile

.EXAMPLE
    .\main.ps1 -Profile paranoid
    Run with maximum security settings

.EXAMPLE
    .\main.ps1 -AuditOnly
    Audit only, no changes made

.EXAMPLE
    .\main.ps1 -DryRun -Profile paranoid
    Preview paranoid settings without applying

.LINK
    https://fk94security.com

.NOTES
    Version: 2.0.0
    Author: FK94 Security
#>

[CmdletBinding()]
param(
    [ValidateSet("basic", "recommended", "paranoid")]
    [string]$Profile = "recommended",

    [switch]$AuditOnly,

    [switch]$DryRun,

    [string]$Modules = "",

    [switch]$Quiet,

    [switch]$Help,

    [switch]$Version
)

#===============================================================================
# INITIALIZATION
#===============================================================================

$ErrorActionPreference = "Continue"
$Script:Version = "2.0.0"
$Script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import modules
Import-Module "$Script:ScriptPath\utils\helpers.psm1" -Force
Import-Module "$Script:ScriptPath\modules\system.psm1" -Force
Import-Module "$Script:ScriptPath\modules\network.psm1" -Force
Import-Module "$Script:ScriptPath\modules\access.psm1" -Force
Import-Module "$Script:ScriptPath\modules\privacy.psm1" -Force

#===============================================================================
# HELP & VERSION
#===============================================================================

if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    exit 0
}

if ($Version) {
    Write-Host "FK94 Security Windows Hardening Tool v$Script:Version"
    Write-Host "https://fk94security.com"
    exit 0
}

#===============================================================================
# BANNER
#===============================================================================

function Show-Banner {
    if ($Quiet) { return }

    Clear-Host
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                                                                           ║" -ForegroundColor Cyan
    Write-Host "  ║   ███████╗██╗  ██╗ █████╗ ██╗  ██╗    ███████╗███████╗ ██████╗           ║" -ForegroundColor Cyan
    Write-Host "  ║   ██╔════╝██║ ██╔╝██╔══██╗██║  ██║    ██╔════╝██╔════╝██╔════╝           ║" -ForegroundColor Cyan
    Write-Host "  ║   █████╗  █████╔╝ ╚██████║███████║    ███████╗█████╗  ██║                ║" -ForegroundColor Cyan
    Write-Host "  ║   ██╔══╝  ██╔═██╗  ╚═══██║╚════██║    ╚════██║██╔══╝  ██║                ║" -ForegroundColor Cyan
    Write-Host "  ║   ██║     ██║  ██╗ █████╔╝     ██║    ███████║███████╗╚██████╗           ║" -ForegroundColor Cyan
    Write-Host "  ║   ╚═╝     ╚═╝  ╚═╝ ╚════╝      ╚═╝    ╚══════╝╚══════╝ ╚═════╝           ║" -ForegroundColor Cyan
    Write-Host "  ║                                                                           ║" -ForegroundColor Cyan
    Write-Host "  ║                   Windows Security Hardening Tool                         ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Version $Script:Version | https://fk94security.com" -ForegroundColor DarkGray
    Write-Host ""
}

#===============================================================================
# PREFLIGHT CHECKS
#===============================================================================

function Test-Preflight {
    # Check Windows version
    $osInfo = Get-WindowsVersion
    $build = [int]$osInfo.Build

    if ($build -lt 17763) {
        Write-Warning "This script is optimized for Windows 10 1809+ / Windows 11"
        Write-Warning "Some features may not work on older versions"
    }

    # Check admin privileges
    if (-not (Test-IsAdmin)) {
        Write-Host ""
        Write-Host "  [!] This script requires Administrator privileges" -ForegroundColor Red
        Write-Host "  [!] Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Red
        Write-Host ""
        exit 1
    }

    # Check execution policy
    $execPolicy = Get-ExecutionPolicy
    if ($execPolicy -eq "Restricted") {
        Write-Warning "Execution policy is 'Restricted'"
        Write-Host "  Run: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
    }
}

#===============================================================================
# SHOW CONFIGURATION
#===============================================================================

function Show-Configuration {
    if ($Quiet) { return }

    $profileColor = switch ($Profile) {
        "basic"       { "Green" }
        "recommended" { "Yellow" }
        "paranoid"    { "Red" }
    }

    Write-Host "  Configuration:" -ForegroundColor White
    Write-Host "  ├─ Profile:    " -NoNewline
    Write-Host $Profile -ForegroundColor $profileColor

    if ($AuditOnly) {
        Write-Host "  ├─ Mode:       " -NoNewline
        Write-Host "Audit Only" -ForegroundColor Cyan
        Write-Host " (no changes will be made)" -ForegroundColor DarkGray
    } elseif ($DryRun) {
        Write-Host "  ├─ Mode:       " -NoNewline
        Write-Host "Dry Run" -ForegroundColor Cyan
        Write-Host " (preview changes)" -ForegroundColor DarkGray
    } else {
        Write-Host "  ├─ Mode:       " -NoNewline
        Write-Host "Apply Changes" -ForegroundColor Green
    }

    if ($Modules) {
        Write-Host "  └─ Modules:    $Modules"
    } else {
        Write-Host "  └─ Modules:    all"
    }

    Write-Host ""

    # Confirmation for non-audit modes
    if (-not $AuditOnly -and -not $DryRun) {
        Write-Host "  This will modify system settings." -ForegroundColor Yellow
        $confirm = Read-Host "  Continue? (y/n)"
        if ($confirm -notmatch "^[yY]") {
            Write-Host ""
            Write-Host "  Cancelled by user" -ForegroundColor DarkGray
            exit 0
        }
    }

    Write-Host ""
}

#===============================================================================
# RUN MODULES
#===============================================================================

function Invoke-Modules {
    $modulesToRun = if ($Modules) { $Modules -split "," } else { @("system", "network", "access", "privacy") }

    foreach ($module in $modulesToRun) {
        $module = $module.Trim()

        switch ($module) {
            "system" {
                Invoke-SystemModule -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
            }
            "network" {
                Invoke-NetworkModule -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
            }
            "access" {
                Invoke-AccessModule -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
            }
            "privacy" {
                Invoke-PrivacyModule -Profile $Profile -AuditOnly $AuditOnly -DryRun $DryRun
            }
            default {
                Write-Warning "Unknown module: $module (skipping)"
            }
        }
    }
}

#===============================================================================
# SHOW SUMMARY
#===============================================================================

function Show-Summary {
    Write-Host ""
    Write-Header "SECURITY SUMMARY"

    $passed = Get-ChecksPassed
    $failed = Get-ChecksFailed
    $total = $passed + $failed

    $score = if ($total -gt 0) { [math]::Floor(($passed * 100) / $total) } else { 0 }

    $scoreColor = switch ($true) {
        ($score -ge 80) { "Green" }
        ($score -ge 60) { "Yellow" }
        default { "Red" }
    }

    Write-Host ""
    Write-Host "  Results:" -ForegroundColor White
    Write-Host "  ├─ " -NoNewline
    Write-Host "$([char]0x2713) Passed:  $passed" -ForegroundColor Green
    Write-Host "  ├─ " -NoNewline
    Write-Host "$([char]0x2717) Failed:  $failed" -ForegroundColor Red
    Write-Host "  └─ " -NoNewline
    Write-Host "Score:    " -NoNewline
    Write-Host "$score%" -ForegroundColor $scoreColor

    Write-Host ""

    # Visual score bar
    $barLength = 40
    $filled = [math]::Floor($score * $barLength / 100)
    $empty = $barLength - $filled

    Write-Host "  [" -NoNewline
    Write-Host ("█" * $filled) -NoNewline -ForegroundColor $scoreColor
    Write-Host ("░" * $empty) -NoNewline -ForegroundColor DarkGray
    Write-Host "] " -NoNewline
    Write-Host "$score%" -ForegroundColor $scoreColor

    Write-Host ""

    # Recommendations
    switch ($true) {
        ($score -ge 90) {
            Write-Host "  Excellent! Your system is well secured." -ForegroundColor Green
        }
        ($score -ge 70) {
            Write-Host "  Good. Consider addressing the warnings above." -ForegroundColor Yellow
        }
        ($score -ge 50) {
            Write-Host "  Fair. Several security improvements recommended." -ForegroundColor Yellow
        }
        default {
            Write-Host "  Needs attention. Multiple security issues found." -ForegroundColor Red
        }
    }

    Write-Host ""

    if ($AuditOnly) {
        Write-Host "  Run without -AuditOnly to apply fixes" -ForegroundColor DarkGray
    } elseif ($DryRun) {
        Write-Host "  Run without -DryRun to apply changes" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  Report generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
    Write-Host "  FK94 Security | https://fk94security.com" -ForegroundColor DarkGray
    Write-Host ""
}

#===============================================================================
# MAIN
#===============================================================================

function Main {
    Show-Banner
    Test-Preflight
    Show-Configuration
    Reset-Checks
    Invoke-Modules
    Show-Summary
}

# Run
Main
