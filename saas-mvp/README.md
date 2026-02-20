# FK94 Monitor - SaaS MVP (Local Demo)

This folder contains a local, static MVP demo for the FK94 Monitoring SaaS.

## What's Included
- `index.html` � marketing landing for the SaaS MVP
- `app.html` � demo dashboard (client-side only)
- `styles.css` � shared styles
- `app.js` � local state + demo logic (localStorage)

## How to Run
Open `index.html` in your browser, then click **Open Demo App**.

## What It Demonstrates
- Onboarding/login flow (local demo)
- Assets (domains/emails) management
- Alerts table with severity
- Report generation
- Billing plan switch

## Next Steps (Production)
- Replace demo login with real auth (Clerk/Supabase)
- Store data in Postgres
- Add HIBP API integration for alerts
- Add Stripe subscriptions
- Add background jobs for daily checks
