require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3000;

const MONTHLY_BUDGET_USD = Number(process.env.MONTHLY_BUDGET_USD || 500);

const COSTS = {
  hibpPerCall: Number(process.env.COST_HIBP_PER_CALL || 0.0025),
  hunterPerCall: Number(process.env.COST_HUNTER_PER_CALL || 0.01),
  intelxPerCall: Number(process.env.COST_INTELX_PER_CALL || 0.04),
};

const RESELLER_PLANS = {
  free: {
    priceUsd: 0,
    includes: 'Breach basic + score',
    monthlyLimit: 50,
  },
  starter: {
    priceUsd: 19,
    includes: 'Breach + email/domain signals',
    monthlyLimit: 400,
  },
  pro: {
    priceUsd: 79,
    includes: 'Advanced intelligence + priority',
    monthlyLimit: 2500,
  },
  doneForYou: {
    priceUsd: 299,
    includes: 'Manual analysis + action plan',
    monthlyLimit: 10000,
  },
};

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));

function isValidEmail(email) {
  return typeof email === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function domainFromEmail(email) {
  return email.split('@')[1]?.toLowerCase() || null;
}

function buildCostEstimate({ hibpCalls = 0, hunterCalls = 0, intelxCalls = 0 }) {
  const total =
    hibpCalls * COSTS.hibpPerCall +
    hunterCalls * COSTS.hunterPerCall +
    intelxCalls * COSTS.intelxPerCall;

  return {
    hibpCalls,
    hunterCalls,
    intelxCalls,
    costBreakdownUsd: {
      hibp: Number((hibpCalls * COSTS.hibpPerCall).toFixed(4)),
      hunter: Number((hunterCalls * COSTS.hunterPerCall).toFixed(4)),
      intelx: Number((intelxCalls * COSTS.intelxPerCall).toFixed(4)),
    },
    estimatedTotalUsd: Number(total.toFixed(4)),
    monthlyBudgetUsd: MONTHLY_BUDGET_USD,
    budgetRemainingUsd: Number((MONTHLY_BUDGET_USD - total).toFixed(4)),
  };
}

async function hibpLookup(email) {
  if (!process.env.HIBP_API_KEY) {
    return { enabled: false, reason: 'HIBP_API_KEY missing' };
  }

  const hibp = axios.create({
    baseURL: 'https://haveibeenpwned.com/api/v3',
    headers: {
      'User-Agent': 'FK94-Security-Monitor',
      'hibp-api-key': process.env.HIBP_API_KEY,
    },
    timeout: 12000,
  });

  try {
    const response = await hibp
      .get(`/breachedaccount/${encodeURIComponent(email)}?truncateResponse=false`)
      .catch((err) => {
        if (err.response?.status === 404) return { data: [] };
        if (err.response?.status === 429) throw new Error('HIBP_RATE_LIMITED');
        throw err;
      });

    const breaches = response.data || [];
    return {
      enabled: true,
      breachCount: breaches.length,
      breaches: breaches.map((b) => ({
        name: b.Name,
        title: b.Title,
        date: b.BreachDate,
        pwnCount: b.PwnCount,
        dataClasses: b.DataClasses,
        verified: b.IsVerified,
      })),
    };
  } catch (error) {
    return { enabled: true, error: error.message };
  }
}

async function hunterDomainSignals(domain) {
  if (!process.env.HUNTER_API_KEY) {
    return { enabled: false, reason: 'HUNTER_API_KEY missing' };
  }

  try {
    const { data } = await axios.get('https://api.hunter.io/v2/domain-search', {
      params: {
        domain,
        api_key: process.env.HUNTER_API_KEY,
      },
      timeout: 12000,
    });

    return {
      enabled: true,
      organization: data?.data?.organization || null,
      disposable: data?.data?.disposable || false,
      webmail: data?.data?.webmail || false,
      emailPatterns: data?.data?.pattern || null,
      confidence: data?.data?.confidence || null,
      sampleEmails: (data?.data?.emails || []).slice(0, 3).map((e) => ({
        value: e.value,
        confidence: e.confidence,
        type: e.type,
      })),
    };
  } catch (error) {
    return { enabled: true, error: error.message };
  }
}

function computeRiskScore({ hibp, hunter }) {
  let score = 0;

  if (hibp?.enabled && !hibp.error) {
    score += Math.min(hibp.breachCount * 15, 70);
  }

  if (hunter?.enabled && !hunter.error) {
    if (hunter.webmail) score += 8;
    if (hunter.disposable) score += 20;
    if ((hunter.sampleEmails || []).length > 0) score += 10;
  }

  return Math.min(score, 100);
}

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    budget: { monthlyBudgetUsd: MONTHLY_BUDGET_USD },
  });
});

app.get('/api/v1/pricing/plans', (req, res) => {
  res.json({
    success: true,
    budget: {
      monthlyBudgetUsd: MONTHLY_BUDGET_USD,
      providerCostsUsd: COSTS,
    },
    plans: RESELLER_PLANS,
  });
});

app.post('/api/v1/intel/email', async (req, res) => {
  const email = req.body?.email?.trim().toLowerCase();
  if (!isValidEmail(email)) {
    return res.status(400).json({ success: false, error: 'Valid email required' });
  }

  const domain = domainFromEmail(email);

  const [hibp, hunter] = await Promise.all([
    hibpLookup(email),
    hunterDomainSignals(domain),
  ]);

  const riskScore = computeRiskScore({ hibp, hunter });

  const estimate = buildCostEstimate({
    hibpCalls: hibp.enabled ? 1 : 0,
    hunterCalls: hunter.enabled ? 1 : 0,
    intelxCalls: 0,
  });

  return res.json({
    success: true,
    data: {
      email,
      domain,
      providers: { hibp, hunter },
      riskScore,
      recommendation:
        riskScore >= 70
          ? 'Riesgo alto: recomendar plan Done-For-You + hardening inmediato.'
          : riskScore >= 35
          ? 'Riesgo medio: recomendar plan Pro y seguimiento mensual.'
          : 'Riesgo bajo: ofrecer plan Starter y checklist preventivo.',
      estimatedProviderCostUsd: estimate,
      scannedAt: new Date().toISOString(),
    },
  });
});

app.post('/api/v1/admin/cost-estimate', (req, res) => {
  const { hibpCalls = 0, hunterCalls = 0, intelxCalls = 0 } = req.body || {};
  return res.json({
    success: true,
    estimate: buildCostEstimate({ hibpCalls, hunterCalls, intelxCalls }),
  });
});

app.get('/api/v1/demo', (req, res) => {
  const estimate = buildCostEstimate({ hibpCalls: 1, hunterCalls: 1, intelxCalls: 0 });
  res.json({
    success: true,
    data: {
      email: 'demo@fk94security.com',
      riskScore: 62,
      recommendation: 'Riesgo medio-alto: mover a plan Pro con upsell Done-For-You.',
      estimatedProviderCostUsd: estimate,
      suggestedResellPlan: RESELLER_PLANS.pro,
    },
  });
});

app.use('*', (req, res) => {
  res.status(404).json({ error: 'Not found' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Health: http://localhost:${PORT}/health`);
  console.log(`Pricing: http://localhost:${PORT}/api/v1/pricing/plans`);
  console.log(`Intel API: POST http://localhost:${PORT}/api/v1/intel/email`);
});
