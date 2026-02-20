const STORAGE_KEY = 'fk94_saas_mvp';

const defaultState = {
    user: null,
    plan: 'personal',
    assets: [
        { name: 'Primary Email', type: 'email', value: 'founder@fk94security.com', status: 'Monitored' },
        { name: 'Main Domain', type: 'domain', value: 'fk94security.com', status: 'Monitored' },
        { name: 'Support Email', type: 'email', value: 'info@fk94security.com', status: 'Monitored' }
    ],
    alerts: [
        { type: 'Breach', severity: 'High', summary: 'New breach detected for 2 accounts', date: 'Today' },
        { type: 'DNS', severity: 'Medium', summary: 'DMARC missing on fk94security.com', date: 'Today' }
    ]
};

function loadState() {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (!saved) return { ...defaultState };
    try {
        return { ...defaultState, ...JSON.parse(saved) };
    } catch {
        return { ...defaultState };
    }
}

function saveState(state) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
}

let state = loadState();

const loginView = document.getElementById('loginView');
const appView = document.getElementById('appView');

function showApp() {
    loginView.style.display = 'none';
    appView.style.display = 'grid';
    hydrateUI();
}

function showLogin() {
    loginView.style.display = 'block';
    appView.style.display = 'none';
}

function hydrateUI() {
    document.getElementById('planLabel').textContent = state.plan === 'business'
        ? 'Business Monitor'
        : 'Personal Monitor';
    document.getElementById('planSelect').value = state.plan;
    document.getElementById('scoreValue').innerHTML = state.plan === 'business'
        ? '82<span>/100</span>'
        : '72<span>/100</span>';
    document.getElementById('alertCount').innerHTML = `${state.alerts.length}<span> alerts</span>`;
    document.getElementById('assetCount').innerHTML = `${state.assets.length}<span> assets</span>`;
    renderAssets();
    renderAlerts();
    if (state.user) {
        document.getElementById('settingsName').value = state.user.name || '';
        document.getElementById('settingsEmail').value = state.user.email || '';
    }
}

function renderAssets() {
    const tbody = document.querySelector('#assetsTable tbody');
    tbody.innerHTML = '';
    state.assets.forEach(asset => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td>${asset.name}</td>
            <td>${asset.type}</td>
            <td>${asset.value}</td>
            <td><span class="tag">${asset.status}</span></td>
        `;
        tbody.appendChild(tr);
    });
}

function renderAlerts() {
    const tbody = document.querySelector('#alertsTable tbody');
    tbody.innerHTML = '';
    state.alerts.forEach(alert => {
        const tr = document.createElement('tr');
        const severityClass = alert.severity === 'High'
            ? 'danger'
            : alert.severity === 'Medium'
                ? 'warning'
                : '';
        tr.innerHTML = `
            <td>${alert.type}</td>
            <td><span class="tag ${severityClass}">${alert.severity}</span></td>
            <td>${alert.summary}</td>
            <td>${alert.date}</td>
        `;
        tbody.appendChild(tr);
    });
}

function registerNav() {
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', () => {
            document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
            document.querySelectorAll('.panel').forEach(panel => panel.classList.remove('active'));
            item.classList.add('active');
            document.getElementById(`panel-${item.dataset.panel}`).classList.add('active');
        });
    });
}

function registerActions() {
    document.getElementById('loginBtn').addEventListener('click', () => {
        const name = document.getElementById('loginName').value.trim() || 'Demo User';
        const email = document.getElementById('loginEmail').value.trim() || 'demo@fk94security.com';
        const plan = document.getElementById('loginPlan').value;
        state.user = { name, email };
        state.plan = plan;
        saveState(state);
        showApp();
    });

    document.getElementById('logoutBtn').addEventListener('click', () => {
        state.user = null;
        saveState(state);
        showLogin();
    });

    document.getElementById('addAssetBtn').addEventListener('click', () => {
        const name = document.getElementById('assetName').value.trim();
        const value = document.getElementById('assetValue').value.trim();
        if (!name || !value) return;
        const type = value.includes('@') ? 'email' : 'domain';
        state.assets.push({ name, type, value, status: 'Monitored' });
        document.getElementById('assetName').value = '';
        document.getElementById('assetValue').value = '';
        saveState(state);
        hydrateUI();
    });

    document.getElementById('generateReportBtn').addEventListener('click', () => {
        const now = new Date().toLocaleDateString();
        const report = [
            'FK94 Monitor - Monthly Report',
            `Date: ${now}`,
            '',
            `Plan: ${state.plan === 'business' ? 'Business Monitor' : 'Personal Monitor'}`,
            `Assets monitored: ${state.assets.length}`,
            `Active alerts: ${state.alerts.length}`,
            '',
            'Alerts:',
            ...state.alerts.map(a => `- [${a.severity}] ${a.type}: ${a.summary}`),
            '',
            'Next steps:',
            '- Review breach alerts and rotate exposed passwords.',
            '- Fix DMARC to prevent spoofing.',
            '- Re-run OSINT watchlist next month.'
        ].join('\n');
        document.getElementById('reportOutput').value = report;
    });

    document.getElementById('updatePlanBtn').addEventListener('click', () => {
        state.plan = document.getElementById('planSelect').value;
        saveState(state);
        hydrateUI();
    });

    document.getElementById('saveSettingsBtn').addEventListener('click', () => {
        const name = document.getElementById('settingsName').value.trim();
        const email = document.getElementById('settingsEmail').value.trim();
        state.user = { name, email };
        saveState(state);
    });
}

if (state.user) {
    showApp();
} else {
    showLogin();
}

registerNav();
registerActions();
