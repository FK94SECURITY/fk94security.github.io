# FK94 Security - macOS Hardening

[![macOS](https://img.shields.io/badge/macOS-11%2B-blue?logo=apple)](https://www.apple.com/macos/)
[![Shell](https://img.shields.io/badge/Shell-Bash-green?logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/License-MIT-yellow)](../../LICENSE)
[![CIS Benchmark](https://img.shields.io/badge/CIS-Compliant-brightgreen)](https://www.cisecurity.org/benchmark/apple_os)

Comprehensive macOS security hardening toolkit based on CIS Benchmarks and industry best practices.

## Features

- **Three Security Profiles**: Basic, Recommended, Paranoid
- **Dry-Run Mode**: Preview changes before applying
- **Audit Mode**: Check security without making changes
- **Modular Design**: Run specific security modules
- **CIS Compliance**: Based on CIS Benchmarks for macOS
- **Apple Silicon Support**: Full support for M1/M2/M3 Macs

## Quick Start

```bash
# Clone the repository
git clone https://github.com/fk94security/fk94_security.git
cd fk94_security/scripts/macos

# Make executable
chmod +x main.sh

# Run with default (recommended) profile
./main.sh

# Preview changes without applying (dry-run)
./main.sh --dry-run

# Audit only (no changes)
./main.sh --audit
```

## Security Profiles

### Basic
Minimal security improvements for maximum compatibility.
- FileVault (prompted)
- Firewall enabled
- Basic privacy settings

### Recommended (Default)
Balanced security and usability for most users.
- FileVault enforced
- Stealth mode firewall
- Sharing services disabled
- Enhanced privacy settings

### Paranoid
Maximum security for high-risk individuals.
- Lockdown Mode (macOS 13+)
- Block all incoming connections
- Disable Bluetooth, AirDrop, Handoff
- Strict Safari hardening
- IPv6 disabled

## Usage

```bash
# Run with specific profile
./main.sh --profile paranoid

# Run specific modules only
./main.sh --modules system,network

# Audit mode (check without changes)
./main.sh --audit

# Dry-run mode (preview changes)
./main.sh --dry-run

# Quiet mode (minimal output)
./main.sh --quiet
```

## Modules

| Module | Description |
|--------|-------------|
| `system` | FileVault, Gatekeeper, SIP, Updates, Kernel |
| `network` | Firewall, Sharing, SSH, IPv6 |
| `access` | Lock screen, Login, Guest account, Sudo |
| `privacy` | Analytics, Siri, Safari, Finder, Spotlight |
| `lockdown` | Lockdown Mode, USB, Bluetooth, Firmware |

## Audit & Compliance

```bash
# Quick security check
./checks/audit.sh quick

# Full audit report (saved to Desktop)
./checks/audit.sh full

# CIS Benchmark compliance check
./checks/audit.sh cis
```

## What Gets Checked

### System Security
- [x] FileVault disk encryption
- [x] Gatekeeper app verification
- [x] System Integrity Protection (SIP)
- [x] Automatic security updates
- [x] Kernel hardening (ASLR, core dumps)
- [x] Secure Boot (Apple Silicon)

### Network Security
- [x] Application firewall
- [x] Stealth mode
- [x] Sharing services (Screen, File, Printer)
- [x] Remote access (SSH, Remote Events, ARD)
- [x] IPv6 configuration
- [x] AirDrop settings

### Access Control
- [x] Password after sleep/screensaver
- [x] Auto-login disabled
- [x] Guest account
- [x] Password hints
- [x] Lock screen message
- [x] Sudo configuration

### Privacy & Data Protection
- [x] Apple diagnostics/analytics
- [x] Personalized advertising
- [x] Siri analytics
- [x] Safari privacy settings
- [x] Finder security (file extensions)
- [x] Spotlight suggestions

### Advanced (Paranoid)
- [x] Lockdown Mode (macOS 13+)
- [x] USB Restricted Mode
- [x] Bluetooth security
- [x] Firmware password (Intel)
- [x] Secure Keyboard Entry
- [x] Kernel extensions audit

## Directory Structure

```
macos/
├── main.sh              # Main entry point
├── README.md            # This file
├── config/
│   └── profiles.conf    # Security profile definitions
├── modules/
│   ├── system.sh        # System security
│   ├── network.sh       # Network security
│   ├── access.sh        # Access control
│   ├── privacy.sh       # Privacy settings
│   └── lockdown.sh      # Advanced hardening
├── checks/
│   └── audit.sh         # Audit & compliance
└── utils/
    ├── colors.sh        # Terminal colors
    └── helpers.sh       # Helper functions
```

## Requirements

- macOS 11 (Big Sur) or later
- Administrator access for some settings
- Terminal.app or compatible terminal

## Compatibility

| macOS Version | Support Level |
|---------------|---------------|
| macOS 15 (Sequoia) | Full |
| macOS 14 (Sonoma) | Full |
| macOS 13 (Ventura) | Full |
| macOS 12 (Monterey) | Full |
| macOS 11 (Big Sur) | Full |
| macOS 10.x | Partial |

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to help improve the project.

## References

- [CIS Benchmark for Apple macOS](https://www.cisecurity.org/benchmark/apple_os)
- [Apple Platform Security Guide](https://support.apple.com/guide/security/welcome/web)
- [NIST macOS Security Guidelines](https://csrc.nist.gov/)

## License

MIT License - See [LICENSE](../../LICENSE) for details.

---

**FK94 Security** | [Website](https://fk94security.com) | [GitHub](https://github.com/fk94security)
