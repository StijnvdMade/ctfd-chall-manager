# Quick Start Guide - Chall-Manager

## 🚀 Automatische Setup (Aanbevolen)

Voer simpelweg uit:

```bash
cd ctfd-chall-manager/hack
bash setup-env.sh
```

Dit script doet **alles automatisch**:
- ✅ Bouwt het Docker scenario
- ✅ Start alle services (CTFd, chall-manager, registry)
- ✅ Pusht het scenario naar de registry
- ✅ Configureert CTFd met admin account
- ✅ Registreert de test challenge in chall-manager

**Klaar in ~30 seconden!**

## 📝 Wat te doen na setup

1. Open http://localhost:8000
2. Login: `ctfer` / `ctfer`
3. Ga naar **Admin Panel** → **Challenges** → **Create**
4. Vul in:
   ```
   Name:     Docker Test Challenge
   Category: Web
   Points:   100
   Type:     chall_manager
   Scenario: registry:5000/examples/docker:latest    ⚠️ BELANGRIJK!
   Mana:     1
   ```
5. Klik **Create**

## 🧪 Test Segmentatie

1. Maak 2 teams aan (Admin Panel → Teams)
2. Login als team 1, boot de challenge
3. Login als team 2, boot de challenge
4. Verifieer:
   ```bash
   docker ps --filter 'name=challenge-'
   ```
   Je zou 2 aparte containers moeten zien!

## 🔄 Opnieuw Beginnen

```bash
cd ctfd-chall-manager/hack
docker compose down -v  # Stop alles en verwijder data
bash setup-env.sh       # Begin opnieuw
```

## ⚠️ Veelvoorkomende Fouten

### "Internal server error" bij challenge maken
**Probleem**: Je gebruikt `localhost:5000` in plaats van `registry:5000`

**Oplossing**: Gebruik altijd `registry:5000/examples/docker:latest` als scenario URL

### Challenge niet zichtbaar
**Probleem**: Challenge is niet aangemaakt in CTFd UI

**Oplossing**: Volg stap 3-5 hierboven om de challenge handmatig aan te maken

## 📚 Meer Info

- Full Guide: `SEGMENTATIE_TEST_README.md`
- Quick Fix: `QUICK-FIX.txt`
- Test Script: `bash test-segmentation.sh`
