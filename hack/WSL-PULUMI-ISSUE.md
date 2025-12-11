# WSL/Pulumi Compatibiliteit Probleem

## Probleem
Chall-manager gebruikt Pulumi's automation API om scenarios te valideren. In Docker Desktop op Windows met WSL2 backend krijg je deze error:

```
WSL (149 - ) ERROR: UtilGetPpid:1290: Failed to parse: /proc/1/stat
```

Dit is een bekend probleem waarbij Pulumi's binaries niet correct werken met WSL's /proc filesystem.

## Opties

### Optie 1: Kubernetes Backend gebruiken (AANBEVOLEN)

Docker Desktop heeft een ingebouwde Kubernetes cluster. Dit werkt wel goed met chall-manager:

#### Stappen:

1. **Enable Kubernetes in Docker Desktop**:
   - Open Docker Desktop
   - Ga naar Settings → Kubernetes
   - Vink "Enable Kubernetes" aan
   - Klik "Apply & restart"
   - Wacht tot Kubernetes cluster draait (groene indicator)

2. **Verify Kubernetes works**:
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

3. **Build en push een Kubernetes scenario** in plaats van Docker scenario:
   ```bash
   cd /c/Users/stijn/OneDrive/Documents/School/HvA/Jaar\ 4/Project\ Cybermeister/ctfd-chall-manager/
   # Download Kubernetes scenario example van chall-manager docs
   ```

4. **Update CTFd challenge** om Kubernetes scenario te gebruiken in plaats van Docker

### Optie 2: Native Linux Deployment

Deploy de volledige stack op een echte Linux VM (bijvoorbeeld Ubuntu in VirtualBox of een cloud VM).

Voordelen:
- Geen WSL compatibiliteitsproblemen
- Betere performance
- Identiek aan productie setup

Stappen:
1. Maak Ubuntu VM
2. Installeer Docker
3. Clone repository
4. Run setup script

### Optie 3: Accepteer limitatie en test handmatig

Als je alleen wilt testen of chall-manager werkt (zonder de volledige scenario validation):

Je kunt handmatig containers deployen en chall-manager laten managen zonder Pulumi scenario validation. Dit is niet ideaal maar kan voor basic testing.

## Aanbeveling

Voor jouw use case (testen van segmentatie):
→ **Gebruik Kubernetes backend** (Optie 1)

Dit is de minste moeite en werkt goed met Docker Desktop op Windows.

## Tijdelijke Workaround

Als je écht Docker backend wilt gebruiken zonder Kubernetes:
- Deploy op een Linux VM (Ubuntu WSL instance of VirtualBox)
- OF: gebruik `ctfd-whale` plugin in plaats van chall-manager (geen Pulumi issues)

## Resources

- [Docker Desktop Kubernetes docs](https://docs.docker.com/desktop/kubernetes/)
- [Chall-manager Kubernetes tutorial](https://ctfer.io/docs/chall-manager/tutorials/kubernetes/)
- [Pulumi WSL issue discussions](https://github.com/pulumi/pulumi/issues)
