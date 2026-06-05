cat > scripts/check-resources.sh <<'EOF'
#!/bin/bash
echo "=== Ressources actuelles (UserLAnd) ==="
echo "Espace disque :"
df -h / | awk 'NR==2 {print "Total: "$2, "Utilisé: "$3, "Dispo: "$4}'
echo ""
echo "Taille du projet :"
du -sh ~/miner-node 2>/dev/null
echo ""
echo "Mémoire :"
free -h | awk 'NR==2{print "Total: "$2, "Utilisé: "$3, "Dispo: "$4}'
echo ""
echo "Processeur :"
grep -m1 "model name" /proc/cpuinfo | cut -d: -f2
echo ""
echo "Conclusion :"
echo "- Ton téléphone peut faire tourner le backend et le mineur CPU."
echo "- Pas assez puissant pour héberger une pool complète, mais parfait pour tester."
echo "- Pour une pool publique, il faudra un VPS (voir script 'find-vps')."
EOF
chmod +x scripts/check-resources.sh
