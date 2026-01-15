# FK94 Security - Scripts de Hardening

Scripts automatizados para fortificar la seguridad de sistemas operativos.

## Contenido

```
scripts/
├── macos/
│   ├── harden-macos.sh          # Script de hardening
│   └── FACTORY-RESET-MACOS.md   # Guía de factory reset
├── windows/
│   ├── harden-windows.ps1       # Script de hardening (PowerShell)
│   └── FACTORY-RESET-WINDOWS.md # Guía de factory reset
├── linux/
│   ├── harden-linux.sh          # Script de hardening
│   └── FACTORY-RESET-LINUX.md   # Guía de factory reset
└── README.md
```

---

## macOS

### Hardening Script

```bash
# Dar permisos de ejecución
chmod +x harden-macos.sh

# Ejecutar (requiere sudo)
sudo ./harden-macos.sh           # Modo interactivo
sudo ./harden-macos.sh --audit   # Solo auditoría (no modifica nada)
sudo ./harden-macos.sh --all     # Aplicar todo sin preguntar
```

#### Módulos incluidos:

| Módulo | Descripción |
|--------|-------------|
| FileVault | Habilita encriptación de disco |
| Firewall | Configura firewall y stealth mode |
| Gatekeeper | Verifica protección de apps |
| SIP | Verifica System Integrity Protection |
| Lock Screen | Configura seguridad de pantalla de bloqueo |
| Services | Deshabilita servicios innecesarios (SSH, Remote Events) |
| Privacy | Reduce telemetría y tracking |
| Safari | Hardening del navegador |
| Finder | Muestra extensiones, warnings |
| Updates | Configura actualizaciones automáticas |

---

## Windows

### Hardening Script

```powershell
# Ejecutar PowerShell como Administrador

# Permitir ejecución del script
Set-ExecutionPolicy Bypass -Scope Process

# Ejecutar
.\harden-windows.ps1           # Modo interactivo
.\harden-windows.ps1 -Audit    # Solo auditoría
.\harden-windows.ps1 -All      # Aplicar todo
```

#### Módulos incluidos:

| Módulo | Descripción |
|--------|-------------|
| Windows Defender | Configura antivirus y protecciones |
| Firewall | Habilita firewall en todos los perfiles |
| UAC | Configura User Account Control |
| BitLocker | Verifica encriptación de disco |
| Services | Deshabilita servicios innecesarios |
| Privacy | Reduce telemetría, ads, tracking |
| Network | Deshabilita SMBv1, LLMNR, NetBIOS |
| Windows Update | Configura actualizaciones automáticas |
| PowerShell | Habilita logging de scripts |

---

## Linux

### Hardening Script

```bash
# Dar permisos de ejecución
chmod +x harden-linux.sh

# Ejecutar (requiere sudo)
sudo ./harden-linux.sh           # Modo interactivo
sudo ./harden-linux.sh --audit   # Solo auditoría
sudo ./harden-linux.sh --all     # Aplicar todo
```

#### Distribuciones soportadas:
- Ubuntu / Debian
- Fedora / CentOS / RHEL
- Arch Linux

#### Módulos incluidos:

| Módulo | Descripción |
|--------|-------------|
| Updates | Instala actualizaciones pendientes |
| Firewall | Configura UFW o firewalld |
| SSH | Hardening de configuración SSH |
| Permissions | Verifica permisos de archivos críticos |
| Kernel | Configura sysctl para seguridad |
| Services | Deshabilita servicios innecesarios |
| Auditd | Habilita sistema de auditoría |
| Passwords | Configura política de contraseñas |
| Fail2ban | Protección contra brute force |

---

## Guías de Factory Reset

Cada directorio incluye una guía detallada para hacer factory reset del sistema:

- [Factory Reset macOS](macos/FACTORY-RESET-MACOS.md)
- [Factory Reset Windows](windows/FACTORY-RESET-WINDOWS.md)
- [Factory Reset Linux](linux/FACTORY-RESET-LINUX.md)

Usar estas guías cuando:
- Sospecha de compromiso o malware
- Venta o transferencia del equipo
- Desea empezar con instalación limpia y segura

---

## Uso Recomendado

### Para Clientes de FK94 Security

1. **Primero:** Ejecutar en modo auditoría para ver estado actual
   ```bash
   sudo ./harden-[os].sh --audit
   ```

2. **Revisar:** Analizar el reporte generado con el cliente

3. **Aplicar:** Ejecutar módulos necesarios de forma interactiva
   ```bash
   sudo ./harden-[os].sh
   ```

4. **Documentar:** Guardar los logs generados en el Desktop

### Para Uso Personal

Ejecutar el script en modo interactivo y responder a cada pregunta según tus necesidades.

---

## Output y Logs

Los scripts generan:

1. **Log file:** `~/Desktop/[os]_hardening_[timestamp].log`
   - Registro de todas las acciones tomadas

2. **Audit report:** `~/Desktop/security_audit_[timestamp].txt`
   - Resumen del estado de seguridad (modo --audit)

---

## Advertencias

- **Hacer backup antes de ejecutar** - Algunos cambios pueden afectar funcionalidad
- **Leer lo que hace cada módulo** - No aplicar ciegamente
- **Probar en entorno de test primero** - Si es posible
- **Algunos cambios requieren reinicio** - Para aplicarse completamente

---

## Contribuir

Si encontrás bugs o querés agregar funcionalidad:

1. Fork del repositorio
2. Crear branch para tu feature
3. Pull request con descripción clara

---

## Licencia

MIT License - Ver LICENSE en el repositorio principal

---

*FK94 Security - https://github.com/fk94security/fk94_security*
