#!/bin/bash
# =================================================
#  Moniteur quotidien - Vérifie l'uptime et
#  déclenche l'installation de la pool après 21 jours
# =================================================

UPTIME_DAYS=$(awk '{print int($1/86400)}' /proc/uptime)
MARKER_FILE="/var/run/pool_installed"

# Si l'uptime dépasse 21 jours ET que la pool n'est pas déjà installée
if [ $UPTIME_DAYS -ge 21 ] && [ ! -f "$MARKER_FILE" ]; then
    echo "$(date) - Uptime > 21 jours, début de l'installation de la pool..."

    # Mise à jour du système
    apt update && apt upgrade -y

    # Installation des dépendances (si pas déjà faites)
    apt install -y git curl wget

    # Téléchargement du script d'installation Yiimp
    cd /tmp
    git clone https://github.com/afiniel/yiimp_install_script.git
    cd yiimp_install_script

    # Lancer l'installation (mode automatique, non interactif si possible)
    # Si le script attend des entrées, on peut utiliser 'yes' pour les valeurs par défaut
    yes "" | bash install.sh

    # Créer un fichier marqueur pour ne pas relancer l'installation
    touch "$MARKER_FILE"

    echo "Installation de la pool terminée. Redémarrage conseillé."
    # Redémarrer pour finaliser certaines configurations (optionnel)
    /sbin/reboot
fi

if [ $UPTIME_DAYS -ge 21 ] && [ ! -f "$MARKER_FILE" ]; then
    cd /tmp
    git clone https://github.com/afiniel/yiimp_install_script.git
    cd yiimp_install_script
    # Utiliser 'expect' pour répondre automatiquement
    apt install -y expect
    # Télécharger le fichier answers.txt depuis ton dépôt GitHub
    curl -O https://raw.githubusercontent.com/TON_COMPTE/miner-node-btc/main/pool/answers.txt
    # Lancer l'installation avec les réponses
    expect -c "
        set timeout -1
        spawn bash install.sh
        expect \"Domain\" { send \"$(cat answers.txt | head -1)\r\" }
        expect \"Email\" { send \"$(cat answers.txt | head -2 | tail -1)\r\" }
        # ... compléter selon les invites réelles
        expect eof
    "
    touch "$MARKER_FILE"
fi
