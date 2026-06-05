cat > scripts/deploy-oracle.sh <<'EOF'
#!/bin/bash
# Ce script nécessite l'OCI CLI installée et configurée
# Instructions : https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm

if ! command -v oci &>/dev/null; then
    echo "Installation de l'OCI CLI..."
    bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"
fi

echo "Vérification de la configuration OCI..."
oci iam compartment list --all 2>/dev/null || {
    echo "Erreur : configurez d'abord vos clés avec 'oci setup config'."
    exit 1
}

# Créer une instance ARM Ampere (Free Tier)
oci compute instance launch \
    --availability-domain "$(oci iam availability-domain list --compartment-id $OCI_COMPARTMENT_ID | jq -r '.data[0].name')" \
    --compartment-id $OCI_COMPARTMENT_ID \
    --shape VM.Standard.A1.Flex \
    --shape-config '{"ocpus":4,"memory_in_gbs":24}' \
    --image-id "ocid1.image.oc1..aaaaaaaab..." \  # ID d'Ubuntu 22.04
    --subnet-id "ocid1.subnet..." \
    --assign-public-ip true \
    --ssh-authorized-keys-file ~/.ssh/id_ed25519.pub \
    --display-name "miner-pool"

echo "Instance créée. Attendez 2 minutes puis connectez-vous avec :"
echo "ssh ubuntu@<IP>"
echo "Ensuite, clonez le dépôt et lancez l'installation :"
echo "git clone git@github.com:sdoukoure12/miner-node.git"
echo "cd miner-node && sudo bash init-monitor.sh"
EOF
chmod +x scripts/deploy-oracle.sh
