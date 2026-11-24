import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/club.dart';
import '../models/collectif.dart';
import '../models/event.dart';
import '../models/social.dart';
import 'repository.dart';

/// Implémentation Supabase (Postgres + Auth anonyme + Realtime).
///
/// Schéma : voir les migrations `fanzone_schema` / `fanzone_seed` du projet
/// Supabase `fanzone`. Les règles RLS garantissent que chacun ne modifie que
/// ses propres lignes et que les chats sont réservés aux membres.
class SupabaseRepository extends FanZoneRepository {
  SupabaseClient get _db => Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  // ── Auth / profil ────────────────────────────────────────────

  @override
  Future<UserProfile?> currentUser() async {
    final u = _db.auth.currentUser;
    if (u == null) return null;
    final row = await _db.from('profiles').select('name, created_at').eq('id', u.id).maybeSingle();
    return UserProfile(
      id: u.id,
      name: (row?['name'] as String?) ?? 'Fan',
      createdAt: DateTime.tryParse(row?['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  Future<UserProfile> signIn(String name) async {
    if (_db.auth.currentUser == null) {
      await _db.auth.signInAnonymously();
    }
    final uid = _uid!;
    await _db.from('profiles').upsert({'id': uid, 'name': name});
    return UserProfile(id: uid, name: name, createdAt: DateTime.now());
  }

  @override
  Future<void> updateName(String name) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.from('profiles').upsert({'id': uid, 'name': name});
  }

  @override
  Future<void> signOut() => _db.auth.signOut();

  // ── Chargement ───────────────────────────────────────────────

  @override
  Future<DataSnapshot> load() async {
    final uid = _uid;
    final results = await Future.wait([
      _db.from('clubs').select(),
      _db.from('collectifs').select(),
      _db.from('events').select().order('date'),
      _db.from('chants').select().order('created_at'),
      _db.from('event_members').select('event_id, user_id'),
      _db.from('collectif_members').select('collectif_id, user_id, role_id'),
      _db.from('club_follows').select('club_id, user_id'),
      _db.from('chant_votes').select('chant_id, user_id'),
      uid == null ? Future.value(<Map<String, dynamic>>[]) : _db.from('messages').select().order('created_at'),
    ]);

    final clubsRows = _rows(results[0]);
    final colsRows = _rows(results[1]);
    final evRows = _rows(results[2]);
    final chantRows = _rows(results[3]);
    final evMembers = _rows(results[4]);
    final colMembers = _rows(results[5]);
    final follows = _rows(results[6]);
    final votes = _rows(results[7]);
    final msgRows = _rows(results[8]);

    // Compteurs hors utilisateur courant + ensembles de l'utilisateur.
    final joinedEvents = <int>{};
    final evCount = <int, int>{};
    for (final r in evMembers) {
      final id = (r['event_id'] as num).toInt();
      if (r['user_id'] == uid) {
        joinedEvents.add(id);
      } else {
        evCount[id] = (evCount[id] ?? 0) + 1;
      }
    }
    final joinedCols = <String>{};
    final myRoles = <String, String>{};
    final colCount = <String, int>{};
    final roleTaken = <String, Map<String, int>>{};
    for (final r in colMembers) {
      final id = r['collectif_id'] as String;
      final role = r['role_id'] as String?;
      if (r['user_id'] == uid) {
        joinedCols.add(id);
        if (role != null) myRoles[id] = role;
      } else {
        colCount[id] = (colCount[id] ?? 0) + 1;
        if (role != null) {
          final m = roleTaken.putIfAbsent(id, () => {});
          m[role] = (m[role] ?? 0) + 1;
        }
      }
    }
    final followed = <String>{};
    final followCount = <String, int>{};
    for (final r in follows) {
      final id = r['club_id'] as String;
      if (r['user_id'] == uid) {
        followed.add(id);
      } else {
        followCount[id] = (followCount[id] ?? 0) + 1;
      }
    }
    final voted = <String>{};
    final voteCount = <String, int>{};
    for (final r in votes) {
      final id = r['chant_id'] as String;
      if (r['user_id'] == uid) {
        voted.add(id);
      } else {
        voteCount[id] = (voteCount[id] ?? 0) + 1;
      }
    }

    final clubs = clubsRows
        .map((r) => Club(
              id: r['id'] as String,
              name: r['name'] as String,
              shortName: r['short_name'] as String,
              emoji: r['emoji'] as String,
              sport: r['sport'] as String,
              city: r['city'] as String? ?? '',
              color: _color(r['color']),
              bgColor: _color(r['bg_color']),
              description: r['description'] as String? ?? '',
              followersBase: ((r['followers_base'] as num?)?.toInt() ?? 0) + (followCount[r['id']] ?? 0),
              homeVenue: r['home_venue'] as String? ?? '',
            ))
        .toList();

    final collectifs = colsRows.map((r) {
      final id = r['id'] as String;
      final base = Map<String, int>.from(
          (r['role_taken_base'] as Map? ?? const {}).map((k, v) => MapEntry(k.toString(), (v as num).toInt())));
      for (final e in (roleTaken[id] ?? const <String, int>{}).entries) {
        base[e.key] = (base[e.key] ?? 0) + e.value;
      }
      return Collectif(
        id: id,
        name: r['name'] as String,
        club: r['club_name'] as String? ?? '',
        clubId: r['club_id'] as String? ?? '',
        emoji: r['emoji'] as String,
        color: _color(r['color']),
        bgColor: _color(r['bg_color']),
        description: r['description'] as String? ?? '',
        members: ((r['members_base'] as num?)?.toInt() ?? 0) + (colCount[id] ?? 0),
        joined: false,
        roleTakenBase: base,
      );
    }).toList();

    final events = evRows.map((r) {
      final id = (r['id'] as num).toInt();
      return FanZoneEvent(
        id: id,
        clubId: r['club_id'] as String? ?? '',
        club: r['club_name'] as String? ?? '',
        sport: r['sport'] as String,
        emoji: r['emoji'] as String,
        match: r['match'] as String,
        level: r['level'] as String? ?? '',
        date: (r['date'] as String).substring(0, 10),
        time: r['time'] as String? ?? '15:00',
        venue: r['venue'] as String? ?? '',
        address: r['address'] as String? ?? '',
        venueKind: r['venue_kind'] as String? ?? 'stade',
        lat: (r['lat'] as num).toDouble(),
        lng: (r['lng'] as num).toDouble(),
        description: r['description'] as String? ?? '',
        supporters: ((r['supporters_base'] as num?)?.toInt() ?? 0) + (evCount[id] ?? 0),
        capacity: (r['capacity'] as num?)?.toInt() ?? 50,
        joined: false,
        color: _color(r['color']),
        bgColor: _color(r['bg_color']),
        free: r['free'] as bool? ?? true,
        price: (r['price'] as num?)?.toDouble(),
        isNew: r['is_new'] as bool? ?? false,
        tags: List<String>.from(r['tags'] as List? ?? const []),
        afterBar: r['after_bar'] as String?,
        afterAddress: r['after_address'] as String?,
        soundAllowed: List<String>.from(r['sound_allowed'] as List? ?? const []),
        soundForbidden: List<String>.from(r['sound_forbidden'] as List? ?? const []),
        collectifIds: List<String>.from(r['collectif_ids'] as List? ?? const []),
        createdBy: r['created_by'] as String? ?? '',
      );
    }).toList();

    final chants = chantRows.map((r) {
      final id = r['id'] as String;
      return Chant(
        id: id,
        collectifId: r['collectif_id'] as String,
        title: r['title'] as String,
        lyrics: r['lyrics'] as String? ?? '',
        rhythm: r['rhythm'] as String? ?? '',
        authorId: r['user_id'] as String? ?? '',
        authorName: r['author_name'] as String? ?? 'Fan',
        votes: ((r['votes_base'] as num?)?.toInt() ?? 0) + (voteCount[id] ?? 0),
        createdAt: DateTime.tryParse(r['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      );
    }).toList();

    final messages = msgRows.map(_message).toList();

    final user = uid == null ? null : await currentUser();

    return DataSnapshot(
      user: user,
      clubs: clubs,
      collectifs: collectifs,
      events: events,
      chants: chants,
      messages: messages,
      joinedEventIds: joinedEvents,
      joinedCollectifIds: joinedCols,
      followedClubIds: followed,
      votedChantIds: voted,
      myRoles: myRoles,
    );
  }

  // ── Écritures ────────────────────────────────────────────────

  @override
  Future<void> setEventJoined(int eventId, bool joined) async {
    final uid = _requireUid();
    if (joined) {
      await _db.from('event_members').upsert({'event_id': eventId, 'user_id': uid});
    } else {
      await _db.from('event_members').delete().match({'event_id': eventId, 'user_id': uid});
    }
  }

  @override
  Future<void> setCollectifJoined(String collectifId, bool joined) async {
    final uid = _requireUid();
    if (joined) {
      await _db.from('collectif_members').upsert({'collectif_id': collectifId, 'user_id': uid});
    } else {
      await _db.from('collectif_members').delete().match({'collectif_id': collectifId, 'user_id': uid});
    }
  }

  @override
  Future<void> setClubFollowed(String clubId, bool followed) async {
    final uid = _requireUid();
    if (followed) {
      await _db.from('club_follows').upsert({'club_id': clubId, 'user_id': uid});
    } else {
      await _db.from('club_follows').delete().match({'club_id': clubId, 'user_id': uid});
    }
  }

  @override
  Future<void> setRole(String collectifId, String? roleId) async {
    final uid = _requireUid();
    await _db.from('collectif_members').upsert({'collectif_id': collectifId, 'user_id': uid, 'role_id': roleId});
  }

  @override
  Future<ChatMessage> sendMessage(ChatMessage draft) async {
    final uid = _requireUid();
    final row = await _db
        .from('messages')
        .insert({'channel': draft.channel, 'user_id': uid, 'author_name': draft.authorName, 'text': draft.text})
        .select()
        .single();
    return _message(row);
  }

  @override
  Future<Chant> proposeChant(Chant draft) async {
    final uid = _requireUid();
    final row = await _db
        .from('chants')
        .insert({
          'collectif_id': draft.collectifId,
          'title': draft.title,
          'lyrics': draft.lyrics,
          'rhythm': draft.rhythm,
          'user_id': uid,
          'author_name': draft.authorName,
        })
        .select()
        .single();
    return Chant(
      id: row['id'] as String,
      collectifId: draft.collectifId,
      title: draft.title,
      lyrics: draft.lyrics,
      rhythm: draft.rhythm,
      authorId: uid,
      authorName: draft.authorName,
      votes: 0,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> setVote(String chantId, bool voted) async {
    final uid = _requireUid();
    if (voted) {
      await _db.from('chant_votes').upsert({'chant_id': chantId, 'user_id': uid});
    } else {
      await _db.from('chant_votes').delete().match({'chant_id': chantId, 'user_id': uid});
    }
  }

  @override
  Future<FanZoneEvent> createEvent(FanZoneEvent draft) async {
    final uid = _requireUid();
    final row = await _db
        .from('events')
        .insert({
          'club_id': draft.clubId,
          'club_name': draft.club,
          'sport': draft.sport,
          'emoji': draft.emoji,
          'match': draft.match,
          'level': draft.level,
          'date': draft.date,
          'time': draft.time,
          'venue': draft.venue,
          'address': draft.address,
          'venue_kind': draft.venueKind,
          'lat': draft.lat,
          'lng': draft.lng,
          'description': draft.description,
          'capacity': draft.capacity,
          'color': draft.color.toARGB32(),
          'bg_color': draft.bgColor.toARGB32(),
          'free': draft.free,
          'price': draft.price,
          'is_new': true,
          'tags': draft.tags,
          'after_bar': draft.afterBar,
          'after_address': draft.afterAddress,
          'sound_allowed': draft.soundAllowed,
          'sound_forbidden': draft.soundForbidden,
          'collectif_ids': draft.collectifIds,
          'created_by': uid,
        })
        .select('id')
        .single();
    return draft.copyWith(id: (row['id'] as num).toInt(), supporters: 0, createdBy: uid);
  }

  @override
  Stream<List<ChatMessage>>? watchChannel(String channel) {
    if (_uid == null) return null;
    return _db
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('channel', channel)
        .order('created_at', ascending: true)
        .map((rows) => rows.map(_message).toList());
  }

  // ── Helpers ──────────────────────────────────────────────────

  String _requireUid() {
    final uid = _uid;
    if (uid == null) throw StateError('Utilisateur non connecté');
    return uid;
  }

  List<Map<String, dynamic>> _rows(dynamic r) => List<Map<String, dynamic>>.from(r as List);

  Color _color(dynamic v) => Color((v as num?)?.toInt() ?? 0xFFFF8C00);

  ChatMessage _message(Map<String, dynamic> r) => ChatMessage(
        id: r['id'] as String,
        channel: r['channel'] as String,
        authorId: r['user_id'] as String? ?? '',
        authorName: r['author_name'] as String? ?? 'Fan',
        text: r['text'] as String? ?? '',
        sentAt: DateTime.tryParse(r['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      );
}
