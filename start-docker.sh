#!/bin/bash

echo "🐳 Démarrage Docker - Time Management API"
echo "========================================"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Vérifier que Docker est démarré
if ! docker info > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Docker n'est pas démarré. Démarrage en cours...${NC}"
    open -a Docker
    echo "Attente du démarrage de Docker..."
    while ! docker info > /dev/null 2>&1; do
        sleep 2
        echo -n "."
    done
    echo -e "\n${GREEN}✅ Docker démarré !${NC}"
fi

echo -e "${BLUE}📋 Vérification de la configuration...${NC}"

# Vérifier les fichiers nécessaires
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Fichier docker-compose.yml non trouvé"
    exit 1
fi

if [ ! -f "backend/Dockerfile" ]; then
    echo "❌ Dockerfile backend non trouvé"
    exit 1
fi

echo -e "${GREEN}✅ Configuration OK${NC}"

echo -e "${BLUE}🏗️  Construction des images Docker...${NC}"
docker-compose build

echo -e "${BLUE}🚀 Démarrage des services...${NC}"
docker-compose up -d

echo -e "${BLUE}📊 État des services :${NC}"
docker-compose ps

echo ""
echo -e "${GREEN}🎉 Services démarrés avec succès !${NC}"
echo ""
echo "📱 Accès aux services :"
echo "  • API Backend:      http://localhost:8080"
echo "  • Firebase UI:      http://localhost:4000"
echo "  • Traefik Dashboard: http://localhost:8081"
echo "  • Grafana:          http://localhost:3000"
echo "  • Prometheus:       http://localhost:9090"
echo ""
echo "🧪 Tests rapides :"
echo "  curl http://localhost:8080/health"
echo "  curl http://localhost:4000"
echo ""
echo "📋 Commandes utiles :"
echo "  docker-compose logs -f backend    # Voir les logs"
echo "  docker-compose ps                 # État des services"
echo "  docker-compose down               # Arrêter tout"
echo ""
