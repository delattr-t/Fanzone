import '../models/club.dart';
import '../models/collectif.dart';
import '../models/event.dart';
import '../models/social.dart';

/// Photo complète des données au chargement.
class DataSnapshot {
  final UserProfile? user;
  final List<Club> clubs;
  final List<Collectif> collectifs;
  final List<FanZoneEvent> events;
  final List<Chant> chants;
  final List<ChatMessage> messages;
  final Set<int> joinedEventIds;
  final Set<String> joinedCollectifIds;
  final Set<String> followedClubIds;
  final Set<String> votedChantIds;
  final Map<String, String> myRoles;

  const DataSnapshot({
    required this.user,
    required this.clubs,
    required this.collectifs,
    required this.events,
    required this.chants,
    required this.messages,
    required this.joinedEventIds,
    required this.joinedCollectifIds,
    required this.followedClubIds,
    required this.votedChantIds,
    required this.myRoles,
  });
}

/// Source de données de l'app. Deux implémentations : locale et Supabase.
///
/// Contrat : les compteurs (`supporters`, `members`, `votes`, `followersBase`)
/// renvoyés dans le snapshot n'incluent PAS la contribution de l'utilisateur
/// courant ; `AppState` l'ajoute lui-même à partir des ensembles d'ids.
abstract class FanZoneRepository {
  Future<UserProfile?> currentUser();
  Future<UserProfile> signIn(String name);
  Future<void> updateName(String name);
  Future<void> signOut();

  Future<DataSnapshot> load();

  Future<void> setEventJoined(int eventId, bool joined);
  Future<void> setCollectifJoined(String collectifId, bool joined);
  Future<void> setClubFollowed(String clubId, bool followed);
  Future<void> setRole(String collectifId, String? roleId);
  Future<ChatMessage> sendMessage(ChatMessage draft);
  Future<Chant> proposeChant(Chant draft);
  Future<void> setVote(String chantId, bool voted);
  Future<FanZoneEvent> createEvent(FanZoneEvent draft);

  /// Flux temps réel des messages d'un salon, ou `null` si non supporté.
  Stream<List<ChatMessage>>? watchChannel(String channel) => null;
}
