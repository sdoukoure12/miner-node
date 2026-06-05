cat > scripts/cloud-mining/mrr-automate.sh << 'EOF'
#!/bin/bash
source ~/miner-node/api_keys.env

# Lister vos rigs disponibles
echo "=== Mes rigs MRR ==="
curl -s -H "X-API-KEY: $MRR_API_KEY" \
     "https://www.miningrigrentals.com/api/v2/rigs" | jq .

# Lister les locations actives
echo "=== Locations actives ==="
curl -s -H "X-API-KEY: $MRR_API_KEY" \
     "https://www.miningrigrentals.com/api/v2/rentals" | jq .
EOF
chmod +x scripts/cloud-mining/mrr-automate.sh
