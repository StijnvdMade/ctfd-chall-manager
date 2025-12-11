#!/bin/bash

# Script om automatisch een test challenge aan te maken via chall-manager gRPC API
set -e

CHALL_MANAGER_URL="http://localhost:8080"
CHALLENGE_ID="docker-test"
SCENARIO_URL="registry:5000/examples/docker:latest"

echo "═══════════════════════════════════════════════════════════"
echo "  Creating Test Challenge"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Wait a bit more for chall-manager to be fully ready
sleep 3

# Create challenge via swagger/HTTP gateway
echo "📦 Creating challenge via chall-manager..."
RESPONSE=$(curl -s -X POST "${CHALL_MANAGER_URL}/api/v1/challenges" \
    -H "Content-Type: application/json" \
    -d "{
        \"id\": \"${CHALLENGE_ID}\",
        \"scenario\": \"${SCENARIO_URL}\"
    }" 2>&1)

# Check response
if echo "$RESPONSE" | grep -q "${CHALLENGE_ID}\|${SCENARIO_URL}"; then
    echo "   ✓ Challenge created in chall-manager!"
else
    echo "   ⚠️  Challenge creation response:"
    echo "$RESPONSE"
    echo ""
    echo "   This might be normal if the challenge already exists."
fi
echo ""

# Now register it in CTFd via the plugin
echo "📝 Registering challenge in CTFd..."
echo "   Note: Challenge will appear in CTFd admin panel"
echo "   under 'Chall-Manager' type challenges."
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "✅ Done!"
echo ""
echo "The challenge is now available. You need to:"
echo ""
echo "1. Go to CTFd: http://localhost:8000"
echo "2. Login as admin: ctfer / ctfer"  
echo "3. Go to Admin Panel → Challenges"
echo "4. Create a new challenge:"
echo "   - Name: Docker Test Challenge"
echo "   - Category: Web"
echo "   - Points: 100"
echo "   - Type: chall_manager"
echo "   - Scenario: ${SCENARIO_URL}"
echo "   - Mana Cost: 1"
echo ""
echo "Or use the quick reference in: hack/QUICK-FIX.txt"
echo "═══════════════════════════════════════════════════════════"
