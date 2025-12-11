#!/bin/bash

# Test script voor chall-manager segmentatie
set -e

echo "=== Chall-Manager Segmentatie Test ==="
echo ""

# 1. Check if services are running
echo "1. Checking services status..."
echo "   CTFd:"
if curl -s -f "http://localhost:8000" > /dev/null; then
    echo "   ✓ CTFd is running on http://localhost:8000"
else
    echo "   ✗ CTFd is not accessible"
    exit 1
fi

echo "   Chall-manager:"
if curl -s -f "http://localhost:8080/swagger/" > /dev/null; then
    echo "   ✓ Chall-manager is running on http://localhost:8080"
    echo "   ✓ Swagger UI: http://localhost:8080/swagger/"
else
    echo "   ✗ Chall-manager is not accessible"
    exit 1
fi

echo "   Registry:"
if curl -s -f "http://localhost:5000/v2/_catalog" > /dev/null; then
    echo "   ✓ Registry is running on http://localhost:5000"
else
    echo "   ✗ Registry is not accessible"
fi
echo ""

# 2. Check scenario in registry
echo "2. Checking scenario in registry..."
CATALOG=$(curl -s "http://localhost:5000/v2/_catalog")
echo "   Registry catalog: $CATALOG"
if echo "$CATALOG" | grep -q "examples/docker"; then
    echo "   ✓ Scenario 'examples/docker' is present in registry"
else
    echo "   ✗ Scenario not found in registry"
fi
echo ""

# 3. Check running containers
echo "3. Checking all running containers..."
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
echo ""

# 4. Check challenge containers (if any)
echo "4. Checking for challenge instance containers..."
CHALLENGE_CONTAINERS=$(docker ps --filter "name=challenge-" --format "{{.Names}}" | wc -l)
if [ "$CHALLENGE_CONTAINERS" -gt "0" ]; then
    echo "   Found $CHALLENGE_CONTAINERS challenge container(s):"
    docker ps --filter "name=challenge-" --format "   - {{.Names}} ({{.Image}}) - {{.Status}}"
else
    echo "   No challenge containers running yet"
    echo "   This is normal - instances are created when users boot them from CTFd"
fi
echo ""

echo "=== Test Environment Ready ==="
echo ""
echo "Summary:"
echo "- CTFd: http://localhost:8000"
echo "  Login: ctfer / ctfer (admin)"
echo ""
echo "- Chall-manager Swagger UI: http://localhost:8080/swagger/"
echo "  (Use this to test the API directly)"
echo ""
echo "- Registry: http://localhost:5000"
echo "  Scenario: localhost:5000/examples/docker:latest"
echo ""
echo "Next steps to test segmentatie:"
echo "1. Open CTFd at http://localhost:8000"
echo "2. Login as admin (ctfer/ctfer)"
echo "3. Go to Admin Panel > Plugins > Chall-Manager Settings"
echo "4. Create a new challenge with the scenario"
echo "5. Create 2 teams en login as each team"
echo "6. Each team boots their own instance"
echo "7. Run: docker ps --filter 'name=challenge-'"
echo "8. Verify each team has their own isolated container"
echo ""
echo "To test via Swagger UI:"
echo "1. Open http://localhost:8080/swagger/"
echo "2. Use POST /api/v1/challenges to create challenge"
echo "3. Use POST /api/v1/instances to create instances for different sources"
echo ""
echo "Useful commands:"
echo "- Watch containers: watch -n 2 'docker ps --filter name=challenge-'"
echo "- View logs: docker logs chall-manager"
echo "- Stop all: cd hack && docker compose down"
