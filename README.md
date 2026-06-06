# FanZone Flutter

Sport local • Passion vraie 🎊

## 🚀 Démarrage rapide

### 1. Pré-requis (Windows)

```bash
# Installe Flutter depuis https://flutter.dev/docs/get-started/install/windows
# Puis vérifie que tout est OK :
flutter doctor
```

### 2. Installer les dépendances

```bash
cd fanzone
flutter pub get
```

### 3. Lancer dans le navigateur (le plus rapide)

```bash
flutter run -d chrome
```

### 4. Lancer sur émulateur Android

Ouvre Android Studio → Device Manager → crée un Pixel 7 API 34
Puis :
```bash
flutter run
```

### 5. Lancer sur ton téléphone Android

Active le mode développeur sur ton Android (Paramètres → À propos → taper 7x sur "Numéro de build")
Active le débogage USB → branche le câble
```bash
flutter devices   # vérifie que ton téléphone est détecté
flutter run
```

### 6. Générer un APK à partager

```bash
flutter build apk --release
# Le fichier est dans build/app/outputs/flutter-apk/app-release.apk
# Envoie-le par WhatsApp ou email à tes testeurs
```

## 📁 Structure du projet

```
lib/
├── main.dart                    # Point d'entrée + navigation
├── theme/
│   └── app_theme.dart          # Couleurs, typographie FanZone
├── models/
│   └── event.dart              # Modèle Event + données de démo
├── widgets/
│   └── event_card.dart         # Carte événement réutilisable
└── screens/
    ├── home_screen.dart        # Accueil (hero + clubs + events)
    ├── event_detail_screen.dart # Fiche détail événement
    ├── agenda_screen.dart      # Calendrier + liste
    └── collectifs_screen.dart  # Collectifs de supporters
```

## 🎨 Charte graphique

- **Fond** : `#FFFDF9` (blanc chaud)
- **Noir** : `#1A1A1A` (bordures, textes)
- **Orange** : `#FF8C00` (couleur principale FanZone)
- **Jaune** : `#FFD166` (stickers, badges)
- **Typo** : Nunito (Google Fonts)
- **Style** : Stickers avec box-shadow 3px décalé

## 📱 Prochaines étapes

- [ ] Écran Carte (flutter_map + OpenStreetMap)
- [ ] Écran Clubs
- [ ] Chat collectif (Firebase Realtime DB)
- [ ] Notifications push (Firebase Cloud Messaging)
- [ ] Authentification (Firebase Auth)
- [ ] Backend complet (Firestore)

## 🔧 Dépendances

| Package | Usage |
|---------|-------|
| `google_fonts` | Nunito font |
| `go_router` | Navigation (prêt pour la v2) |
