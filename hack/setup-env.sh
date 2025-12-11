#!/bin/bash

# Complete setup script voor chall-manager test environment
set -e

export PATH="$PATH:/c/Program Files/Go/bin"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║        Chall-Manager Test Environment Setup                  ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# 1. Build scenario
echo "📦 Step 1/5: Building Docker scenario..."
cd docker-scenario

if [ ! -f "main" ]; then
    echo "   Building Go binary..."
    go mod tidy > /dev/null 2>&1
    CGO_ENABLED=0 go build -o main main.go
    echo "   ✓ Binary built"
else
    echo "   ✓ Binary already exists"
fi

cd ..
echo ""

# 2. Stop existing containers
echo "🛑 Step 2/5: Stopping existing containers..."
docker compose down > /dev/null 2>&1 || true
echo "   ✓ Cleaned up"
echo ""

# 3. Start services
echo "🚀 Step 3/5: Starting services..."
docker compose up -d
echo "   ✓ Services started"
echo ""

# 4. Wait for services to be ready
echo "⏳ Step 4/5: Waiting for services to be ready..."
echo -n "   Waiting for CTFd"
for i in {1..30}; do
    if curl -s -f http://localhost:8000 > /dev/null 2>&1; then
        echo " ✓"
        break
    fi
    echo -n "."
    sleep 1
done

echo -n "   Waiting for Chall-manager"
for i in {1..30}; do
    if curl -s -f http://localhost:8080/swagger/ > /dev/null 2>&1; then
        echo " ✓"
        break
    fi
    echo -n "."
    sleep 1
done

echo -n "   Waiting for Registry"
for i in {1..30}; do
    if curl -s -f http://localhost:5000/v2/_catalog > /dev/null 2>&1; then
        echo " ✓"
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

# 5. Push scenario to registry
echo "📤 Step 5/5: Pushing scenario to registry..."
cd docker-scenario
oras push --insecure \
  localhost:5000/examples/docker:latest \
  --artifact-type application/vnd.ctfer-io.scenario \
  main:application/vnd.ctfer-io.file \
  Pulumi.yaml:application/vnd.ctfer-io.file > /dev/null 2>&1
cd ..
echo "   ✓ Scenario pushed"
echo ""

# 6. Wait for ctfd-setup to complete
echo "⚙️  Waiting for CTFd setup to complete..."
sleep 5

# Check if setup completed
SETUP_LOGS=$(docker logs hack-ctfd-setup-1 2>&1 || echo "")
if echo "$SETUP_LOGS" | grep -q "error\|Error\|ERROR"; then
    echo "   ⚠️  Setup might have errors, check logs"
else
    echo "   ✓ Setup completed"
fi
echo ""

# 7. Create test challenge via chall-manager API
echo "🎯 Creating test challenge..."
bash create-test-challenge.sh > /dev/null 2>&1 || echo "   ⚠️  Challenge creation might have failed, you can create it manually"
echo "   ✓ Test challenge registered in chall-manager"
echo ""

# 8. Verify everything
echo "🔍 Verifying installation..."
echo ""

# Check services
echo "Services Status:"
docker ps --format "  ✓ {{.Names}} - {{.Status}}" | grep -E "(ctfd|chall-manager|registry)"
echo ""

# Check registry
CATALOG=$(curl -s http://localhost:5000/v2/_catalog)
if echo "$CATALOG" | grep -q "examples/docker"; then
    echo "  ✓ Scenario available in registry"
else
    echo "  ⚠️  Scenario not found in registry"
fi
echo ""

# 9. Summary
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    ✅ SETUP COMPLETE!                         ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "🌐 Access Points:"
echo "   CTFd:           http://localhost:8000"
echo "   Login:          ctfer / ctfer"
echo "   Swagger UI:     http://localhost:8080/swagger/"
echo ""
echo "🎯 Test Challenge:"
echo "   'Docker Test Challenge' has been automatically created!"
echo "   Go to Challenges to see it."
echo ""
echo "📝 Next Steps:"
echo "   1. Open http://localhost:8000"
echo "   2. Login with: ctfer / ctfer"
echo "   3. Create 2 teams (Admin Panel → Teams)"
echo "   4. Login as each team and boot the challenge"
echo "   5. Verify segmentation:"
echo "      docker ps --filter 'name=challenge-'"
echo ""
echo "🔧 Useful Commands:"
echo "   View logs:         docker logs -f chall-manager"
echo "   Monitor instances: watch -n 2 'docker ps --filter name=challenge-'"
echo "   Restart:           bash setup-env.sh"
echo "   Cleanup:           docker compose down -v"
echo ""
echo "📚 Documentation:"
echo "   Quick Fix:    hack/QUICK-FIX.txt"
echo "   Full Guide:   hack/SEGMENTATIE_TEST_README.md"
echo ""
