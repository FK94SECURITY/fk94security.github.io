<div align="center">

# VIGIA

### Security Scanner & Hardening Tools

[![macOS](https://img.shields.io/badge/macOS-Sonoma%20%7C%20Ventura%20%7C%20Monterey-blue)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/Bash-5.0+-orange.svg)](https://www.gnu.org/software/bash/)
[![Maintained](https://img.shields.io/badge/Maintained-Yes-brightgreen.svg)](https://github.com/fk94security/vigia)

**Free and open source tools to analyze and improve your Mac's security.**

[Download](#-installation) • [Documentation](#-what-does-it-analyze) • [Contribute](#-contributing)

---

</div>

## What is Vigia?

Vigia is a set of security tools for macOS that allows you to:

- **Analyze** your Mac's security configuration
- **Get** a score from 0 to 100 based on best practices
- **Improve** your security with a single command
- **Understand** what each setting means in plain language

100% free, open source, and no telemetry.

## Installation

### Option 1: Clone the repository

```bash
git clone https://github.com/fk94security/vigia.git
cd vigia/scripts
chmod +x *.sh
```

### Option 2: Direct download

```bash
curl -O https://raw.githubusercontent.com/fk94security/vigia/main/scripts/scan-macos.sh
curl -O https://raw.githubusercontent.com/fk94security/vigia/main/scripts/harden-macos.sh
chmod +x *.sh
```

## Usage

### Scan your Mac

```bash
./scan-macos.sh
```

This will analyze 10 security settings and give you a score.

### Improve your security

```bash
./harden-macos.sh
```

This automatically applies the recommended settings.

## What does it analyze?

| Check | Description | Impact |
|-------|-------------|--------|
| **FileVault** | Disk encryption | If your Mac is stolen, they can't read your files |
| **Firewall** | Blocks incoming connections | Prevents hackers from connecting to your Mac |
| **Gatekeeper** | Verifies signed apps | Prevents malware installation |
| **Auto-Update** | Automatic updates | Security patches up to date |
| **SSH** | Remote access | Prevents unauthorized connections |
| **Screen Sharing** | Screen sharing | Prevents remote screen viewing |
| **Find My Mac** | Device location | Find or wipe a stolen Mac |
| **SIP** | System protection | Prevents malicious modifications |
| **Password After Sleep** | Auto-lock | Protects when you leave your Mac unattended |
| **Guest Account** | Guest account | Eliminates attack vector |

## Score Interpretation

| Score | Status | Meaning |
|-------|--------|---------|
| 80-100 | Excellent | Your Mac is well protected |
| 60-79 | Fair | There are things you should improve |
| 0-59 | Critical | Your Mac has serious security issues |

## Project Structure

```
vigia/
├── scripts/
│   ├── scan-macos.sh      # Security scanner
│   └── harden-macos.sh    # Hardening script
├── audit-tool/            # Audit web app (coming soon)
├── osint/                 # OSINT tools (coming soon)
├── README.md
└── LICENSE
```

## Roadmap

- [x] Security scanner for macOS
- [x] Automatic hardening script
- [ ] Scanner for Windows
- [ ] Scanner for Linux
- [ ] OSINT tools (username search, breach check)
- [ ] Complete audit web app
- [ ] PDF reports

## Contributing

Contributions are welcome!

1. Fork the repository
2. Create your branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -m 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Open a Pull Request

## License

This project is under the MIT license. See [LICENSE](LICENSE) for more details.

## About FK94 Security

Vigia is developed and maintained by **FK94 Security**, a cybersecurity company specializing in:

- Personal security audits
- Protection against targeted attacks
- Security training
- Incident response

**Need professional help?** Visit [fk94security.com](https://fk94security.com)

---

<div align="center">

**Powered by [FK94 Security](https://fk94security.com)**

</div>
