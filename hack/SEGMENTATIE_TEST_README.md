# Chall-Manager Segmentatie Test Setup

Deze guide helpt je om chall-manager op te zetten en te testen voor challenge segmentatie als alternatief voor CTFd-whale.

## Overzicht

Chall-manager biedt **Challenge on Demand** waarbij elke team/user hun eigen geïsoleerde instance krijgt van een challenge. Dit voorkomt dat teams elkaar beïnvloeden tijdens het CTF.

### Voordelen vs CTFd-whale:
- ✅ Geen Docker Swarm nodig
- ✅ Werkt met Docker Compose, Kubernetes, of cloud providers  
- ✅ Betere schaalbaarheid via Pulumi IaC
- ✅ Ingebouwde resource management (Mana systeem)
- ✅ Support voor meerdere flag variants per instance
- ✅ Automatische cleanup via janitor service

## Prerequisites

- ✅ Docker & Docker Compose geïnstalleerd
- ✅ Go 1.17+ geïnstalleerd
- ✅ ORAS CLI geïnstalleerd

## Setup Stappen

### 1. Build het Docker Scenario

Het example scenario deployt een Docker container per team:

```bash
cd ctfd-chall-manager/hack/docker-scenario

# Download dependencies
go mod tidy

# Build de binary
CGO_ENABLED=0 go build -o main main.go

# Push naar lokale registry
oras push --insecure localhost:5000/examples/docker:latest \
  --artifact-type application/vnd.ctfer-io.scenario \
  main:application/vnd.ctfer-io.file \
  Pulumi.yaml:application/vnd.ctfer-io.file
```

### 2. Start de Test Environment

```bash
cd ctfd-chall-manager/hack

# Stop eventuele oude containers
docker compose down

# Start alle services
docker compose up -d

# Verifieer dat alles draait
bash test-segmentation.sh
```

Dit start:
- **CTFd** op http://localhost:8000
- **Chall-manager** op http://localhost:8080  
- **Registry** op http://localhost:5000
- **Chall-manager-janitor** (cleanup service)

### 3. Test via CTFd UI

1. Open http://localhost:8000
2. Login: `ctfer` / `ctfer`
3. Ga naar **Admin Panel**
4. Ga naar **Plugins** > **Chall-Manager**
5. Klik **Create Challenge**
6. Vul in:
   - **Scenario**: `registry:5000/examples/docker:latest` ⚠️ **BELANGRIJK: Gebruik `registry:5000`, NIET `localhost:5000`!**
   - **Challenge name**: Test Challenge
   - **Category**: Web
   - **Points**: 100
7. Maak 2 teams aan (of gebruik Users mode)
8. Login als beide teams en boot de challenge
9. Verifieer segmentatie:

```bash
# Kijk naar alle challenge containers
docker ps --filter 'name=challenge-'

# Je zou 2 aparte containers moeten zien, één per team
# Elke container heeft een unieke identity (bijv. challenge-abc123, challenge-def456)
```

### 4. Test via Swagger API

Voor directe API testing:

1. Open http://localhost:8080/swagger/
2. **Create Challenge** via `POST /api/v1/challenges`:
```json
{
  "id": "test-challenge",
  "scenario": "registry:5000/examples/docker:latest"
}
```

3. **Create Instance voor team1** via `POST /api/v1/instances`:
```json
{
  "challenge_id": "test-challenge",
  "source_id": "team1"
}
```

4. **Create Instance voor team2** via `POST /api/v1/instances`:
```json
{
  "challenge_id": "test-challenge",
  "source_id": "team2"
}
```

5. Verifieer met `docker ps`:
```bash
docker ps --filter 'name=challenge-' --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}"
```

## Architectuur

```
┌─────────────┐
│   CTFd UI   │  ← Players/Teams login hier
└──────┬──────┘
       │
       ↓
┌─────────────────────┐
│  CTFd-chall-manager │  ← Plugin in CTFd
│      Plugin         │
└──────┬──────────────┘
       │
       ↓
┌─────────────────────┐
│   Chall-Manager     │  ← Beheert instances
│      (gRPC API)     │
└──────┬──────────────┘
       │
       ↓
┌─────────────────────┐
│   Docker Engine     │  ← Draait containers
│                     │
│  ┌───────────────┐  │
│  │ Team1 Instance│  │  ← Geïsoleerd
│  └───────────────┘  │
│  ┌───────────────┐  │
│  │ Team2 Instance│  │  ← Geïsoleerd
│  └───────────────┘  │
└─────────────────────┘
```

## Scenario Structuur

Een scenario is een Pulumi project dat definieert hoe de challenge wordt gedeployed:

```
docker-scenario/
├── Pulumi.yaml        # Pulumi configuratie
├── main.go           # Deployment logica (compiled binary)
└── go.mod            # Go dependencies
```

De `main.go` gebruikt de chall-manager SDK om:
- Docker images te pullen
- Containers te starten met unieke names
- Poorten te exposen
- Connection info terug te geven

## Verificatie van Segmentatie

### Test 1: Aparte Containers
```bash
docker ps --filter 'name=challenge-'
```
Verwacht resultaat: Elke team heeft een unieke container met verschillende identity.

### Test 2: Isolatie
Containers hebben geen netwerk connectie met elkaar (tenzij geconfigureerd).

### Test 3: Resource Cleanup
```bash
# Delete een instance via CTFd UI of API
# Verifieer dat container wordt verwijderd
docker ps --filter 'name=challenge-'
```

## Troubleshooting

### ❌ Error: "Internal server error" bij challenge aanmaken

**Symptoom**: CTFd geeft error "Chall-manager returned an error: {'code':2, 'message': 'Internal server error'}"

**Oorzaak**: Je gebruikt `localhost:5000` in plaats van `registry:5000` als scenario URL.

**Oplossing**: 
```
❌ FOUT:   localhost:5000/examples/docker:latest
✅ GOED:   registry:5000/examples/docker:latest
```

Binnen Docker containers verwijst `localhost` naar de container zelf. Containers communiceren met elkaar via de Docker network service names.

### Containers starten niet
```bash
# Check chall-manager logs
docker logs chall-manager

# Check CTFd logs  
docker logs ctfd
```

### Scenario niet gevonden
```bash
# Verifieer registry inhoud
curl http://localhost:5000/v2/_catalog

# Push scenario opnieuw
cd docker-scenario
bash build.sh  # of handmatig met oras
```

### API errors
```bash
# Test connectivity
curl http://localhost:8080/swagger/

# Check gRPC service
docker exec -it chall-manager ps aux
```

## Productie Overwegingen

Voor productie gebruik:

1. **Kubernetes Backend**: Gebruik Kubernetes in plaats van Docker voor betere schaalbaarheid
2. **External Registry**: Gebruik een echte OCI registry (Harbor, GCR, ECR)
3. **TLS**: Enable HTTPS voor alle services
4. **Mana System**: Configureer resource limits per team
5. **Monitoring**: Enable OpenTelemetry tracing
6. **Backup**: Backup de `/tmp/chall-manager` directory (of configureer persistent storage)

## Nuttige Commando's

```bash
# Watch challenge containers live
watch -n 2 'docker ps --filter name=challenge-'

# View chall-manager logs live
docker logs -f chall-manager

# Cleanup alles
cd hack && docker compose down -v

# Rebuild scenario
cd docker-scenario && CGO_ENABLED=0 go build -o main main.go

# Test registry
curl http://localhost:5000/v2/examples/docker/tags/list
```

## Volgende Stappen

1. ✅ Test met meerdere teams tegelijk
2. ✅ Voeg complexere scenarios toe (met databases, meerdere containers, etc.)
3. ✅ Test Mana systeem voor resource limiting
4. ✅ Deploy naar Kubernetes cluster voor productie
5. ✅ Configureer flag variants per team

## Resources

- [Chall-Manager Docs](https://ctfer.io/docs/chall-manager/)
- [CTFd-chall-manager Plugin](https://ctfer.io/docs/ctfd-chall-manager/)
- [Complete Example Tutorial](https://ctfer.io/docs/chall-manager/tutorials/a-complete-example/)
- [SDK Documentation](https://ctfer.io/docs/chall-manager/challmaker-guides/software-development-kit/)
