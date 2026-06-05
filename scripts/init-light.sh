#!/bin/bash
set -e

WALLET_BTC="bc1qkue2h6hy0mchup80f9me036qwywfpmmcvefnsf"
POOL_URL="stratum+tcp://public-pool.io:3333"
ALGO="sha256d"
WORKER_NAME="worker1"
MINER_PASSWORD="x"
PROJECT_DIR="$HOME/miner-node"

echo ">>> Mise à jour et installation des dépendances"
apt update && apt upgrade -y
apt install -y git build-essential automake autoconf libtool libcurl4-openssl-dev libjansson-dev libgmp-dev zlib1g-dev libssl-dev nodejs npm

# Compilation de cpuminer si absent
if ! command -v cpuminer &>/dev/null; then
    echo ">>> Compilation de cpuminer-multi"
    cd /tmp
    rm -rf cpuminer-multi
    git clone https://github.com/tpruvot/cpuminer-multi.git
    cd cpuminer-multi
    ./build.sh
    cp cpuminer /usr/local/bin/
    cd ~
    rm -rf /tmp/cpuminer-multi
fi

echo ">>> Mise en place du projet"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR
if [ ! -d ".git" ]; then
    git clone https://github.com/sdoukoure12/miner-node.git .
else
    git pull origin main
fi

# Script de démarrage du mineur
cat > scripts/start-miner.sh <<EOF
#!/bin/bash
nohup cpuminer -a $ALGO -o $POOL_URL -u ${WALLET_BTC}.${WORKER_NAME} -p $MINER_PASSWORD --api-bind 0.0.0.0:4048 > /var/log/miner.log 2>&1 &
echo \$! > /var/run/miner.pid
EOF
chmod +x scripts/start-miner.sh

echo ">>> Installation du backend Node.js (mode JSON)"
cd backend
npm init -y
npm install express dotenv axios

# Créer le .env sans MongoDB (donc mode JSON)
cat > .env <<EOF
WALLET_BTC=$WALLET_BTC
# MONGODB_URI n'est pas défini -> stockage JSON
EOF

echo ">>> Lancement du backend avec PM2"
npm install -g pm2
pm2 start server.js --name miner-backend
pm2 save
pm2 startup 2>/dev/null || true

echo ">>> Lancement du mineur"
bash $PROJECT_DIR/scripts/start-miner.sh

echo "============================================="
echo "  Installation légère terminée !"
echo "  Backend : http://localhost:3000/api/status"
echo "  Logs mineur : tail -f /var/log/miner.log"
echo "  Pour plus tard, si MongoDB disponible :"
echo "  Ajoute MONGODB_URI=mongodb://... dans .env et redémarre (pm2 restart miner-backend)"
echo "============================================="
