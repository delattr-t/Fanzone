import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';
import '../screens/collectifs_screen.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ── EVENTS ────────────────────────────────────────────────────

  static Stream<List<FanZoneEvent>> eventsStream(String userId) {
    return _db.collection('events').orderBy('date').snapshots().asyncMap(
      (snap) async {
        final joined = await _joinedEventIds(userId);
        final supporterCounts = await _supporterCounts(snap.docs.map((d) => d.id).toList());
        return snap.docs.map((doc) {
          final data = doc.data();
          final isJoined = joined.contains(doc.id);
          return FanZoneEvent.fromFirestore(
            doc.id,
            data,
            joined: isJoined,
            supporters: supporterCounts[doc.id] ?? (data['supportersBase'] as int? ?? 0),
          );
        }).toList();
      },
    );
  }

  static Future<Set<String>> _joinedEventIds(String userId) async {
    if (userId.isEmpty) return {};
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('joinedEvents')
        .get();
    return snap.docs.map((d) => d.id).toSet();
  }

  static Future<Map<String, int>> _supporterCounts(List<String> eventIds) async {
    if (eventIds.isEmpty) return {};
    final counts = <String, int>{};
    for (final id in eventIds) {
      final snap = await _db
          .collection('events')
          .doc(id)
          .collection('supporters')
          .count()
          .get();
      counts[id] = snap.count ?? 0;
    }
    return counts;
  }

  static Future<void> toggleJoinEvent(String eventId, bool join) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userEventRef = _db
        .collection('users')
        .doc(uid)
        .collection('joinedEvents')
        .doc(eventId);

    final supporterRef = _db
        .collection('events')
        .doc(eventId)
        .collection('supporters')
        .doc(uid);

    final batch = _db.batch();
    if (join) {
      batch.set(userEventRef, {'joinedAt': FieldValue.serverTimestamp()});
      batch.set(supporterRef, {'joinedAt': FieldValue.serverTimestamp()});
    } else {
      batch.delete(userEventRef);
      batch.delete(supporterRef);
    }
    await batch.commit();
  }

  // ── COLLECTIFS ────────────────────────────────────────────────

  static Stream<List<Collectif>> collectifsStream(String userId) {
    return _db.collection('collectifs').snapshots().asyncMap(
      (snap) async {
        final joined = await _joinedCollectifIds(userId);
        return snap.docs.map((doc) {
          final data = doc.data();
          return Collectif.fromFirestore(
            doc.id,
            data,
            joined: joined.contains(doc.id),
          );
        }).toList();
      },
    );
  }

  static Future<Set<String>> _joinedCollectifIds(String userId) async {
    if (userId.isEmpty) return {};
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('joinedCollectifs')
        .get();
    return snap.docs.map((d) => d.id).toSet();
  }

  static Future<void> toggleJoinCollectif(String collectifId, bool join) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userColRef = _db
        .collection('users')
        .doc(uid)
        .collection('joinedCollectifs')
        .doc(collectifId);

    final memberRef = _db
        .collection('collectifs')
        .doc(collectifId)
        .collection('members')
        .doc(uid);

    final batch = _db.batch();
    if (join) {
      batch.set(userColRef, {'joinedAt': FieldValue.serverTimestamp()});
      batch.set(memberRef, {'joinedAt': FieldValue.serverTimestamp()});
    } else {
      batch.delete(userColRef);
      batch.delete(memberRef);
    }
    await batch.commit();
  }

  // ── USER PROFILE ──────────────────────────────────────────────

  static Future<void> updateDisplayName(String name) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set(
      {'displayName': name, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  static Future<String?> getDisplayName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['displayName'] as String?;
  }

  // ── SEED (données de démo) ────────────────────────────────────

  static Future<void> seedIfEmpty() async {
    final snap = await _db.collection('events').limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final e in sampleEventsData) {
      batch.set(_db.collection('events').doc(), e);
    }
    for (final c in sampleCollectifsData) {
      batch.set(_db.collection('collectifs').doc(), c);
    }
    await batch.commit();
  }
}

// ── Données de seed Firestore ─────────────────────────────────────
const sampleEventsData = [
  {
    'clubId': 'c1', 'club': 'AS Ménilmontant', 'sport': 'Football',
    'emoji': '⚽', 'match': 'AS Ménilmontant vs FC Belleville',
    'level': 'Régionale 2', 'date': '2026-05-24', 'time': '15:00',
    'venue': 'Terrain Émile Anthoine', 'address': 'Paris 15e',
    'lat': 48.8414, 'lng': 2.2946,
    'description': "Derby de quartier ! Ces deux clubs se connaissent depuis 30 ans. Venez mettre l'ambiance — même à 20, ça change tout pour les joueurs.",
    'supportersBase': 8, 'capacity': 50, 'colorHex': 0xFFFF4D4D,
    'bgColorHex': 0xFFFFF0F0, 'free': true, 'price': null, 'isNew': false,
    'tags': ['Derby 🔥', 'Famille 👨‍👩‍👧'],
  },
  {
    'clubId': 'c2', 'club': 'BC Saint-Denis', 'sport': 'Basketball',
    'emoji': '🏀', 'match': 'BC Saint-Denis U21 — Finale',
    'level': 'Championnat IDF • U21', 'date': '2026-05-22', 'time': '19:30',
    'venue': 'Gymnase Géo-André', 'address': 'Saint-Denis 93',
    'lat': 48.9362, 'lng': 2.3574,
    'description': "La finale de leur vie ! Ces U21 méritent du bruit. Viens avec tes potes — plus on est, plus c'est fun !",
    'supportersBase': 14, 'capacity': 80, 'colorHex': 0xFFFF8C00,
    'bgColorHex': 0xFFFFF5E0, 'free': false, 'price': 3.0, 'isNew': false,
    'tags': ['Finale 🏆', 'Jeunes 💪'],
  },
  {
    'clubId': 'c3', 'club': 'Volley Vincennes', 'sport': 'Volleyball',
    'emoji': '🏐', 'match': 'Volley Vincennes F vs VB Nogent',
    'level': 'Pro B Féminine', 'date': '2026-05-29', 'time': '20:00',
    'venue': 'Salle Polyvalente', 'address': 'Vincennes 94',
    'lat': 48.8483, 'lng': 2.4390,
    'description': "L'équipe féminine lutte pour le maintien. Bonne ambiance garantie — venez en famille !",
    'supportersBase': 6, 'capacity': 60, 'colorHex': 0xFF0096FF,
    'bgColorHex': 0xFFE8F4FF, 'free': true, 'price': null, 'isNew': false,
    'tags': ['Maintien ⚡', 'Équipe féminine 💙'],
  },
  {
    'clubId': 'c5', 'club': 'Run Club Pantin', 'sport': 'Course à pied',
    'emoji': '🏃', 'match': '10km de Pantin — Édition 2026',
    'level': 'Course populaire • Toutes catégories', 'date': '2026-06-14', 'time': '09:00',
    'venue': 'Place de la Mairie', 'address': 'Pantin 93',
    'lat': 48.8944, 'lng': 2.4051,
    'description': "La course populaire de Pantin revient ! 500 coureurs attendus. Postez-vous au km 5 pour faire exploser l'ambiance !",
    'supportersBase': 11, 'capacity': 200, 'colorHex': 0xFF00A86B,
    'bgColorHex': 0xFFE0FFF4, 'free': true, 'price': null, 'isNew': true,
    'tags': ['Course pop 🏃', 'Familles 👨‍👩‍👧'],
  },
  {
    'clubId': 'c6', 'club': 'Velo Club Vincennes', 'sport': 'Cyclisme',
    'emoji': '🚴', 'match': 'Critérium de Vincennes',
    'level': 'Critérium amateur • 3ème cat.', 'date': '2026-06-21', 'time': '14:00',
    'venue': 'Bois de Vincennes', 'address': 'Vincennes 94',
    'lat': 48.8330, 'lng': 2.4470,
    'description': "25 tours de circuit dans le Bois. Les coureurs passent toutes les 4 minutes — positionnez-vous au virage 3 pour créer un couloir de bruit !",
    'supportersBase': 7, 'capacity': 80, 'colorHex': 0xFFE65C00,
    'bgColorHex': 0xFFFFF0E0, 'free': true, 'price': null, 'isNew': true,
    'tags': ['Cyclisme 🚴', 'Plein air 🌳'],
  },
];

const sampleCollectifsData = [
  {
    'name': 'Les Irréductibles', 'club': 'AS Ménilmontant', 'emoji': '🔴',
    'colorHex': 0xFFFF4D4D, 'bgColorHex': 0xFFFFF0F0,
    'description': "Le kop historique du terrain Émile Anthoine. Tambours, drapeaux, et bonne humeur depuis 2008.",
    'membersBase': 34,
  },
  {
    'name': 'North Side Crew', 'club': 'BC Saint-Denis', 'emoji': '🧡',
    'colorHex': 0xFFFF8C00, 'bgColorHex': 0xFFFFF5E0,
    'description': "On occupe le côté Nord du gymnase. Spécialistes du clapping syncopé et du chant collectif.",
    'membersBase': 22,
  },
  {
    'name': 'Les Coureurs du Dimanche', 'club': 'Course locale', 'emoji': '🏃',
    'colorHex': 0xFF00A86B, 'bgColorHex': 0xFFE0FFF4,
    'description': "On encourage tous les participants du départ à l'arrivée — du premier au dernier !",
    'membersBase': 18,
  },
  {
    'name': 'Velo Squad 93', 'club': 'Cyclisme amateur', 'emoji': '🚴',
    'colorHex': 0xFF0096FF, 'bgColorHex': 0xFFE8F4FF,
    'description': "On se poste aux cols et virages pour faire du bruit. Klaxons, sifflets et cris garantis !",
    'membersBase': 12,
  },
];
