import 'package:flutter/material.dart';

class Club {
  final String id;
  final String name;
  final String shortName;
  final String emoji;
  final String sport;
  final String city;
  final Color color;
  final Color bgColor;
  final String description;
  final int followersBase;
  final String homeVenue;

  const Club({
    required this.id,
    required this.name,
    required this.shortName,
    required this.emoji,
    required this.sport,
    required this.city,
    required this.color,
    required this.bgColor,
    required this.description,
    required this.followersBase,
    required this.homeVenue,
  });
}

const sampleClubs = [
  Club(
    id: 'c1', name: 'AS Ménilmontant', shortName: 'Ménil', emoji: '⚽', sport: 'Football',
    city: 'Paris 20e', color: Color(0xFFFF4D4D), bgColor: Color(0xFFFFF0F0),
    description: "Club de quartier fondé en 1974. Deux équipes seniors, une école de foot et un kop qui ne lâche rien.",
    followersBase: 128, homeVenue: 'Terrain Émile Anthoine',
  ),
  Club(
    id: 'c2', name: 'BC Saint-Denis', shortName: 'BC SDenis', emoji: '🏀', sport: 'Basketball',
    city: 'Saint-Denis 93', color: Color(0xFFFF8C00), bgColor: Color(0xFFFFF5E0),
    description: "Le basket dionysien de U9 à seniors. Les U21 visent le titre IDF cette saison.",
    followersBase: 96, homeVenue: 'Gymnase Géo-André',
  ),
  Club(
    id: 'c3', name: 'Volley Vincennes', shortName: 'Vincennes', emoji: '🏐', sport: 'Volleyball',
    city: 'Vincennes 94', color: Color(0xFF0096FF), bgColor: Color(0xFFE8F4FF),
    description: "Équipe féminine en Pro B, équipe masculine en Nationale 3. Ambiance familiale garantie.",
    followersBase: 74, homeVenue: 'Salle Polyvalente',
  ),
  Club(
    id: 'c4', name: 'Judo Club Aubervilliers', shortName: 'Aubervilliers', emoji: '🥋', sport: 'Judo',
    city: 'Aubervilliers 93', color: Color(0xFF9B27AF), bgColor: Color(0xFFF6E8FF),
    description: "Un des plus gros clubs de judo du 93. Tournois inter-clubs tous les deux mois.",
    followersBase: 41, homeVenue: 'Dojo municipal',
  ),
  Club(
    id: 'c5', name: 'Run Club Pantin', shortName: 'Pantin', emoji: '🏃', sport: 'Course à pied',
    city: 'Pantin 93', color: Color(0xFF00A86B), bgColor: Color(0xFFE0FFF4),
    description: "Collectif de coureurs et organisateur du 10km de Pantin. Tous niveaux, toutes allures.",
    followersBase: 210, homeVenue: 'Place de la Mairie',
  ),
  Club(
    id: 'c6', name: 'Velo Club Vincennes', shortName: 'VéloVinc', emoji: '🚴', sport: 'Cyclisme',
    city: 'Vincennes 94', color: Color(0xFFE65C00), bgColor: Color(0xFFFFF0E0),
    description: "Club cycliste amateur, critériums dans le Bois de Vincennes et sorties du dimanche.",
    followersBase: 63, homeVenue: 'Bois de Vincennes',
  ),
];
