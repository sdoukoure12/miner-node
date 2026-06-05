require('dotenv').config();
const express = require('express');
const fs = require('fs');
const axios = require('axios');
const app = express();
app.use(express.json());

const PAYMENTS_FILE = 'payments.json';
const SESSIONS_FILE = 'sessions.json';
const WALLET_BTC = process.env.WALLET_BTC || "bc1qkue2h6hy0mchup80f9me036qwywfpmmcvefnsf";
const CHECK_INTERVAL = 10 * 60 * 1000;

let Session; // sera soit un modèle Mongoose, soit un objet JSON simulé

// Détection MongoDB
if (process.env.MONGODB_URI) {
  const mongoose = require('mongoose');
  mongoose.connect(process.env.MONGODB_URI);
  const schema = new mongoose.Schema({
    start_time: Date,
    hashrate: Number,
    shares_accepted: Number,
    shares_rejected: Number,
    wallet: String,
    pool: String,
    worker: String
  });
  Session = mongoose.model('Session', schema);
  console.log('Utilisation de MongoDB');
} else {
  // Mode fichier JSON
  function loadSessions() {
    if (!fs.existsSync(SESSIONS_FILE)) return [];
    return JSON.parse(fs.readFileSync(SESSIONS_FILE));
  }
  function saveSessions(sessions) {
    fs.writeFileSync(SESSIONS_FILE, JSON.stringify(sessions, null, 2));
  }
  Session = {
    create: (data) => {
      const sessions = loadSessions();
      const newSession = { ...data, _id: Date.now().toString() };
      sessions.push(newSession);
      saveSessions(sessions);
      return Promise.resolve(newSession);
    },
    find: () => Promise.resolve(loadSessions())
  };
  console.log('Utilisation du stockage JSON (pas de MongoDB)');
}

// Chargement/sauvegarde des paiements (toujours JSON pour simplicité)
function loadPayments() {
  if (!fs.existsSync(PAYMENTS_FILE)) return [];
  return JSON.parse(fs.readFileSync(PAYMENTS_FILE));
}
function savePayments(payments) {
  fs.writeFileSync(PAYMENTS_FILE, JSON.stringify(payments, null, 2));
}

// Vérification des paiements
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
        if (output.scriptpubkey_address === WALLET_BTC) total += output.value;
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

app.post('/api/session/start', async (req, res) => {
  try {
    const session = await Session.create({ start_time: new Date(), ...req.body });
    res.json(session);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/status', (req, res) => res.json({ online: true }));

app.get('/api/payments', (req, res) => {
  const payments = loadPayments();
  res.json(payments);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Backend sur le port ${PORT} (mode ${process.env.MONGODB_URI ? 'MongoDB' : 'JSON'})`));
