import 'package:flutter/material.dart';

class FanZoneEvent {
  final String firestoreId;
  final int id;
  final String clubId;
  final String club;
  final String sport;
  final String emoji;
  final String match;
  final String level;
  final String date;
  final String time;
  final String venue;
  final String address;
  final double lat;
  final double lng;
  final String description;
  int supporters;
  final int capacity;
  bool joined;
  final Color color;
  final Color bgColor;
  final bool free;
  final double? price;
  final bool isNew;
  final List<String> tags;

  FanZoneEvent({
    this.firestoreId = '',
    required this.id,
    required this.clubId,
    required this.club,
    required this.sport,
    required this.emoji,
    required this.match,
    required this.level,
    required this.date,
    required this.time,
    required this.venue,
    required this.address,
    required this.lat,
    required this.lng,
    required this.description,
    required this.supporters,
    required this.capacity,
    required this.joined,
    required this.color,
    required this.bgColor,
    required this.free,
    this.price,
    this.isNew = false,
    this.tags = const [],
  });

  String get daysUntil {
    try {
      final eventDate = DateTime.parse(date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final diff = eventDate.difference(today).inDays;
      if (diff < 0) return 'Passé';
      if (diff == 0) return "Aujourd'hui !";
      if (diff == 1) return 'Demain !';
      return 'J-$diff';
    } catch (_) {
      return '';
    }
  }

  String get dateFormatted {
    try {
      final d = DateTime.parse(date);
      const months = ['jan', 'fév', 'mar', 'avr', 'mai', 'jun',
                      'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'];
      return '${d.day} ${months[d.month - 1]}';
    } catch (_) {
      return date;
    }
  }

  String get vibeLabel {
    final pct = supporters / capacity;
    if (pct < 0.15) return 'Besoin de vous 🙏';
    if (pct < 0.45) return 'Ça monte ! 🌱';
    return 'Ambiance de folie 🎉';
  }

  Color get vibeColor {
    final pct = supporters / capacity;
    if (pct < 0.15) return const Color(0xFFC62828);
    if (pct < 0.45) return const Color(0xFFE65C00);
    return const Color(0xFF1B5E20);
  }

  Color get vibeBgColor {
    final pct = supporters / capacity;
    if (pct < 0.15) return const Color(0xFFFFEBEE);
    if (pct < 0.45) return const Color(0xFFFFF3E0);
    return const Color(0xFFE8F5E9);
  }

  double get fillPct => (supporters / capacity).clamp(0.0, 1.0);

  factory FanZoneEvent.fromFirestore(
    String docId,
    Map<String, dynamic> data, {
    required bool joined,
    required int supporters,
  }) {
    return FanZoneEvent(
      firestoreId: docId,
      id: docId.hashCode,
      clubId: data['clubId'] as String? ?? '',
      club: data['club'] as String? ?? '',
      sport: data['sport'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '🏟️',
      match: data['match'] as String? ?? '',
      level: data['level'] as String? ?? '',
      date: data['date'] as String? ?? '',
      time: data['time'] as String? ?? '',
      venue: data['venue'] as String? ?? '',
      address: data['address'] as String? ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 48.8566,
      lng: (data['lng'] as num?)?.toDouble() ?? 2.3522,
      description: data['description'] as String? ?? '',
      supporters: supporters,
      capacity: (data['capacity'] as num?)?.toInt() ?? 50,
      joined: joined,
      color: Color((data['colorHex'] as int?) ?? 0xFFFF8C00),
      bgColor: Color((data['bgColorHex'] as int?) ?? 0xFFFFF5E0),
      free: data['free'] as bool? ?? true,
      price: (data['price'] as num?)?.toDouble(),
      isNew: data['isNew'] as bool? ?? false,
      tags: List<String>.from(data['tags'] as List? ?? []),
    );
  }
}

// ── Données de démo ──────────────────────────────────────────────
List<FanZoneEvent> sampleEvents = [
  FanZoneEvent(
    id: 1,
    clubId: 'c1',
    club: 'AS Ménilmontant',
    sport: 'Football',
    emoji: '⚽',
    match: 'AS Ménilmontant vs FC Belleville',
    level: 'Régionale 2',
    date: '2026-05-24',
    time: '15:00',
    venue: 'Terrain Émile Anthoine',
    address: 'Paris 15e',
    lat: 48.8414,
    lng: 2.2946,
    description:
        "Derby de quartier ! Ces deux clubs se connaissent depuis 30 ans. "
        "Venez mettre l'ambiance — même à 20, ça change tout pour les joueurs.",
    supporters: 8,
    capacity: 50,
    joined: false,
    color: const Color(0xFFFF4D4D),
    bgColor: const Color(0xFFFFF0F0),
    free: true,
    tags: ['Derby 🔥', 'Famille 👨‍👩‍👧'],
  ),
  FanZoneEvent(
    id: 2,
    clubId: 'c2',
    club: 'BC Saint-Denis',
    sport: 'Basketball',
    emoji: '🏀',
    match: 'BC Saint-Denis U21 — Finale',
    level: 'Championnat IDF • U21',
    date: '2026-05-22',
    time: '19:30',
    venue: 'Gymnase Géo-André',
    address: 'Saint-Denis 93',
    lat: 48.9362,
    lng: 2.3574,
    description:
        "La finale de leur vie ! Ces U21 méritent du bruit. "
        "Viens avec tes potes — plus on est, plus c'est fun !",
    supporters: 14,
    capacity: 80,
    joined: true,
    color: const Color(0xFFFF8C00),
    bgColor: const Color(0xFFFFF5E0),
    free: false,
    price: 3,
    tags: ['Finale 🏆', 'Jeunes 💪'],
    isNew: false,
  ),
  FanZoneEvent(
    id: 3,
    clubId: 'c3',
    club: 'Volley Vincennes',
    sport: 'Volleyball',
    emoji: '🏐',
    match: 'Volley Vincennes F vs VB Nogent',
    level: 'Pro B Féminine',
    date: '2026-05-29',
    time: '20:00',
    venue: 'Salle Polyvalente',
    address: 'Vincennes 94',
    lat: 48.8483,
    lng: 2.4390,
    description:
        "L'équipe féminine lutte pour le maintien. "
        "Bonne ambiance garantie — venez en famille !",
    supporters: 6,
    capacity: 60,
    joined: false,
    color: const Color(0xFF0096FF),
    bgColor: const Color(0xFFE8F4FF),
    free: true,
    tags: ['Maintien ⚡', 'Équipe féminine 💙'],
  ),
  FanZoneEvent(
    id: 4,
    clubId: 'c5',
    club: 'Run Club Pantin',
    sport: 'Course à pied',
    emoji: '🏃',
    match: '10km de Pantin — Édition 2026',
    level: 'Course populaire • Toutes catégories',
    date: '2026-06-14',
    time: '09:00',
    venue: 'Place de la Mairie',
    address: 'Pantin 93',
    lat: 48.8944,
    lng: 2.4051,
    description:
        "La course populaire de Pantin revient ! 500 coureurs attendus. "
        "Postez-vous au km 5 pour faire exploser l'ambiance !",
    supporters: 11,
    capacity: 200,
    joined: false,
    color: const Color(0xFF00A86B),
    bgColor: const Color(0xFFE0FFF4),
    free: true,
    tags: ['Course pop 🏃', 'Familles 👨‍👩‍👧'],
    isNew: true,
  ),
  FanZoneEvent(
    id: 5,
    clubId: 'c6',
    club: 'Velo Club Vincennes',
    sport: 'Cyclisme',
    emoji: '🚴',
    match: 'Critérium de Vincennes',
    level: 'Critérium amateur • 3ème cat.',
    date: '2026-06-21',
    time: '14:00',
    venue: 'Bois de Vincennes',
    address: 'Vincennes 94',
    lat: 48.8330,
    lng: 2.4470,
    description:
        "25 tours de circuit dans le Bois. Les coureurs passent toutes les 4 minutes "
        "— positionnez-vous au virage 3 pour créer un couloir de bruit !",
    supporters: 7,
    capacity: 80,
    joined: false,
    color: const Color(0xFFE65C00),
    bgColor: const Color(0xFFFFF0E0),
    free: true,
    tags: ['Cyclisme 🚴', 'Plein air 🌳'],
    isNew: true,
  ),
];
