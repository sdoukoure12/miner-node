cat > scripts/cloud-mining/mrr-api.sh << 'EOF'
#!/bin/bash
# Exemple d'appel API MiningRigRentals pour lister vos rigs
# Vous devez avoir une clé API (MRR_API_KEY) et un secret (MRR_API_SECRET)

API_KEY="votre_api_key"
API_SECRET="votre_api_secret"
BASE_URL="https://www.miningrigrentals.com/api/v2"

# Endpoint pour récupérer vos rigs (méthode GET)
curl -s -H "X-API-KEY: $API_KEY" -H "X-API-SIGN: ..." "$BASE_URL/rigs" | jq .
EOF
chmod +x scripts/cloud-mining/mrr-api.sh
