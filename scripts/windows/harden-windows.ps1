#Requires -RunAsAdministrator
<#
.SYNOPSIS
    FK94 Security - Windows Hardening Script

.DESCRIPTION
    Script para fortificar la seguridad de Windows 10/11
    Ejecutar como Administrador

.PARAMETER Audit
    Solo audita sin aplicar cambios

.PARAMETER All
    Aplica todos los cambios sin confirmacion

.EXAMPLE
    .\harden-windows.ps1
    .\harden-windows.ps1 -Audit
    .\harden-windows.ps1 -All

.NOTES
    Author: FK94 Security
    Website: https://github.com/fk94security/fk94_security
#>

param(
    [switch]$Audit,
    [switch]$All
)

#===============================================================================
# CONFIGURACION
#===============================================================================

$ErrorActionPreference = "SilentlyContinue"
$LogFile = "$env:USERPROFILE\Desktop\windows_hardening_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

#===============================================================================
# FUNCIONES AUXILIARES
#===============================================================================

function Write-Log {
    param([string]$Message, [string]$Type = "INFO")

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Type] $Message"

    switch ($Type) {
        "SUCCESS" { Write-Host "[OK] $Message" -ForegroundColor Green }
        "WARNING" { Write-Host "[!] $Message" -ForegroundColor Yellow }
        "ERROR"   { Write-Host "[X] $Message" -ForegroundColor Red }
        "HEADER"  {
            Write-Host ""
            Write-Host "================================================================" -ForegroundColor Cyan
            Write-Host "  $Message" -ForegroundColor Cyan
            Write-Host "================================================================" -ForegroundColor Cyan
        }
        default   { Write-Host "[i] $Message" -ForegroundColor White }
    }

    Add-Content -Path $LogFile -Value $LogMessage
}

function Confirm-Action {
    param([string]$Message)

    if ($All) { return $true }
    if ($Audit) { return $false }

    $response = Read-Host "$Message [y/N]"
    return ($response -eq 'y' -or $response -eq 'Y')
}

function Show-Banner {
    Write-Host ""
    Write-Host "  _____ _  _____ _  _     ____                       _ _         " -ForegroundColor Cyan
    Write-Host " |  ___| |/ / _ | || |   / ___|  ___  ___ _   _ _ __(_| |_ _   _ " -ForegroundColor Cyan
    Write-Host " | |_  | ' | (_)| || |_  \___ \ / _ \/ __| | | | '__| | __| | | |" -ForegroundColor Cyan
    Write-Host " |  _| | . \__, |__   _|  ___) |  __| (__| |_| | |  | | |_| |_| |" -ForegroundColor Cyan
    Write-Host " |_|   |_|\_\ /_/   |_|   |____/ \___|\___|\__,_|_|  |_|\__|\__, |" -ForegroundColor Cyan
    Write-Host "                                                           |___/ " -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Windows Hardening Script" -ForegroundColor Yellow
    Write-Host "https://github.com/fk94security/fk94_security" -ForegroundColor Gray
    Write-Host ""
}

#===============================================================================
# MODULO 1: WINDOWS DEFENDER
#===============================================================================

function Set-WindowsDefender {
    Write-Log "WINDOWS DEFENDER - Configuracion de Antivirus" -Type "HEADER"

    # Verificar estado
    $DefenderStatus = Get-MpComputerStatus

    if ($DefenderStatus.AntivirusEnabled) {
        Write-Log "Windows Defender esta habilitado" -Type "SUCCESS"
    } else {
        Write-Log "Windows Defender esta DESHABILITADO" -Type "ERROR"
    }

    Write-Log "Real-time Protection: $($DefenderStatus.RealTimeProtectionEnabled)"
    Write-Log "Behavior Monitoring: $($DefenderStatus.BehaviorMonitorEnabled)"
    Write-Log "Cloud Protection: $($DefenderStatus.IoavProtectionEnabled)"

    if (-not $Audit) {
        Write-Log "Configurando Windows Defender para maxima proteccion..."

        if (Confirm-Action "Habilitar proteccion en tiempo real?") {
            Set-MpPreference -DisableRealtimeMonitoring $false
            Write-Log "Real-time protection habilitado" -Type "SUCCESS"
        }

        if (Confirm-Action "Habilitar proteccion cloud?") {
            Set-MpPreference -MAPSReporting Advanced
            Set-MpPreference -SubmitSamplesConsent SendAllSamples
            Write-Log "Cloud protection configurado" -Type "SUCCESS"
        }

        if (Confirm-Action "Habilitar proteccion contra PUAs (Potentially Unwanted Apps)?") {
            Set-MpPreference -PUAProtection Enabled
            Write-Log "PUA protection habilitado" -Type "SUCCESS"
        }

        if (Confirm-Action "Habilitar Network Protection?") {
            Set-MpPreference -EnableNetworkProtection Enabled
            Write-Log "Network protection habilitado" -Type "SUCCESS"
        }
    }
}

#===============================================================================
# MODULO 2: WINDOWS FIREWALL
#===============================================================================

function Set-WindowsFirewall {
    Write-Log "WINDOWS FIREWALL - Configuracion de Red" -Type "HEADER"

    # Verificar estado por perfil
    $Profiles = @("Domain", "Private", "Public")

    foreach ($Profile in $Profiles) {
        $Status = Get-NetFirewallProfile -Name $Profile
        $StateText = if ($Status.Enabled) { "Habilitado" } else { "DESHABILITADO" }
        $Type = if ($Status.Enabled) { "SUCCESS" } else { "ERROR" }
        Write-Log "Firewall $Profile : $StateText" -Type $Type
    }

    if (-not $Audit) {
        if (Confirm-Action "Habilitar firewall en todos los perfiles?") {
            Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
            Write-Log "Firewall habilitado en todos los perfiles" -Type "SUCCESS"
        }

        if (Confirm-Action "Bloquear conexiones entrantes por defecto?") {
            Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block
            Write-Log "Conexiones entrantes bloqueadas por defecto" -Type "SUCCESS"
        }

        if (Confirm-Action "Habilitar logging del firewall?") {
            Set-NetFirewallProfile -Profile Domain,Public,Private -LogBlocked True -LogMaxSizeKilobytes 4096
            Write-Log "Logging del firewall habilitado" -Type "SUCCESS"
        }
    }
}

#===============================================================================
# MODULO 3: UAC (User Account Control)
#===============================================================================

function Set-UAC {
    Write-Log "UAC - User Account Control" -Type "HEADER"

    $UACPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    $UACLevel = Get-ItemProperty -Path $UACPath -Name "ConsentPromptBehaviorAdmin"

    Write-Log "UAC Level actual: $($UACLevel.ConsentPromptBehaviorAdmin)"

    # 0 = Elevate without prompting
    # 1 = Prompt for credentials on secure desktop
    # 2 = Prompt for consent on secure desktop
    # 3 = Prompt for credentials
    # 4 = Prompt for consent
    # 5 = Prompt for consent for non-Windows binaries (default)

    if ($UACLevel.ConsentPromptBehaviorAdmin -ge 2) {
        Write-Log "UAC esta configurado correctamente" -Type "SUCCESS"
    } else {
        Write-Log "UAC tiene configuracion debil" -Type "WARNING"
    }

    if (-not $Audit) {
        if (Confirm-Action "Configurar UAC al nivel mas alto?") {
            Set-ItemProperty -Path $UACPath -Name "ConsentPromptBehaviorAdmin" -Value 2
            Set-ItemProperty -Path $UACPath -Name "PromptOnSecureDesktop" -Value 1
            Write-Log "UAC configurado al maximo nivel" -Type "SUCCESS"
        }
    }
}

#===============================================================================
# MODULO 4: BITLOCKER
#===============================================================================

function Set-BitLocker {
    Write-Log "BITLOCKER - Encriptacion de Disco" -Type "HEADER"

    $BitLockerVolume = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue

    if ($BitLockerVolume) {
        Write-Log "BitLocker Status: $($BitLockerVolume.ProtectionStatus)"
        Write-Log "Encryption Method: $($BitLockerVolume.EncryptionMethod)"

        if ($BitLockerVolume.ProtectionStatus -eq "On") {
            Write-Log "BitLocker esta habilitado" -Type "SUCCESS"
        } else {
            Write-Log "BitLocker NO esta habilitado" -Type "WARNING"

            if (-not $Audit) {
                Write-Log "Para habilitar BitLocker manualmente:"
                Write-Log "  1. Settings > Privacy & Security > Device Encryption"
                Write-Log "  2. O ejecutar: manage-bde -on C:"
                Write-Log "  IMPORTANTE: Guardar la Recovery Key en lugar seguro"
            }
        }
    } else {
        Write-Log "BitLocker no disponible en este sistema" -Type "WARNING"
    }
}

#===============================================================================
# MODULO 5: DESHABILITAR SERVICIOS INNECESARIOS
#===============================================================================

function Set-Services {
    Write-Log "SERVICIOS - Deshabilitar Servicios Innecesarios" -Type "HEADER"

    $ServicesToDisable = @(
        @{Name="RemoteRegistry"; Description="Remote Registry - permite acceso remoto al registro"},
        @{Name="RemoteAccess"; Description="Routing and Remote Access"},
        @{Name="WinRM"; Description="Windows Remote Management"},
        @{Name="Fax"; Description="Servicio de Fax"},
        @{Name="XblAuthManager"; Description="Xbox Live Auth Manager"},
        @{Name="XblGameSave"; Description="Xbox Live Game Save"},
        @{Name="XboxNetApiSvc"; Description="Xbox Live Networking Service"}
    )

    foreach ($Service in $ServicesToDisable) {
        $Svc = Get-Service -Name $Service.Name -ErrorAction SilentlyContinue
        if ($Svc) {
            Write-Log "$($Service.Name): $($Svc.Status) - $($Service.Description)"

            if (-not $Audit -and $Svc.Status -eq "Running") {
                if (Confirm-Action "Deshabilitar $($Service.Name)?") {
                    Stop-Service -Name $Service.Name -Force
                    Set-Service -Name $Service.Name -StartupType Disabled
                    Write-Log "$($Service.Name) deshabilitado" -Type "SUCCESS"
                }
            }
        }
    }
}

#===============================================================================
# MODULO 6: TELEMETRIA Y PRIVACIDAD
#===============================================================================

function Set-Privacy {
    Write-Log "PRIVACIDAD - Configuracion de Telemetria" -Type "HEADER"

    if (-not $Audit) {
        if (Confirm-Action "Reducir telemetria de Windows al minimo?") {
            # Telemetria
            $TelemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
            if (-not (Test-Path $TelemetryPath)) {
                New-Item -Path $TelemetryPath -Force | Out-Null
            }
            Set-ItemProperty -Path $TelemetryPath -Name "AllowTelemetry" -Value 0

            # Deshabilitar servicio de telemetria
            Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue
            Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue

            Write-Log "Telemetria reducida" -Type "SUCCESS"
        }

        if (Confirm-Action "Deshabilitar Advertising ID?") {
            $AdvPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
            if (-not (Test-Path $AdvPath)) {
                New-Item -Path $AdvPath -Force | Out-Null
            }
            Set-ItemProperty -Path $AdvPath -Name "Enabled" -Value 0
            Write-Log "Advertising ID deshabilitado" -Type "SUCCESS"
        }

        if (Confirm-Action "Deshabilitar Activity History?") {
            $ActivityPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
            Set-ItemProperty -Path $ActivityPath -Name "EnableActivityFeed" -Value 0 -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $ActivityPath -Name "PublishUserActivities" -Value 0 -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $ActivityPath -Name "UploadUserActivities" -Value 0 -ErrorAction SilentlyContinue
            Write-Log "Activity History deshabilitado" -Type "SUCCESS"
        }

        if (Confirm-Action "Deshabilitar Location Tracking?") {
            $LocationPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"
            if (-not (Test-Path $LocationPath)) {
                New-Item -Path $LocationPath -Force | Out-Null
            }
            Set-ItemProperty -Path $LocationPath -Name "DisableLocation" -Value 1
            Write-Log "Location Tracking deshabilitado" -Type "SUCCESS"
        }
    } else {
        Write-Log "Modo auditoria - verificar en Settings > Privacy" -Type "INFO"
    }
}

#===============================================================================
# MODULO 7: SMB Y NETWORK
#===============================================================================

function Set-NetworkSecurity {
    Write-Log "NETWORK SECURITY - Configuracion de Red" -Type "HEADER"

    # SMBv1
    $SMBv1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
    if ($SMBv1.State -eq "Enabled") {
        Write-Log "SMBv1 esta HABILITADO - RIESGO DE SEGURIDAD" -Type "ERROR"

        if (-not $Audit -and (Confirm-Action "Deshabilitar SMBv1 (vulnerable)?")) {
            Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
            Write-Log "SMBv1 deshabilitado (requiere reinicio)" -Type "SUCCESS"
        }
    } else {
        Write-Log "SMBv1 esta deshabilitado" -Type "SUCCESS"
    }

    # SMB Signing
    if (-not $Audit -and (Confirm-Action "Habilitar SMB Signing (protege contra MITM)?")) {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "RequireSecuritySignature" -Value 1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "RequireSecuritySignature" -Value 1
        Write-Log "SMB Signing habilitado" -Type "SUCCESS"
    }

    # Deshabilitar LLMNR (vulnerable a responder attacks)
    if (-not $Audit -and (Confirm-Action "Deshabilitar LLMNR (vulnerable a ataques)?")) {
        $LLMNRPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
        if (-not (Test-Path $LLMNRPath)) {
            New-Item -Path $LLMNRPath -Force | Out-Null
        }
        Set-ItemProperty -Path $LLMNRPath -Name "EnableMulticast" -Value 0
        Write-Log "LLMNR deshabilitado" -Type "SUCCESS"
    }

    # Deshabilitar NetBIOS
    if (-not $Audit -and (Confirm-Action "Deshabilitar NetBIOS sobre TCP/IP?")) {
        $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True"
        foreach ($adapter in $adapters) {
            $adapter.SetTcpipNetbios(2) | Out-Null
        }
        Write-Log "NetBIOS deshabilitado" -Type "SUCCESS"
    }
}

#===============================================================================
# MODULO 8: WINDOWS UPDATE
#===============================================================================

function Set-WindowsUpdate {
    Write-Log "WINDOWS UPDATE - Configuracion de Actualizaciones" -Type "HEADER"

    if (-not $Audit -and (Confirm-Action "Configurar Windows Update para instalar updates automaticamente?")) {
        $WUPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        if (-not (Test-Path $WUPath)) {
            New-Item -Path $WUPath -Force | Out-Null
        }

        # Auto download and schedule install
        Set-ItemProperty -Path $WUPath -Name "AUOptions" -Value 4
        Set-ItemProperty -Path $WUPath -Name "NoAutoUpdate" -Value 0

        Write-Log "Windows Update configurado" -Type "SUCCESS"
    }

    # Verificar updates pendientes
    Write-Log "Verificando updates pendientes..."
    $Updates = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5
    Write-Log "Ultimas 5 actualizaciones instaladas:"
    foreach ($Update in $Updates) {
        Write-Log "  $($Update.HotFixID) - $($Update.InstalledOn)"
    }
}

#===============================================================================
# MODULO 9: POWERSHELL SECURITY
#===============================================================================

function Set-PowerShellSecurity {
    Write-Log "POWERSHELL SECURITY - Hardening de PowerShell" -Type "HEADER"

    # Execution Policy
    $Policy = Get-ExecutionPolicy
    Write-Log "Execution Policy actual: $Policy"

    # PowerShell Logging
    if (-not $Audit -and (Confirm-Action "Habilitar PowerShell Script Block Logging?")) {
        $PSLogPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
        if (-not (Test-Path $PSLogPath)) {
            New-Item -Path $PSLogPath -Force | Out-Null
        }
        Set-ItemProperty -Path $PSLogPath -Name "EnableScriptBlockLogging" -Value 1
        Write-Log "Script Block Logging habilitado" -Type "SUCCESS"
    }

    # Constrained Language Mode
    Write-Log "PowerShell Language Mode: $($ExecutionContext.SessionState.LanguageMode)"
}

#===============================================================================
# MODULO 10: GENERAR REPORTE
#===============================================================================

function New-SecurityReport {
    Write-Log "GENERANDO REPORTE DE SEGURIDAD" -Type "HEADER"

    $ReportFile = "$env:USERPROFILE\Desktop\security_audit_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

    $Report = @"
================================================================
  FK94 Security - Reporte de Auditoria Windows
  Fecha: $(Get-Date)
  Equipo: $env:COMPUTERNAME
  Usuario: $env:USERNAME
  Windows: $(Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption)
================================================================

WINDOWS DEFENDER
$(Get-MpComputerStatus | Format-List AntivirusEnabled, RealTimeProtectionEnabled, BehaviorMonitorEnabled | Out-String)

FIREWALL
$(Get-NetFirewallProfile | Format-Table Name, Enabled, DefaultInboundAction | Out-String)

BITLOCKER
$(Get-BitLockerVolume -MountPoint C: -ErrorAction SilentlyContinue | Format-List VolumeStatus, ProtectionStatus | Out-String)

UAC
ConsentPromptBehaviorAdmin: $(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name ConsentPromptBehaviorAdmin | Select-Object -ExpandProperty ConsentPromptBehaviorAdmin)

SERVICIOS POTENCIALMENTE RIESGOSOS
$(Get-Service RemoteRegistry, RemoteAccess, WinRM -ErrorAction SilentlyContinue | Format-Table Name, Status, StartType | Out-String)

SMBv1
$(Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue | Format-List FeatureName, State | Out-String)

ULTIMAS ACTUALIZACIONES
$(Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10 | Format-Table HotFixID, InstalledOn | Out-String)

================================================================
  Reporte generado por FK94 Security
  https://github.com/fk94security/fk94_security
================================================================
"@

    $Report | Out-File -FilePath $ReportFile -Encoding UTF8
    Write-Log "Reporte guardado en: $ReportFile" -Type "SUCCESS"
    Start-Process notepad.exe $ReportFile
}

#===============================================================================
# MENU PRINCIPAL
#===============================================================================

function Show-Menu {
    Write-Host ""
    Write-Host "Seleccionar modulo a ejecutar:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1) Windows Defender"
    Write-Host "  2) Windows Firewall"
    Write-Host "  3) UAC (User Account Control)"
    Write-Host "  4) BitLocker"
    Write-Host "  5) Servicios"
    Write-Host "  6) Privacidad y Telemetria"
    Write-Host "  7) Network Security (SMB, LLMNR)"
    Write-Host "  8) Windows Update"
    Write-Host "  9) PowerShell Security"
    Write-Host ""
    Write-Host "  A) Ejecutar TODOS los modulos"
    Write-Host "  R) Solo auditoria (generar reporte)"
    Write-Host "  Q) Salir"
    Write-Host ""

    $choice = Read-Host "Opcion"

    switch ($choice) {
        "1" { Set-WindowsDefender }
        "2" { Set-WindowsFirewall }
        "3" { Set-UAC }
        "4" { Set-BitLocker }
        "5" { Set-Services }
        "6" { Set-Privacy }
        "7" { Set-NetworkSecurity }
        "8" { Set-WindowsUpdate }
        "9" { Set-PowerShellSecurity }
        "A" {
            Set-WindowsDefender
            Set-WindowsFirewall
            Set-UAC
            Set-BitLocker
            Set-Services
            Set-Privacy
            Set-NetworkSecurity
            Set-WindowsUpdate
            Set-PowerShellSecurity
            New-SecurityReport
        }
        "R" {
            $script:Audit = $true
            Set-WindowsDefender
            Set-WindowsFirewall
            Set-UAC
            Set-BitLocker
            Set-Services
            Set-Privacy
            Set-NetworkSecurity
            Set-WindowsUpdate
            Set-PowerShellSecurity
            New-SecurityReport
        }
        "Q" { exit }
        default { Write-Log "Opcion invalida" -Type "ERROR" }
    }

    Show-Menu
}

#===============================================================================
# MAIN
#===============================================================================

# Verificar admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Este script requiere permisos de Administrador" -ForegroundColor Red
    Write-Host "Click derecho > Ejecutar como Administrador" -ForegroundColor Yellow
    exit 1
}

Show-Banner
Write-Log "Log guardandose en: $LogFile"
Write-Log "Fecha: $(Get-Date)"

if ($Audit) {
    Set-WindowsDefender
    Set-WindowsFirewall
    Set-UAC
    Set-BitLocker
    Set-Services
    Set-Privacy
    Set-NetworkSecurity
    Set-WindowsUpdate
    Set-PowerShellSecurity
    New-SecurityReport
} elseif ($All) {
    Set-WindowsDefender
    Set-WindowsFirewall
    Set-UAC
    Set-BitLocker
    Set-Services
    Set-Privacy
    Set-NetworkSecurity
    Set-WindowsUpdate
    Set-PowerShellSecurity
    New-SecurityReport
} else {
    Show-Menu
}
