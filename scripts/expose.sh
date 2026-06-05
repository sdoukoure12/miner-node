cat > scripts/expose.sh <<'EOF'
#!/bin/bash
# Lance ngrok en arrière-plan pour exposer le backend
nohup ngrok http 3000 --log=stdout > /var/log/ngrok.log 2>&1 &
sleep 2
# Affiche l'URL publique
curl -s http://127.0.0.1:4040/api/tunnels | grep -o 'https://[a-zA-Z0-9.-]*\.ngrok\.io'
EOF
chmod +x scripts/expose.sh
