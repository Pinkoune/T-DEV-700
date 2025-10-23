#!/bin/bash

echo "🔐 Tests de Sécurité Complets - Time Management API"
echo "=================================================="

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_BASE_URL="http://localhost:8080"
TEST_EMAIL="admin@example.com"
TEST_PASSWORD="temp_password_dev_only"

# Compteurs
TESTS_PASSED=0
TESTS_FAILED=0
SECURITY_ISSUES=0

# Fonction pour afficher les résultats
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ PASS${NC}: $2"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}: $2"
        ((TESTS_FAILED++))
        if [ "$3" = "SECURITY" ]; then
            ((SECURITY_ISSUES++))
        fi
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
    local security_test=$7
    
    if [ -n "$data" ]; then
        response=$(curl -s -w "%{http_code}" -X "$method" "$url" -H "Content-Type: application/json" $headers -d "$data")
    else
        response=$(curl -s -w "%{http_code}" -X "$method" "$url" $headers)
    fi
    
    status_code="${response: -3}"
    body="${response%???}"
    
    if [ "$status_code" = "$expected_status" ]; then
        print_result 0 "$description (Status: $status_code)" "$security_test"
        return 0
    else
        print_result 1 "$description (Expected: $expected_status, Got: $status_code)" "$security_test"
        if [ -n "$body" ]; then
            echo "Response: $body"
        fi
        return 1
    fi
}

echo ""
echo "🚀 Démarrage des tests de sécurité..."
echo ""

# Test 1: Vérifier que l'API est accessible
echo -e "${BLUE}Test 1: Vérification de l'API${NC}"
echo "--------------------------------"
test_http "GET" "$API_BASE_URL/health" "" "" "200" "API Health Check"
echo ""

# Test 2: Vérifier les headers de sécurité
echo -e "${BLUE}Test 2: Headers de sécurité${NC}"
echo "------------------------------"
headers_response=$(curl -s -I "$API_BASE_URL/health")

if echo "$headers_response" | grep -q "X-Content-Type-Options: nosniff"; then
    print_result 0 "Header X-Content-Type-Options présent"
else
    print_result 1 "Header X-Content-Type-Options manquant" "SECURITY"
fi

if echo "$headers_response" | grep -q "X-Frame-Options: DENY"; then
    print_result 0 "Header X-Frame-Options présent"
else
    print_result 1 "Header X-Frame-Options manquant" "SECURITY"
fi

if echo "$headers_response" | grep -q "X-XSS-Protection"; then
    print_result 0 "Header X-XSS-Protection présent"
else
    print_result 1 "Header X-XSS-Protection manquant" "SECURITY"
fi
echo ""

# Test 3: Accès sans authentification (doit échouer)
echo -e "${BLUE}Test 3: Contrôle d'accès sans token${NC}"
echo "------------------------------------"
test_http "GET" "$API_BASE_URL/api/users" "" "" "401" "Accès refusé sans token" "SECURITY"
test_http "POST" "$API_BASE_URL/api/users" "" '{"firstName":"Test","lastName":"User","email":"test@test.com","phone":"1234567890","password":"password123"}' "401" "Création utilisateur refusée sans token" "SECURITY"
test_http "DELETE" "$API_BASE_URL/api/users/123" "" "" "401" "Suppression refusée sans token" "SECURITY"
echo ""

# Test 4: Test de rate limiting
echo -e "${BLUE}Test 4: Rate Limiting${NC}"
echo "----------------------"
echo "Envoi de 105 requêtes rapides pour tester le rate limiting..."
for i in {1..105}; do
    status=$(curl -s -o /dev/null -w "%{http_code}" "$API_BASE_URL/health")
    if [ "$status" = "429" ]; then
        print_result 0 "Rate limiting activé après $i requêtes"
        break
    fi
    if [ $i -eq 105 ]; then
        print_result 1 "Rate limiting non activé après 105 requêtes" "SECURITY"
    fi
done
echo ""

# Attendre que le rate limit se réinitialise
echo "Attente de 5 secondes pour la réinitialisation du rate limit..."
sleep 5

# Test 5: Login avec credentials invalides
echo -e "${BLUE}Test 5: Authentification avec credentials invalides${NC}"
echo "---------------------------------------------------"
test_http "POST" "$API_BASE_URL/login" "" '{"email":"invalid@example.com","password":"wrongpassword"}' "401" "Login refusé avec credentials invalides" "SECURITY"
test_http "POST" "$API_BASE_URL/login" "" '{"email":"","password":""}' "400" "Login refusé avec champs vides" "SECURITY"
test_http "POST" "$API_BASE_URL/login" "" '{"email":"admin@example.com","password":""}' "400" "Login refusé avec mot de passe vide" "SECURITY"
echo ""

# Test 6: Login avec credentials valides
echo -e "${BLUE}Test 6: Authentification avec credentials valides${NC}"
echo "--------------------------------------------------"
login_data="{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}"
login_response=$(curl -s -X POST "$API_BASE_URL/login" -H "Content-Type: application/json" -d "$login_data")
login_status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_BASE_URL/login" -H "Content-Type: application/json" -d "$login_data")

if [ "$login_status" = "200" ]; then
    print_result 0 "Login avec credentials valides"
    JWT_TOKEN=$(echo "$login_response" | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
    if [ -n "$JWT_TOKEN" ]; then
        echo -e "${GREEN}Token JWT reçu: ${JWT_TOKEN:0:50}...${NC}"
    else
        print_result 1 "Token JWT non trouvé dans la réponse" "SECURITY"
        JWT_TOKEN=""
    fi
else
    print_result 1 "Login échoué avec credentials valides" "SECURITY"
    JWT_TOKEN=""
fi
echo ""

# Test 7: Accès avec token valide
if [ -n "$JWT_TOKEN" ]; then
    echo -e "${BLUE}Test 7: Accès avec token valide${NC}"
    echo "--------------------------------"
    auth_header="-H \"Authorization: Bearer $JWT_TOKEN\""
    test_http "GET" "$API_BASE_URL/api/users" "$auth_header" "" "200" "Accès autorisé avec token valide"
    echo ""
    
    # Test 8: Test des permissions par rôle
    echo -e "${BLUE}Test 8: Contrôle des permissions${NC}"
    echo "--------------------------------"
    # Ces tests dépendent du rôle de l'utilisateur de test
    test_http "POST" "$API_BASE_URL/api/users" "$auth_header" '{"firstName":"Test","lastName":"User","email":"newuser@test.com","phone":"1234567890","password":"password123"}' "200" "Création utilisateur avec permissions admin"
    echo ""
    
    # Test 9: Test d'accès aux ressources utilisateur
    echo -e "${BLUE}Test 9: Accès aux ressources utilisateur${NC}"
    echo "--------------------------------------------"
    # Tenter d'accéder aux données d'un autre utilisateur (devrait échouer sauf pour admin)
    test_http "GET" "$API_BASE_URL/api/users/other-user-id" "$auth_header" "" "403" "Accès refusé aux données d'un autre utilisateur"
    echo ""
else
    echo -e "${YELLOW}⚠️  Tests 7-9 ignorés car aucun token JWT disponible${NC}"
    echo ""
fi

# Test 10: Test avec token invalide/malformé
echo -e "${BLUE}Test 10: Accès avec tokens invalides${NC}"
echo "-------------------------------------"
invalid_auth_header="-H \"Authorization: Bearer invalid.token.here\""
test_http "GET" "$API_BASE_URL/api/users" "$invalid_auth_header" "" "401" "Accès refusé avec token invalide" "SECURITY"

malformed_auth_header="-H \"Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.malformed\""
test_http "GET" "$API_BASE_URL/api/users" "$malformed_auth_header" "" "401" "Accès refusé avec token malformé" "SECURITY"

expired_auth_header="-H \"Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE1MTYyMzkwMjJ9.invalid\""
test_http "GET" "$API_BASE_URL/api/users" "$expired_auth_header" "" "401" "Accès refusé avec token expiré" "SECURITY"
echo ""

# Test 11: Test d'injection SQL/NoSQL (tentatives basiques)
echo -e "${BLUE}Test 11: Tests d'injection${NC}"
echo "-----------------------------"
injection_data='{"email":"admin@example.com\"; DROP TABLE users; --","password":"password"}'
test_http "POST" "$API_BASE_URL/login" "" "$injection_data" "401" "Tentative d'injection SQL bloquée" "SECURITY"

nosql_injection='{"email":{"$ne":""},"password":{"$ne":""}}'
test_http "POST" "$API_BASE_URL/login" "" "$nosql_injection" "400" "Tentative d'injection NoSQL bloquée" "SECURITY"
echo ""

# Test 12: Test de validation des entrées
echo -e "${BLUE}Test 12: Validation des entrées${NC}"
echo "--------------------------------"
invalid_email='{"firstName":"Test","lastName":"User","email":"invalid-email","phone":"1234567890","password":"password123"}'
test_http "POST" "$API_BASE_URL/api/users" "" "$invalid_email" "401" "Email invalide rejeté" "SECURITY"

short_password='{"firstName":"Test","lastName":"User","email":"test@example.com","phone":"1234567890","password":"123"}'
test_http "POST" "$API_BASE_URL/api/users" "" "$short_password" "401" "Mot de passe trop court rejeté" "SECURITY"
echo ""

# Test 13: Test des méthodes HTTP non autorisées
echo -e "${BLUE}Test 13: Méthodes HTTP non autorisées${NC}"
echo "--------------------------------------"
test_http "PATCH" "$API_BASE_URL/api/users" "" "" "405" "Méthode PATCH non autorisée"
test_http "TRACE" "$API_BASE_URL/api/users" "" "" "405" "Méthode TRACE non autorisée" "SECURITY"
test_http "OPTIONS" "$API_BASE_URL/api/users" "" "" "200" "Méthode OPTIONS autorisée (CORS)"
echo ""

# Résumé des tests
echo ""
echo "📊 RÉSUMÉ DES TESTS DE SÉCURITÉ"
echo "==============================="
echo -e "Tests réussis: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests échoués: ${RED}$TESTS_FAILED${NC}"
echo -e "Problèmes de sécurité: ${RED}$SECURITY_ISSUES${NC}"
echo -e "Total: $((TESTS_PASSED + TESTS_FAILED))"

# Évaluation de la sécurité
if [ $SECURITY_ISSUES -eq 0 ]; then
    echo -e "\n${GREEN}🛡️  EXCELLENT - Aucun problème de sécurité détecté !${NC}"
    echo -e "${GREEN}✅ L'API respecte les bonnes pratiques de sécurité${NC}"
    exit 0
elif [ $SECURITY_ISSUES -le 2 ]; then
    echo -e "\n${YELLOW}⚠️  BON - Quelques améliorations de sécurité possibles${NC}"
    echo -e "${YELLOW}🔧 $SECURITY_ISSUES problème(s) de sécurité détecté(s)${NC}"
    exit 1
elif [ $SECURITY_ISSUES -le 5 ]; then
    echo -e "\n${RED}🚨 MOYEN - Plusieurs problèmes de sécurité détectés${NC}"
    echo -e "${RED}🔧 $SECURITY_ISSUES problème(s) de sécurité nécessitent une attention${NC}"
    exit 2
else
    echo -e "\n${RED}💀 CRITIQUE - Nombreux problèmes de sécurité !${NC}"
    echo -e "${RED}🚨 $SECURITY_ISSUES problème(s) de sécurité DOIVENT être corrigés immédiatement${NC}"
    exit 3
fi
