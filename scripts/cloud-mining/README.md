cd ~/miner-node
mkdir -p scripts/cloud-mining

cat > scripts/cloud-mining/README.md << 'EOF'
# Modules Cloud Mining

Ce dossier contient les scripts pour intégrer des services de cloud mining et des pools alternatives.

## Contenu

- `profit-switcher.sh` : Interroge WhatToMine pour basculer automatiquement vers la pool la plus rentable.
- `nicehash-stratum.sh` : Exemple de connexion stratum à NiceHash.
- `mrr-api.sh` : Script de démonstration pour l'API MiningRigRentals.

## Utilisation

Ajoutez ces scripts dans la cron via `monitor.sh` pour diversifier vos sources de revenus.
EOF
