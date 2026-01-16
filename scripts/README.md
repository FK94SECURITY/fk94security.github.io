# FK94 Security - Hardening Scripts

[![macOS](https://img.shields.io/badge/macOS-11%2B-blue?logo=apple)](./macos/)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-blue?logo=windows)](./windows/)
[![CIS Benchmark](https://img.shields.io/badge/CIS-Compliant-brightgreen)](https://www.cisecurity.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow)](../LICENSE)

Comprehensive security hardening toolkits for macOS and Windows, based on CIS Benchmarks and industry best practices.

## Features

- **Three Security Profiles**: Basic, Recommended, Paranoid
- **Dry-Run Mode**: Preview changes before applying
- **Audit Mode**: Check security without making changes
- **Modular Design**: Run specific security modules
- **CIS Compliance**: Based on industry security benchmarks
- **Interactive & Non-Interactive**: Flexible usage options

## Quick Start

### macOS

```bash
cd scripts/macos
chmod +x main.sh

# Run with default (recommended) profile
./main.sh

# Audit only (no changes)
./main.sh --audit

# Preview changes (dry-run)
./main.sh --dry-run
```

### Windows

```powershell
# Run PowerShell as Administrator
cd scripts\windows

# Run with default (recommended) profile
.\main.ps1

# Audit only (no changes)
.\main.ps1 -AuditOnly

# Preview changes (dry-run)
.\main.ps1 -DryRun
```

## Directory Structure

```
scripts/
├── README.md           # This file
├── macos/
│   ├── main.sh         # Main entry point
│   ├── README.md       # macOS documentation
│   ├── config/         # Profile configurations
│   ├── modules/        # Security modules
│   ├── checks/         # Audit & compliance
│   └── utils/          # Helper functions
└── windows/
    ├── main.ps1        # Main entry point
    ├── README.md       # Windows documentation
    ├── modules/        # Security modules (PowerShell)
    └── utils/          # Helper functions
```

## Security Profiles

| Profile | Description | Use Case |
|---------|-------------|----------|
| **Basic** | Essential protections, maximum compatibility | Users who need app compatibility |
| **Recommended** | Balanced security and usability | Most users (default) |
| **Paranoid** | Maximum security, may affect functionality | High-risk individuals |

## Modules

### macOS Modules

| Module | Description |
|--------|-------------|
| `system` | FileVault, Gatekeeper, SIP, Updates, Kernel |
| `network` | Firewall, Sharing, SSH, IPv6 |
| `access` | Lock screen, Login, Guest account, Sudo |
| `privacy` | Analytics, Siri, Safari, Finder, Spotlight |
| `lockdown` | Lockdown Mode, USB, Bluetooth, Firmware |

### Windows Modules

| Module | Description |
|--------|-------------|
| `system` | Defender, BitLocker, UAC, Updates, Secure Boot |
| `network` | Firewall, Remote Desktop, SMB, Services |
| `access` | Guest, Auto-login, Password policy, Lock screen |
| `privacy` | Telemetry, Cortana, Advertising, Location |

## Usage Examples

### Run Specific Modules

```bash
# macOS - only system and network
./main.sh --modules system,network

# Windows - only system and privacy
.\main.ps1 -Modules system,privacy
```

### Different Profiles

```bash
# macOS - paranoid mode
./main.sh --profile paranoid

# Windows - basic mode
.\main.ps1 -Profile basic
```

### Audit & Compliance

```bash
# macOS - CIS benchmark check
./checks/audit.sh cis

# macOS - Generate full audit report
./checks/audit.sh full
```

## Recommended Workflow

1. **Audit First** - Run in audit mode to understand current security posture
   ```bash
   ./main.sh --audit          # macOS
   .\main.ps1 -AuditOnly      # Windows
   ```

2. **Preview Changes** - Use dry-run to see what would be modified
   ```bash
   ./main.sh --dry-run        # macOS
   .\main.ps1 -DryRun         # Windows
   ```

3. **Apply Changes** - Run interactively to apply with confirmation
   ```bash
   ./main.sh                  # macOS
   .\main.ps1                 # Windows
   ```

4. **Document** - Save the generated logs and reports

## Requirements

### macOS
- macOS 11 (Big Sur) or later
- Administrator access for some settings
- Terminal.app or compatible terminal

### Windows
- Windows 10 1809+ or Windows 11
- PowerShell 5.1 or later
- Administrator privileges

## Documentation

- [macOS Hardening Guide](./macos/README.md)
- [Windows Hardening Guide](./windows/README.md)

## References

- [CIS Benchmark - macOS](https://www.cisecurity.org/benchmark/apple_os)
- [CIS Benchmark - Windows](https://www.cisecurity.org/benchmark/microsoft_windows_desktop)
- [Apple Platform Security Guide](https://support.apple.com/guide/security/welcome/web)
- [Microsoft Security Baselines](https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-security-baselines)

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests.

## License

MIT License - See [LICENSE](../LICENSE) for details.

---

**FK94 Security** | [Website](https://fk94security.com) | [GitHub](https://github.com/fk94security)
