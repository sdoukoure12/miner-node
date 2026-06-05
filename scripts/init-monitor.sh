#!/bin/bash
# ==============================================
#  Moniteur Autonome de Minage BTC
#  À exécuter UNE fois sur un serveur Ubuntu 20.04/22.04
#  Usage : sudo bash init-monitor.sh
# ==============================================
set -e

# ------ CONFIGURATION (modifie ces variables) ------
WALLET_BTC="bc1qkue2h6hy0mchup80f9me036qwywfpmmcvefnsf"
POOL_URL="stratum+tcp://public-pool.io:3333"
ALGO="sha256d"
WORKER_NAME="worker1"
MINER_PASSWORD="x"
MONGO_URI="mongodb://localhost:27017/miner_logs"
BACKEND_PORT=3000
PROJECT_DIR="/opt/miner-node"
GIT_REPO="https://github.com/sdoukoure12/miner-node.git"   # À adapter si besoin
# --------------------------------------------

echo ">>> [1/8] Mise à jour du système"
apt update && apt upgrade -y

echo ">>> [2/8] Installation des dépendances"
apt install -y git build-essential automake autoconf libtool libcurl4-openssl-dev libjansson-dev libgmp-dev zlib1g-dev libssl-dev
apt install -y mongodb nodejs npm curl wget

echo ">>> [3/8] Compilation et installation de cpuminer"
cd /tmp
rm -rf cpuminer-multi
git clone https://github.com/tpruvot/cpuminer-multi.git
cd cpuminer-multi
./build.sh
cp cpuminer /usr/local/bin/
cd ~
rm -rf /tmp/cpuminer-multi

echo ">>> [4/8] Configuration de MongoDB"
systemctl start mongod || systemctl start mongodb
systemctl enable mongod || systemctl enable mongodb
sleep 5
mongosh --eval "
  use miner_logs;
  db.createCollection('sessions');
  db.sessions.createIndex({ start_time: 1 });
  print('Base de données prête.');
" 2>/dev/null || mongo --eval "use miner_logs; db.createCollection('sessions'); db.sessions.createIndex({ start_time: 1 }); print('Base prête.');"

echo ">>> [5/8] Mise en place du projet"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR
if [ -d ".git" ]; then
    git pull origin main
else
    git clone $GIT_REPO .
fi
# Créer le script de démarrage du mineur
cat > $PROJECT_DIR/scripts/start-miner.sh <<EOF
#!/bin/bash
nohup cpuminer -a $ALGO -o $POOL_URL -u ${WALLET_BTC}.${WORKER_NAME} -p $MINER_PASSWORD --api-bind 0.0.0.0:4048 \
  > /var/log/miner.log 2>&1 &
echo \$! > /var/run/miner.pid
EOF
chmod +x $PROJECT_DIR/scripts/start-miner.sh

echo ">>> [6/8] Lancement permanent du backend (PM2)"
cd $PROJECT_DIR/backend
npm init -y
npm install express mongoose dotenv axios
cat > server.js <<'SERVEREOF'
require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const fs = require('fs');
const axios = require('axios');
const app = express();
app.use(express.json());

const PAYMENTS_FILE = 'payments.json';
const WALLET_BTC = process.env.WALLET_BTC || "bc1qkue2h6hy0mchup80f9me036qwywfpmmcvefnsf";
const CHECK_INTERVAL = 10 * 60 * 1000;

mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/miner_logs');

const SessionSchema = new mongoose.Schema({
  start_time: Date,
  hashrate: Number,
  shares_accepted: Number,
  shares_rejected: Number,
  wallet: String,
  pool: String,
  worker: String
});
const Session = mongoose.model('Session', SessionSchema);

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
  const session = new Session({ start_time: new Date(), ...req.body });
  await session.save();
  res.json(session);
});
app.get('/api/status', (req, res) => res.json({ online: true }));
app.get('/api/payments', (req, res) => {
  const payments = loadPayments();
  res.json(payments);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Backend sur le port ${PORT} (suivi paiements actif)`));
SERVEREOF

cat > .env <<EOF
MONGODB_URI=$MONGO_URI
WALLET_BTC=$WALLET_BTC
EOF

npm install -g pm2
pm2 start server.js --name miner-backend
pm2 save
pm2 startup systemd -u $USER --hp $HOME
env PATH=$PATH:/usr/bin pm2 startup systemd -u $USER --hp $HOME 2>/dev/null || true

echo ">>> [7/8] Service systemd pour le mineur"
cp $PROJECT_DIR/scripts/start-miner.sh /usr/local/bin/
chmod +x /usr/local/bin/start-miner.sh

cat > /etc/systemd/system/miner.service <<EOF
[Unit]
Description=Mineur CPU BTC
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/bin/start-miner.sh
PIDFile=/var/run/miner.pid
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl enable miner.service
systemctl start miner.service

echo ">>> [8/8] Activation du moniteur intelligent (wakelock + auto-déploiement)"
# Empêcher la mise en veille
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null || true

# Script moniteur quotidien
cat > /usr/local/bin/monitor.sh <<'MONITOR'
#!/bin/bash
UPTIME_DAYS=$(awk '{print int($1/86400)}' /proc/uptime)
MARKER_FILE="/var/run/pool_installed"
PROJECT_DIR="/opt/miner-node"

if [ $UPTIME_DAYS -ge 21 ] && [ ! -f "$MARKER_FILE" ]; then
    echo "$(date) - Uptime > 21 jours, début de l'installation de la pool..."

    # Installer la pool Yiimp
    cd /tmp
    rm -rf yiimp_install_script
    git clone https://github.com/afiniel/yiimp_install_script.git
    cd yiimp_install_script
    # Réponses automatiques (adapter si nécessaire)
    yes "" | bash install.sh

    touch "$MARKER_FILE"
    echo "Installation de la pool terminée. Redémarrage conseillé."
    /sbin/reboot
else
    echo "$(date) - Uptime $UPTIME_DAYS jours, rien à faire."
fi

# Mise à jour du projet et redéploiement du backend
if [ -d "$PROJECT_DIR/.git" ]; then
    cd $PROJECT_DIR
    git pull origin main
    cd backend
    npm install
    pm2 restart miner-backend
fi
MONITOR
chmod +x /usr/local/bin/monitor.sh

# Tâche cron quotidienne
(crontab -l 2>/dev/null; echo "@daily /usr/local/bin/monitor.sh") | crontab -

echo "============================================="
echo "  ✅ Moniteur autonome installé !"
echo "  - Mineur tourne en arrière-plan"
echo "  - Backend API sur http://localhost:$BACKEND_PORT/api/status"
echo "  - Logs du mineur : tail -f /var/log/miner.log"
echo "  - Moniteur quotidien : /usr/local/bin/monitor.sh"
echo "  - Projet dans $PROJECT_DIR"
echo "  - Après 3 semaines, la pool s'installera toute seule"
echo "============================================="
