<div align="center">

# 👁️ VIGÍA

### Security Scanner & Hardening Tools

[![macOS](https://img.shields.io/badge/macOS-Sonoma%20%7C%20Ventura%20%7C%20Monterey-blue)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/Bash-5.0+-orange.svg)](https://www.gnu.org/software/bash/)
[![Maintained](https://img.shields.io/badge/Maintained-Yes-brightgreen.svg)](https://github.com/fk94security/vigia)

**Herramientas gratuitas y open source para analizar y mejorar la seguridad de tu Mac.**

[Descargar](#-instalación) • [Documentación](#-qué-analiza) • [Contribuir](#-contribuir)

---

</div>

## 🎯 ¿Qué es Vigía?

Vigía es un conjunto de herramientas de seguridad para macOS que te permite:

- **Analizar** la configuración de seguridad de tu Mac
- **Obtener** un score de 0 a 100 basado en mejores prácticas
- **Mejorar** tu seguridad con un solo comando
- **Entender** qué significa cada configuración en español simple

Todo 100% gratuito, open source, y sin telemetría.

## 📥 Instalación

### Opción 1: Clonar el repositorio

```bash
git clone https://github.com/fk94security/vigia.git
cd vigia/scripts
chmod +x *.sh
```

### Opción 2: Descargar directo

```bash
curl -O https://raw.githubusercontent.com/fk94security/vigia/main/scripts/scan-macos.sh
curl -O https://raw.githubusercontent.com/fk94security/vigia/main/scripts/harden-macos.sh
chmod +x *.sh
```

## 🚀 Uso

### Analizar tu Mac

```bash
./scan-macos.sh
```

Esto va a analizar 10 configuraciones de seguridad y darte un score.

### Mejorar tu seguridad

```bash
./harden-macos.sh
```

Esto aplica automáticamente las configuraciones recomendadas.

## 🔍 ¿Qué analiza?

| Check | Descripción | Impacto |
|-------|-------------|---------|
| **FileVault** | Encriptación del disco | Si te roban la Mac, no pueden leer tus archivos |
| **Firewall** | Bloquea conexiones entrantes | Evita que hackers se conecten a tu Mac |
| **Gatekeeper** | Verifica apps firmadas | Previene instalación de malware |
| **Auto-Update** | Actualizaciones automáticas | Parches de seguridad al día |
| **SSH** | Acceso remoto | Previene conexiones no autorizadas |
| **Screen Sharing** | Compartir pantalla | Evita que vean tu pantalla remotamente |
| **Find My Mac** | Ubicación del dispositivo | Encontrar o borrar Mac robada |
| **SIP** | Protección del sistema | Previene modificaciones maliciosas |
| **Password After Sleep** | Bloqueo automático | Protege cuando dejás la Mac sola |
| **Guest Account** | Cuenta de invitado | Elimina vector de ataque |

## 📊 Interpretación del Score

| Score | Estado | Significado |
|-------|--------|-------------|
| 80-100 | 🟢 Excelente | Tu Mac está bien protegida |
| 60-79 | 🟡 Regular | Hay cosas que deberías mejorar |
| 0-59 | 🔴 Crítico | Tu Mac tiene problemas serios de seguridad |

## 📁 Estructura del Proyecto

```
vigia/
├── scripts/
│   ├── scan-macos.sh      # Scanner de seguridad
│   └── harden-macos.sh    # Script de hardening
├── audit-tool/            # Web app de auditoría (próximamente)
├── osint/                 # Herramientas OSINT (próximamente)
├── README.md
└── LICENSE
```

## 🔮 Roadmap

- [x] Scanner de seguridad para macOS
- [x] Script de hardening automático
- [ ] Scanner para Windows
- [ ] Scanner para Linux
- [ ] Herramientas OSINT (username search, breach check)
- [ ] Web app de auditoría completa
- [ ] Reportes en PDF

## 🤝 Contribuir

¡Las contribuciones son bienvenidas!

1. Fork el repositorio
2. Creá tu branch (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -m 'Agregar nueva funcionalidad'`)
4. Push al branch (`git push origin feature/nueva-funcionalidad`)
5. Abrí un Pull Request

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver [LICENSE](LICENSE) para más detalles.

## 🏢 Sobre FK94 Security

Vigía es desarrollado y mantenido por **FK94 Security**, una empresa de ciberseguridad especializada en:

- Auditorías de seguridad personal
- Protección contra ataques dirigidos
- Capacitación en seguridad
- Respuesta a incidentes

**¿Necesitás ayuda profesional?** Visitá [fk94security.com](https://fk94security.com)

---

<div align="center">

**Powered by [FK94 Security](https://fk94security.com)**

⭐ Si te sirvió, dejanos una estrella en GitHub ⭐

</div>
