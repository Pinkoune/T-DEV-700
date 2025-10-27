#!/bin/bash

# Script pour pousser automatiquement vers deux repositories GitHub
# Usage: ./git-pushall.sh [message de commit] [branch]

# Couleurs pour un affichage plus clair
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Définir les remotes
REMOTE_ECOLE="origin"
REMOTE_PERSO="perso"

# Récupérer la branche actuelle si non spécifiée
BRANCH=${2:-$(git symbolic-ref --short HEAD)}

# Vérifier si on a des changements non commités
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}Des changements non commités ont été détectés.${NC}"

    # Si un message de commit a été fourni, on commit automatiquement
    if [ -n "$1" ]; then
        echo -e "Committing avec le message: ${GREEN}$1${NC}"
        git add .
        git commit -m "$1"
    else
        echo -e "${RED}Aucun message de commit fourni. Veuillez commiter vos changements manuellement.${NC}"
        exit 1
    fi
fi

# Pousser vers le repository école
echo -e "${YELLOW}Poussée vers le repository école (${REMOTE_ECOLE})...${NC}"
if git push ${REMOTE_ECOLE} ${BRANCH}; then
    echo -e "${GREEN}Poussée vers le repository école réussie!${NC}"
else
    echo -e "${RED}Erreur lors de la poussée vers le repository école.${NC}"
    exit 1
fi

# Pousser vers le repository personnel
echo -e "${YELLOW}Poussée vers le repository personnel (${REMOTE_PERSO})...${NC}"
if git push ${REMOTE_PERSO} ${BRANCH}; then
    echo -e "${GREEN}Poussée vers le repository personnel réussie!${NC}"
else
    echo -e "${RED}Erreur lors de la poussée vers le repository personnel.${NC}"
    exit 1
fi

echo -e "${GREEN}Toutes les poussées ont été effectuées avec succès!${NC}"