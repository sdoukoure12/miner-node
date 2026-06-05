cat > scripts/cloud-mining/nicehash-stratum.sh << 'EOF'
#!/bin/bash
# Exemple de connexion à NiceHash via stratum pour vendre votre puissance
# Remplacez par votre adresse BTC NiceHash

WALLET="bc1qkue2h6hy0mchup80f9me036qwywfpmmcvefnsf"
WORKER="worker1"
ALGO="sha256d"
POOL="stratum+tcp://sha256.eu.nicehash.com:3334"

# Commande cpuminer (à adapter)
echo "Lancement du mineur vers NiceHash..."
cpuminer -a $ALGO -o $POOL -u $WALLET.$WORKER -p x --api-bind 0.0.0.0:4048 > /var/log/miner-nicehash.log 2>&1 &
echo $! > /var/run/miner-nicehash.pid
EOF
chmod +x scripts/cloud-mining/nicehash-stratum.sh
