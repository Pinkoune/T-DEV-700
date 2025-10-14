#!/bin/bash

echo "Scan de sécurité Docker..."

# Scan des images
echo "Scan des images Docker..."
docker images --format "table {{.Repository}}:{{.Tag}}" | tail -n +2 | while read image; do
    echo "Scanning $image..."
    trivy image --exit-code 1 --severity HIGH,CRITICAL "$image"
done

# Scan des configurations
echo "Scan des configurations..."
docker run --rm -v "$(pwd)":/project \
    aquasec/trivy config /project

# Scan des secrets
echo "Scan des secrets..."
docker run --rm -v "$(pwd)":/project \
    trufflesecurity/trufflehog:latest filesystem /project

echo "Scan de sécurité terminé"
