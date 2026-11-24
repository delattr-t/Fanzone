import 'dart:math';

import '../models/club.dart';
import '../models/collectif.dart';
import '../models/event.dart';
import '../models/social.dart';
import 'local_store.dart';
import 'repository.dart';

/// Implémentation 100 % locale : données de démo + blob JSON dans [FanZoneStore].
class LocalRepository extends FanZoneRepository {
  LocalRepository(this._store);

  final FanZoneStore _store;
  final _rng = Random();

  UserProfile? _user;
  final List<FanZoneEvent> _createdEvents = [];
  final Set<int> _joinedEvents = {};
  final Set<String> _joinedCollectifs = {};
  final Set<String> _followedClubs = {};
  final Set<String> _votedChants = {};
  final Map<String, String> _roles = {};
  final List<ChatMessage> _userMessages = [];
  final List<Chant> _userChants = [];
  bool _loaded = false;

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}-${_rng.nextInt(99999)}';

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final data = await _store.load();
    if (data == null) return;
    final u = data['user'];
    if (u is Map<String, dynamic>) _user = UserProfile.fromJson(u);
    for (final e in (data['createdEvents'] as List? ?? const [])) {
      if (e is Map<String, dynamic>) _createdEvents.add(FanZoneEvent.fromJson(e));
    }
    _joinedEvents.addAll(List<num>.from(data['joinedEventIds'] as List? ?? const []).map((n) => n.toInt()));
    _joinedCollectifs.addAll(List<String>.from(data['joinedCollectifIds'] as List? ?? const []));
    _followedClubs.addAll(List<String>.from(data['followedClubIds'] as List? ?? const []));
    _votedChants.addAll(List<String>.from(data['votedChantIds'] as List? ?? const []));
    final roles = data['myRoles'];
    if (roles is Map) roles.forEach((k, v) => _roles[k.toString()] = v.toString());
    for (final m in (data['userMessages'] as List? ?? const [])) {
      if (m is Map<String, dynamic>) _userMessages.add(ChatMessage.fromJson(m));
    }
    for (final c in (data['userChants'] as List? ?? const [])) {
      if (c is Map<String, dynamic>) _userChants.add(Chant.fromJson(c));
    }
  }

  Future<void> _save() => _store.save({
        'user': _user?.toJson(),
        'createdEvents': _createdEvents.map((e) => e.toJson()).toList(),
        'joinedEventIds': _joinedEvents.toList(),
        'joinedCollectifIds': _joinedCollectifs.toList(),
        'followedClubIds': _followedClubs.toList(),
        'votedChantIds': _votedChants.toList(),
        'myRoles': _roles,
        'userMessages': _userMessages.map((m) => m.toJson()).toList(),
        'userChants': _userChants.map((c) => c.toJson()).toList(),
      });

  @override
  Future<UserProfile?> currentUser() async {
    await _ensureLoaded();
    return _user;
  }

  @override
  Future<UserProfile> signIn(String name) async {
    await _ensureLoaded();
    _user ??= UserProfile(id: _newId('u'), name: name, createdAt: DateTime.now());
    _user!.name = name;
    await _save();
    return _user!;
  }

  @override
  Future<void> updateName(String name) async {
    if (_user == null) return;
    _user!.name = name;
    await _save();
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _createdEvents.clear();
    _joinedEvents.clear();
    _joinedCollectifs.clear();
    _followedClubs.clear();
    _votedChants.clear();
    _roles.clear();
    _userMessages.clear();
    _userChants.clear();
    await _save();
  }

  @override
  Future<DataSnapshot> load() async {
    await _ensureLoaded();
    // Copies : AppState mutera les compteurs (supporters, votes) des objets
    // qu'il reçoit, et ces mutations ne doivent pas être persistées ici.
    final events = [...buildSampleEvents(), ..._createdEvents.map((e) => e.copyWith())];
    return DataSnapshot(
      user: _user,
      clubs: List.of(sampleClubs),
      collectifs: buildSampleCollectifs(),
      events: events,
      chants: [...buildSampleChants(), ..._userChants.map((c) => Chant.fromJson(c.toJson()))],
      messages: [...buildSampleMessages(), ..._userMessages],
      joinedEventIds: {..._joinedEvents},
      joinedCollectifIds: {..._joinedCollectifs},
      followedClubIds: {..._followedClubs},
      votedChantIds: {..._votedChants},
      myRoles: {..._roles},
    );
  }

  @override
  Future<void> setEventJoined(int eventId, bool joined) async {
    joined ? _joinedEvents.add(eventId) : _joinedEvents.remove(eventId);
    await _save();
  }

  @override
  Future<void> setCollectifJoined(String collectifId, bool joined) async {
    if (joined) {
      _joinedCollectifs.add(collectifId);
    } else {
      _joinedCollectifs.remove(collectifId);
      _roles.remove(collectifId);
    }
    await _save();
  }

  @override
  Future<void> setClubFollowed(String clubId, bool followed) async {
    followed ? _followedClubs.add(clubId) : _followedClubs.remove(clubId);
    await _save();
  }

  @override
  Future<void> setRole(String collectifId, String? roleId) async {
    roleId == null ? _roles.remove(collectifId) : _roles[collectifId] = roleId;
    await _save();
  }

  @override
  Future<ChatMessage> sendMessage(ChatMessage draft) async {
    final m = ChatMessage(
      id: _newId('um'),
      channel: draft.channel,
      authorId: draft.authorId,
      authorName: draft.authorName,
      text: draft.text,
      sentAt: DateTime.now(),
    );
    _userMessages.add(m);
    await _save();
    return m;
  }

  @override
  Future<Chant> proposeChant(Chant draft) async {
    final c = Chant(
      id: _newId('uch'),
      collectifId: draft.collectifId,
      title: draft.title,
      lyrics: draft.lyrics,
      rhythm: draft.rhythm,
      authorId: draft.authorId,
      authorName: draft.authorName,
      votes: 0,
      createdAt: DateTime.now(),
    );
    _userChants.add(c);
    await _save();
    return Chant.fromJson(c.toJson());
  }

  @override
  Future<void> setVote(String chantId, bool voted) async {
    voted ? _votedChants.add(chantId) : _votedChants.remove(chantId);
    await _save();
  }

  @override
  Future<FanZoneEvent> createEvent(FanZoneEvent draft) async {
    final ev = draft.copyWith(
      id: DateTime.now().millisecondsSinceEpoch,
      supporters: 0,
      createdBy: _user?.id ?? 'local',
    );
    _createdEvents.add(ev);
    await _save();
    return ev.copyWith();
  }
}
