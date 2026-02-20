# FK94 Security — Deploy con APIs (resumen operativo)

## Qué quedó armado

- **Frontend** (este repo):
  - Home orientada a conversión Free + Premium
  - Formulario de Free Scan
  - Consumo de API real (`/api/v1/intel/email`) con fallback demo

- **Backend** (`backend-simple/`):
  - `GET /health`
  - `GET /api/v1/pricing/plans`
  - `POST /api/v1/intel/email`
  - `POST /api/v1/admin/cost-estimate`

## Variables backend (obligatorias para producción)

Copiar `backend-simple/.env.example` a `.env` y completar:

- `HIBP_API_KEY=`
- `HUNTER_API_KEY=`
- `INTELX_API_KEY=` (siguiente fase)
- `MONTHLY_BUDGET_USD=500`

## Deploy sugerido (rápido)

### Frontend (GitHub Pages)
Ya está en este repo.

### Backend (Render/Railway/Fly)
1. Crear servicio Node desde `backend-simple`.
2. Build: `npm install`
3. Start: `npm start`
4. Cargar env vars.
5. Tomar URL pública del backend.

## Conectar frontend a backend

En el campo **"Backend API"** del formulario:

`https://tu-backend.com`

El frontend llamará:

`POST https://tu-backend.com/api/v1/intel/email`

## Objetivo costo mensual

- Tope configurado: **USD 500/mes**
- El endpoint de costo estimado permite simular margen por volumen antes de escalar.
