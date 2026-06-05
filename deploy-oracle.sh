cat > scripts/deploy-oracle.sh <<'EOF'
#!/bin/bash
set -e

# Charger les variables
if [ ! -f oci.env ]; then
    echo "Fichier oci.env introuvable. Copie le modèle et remplis-le."
    exit 1
fi
source oci.env

# Vérifier que l'OCI CLI est installée et configurée
if ! command -v oci &>/dev/null; then
    echo "Installation de l'OCI CLI..."
    bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"
fi

# Configurer l'environnement OCI
export OCI_CLI_PROFILE=DEFAULT
[ -f "$OCI_CONFIG_FILE" ] && export OCI_CONFIG_FILE="$OCI_CONFIG_FILE"

echo "Lancement de l'instance Oracle Free Tier..."
INSTANCE_ID=$(oci compute instance launch \
    --availability-domain "$(oci iam availability-domain list --compartment-id $OCI_COMPARTMENT_ID | jq -r '.data[0].name')" \
    --compartment-id "$OCI_COMPARTMENT_ID" \
    --shape VM.Standard.A1.Flex \
    --shape-config '{"ocpus":4,"memory_in_gbs":24}' \
    --image-id "$OCI_IMAGE_ID" \
    --subnet-id "$OCI_SUBNET_ID" \
    --assign-public-ip true \
    --ssh-authorized-keys-file /dev/stdin <<< "$OCI_SSH_PUBLIC_KEY" \
    --display-name "miner-pool" \
    --wait-for-state RUNNING \
    | jq -r '.data.id')

echo "Instance créée : $INSTANCE_ID"
# Récupérer l'IP publique
PUBLIC_IP=$(oci compute instance list-vnics --instance-id $INSTANCE_ID | jq -r '.data[0]."public-ip"')
echo "IP publique : $PUBLIC_IP"

echo "Connexion SSH : ssh ubuntu@$PUBLIC_IP"
echo "Déploiement du projet :"
echo "git clone git@github.com:sdoukoure12/miner-node.git"
echo "cd miner-node && sudo bash init-monitor.sh"
EOF
chmod +x scripts/deploy-oracle.sh
