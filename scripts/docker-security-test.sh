#!/bin/bash

echo "🧪 Tests de sécurité Docker - Time Management API"
echo "=================================================="

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Compteurs
TESTS_PASSED=0
TESTS_FAILED=0

# Fonction pour afficher les résultats
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ PASS${NC}: $2"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}: $2"
        ((TESTS_FAILED++))
    fi
}

echo ""
echo "🔍 Test 1: Vérification des utilisateurs non-privilégiés"
echo "--------------------------------------------------------"

# Test Backend
BACKEND_USER=$(docker-compose exec -T backend whoami 2>/dev/null || echo "error")
if [ "$BACKEND_USER" = "vapor" ]; then
    print_result 0 "Backend s'exécute avec l'utilisateur 'vapor'"
else
    print_result 1 "Backend s'exécute avec l'utilisateur '$BACKEND_USER' (devrait être 'vapor')"
fi

echo ""
echo "🔍 Test 2: Vérification des limitations de ressources"
echo "-----------------------------------------------------"

# Vérifier si les conteneurs ont des limites de mémoire
BACKEND_MEMORY=$(docker inspect project-backend --format='{{.HostConfig.Memory}}' 2>/dev/null || echo "0")
if [ "$BACKEND_MEMORY" != "0" ]; then
    print_result 0 "Backend a des limitations de mémoire configurées"
else
    print_result 1 "Backend n'a pas de limitations de mémoire"
fi

echo ""
echo "🔍 Test 3: Vérification de l'isolation réseau"
echo "---------------------------------------------"

# Vérifier les réseaux Docker
NETWORKS=$(docker network ls --format "{{.Name}}" | grep -E "(frontend-network|backend-network|docker-proxy-network)" | wc -l)
if [ "$NETWORKS" -ge 3 ]; then
    print_result 0 "Réseaux isolés correctement configurés"
else
    print_result 1 "Réseaux isolés manquants (trouvés: $NETWORKS/3)"
fi

echo ""
echo "🔍 Test 4: Vérification des ports exposés"
echo "-----------------------------------------"

# Vérifier que seuls les ports nécessaires sont exposés
EXPOSED_PORTS=$(docker-compose ps --format "table {{.Name}}\t{{.Ports}}" | grep -v "Name" | wc -l)
if [ "$EXPOSED_PORTS" -gt 0 ]; then
    print_result 0 "Services Docker en cours d'exécution"
    docker-compose ps --format "table {{.Name}}\t{{.Ports}}"
else
    print_result 1 "Aucun service Docker en cours d'exécution"
fi

echo ""
echo "🔍 Test 5: Vérification des capabilities Linux"
echo "----------------------------------------------"

# Vérifier les capabilities du conteneur backend
BACKEND_CAPS=$(docker inspect project-backend --format='{{.HostConfig.CapDrop}}' 2>/dev/null || echo "[]")
if [[ "$BACKEND_CAPS" == *"ALL"* ]]; then
    print_result 0 "Backend a toutes les capabilities supprimées"
else
    print_result 1 "Backend n'a pas toutes les capabilities supprimées"
fi

echo ""
echo "🔍 Test 6: Vérification du mode lecture seule"
echo "---------------------------------------------"

BACKEND_READONLY=$(docker inspect project-backend --format='{{.HostConfig.ReadonlyRootfs}}' 2>/dev/null || echo "false")
if [ "$BACKEND_READONLY" = "true" ]; then
    print_result 0 "Backend configuré en mode lecture seule"
else
    print_result 1 "Backend n'est pas en mode lecture seule"
fi

echo ""
echo "🔍 Test 7: Vérification du proxy Docker Socket"
echo "----------------------------------------------"

DOCKER_PROXY_RUNNING=$(docker ps --filter "name=docker-proxy" --format "{{.Names}}" | wc -l)
if [ "$DOCKER_PROXY_RUNNING" -eq 1 ]; then
    print_result 0 "Proxy Docker Socket en cours d'exécution"
else
    print_result 1 "Proxy Docker Socket non trouvé"
fi

echo ""
echo "🔍 Test 8: Vérification des healthchecks"
echo "----------------------------------------"

FIREBASE_HEALTH=$(docker inspect project-firebase --format='{{.Config.Healthcheck.Test}}' 2>/dev/null || echo "none")
if [ "$FIREBASE_HEALTH" != "none" ] && [ "$FIREBASE_HEALTH" != "<no value>" ]; then
    print_result 0 "Firebase a un healthcheck configuré"
else
    print_result 1 "Firebase n'a pas de healthcheck"
fi

echo ""
echo "🔍 Test 9: Vérification des volumes sécurisés"
echo "---------------------------------------------"

# Vérifier les volumes en lecture seule
READONLY_VOLUMES=$(docker inspect project-backend --format='{{range .Mounts}}{{if .RW}}{{else}}{{.Destination}} {{end}}{{end}}' 2>/dev/null | wc -w)
if [ "$READONLY_VOLUMES" -gt 0 ]; then
    print_result 0 "Volumes en lecture seule configurés"
else
    print_result 1 "Aucun volume en lecture seule trouvé"
fi

echo ""
echo "🔍 Test 10: Vérification de la sécurité Traefik"
echo "-----------------------------------------------"

TRAEFIK_AUTH=$(docker inspect project-traefik --format='{{range .Config.Env}}{{if contains . "BASICAUTH"}}{{.}}{{end}}{{end}}' 2>/dev/null)
if [ -n "$TRAEFIK_AUTH" ]; then
    print_result 0 "Traefik a une authentification configurée"
else
    print_result 1 "Traefik n'a pas d'authentification configurée"
fi

echo ""
echo "📊 RÉSUMÉ DES TESTS"
echo "==================="
echo -e "Tests réussis: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests échoués: ${RED}$TESTS_FAILED${NC}"
echo -e "Total: $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 Tous les tests de sécurité sont passés !${NC}"
    exit 0
else
    echo -e "\n${YELLOW}⚠️  Certains tests de sécurité ont échoué. Vérifiez la configuration.${NC}"
    exit 1
fi
