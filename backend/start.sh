#!/bin/bash

echo "Démarrage de l'API Time Management avec Firebase"

# Charge les variables depuis .env si le fichier existe
if [ -f .env ]; then
    echo "Chargement des variables depuis .env"
    export $(cat .env | grep -v '^#' | grep -v '^$' | xargs)
else
    echo "Fichier .env non trouvé - utilisez les variables système"
fi

# Vérifie les variables requises
if [ -z "$FIREBASE_PROJECT_ID" ]; then
    echo "FIREBASE_PROJECT_ID manquant"
    echo "Définissez : export FIREBASE_PROJECT_ID='votre-project-id'"
    exit 1
fi

if [ -z "$FIREBASE_SERVICE_ACCOUNT_PATH" ]; then
    echo "FIREBASE_SERVICE_ACCOUNT_PATH manquant"
    echo "Définissez : export FIREBASE_SERVICE_ACCOUNT_PATH='./config/serviceAccountKey.json'"
    exit 1
fi

# Vérifie que le fichier de service account existe
if [ ! -f "$FIREBASE_SERVICE_ACCOUNT_PATH" ]; then
    echo "Fichier service account non trouvé : $FIREBASE_SERVICE_ACCOUNT_PATH"
    echo "Téléchargez votre serviceAccountKey.json depuis Firebase Console"
    exit 1
fi

echo "Configuration validée"
echo "Projet Firebase : $FIREBASE_PROJECT_ID"
echo "Service Account : $FIREBASE_SERVICE_ACCOUNT_PATH"

# Compiler si nécessaire
echo "Compilation..."
swift build

if [ $? -eq 0 ]; then
    echo "Compilation réussie"
else
    echo "Erreur de compilation"
    exit 1
fi

# Lance le serveur
echo "Lancement du serveur..."
swift run backend
