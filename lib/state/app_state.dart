import 'dart:math';

import 'package:flutter/material.dart';

import '../data/local_store.dart';
import '../models/club.dart';
import '../models/collectif.dart';
import '../models/event.dart';
import '../models/social.dart';

/// État global de l'app. Seule classe qui touche aux données :
/// les écrans lisent via `AppScope.of(context)` et appellent ses méthodes.
class AppState extends ChangeNotifier {
  AppState(this._store);

  final FanZoneStore _store;
  final _rng = Random();

  bool loaded = false;
  UserProfile? user;

  List<FanZoneEvent> events = [];
  List<Club> clubs = List.of(sampleClubs);
  List<Collectif> collectifs = [];
  List<ChatMessage> messages = [];
  List<Chant> chants = [];
  List<FanAlert> alerts = [];

  final Set<int> joinedEventIds = {};
  final Set<String> joinedCollectifIds = {};
  final Set<String> followedClubIds = {};
  final Map<String, String> myRoles = {}; // collectifId -> roleId
  final Set<String> votedChantIds = {};

  bool get isLoggedIn => user != null;
  String get userName => user?.name ?? 'Fan';
  String get userId => user?.id ?? '';
  int get unreadAlerts => alerts.where((a) => !a.read).length;

  // ── Chargement ────────────────────────────────────────────────

  Future<void> load() async {
    final data = await _store.load();

    events = buildSampleEvents();
    collectifs = buildSampleCollectifs();
    messages = buildSampleMessages();
    chants = buildSampleChants();

    if (data != null) {
      final u = data['user'];
      if (u is Map<String, dynamic>) user = UserProfile.fromJson(u);

      for (final e in (data['createdEvents'] as List? ?? const [])) {
        if (e is Map<String, dynamic>) events.add(FanZoneEvent.fromJson(e));
      }
      joinedEventIds.addAll(List<num>.from(data['joinedEventIds'] as List? ?? const []).map((n) => n.toInt()));
      joinedCollectifIds.addAll(List<String>.from(data['joinedCollectifIds'] as List? ?? const []));
      followedClubIds.addAll(List<String>.from(data['followedClubIds'] as List? ?? const []));
      votedChantIds.addAll(List<String>.from(data['votedChantIds'] as List? ?? const []));
      final roles = data['myRoles'];
      if (roles is Map) {
        roles.forEach((k, v) => myRoles[k.toString()] = v.toString());
      }
      for (final m in (data['userMessages'] as List? ?? const [])) {
        if (m is Map<String, dynamic>) messages.add(ChatMessage.fromJson(m));
      }
      for (final c in (data['userChants'] as List? ?? const [])) {
        if (c is Map<String, dynamic>) chants.add(Chant.fromJson(c));
      }
      for (final a in (data['alerts'] as List? ?? const [])) {
        if (a is Map<String, dynamic>) alerts.add(FanAlert.fromJson(a));
      }
    }

    _applyMembership();
    _generateReminders();
    loaded = true;
    notifyListeners();
  }

  Map<String, dynamic> _toJson() => {
        'user': user?.toJson(),
        'createdEvents': events.where((e) => e.createdBy.isNotEmpty).map((e) => e.toJson()).toList(),
        'joinedEventIds': joinedEventIds.toList(),
        'joinedCollectifIds': joinedCollectifIds.toList(),
        'followedClubIds': followedClubIds.toList(),
        'myRoles': myRoles,
        'votedChantIds': votedChantIds.toList(),
        'userMessages': messages.where((m) => m.authorId == userId && userId.isNotEmpty).map((m) => m.toJson()).toList(),
        'userChants': chants.where((c) => c.authorId == userId && userId.isNotEmpty).map((c) {
          final j = c.toJson();
          // Le vote de l'utilisateur est ré-appliqué au chargement : on stocke le compteur sans lui.
          if (_voteApplied.contains(c.id)) j['votes'] = max(0, c.votes - 1);
          return j;
        }).toList(),
        'alerts': alerts.map((a) => a.toJson()).toList(),
      };

  Future<void> _persist() async {
    notifyListeners();
    await _store.save(_toJson());
  }

  /// Recalcule `joined` / compteurs à partir des ensembles d'ids.
  void _applyMembership() {
    for (final e in events) {
      final wasJoined = e.joined;
      e.joined = joinedEventIds.contains(e.id);
      if (e.joined && !wasJoined) e.supporters += 1;
      if (!e.joined && wasJoined) e.supporters -= 1;
    }
    for (final c in collectifs) {
      final wasJoined = c.joined;
      c.joined = joinedCollectifIds.contains(c.id);
      if (c.joined && !wasJoined) c.members += 1;
      if (!c.joined && wasJoined) c.members -= 1;
    }
    _applyVotes();
  }

  final Set<String> _voteApplied = {};

  /// Ajoute/retire le vote de l'utilisateur aux compteurs, de façon idempotente.
  void _applyVotes() {
    for (final ch in chants) {
      final should = votedChantIds.contains(ch.id);
      final has = _voteApplied.contains(ch.id);
      if (should && !has) {
        ch.votes += 1;
        _voteApplied.add(ch.id);
      } else if (!should && has) {
        ch.votes = max(0, ch.votes - 1);
        _voteApplied.remove(ch.id);
      }
    }
  }

  // ── Profil ───────────────────────────────────────────────────

  Future<void> signIn(String name) async {
    final clean = name.trim().isEmpty ? 'Fan' : name.trim();
    user ??= UserProfile(id: _newId('u'), name: clean, createdAt: DateTime.now());
    user!.name = clean;
    await _persist();
  }

  Future<void> updateName(String name) async {
    if (user == null) return;
    user!.name = name.trim().isEmpty ? 'Fan' : name.trim();
    await _persist();
  }

  Future<void> signOut() async {
    user = null;
    joinedEventIds.clear();
    joinedCollectifIds.clear();
    followedClubIds.clear();
    myRoles.clear();
    votedChantIds.clear();
    alerts.clear();
    events.removeWhere((e) => e.createdBy.isNotEmpty);
    messages.removeWhere((m) => !m.id.startsWith('m'));
    chants.removeWhere((c) => !c.id.startsWith('ch'));
    _applyMembership();
    await _persist();
  }

  // ── Events ───────────────────────────────────────────────────

  FanZoneEvent? eventById(int id) {
    for (final e in events) {
      if (e.id == id) return e;
    }
    return null;
  }

  List<FanZoneEvent> get upcomingEvents => events.where((e) => !e.isPast).toList()
    ..sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));

  List<FanZoneEvent> eventsForClub(String clubId) =>
      events.where((e) => e.clubId == clubId).toList()
        ..sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));

  Future<void> toggleJoinEvent(int eventId) async {
    final ev = eventById(eventId);
    if (ev == null) return;
    if (joinedEventIds.contains(eventId)) {
      joinedEventIds.remove(eventId);
      ev.joined = false;
      ev.supporters = max(0, ev.supporters - 1);
    } else {
      joinedEventIds.add(eventId);
      ev.joined = true;
      ev.supporters += 1;
    }
    _generateReminders();
    await _persist();
  }

  Future<FanZoneEvent> createEvent(FanZoneEvent draft) async {
    final club = clubById(draft.clubId);
    final ev = FanZoneEvent(
      id: DateTime.now().millisecondsSinceEpoch,
      clubId: draft.clubId,
      club: draft.club,
      sport: draft.sport,
      emoji: draft.emoji,
      match: draft.match,
      level: draft.level,
      date: draft.date,
      time: draft.time,
      venue: draft.venue,
      address: draft.address,
      venueKind: draft.venueKind,
      lat: draft.lat,
      lng: draft.lng,
      description: draft.description,
      supporters: 0,
      capacity: draft.capacity,
      joined: false,
      color: club?.color ?? draft.color,
      bgColor: club?.bgColor ?? draft.bgColor,
      free: draft.free,
      price: draft.price,
      isNew: true,
      tags: draft.tags,
      afterBar: draft.afterBar,
      afterAddress: draft.afterAddress,
      soundAllowed: draft.soundAllowed,
      soundForbidden: draft.soundForbidden,
      collectifIds: draft.collectifIds,
      createdBy: userId.isEmpty ? 'local' : userId,
    );
    events.add(ev);
    alerts.insert(
      0,
      FanAlert(
        id: _newId('al'),
        emoji: '📣',
        title: 'Event publié : ${ev.match}',
        body: 'Les fans qui suivent ${ev.club} sont alertés. À toi de mettre le feu !',
        date: DateTime.now(),
        eventId: ev.id,
      ),
    );
    await _persist();
    return ev;
  }

  // ── Clubs ────────────────────────────────────────────────────

  Club? clubById(String id) {
    for (final c in clubs) {
      if (c.id == id) return c;
    }
    return null;
  }

  bool isFollowing(String clubId) => followedClubIds.contains(clubId);

  int followersOf(Club c) => c.followersBase + (isFollowing(c.id) ? 1 : 0);

  Future<void> toggleFollowClub(String clubId) async {
    final club = clubById(clubId);
    if (followedClubIds.contains(clubId)) {
      followedClubIds.remove(clubId);
    } else {
      followedClubIds.add(clubId);
      if (club != null) {
        final next = eventsForClub(clubId).where((e) => !e.isPast).toList();
        alerts.insert(
          0,
          FanAlert(
            id: _newId('al'),
            emoji: club.emoji,
            title: 'Tu suis ${club.name}',
            body: next.isEmpty
                ? 'Tu seras alerté dès que le club publie un événement.'
                : 'Prochain rendez-vous : ${next.first.match} le ${next.first.dateFormatted}.',
            date: DateTime.now(),
            eventId: next.isEmpty ? null : next.first.id,
          ),
        );
      }
    }
    await _persist();
  }

  // ── Collectifs ───────────────────────────────────────────────

  Collectif? collectifById(String id) {
    for (final c in collectifs) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Collectifs annoncés sur l'event + ceux du même club.
  List<Collectif> collectifsForEvent(FanZoneEvent ev) {
    final ids = <String>{...ev.collectifIds};
    for (final c in collectifs) {
      if (c.clubId == ev.clubId) ids.add(c.id);
    }
    return collectifs.where((c) => ids.contains(c.id)).toList();
  }

  Future<void> toggleJoinCollectif(String collectifId) async {
    final col = collectifById(collectifId);
    if (col == null) return;
    if (joinedCollectifIds.contains(collectifId)) {
      joinedCollectifIds.remove(collectifId);
      myRoles.remove(collectifId);
      col.joined = false;
      col.members = max(0, col.members - 1);
    } else {
      joinedCollectifIds.add(collectifId);
      col.joined = true;
      col.members += 1;
    }
    await _persist();
  }

  String? myRoleIn(String collectifId) => myRoles[collectifId];

  int roleTaken(Collectif col, String roleId) =>
      (col.roleTakenBase[roleId] ?? 0) + (myRoles[col.id] == roleId ? 1 : 0);

  bool roleIsFull(Collectif col, String roleId) =>
      myRoles[col.id] != roleId && roleTaken(col, roleId) >= roleById(roleId).max;

  Future<void> setRole(String collectifId, String? roleId) async {
    if (roleId == null) {
      myRoles.remove(collectifId);
    } else {
      myRoles[collectifId] = roleId;
    }
    await _persist();
  }

  // ── Chat ─────────────────────────────────────────────────────

  List<ChatMessage> messagesFor(String channel) =>
      messages.where((m) => m.channel == channel).toList()
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

  Future<void> sendMessage(String channel, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    messages.add(ChatMessage(
      id: _newId('um'),
      channel: channel,
      authorId: userId,
      authorName: userName,
      text: t,
      sentAt: DateTime.now(),
    ));
    await _persist();
  }

  // ── Chants ───────────────────────────────────────────────────

  List<Chant> chantsFor(String collectifId) =>
      chants.where((c) => c.collectifId == collectifId).toList()
        ..sort((a, b) => b.votes.compareTo(a.votes));

  bool hasVoted(String chantId) => votedChantIds.contains(chantId);

  Future<void> toggleVote(String chantId) async {
    if (votedChantIds.contains(chantId)) {
      votedChantIds.remove(chantId);
    } else {
      votedChantIds.add(chantId);
    }
    _applyVotes();
    await _persist();
  }

  Future<void> proposeChant({
    required String collectifId,
    required String title,
    required String lyrics,
    required String rhythm,
  }) async {
    final id = _newId('uch');
    chants.add(Chant(
      id: id,
      collectifId: collectifId,
      title: title.trim(),
      lyrics: lyrics.trim(),
      rhythm: rhythm.trim(),
      authorId: userId,
      authorName: userName,
      votes: 0,
      createdAt: DateTime.now(),
    ));
    votedChantIds.add(id);
    _applyVotes();
    await _persist();
  }

  // ── Alertes ──────────────────────────────────────────────────

  void _generateReminders() {
    final now = DateTime.now();
    for (final e in events) {
      if (!e.joined) continue;
      final dt = e.dateTime;
      if (dt == null) continue;
      final diff = dt.difference(now);
      if (diff.inHours < 0 || diff.inHours > 36) continue;
      final id = 'rem-${e.id}-${e.date}';
      if (alerts.any((a) => a.id == id)) continue;
      alerts.insert(
        0,
        FanAlert(
          id: id,
          emoji: '⏰',
          title: diff.inHours < 12 ? "C'est aujourd'hui !" : "C'est demain !",
          body: '${e.emoji} ${e.match} · ${e.time} · ${e.venue}',
          date: now,
          eventId: e.id,
        ),
      );
    }
  }

  Future<void> markAllAlertsRead() async {
    for (final a in alerts) {
      a.read = true;
    }
    await _persist();
  }

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}-${_rng.nextInt(99999)}';
}

/// Donne accès à `AppState` depuis n'importe quel widget.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope introuvable dans l\'arbre de widgets');
    return scope!.notifier!;
  }

  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    return scope!.notifier!;
  }
}
