import 'package:flutter/material.dart';

import '../models/club.dart';
import '../models/event.dart';
import '../models/sound_gear.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/event_card.dart';
import '../widgets/sticker.dart';
import 'event_detail_screen.dart';

const _sports = [
  'Football', 'Basketball', 'Volleyball', 'Handball', 'Rugby', 'Judo',
  'Boxe', 'Tennis', 'Course à pied', 'Cyclisme', 'Triathlon', 'Trail',
];

const _venueKinds = [
  ('stade', 'Stade ou terrain'),
  ('gymnase', 'Gymnase ou salle'),
  ('route', 'Dans la rue'),
];

const _quickHours = [
  TimeOfDay(hour: 14, minute: 0),
  TimeOfDay(hour: 15, minute: 0),
  TimeOfDay(hour: 18, minute: 0),
  TimeOfDay(hour: 20, minute: 30),
];

const _weekdays = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
const _months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

/// Type de lieu le plus probable pour un sport, ajustable ensuite.
String venueKindForSport(String sport) => switch (sport) {
      'Basketball' || 'Volleyball' || 'Handball' || 'Judo' || 'Boxe' => 'gymnase',
      'Course à pied' || 'Cyclisme' || 'Triathlon' || 'Trail' => 'route',
      _ => 'stade',
    };

String _hourLabel(TimeOfDay t) => t.minute == 0 ? '${t.hour} h' : '${t.hour} h ${t.minute.toString().padLeft(2, '0')}';
DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Organiser un match : quatre étapes, et la carte que verront les fans se
/// construit en direct en haut de l'écran.
class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  Club? _club;
  String _sport = 'Football';
  final _match = TextEditingController();
  final _opponent = TextEditingController();
  final _level = TextEditingController();
  late DateTime _date = _quickDates().first.$2;
  TimeOfDay _time = const TimeOfDay(hour: 15, minute: 0);
  final _venue = TextEditingController();
  final _address = TextEditingController();
  String _venueKind = 'stade';
  int _capacity = 50;
  bool _free = true;
  final _price = TextEditingController(text: '3');
  final _pitch = TextEditingController();
  bool _after = false;
  final _afterBar = TextEditingController();
  final _afterAddress = TextEditingController();
  final Set<String> _allowed = {'chants', 'clapping'};
  final Set<String> _forbidden = {};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_match, _opponent, _level, _venue, _address, _price, _pitch, _afterBar, _afterAddress]) {
      c.dispose();
    }
    super.dispose();
  }

  void _refresh(String _) => setState(() {});

  /// Ce samedi, ce dimanche, samedi prochain : les dates qu'on choisit neuf fois sur dix.
  static List<(String, DateTime)> _quickDates() {
    final today = _day(DateTime.now());
    final sat = today.add(Duration(days: (DateTime.saturday - today.weekday) % 7));
    final sun = sat.add(const Duration(days: 1));
    return [
      (sat == today ? 'aujourd\'hui' : 'ce samedi', sat),
      ('ce dimanche', sun),
      ('samedi prochain', sat.add(const Duration(days: 7))),
    ];
  }

  List<String> get _missing => [
        if (_club == null) 'le club',
        if (_match.text.trim().isEmpty) 'le nom du match',
        if (_venue.text.trim().isEmpty) 'le lieu',
      ];

  bool get _valid => _missing.isEmpty;

  String get _isoDate =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  FanZoneEvent _draft(AppState state) {
    final club = _club;
    final opponent = _opponent.text.trim();
    final name = _match.text.trim();
    final title = name.isEmpty
        ? (club?.name ?? 'Ton match')
        : (opponent.isEmpty ? name : '$name vs $opponent');
    final price = double.tryParse(_price.text.trim().replaceAll(',', '.'));
    return FanZoneEvent(
      id: 0,
      clubId: club?.id ?? '',
      club: club?.name ?? 'Ton club',
      sport: _sport,
      emoji: '',
      match: title,
      level: _level.text.trim().isEmpty ? 'Amateur' : _level.text.trim(),
      date: _isoDate,
      time: '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
      venue: _venue.text.trim().isEmpty ? 'Lieu à préciser' : _venue.text.trim(),
      address: _address.text.trim(),
      venueKind: _venueKind,
      // Sans géocodage, l'event est placé près du lieu habituel du club.
      lat: _defaultPos(state, club, (e) => e.lat, 48.8566),
      lng: _defaultPos(state, club, (e) => e.lng, 2.3522),
      description: _pitch.text.trim().isEmpty ? 'Venez nombreux, chaque voix compte.' : _pitch.text.trim(),
      supporters: 0,
      capacity: _capacity,
      joined: false,
      color: club?.color ?? FanZoneColors.cement,
      bgColor: club?.bgColor ?? FanZoneColors.wall,
      free: _free,
      price: _free ? null : price,
      tags: ['Nouveau'],
      afterBar: _after && _afterBar.text.trim().isNotEmpty ? _afterBar.text.trim() : null,
      afterAddress: _after && _afterAddress.text.trim().isNotEmpty ? _afterAddress.text.trim() : null,
      soundAllowed: _allowed.toList(),
      soundForbidden: _forbidden.toList(),
      collectifIds: club == null
          ? const []
          : state.collectifs.where((c) => c.clubId == club.id).map((c) => c.id).toList(),
    );
  }

  double _defaultPos(AppState state, Club? club, double Function(FanZoneEvent) pick, double fallback) {
    if (club == null) return fallback;
    final existing = state.eventsForClub(club.id);
    return existing.isEmpty ? fallback : pick(existing.first) + 0.002;
  }

  void _selectClub(Club c) => setState(() {
        final previous = _club;
        _club = c;
        if (_sports.contains(c.sport)) _setSport(c.sport);
        if (_venue.text.isEmpty || _venue.text == previous?.homeVenue) _venue.text = c.homeVenue;
      });

  void _setSport(String sport) {
    _sport = sport;
    _venueKind = venueKindForSport(sport);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _day(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  void _cycleGear(String id) => setState(() {
        if (_allowed.remove(id)) {
          _forbidden.add(id);
        } else if (!_forbidden.remove(id)) {
          _allowed.add(id);
        }
      });

  Future<void> _submit() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    final state = AppScope.read(context);
    final created = await state.createEvent(_draft(state));
    if (!mounted) return;
    showFanToast(context, 'Match publié. Ramène tes potes depuis la fiche.');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(event: created, onToggleJoin: () => state.toggleJoinEvent(created.id)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final draft = _draft(state);
    final quick = _quickDates();
    final customDate = !quick.any((q) => q.$2 == _day(_date));
    final customTime = !_quickHours.contains(_time);

    return Scaffold(
      backgroundColor: FanZoneColors.wool,
      appBar: AppBar(title: const Text('Organiser un match')),
      bottomNavigationBar: _PublishBar(
        missing: _missing,
        saving: _saving,
        onPublish: _valid ? _submit : null,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text('Ce que verront les fans', style: fz(fontSize: 13, fontWeight: FontWeight.w700, color: FanZoneColors.cement)),
          const SizedBox(height: 8),
          IgnorePointer(child: EventCard(event: draft, onTap: () {}, onJoin: () {})),
          const SizedBox(height: 22),

          _Step(
            number: 1,
            title: 'Qui joue',
            children: [
              const StickerLabel('Le club qui reçoit'),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.clubs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final c = state.clubs[i];
                    return _ClubChoice(club: c, selected: _club?.id == c.id, onTap: () => _selectClub(c));
                  },
                ),
              ),
              const SizedBox(height: 14),
              const StickerLabel('Sport'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _sports) _Choice(label: s, selected: _sport == s, onTap: () => setState(() => _setSport(s))),
                ],
              ),
              const SizedBox(height: 16),
              StickerField(controller: _match, label: 'Nom du match ou de la course', hint: 'AS Ménilmontant, 10 km de Pantin…', onChanged: _refresh),
              StickerField(controller: _opponent, label: 'Adversaire, si il y en a un', hint: 'FC Belleville', onChanged: _refresh),
              StickerField(controller: _level, label: 'Niveau', hint: 'Régionale 2, U21, course populaire…', onChanged: _refresh),
            ],
          ),

          _Step(
            number: 2,
            title: 'Quand et où',
            children: [
              const StickerLabel('Le jour'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final q in quick)
                    _Choice(label: q.$1, selected: _day(_date) == q.$2, onTap: () => setState(() => _date = q.$2)),
                  _Choice(
                    label: customDate ? '${_weekdays[_date.weekday - 1]} ${_date.day} ${_months[_date.month - 1]}' : 'autre jour',
                    icon: Icons.calendar_month_rounded,
                    selected: customDate,
                    onTap: _pickDate,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const StickerLabel('Le coup d\'envoi'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in _quickHours)
                    _Choice(label: _hourLabel(t), selected: _time == t, onTap: () => setState(() => _time = t)),
                  _Choice(
                    label: customTime ? _hourLabel(_time) : 'autre heure',
                    icon: Icons.schedule_rounded,
                    selected: customTime,
                    onTap: _pickTime,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StickerField(controller: _venue, label: 'Lieu', hint: 'Gymnase Géo-André', onChanged: _refresh),
              StickerField(controller: _address, label: 'Adresse', hint: 'Numéro, rue, ville'),
              const StickerLabel('Type de lieu'),
              _Segmented(
                options: _venueKinds,
                value: _venueKind,
                onChanged: (v) => setState(() => _venueKind = v),
              ),
            ],
          ),

          _Step(
            number: 3,
            title: 'L\'ambiance',
            children: [
              const StickerLabel('Combien de supporters tu vises'),
              _Stepper(
                value: _capacity,
                onChanged: (v) => setState(() => _capacity = v),
              ),
              const SizedBox(height: 16),
              const StickerLabel('L\'entrée'),
              _Segmented(
                options: const [('free', 'Gratuite'), ('paid', 'Payante')],
                value: _free ? 'free' : 'paid',
                onChanged: (v) => setState(() => _free = v == 'free'),
              ),
              if (!_free) ...[
                const SizedBox(height: 12),
                StickerField(
                  controller: _price,
                  label: 'Prix par personne, en euros',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: _refresh,
                ),
              ] else
                const SizedBox(height: 16),
              StickerField(
                controller: _pitch,
                label: 'Pourquoi venir',
                hint: 'Derby de quartier, les joueuses ont besoin de vous.',
                maxLines: 3,
              ),
              const StickerLabel('Matériel sonore'),
              Text(
                'Touche une fois pour autoriser, deux fois pour interdire, trois fois pour ne rien dire.',
                style: fz(fontSize: 13, color: FanZoneColors.cement, height: 1.35),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final g in soundGearCatalog)
                    _GearChoice(
                      label: g.label,
                      state: _allowed.contains(g.id) ? 1 : (_forbidden.contains(g.id) ? -1 : 0),
                      onTap: () => _cycleGear(g.id),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: FanZoneColors.wall, borderRadius: BorderRadius.circular(16)),
                child: Text(
                  soundNoteForVenueKind(_venueKind),
                  style: fz(fontSize: 13, color: FanZoneColors.cement, height: 1.4),
                ),
              ),
            ],
          ),

          _Step(
            number: 4,
            title: 'Et après',
            trailing: Switch(
              value: _after,
              activeThumbColor: FanZoneColors.paper,
              activeTrackColor: FanZoneColors.flare,
              onChanged: (v) => setState(() => _after = v),
            ),
            children: [
              if (!_after)
                Text(
                  'Un bar pour refaire le match ? Active pour l\'indiquer aux fans.',
                  style: fz(fontSize: 14, color: FanZoneColors.cement, height: 1.4),
                )
              else ...[
                StickerField(controller: _afterBar, label: 'Le bar', hint: 'Le Café du Stade'),
                StickerField(controller: _afterAddress, label: 'Son adresse', hint: 'Rue, ville'),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String title;
  final Widget? trailing;
  final List<Widget> children;
  const _Step({required this.number, required this.title, required this.children, this.trailing});

  @override
  Widget build(BuildContext context) {
    return StickerBlock(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: FanZoneColors.hiVis, shape: BoxShape.circle),
                child: Text('$number', style: fzDisplay(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: fzDisplay(fontSize: 24))),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ClubChoice extends StatelessWidget {
  final Club club;
  final bool selected;
  final VoidCallback onTap;
  const _ClubChoice({required this.club, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: 86,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? FanZoneColors.hiVis.withValues(alpha: 0.28) : FanZoneColors.wool,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? FanZoneColors.hiVis : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Monogram(name: club.name, color: club.color, size: 42),
            const SizedBox(height: 6),
            Text(
              club.shortName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: fz(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  const _Choice({required this.label, required this.selected, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? FanZoneColors.ink : FanZoneColors.wool,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? FanZoneColors.hiVis : FanZoneColors.cement),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: fz(fontSize: 14, fontWeight: FontWeight.w700, color: selected ? FanZoneColors.cream : FanZoneColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _GearChoice extends StatelessWidget {
  final String label;
  final int state;
  final VoidCallback onTap;
  const _GearChoice({required this.label, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (state) {
      1 => (FanZoneColors.successBg, FanZoneColors.success, Icons.check_rounded),
      -1 => (FanZoneColors.errorBg, FanZoneColors.error, Icons.block_rounded),
      _ => (FanZoneColors.wool, FanZoneColors.cement, Icons.add_rounded),
    };
    return Pressable(
      onTap: onTap,
      child: Semantics(
        label: '$label, ${state == 1 ? 'autorisé' : state == -1 ? 'interdit' : 'non précisé'}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: fz(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: state == 0 ? FanZoneColors.ink : fg,
                ).copyWith(decoration: state == -1 ? TextDecoration.lineThrough : null, decorationColor: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onChanged;
  const _Segmented({required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: FanZoneColors.wool, borderRadius: BorderRadius.circular(99)),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: Pressable(
                onTap: () => onChanged(o.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: value == o.$1 ? FanZoneColors.paper : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: value == o.$1 ? FanZoneColors.lift : null,
                  ),
                  child: Text(
                    o.$2,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: fz(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: value == o.$1 ? FanZoneColors.ink : FanZoneColors.cement,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _Stepper({required this.value, required this.onChanged});

  int get _step => value < 50 ? 5 : (value < 200 ? 10 : 50);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundButton(icon: Icons.remove_rounded, onTap: value > 5 ? () => onChanged((value - _step).clamp(5, 5000)) : null),
        Expanded(
          child: Column(
            children: [
              Text('$value', style: fzDisplay(fontSize: 34)),
              Text('supporters', style: fz(fontSize: 13, color: FanZoneColors.cement)),
            ],
          ),
        ),
        _RoundButton(icon: Icons.add_rounded, onTap: value < 5000 ? () => onChanged((value + _step).clamp(5, 5000)) : null),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: onTap == null ? FanZoneColors.wall : FanZoneColors.ink,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: onTap == null ? FanZoneColors.cement : FanZoneColors.cream),
      ),
    );
  }
}

class _PublishBar extends StatelessWidget {
  final List<String> missing;
  final bool saving;
  final VoidCallback? onPublish;
  const _PublishBar({required this.missing, required this.saving, required this.onPublish});

  @override
  Widget build(BuildContext context) {
    final hint = missing.isEmpty
        ? 'Tout est prêt, les fans du coin seront prévenus.'
        : 'Il manque ${missing.length == 1 ? missing.first : '${missing.sublist(0, missing.length - 1).join(', ')} et ${missing.last}'}.';
    return Container(
      decoration: BoxDecoration(
        color: FanZoneColors.paper,
        boxShadow: [BoxShadow(color: FanZoneColors.ink.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hint,
                textAlign: TextAlign.center,
                style: fz(fontSize: 13, color: missing.isEmpty ? FanZoneColors.success : FanZoneColors.cement),
              ),
              const SizedBox(height: 8),
              StickerButton(
                label: saving ? 'Publication…' : 'Publier le match',
                color: FanZoneColors.flare,
                fontSize: 16,
                onTap: onPublish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
