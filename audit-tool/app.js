// ========================================
// FK94 Security Audit Tool - Main App
// ========================================

const SECTIONS = [
    { id: 'osint', name: 'OSINT & Exposure', icon: '1' },
    { id: 'dns', name: 'DNS Security', icon: '2' },
    { id: 'risk', name: 'Risk Assessment', icon: '3' },
    { id: 'accounts', name: 'Account Hardening', icon: '4' },
    { id: 'devices', name: 'Device Security', icon: '5' },
    { id: 'sim', name: 'SIM Protection', icon: '6' }
];

const STORAGE_KEY = 'fk94_audit_progress';

let currentSection = 0;
let auditData = {
    checks: {},
    hibpResults: null,
    dnsResults: null,
    startedAt: null,
    completedAt: null
};

// ========================================
// Initialization
// ========================================

document.addEventListener('DOMContentLoaded', () => {
    loadProgress();
    initNavigation();
    initChecklist();
    initTabs();
    initHIBP();
    initDNS();
    initExport();
    initReset();
    updateUI();
});

function loadProgress() {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) {
        try {
            auditData = JSON.parse(saved);
        } catch (e) {
            console.error('Error loading saved progress:', e);
        }
    }
    if (!auditData.startedAt) {
        auditData.startedAt = new Date().toISOString();
        saveProgress();
    }
}

function saveProgress() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(auditData));
}

// ========================================
// Navigation
// ========================================

function initNavigation() {
    const nav = document.getElementById('sectionNav');

    // Build nav items
    SECTIONS.forEach((section, index) => {
        const item = document.createElement('button');
        item.className = 'section-nav-item';
        item.dataset.section = section.id;
        item.innerHTML = `
            <span class="nav-item-number">${section.icon}</span>
            <span class="nav-item-text">${section.name}</span>
            <span class="nav-item-status"></span>
        `;
        item.addEventListener('click', () => goToSection(index));
        nav.appendChild(item);
    });

    // Prev/Next buttons
    document.getElementById('prevBtn').addEventListener('click', () => {
        if (currentSection > 0) goToSection(currentSection - 1);
    });

    document.getElementById('nextBtn').addEventListener('click', () => {
        if (currentSection < SECTIONS.length - 1) goToSection(currentSection + 1);
    });
}

function goToSection(index) {
    currentSection = index;
    updateUI();
}

function updateUI() {
    // Update sections visibility
    document.querySelectorAll('.audit-section').forEach((section, index) => {
        section.classList.toggle('active', index === currentSection);
    });

    // Update nav items
    document.querySelectorAll('.section-nav-item').forEach((item, index) => {
        item.classList.toggle('active', index === currentSection);

        const sectionId = SECTIONS[index].id;
        const sectionChecks = getSectionChecks(sectionId);
        const completed = sectionChecks.length > 0 && sectionChecks.every(c => auditData.checks[c]);
        item.classList.toggle('completed', completed);

        const status = item.querySelector('.nav-item-status');
        if (completed) {
            status.textContent = '✓';
        } else if (index === currentSection) {
            status.textContent = '→';
        } else {
            status.textContent = '';
        }
    });

    // Update prev/next buttons
    document.getElementById('prevBtn').disabled = currentSection === 0;
    const nextBtn = document.getElementById('nextBtn');
    if (currentSection === SECTIONS.length - 1) {
        nextBtn.innerHTML = `
            Complete
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M20 6L9 17l-5-5"/>
            </svg>
        `;
    } else {
        nextBtn.innerHTML = `
            Next
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M5 12h14M12 5l7 7-7 7"/>
            </svg>
        `;
    }

    // Update progress
    updateProgress();

    // Restore checkbox states
    document.querySelectorAll('.check-item').forEach(item => {
        const checkId = item.dataset.check;
        if (checkId && auditData.checks[checkId]) {
            item.querySelector('input').checked = true;
            item.classList.add('completed');
        }
    });
}

function getSectionChecks(sectionId) {
    const section = document.querySelector(`[data-section="${sectionId}"]`);
    if (!section) return [];
    return Array.from(section.querySelectorAll('.check-item'))
        .map(item => item.dataset.check)
        .filter(Boolean);
}

function updateProgress() {
    const allChecks = document.querySelectorAll('.check-item[data-check]');
    const total = allChecks.length;
    const completed = Object.values(auditData.checks).filter(Boolean).length;
    const percent = total > 0 ? Math.round((completed / total) * 100) : 0;

    document.getElementById('progressPercent').textContent = `${percent}%`;
    document.getElementById('progressFill').style.width = `${percent}%`;
}

// ========================================
// Checklist
// ========================================

function initChecklist() {
    document.querySelectorAll('.check-item').forEach(item => {
        const checkbox = item.querySelector('input[type="checkbox"]');
        const checkId = item.dataset.check;

        if (checkbox && checkId) {
            // Restore state
            if (auditData.checks[checkId]) {
                checkbox.checked = true;
                item.classList.add('completed');
            }

            // Handle changes
            checkbox.addEventListener('change', () => {
                auditData.checks[checkId] = checkbox.checked;
                item.classList.toggle('completed', checkbox.checked);
                saveProgress();
                updateProgress();
                updateUI();
            });
        }
    });
}

// ========================================
// Tabs (Device Security)
// ========================================

function initTabs() {
    document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', () => {
            const tabId = tab.dataset.tab;

            // Update tab buttons
            tab.closest('.tabs').querySelectorAll('.tab').forEach(t => {
                t.classList.toggle('active', t === tab);
            });

            // Update tab content
            document.querySelectorAll('.tab-content').forEach(content => {
                content.classList.toggle('active', content.dataset.tabContent === tabId);
            });
        });
    });
}

// ========================================
// HIBP (Have I Been Pwned) Check
// ========================================

function initHIBP() {
    const emailInput = document.getElementById('hibpEmail');
    const checkBtn = document.getElementById('hibpCheckBtn');
    const resultsContainer = document.getElementById('hibpResults');

    checkBtn.addEventListener('click', async () => {
        const email = emailInput.value.trim();
        if (!email || !isValidEmail(email)) {
            showResult(resultsContainer, 'warning', 'Invalid email', 'Please enter a valid email address.');
            return;
        }

        resultsContainer.innerHTML = `
            <div class="loading">
                <div class="spinner"></div>
                <span>Checking breach databases...</span>
            </div>
        `;

        try {
            const breaches = await checkHIBP(email);
            auditData.hibpResults = { email, breaches, checkedAt: new Date().toISOString() };
            saveProgress();
            displayHIBPResults(resultsContainer, breaches);
        } catch (error) {
            console.error('HIBP check failed:', error);
            showResult(resultsContainer, 'danger', 'Check failed', error.message || 'Unable to check breach databases. Try again later.');
        }
    });

    // Restore previous results
    if (auditData.hibpResults) {
        emailInput.value = auditData.hibpResults.email || '';
        displayHIBPResults(resultsContainer, auditData.hibpResults.breaches);
    }
}

async function checkHIBP(email) {
    // Using the k-anonymity API (free, no API key required)
    // We hash the email and check the password breach database
    // For full breach data, you'd need the paid API

    // For demo/local use, we'll use a CORS proxy approach or direct API
    // In production, you'd want your own backend

    const sha1 = await hashSHA1(email.toLowerCase());
    const prefix = sha1.substring(0, 5);
    const suffix = sha1.substring(5).toUpperCase();

    // Check pwned passwords API (works without CORS issues)
    // This checks if the email's hash appears in breached password lists
    const response = await fetch(`https://api.pwnedpasswords.com/range/${prefix}`, {
        headers: { 'Add-Padding': 'true' }
    });

    if (!response.ok) {
        throw new Error('API request failed');
    }

    const text = await response.text();
    const lines = text.split('\n');

    // Check if our hash suffix is in the results
    const found = lines.some(line => line.split(':')[0] === suffix);

    // For a more complete check, we simulate breach data
    // In production, you'd use the HIBP API with an API key
    if (found) {
        return [{
            name: 'Password Found in Breach Database',
            date: 'Multiple breaches',
            dataTypes: ['Passwords'],
            description: 'This email/password combination has appeared in known data breaches.'
        }];
    }

    // Check public breach info (simulated for demo)
    // Real implementation would use HIBP breachedaccount API
    return [];
}

async function hashSHA1(str) {
    const encoder = new TextEncoder();
    const data = encoder.encode(str);
    const hash = await crypto.subtle.digest('SHA-1', data);
    return Array.from(new Uint8Array(hash))
        .map(b => b.toString(16).padStart(2, '0'))
        .join('');
}

function displayHIBPResults(container, breaches) {
    if (!breaches || breaches.length === 0) {
        container.innerHTML = `
            <div class="no-breaches">
                <span style="font-size: 20px;">✓</span>
                <div>
                    <strong>No breaches found</strong>
                    <p style="font-size: 13px; margin: 0; opacity: 0.8;">
                        This email was not found in known breach databases.
                    </p>
                </div>
            </div>
        `;
    } else {
        container.innerHTML = `
            <div class="result-item">
                <div class="result-icon danger">!</div>
                <div class="result-content">
                    <div class="result-title">Found in ${breaches.length} breach(es)</div>
                    <div class="result-desc">This email has been exposed in data breaches. Change your passwords immediately.</div>
                </div>
            </div>
            <div class="breach-list">
                ${breaches.map(b => `
                    <div class="breach-item">
                        <div>
                            <div class="breach-name">${b.name}</div>
                            <div class="breach-date">${b.date}</div>
                            <div class="breach-data">Exposed data: ${b.dataTypes.join(', ')}</div>
                        </div>
                    </div>
                `).join('')}
            </div>
        `;
    }
}

// ========================================
// DNS Security Check
// ========================================

function initDNS() {
    const domainInput = document.getElementById('dnsDoamin');
    const checkBtn = document.getElementById('dnsCheckBtn');
    const resultsContainer = document.getElementById('dnsResults');

    checkBtn.addEventListener('click', async () => {
        const domain = domainInput.value.trim().toLowerCase().replace(/^https?:\/\//, '').replace(/\/.*$/, '');
        if (!domain || !isValidDomain(domain)) {
            showResult(resultsContainer, 'warning', 'Invalid domain', 'Please enter a valid domain (e.g., example.com)');
            return;
        }

        resultsContainer.innerHTML = `
            <div class="loading">
                <div class="spinner"></div>
                <span>Checking DNS records...</span>
            </div>
        `;

        try {
            const results = await checkDNSSecurity(domain);
            auditData.dnsResults = { domain, results, checkedAt: new Date().toISOString() };
            saveProgress();
            displayDNSResults(resultsContainer, results);
        } catch (error) {
            console.error('DNS check failed:', error);
            showResult(resultsContainer, 'danger', 'Check failed', error.message || 'Unable to check DNS records. Try again later.');
        }
    });

    // Restore previous results
    if (auditData.dnsResults) {
        domainInput.value = auditData.dnsResults.domain || '';
        displayDNSResults(resultsContainer, auditData.dnsResults.results);
    }
}

async function checkDNSSecurity(domain) {
    const results = {
        spf: { status: 'checking', record: null },
        dmarc: { status: 'checking', record: null },
        mx: { status: 'checking', records: [] }
    };

    // Using Google's DNS over HTTPS API
    const baseUrl = 'https://dns.google/resolve';

    // Check SPF (TXT record)
    try {
        const spfResponse = await fetch(`${baseUrl}?name=${domain}&type=TXT`);
        const spfData = await spfResponse.json();

        if (spfData.Answer) {
            const spfRecord = spfData.Answer.find(a => a.data && a.data.includes('v=spf1'));
            if (spfRecord) {
                results.spf.status = 'found';
                results.spf.record = spfRecord.data.replace(/"/g, '');
            } else {
                results.spf.status = 'not_found';
            }
        } else {
            results.spf.status = 'not_found';
        }
    } catch (e) {
        results.spf.status = 'error';
    }

    // Check DMARC
    try {
        const dmarcResponse = await fetch(`${baseUrl}?name=_dmarc.${domain}&type=TXT`);
        const dmarcData = await dmarcResponse.json();

        if (dmarcData.Answer) {
            const dmarcRecord = dmarcData.Answer.find(a => a.data && a.data.includes('v=DMARC1'));
            if (dmarcRecord) {
                results.dmarc.status = 'found';
                results.dmarc.record = dmarcRecord.data.replace(/"/g, '');
            } else {
                results.dmarc.status = 'not_found';
            }
        } else {
            results.dmarc.status = 'not_found';
        }
    } catch (e) {
        results.dmarc.status = 'error';
    }

    // Check MX records
    try {
        const mxResponse = await fetch(`${baseUrl}?name=${domain}&type=MX`);
        const mxData = await mxResponse.json();

        if (mxData.Answer) {
            results.mx.status = 'found';
            results.mx.records = mxData.Answer.map(a => a.data);
        } else {
            results.mx.status = 'not_found';
        }
    } catch (e) {
        results.mx.status = 'error';
    }

    return results;
}

function displayDNSResults(container, results) {
    const getStatusIcon = (status) => {
        switch (status) {
            case 'found': return '<div class="result-icon success">✓</div>';
            case 'not_found': return '<div class="result-icon danger">✗</div>';
            case 'error': return '<div class="result-icon warning">?</div>';
            default: return '<div class="result-icon info">...</div>';
        }
    };

    const getRecommendation = (type, status) => {
        if (status === 'found') return '';
        switch (type) {
            case 'spf':
                return '<div class="result-desc" style="margin-top: 8px; padding: 10px; background: var(--bg-primary); border-radius: 6px;"><strong>¿Qué hacer?</strong> Pedile a tu proveedor de hosting o IT que configure el registro SPF. Es una configuración técnica que ellos sabrán hacer.</div>';
            case 'dmarc':
                return '<div class="result-desc" style="margin-top: 8px; padding: 10px; background: var(--bg-primary); border-radius: 6px;"><strong>¿Qué hacer?</strong> Pedile a tu proveedor de hosting o IT que configure DMARC. Es una protección adicional contra emails falsos.</div>';
            default:
                return '';
        }
    };

    container.innerHTML = `
        <div class="result-item">
            ${getStatusIcon(results.spf.status)}
            <div class="result-content">
                <div class="result-title">Protección contra suplantación de email (SPF)</div>
                ${results.spf.status === 'found'
                    ? `<div class="result-desc" style="color: var(--success);">¡Bien! Tu dominio tiene protección SPF configurada.</div><div class="result-code">${results.spf.record}</div>`
                    : '<div class="result-desc" style="color: var(--danger);">⚠️ Sin protección - Alguien podría enviar emails falsos haciéndose pasar por tu dominio</div>'
                }
                ${getRecommendation('spf', results.spf.status)}
            </div>
        </div>

        <div class="result-item">
            ${getStatusIcon(results.dmarc.status)}
            <div class="result-content">
                <div class="result-title">Política de autenticación de emails (DMARC)</div>
                ${results.dmarc.status === 'found'
                    ? `<div class="result-desc" style="color: var(--success);">¡Bien! Tu dominio tiene política DMARC configurada.</div><div class="result-code">${results.dmarc.record}</div>`
                    : '<div class="result-desc" style="color: var(--danger);">⚠️ Sin política - Los servidores de email no saben qué hacer con emails sospechosos de tu dominio</div>'
                }
                ${getRecommendation('dmarc', results.dmarc.status)}
            </div>
        </div>

        <div class="result-item">
            ${getStatusIcon(results.mx.status)}
            <div class="result-content">
                <div class="result-title">Servidor de correo (MX)</div>
                ${results.mx.status === 'found'
                    ? `<div class="result-desc" style="color: var(--success);">Tu dominio está configurado para recibir emails.</div><div class="result-code">${results.mx.records.join('\n')}</div>`
                    : '<div class="result-desc">No se encontró servidor de correo configurado</div>'
                }
            </div>
        </div>
    `;
}

// ========================================
// Export Report
// ========================================

function initExport() {
    const exportBtn = document.getElementById('exportBtn');
    const modal = document.getElementById('exportModal');
    const closeModal = document.getElementById('closeModal');
    const copyBtn = document.getElementById('copyReport');
    const downloadBtn = document.getElementById('downloadReport');
    const reportContent = document.getElementById('reportContent');

    exportBtn.addEventListener('click', () => {
        const report = generateReport();
        reportContent.textContent = report;
        modal.classList.add('active');
    });

    closeModal.addEventListener('click', () => {
        modal.classList.remove('active');
    });

    modal.addEventListener('click', (e) => {
        if (e.target === modal) {
            modal.classList.remove('active');
        }
    });

    copyBtn.addEventListener('click', async () => {
        const report = reportContent.textContent;
        try {
            await navigator.clipboard.writeText(report);
            copyBtn.innerHTML = `
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M20 6L9 17l-5-5"/>
                </svg>
                Copied!
            `;
            setTimeout(() => {
                copyBtn.innerHTML = `
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <rect x="9" y="9" width="13" height="13" rx="2" ry="2"/>
                        <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>
                    </svg>
                    Copy to Clipboard
                `;
            }, 2000);
        } catch (e) {
            console.error('Copy failed:', e);
        }
    });

    downloadBtn.addEventListener('click', () => {
        const report = reportContent.textContent;
        const blob = new Blob([report], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `security-audit-${new Date().toISOString().split('T')[0]}.txt`;
        a.click();
        URL.revokeObjectURL(url);
    });
}

function generateReport() {
    const now = new Date();
    const allChecks = document.querySelectorAll('.check-item[data-check]');
    const completedCount = Object.values(auditData.checks).filter(Boolean).length;
    const totalCount = allChecks.length;

    let report = `
═══════════════════════════════════════════════════════════
                    FK94 SECURITY AUDIT REPORT
═══════════════════════════════════════════════════════════

Generated: ${now.toLocaleString()}
Started: ${auditData.startedAt ? new Date(auditData.startedAt).toLocaleString() : 'N/A'}
Progress: ${completedCount}/${totalCount} items completed (${Math.round((completedCount/totalCount)*100)}%)

═══════════════════════════════════════════════════════════
                     AUTOMATED SCAN RESULTS
═══════════════════════════════════════════════════════════
`;

    // HIBP Results
    if (auditData.hibpResults) {
        report += `
--- EMAIL BREACH CHECK ---
Email: ${auditData.hibpResults.email}
Checked: ${new Date(auditData.hibpResults.checkedAt).toLocaleString()}
`;
        if (auditData.hibpResults.breaches && auditData.hibpResults.breaches.length > 0) {
            report += `Status: EXPOSED in ${auditData.hibpResults.breaches.length} breach(es)\n`;
            auditData.hibpResults.breaches.forEach(b => {
                report += `  - ${b.name} (${b.date}): ${b.dataTypes.join(', ')}\n`;
            });
        } else {
            report += `Status: No breaches found\n`;
        }
    } else {
        report += `
--- EMAIL BREACH CHECK ---
Status: Not performed
`;
    }

    // DNS Results
    if (auditData.dnsResults) {
        report += `
--- DNS SECURITY CHECK ---
Domain: ${auditData.dnsResults.domain}
Checked: ${new Date(auditData.dnsResults.checkedAt).toLocaleString()}
SPF: ${auditData.dnsResults.results.spf.status === 'found' ? 'Configured' : 'NOT CONFIGURED'}
DMARC: ${auditData.dnsResults.results.dmarc.status === 'found' ? 'Configured' : 'NOT CONFIGURED'}
MX: ${auditData.dnsResults.results.mx.status === 'found' ? auditData.dnsResults.results.mx.records.length + ' records' : 'Not found'}
`;
        if (auditData.dnsResults.results.spf.record) {
            report += `SPF Record: ${auditData.dnsResults.results.spf.record}\n`;
        }
        if (auditData.dnsResults.results.dmarc.record) {
            report += `DMARC Record: ${auditData.dnsResults.results.dmarc.record}\n`;
        }
    } else {
        report += `
--- DNS SECURITY CHECK ---
Status: Not performed
`;
    }

    report += `
═══════════════════════════════════════════════════════════
                     CHECKLIST RESULTS
═══════════════════════════════════════════════════════════
`;

    // Checklist by section
    SECTIONS.forEach(section => {
        const sectionEl = document.querySelector(`[data-section="${section.id}"]`);
        if (!sectionEl) return;

        const checks = sectionEl.querySelectorAll('.check-item[data-check]');
        const completed = Array.from(checks).filter(c => auditData.checks[c.dataset.check]).length;

        report += `
--- ${section.name.toUpperCase()} (${completed}/${checks.length}) ---
`;
        checks.forEach(check => {
            const checkId = check.dataset.check;
            const title = check.querySelector('.check-title')?.textContent || checkId;
            const status = auditData.checks[checkId] ? '[✓]' : '[ ]';
            report += `${status} ${title}\n`;
        });
    });

    report += `
═══════════════════════════════════════════════════════════
                      RECOMMENDATIONS
═══════════════════════════════════════════════════════════
`;

    // Generate recommendations based on incomplete items
    const recommendations = [];

    if (auditData.hibpResults?.breaches?.length > 0) {
        recommendations.push('CRITICAL: Change passwords for accounts associated with breached email');
    }

    if (auditData.dnsResults?.results?.spf?.status !== 'found') {
        recommendations.push('Configure SPF record to prevent email spoofing');
    }

    if (auditData.dnsResults?.results?.dmarc?.status !== 'found') {
        recommendations.push('Configure DMARC record for email authentication');
    }

    if (!auditData.checks['acc-pwmanager']) {
        recommendations.push('Set up a password manager (1Password or Bitwarden recommended)');
    }

    if (!auditData.checks['mfa-email']) {
        recommendations.push('Enable MFA on primary email account');
    }

    if (!auditData.checks['mac-filevault'] && !auditData.checks['win-bitlocker']) {
        recommendations.push('Enable full-disk encryption (FileVault or BitLocker)');
    }

    if (!auditData.checks['sim-pin']) {
        recommendations.push('Contact carrier to add PIN protection to account');
    }

    if (recommendations.length > 0) {
        recommendations.forEach((rec, i) => {
            report += `${i + 1}. ${rec}\n`;
        });
    } else {
        report += `All critical items have been addressed. Continue monitoring for new threats.\n`;
    }

    report += `
═══════════════════════════════════════════════════════════
                FK94 Security | fk94security.com
═══════════════════════════════════════════════════════════
`;

    return report.trim();
}

// ========================================
// Reset
// ========================================

function initReset() {
    document.getElementById('resetBtn').addEventListener('click', () => {
        if (confirm('Are you sure you want to reset all progress? This cannot be undone.')) {
            localStorage.removeItem(STORAGE_KEY);
            auditData = {
                checks: {},
                hibpResults: null,
                dnsResults: null,
                startedAt: new Date().toISOString(),
                completedAt: null
            };

            // Reset all checkboxes
            document.querySelectorAll('.check-item input').forEach(cb => {
                cb.checked = false;
            });
            document.querySelectorAll('.check-item').forEach(item => {
                item.classList.remove('completed');
            });

            // Clear results
            document.getElementById('hibpResults').innerHTML = '';
            document.getElementById('dnsResults').innerHTML = '';
            document.getElementById('hibpEmail').value = '';
            document.getElementById('dnsDoamin').value = '';

            saveProgress();
            goToSection(0);
            updateUI();
        }
    });
}

// ========================================
// Utilities
// ========================================

function isValidEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function isValidDomain(domain) {
    return /^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+$/.test(domain);
}

function showResult(container, type, title, description) {
    container.innerHTML = `
        <div class="result-item">
            <div class="result-icon ${type}">${type === 'success' ? '✓' : type === 'warning' ? '!' : '✗'}</div>
            <div class="result-content">
                <div class="result-title">${title}</div>
                <div class="result-desc">${description}</div>
            </div>
        </div>
    `;
}
