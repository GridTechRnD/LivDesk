#!/bin/bash
# Bash script to pull all GHCR images for gridtechrnd
images=(
    "ghcr.io/gridtechrnd/livdesk-rails:latest"
    "ghcr.io/gridtechrnd/livdesk-development:latest"
    "ghcr.io/gridtechrnd/livdesk-vite:latest"
)

for image in "${images[@]}"; do
    echo "Pulling $image..."
    docker pull "$image"
done
