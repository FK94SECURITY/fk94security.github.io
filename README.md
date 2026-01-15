# FK94 Security

**OPSEC & Privacy Services**

Servicios de seguridad operativa y privacidad personal para individuos y organizaciones.

## Servicios

- **OSINT & Exposure Analysis** - Análisis de huella digital y exposición
- **Privacy Architecture** - Diseño de estrategia de privacidad personal
- **Account & Device Hardening** - Fortificación de cuentas y dispositivos
- **Communications Security** - Seguridad en comunicaciones
- **Crypto/Web3 OPSEC** - Seguridad para holders de crypto

## Open Source Tools

### Scripts de Hardening

Scripts automatizados para fortificar sistemas operativos:

| OS | Script | Descripción |
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

### Guías de Factory Reset

- [macOS Factory Reset](scripts/macos/FACTORY-RESET-MACOS.md)
- [Windows Factory Reset](scripts/windows/FACTORY-RESET-WINDOWS.md)
- [Linux Factory Reset](scripts/linux/FACTORY-RESET-LINUX.md)

### Vigía - Web Tools

Suite de herramientas gratuitas basadas en web:

- **Security Scanner** - Score de seguridad para dispositivos
- **Digital Footprint Analyzer** - Análisis OSINT de exposición
- **Audit Tool** - Checklist interactivo de seguridad

## Estructura del Proyecto

```
fk94_security/
├── index.html              # Website principal
├── styles.css              # Estilos
├── script.js               # JavaScript
│
├── scripts/                # Scripts de hardening
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
├── docs/                   # Documentación
│   ├── README.md
│   └── procedures/         # Procedimientos operativos
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
# Clonar repositorio
git clone https://github.com/fk94security/fk94_security.git
cd fk94_security

# Correr servidor local
python3 -m http.server 8888

# Abrir en browser
open http://localhost:8888
```

## Contribuir

1. Fork del repositorio
2. Crear branch para tu feature (`git checkout -b feature/nueva-feature`)
3. Commit de cambios (`git commit -m 'Add nueva feature'`)
4. Push al branch (`git push origin feature/nueva-feature`)
5. Abrir Pull Request

## Licencia

- **Scripts de hardening y guías:** MIT License
- **Servicios profesionales:** Propiedad de FK94 Security

---

**FK94 Security** - OPSEC & Privacy Services

Website: [fk94security.com](https://fk94security.com)
GitHub: [github.com/fk94security](https://github.com/fk94security)
