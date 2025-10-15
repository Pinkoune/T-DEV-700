#!/bin/bash

echo "🔐 Tests d'authentification JWT - Time Management API"
echo "====================================================="

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_BASE_URL="http://localhost:8080"
TEST_EMAIL="test@example.com"
TEST_PASSWORD="temp_password"

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

# Fonction pour tester une requête HTTP
test_http() {
    local method=$1
    local url=$2
    local headers=$3
    local data=$4
    local expected_status=$5
    local description=$6
    
    if [ -n "$data" ]; then
        response=$(curl -s -w "%{http_code}" -X "$method" "$url" -H "Content-Type: application/json" $headers -d "$data")
    else
        response=$(curl -s -w "%{http_code}" -X "$method" "$url" $headers)
    fi
    
    status_code="${response: -3}"
    body="${response%???}"
    
    if [ "$status_code" = "$expected_status" ]; then
        print_result 0 "$description (Status: $status_code)"
        echo "$body"
        return 0
    else
        print_result 1 "$description (Expected: $expected_status, Got: $status_code)"
        echo "Response: $body"
        return 1
    fi
}

echo ""
echo "🚀 Démarrage des tests JWT..."
echo ""

# Test 1: Vérifier que l'API est accessible
echo -e "${BLUE}Test 1: Vérification de l'API${NC}"
echo "--------------------------------"
test_http "GET" "$API_BASE_URL/health" "" "" "200" "API Health Check"
echo ""

# Test 2: Accès sans token (doit échouer)
echo -e "${BLUE}Test 2: Accès sans token${NC}"
echo "-----------------------------"
test_http "GET" "$API_BASE_URL/api/users" "" "" "401" "Accès refusé sans token"
echo ""

# Test 3: Login avec credentials valides
echo -e "${BLUE}Test 3: Login avec credentials${NC}"
echo "--------------------------------"
login_data="{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}"
login_response=$(test_http "POST" "$API_BASE_URL/login" "" "$login_data" "200" "Login avec credentials valides")

if [ $? -eq 0 ]; then
    # Extraire le token JWT de la réponse
    JWT_TOKEN=$(echo "$login_response" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
    if [ -n "$JWT_TOKEN" ]; then
        echo -e "${GREEN}Token JWT reçu: ${JWT_TOKEN:0:50}...${NC}"
    else
        echo -e "${RED}Erreur: Token JWT non trouvé dans la réponse${NC}"
        JWT_TOKEN=""
    fi
fi
echo ""

# Test 4: Accès avec token valide
if [ -n "$JWT_TOKEN" ]; then
    echo -e "${BLUE}Test 4: Accès avec token valide${NC}"
    echo "--------------------------------"
    auth_header="-H \"Authorization: Bearer $JWT_TOKEN\""
    test_http "GET" "$API_BASE_URL/api/users" "$auth_header" "" "200" "Accès autorisé avec token valide"
    echo ""
    
    # Test 5: Accès aux statistiques protégées
    echo -e "${BLUE}Test 5: Accès aux statistiques${NC}"
    echo "--------------------------------"
    test_http "GET" "$API_BASE_URL/api/stats" "$auth_header" "" "200" "Accès aux statistiques protégées"
    echo ""
    
    # Test 6: Refresh token
    echo -e "${BLUE}Test 6: Refresh token${NC}"
    echo "------------------------"
    refresh_response=$(test_http "POST" "$API_BASE_URL/refresh" "$auth_header" "" "200" "Refresh token")
    
    if [ $? -eq 0 ]; then
        NEW_JWT_TOKEN=$(echo "$refresh_response" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
        if [ -n "$NEW_JWT_TOKEN" ]; then
            echo -e "${GREEN}Nouveau token JWT reçu: ${NEW_JWT_TOKEN:0:50}...${NC}"
        fi
    fi
    echo ""
else
    echo -e "${YELLOW}⚠️  Tests 4-6 ignorés car aucun token JWT disponible${NC}"
    echo ""
fi

# Test 7: Login avec credentials invalides
echo -e "${BLUE}Test 7: Login avec credentials invalides${NC}"
echo "----------------------------------------"
invalid_login_data="{\"email\":\"invalid@example.com\",\"password\":\"wrongpassword\"}"
test_http "POST" "$API_BASE_URL/login" "" "$invalid_login_data" "401" "Login refusé avec credentials invalides"
echo ""

# Test 8: Accès avec token invalide
echo -e "${BLUE}Test 8: Accès avec token invalide${NC}"
echo "-----------------------------------"
invalid_auth_header="-H \"Authorization: Bearer invalid.token.here\""
test_http "GET" "$API_BASE_URL/api/users" "$invalid_auth_header" "" "401" "Accès refusé avec token invalide"
echo ""

# Test 9: Vérifier la structure du token JWT
if [ -n "$JWT_TOKEN" ]; then
    echo -e "${BLUE}Test 9: Structure du token JWT${NC}"
    echo "------------------------------"
    
    # Décoder le header du JWT (première partie)
    header=$(echo "$JWT_TOKEN" | cut -d'.' -f1)
    # Ajouter le padding nécessaire pour base64
    while [ $((${#header} % 4)) -ne 0 ]; do
        header="${header}="
    done
    
    decoded_header=$(echo "$header" | base64 -d 2>/dev/null)
    if [ $? -eq 0 ]; then
        print_result 0 "Header JWT décodé avec succès"
        echo "Header: $decoded_header"
    else
        print_result 1 "Erreur lors du décodage du header JWT"
    fi
    echo ""
fi

# Test 10: Vérifier les endpoints de l'API
echo -e "${BLUE}Test 10: Endpoints de l'API${NC}"
echo "-----------------------------"
api_info=$(test_http "GET" "$API_BASE_URL/" "" "" "200" "Information sur l'API")

if [ $? -eq 0 ]; then
    echo "Endpoints disponibles:"
    echo "$api_info" | grep -o '"[^"]*":"/api/[^"]*"' | sed 's/"//g'
fi
echo ""

# Résumé des tests
echo ""
echo "📊 RÉSUMÉ DES TESTS JWT"
echo "======================="
echo -e "Tests réussis: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests échoués: ${RED}$TESTS_FAILED${NC}"
echo -e "Total: $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 Tous les tests JWT sont passés !${NC}"
    echo -e "${GREEN}✅ L'authentification JWT fonctionne correctement${NC}"
    exit 0
else
    echo -e "\n${YELLOW}⚠️  Certains tests JWT ont échoué.${NC}"
    echo -e "${YELLOW}🔧 Vérifiez la configuration JWT et les services${NC}"
    exit 1
fi

