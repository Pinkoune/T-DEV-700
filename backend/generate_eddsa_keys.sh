#!/bin/bash

echo "Génération des clés EdDSA Ed25519 pour JWT"
echo "=========================================="

# Génération des clés
openssl genpkey -algorithm Ed25519 -out jwt_ed25519_private.pem
openssl pkey -in jwt_ed25519_private.pem -pubout -out jwt_ed25519_public.pem

# Conversion pour variables d'environnement
echo ""
echo "Variables d'environnement à ajouter dans votre .env:"
echo "===================================================="
echo ""

echo "JWT_EDDSA_PRIVATE_KEY=\\"$(cat jwt_ed25519_private.pem | tr '\\n' '\\\\n')\\""
echo ""
echo "JWT_EDDSA_PUBLIC_KEY=\\"$(cat jwt_ed25519_public.pem | tr '\\n' '\\\\n')\\""

echo ""
echo "Clés EdDSA générées avec succès !"
echo "Fichiers créés :"
echo "   - jwt_ed25519_private.pem (à garder secret)"
echo "   - jwt_ed25519_public.pem (peut être partagée)"
echo ""
echo "IMPORTANT : Gardez la clé privée secrète et sécurisée !"
