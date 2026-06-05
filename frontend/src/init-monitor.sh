cat > scripts/init-monitor.sh << 'EOF'
#!/bin/bash
set -e

# Configuration
WALLET_BTC="bc1qkue2h6hy0mchup80f9me036qwywfpmmcvefnsf"
POOL_URL="stratum+tcp://public-pool.io:3333"
ALGO="sha256d"
WORKER_NAME="worker1"
MINER_PASSWORD="x"
PROJECT_DIR="/opt/miner-node"

echo ">>> Installation du backend et des dépendances..."
# (même qu'avant : cpuminer, node, pm2, etc.)

# ... [tout le début de l'installation reste identique] ...

echo ">>> Installation du frontend React"
if [ ! -d "$PROJECT_DIR/frontend" ]; then
    # Créer le frontend avec Vite si pas déjà présent
    cd $PROJECT_DIR
    npm create vite@latest frontend -- --template react
    cd frontend
    npm install
    # Copier les fichiers personnalisés (si tu les as dans le dépôt, ils seront déjà là)
    # Sinon, on peut télécharger une version de base depuis ton dépôt
fi

cd $PROJECT_DIR/frontend
npm run build   # génère le dossier dist/

# Choix du mode de service
if command -v nginx &>/dev/null; then
    echo ">>> Configuration de Nginx pour servir le frontend"
    sudo tee /etc/nginx/sites-available/miner-node << 'NGINX'
server {
    listen 80;
    server_name _;
    root /opt/miner-node/frontend/dist;
    index index.html;
    location /api/ {
        proxy_pass http://localhost:3000;
    }
    location / {
        try_files $uri $uri/ /index.html;
    }
}
NGINX
    sudo ln -sf /etc/nginx/sites-available/miner-node /etc/nginx/sites-enabled/
    sudo nginx -t && sudo systemctl reload nginx
else
    echo ">>> Nginx absent, le backend servira le frontend statique"
    # On modifie server.js pour servir le dossier dist (via Express)
    # (un petit patch automatique)
    if ! grep -q "express.static" $PROJECT_DIR/backend/server.js; then
        sed -i 's/app.use(express.json());/app.use(express.json()); app.use(express.static("..\/frontend\/dist"));/' $PROJECT_DIR/backend/server.js
        pm2 restart miner-backend
    fi
fi

echo ">>> Installation terminée avec succès !"
echo "Accès dashboard : http://<IP>"
EOF
chmod +x scripts/init-monitor.sh
