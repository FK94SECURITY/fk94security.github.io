#===============================================================================
# FK94 Security - Windows Hardening
# Utility Functions
#===============================================================================

# Colors
$Script:Colors = @{
    Green  = "Green"
    Red    = "Red"
    Yellow = "Yellow"
    Cyan   = "Cyan"
    White  = "White"
    Gray   = "DarkGray"
}

# Symbols
$Script:CHECK = [char]0x2713
$Script:CROSS = [char]0x2717
$Script:WARN  = "!"
$Script:INFO  = "i"

# Counters
$Script:ChecksPassed = 0
$Script:ChecksFailed = 0

#===============================================================================
# LOGGING FUNCTIONS
#===============================================================================

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "=" -NoNewline -ForegroundColor Cyan
    Write-Host ("=" * 78) -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host ("=" * 79) -ForegroundColor Cyan
}

function Write-SubHeader {
    param([string]$Text)
    Write-Host ""
    Write-Host "  --- $Text ---" -ForegroundColor Yellow
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "  [$CHECK] " -NoNewline -ForegroundColor Green
    Write-Host $Message
}

function Write-Fail {
    param([string]$Message)
    Write-Host "  [$CROSS] " -NoNewline -ForegroundColor Red
    Write-Host $Message -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "  [$WARN] " -NoNewline -ForegroundColor Yellow
    Write-Host $Message -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "  [$INFO] " -NoNewline -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor DarkGray
}

#===============================================================================
# CHECK TRACKING
#===============================================================================

function Add-Check {
    param([bool]$Passed)
    if ($Passed) {
        $Script:ChecksPassed++
    } else {
        $Script:ChecksFailed++
    }
}

function Get-ChecksPassed { return $Script:ChecksPassed }
function Get-ChecksFailed { return $Script:ChecksFailed }
function Reset-Checks {
    $Script:ChecksPassed = 0
    $Script:ChecksFailed = 0
}

#===============================================================================
# EXECUTION HELPERS
#===============================================================================

function Invoke-SecurityCommand {
    param(
        [string]$Command,
        [string]$Description,
        [bool]$DryRun = $false
    )

    if ($DryRun) {
        Write-Info "[DRY-RUN] Would execute: $Command"
        return $true
    }

    try {
        $result = Invoke-Expression $Command
        if ($Description) {
            Write-Success $Description
        }
        return $true
    } catch {
        Write-Fail "Failed: $Description - $_"
        return $false
    }
}

function Request-Confirmation {
    param([string]$Message)

    $response = Read-Host "  $Message (y/n)"
    return $response -match "^[yY]"
}

#===============================================================================
# SYSTEM DETECTION
#===============================================================================

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-WindowsVersion {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    return @{
        Version = $os.Version
        Build   = $os.BuildNumber
        Caption = $os.Caption
    }
}

function Test-IsWindows11 {
    $build = (Get-WindowsVersion).Build
    return [int]$build -ge 22000
}

function Test-IsWindowsServer {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    return $os.ProductType -ne 1
}

#===============================================================================
# REGISTRY HELPERS
#===============================================================================

function Get-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        $Default = $null
    )

    try {
        $value = Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction Stop
        return $value
    } catch {
        return $Default
    }
}

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        $Value,
        [string]$Type = "DWord",
        [bool]$DryRun = $false
    )

    if ($DryRun) {
        Write-Info "[DRY-RUN] Would set $Path\$Name = $Value"
        return $true
    }

    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
        return $true
    } catch {
        Write-Fail "Failed to set registry: $_"
        return $false
    }
}

#===============================================================================
# PROFILE HELPERS
#===============================================================================

function Get-ProfileValue {
    param(
        [string]$Key,
        [string]$Profile = "recommended",
        $Default = $null
    )

    $profiles = @{
        basic = @{
            enable_firewall       = $true
            enable_defender       = $true
            disable_guest         = $true
            disable_remote_desktop = $false
            disable_smb1          = $true
            enable_bitlocker      = "prompt"
            uac_level             = "default"
        }
        recommended = @{
            enable_firewall       = $true
            enable_defender       = $true
            disable_guest         = $true
            disable_remote_desktop = $true
            disable_smb1          = $true
            enable_bitlocker      = $true
            uac_level             = "high"
            disable_telemetry     = $true
            secure_boot_required  = $true
        }
        paranoid = @{
            enable_firewall       = $true
            enable_defender       = $true
            disable_guest         = $true
            disable_remote_desktop = $true
            disable_smb1          = $true
            enable_bitlocker      = $true
            uac_level             = "always"
            disable_telemetry     = $true
            secure_boot_required  = $true
            disable_cortana       = $true
            disable_wifi_sense    = $true
            credential_guard      = $true
            block_admin_elevation = $true
        }
    }

    if ($profiles[$Profile] -and $profiles[$Profile].ContainsKey($Key)) {
        return $profiles[$Profile][$Key]
    }
    return $Default
}

# Export functions
Export-ModuleMember -Function *
