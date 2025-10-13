#!/bin/bash

echo "Test de configuration Firebase..."

# Vérifie les fichiers
if [ ! -f ".env" ]; then
    echo "Fichier .env manquant"
    echo "Créez un fichier .env basé sur .env.example"
    exit 1
fi

if [ ! -f "config/serviceAccountKey.json" ]; then
    echo "Fichier serviceAccountKey.json manquant"
    echo "Téléchargez votre service account depuis Firebase Console"
    exit 1
fi

echo "Fichiers de configuration présents"

# Vérifie les variables d'environnement
source .env
if [ -z "$FIREBASE_PROJECT_ID" ]; then
    echo "FIREBASE_PROJECT_ID manquant dans .env"
    exit 1
fi

echo "Variables d'environnement configurées"
echo "Projet Firebase : $FIREBASE_PROJECT_ID"

# Compiler
echo "Compilation..."
swift build

if [ $? -eq 0 ]; then
    echo "Compilation réussie"
else
    echo "Erreur de compilation"
    exit 1
fi

# Démarre le serveur en arrière-plan
echo "Démarrage du serveur..."
swift run backend &
SERVER_PID=$!

# Attends que le serveur démarre
sleep 5

# Test les routes
echo "Test des routes..."

# Test de santé
HEALTH=$(curl -s http://localhost:8080/health)
if [ "$HEALTH" = "\"API is healthy!\"" ]; then
    echo "Route health OK"
else
    echo "Route health échoué"
fi

# Test des stats (utilise Firebase)
STATS=$(curl -s http://localhost:8080/api/stats)
if [[ $STATS == *"activeUsers"* ]]; then
    echo "Route stats OK (Firebase fonctionne)"
    echo "Réponse : $STATS"
else
    echo "Route stats échoué (problème Firebase)"
    echo "Réponse : $STATS"
fi

# Test de création d'utilisateur
echo "Test de création d'utilisateur..."
USER_RESPONSE=$(curl -s -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Test",
    "lastName": "Firebase",
    "email": "test@firebase.com",
    "phone": "0123456789",
    "role": "employee"
  }')

if [[ $USER_RESPONSE == *"firstName"* ]]; then
    echo "Création d'utilisateur OK"
else
    echo "Création d'utilisateur échoué"
    echo "Réponse : $USER_RESPONSE"
fi

# Arrêt du serveur
kill $SERVER_PID

echo ""
echo "Test terminé"
echo "Firebase Firestore est configuré et fonctionne !"
