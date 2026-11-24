import 'package:flutter/material.dart';

/// Un événement sportif local (match, course, critérium…).
class FanZoneEvent {
  final int id;
  final String clubId;
  final String club;
  final String sport;
  final String emoji;
  final String match;
  final String level;
  final String date; // ISO yyyy-MM-dd
  final String time; // HH:mm
  final String venue;
  final String address;
  final String venueKind; // stade | gymnase | route
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

  // After-match optionnel
  final String? afterBar;
  final String? afterAddress;

  // Matériel sonore
  final List<String> soundAllowed;
  final List<String> soundForbidden;

  // Collectifs qui ont annoncé leur présence
  final List<String> collectifIds;

  // '' = événement de démo ; sinon id de l'utilisateur créateur
  final String createdBy;

  FanZoneEvent({
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
    this.venueKind = 'stade',
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
    this.afterBar,
    this.afterAddress,
    this.soundAllowed = const [],
    this.soundForbidden = const [],
    this.collectifIds = const [],
    this.createdBy = '',
  });

  bool get hasAfter => afterBar != null && afterBar!.trim().isNotEmpty;

  DateTime? get dateTime {
    try {
      final d = DateTime.parse(date);
      final parts = time.split(':');
      return DateTime(d.year, d.month, d.day, int.parse(parts[0]), int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  bool get isPast {
    final dt = dateTime;
    if (dt == null) return false;
    return dt.isBefore(DateTime.now().subtract(const Duration(hours: 3)));
  }

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'clubId': clubId,
        'club': club,
        'sport': sport,
        'emoji': emoji,
        'match': match,
        'level': level,
        'date': date,
        'time': time,
        'venue': venue,
        'address': address,
        'venueKind': venueKind,
        'lat': lat,
        'lng': lng,
        'description': description,
        'supporters': supporters,
        'capacity': capacity,
        'color': color.toARGB32(),
        'bgColor': bgColor.toARGB32(),
        'free': free,
        'price': price,
        'isNew': isNew,
        'tags': tags,
        'afterBar': afterBar,
        'afterAddress': afterAddress,
        'soundAllowed': soundAllowed,
        'soundForbidden': soundForbidden,
        'collectifIds': collectifIds,
        'createdBy': createdBy,
      };

  factory FanZoneEvent.fromJson(Map<String, dynamic> j) => FanZoneEvent(
        id: (j['id'] as num).toInt(),
        clubId: j['clubId'] as String? ?? '',
        club: j['club'] as String? ?? '',
        sport: j['sport'] as String? ?? '',
        emoji: j['emoji'] as String? ?? '🏟️',
        match: j['match'] as String? ?? '',
        level: j['level'] as String? ?? '',
        date: j['date'] as String? ?? '',
        time: j['time'] as String? ?? '',
        venue: j['venue'] as String? ?? '',
        address: j['address'] as String? ?? '',
        venueKind: j['venueKind'] as String? ?? 'stade',
        lat: (j['lat'] as num?)?.toDouble() ?? 48.8566,
        lng: (j['lng'] as num?)?.toDouble() ?? 2.3522,
        description: j['description'] as String? ?? '',
        supporters: (j['supporters'] as num?)?.toInt() ?? 0,
        capacity: (j['capacity'] as num?)?.toInt() ?? 50,
        joined: false,
        color: Color((j['color'] as num?)?.toInt() ?? 0xFFFF8C00),
        bgColor: Color((j['bgColor'] as num?)?.toInt() ?? 0xFFFFF5E0),
        free: j['free'] as bool? ?? true,
        price: (j['price'] as num?)?.toDouble(),
        isNew: j['isNew'] as bool? ?? false,
        tags: List<String>.from(j['tags'] as List? ?? const []),
        afterBar: j['afterBar'] as String?,
        afterAddress: j['afterAddress'] as String?,
        soundAllowed: List<String>.from(j['soundAllowed'] as List? ?? const []),
        soundForbidden: List<String>.from(j['soundForbidden'] as List? ?? const []),
        collectifIds: List<String>.from(j['collectifIds'] as List? ?? const []),
        createdBy: j['createdBy'] as String? ?? '',
      );
}

// ── Données de démo ──────────────────────────────────────────────
// Les dates sont calculées par rapport à aujourd'hui pour que la démo
// reste vivante quelle que soit la date d'ouverture de l'app.
String _inDays(int n) {
  final d = DateTime.now().add(Duration(days: n));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

List<FanZoneEvent> buildSampleEvents() => [
  FanZoneEvent(
    id: 1,
    clubId: 'c1',
    club: 'AS Ménilmontant',
    sport: 'Football',
    emoji: '⚽',
    match: 'AS Ménilmontant vs FC Belleville',
    level: 'Régionale 2',
    date: _inDays(5),
    time: '15:00',
    venue: 'Terrain Émile Anthoine',
    address: '9 rue Jean Rey, 75015 Paris',
    venueKind: 'stade',
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
    afterBar: 'Le Café du Stade',
    afterAddress: '12 rue Nélaton, 75015 Paris',
    soundAllowed: ['tambour', 'trompette', 'chants', 'clapping', 'sifflet'],
    soundForbidden: ['sono', 'megaphone'],
    collectifIds: ['col1'],
  ),
  FanZoneEvent(
    id: 2,
    clubId: 'c2',
    club: 'BC Saint-Denis',
    sport: 'Basketball',
    emoji: '🏀',
    match: 'BC Saint-Denis U21 — Finale',
    level: 'Championnat IDF • U21',
    date: _inDays(2),
    time: '19:30',
    venue: 'Gymnase Géo-André',
    address: '4 rue du Landy, 93200 Saint-Denis',
    venueKind: 'gymnase',
    lat: 48.9362,
    lng: 2.3574,
    description:
        "La finale de leur vie ! Ces U21 méritent du bruit. "
        "Viens avec tes potes — plus on est, plus c'est fun !",
    supporters: 14,
    capacity: 80,
    joined: false,
    color: const Color(0xFFFF8C00),
    bgColor: const Color(0xFFFFF5E0),
    free: false,
    price: 3,
    tags: ['Finale 🏆', 'Jeunes 💪'],
    afterBar: 'Chez Momo',
    afterAddress: '22 rue de la République, 93200 Saint-Denis',
    soundAllowed: ['clapping', 'chants', 'tambour'],
    soundForbidden: ['vuvuzela', 'sono', 'megaphone', 'trompette'],
    collectifIds: ['col2'],
  ),
  FanZoneEvent(
    id: 3,
    clubId: 'c3',
    club: 'Volley Vincennes',
    sport: 'Volleyball',
    emoji: '🏐',
    match: 'Volley Vincennes F vs VB Nogent',
    level: 'Pro B Féminine',
    date: _inDays(9),
    time: '20:00',
    venue: 'Salle Polyvalente',
    address: '14 avenue du Château, 94300 Vincennes',
    venueKind: 'gymnase',
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
    soundAllowed: ['clapping', 'chants', 'sifflet'],
    soundForbidden: ['tambour', 'sono', 'megaphone'],
  ),
  FanZoneEvent(
    id: 4,
    clubId: 'c5',
    club: 'Run Club Pantin',
    sport: 'Course à pied',
    emoji: '🏃',
    match: '10km de Pantin — Édition hivernale',
    level: 'Course populaire • Toutes catégories',
    date: _inDays(16),
    time: '09:00',
    venue: 'Place de la Mairie',
    address: '45 avenue du Général Leclerc, 93500 Pantin',
    venueKind: 'route',
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
    afterBar: 'La Brasserie de la Mairie',
    afterAddress: '2 place de la Mairie, 93500 Pantin',
    soundAllowed: ['tambour', 'djembe', 'sifflet', 'clapping', 'chants', 'vuvuzela'],
    soundForbidden: ['sono', 'megaphone'],
    collectifIds: ['col3'],
  ),
  FanZoneEvent(
    id: 5,
    clubId: 'c6',
    club: 'Velo Club Vincennes',
    sport: 'Cyclisme',
    emoji: '🚴',
    match: 'Critérium de Vincennes',
    level: 'Critérium amateur • 3ème cat.',
    date: _inDays(23),
    time: '14:00',
    venue: 'Bois de Vincennes',
    address: 'Route de la Pyramide, 75012 Paris',
    venueKind: 'route',
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
    soundAllowed: ['tambour', 'sifflet', 'vuvuzela', 'chants', 'clapping'],
    soundForbidden: ['sono'],
    collectifIds: ['col4'],
  ),
  FanZoneEvent(
    id: 6,
    clubId: 'c4',
    club: 'Judo Club Aubervilliers',
    sport: 'Judo',
    emoji: '🥋',
    match: 'Tournoi inter-clubs — Finales cadets',
    level: 'Tournoi départemental • Cadets',
    date: _inDays(12),
    time: '14:30',
    venue: 'Dojo municipal',
    address: '31 rue Henri Barbusse, 93300 Aubervilliers',
    venueKind: 'gymnase',
    lat: 48.9146,
    lng: 2.3838,
    description:
        "Les cadets du club jouent les finales à domicile. Un dojo qui chante, "
        "ça n'arrive jamais — soyons les premiers !",
    supporters: 3,
    capacity: 40,
    joined: false,
    color: const Color(0xFF9B27AF),
    bgColor: const Color(0xFFF6E8FF),
    free: true,
    tags: ['Combat 🥋', 'Jeunes 💪'],
    isNew: true,
    soundAllowed: ['clapping', 'chants'],
    soundForbidden: ['tambour', 'djembe', 'trompette', 'vuvuzela', 'sifflet', 'sono', 'megaphone'],
  ),
];
