#!/bin/bash
# Bash script to pull all GHCR images for gridtechrnd
images=(
    "ghcr.io/gridtechrnd/chatwoot-rails:latest"
    "ghcr.io/gridtechrnd/chatwoot-development:latest"
    "ghcr.io/gridtechrnd/chatwoot-vite:latest"
)

for image in "${images[@]}"; do
    echo "Pulling $image..."
    docker pull "$image"
done
