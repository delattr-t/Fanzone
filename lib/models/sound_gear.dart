class SoundGear {
  final String id;
  final String label;
  final String emoji;
  const SoundGear({required this.id, required this.label, required this.emoji});
}

const soundGearCatalog = [
  SoundGear(id: 'tambour',   label: 'Tambours',        emoji: '🥁'),
  SoundGear(id: 'djembe',    label: 'Djembés',         emoji: '🪘'),
  SoundGear(id: 'trompette', label: 'Trompettes',      emoji: '🎺'),
  SoundGear(id: 'vuvuzela',  label: 'Vuvuzelas',       emoji: '📯'),
  SoundGear(id: 'sifflet',   label: 'Sifflets',        emoji: '🔔'),
  SoundGear(id: 'clapping',  label: 'Clapping boards', emoji: '👏'),
  SoundGear(id: 'chants',    label: 'Chants',          emoji: '🎤'),
  SoundGear(id: 'sono',      label: 'Sono',            emoji: '🔊'),
  SoundGear(id: 'megaphone', label: 'Mégaphone',       emoji: '📣'),
];

SoundGear gearById(String id) =>
    soundGearCatalog.firstWhere((g) => g.id == id, orElse: () => SoundGear(id: id, label: id, emoji: '🎵'));

/// Note contextuelle selon le type de lieu (gymnase, stade, voie publique…).
String soundNoteForVenueKind(String kind) {
  switch (kind) {
    case 'gymnase':
      return 'En salle, le son résonne fort : les tambours et clapping boards suffisent largement, '
          'évitez la sono et le mégaphone.';
    case 'route':
      return 'Sur la voie publique, pas de sono ni de mégaphone sans autorisation de la mairie. '
          'Sifflets, cloches et voix font le job !';
    case 'stade':
    default:
      return 'En plein air, tout passe mieux : tambours, trompettes et chants sont les bienvenus. '
          'Vérifiez auprès du club pour la sono.';
  }
}
