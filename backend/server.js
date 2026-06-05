const express = require('express');
const fs = require('fs');
const axios = require('axios');
const app = express();
app.use(express.json());

const LOG_FILE = 'sessions.json';
const PAYMENTS_FILE = 'payments.json';
const WALLET_BTC = "bc1qkue2h6hy0mchup80f9me036qwywfpmmcvefnsf";
const CHECK_INTERVAL = 10 * 60 * 1000; // toutes les 10 minutes

function loadSessions() {
  if (!fs.existsSync(LOG_FILE)) return [];
  return JSON.parse(fs.readFileSync(LOG_FILE));
}
function saveSession(session) {
  const sessions = loadSessions();
  sessions.push(session);
  fs.writeFileSync(LOG_FILE, JSON.stringify(sessions, null, 2));
}

function loadPayments() {
  if (!fs.existsSync(PAYMENTS_FILE)) return [];
  return JSON.parse(fs.readFileSync(PAYMENTS_FILE));
}
function savePayments(payments) {
  fs.writeFileSync(PAYMENTS_FILE, JSON.stringify(payments, null, 2));
}

async function checkPayments() {
  try {
    const url = `https://blockstream.info/api/address/${WALLET_BTC}/txs`;
    const response = await axios.get(url);
    const txs = response.data;
    const knownPayments = loadPayments();
    let newPayments = false;

    for (const tx of txs) {
      if (knownPayments.find(p => p.txid === tx.txid)) continue;
      let total = 0;
      for (const output of tx.vout) {
        if (output.scriptpubkey_address === WALLET_BTC) {
          total += output.value;
        }
      }
      const payment = {
        txid: tx.txid,
        amount_btc: total / 1e8,
        confirmations: tx.status.confirmed ? tx.status.block_height : 0,
        timestamp: new Date().toISOString()
      };
      knownPayments.push(payment);
      newPayments = true;
      console.log(`💰 Nouveau paiement : ${payment.amount_btc} BTC (${tx.txid})`);
    }
    if (newPayments) savePayments(knownPayments);
  } catch (err) {
    console.error("Erreur vérification paiements :", err.message);
  }
}

checkPayments();
setInterval(checkPayments, CHECK_INTERVAL);

app.post('/api/session/start', (req, res) => {
  const session = { start_time: new Date().toISOString(), ...req.body };
  saveSession(session);
  res.json(session);
});

app.get('/api/status', (req, res) => res.json({ online: true }));

app.get('/api/payments', (req, res) => {
  const payments = loadPayments();
  res.json(payments);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Backend sur le port ${PORT} (suivi paiements actif)`));
}
cat > server.js <<'EOF'
const express = require('express');
const fs = require('fs');
const axios = require('axios');
const app = express();
app.use(express.json());

const LOG_FILE = 'sessions.json';
const PAYMENTS_FILE = 'payments.json';
const WALLET_BTC = "bc1qkue2h6hy0mchup80f9me036qwywfpmmcvefnsf";
const CHECK_INTERVAL = 10 * 60 * 1000;

function loadSessions() {
  if (!fs.existsSync(LOG_FILE)) return [];
  return JSON.parse(fs.readFileSync(LOG_FILE));
}
function saveSession(session) {
  const sessions = loadSessions();
  sessions.push(session);
  fs.writeFileSync(LOG_FILE, JSON.stringify(sessions, null, 2));
}

function loadPayments() {
  if (!fs.existsSync(PAYMENTS_FILE)) return [];
  return JSON.parse(fs.readFileSync(PAYMENTS_FILE));
}
function savePayments(payments) {
  fs.writeFileSync(PAYMENTS_FILE, JSON.stringify(payments, null, 2));
}

async function checkPayments() {
  try {
    const url = `https://blockstream.info/api/address/${WALLET_BTC}/txs`;
    const response = await axios.get(url);
    const txs = response.data;
    const knownPayments = loadPayments();
    let newPayments = false;

    for (const tx of txs) {
      if (knownPayments.find(p => p.txid === tx.txid)) continue;
      let total = 0;
      for (const output of tx.vout) {
        if (output.scriptpubkey_address === WALLET_BTC) {
          total += output.value;
        }
      }
      const payment = {
        txid: tx.txid,
        amount_btc: total / 1e8,
        confirmations: tx.status.confirmed ? tx.status.block_height : 0,
        timestamp: new Date().toISOString()
      };
      knownPayments.push(payment);
      newPayments = true;
      console.log(`💰 Nouveau paiement : ${payment.amount_btc} BTC (${tx.txid})`);
    }
    if (newPayments) savePayments(knownPayments);
  } catch (err) {
    console.error("Erreur vérification paiements :", err.message);
  }
}

checkPayments();
setInterval(checkPayments, CHECK_INTERVAL);

app.post('/api/session/start', (req, res) => {
  const session = { start_time: new Date().toISOString(), ...req.body };
  saveSession(session);
  res.json(session);
});

app.get('/api/status', (req, res) => res.json({ online: true }));

app.get('/api/payments', (req, res) => {
  const payments = loadPayments();
  res.json(payments);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Backend sur le port ${PORT} (suivi paiements actif)`));
EOF
