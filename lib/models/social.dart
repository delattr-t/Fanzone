// Modèles « sociaux » : profil, messages de chat, chants, alertes.

class UserProfile {
  final String id;
  String name;
  final DateTime createdAt;

  UserProfile({required this.id, required this.name, required this.createdAt});

  String get initial => name.trim().isEmpty ? 'F' : name.trim()[0].toUpperCase();

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'createdAt': createdAt.toIso8601String()};

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Fan',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Un message dans un salon. `channel` vaut `event:<id>` ou `col:<id>`.
class ChatMessage {
  final String id;
  final String channel;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime sentAt;

  ChatMessage({
    required this.id,
    required this.channel,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.sentAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'channel': channel,
        'authorId': authorId,
        'authorName': authorName,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        channel: j['channel'] as String,
        authorId: j['authorId'] as String? ?? '',
        authorName: j['authorName'] as String? ?? 'Fan',
        text: j['text'] as String? ?? '',
        sentAt: DateTime.tryParse(j['sentAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Un chant proposé dans un collectif, soumis au vote.
class Chant {
  final String id;
  final String collectifId;
  final String title;
  final String lyrics;
  final String rhythm;
  final String authorId;
  final String authorName;
  int votes;
  final DateTime createdAt;

  Chant({
    required this.id,
    required this.collectifId,
    required this.title,
    required this.lyrics,
    required this.rhythm,
    required this.authorId,
    required this.authorName,
    required this.votes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'collectifId': collectifId,
        'title': title,
        'lyrics': lyrics,
        'rhythm': rhythm,
        'authorId': authorId,
        'authorName': authorName,
        'votes': votes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Chant.fromJson(Map<String, dynamic> j) => Chant(
        id: j['id'] as String,
        collectifId: j['collectifId'] as String,
        title: j['title'] as String? ?? '',
        lyrics: j['lyrics'] as String? ?? '',
        rhythm: j['rhythm'] as String? ?? '',
        authorId: j['authorId'] as String? ?? '',
        authorName: j['authorName'] as String? ?? 'Fan',
        votes: (j['votes'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Alerte in-app (nouvel event d'un club suivi, rappel J-1…).
class FanAlert {
  final String id;
  final String emoji;
  final String title;
  final String body;
  final DateTime date;
  final int? eventId;
  bool read;

  FanAlert({
    required this.id,
    required this.emoji,
    required this.title,
    required this.body,
    required this.date,
    this.eventId,
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'emoji': emoji,
        'title': title,
        'body': body,
        'date': date.toIso8601String(),
        'eventId': eventId,
        'read': read,
      };

  factory FanAlert.fromJson(Map<String, dynamic> j) => FanAlert(
        id: j['id'] as String,
        emoji: j['emoji'] as String? ?? '🔔',
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        eventId: (j['eventId'] as num?)?.toInt(),
        read: j['read'] as bool? ?? false,
      );
}

// ── Données de démo ──────────────────────────────────────────────

List<ChatMessage> buildSampleMessages() {
  final now = DateTime.now();
  return [
    ChatMessage(id: 'm1', channel: 'col:col1', authorId: 'demo-karim', authorName: 'Karim',
        text: "Salut la team ! Qui ramène le tambour samedi ?", sentAt: now.subtract(const Duration(hours: 26))),
    ChatMessage(id: 'm2', channel: 'col:col1', authorId: 'demo-lea', authorName: 'Léa',
        text: "Moi 🥁 Et j'ai 2 drapeaux en rab si besoin", sentAt: now.subtract(const Duration(hours: 25))),
    ChatMessage(id: 'm3', channel: 'col:col1', authorId: 'demo-karim', authorName: 'Karim',
        text: "Top. RDV 14h15 devant l'entrée, on se met côté tribune gauche", sentAt: now.subtract(const Duration(hours: 20))),
    ChatMessage(id: 'm4', channel: 'col:col2', authorId: 'demo-sofia', authorName: 'Sofia',
        text: "La finale c'est VENDREDI 🔥 On fait une répèt' du clapping jeudi soir ?", sentAt: now.subtract(const Duration(hours: 8))),
    ChatMessage(id: 'm5', channel: 'col:col2', authorId: 'demo-tom', authorName: 'Tom',
        text: "Chaud. 19h au city stade ?", sentAt: now.subtract(const Duration(hours: 7))),
    ChatMessage(id: 'm6', channel: 'event:2', authorId: 'demo-sofia', authorName: 'Sofia',
        text: "Pour ceux qui viennent à la finale : le gymnase ouvre à 18h45, on garde des places côté Nord 🧡",
        sentAt: now.subtract(const Duration(hours: 5))),
    ChatMessage(id: 'm7', channel: 'event:1', authorId: 'demo-lea', authorName: 'Léa',
        text: "Qui est chaud pour l'after au Café du Stade ? 🍻", sentAt: now.subtract(const Duration(hours: 3))),
    ChatMessage(id: 'm8', channel: 'col:col3', authorId: 'demo-ines', authorName: 'Inès',
        text: "On se place au km 5 comme d'hab, ramenez des cloches 🔔", sentAt: now.subtract(const Duration(days: 2))),
    ChatMessage(id: 'm9', channel: 'col:col4', authorId: 'demo-nico', authorName: 'Nico',
        text: "Virage 3 ou ligne droite d'arrivée pour le critérium ?", sentAt: now.subtract(const Duration(days: 1))),
  ];
}

List<Chant> buildSampleChants() {
  final now = DateTime.now();
  return [
    Chant(id: 'ch1', collectifId: 'col1', title: 'Allez Ménil !',
        lyrics: "Allez Ménil, allez allez !\nOn est là, on va chanter !\nMénilmontant, c'est notre quartier !",
        rhythm: 'Clap-clap-clap • clap-clap', authorId: 'demo-karim', authorName: 'Karim', votes: 23,
        createdAt: now.subtract(const Duration(days: 40))),
    Chant(id: 'ch2', collectifId: 'col1', title: 'Rouge et noir',
        lyrics: "Rouge et noir, rouge et noir,\nMénil ce soir va tout avoir !",
        rhythm: 'Tambour lent : boum… boum… boum-boum', authorId: 'demo-lea', authorName: 'Léa', votes: 17,
        createdAt: now.subtract(const Duration(days: 30))),
    Chant(id: 'ch3', collectifId: 'col1', title: 'Olé Belleville (pour les chambrer)',
        lyrics: "Olé olé olé olé,\nBelleville rentre à pied !",
        rhythm: 'Sur l\'air de « Olé olé »', authorId: 'demo-yanis', authorName: 'Yanis', votes: 9,
        createdAt: now.subtract(const Duration(days: 10))),
    Chant(id: 'ch4', collectifId: 'col2', title: 'North Side !',
        lyrics: "North Side ! (clap clap)\nNorth Side ! (clap clap)\nSaint-Denis on est là !",
        rhythm: 'Clapping syncopé x2', authorId: 'demo-sofia', authorName: 'Sofia', votes: 31,
        createdAt: now.subtract(const Duration(days: 60))),
    Chant(id: 'ch5', collectifId: 'col2', title: 'Défense !',
        lyrics: "DÉ-FENSE ! (boum boum)\nDÉ-FENSE ! (boum boum)",
        rhythm: 'Tambour sur chaque syllabe', authorId: 'demo-tom', authorName: 'Tom', votes: 14,
        createdAt: now.subtract(const Duration(days: 20))),
    Chant(id: 'ch6', collectifId: 'col3', title: 'Du premier au dernier',
        lyrics: "Du premier au dernier,\nOn est là pour vous pousser !\nAllez allez allez !",
        rhythm: 'Cloche sur « allez »', authorId: 'demo-ines', authorName: 'Inès', votes: 12,
        createdAt: now.subtract(const Duration(days: 15))),
    Chant(id: 'ch7', collectifId: 'col4', title: 'Monte monte !',
        lyrics: "Monte monte monte !\nLe virage il est à toi !",
        rhythm: 'Crié au passage des coureurs', authorId: 'demo-nico', authorName: 'Nico', votes: 8,
        createdAt: now.subtract(const Duration(days: 5))),
  ];
}
