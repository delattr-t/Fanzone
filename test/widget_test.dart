import 'package:fanzone/data/local_repository.dart';
import 'package:fanzone/data/local_store.dart';
import 'package:fanzone/models/event.dart';
import 'package:fanzone/screens/create_event_screen.dart';
import 'package:fanzone/state/app_state.dart';
import 'package:fanzone/widgets/share_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore implements FanZoneStore {
  Map<String, dynamic>? data;
  @override
  Future<Map<String, dynamic>?> load() async => data;
  @override
  Future<void> save(Map<String, dynamic> d) async => data = d;
}

AppState _state(_MemoryStore store) =>
    AppState(LocalRepository(store), alertsStore: _MemoryStore());

void main() {
  test('rejoindre un event incrémente la jauge et persiste', () async {
    final store = _MemoryStore();
    final state = _state(store);
    await state.load();
    await state.signIn('Thibaut');

    final ev = state.events.first;
    final before = ev.supporters;
    await state.toggleJoinEvent(ev.id);
    expect(ev.joined, isTrue);
    expect(ev.supporters, before + 1);
    expect(state.lastError, isNull);

    // Rechargement depuis le store : l'état est conservé.
    final state2 = _state(store);
    await state2.load();
    expect(state2.userName, 'Thibaut');
    expect(state2.eventById(ev.id)!.joined, isTrue);
    expect(state2.eventById(ev.id)!.supporters, before + 1);
  });

  test('un seul rôle par collectif, capacité respectée', () async {
    final state = _state(_MemoryStore());
    await state.load();
    await state.signIn('Léa');
    final col = state.collectifs.first; // chef déjà pris (1/1)
    await state.toggleJoinCollectif(col.id);
    expect(state.roleIsFull(col, 'chef'), isTrue);
    await state.setRole(col.id, 'tambour');
    expect(state.myRoleIn(col.id), 'tambour');
    await state.setRole(col.id, 'ultra');
    expect(state.myRoleIn(col.id), 'ultra');
    expect(state.roleTaken(col, 'tambour'), col.roleTakenBase['tambour']);
  });

  test('vote sur un chant idempotent après rechargement', () async {
    final store = _MemoryStore();
    final state = _state(store);
    await state.load();
    await state.signIn('Nico');
    final chant = state.chants.first;
    final base = chant.votes;
    await state.toggleVote(chant.id);
    expect(chant.votes, base + 1);
    await state.proposeChant(collectifId: chant.collectifId, title: 'Test', lyrics: 'la la', rhythm: '');
    expect(state.chants.firstWhere((c) => c.title == 'Test').votes, 1);

    final state2 = _state(store);
    await state2.load();
    expect(state2.chants.firstWhere((c) => c.id == chant.id).votes, base + 1);
    expect(state2.chants.firstWhere((c) => c.title == 'Test').votes, 1);
  });

  test('créer un event puis le rejoindre, compteur stable après rechargement', () async {
    final store = _MemoryStore();
    final state = _state(store);
    await state.load();
    await state.signIn('Sofia');
    final draft = state.events.first.copyWith(id: 0);
    final ev = await state.createEvent(draft);
    expect(ev.supporters, 0);
    await state.toggleJoinEvent(ev.id);
    expect(state.eventById(ev.id)!.supporters, 1);

    final state2 = _state(store);
    await state2.load();
    expect(state2.eventById(ev.id)!.supporters, 1);
    expect(state2.eventById(ev.id)!.joined, isTrue);
  });

  test('lien de partage : aller-retour vers l\'identifiant du match', () {
    final ev = buildSampleEvents().first;
    final link = matchLink(ev);
    expect(link, endsWith('#/match/${ev.id}'));
    expect(matchIdFromUri(Uri.parse(link)), ev.id);
    expect(matchIdFromUri(Uri.parse('https://exemple.fr/#/')), isNull);
    expect(matchIdFromUri(Uri.parse('https://exemple.fr/?typo=gazette#/match/12')), 12);
    expect(matchInvite(ev), contains(shareUrl(ev)));
  });

  test('le type de lieu suit le sport choisi', () {
    expect(venueKindForSport('Basketball'), 'gymnase');
    expect(venueKindForSport('Trail'), 'route');
    expect(venueKindForSport('Football'), 'stade');
  });

  test('lien de partage : passe par le service d\'aperçu quand il est configuré', () {
    final ev = buildSampleEvents().first;
    expect(shareUrl(ev, service: ''), matchLink(ev));
    expect(shareUrl(ev, service: 'https://fz.example'), 'https://fz.example/m/${ev.id}');
    expect(shareUrl(ev, service: 'https://fz.example/'), 'https://fz.example/m/${ev.id}');
  });
}
