import 'package:flutter/material.dart';

/// Un collectif de supporters (kop, crew…) rattaché à un club ou à un sport.
class Collectif {
  final String id;
  final String name;
  final String club;
  final String clubId;
  final String emoji;
  final Color color;
  final Color bgColor;
  final String description;
  int members;
  bool joined;

  /// Nombre de places déjà prises par rôle dans la démo (hors utilisateur).
  final Map<String, int> roleTakenBase;

  Collectif({
    required this.id,
    required this.name,
    required this.club,
    required this.clubId,
    required this.emoji,
    required this.color,
    required this.bgColor,
    required this.description,
    required this.members,
    required this.joined,
    this.roleTakenBase = const {},
  });
}

/// Rôle dans un collectif (1 rôle max par membre et par collectif).
class CollectifRole {
  final String id;
  final String label;
  final String emoji;
  final int max;
  final String hint;
  const CollectifRole({
    required this.id,
    required this.label,
    required this.emoji,
    required this.max,
    required this.hint,
  });
}

const roleCatalog = [
  CollectifRole(id: 'chef',     label: 'Chef de chant',    emoji: '🎤', max: 1, hint: 'Lance les chants et donne le tempo'),
  CollectifRole(id: 'tambour',  label: 'Tambour',          emoji: '🥁', max: 2, hint: 'Tient le rythme pendant tout le match'),
  CollectifRole(id: 'trompette',label: 'Trompette',        emoji: '🎺', max: 2, hint: 'Les fanfares entre deux actions'),
  CollectifRole(id: 'drapeau',  label: 'Porte-drapeau',    emoji: '🚩', max: 3, hint: 'Les couleurs du club bien en vue'),
  CollectifRole(id: 'tifo',     label: 'Tifo / Banderole', emoji: '🎨', max: 2, hint: 'Prépare et déploie le tifo'),
  CollectifRole(id: 'accueil',  label: 'Accueil nouveaux', emoji: '🤝', max: 2, hint: 'Explique les chants aux nouveaux'),
  CollectifRole(id: 'ultra',    label: 'Ultra de kop',     emoji: '🔥', max: 6, hint: 'Chante, saute, met le feu'),
  CollectifRole(id: 'clapping', label: 'Clapping boards',  emoji: '👏', max: 4, hint: 'Distribue et mène le clapping'),
];

CollectifRole roleById(String id) =>
    roleCatalog.firstWhere((r) => r.id == id, orElse: () => roleCatalog.last);

List<Collectif> buildSampleCollectifs() => [
  Collectif(
    id: 'col1', name: 'Les Irréductibles', club: 'AS Ménilmontant', clubId: 'c1', emoji: '🔴',
    color: const Color(0xFFE0251B), bgColor: const Color(0xFFFBE7E7),
    description: "Le kop historique du terrain Émile Anthoine. Tambours, drapeaux, et bonne humeur depuis 2008.",
    members: 34, joined: false,
    roleTakenBase: {'chef': 1, 'tambour': 1, 'drapeau': 2, 'ultra': 4, 'clapping': 2},
  ),
  Collectif(
    id: 'col2', name: 'North Side Crew', club: 'BC Saint-Denis', clubId: 'c2', emoji: '🧡',
    color: const Color(0xFFF0471F), bgColor: const Color(0xFFFCE9E3),
    description: "On occupe le côté Nord du gymnase. Spécialistes du clapping syncopé et du chant collectif.",
    members: 22, joined: false,
    roleTakenBase: {'chef': 1, 'clapping': 3, 'ultra': 2, 'accueil': 1},
  ),
  Collectif(
    id: 'col3', name: 'Les Coureurs du Dimanche', club: 'Run Club Pantin', clubId: 'c5', emoji: '🏃',
    color: const Color(0xFF1F8A4C), bgColor: const Color(0xFFE6F4EB),
    description: "On encourage tous les participants du départ à l'arrivée — du premier au dernier !",
    members: 18, joined: false,
    roleTakenBase: {'tambour': 2, 'ultra': 1, 'accueil': 2},
  ),
  Collectif(
    id: 'col4', name: 'Velo Squad 93', club: 'Velo Club Vincennes', clubId: 'c6', emoji: '🚴',
    color: const Color(0xFF1F4FD8), bgColor: const Color(0xFFE6ECFB),
    description: "On se poste aux cols et virages pour faire du bruit. Klaxons, sifflets et cris garantis !",
    members: 12, joined: false,
    roleTakenBase: {'drapeau': 1, 'ultra': 3},
  ),
  Collectif(
    id: 'col5', name: 'Dojo Ultras', club: 'Judo Club Aubervilliers', clubId: 'c4', emoji: '🥋',
    color: const Color(0xFF6A2FB5), bgColor: const Color(0xFFEFE7FA),
    description: "Tout nouveau collectif : on veut faire chanter un dojo pour la première fois. Rejoins-nous !",
    members: 4, joined: false,
    roleTakenBase: {'accueil': 1},
  ),
];
