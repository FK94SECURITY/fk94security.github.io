# FK94 Security - Windows Hardening

[![Windows](https://img.shields.io/badge/Windows-10%2F11-blue?logo=windows)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)](https://docs.microsoft.com/en-us/powershell/)
[![License](https://img.shields.io/badge/License-MIT-yellow)](../../LICENSE)
[![CIS Benchmark](https://img.shields.io/badge/CIS-Compliant-brightgreen)](https://www.cisecurity.org/benchmark/microsoft_windows_desktop)

Comprehensive Windows security hardening toolkit based on CIS Benchmarks and industry best practices.

## Features

- **Three Security Profiles**: Basic, Recommended, Paranoid
- **Dry-Run Mode**: Preview changes before applying
- **Audit Mode**: Check security without making changes
- **Modular Design**: Run specific security modules
- **CIS Compliance**: Based on CIS Benchmarks for Windows
- **Windows 10/11 Support**: Full support for modern Windows

## Quick Start

```powershell
# Run PowerShell as Administrator

# Allow script execution (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Clone the repository
git clone https://github.com/fk94security/fk94_security.git
cd fk94_security/scripts/windows

# Run with default (recommended) profile
.\main.ps1

# Preview changes without applying (dry-run)
.\main.ps1 -DryRun

# Audit only (no changes)
.\main.ps1 -AuditOnly
```

## Security Profiles

### Basic
Minimal security improvements for maximum compatibility.
- Windows Defender enabled
- Firewall enabled
- Guest account disabled

### Recommended (Default)
Balanced security and usability for most users.
- BitLocker encryption
- UAC at default level
- Remote Desktop disabled
- Telemetry reduced
- SMBv1 disabled

### Paranoid
Maximum security for high-risk individuals.
- UAC at maximum
- Telemetry minimized
- Cortana disabled
- Credential Guard enabled
- Activity tracking disabled
- All unnecessary services disabled

## Usage

```powershell
# Run with specific profile
.\main.ps1 -Profile paranoid

# Run specific modules only
.\main.ps1 -Modules system,network

# Audit mode (check without changes)
.\main.ps1 -AuditOnly

# Dry-run mode (preview changes)
.\main.ps1 -DryRun

# Quiet mode (minimal output)
.\main.ps1 -Quiet
```

## Modules

| Module | Description |
|--------|-------------|
| `system` | Windows Defender, BitLocker, UAC, Updates, Secure Boot |
| `network` | Firewall, Remote Desktop, SMB, Network Services |
| `access` | Guest account, Auto-login, Password policy, Lock screen |
| `privacy` | Telemetry, Cortana, Advertising, Location, Activity history |

## What Gets Checked

### System Security
- [x] Windows Defender status
- [x] Real-time protection
- [x] Cloud-delivered protection
- [x] BitLocker disk encryption
- [x] User Account Control (UAC)
- [x] Secure Boot status
- [x] Windows Updates

### Network Security
- [x] Windows Firewall (all profiles)
- [x] Remote Desktop
- [x] SMBv1 (disabled for security)
- [x] SMB signing and encryption
- [x] Unnecessary network services
- [x] Network Level Authentication

### Access Control
- [x] Guest account
- [x] Auto-login disabled
- [x] Password policy
- [x] Lock screen settings
- [x] Built-in Administrator account
- [x] Credential Guard (paranoid)

### Privacy & Data Protection
- [x] Windows telemetry level
- [x] Cortana settings
- [x] Advertising ID
- [x] Location services
- [x] Activity history
- [x] Feedback settings

## Directory Structure

```
windows/
├── main.ps1             # Main entry point
├── README.md            # This file
├── modules/
│   ├── system.psm1      # System security
│   ├── network.psm1     # Network security
│   ├── access.psm1      # Access control
│   └── privacy.psm1     # Privacy settings
└── utils/
    └── helpers.psm1     # Helper functions
```

## Requirements

- Windows 10 1809+ or Windows 11
- PowerShell 5.1 or later
- Administrator privileges
- Execution policy: RemoteSigned or less restrictive

## Compatibility

| Windows Version | Support Level |
|-----------------|---------------|
| Windows 11 23H2 | Full |
| Windows 11 22H2 | Full |
| Windows 10 22H2 | Full |
| Windows 10 21H2 | Full |
| Windows 10 1809+ | Full |
| Windows 10 older | Partial |
| Windows Server 2019+ | Partial |

## Troubleshooting

### Script won't run
```powershell
# Check execution policy
Get-ExecutionPolicy

# Set to allow local scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Not running as Administrator
Right-click PowerShell and select "Run as Administrator" before running the script.

### Module import errors
Ensure you're running from the correct directory:
```powershell
cd path\to\fk94_security\scripts\windows
.\main.ps1
```

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests.

## References

- [CIS Benchmark for Windows](https://www.cisecurity.org/benchmark/microsoft_windows_desktop)
- [Microsoft Security Baselines](https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-security-baselines)
- [NIST Windows Guidelines](https://csrc.nist.gov/)

## License

MIT License - See [LICENSE](../../LICENSE) for details.

---

**FK94 Security** | [Website](https://fk94security.com) | [GitHub](https://github.com/fk94security)
