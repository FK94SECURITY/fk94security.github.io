# FK94 Security

**OPSEC & Privacy Services**

Operational security and personal privacy services for individuals and organizations.

## Services

- **OSINT & Exposure Analysis** - Digital footprint and exposure analysis
- **Privacy Architecture** - Personal privacy strategy design
- **Account & Device Hardening** - Account and device fortification
- **Communications Security** - Secure communications
- **Crypto/Web3 OPSEC** - Security for crypto holders

## Open Source Tools

### Hardening Scripts

Automated scripts to fortify operating systems:

| OS | Script | Description |
|----|--------|-------------|
| **macOS** | `scripts/macos/harden-macos.sh` | FileVault, Firewall, Gatekeeper, Privacy |
| **Windows** | `scripts/windows/harden-windows.ps1` | Defender, Firewall, BitLocker, Privacy |
| **Linux** | `scripts/linux/harden-linux.sh` | UFW, SSH, Kernel, Fail2ban |

```bash
# macOS
sudo ./scripts/macos/harden-macos.sh --audit

# Windows (PowerShell as Admin)
.\scripts\windows\harden-windows.ps1 -Audit

# Linux
sudo ./scripts/linux/harden-linux.sh --audit
```

### Factory Reset Guides

- [macOS Factory Reset](scripts/macos/FACTORY-RESET-MACOS.md)
- [Windows Factory Reset](scripts/windows/FACTORY-RESET-WINDOWS.md)
- [Linux Factory Reset](scripts/linux/FACTORY-RESET-LINUX.md)

### Vigia - Web Tools

Free web-based tools suite:

- **Security Scanner** - Security score for devices
- **Digital Footprint Analyzer** - OSINT exposure analysis
- **Audit Tool** - Interactive security checklist

## Project Structure

```
fk94_security/
├── index.html              # Main website
├── styles.css              # Styles
├── script.js               # JavaScript
│
├── scripts/                # Hardening scripts
│   ├── macos/
│   │   ├── harden-macos.sh
│   │   └── FACTORY-RESET-MACOS.md
│   ├── windows/
│   │   ├── harden-windows.ps1
│   │   └── FACTORY-RESET-WINDOWS.md
│   └── linux/
│       ├── harden-linux.sh
│       └── FACTORY-RESET-LINUX.md
│
├── docs/                   # Documentation
│   ├── README.md
│   └── procedures/         # Operational procedures
│       ├── 01-OSINT-ANALYSIS.md
│       ├── 02-PRIVACY-ARCHITECTURE.md
│       ├── 03-ACCOUNT-HARDENING.md
│       ├── 04-COMMUNICATIONS-SECURITY.md
│       └── 05-CRYPTO-OPSEC.md
│
├── vigia/                  # Web tools suite
│   ├── index.html
│   └── tools/
│
└── audit-tool/             # Audit checklist tool
```

## Development

```bash
# Clone repository
git clone https://github.com/fk94security/fk94_security.git
cd fk94_security

# Run local server
python3 -m http.server 8888

# Open in browser
open http://localhost:8888
```

## Contributing

1. Fork the repository
2. Create a branch for your feature (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -m 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Open a Pull Request

## License

- **Hardening scripts and guides:** MIT License
- **Professional services:** Property of FK94 Security

---

**FK94 Security** - OPSEC & Privacy Services

Website: [fk94security.com](https://fk94security.com)
GitHub: [github.com/fk94security](https://github.com/fk94security)
