#!/bin/bash

# Script om scenario te pushen naar registry met de juiste hostname
set -e

echo "=== Pushing Scenario to Registry ==="
echo ""

cd docker-scenario

# Check if binary exists
if [ ! -f "main" ]; then
    echo "Building Go binary..."
    export PATH="$PATH:/c/Program Files/Go/bin"
    CGO_ENABLED=0 go build -o main main.go
    echo "✓ Binary built"
fi

# Push with localhost for external access
echo "Pushing scenario to registry..."
oras push --insecure \
  localhost:5000/examples/docker:latest \
  --artifact-type application/vnd.ctfer-io.scenario \
  main:application/vnd.ctfer-io.file \
  Pulumi.yaml:application/vnd.ctfer-io.file

echo ""
echo "✓ Scenario pushed successfully!"
echo ""
echo "═══════════════════════════════════════════���════════════════"
echo "IMPORTANT: When creating a challenge in CTFd, use:"
echo ""
echo "    registry:5000/examples/docker:latest"
echo ""
echo "NOT: localhost:5000/examples/docker:latest"
echo ""
echo "Why? Because 'localhost' inside Docker containers refers to"
echo "the container itself, not your host machine. The containers"
echo "communicate via the Docker network using service names."
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Verify the scenario is available:"
curl -s http://localhost:5000/v2/examples/docker/tags/list | python3 -m json.tool

echo ""
echo "Next step: Create challenge in CTFd with scenario URL:"
echo "  registry:5000/examples/docker:latest"
