# FK94 Security - Documentación

## Procedimientos Operativos

Guías paso a paso para ejecutar cada servicio:

| # | Procedimiento | Tiempo Est. | Descripción |
|---|---------------|-------------|-------------|
| 01 | [OSINT Analysis](procedures/01-OSINT-ANALYSIS.md) | 2-6 horas | Análisis de exposición pública del cliente |
| 02 | [Privacy Architecture](procedures/02-PRIVACY-ARCHITECTURE.md) | 3-5 horas | Diseño de estrategia de privacidad personal |
| 03 | [Account Hardening](procedures/03-ACCOUNT-HARDENING.md) | 4-5 horas | Fortificación de cuentas y dispositivos |
| 04 | [Communications Security](procedures/04-COMMUNICATIONS-SECURITY.md) | 2-3 horas | Mensajería segura, email cifrado, VPN |
| 05 | [Crypto OPSEC](procedures/05-CRYPTO-OPSEC.md) | 4-6 horas | Seguridad de wallets y exchanges |

## Estructura de Cada Procedimiento

Cada documento incluye:

1. **Objetivo** - Qué se busca lograr
2. **Información Requerida** - Qué pedir al cliente antes de empezar
3. **Fases detalladas** - Paso a paso con herramientas específicas
4. **Deliverables** - Qué entregar al cliente
5. **Tiempo estimado** - Cuánto toma cada fase
6. **Checklist final** - Verificación de completitud

## Herramientas Utilizadas

### OSINT & Breach Analysis
- Have I Been Pwned (gratis)
- DeHashed (pago)
- Intelligence X (freemium)
- Sherlock (CLI, gratis)

### People Search / Data Brokers
- TruePeopleSearch (gratis)
- Spokeo, WhitePages, BeenVerified (pagos)

### Privacy Tools
- SimpleLogin / AnonAddy (email aliases)
- MySudo / Google Voice (phone privacy)
- Privacy.com (tarjetas virtuales)

### Security Tools
- 1Password / Bitwarden (password managers)
- Signal (mensajería)
- ProtonMail (email cifrado)
- Mullvad / ProtonVPN (VPN)

### Crypto Tools
- Ledger / Trezor (hardware wallets)
- Gnosis Safe (multisig)
- Revoke.cash (approval management)

## Flujo de Trabajo Típico

```
1. Consulta inicial (entender necesidades)
         ↓
2. OSINT Analysis (evaluar exposición actual)
         ↓
3. Privacy Architecture (diseñar estrategia)
         ↓
4. Account Hardening (implementar seguridad)
         ↓
5. Communications Security (asegurar comunicaciones)
         ↓
6. Crypto OPSEC (si aplica)
         ↓
7. Reporte final y recomendaciones
```

## Notas Importantes

- **Cada caso es único** - Los procedimientos son guías, adaptar según el cliente
- **Documentar todo** - Screenshots, fechas, acciones tomadas
- **No guardar datos sensibles** - Seeds, passwords del cliente nunca en nuestros sistemas
- **Consultar profesionales** - Para LLCs, temas legales/fiscales, referir a abogados/contadores
