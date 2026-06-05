cat > scripts/cloud-mining/profit-switcher.sh << 'EOF'
#!/bin/bash
# Interroge WhatToMine pour l'algo le plus rentable et redémarre le mineur avec la bonne config

API_URL="https://whattomine.com/coins.json"
BTC_WALLET="bc1qkue2h6hy0mchup80f9me036qwywfpmmcvefnsf"
FALLBACK_POOL="stratum+tcp://public-pool.io:3333"
FALLBACK_ALGO="sha256d"
LOG_FILE="/var/log/pool_switch.log"

# Télécharger les données
DATA=$(curl -s $API_URL)
if [ -z "$DATA" ]; then
    echo "$(date) - Impossible de récupérer les données, utilisation du fallback" >> $LOG_FILE
    ALGO=$FALLBACK_ALGO
    POOL=$FALLBACK_POOL
else
    # Extraire l'algo le plus rentable (simplifié)
    BEST_ALGO=$(echo $DATA | jq -r '.coins | to_entries | max_by(.value.btc_revenue) | .value.algorithm' 2>/dev/null)
    case $BEST_ALGO in
        SHA-256) ALGO="sha256d"; POOL="stratum+tcp://mine.zpool.ca:3333";;
        Scrypt)  ALGO="scrypt"; POOL="stratum+tcp://mine.zpool.ca:3433";;
        Yescrypt) ALGO="yescrypt"; POOL="stratum+tcp://mine.zpool.ca:6233";;
        *) ALGO=$FALLBACK_ALGO; POOL=$FALLBACK_POOL;;
    esac
    echo "$(date) - Bascule vers $ALGO sur $POOL" >> $LOG_FILE
fi

# Mettre à jour la configuration du mineur
sed -i "s/ALGO=.*/ALGO=\"$ALGO\"/" /opt/miner-node/scripts/start-miner.sh
sed -i "s|POOL_URL=.*|POOL_URL=\"$POOL\"|" /opt/miner-node/scripts/start-miner.sh

# Redémarrer le mineur
systemctl restart miner.service
EOF
chmod +x scripts/cloud-mining/profit-switcher.sh
