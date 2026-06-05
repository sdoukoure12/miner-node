cat > scripts/cloud-mining/nicehash-api.sh << 'EOF'
#!/bin/bash
# Charge les clés
source ~/miner-node/api_keys.env

# Organisation ID (si tu en as une, sinon laisse vide)
ORG_ID=""

# Récupérer les stats de minage externe
echo "=== Statut de minage NiceHash ==="
curl -s -H "X-Organization-Id: $ORG_ID" \
     "https://api2.nicehash.com/main/api/v2/mining/external/$NICEHASH_WALLET/rigs" | jq .

# Récupérer le solde non payé
echo "=== Solde NiceHash ==="
curl -s -H "X-Organization-Id: $ORG_ID" \
     "https://api2.nicehash.com/main/api/v2/accounting/accounts" | jq .
EOF
chmod +x scripts/cloud-mining/nicehash-api.sh
