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
| Fonts | Google Fonts — Bricolage Grotesque (jeu « Écharpe ») ou Caprasimo + Atkinson Hyperlegible + Jersey 15 (jeu « Gazette ») |
| Carte | flutter_map 7.0 + OpenStreetMap |
| Géolocalisation | geolocator 13.0 |
| Backend | **Supabase** (projet `fanzone`, région eu-west-3 Paris) : Postgres + Auth anonyme + Realtime. `AppConfig.useSupabase = false` pour revenir au mode 100 % local |
| Persistance locale | `shared_preferences` (mode local + alertes) |
| Localisation | `flutter_localizations` (date/time pickers en français) |
| State management | `AppState` (ChangeNotifier) exposé par `AppScope` (InheritedNotifier) |
| Navigation | Bottom nav custom + `Navigator.push` |

> Firebase a été **retiré** (v1.1) : l'intégration bloquait sur `flutterfire configure` et
> empêchait l'app de compiler. Les anciens services sont archivés dans `docs/archive/firebase/`.
> Supabase l'a remplacé (v1.2) : Claude pilote la base via connecteur (migrations, RLS, seed).

---

## Architecture des fichiers

```
lib/
├── main.dart                        # FanZoneApp, _AuthGate, MainShell, bottom nav
├── config.dart                      # AppConfig : useSupabase, URL, clé publishable, shareBaseUrl
├── data/
│   ├── repository.dart              # FanZoneRepository (interface) + DataSnapshot
│   ├── local_repository.dart        # Impl. locale (démo + blob JSON)
│   ├── supabase_repository.dart     # Impl. Supabase (tables, RLS, realtime messages)
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
│   ├── create_event_screen.dart     # « Organiser un match » : 4 étapes + aperçu en direct de la carte
│   ├── clubs_screen.dart            # ClubsScreen (liste, suivre) + ClubDetailScreen
│   ├── collectifs_screen.dart       # Liste des collectifs
│   ├── collectif_detail_screen.dart # Onglets Chat / Chants / Rôles
│   ├── chat_view.dart               # ChatView générique (channel `event:<id>` ou `col:<id>`)
│   ├── chants_view.dart             # Podium, vote, proposition de chant
│   ├── roles_view.dart              # Choix d'un rôle (1 par membre, capacité par rôle)
│   ├── alerts_screen.dart           # Centre d'alertes in-app
│   └── profile_screen.dart          # Profil, mes events/collectifs/clubs, reset
├── widgets/
│   ├── event_card.dart              # Card event, JoinPill, CrowdDots
│   ├── share_sheet.dart             # Panneau « Ramène tes potes » + liens `#/match/<id>` (matchLink, matchIdFromUri)
│   ├── scarf.dart                   # Scarf : l'écharpe tricotée (geste signature)
│   └── sticker.dart                 # StickerBlock/Label/Button/Pill/Field, EmptyHint, showFanToast
└── theme/app_theme.dart             # FanZoneColors + AppTheme
test/widget_test.dart                # 5 tests unitaires (AppState via LocalRepository + liens de partage)
web/                                 # index.html (écran de chargement, balises Open Graph), manifest, icônes, og.png
tool/branding/                       # scarf.py + icon.py : génèrent l'icône (deux écharpes croisées) en Python
```

---

## Design system — « Écharpe » (v1.4)

Direction : la laine du supporter. Tout ce qui est chaleureux dans le sport amateur tient dans
l'écharpe tricotée aux couleurs du club ; c'est le geste signature de l'app.

- **Geste signature** : `Scarf` (`lib/widgets/scarf.dart`) dessine une écharpe en code
  (rayures crème, mailles jersey, lettrage jacquard, franges). Une écharpe par club sur l'accueil
  (« Les écharpes du coin », toucher = suivre), en tête du prochain match, des collectifs, de la
  fiche match, trois écharpes qui se déroulent à l'entrée, et « ton écharpe » sur le profil
  (un tronçon par club suivi / collectif rejoint). Les cartes de match portent une lisière tricotée.
- **Couleurs** (`FanZoneColors`) : `wool #F6EDE0` (fond) · `paper #FFFBF5` (cartes) · `ink #2B1A12`
  (encre brune) · `flare #E2462B` (braise : action) · `hiVis #FFB420` (soleil : jauge, sélection,
  « membre ») · `wall #EFE3D2` / `wallDeep #E3D3BD` (sable, filets) · `cement #7A6253` (texte
  secondaire) · `night #2B1A12` (blocs soir de match) · `cream #FFF3E0` (rayures des écharpes).
- **Typo — deux jeux** (`FanZoneType`, notifier `fanZoneType` dans `app_theme.dart`) :
  - `echarpe` (défaut) : Bricolage Grotesque partout (`fzDisplay` w800, facteur 0.86) ;
  - `gazette` : Caprasimo pour les titres (facteur 0.8, poids unique), Atkinson Hyperlegible pour
    le texte (400/700), Jersey 15 (lettres de maillot tricoté) pour le lettrage des écharpes.
  Toujours passer par `fz()`, `fzDisplay()`, `fzScarf()`. Choix : `?typo=gazette` dans l'URL, ou
  « Typographie » dans le profil (`switchTypography`), mémorisé (`fanzone_typo`). Les polices sont
  préchargées (`loadTypography`) avant l'affichage, car les écharpes sont peintes sur un canvas.
- **Formes** : cartes rayon 20–28, boutons en pilule, ombre douce `FanZoneColors.lift`, pas de
  contour noir. Écussons ronds (`Monogram`), éphémérides (`DateBlock`), foule de têtes
  (`CrowdDots`), bouton `JoinPill` (braise → soleil une fois engagé).
- **Carte** : tuiles OpenStreetMap (sans clé) teintées « laine » par `ColorFiltered` ; épingles =
  écusson du club + nombre de supporters ; carrousel synchronisé en bas. Attribution OSM affichée.
- **Ton des textes** : phrases complètes, minuscules, verbes concrets. Virgules, pas de « · ».
- Une `Border` non uniforme (ex. seulement `left`) ne doit jamais être combinée à un `borderRadius`
  (erreur de rendu Flutter).

---

## État de l'app (v1.1)

### Navigation — 5 onglets (IndexedStack)
🏠 Accueil · 🗺️ Carte · 📅 Agenda · 🎊 Collectifs · 👤 Profil
+ écrans poussés : Clubs, fiche club, fiche event, chat event, création d'event, fiche collectif, alertes.

### Données & état
- `AppState` est la **seule** classe qui touche aux données. Les écrans lisent via `AppScope.of(context)`
  (rebuild automatique) ou `AppScope.read(context)` (sans dépendance, pour les callbacks).
- `AppState` parle à un `FanZoneRepository` : écriture **optimiste** (UI mise à jour, puis appel distant ;
  en cas d'échec, rechargement + `lastError`, affiché en toast par `MainShell`).
- Contrat du repository : les compteurs renvoyés (supporters, membres, votes, fans) n'incluent **pas**
  l'utilisateur courant ; `AppState` les ajoute de façon idempotente (`_applyMembership`, `_applyVotes`).
- Chat temps réel : `openChannel`/`closeChannel` (stream Supabase sur `messages`), appelés par `ChatView`.
- Alertes : locales (shared_preferences `fanzone_alerts_v1`), générées à partir des données
  (rappels J-1, nouveaux events des clubs suivis depuis la dernière visite).
- Mode local : données de démo (`buildSample*()`) à dates relatives + blob `fanzone_state_v1`.

### Supabase (projet `lizbzscnskvsszoiszlt`)
- Tables : `profiles`, `clubs`, `collectifs`, `events`, `event_members`, `collectif_members` (+ `role_id`),
  `club_follows`, `messages` (`channel` = `event:<id>` / `col:<id>`), `chants`, `chant_votes`.
- RLS : lecture publique des référentiels et compteurs ; chacun n'écrit que ses lignes (`auth.uid()`) ;
  messages réservés aux membres du salon (`can_access_channel`). Realtime activé sur `messages`, `chants`, `chant_votes`.
- Auth : **connexion anonyme** (`signInAnonymously`) + profil (`profiles.name`). Il faut que
  « Anonymous sign-ins » soit activé dans le dashboard (Authentication → Sign In / Providers).
- Seed : 6 clubs, 5 collectifs, 6 events (dates relatives via `current_date + n`), chants, messages.
- Migrations appliquées : `fanzone_schema`, `fanzone_seed`, `fanzone_harden_function`.

### Fonctionnalités
- Events : liste/recherche/filtres (sport, gratuit), carte, agenda, fiche complète
  (accroche, date/lieu/adresse, jauge + vibe, collectifs présents, matériel sonore autorisé/interdit
  + note selon le lieu, after-match, chat réservé aux participants), création d'event complète.
- Clubs : liste, fiche, suivre/ne plus suivre → alertes, section « Tes clubs jouent » sur l'accueil.
- Collectifs : rejoindre, chat membres, chants (proposer / voter / podium), rôles (1 par membre, capacité).
- Partage : bouton sur la fiche match et l'affiche d'accueil ; le lien `https://delattr-t.github.io/Fanzone/#/match/<id>`
  ouvre directement la fiche (lu dans `main()`, ouvert par `MainShell` après connexion).
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
- **v1.6 (26 nov. 2026)** — partage d'un match (WhatsApp, SMS, copie) avec lien direct `#/match/<id>`
  qui ouvre la fiche, icône « écharpes croisées » (web + Android), écran de démarrage brun nuit,
  aperçu riche des liens (Open Graph), formulaire de création refait en 4 étapes avec aperçu en direct.
- **v1.5 (25 nov. 2026)** — deuxième jeu typographique « Gazette » (Caprasimo, Atkinson Hyperlegible, Jersey 15), au choix.
- **v1.4 (25 nov. 2026)** — design « Écharpe » (chaleureux) ; carte réparée (CARTO exigeait une clé → OSM).
- **v1.3 (24 nov. 2026)** — design « Affiche de match » (remplacé par la v1.4).
- **v1.2 (24 nov. 2026)** — backend Supabase : `FanZoneRepository` (local / Supabase), auth anonyme,
  schéma + RLS + seed, chat temps réel, écriture optimiste avec rattrapage, 4 tests.
- **v1.1 (nov. 2026)** — refonte sans backend : AppState + persistance locale, suppression Firebase,
  nouveaux écrans Clubs / création d'event / chat / chants / rôles / alertes / matériel sonore / after,
  fiche event enrichie, login par prénom, widgets sticker, localisation FR, 3 tests unitaires,
  données de démo à dates relatives, 6e event (judo) + 5e collectif.

---

## Backlog

### Court terme
- [ ] Tester sur téléphone Android (USB puis APK) et faire tester à 3-5 personnes
- [ ] Géocodage des adresses à la création d'event (aujourd'hui : position ≈ celle du club)
- [x] Partage d'un match par lien direct (v1.6)
- [x] Icône + écran de démarrage (v1.6)
- [ ] Screenshots stores

### Backend
- [x] Supabase branché (v1.2)
- [ ] Activer « Anonymous sign-ins » dans le dashboard Supabase (manuel, une fois)
- [ ] Contrainte DB sur la capacité des rôles (aujourd'hui vérifiée côté client)
- [ ] Vrai compte (email/Google) lié au compte anonyme pour retrouver son profil sur un autre téléphone
- [ ] Notifications push (remplace les alertes in-app), modération/signalement (exigé par les stores)
- [ ] Le plan gratuit met le projet en pause après 7 jours sans requête → passer en Pro avant publication

### Plus tard
- Boutique / merch (prototype React existant), thermomètre d'ambiance, badges, répétitions, défis chants.

---

## Conventions de code

- Pas de commentaires sauf si le WHY est non-obvious
- Widgets privés préfixés `_`
- `.withValues(alpha: x)` et non `.withOpacity(x)` ; `Color.toARGB32()` et non `.value`
- Couleurs via `FanZoneColors.xxx` (jamais de hex inline hors design system et données de démo)
- Texte via `fz()` / `fzDisplay()` ; aucun emoji dans l'UI (les monogrammes et icônes Material les remplacent)
- Tri des events toujours via `DateTime.parse(e.date)`
- Toute mutation de données passe par une méthode d'`AppState` qui termine par `_persist()`
- Un test dans `test/widget_test.dart` pour chaque nouvelle règle métier
