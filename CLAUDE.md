# FanZone Flutter — Guide projet pour Claude

## Vue d'ensemble

Application Flutter de découverte et participation à des événements sportifs locaux (région parisienne).
Objectif : permettre aux fans de trouver facilement des matchs de sport amateur près de chez eux,
de rejoindre des collectifs de supporters et de s'organiser (chat, chants, rôles, after).

**Repo GitHub :** https://github.com/delattr-t/Fanzone
**Développeur :** Thibaut (thidelattre@gmail.com)

---

## Stack technique

| Couche | Technologie |
|---|---|
| Framework | Flutter (Dart ≥ 3.3) |
| Fonts | Google Fonts — Nunito |
| Carte | flutter_map 7.0 + OpenStreetMap |
| Géolocalisation | geolocator 13.0 |
| Persistance | `shared_preferences` (blob JSON local) — **aucun backend requis** |
| Localisation | `flutter_localizations` (date/time pickers en français) |
| State management | `AppState` (ChangeNotifier) exposé par `AppScope` (InheritedNotifier) |
| Navigation | Bottom nav custom + `Navigator.push` |

> Firebase a été **retiré** (v1.1) : l'intégration bloquait sur `flutterfire configure` et
> empêchait l'app de compiler. Les anciens services sont archivés dans `docs/archive/firebase/`.

---

## Architecture des fichiers

```
lib/
├── main.dart                        # FanZoneApp, _AuthGate, MainShell, bottom nav
├── data/
│   └── local_store.dart             # FanZoneStore (interface) + LocalStore (shared_preferences)
├── state/
│   └── app_state.dart               # AppState : TOUTE la logique métier + AppScope
├── models/
│   ├── event.dart                   # FanZoneEvent (+ after, matériel sonore, collectifs) + démo
│   ├── club.dart                    # Club + sampleClubs
│   ├── collectif.dart               # Collectif, CollectifRole, roleCatalog + démo
│   ├── social.dart                  # UserProfile, ChatMessage, Chant, FanAlert + démo
│   └── sound_gear.dart              # Catalogue matériel sonore + note selon type de lieu
├── screens/
│   ├── login_screen.dart            # Prénom → profil local
│   ├── home_screen.dart             # Accueil : hero + cloche alertes, recherche, filtres, clubs, FAB créer
│   ├── map_screen.dart              # Carte OSM + pins + géoloc
│   ├── agenda_screen.dart           # Calendrier mensuel + liste
│   ├── event_detail_screen.dart     # Fiche event complète + EventChatScreen
│   ├── create_event_screen.dart     # Formulaire création d'event
│   ├── clubs_screen.dart            # ClubsScreen (liste, suivre) + ClubDetailScreen
│   ├── collectifs_screen.dart       # Liste des collectifs
│   ├── collectif_detail_screen.dart # Onglets Chat / Chants / Rôles
│   ├── chat_view.dart               # ChatView générique (channel `event:<id>` ou `col:<id>`)
│   ├── chants_view.dart             # Podium, vote, proposition de chant
│   ├── roles_view.dart              # Choix d'un rôle (1 par membre, capacité par rôle)
│   ├── alerts_screen.dart           # Centre d'alertes in-app
│   └── profile_screen.dart          # Profil, mes events/collectifs/clubs, reset
├── widgets/
│   ├── event_card.dart              # Card event (Home, Agenda, Club)
│   └── sticker.dart                 # StickerBlock/Label/Button/Pill/Field, EmptyHint, showFanToast
└── theme/app_theme.dart             # FanZoneColors + AppTheme
test/widget_test.dart                # 3 tests unitaires sur AppState (join, rôles, votes)
```

---

## Design system

- **Couleur primaire :** `#FF8C00` (orange) · **Fond :** `#FFFDF9` · **Noir :** `#1A1A1A` · **Jaune sticker :** `#FFD166`
- **Style "sticker"** : bordures `2.5px` noires, ombre décalée `Offset(3,3)` sans flou, coins arrondis, emojis partout
- **Typo :** Nunito, `w900` titres, `w800`/`w700` corps
- Chaque club/collectif porte sa couleur (`color` + `bgColor`)
- Widgets réutilisables dans `lib/widgets/sticker.dart` — **les utiliser** plutôt que de recopier des `BoxDecoration`

---

## État de l'app (v1.1)

### Navigation — 5 onglets (IndexedStack)
🏠 Accueil · 🗺️ Carte · 📅 Agenda · 🎊 Collectifs · 👤 Profil
+ écrans poussés : Clubs, fiche club, fiche event, chat event, création d'event, fiche collectif, alertes.

### Données & état
- `AppState` est la **seule** classe qui touche aux données. Les écrans lisent via `AppScope.of(context)`
  (rebuild automatique) ou `AppScope.read(context)` (sans dépendance, pour les callbacks).
- Les données de démo (`buildSample*()`) sont régénérées à chaque lancement avec des **dates relatives à aujourd'hui**.
- Ce qui est persisté : profil, events créés, ids rejoints (events/collectifs/clubs), rôles, votes,
  messages et chants de l'utilisateur, alertes. Clé : `fanzone_state_v1`.
- Les compteurs (supporters, membres, votes) = base de démo + contribution de l'utilisateur,
  appliqués de façon idempotente (`_applyMembership`, `_applyVotes`).

### Fonctionnalités
- Events : liste/recherche/filtres (sport, gratuit), carte, agenda, fiche complète
  (accroche, date/lieu/adresse, jauge + vibe, collectifs présents, matériel sonore autorisé/interdit
  + note selon le lieu, after-match, chat réservé aux participants), création d'event complète.
- Clubs : liste, fiche, suivre/ne plus suivre → alertes, section « Tes clubs jouent » sur l'accueil.
- Collectifs : rejoindre, chat membres, chants (proposer / voter / podium), rôles (1 par membre, capacité).
- Alertes in-app : nouvel event publié, club suivi, rappel J-1/jour J des events rejoints. Badge sur la cloche.
- Profil : prénom éditable, stats, mes events / collectifs (avec rôle) / clubs, reset complet.

---

## Commandes

```powershell
cd fanzone_flutter\fanzone_flutter
flutter pub get
flutter run -d chrome        # ou flutter run (Android)
flutter analyze
flutter test
flutter build apk --release  # APK pour les testeurs
```

Correctifs connus : se placer dans le bon dossier avant `flutter pub get` ; `flutter create .` si la cible web manque.

---

## Historique

- `47a123b` MVP initial (4 onglets, données mock)
- `47dc510` fix bugs + recherche/filtres
- `f10fdc5` écran Profil
- `5d34a7c` intégration Firebase (non finalisée, retirée ensuite)
- `0cc1bfa` CLAUDE.md
- **v1.1 (nov. 2026)** — refonte sans backend : AppState + persistance locale, suppression Firebase,
  nouveaux écrans Clubs / création d'event / chat / chants / rôles / alertes / matériel sonore / after,
  fiche event enrichie, login par prénom, widgets sticker, localisation FR, 3 tests unitaires,
  données de démo à dates relatives, 6e event (judo) + 5e collectif.

---

## Backlog

### Court terme
- [ ] Tester sur téléphone Android (USB puis APK) et faire tester à 3-5 personnes
- [ ] Géocodage des adresses à la création d'event (aujourd'hui : position ≈ celle du club)
- [ ] Partage d'event (share_plus)
- [ ] Icône + splash + screenshots stores

### Backend (quand la démo locale est validée)
- Choix à faire : **Supabase** (Postgres + Auth + Realtime, pilotable par Claude via connecteur,
  2 projets actifs max en gratuit) ou Firebase (nécessite des clics manuels dans la console).
- Remplacer `LocalStore` par une implémentation distante et rendre les méthodes d'`AppState`
  réellement asynchrones ; brancher l'auth dans `LoginScreen`. Les écrans ne changent pas.
- Notifications push (remplace les alertes in-app), modération/signalement (exigé par les stores).

### Plus tard
- Boutique / merch (prototype React existant), thermomètre d'ambiance, badges, répétitions, défis chants.

---

## Conventions de code

- Pas de commentaires sauf si le WHY est non-obvious
- Widgets privés préfixés `_`
- `.withValues(alpha: x)` et non `.withOpacity(x)` ; `Color.toARGB32()` et non `.value`
- Couleurs via `FanZoneColors.xxx` (jamais de hex inline hors design system et données de démo)
- Tri des events toujours via `DateTime.parse(e.date)`
- Toute mutation de données passe par une méthode d'`AppState` qui termine par `_persist()`
- Un test dans `test/widget_test.dart` pour chaque nouvelle règle métier
