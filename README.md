# FanZone Flutter

Sport local • Passion vraie 🎊

Application mobile pour trouver les événements sportifs amateurs autour de soi, rejoindre un collectif
de supporters et s'organiser pour mettre l'ambiance (chants, rôles, matériel, after).

**v1.1 — fonctionne sans backend** : tout est stocké sur le téléphone. Idéal pour tester l'expérience
avec de vrais supporters avant de brancher une base de données.

## 🚀 Démarrage rapide

```bash
cd fanzone_flutter
flutter pub get
flutter run -d chrome      # navigateur
flutter run                # téléphone / émulateur Android
```

Générer un APK à partager aux testeurs :

```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

Vérifier le code :

```bash
flutter analyze
flutter test
```

## ✨ Fonctionnalités

- 🏠 **Accueil** : recherche, filtres par sport / gratuit, clubs locaux, events des clubs suivis, prochains events
- 🗺️ **Carte** OpenStreetMap avec géolocalisation · 📅 **Agenda** mensuel
- 🎟️ **Fiche event** : accroche, lieu + adresse, jauge de mobilisation, collectifs présents,
  matériel sonore autorisé / interdit, after-match, chat réservé aux participants
- 📣 **Créer un event** : club, sport, adversaire, niveau, date/heure, lieu, capacité, gratuit/payant, after, matériel
- 🏅 **Clubs** : suivre un club → alerte à chaque nouvel event
- 🎊 **Collectifs** : chat des membres, chants (proposer, voter, podium), rôles dans la tribune
- 🔔 **Alertes** : nouveaux events, rappel la veille
- 👤 **Profil** : mes events, mes collectifs et rôles, mes clubs

## 📁 Structure

```
lib/
├── main.dart            # App, navigation
├── state/app_state.dart # Toute la logique métier (ChangeNotifier)
├── data/local_store.dart# Persistance locale (interface prête pour un backend)
├── models/              # Event, Club, Collectif, Chant, Message, Alerte…
├── screens/             # Un fichier par écran
├── widgets/             # EventCard + composants "sticker"
└── theme/               # Couleurs + thème
```

Voir `CLAUDE.md` pour l'architecture détaillée, l'historique et le backlog.

## 🎨 Charte

Fond `#FFFDF9` · Noir `#1A1A1A` · Orange `#FF8C00` · Jaune `#FFD166` · Nunito · style « stickers »
