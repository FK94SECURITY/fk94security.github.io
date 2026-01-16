# VIGIA OSINT Tools

Open Source Intelligence (OSINT) tools to check your digital exposure.

## Tools

### 1. Username Search (`username-search.sh`)

Searches for a username across 30+ platforms to see where that account exists.

```bash
./username-search.sh johndoe
```

**Platforms checked:**
- Social media: Twitter, Instagram, TikTok, Facebook, LinkedIn, Reddit, Pinterest
- Development: GitHub, GitLab, Stack Overflow, CodePen, Dev.to
- Gaming: Steam, Twitch, Xbox, Roblox
- Multimedia: YouTube, Spotify, SoundCloud, Vimeo, Medium
- Others: Gravatar, Keybase, Patreon, Telegram

### 2. Email Intelligence (`email-intel.sh`)

Analyzes the exposure of an email and creates a risk profile.

```bash
./email-intel.sh john@gmail.com
```

**What does it do?**
- Checks if it has a Gravatar (global profile picture)
- Searches for accounts associated with the email's username
- Analyzes the email domain
- Generates Google Dorks for manual research
- Creates a report with recommendations

## Why is this important?

An attacker can use this information for:

1. **Personalized phishing**: Sending emails mentioning sites where you have an account
2. **Social engineering**: Using info from reviews/social networks to gain your trust
3. **Credential stuffing**: If a password was leaked, trying it on other sites

## Ethical Use

These tools are for:
- Checking your own exposure
- Authorized security audits
- Research with consent
- NOT for stalking or harassment
- NOT for accessing other people's accounts

## Powered by FK94 Security

[fk94security.com](https://fk94security.com)
