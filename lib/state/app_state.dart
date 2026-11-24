import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/local_store.dart';
import '../data/repository.dart';
import '../models/club.dart';
import '../models/collectif.dart';
import '../models/event.dart';
import '../models/social.dart';

/// État global de l'app. Seule classe qui touche aux données :
/// les écrans lisent via `AppScope.of(context)` et appellent ses méthodes.
///
/// Les écritures sont optimistes : l'UI est mise à jour immédiatement, puis
/// la source de données ([FanZoneRepository]) est appelée. En cas d'échec,
/// l'état est rechargé depuis la source et `lastError` est renseigné.
class AppState extends ChangeNotifier {
  AppState(this._repo, {FanZoneStore? alertsStore})
      : _alertsStore = alertsStore ?? LocalStore(key: 'fanzone_alerts_v1');

  final FanZoneRepository _repo;
  final FanZoneStore _alertsStore;
  final _rng = Random();

  bool loaded = false;
  String? lastError;
  UserProfile? user;

  List<FanZoneEvent> events = [];
  List<Club> clubs = [];
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
    try {
      user = await _repo.currentUser();
      await _loadAlerts();
      if (user != null) await _refresh();
      lastError = null;
    } catch (e) {
      lastError = 'Impossible de charger les données : $e';
    }
    loaded = true;
    notifyListeners();
  }

  /// Recharge tout depuis la source de données.
  Future<void> _refresh() async {
    final s = await _repo.load();
    user = s.user ?? user;
    clubs = s.clubs;
    collectifs = s.collectifs;
    events = s.events;
    chants = s.chants;
    messages = s.messages;
    joinedEventIds
      ..clear()
      ..addAll(s.joinedEventIds);
    joinedCollectifIds
      ..clear()
      ..addAll(s.joinedCollectifIds);
    followedClubIds
      ..clear()
      ..addAll(s.followedClubIds);
    votedChantIds
      ..clear()
      ..addAll(s.votedChantIds);
    myRoles
      ..clear()
      ..addAll(s.myRoles);
    _eventApplied.clear();
    _colApplied.clear();
    _voteApplied.clear();
    _applyMembership();
    _generateReminders();
    _generateNewEventAlerts();
  }

  Future<void> refresh() async {
    try {
      await _refresh();
      lastError = null;
    } catch (e) {
      lastError = 'Synchronisation impossible : $e';
    }
    notifyListeners();
  }

  /// Exécute une écriture ; en cas d'échec, recharge l'état depuis la source.
  Future<void> _commit(Future<void> Function() write) async {
    notifyListeners();
    try {
      await write();
      lastError = null;
    } catch (e) {
      lastError = 'Action non enregistrée : $e';
      try {
        await _refresh();
      } catch (_) {}
      notifyListeners();
    }
  }

  final Set<int> _eventApplied = {};
  final Set<String> _colApplied = {};
  final Set<String> _voteApplied = {};

  /// Ajoute/retire la contribution de l'utilisateur aux compteurs, de façon idempotente.
  void _applyMembership() {
    for (final e in events) {
      final should = joinedEventIds.contains(e.id);
      final has = _eventApplied.contains(e.id);
      e.joined = should;
      if (should && !has) {
        e.supporters += 1;
        _eventApplied.add(e.id);
      } else if (!should && has) {
        e.supporters = max(0, e.supporters - 1);
        _eventApplied.remove(e.id);
      }
    }
    for (final c in collectifs) {
      final should = joinedCollectifIds.contains(c.id);
      final has = _colApplied.contains(c.id);
      c.joined = should;
      if (should && !has) {
        c.members += 1;
        _colApplied.add(c.id);
      } else if (!should && has) {
        c.members = max(0, c.members - 1);
        _colApplied.remove(c.id);
      }
    }
    _applyVotes();
  }

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
    try {
      user = await _repo.signIn(clean);
      await _refresh();
      lastError = null;
    } catch (e) {
      lastError = 'Connexion impossible : $e';
    }
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    if (user == null) return;
    user!.name = name.trim().isEmpty ? 'Fan' : name.trim();
    await _commit(() => _repo.updateName(user!.name));
  }

  Future<void> signOut() async {
    user = null;
    events = [];
    collectifs = [];
    chants = [];
    messages = [];
    joinedEventIds.clear();
    joinedCollectifIds.clear();
    followedClubIds.clear();
    myRoles.clear();
    votedChantIds.clear();
    _eventApplied.clear();
    _colApplied.clear();
    _voteApplied.clear();
    alerts.clear();
    await _saveAlerts();
    notifyListeners();
    try {
      await _repo.signOut();
    } catch (e) {
      lastError = 'Déconnexion incomplète : $e';
      notifyListeners();
    }
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
    final join = !joinedEventIds.contains(eventId);
    join ? joinedEventIds.add(eventId) : joinedEventIds.remove(eventId);
    _applyMembership();
    _generateReminders();
    await _commit(() => _repo.setEventJoined(eventId, join));
  }

  Future<FanZoneEvent> createEvent(FanZoneEvent draft) async {
    final club = clubById(draft.clubId);
    final prepared = draft.copyWith(
      color: club?.color,
      bgColor: club?.bgColor,
      supporters: 0,
      createdBy: userId.isEmpty ? 'local' : userId,
    );
    final ev = await _repo.createEvent(prepared);
    events.add(ev);
    alerts.insert(
      0,
      FanAlert(
        id: _newId('al'),
        emoji: '',
        title: 'Event publié : ${ev.match}',
        body: 'Les fans qui suivent ${ev.club} sont alertés. À toi de mettre le feu !',
        date: DateTime.now(),
        eventId: ev.id,
      ),
    );
    await _saveAlerts();
    notifyListeners();
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
    final follow = !followedClubIds.contains(clubId);
    if (follow) {
      followedClubIds.add(clubId);
      if (club != null) {
        final next = eventsForClub(clubId).where((e) => !e.isPast).toList();
        alerts.insert(
          0,
          FanAlert(
            id: _newId('al'),
            emoji: '',
            title: 'Tu suis ${club.name}',
            body: next.isEmpty
                ? 'Tu seras alerté dès que le club publie un événement.'
                : 'Prochain rendez-vous : ${next.first.match} le ${next.first.dateFormatted}.',
            date: DateTime.now(),
            eventId: next.isEmpty ? null : next.first.id,
          ),
        );
        await _saveAlerts();
      }
    } else {
      followedClubIds.remove(clubId);
    }
    await _commit(() => _repo.setClubFollowed(clubId, follow));
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
    final join = !joinedCollectifIds.contains(collectifId);
    if (join) {
      joinedCollectifIds.add(collectifId);
    } else {
      joinedCollectifIds.remove(collectifId);
      myRoles.remove(collectifId);
    }
    _applyMembership();
    await _commit(() => _repo.setCollectifJoined(collectifId, join));
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
    await _commit(() => _repo.setRole(collectifId, roleId));
  }

  // ── Chat ─────────────────────────────────────────────────────

  List<ChatMessage> messagesFor(String channel) =>
      messages.where((m) => m.channel == channel).toList()
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

  Future<void> sendMessage(String channel, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final draft = ChatMessage(
      id: _newId('tmp'),
      channel: channel,
      authorId: userId,
      authorName: userName,
      text: t,
      sentAt: DateTime.now(),
    );
    messages.add(draft);
    await _commit(() async {
      final saved = await _repo.sendMessage(draft);
      messages.remove(draft);
      if (!messages.any((m) => m.id == saved.id)) messages.add(saved);
      notifyListeners();
    });
  }

  final Map<String, StreamSubscription<List<ChatMessage>>> _channelSubs = {};

  /// Abonne un salon au temps réel (si la source le supporte).
  void openChannel(String channel) {
    if (_channelSubs.containsKey(channel)) return;
    final stream = _repo.watchChannel(channel);
    if (stream == null) return;
    _channelSubs[channel] = stream.listen((list) {
      messages.removeWhere((m) => m.channel == channel && !m.id.startsWith('tmp'));
      messages.addAll(list);
      notifyListeners();
    }, onError: (_) {});
  }

  void closeChannel(String channel) {
    _channelSubs.remove(channel)?.cancel();
  }

  // ── Chants ───────────────────────────────────────────────────

  List<Chant> chantsFor(String collectifId) =>
      chants.where((c) => c.collectifId == collectifId).toList()
        ..sort((a, b) => b.votes.compareTo(a.votes));

  bool hasVoted(String chantId) => votedChantIds.contains(chantId);

  Future<void> toggleVote(String chantId) async {
    final vote = !votedChantIds.contains(chantId);
    vote ? votedChantIds.add(chantId) : votedChantIds.remove(chantId);
    _applyVotes();
    await _commit(() => _repo.setVote(chantId, vote));
  }

  Future<void> proposeChant({
    required String collectifId,
    required String title,
    required String lyrics,
    required String rhythm,
  }) async {
    final draft = Chant(
      id: _newId('tmp'),
      collectifId: collectifId,
      title: title.trim(),
      lyrics: lyrics.trim(),
      rhythm: rhythm.trim(),
      authorId: userId,
      authorName: userName,
      votes: 0,
      createdAt: DateTime.now(),
    );
    await _commit(() async {
      final saved = await _repo.proposeChant(draft);
      chants.add(saved);
      votedChantIds.add(saved.id);
      _applyVotes();
      await _repo.setVote(saved.id, true);
      notifyListeners();
    });
  }

  // ── Alertes ──────────────────────────────────────────────────

  DateTime? _lastSeenEventAt;

  Future<void> _loadAlerts() async {
    final data = await _alertsStore.load();
    alerts = [];
    for (final a in (data?['alerts'] as List? ?? const [])) {
      if (a is Map<String, dynamic>) alerts.add(FanAlert.fromJson(a));
    }
    _lastSeenEventAt = DateTime.tryParse(data?['lastSeenEventAt'] as String? ?? '');
  }

  Future<void> _saveAlerts() => _alertsStore.save({
        'alerts': alerts.map((a) => a.toJson()).toList(),
        'lastSeenEventAt': DateTime.now().toIso8601String(),
      });

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
          emoji: '',
          title: diff.inHours < 12 ? "C'est aujourd'hui !" : "C'est demain !",
          body: '${e.match}, ${e.time}, ${e.venue}',
          date: now,
          eventId: e.id,
        ),
      );
    }
  }

  /// Events publiés par d'autres pour les clubs suivis, non encore signalés.
  void _generateNewEventAlerts() {
    if (_lastSeenEventAt == null) return;
    for (final e in events) {
      if (!followedClubIds.contains(e.clubId) || e.createdBy.isEmpty || e.createdBy == userId) continue;
      if (e.isPast) continue;
      final id = 'new-${e.id}';
      if (alerts.any((a) => a.id == id)) continue;
      alerts.insert(
        0,
        FanAlert(
          id: id,
          emoji: '',
          title: 'Nouvel event : ${e.club}',
          body: '${e.match} · ${e.dateFormatted} à ${e.time}',
          date: DateTime.now(),
          eventId: e.id,
        ),
      );
    }
  }

  Future<void> markAllAlertsRead() async {
    for (final a in alerts) {
      a.read = true;
    }
    await _saveAlerts();
    notifyListeners();
  }

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}-${_rng.nextInt(99999)}';

  @override
  void dispose() {
    for (final s in _channelSubs.values) {
      s.cancel();
    }
    super.dispose();
  }
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
