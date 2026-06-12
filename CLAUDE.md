# FanZone Flutter — Guide projet pour Claude

## Vue d'ensemble

Application Flutter de découverte et participation à des événements sportifs locaux (région parisienne).
Objectif : permettre aux fans de trouver facilement des matchs de sport amateur près de chez eux et de rejoindre des collectifs de supporters.

**Repo GitHub :** https://github.com/delattr-t/Fanzone
**Développeur :** Thibaut (thidelattre@gmail.com)

---

## Stack technique

| Couche | Technologie |
|---|---|
| Framework | Flutter (Dart) |
| Fonts | Google Fonts — Nunito |
| Carte | flutter_map 7.0 + OpenStreetMap (CartoDB dark) |
| Géolocalisation | geolocator 13.0 |
| Auth | Firebase Auth — Google Sign-In + Anonyme |
| Base de données | Cloud Firestore (NoSQL) |
| Navigation | Bottom nav custom (go_router installé, pas encore utilisé) |
| State management | StatefulWidget + callbacks (pas de Riverpod/Bloc pour l'instant) |

---

## Architecture des fichiers

```
lib/
├── main.dart                    # Entry point, FanZoneApp, MainShell, BottomNav
├── firebase_options.dart        # Généré par flutterfire configure (NON commité)
├── models/
│   └── event.dart               # FanZoneEvent + sampleEvents + fromFirestore()
├── services/
│   ├── auth_service.dart        # Google Sign-In, anonyme, signOut, userStream
│   └── firestore_service.dart   # Streams events/collectifs, toggleJoin, seed, updateName
├── screens/
│   ├── home_screen.dart         # Accueil : hero, recherche, filtres, events
│   ├── map_screen.dart          # Carte OSM + pins events + géoloc
│   ├── agenda_screen.dart       # Calendrier mensuel + liste events
│   ├── collectifs_screen.dart   # Collectif model + liste + toggle rejoindre
│   ├── event_detail_screen.dart # Détail event : description, vibe, CTA
│   ├── profile_screen.dart      # Profil : avatar, stats, mes events, mes collectifs
│   └── login_screen.dart        # Écran connexion : Google + anonyme
├── widgets/
│   └── event_card.dart          # Card réutilisable event (utilisée sur Home + Agenda)
└── theme/
    └── app_theme.dart           # FanZoneColors + AppTheme (Material3)
```

---

## Design system

- **Couleur primaire :** `#FF8C00` (orange)
- **Fond :** `#FFFDF9` (blanc chaud)
- **Surface (cartes) :** `#FFFFFF`
- **Noir :** `#1A1A1A`
- **Accent sticker :** `#FFD166` (jaune)
- **Succès :** `#2E7D32` / fond `#E8F5E9`
- **Ombres :** `BoxShadow(offset: Offset(3,3), blurRadius: 0)` — style "sticker" flat
- **Bordures :** `2.5px` solide `#1A1A1A` sur toutes les cartes
- **Typography :** Nunito, `fontWeight: w900` pour les titres, `w800`/`w700` pour le corps
- **Emoji :** usage intensif comme icônes et décorations (style volontaire)

---

## État de l'app

### Navigation — 5 onglets (IndexedStack)
| Index | Onglet | Écran |
|---|---|---|
| 0 | 🏠 Accueil | HomeScreen |
| 1 | 🗺️ Carte | MapScreen |
| 2 | 📅 Agenda | AgendaScreen |
| 3 | 🎊 Collectifs | CollectifsScreen |
| 4 | 👤 Profil | ProfileScreen |

### State management actuel
- `_events` et `_collectifs` vivent dans `_MainShellState`
- Passés en props + callbacks (`onToggleJoin`, `onToggle`) à tous les écrans
- Avec Firebase : rechargés via streams Firestore en temps réel
- Mise à jour **optimiste** de l'UI avant écriture réseau

### Modèle Firestore
```
events/{eventId}
  └── supporters/{uid}         ← membres ayant rejoint

collectifs/{collectifId}
  └── members/{uid}            ← membres du collectif

users/{uid}
  ├── displayName, updatedAt
  ├── joinedEvents/{eventId}   ← events rejoints par l'user
  └── joinedCollectifs/{colId} ← collectifs rejoints par l'user
```

---

## Historique des modifications

### Commit 1 — `47a123b` — Initial commit MVP
**Date :** session initiale

MVP complet avec :
- 4 onglets : Accueil, Carte, Agenda, Collectifs
- 5 events et 4 collectifs en données mock (`sampleEvents`, `sampleCollectifs`)
- Carte interactive OSM avec géolocalisation
- Calendrier mensuel avec indicateurs d'events
- Système join/leave d'events
- Design system Nunito + orange/jaune/dark

---

### Commit 2 — `47dc510` — fix: corriger bugs + ajouter recherche et filtres
**Date :** session 1

**Bugs corrigés :**
- `event_card.dart` : `vibeLabel` affiché en double (pill + texte sous la barre de progression) — supprimé le pill redondant
- `main.dart` : `_events = sampleEvents` partageait la référence mutable → remplacé par `List.from(sampleEvents)`
- Partout : `.withOpacity()` déprécié en Flutter 3.x → remplacé par `.withValues(alpha: x)` (17 occurrences dans 6 fichiers)
- `home_screen.dart` : tri des events par `a.date.compareTo(b.date)` (string) → `DateTime.parse(a.date).compareTo(DateTime.parse(b.date))`

**Feature : Recherche + filtres sur HomeScreen**
- Barre de recherche avec bouton ✕ clear, filtre sur `match`, `club`, `venue`, `address`
- Filter chips animés par sport : Tous / Football ⚽ / Basketball 🏀 / Volleyball 🏐 / Course 🏃 / Cyclisme 🚴
- Toggle "Gratuit 🎟️" comme filtre supplémentaire
- Filtrage combiné en temps réel (query + sport + free)
- Empty state quand aucun résultat
- Sections "Mes équipes" et "Clubs locaux" masquées automatiquement pendant une recherche active

**Fichiers modifiés :** `main.dart`, `home_screen.dart`, `event_card.dart`, `agenda_screen.dart`, `collectifs_screen.dart`, `event_detail_screen.dart`, `map_screen.dart`

---

### Commit 3 — `f10fdc5` — feat: ajouter l'écran Profil utilisateur (5e onglet)
**Date :** session 1

**Refacto — lever l'état des collectifs :**
- `CollectifsScreen` gérait son propre état (`sampleCollectifs` local) → maintenant reçoit `collectifs` + `onToggle` en props depuis `MainShell`
- `MainShell` ajoute `_collectifs = List.from(sampleCollectifs)` et `_toggleCollectif()`
- `Collectif` model reste dans `collectifs_screen.dart` (accessible via import)

**Nouvel écran `ProfileScreen` (`lib/screens/profile_screen.dart`) :**
- Header dark : avatar cercle avec initiale du prénom, prénom éditable via `AlertDialog`
- Barre de stats : events rejoints / collectifs rejoints / events à venir
- Section "Mes events" : scroll horizontal de `_EventMiniCard` avec bouton "Quitter" direct
- Section "Mes collectifs" : `Wrap` de chips colorés avec emoji + membre count
- Empty states si aucun event / collectif rejoint
- 5e onglet 👤 Profil ajouté dans `_FanZoneBottomNav`

**Fichiers créés :** `lib/screens/profile_screen.dart`
**Fichiers modifiés :** `main.dart`, `collectifs_screen.dart`

---

### Commit 4 — `5d34a7c` — feat: intégrer Firebase Auth + Firestore
**Date :** session 1

**Dépendances ajoutées (`pubspec.yaml`) :**
```yaml
firebase_core: ^3.6.0
firebase_auth: ^5.3.1
cloud_firestore: ^5.4.4
google_sign_in: ^6.2.1
```

**`lib/services/auth_service.dart` (nouveau) :**
- `signInWithGoogle()` — Google Sign-In OAuth
- `signInAnonymously()` — accès sans compte
- `signOut()` — déconnexion Google + Firebase
- `userStream` — stream pour l'aiguillage auth
- `displayName` — prénom depuis le compte Google

**`lib/services/firestore_service.dart` (nouveau) :**
- `eventsStream(uid)` — stream temps réel des events + jointure joined/supporters
- `collectifsStream(uid)` — stream temps réel des collectifs
- `toggleJoinEvent(eventId, join)` — batch Firestore (userEvents + supporters)
- `toggleJoinCollectif(collectifId, join)` — batch Firestore (userCollectifs + members)
- `updateDisplayName(name)` — persistance du prénom en Firestore
- `seedIfEmpty()` — insère les 5 events + 4 collectifs de démo si la base est vide

**`lib/screens/login_screen.dart` (nouveau) :**
- Écran dark avec hero 🏟️ + titre FanZone
- 3 feature bullets (📍 🎊 🥁)
- Bouton "Continuer avec Google" (fond blanc, ombre jaune)
- Bouton "Continuer sans compte" (transparent)
- Spinner pendant le chargement

**`lib/models/event.dart` :**
- Ajout champ `firestoreId` (String, optionnel pour la compat mock)
- Ajout `FanZoneEvent.fromFirestore(docId, data, {joined, supporters})`

**`lib/screens/collectifs_screen.dart` :**
- Ajout `Collectif.fromFirestore(docId, data, {joined})`

**`lib/main.dart` :**
- `Firebase.initializeApp()` dans `main()`
- `StreamBuilder<User?>` sur `AuthService.userStream` → aiguille vers `LoginScreen` ou `MainShell`
- `_SplashScreen` pendant l'init Firebase
- `MainShell` charge events + collectifs via streams Firestore
- Mise à jour optimiste de l'UI avant écriture réseau
- `_updateName()` persiste en Firestore

**⚠️ BLOQUANT — action manuelle requise :**
Le fichier `lib/firebase_options.dart` doit être généré par `flutterfire configure`.
Il n'est PAS dans le repo (à ajouter dans `.gitignore` car contient des clés).

---

## Setup Firebase (à faire une fois)

```powershell
# 1. Firebase CLI
npm install -g firebase-tools
firebase login

# 2. FlutterFire CLI
dart pub global activate flutterfire_cli

# 3. Générer firebase_options.dart
flutterfire configure --project=fanzone

# 4. Packages
flutter pub get

# 5. Lancer
flutter run -d chrome
```

Dans la console Firebase :
- **Authentication** → activer Google + Anonyme
- **Firestore** → créer en mode Test, région `eur3 (europe-west)`

---

## Ce qui reste à faire (backlog)

### Court terme
- [ ] Finaliser la configuration Firebase (firebase_options.dart)
- [ ] Ajouter `firebase_options.dart` dans `.gitignore`
- [ ] Tester le flow complet : login → events Firestore → join → profil

### Moyen terme
- [ ] Push notifications (firebase_messaging) — rappel la veille d'un event rejoint
- [ ] Animations Hero entre EventCard et EventDetailScreen
- [ ] Écran de création d'event (pour les organisateurs)
- [ ] Partage d'event (Share API)
- [ ] Migrer vers go_router (déjà dans pubspec, pas encore utilisé)

### Long terme
- [ ] State management Riverpod (remplacer callbacks manuels)
- [ ] Build iOS + Android + publication App Store / Play Store
- [ ] Système de rôles : Fan / Organisateur / Admin
- [ ] Géoloc pour "events près de moi" avec rayon configurable
- [ ] Internationalisation (i18n) si expansion hors France

---

## Conventions de code

- Pas de commentaires sauf si le WHY est non-obvious
- Widgets privés préfixés `_` (ex: `_EventMiniCard`, `_FilterChip`)
- `.withValues(alpha: x)` et non `.withOpacity(x)` (déprécié Flutter 3.x)
- Couleurs via `FanZoneColors.xxx` (jamais de hex inline sauf dans le design system)
- Listes de données copiées avec `List.from()` pour éviter la mutation des sources
- Tri des events toujours via `DateTime.parse(e.date)` (jamais comparaison string)
