# FK94 Security - Hardening Scripts

Automated scripts to fortify operating system security.

## Contents

```
scripts/
├── macos/
│   ├── harden-macos.sh          # Hardening script
│   └── FACTORY-RESET-MACOS.md   # Factory reset guide
├── windows/
│   ├── harden-windows.ps1       # Hardening script (PowerShell)
│   └── FACTORY-RESET-WINDOWS.md # Factory reset guide
├── linux/
│   ├── harden-linux.sh          # Hardening script
│   └── FACTORY-RESET-LINUX.md   # Factory reset guide
└── README.md
```

---

## macOS

### Hardening Script

```bash
# Grant execution permissions
chmod +x harden-macos.sh

# Run (requires sudo)
sudo ./harden-macos.sh           # Interactive mode
sudo ./harden-macos.sh --audit   # Audit only (doesn't modify anything)
sudo ./harden-macos.sh --all     # Apply all without prompts
```

#### Included modules:

| Module | Description |
|--------|-------------|
| FileVault | Enables disk encryption |
| Firewall | Configures firewall and stealth mode |
| Gatekeeper | Verifies app protection |
| SIP | Verifies System Integrity Protection |
| Lock Screen | Configures lock screen security |
| Services | Disables unnecessary services (SSH, Remote Events) |
| Privacy | Reduces telemetry and tracking |
| Safari | Browser hardening |
| Finder | Shows extensions, warnings |
| Updates | Configures automatic updates |

---

## Windows

### Hardening Script

```powershell
# Run PowerShell as Administrator

# Allow script execution
Set-ExecutionPolicy Bypass -Scope Process

# Run
.\harden-windows.ps1           # Interactive mode
.\harden-windows.ps1 -Audit    # Audit only
.\harden-windows.ps1 -All      # Apply all
```

#### Included modules:

| Module | Description |
|--------|-------------|
| Windows Defender | Configures antivirus and protections |
| Firewall | Enables firewall on all profiles |
| UAC | Configures User Account Control |
| BitLocker | Verifies disk encryption |
| Services | Disables unnecessary services |
| Privacy | Reduces telemetry, ads, tracking |
| Network | Disables SMBv1, LLMNR, NetBIOS |
| Windows Update | Configures automatic updates |
| PowerShell | Enables script logging |

---

## Linux

### Hardening Script

```bash
# Grant execution permissions
chmod +x harden-linux.sh

# Run (requires sudo)
sudo ./harden-linux.sh           # Interactive mode
sudo ./harden-linux.sh --audit   # Audit only
sudo ./harden-linux.sh --all     # Apply all
```

#### Supported distributions:
- Ubuntu / Debian
- Fedora / CentOS / RHEL
- Arch Linux

#### Included modules:

| Module | Description |
|--------|-------------|
| Updates | Installs pending updates |
| Firewall | Configures UFW or firewalld |
| SSH | SSH configuration hardening |
| Permissions | Verifies critical file permissions |
| Kernel | Configures sysctl for security |
| Services | Disables unnecessary services |
| Auditd | Enables audit system |
| Passwords | Configures password policy |
| Fail2ban | Brute force protection |

---

## Factory Reset Guides

Each directory includes a detailed guide for system factory reset:

- [Factory Reset macOS](macos/FACTORY-RESET-MACOS.md)
- [Factory Reset Windows](windows/FACTORY-RESET-WINDOWS.md)
- [Factory Reset Linux](linux/FACTORY-RESET-LINUX.md)

Use these guides when:
- Suspected compromise or malware
- Selling or transferring the device
- Want to start with a clean and secure installation

---

## Recommended Usage

### For FK94 Security Clients

1. **First:** Run in audit mode to see current status
   ```bash
   sudo ./harden-[os].sh --audit
   ```

2. **Review:** Analyze the generated report with the client

3. **Apply:** Run necessary modules interactively
   ```bash
   sudo ./harden-[os].sh
   ```

4. **Document:** Save the logs generated on Desktop

### For Personal Use

Run the script in interactive mode and answer each question according to your needs.

---

## Output and Logs

The scripts generate:

1. **Log file:** `~/Desktop/[os]_hardening_[timestamp].log`
   - Record of all actions taken

2. **Audit report:** `~/Desktop/security_audit_[timestamp].txt`
   - Security status summary (--audit mode)

---

## Warnings

- **Backup before running** - Some changes may affect functionality
- **Read what each module does** - Don't apply blindly
- **Test in a test environment first** - If possible
- **Some changes require restart** - To fully apply

---

## Contributing

If you find bugs or want to add functionality:

1. Fork the repository
2. Create a branch for your feature
3. Pull request with clear description

---

## License

MIT License - See LICENSE in the main repository

---

*FK94 Security - https://github.com/fk94security/fk94_security*
