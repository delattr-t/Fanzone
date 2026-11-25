import 'package:flutter/material.dart';

import '../models/club.dart';
import '../models/event.dart';
import '../models/sound_gear.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker.dart';
import 'event_detail_screen.dart';

const _sports = [
  ('Football', ''), ('Basketball', ''), ('Volleyball', ''), ('Handball', ''),
  ('Rugby', ''), ('Judo', ''), ('Boxe', ''), ('Tennis', ''),
  ('Course à pied', ''), ('Cyclisme', ''), ('Triathlon', ''), ('Trail', ''),
];

const _venueKinds = [
  ('stade', 'Stade / terrain'),
  ('gymnase', 'Gymnase / salle'),
  ('route', 'Voie publique'),
];

/// Formulaire de création d'un événement (club organisateur ou fan relais).
class CreateEventScreen extends StatefulWidget {
 const CreateEventScreen({super.key});

 @override
 State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
 Club? _club;
 String _sport ='Football';
 final _match = TextEditingController();
 final _opponent = TextEditingController();
 final _level = TextEditingController();
 DateTime _date = DateTime.now().add(const Duration(days: 7));
 TimeOfDay _time = const TimeOfDay(hour: 15, minute: 0);
 final _venue = TextEditingController();
 final _address = TextEditingController();
 String _venueKind ='stade';
 final _capacity = TextEditingController(text:'50');
 final _pitch = TextEditingController();
 bool _free = true;
 final _price = TextEditingController(text:'3');
 bool _after = false;
 final _afterBar = TextEditingController();
 final _afterAddress = TextEditingController();
 final Set<String> _allowed = {'chants','clapping'};
 final Set<String> _forbidden = {};
 bool _saving = false;

 @override
 void dispose() {
 for (final c in [_match, _opponent, _level, _venue, _address, _capacity, _pitch, _price, _afterBar, _afterAddress]) {
 c.dispose();
 }
 super.dispose();
 }

 String get _emoji => _sports.firstWhere((s) => s.$1 == _sport, orElse: () => _sports.first).$2;

 bool get _valid => _club!= null && _match.text.trim().isNotEmpty && _venue.text.trim().isNotEmpty;

 Future<void> _pickDate() async {
 final d = await showDatePicker(
 context: context,
 initialDate: _date,
 firstDate: DateTime.now(),
 lastDate: DateTime.now().add(const Duration(days: 365)),
 );
 if (d!= null) setState(() => _date = d);
 }

 Future<void> _pickTime() async {
 final t = await showTimePicker(context: context, initialTime: _time);
 if (t!= null) setState(() => _time = t);
 }

 Future<void> _submit() async {
 if (!_valid || _saving) return;
 setState(() => _saving = true);
 final state = AppScope.read(context);
 final club = _club!;
 final capacity = int.tryParse(_capacity.text.trim())?? 50;
 final price = double.tryParse(_price.text.trim().replaceAll(',','.'));
 final opponent = _opponent.text.trim();
 final title = opponent.isEmpty? _match.text.trim():'${_match.text.trim()} vs $opponent';
 final draft = FanZoneEvent(
 id: 0,
 clubId: club.id,
 club: club.name,
 sport: _sport,
 emoji: _emoji,
 match: title,
 level: _level.text.trim().isEmpty?'Amateur': _level.text.trim(),
 date:'${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
 time:'${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
 venue: _venue.text.trim(),
 address: _address.text.trim(),
 venueKind: _venueKind,
 // Sans géocodage (pas de backend), on place l'event près du lieu habituel du club.
      lat: _defaultLatFor(club.id),
      lng: _defaultLngFor(club.id),
      description: _pitch.text.trim().isEmpty ? 'Venez nombreux, chaque voix compte!' : _pitch.text.trim(),
      supporters: 0,
      capacity: capacity < 5 ? 5 : capacity,
      joined: false,
      color: club.color,
      bgColor: club.bgColor,
      free: _free,
      price: _free ? null : price,
      tags: ['Nouveau'],
      afterBar: _after ? _afterBar.text.trim() : null,
      afterAddress: _after ? _afterAddress.text.trim() : null,
      soundAllowed: _allowed.toList(),
      soundForbidden: _forbidden.toList(),
      collectifIds: state.collectifs.where((c) => c.clubId == club.id).map((c) => c.id).toList(),
    );
    final created = await state.createEvent(draft);
    if (!mounted) return;
    showFanToast(context, 'Event publié!');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(event: created, onToggleJoin: () => state.toggleJoinEvent(created.id))),
    );
  }

  double _defaultLatFor(String clubId) {
    final state = AppScope.read(context);
    final existing = state.eventsForClub(clubId);
    return existing.isEmpty ? 48.8566 : existing.first.lat + 0.002;
  }

  double _defaultLngFor(String clubId) {
    final state = AppScope.read(context);
    final existing = state.eventsForClub(clubId);
    return existing.isEmpty ? 2.3522 : existing.first.lng + 0.002;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    const months = ['jan', 'fév', 'mar', 'avr', 'mai', 'jun', 'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'];

    return Scaffold(
      backgroundColor: FanZoneColors.background,
      appBar: AppBar(title: const Text('Créer un event')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // ── Club ──
          const StickerLabel('Club organisateur'),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: state.clubs.map((c) {
              final sel = _club?.id == c.id;
              return GestureDetector(
                onTap: () => setState(() {
                  _club = c;
                  if (_sports.any((s) => s.$1 == c.sport)) _sport = c.sport;
                  if (_venue.text.isEmpty) _venue.text = c.homeVenue;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? c.color : FanZoneColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: sel ? c.color : FanZoneColors.wallDeep, width: 1.5),
                  ),
                  child: Text(c.shortName, style: fz(fontSize: 13, fontWeight: FontWeight.w700, color: sel ? Colors.white : FanZoneColors.dark)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── Sport ──
          const StickerLabel('Sport'),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _sports.map((s) {
                final sel = _sport == s.$1;
                return GestureDetector(
                  onTap: () => setState(() => _sport = s.$1),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: sel ? FanZoneColors.dark : FanZoneColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: FanZoneColors.wallDeep, width: 1.5),
                    ),
                    child: Center(child: Text('${s.$2} ${s.$1}', style: fz(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? Colors.white : FanZoneColors.dark))),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          StickerField(controller: _match, label: 'Match / épreuve', hint: 'Ex: AS Ménilmontant, 10km de Pantin…', onChanged: (_) => setState(() {})),
          StickerField(controller: _opponent, label: 'Adversaire (optionnel)', hint: 'Ex: FC Belleville'),
          StickerField(controller: _level, label: 'Niveau', hint: 'Ex: Régionale 2, U21, course populaire…'),

          // ── Date & heure ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StickerLabel('Date'),
                    _PickerTile(label: '${_date.day} ${months[_date.month - 1]} ${_date.year}', onTap: _pickDate),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StickerLabel('Heure'),
                    _PickerTile(label: '${_time.hour.toString().padLeft(2,'0')}:${_time.minute.toString().padLeft(2,'0')}', onTap: _pickTime),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          StickerField(controller: _venue, label: 'Lieu', hint: 'Ex: Gymnase Géo-André', onChanged: (_) => setState(() {})),
          StickerField(controller: _address, label: 'Adresse complète', hint: 'N°, rue, code postal, ville'),

          const StickerLabel('Type de lieu'),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _venueKinds.map((k) {
              final sel = _venueKind == k.$1;
              return GestureDetector(
                onTap: () => setState(() => _venueKind = k.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? FanZoneColors.dark : FanZoneColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FanZoneColors.wallDeep, width: 1.5),
                  ),
                  child: Text(k.$2, style: fz(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? Colors.white : FanZoneColors.dark)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: StickerField(controller: _capacity, label: 'Objectif supporters', keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StickerLabel('Entrée'),
                    Row(
                      children: [
                        _Toggle(label: 'Gratuit', active: _free, onTap: () => setState(() => _free = true)),
                        const SizedBox(width: 6),
                        _Toggle(label: 'Payant', active: !_free, onTap: () => setState(() => _free = false)),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
          if (!_free) StickerField(controller: _price, label: 'Prix (€ / personne)', keyboardType: const TextInputType.numberWithOptions(decimal: true)),

          StickerField(controller: _pitch, label: 'Accroche, pourquoi venir?', hint: 'Ex: Derby de quartier, les joueurs ont besoin de vous!', maxLines: 3),

          // ── After ──
          StickerBlock(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('After-match', style: fzDisplay(fontSize: 18, color: FanZoneColors.dark))),
                    Switch(value: _after, activeThumbColor: FanZoneColors.primary, onChanged: (v) => setState(() => _after = v)),
                  ],
                ),
                if (_after) ...[
                  const SizedBox(height: 8),
                  StickerField(controller: _afterBar, label: 'Bar / lieu', hint: 'Ex: Le Café du Stade'),
                  StickerField(controller: _afterAddress, label: 'Adresse', hint: 'Rue, ville'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Matériel sonore ──
          StickerBlock(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Matériel sonore', style: fzDisplay(fontSize: 18, color: FanZoneColors.dark)),
                const SizedBox(height: 2),
                Text('Touche un élément pour l\'autoriser, une deuxième fois pour l\'interdire, une troisième pour ne rien préciser.',
                    style: fz(fontSize: 11, fontWeight: FontWeight.w500, color: FanZoneColors.textSecondary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: soundGearCatalog.map((g) {
                    final ok = _allowed.contains(g.id);
                    final no = _forbidden.contains(g.id);
                    final color = ok ? FanZoneColors.success : no ? FanZoneColors.error : FanZoneColors.textLight;
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (ok) {
                          _allowed.remove(g.id);
                          _forbidden.add(g.id);
                        } else if (no) {
                          _forbidden.remove(g.id);
                        } else {
                          _allowed.add(g.id);
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: ok ? FanZoneColors.successBg : no ? FanZoneColors.errorBg : FanZoneColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: color, width: 1.5),
                        ),
                        child: Text('${g.label}${ok ? ' autorisé' : no ? ' interdit' : ''}',
                            style: fz(fontSize: 12, fontWeight: FontWeight.w700, color: ok || no ? color : FanZoneColors.dark)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: FanZoneColors.cream, borderRadius: BorderRadius.circular(14)),
                  child: Text('${soundNoteForVenueKind(_venueKind)}',
                      style: fz(fontSize: 11, fontWeight: FontWeight.w500, color: FanZoneColors.textSecondary, height: 1.4)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          StickerButton(
            label: _saving ? 'Publication…' : 'Publier l\'event',
            color: FanZoneColors.primary,
            onTap: _valid ? _submit : null,
          ),
          if (!_valid)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Choisis un club, un nom de match et un lieu pour publier.',
                  textAlign: TextAlign.center,
                  style: fz(fontSize: 11, fontWeight: FontWeight.w600, color: FanZoneColors.textLight)),
            ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PickerTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: FanZoneColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FanZoneColors.wallDeep, width: 1.5),
        ),
        child: Text(label, style: fz(fontSize: 14, fontWeight: FontWeight.w600, color: FanZoneColors.dark)),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Toggle({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? FanZoneColors.dark : FanZoneColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FanZoneColors.wallDeep, width: 1.5),
          ),
          child: Center(child: Text(label, style: fz(fontSize: 13, fontWeight: FontWeight.w700, color: active ? Colors.white : FanZoneColors.dark))),
        ),
      ),
    );
  }
}
