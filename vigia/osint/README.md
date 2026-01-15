# 🔍 VIGÍA OSINT Tools

Herramientas de Open Source Intelligence (OSINT) para verificar tu exposición digital.

## Herramientas

### 1. Username Search (`username-search.sh`)

Busca un username en +30 plataformas para ver dónde existe esa cuenta.

```bash
./username-search.sh johndoe
```

**Plataformas que verifica:**
- Redes sociales: Twitter, Instagram, TikTok, Facebook, LinkedIn, Reddit, Pinterest
- Desarrollo: GitHub, GitLab, Stack Overflow, CodePen, Dev.to
- Gaming: Steam, Twitch, Xbox, Roblox
- Multimedia: YouTube, Spotify, SoundCloud, Vimeo, Medium
- Otros: Gravatar, Keybase, Patreon, Telegram

### 2. Email Intelligence (`email-intel.sh`)

Analiza la exposición de un email y crea un perfil de riesgo.

```bash
./email-intel.sh juan@gmail.com
```

**¿Qué hace?**
- Verifica si tiene Gravatar (foto de perfil global)
- Busca cuentas asociadas al username del email
- Analiza el dominio del email
- Genera Google Dorks para investigación manual
- Crea un reporte con recomendaciones

## ¿Por qué es importante?

Un atacante puede usar esta información para:

1. **Phishing personalizado**: Enviar emails mencionando sitios donde tenés cuenta
2. **Ingeniería social**: Usar info de reviews/redes para ganar tu confianza
3. **Credential stuffing**: Si un password fue filtrado, probarlo en otros sitios

## Uso ético

Estas herramientas son para:
- ✅ Verificar tu propia exposición
- ✅ Auditorías de seguridad autorizadas
- ✅ Investigación con consentimiento
- ❌ NO para stalking o acoso
- ❌ NO para acceder a cuentas ajenas

## Powered by FK94 Security

[fk94security.com](https://fk94security.com)
