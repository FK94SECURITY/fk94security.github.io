require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}));

app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Scan endpoint
app.post('/api/v1/scan', async (req, res) => {
  const { email } = req.body;
  
  if (!email || !email.includes('@')) {
    return res.status(400).json({ success: false, error: 'Valid email required' });
  }

  try {
    const hibp = axios.create({
      baseURL: 'https://haveibeenpwned.com/api/v3',
      headers: {
        'User-Agent': 'FK94-Security-Monitor',
        'hibp-api-key': process.env.HIBP_API_KEY,
      },
      timeout: 10000,
    });

    const normalized = email.trim().toLowerCase();
    
    // Check breaches
    const breachRes = await hibp.get(`/breachedaccount/${encodeURIComponent(normalized)}`)
      .catch(err => {
        if (err.response?.status === 404) return { data: null };
        if (err.response?.status === 429) throw new Error('RATE_LIMITED');
        throw err;
      });

    const breaches = breachRes.data || [];
    
    res.json({
      success: true,
      data: {
        email: normalized,
        isCompromised: breaches.length > 0,
        breachCount: breaches.length,
        breaches: breaches.map(b => ({
          name: b.Name,
          title: b.Title,
          date: b.BreachDate,
          description: b.Description,
          pwnCount: b.PwnCount.toLocaleString(),
          dataClasses: b.DataClasses,
          verified: b.IsVerified,
        })),
        scannedAt: new Date().toISOString(),
      }
    });
    
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Demo endpoint
app.get('/api/v1/demo', (req, res) => {
  res.json({
    success: true,
    data: {
      email: 'demo@fk94security.com',
      breaches: [{
        name: 'LinkedIn',
        title: 'LinkedIn',
        date: '2012-06-06',
        description: '164 million accounts compromised',
        pwnCount: '164,611,595',
      }],
      isCompromised: true,
    }
  });
});

app.use('*', (req, res) => {
  res.status(404).json({ error: 'Not found' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Health: http://localhost:${PORT}/health`);
  console.log(`API: http://localhost:${PORT}/api/v1/scan`);
});
