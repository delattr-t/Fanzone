import 'package:flutter/material.dart';

import '../models/social.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker.dart';

/// Salon de discussion générique (`event:<id>` ou `col:<id>`).
/// `locked` : l'utilisateur n'est pas membre → lecture seule + CTA.
class ChatView extends StatefulWidget {
  final String channel;
  final Color accent;
  final bool locked;
  final String lockedHint;
  final VoidCallback? onUnlock;
  final String unlockLabel;

  const ChatView({
    super.key,
    required this.channel,
    required this.accent,
    this.locked = false,
    this.lockedHint = 'Rejoins pour participer au chat.',
    this.onUnlock,
    this.unlockLabel = 'Rejoindre',
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  AppState? _state;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state == null) {
      _state = AppScope.read(context);
      if (!widget.locked) _state!.openChannel(widget.channel);
    }
  }

  @override
  void didUpdateWidget(covariant ChatView old) {
    super.didUpdateWidget(old);
    if (old.locked && !widget.locked) _state?.openChannel(widget.channel);
  }

  @override
  void dispose() {
    _state?.closeChannel(widget.channel);
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text;
    if (text.trim().isEmpty) return;
    _ctrl.clear();
    await AppScope.read(context).sendMessage(widget.channel, text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final msgs = state.messagesFor(widget.channel);

    return Column(
      children: [
        Expanded(
          child: msgs.isEmpty
              ? const EmptyHint(emoji: '💬', text: 'Personne n\'a encore écrit. Lance la conversation !')
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[i];
                    final mine = m.authorId == state.userId && state.userId.isNotEmpty;
                    final showDay = i == 0 || !_sameDay(msgs[i - 1].sentAt, m.sentAt);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDay) _DayChip(date: m.sentAt),
                        _Bubble(msg: m, mine: mine, accent: widget.accent),
                      ],
                    );
                  },
                ),
        ),
        if (widget.locked)
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            decoration: const BoxDecoration(
              color: FanZoneColors.surface,
              border: Border(top: BorderSide(color: FanZoneColors.dark, width: 2.5)),
            ),
            child: Row(
              children: [
                const Text('🔒', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.lockedHint,
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700, color: FanZoneColors.textSecondary),
                  ),
                ),
                if (widget.onUnlock != null) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: widget.onUnlock,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.accent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: widget.accent, width: 2),
                      ),
                      child: Text(
                        widget.unlockLabel,
                        style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              color: FanZoneColors.surface,
              border: Border(top: BorderSide(color: FanZoneColors.dark, width: 2.5)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: FanZoneColors.background,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: FanZoneColors.dark, width: 2),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w700, color: FanZoneColors.dark),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          hintText: 'Écris un message…',
                          hintStyle: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w600, color: FanZoneColors.textLight),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: widget.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: FanZoneColors.dark, width: 2.5),
                        boxShadow: const [BoxShadow(color: FanZoneColors.dark, offset: Offset(2, 2), blurRadius: 0)],
                      ),
                      child: const Center(child: Text('📨', style: TextStyle(fontSize: 18))),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayChip extends StatelessWidget {
  final DateTime date;
  const _DayChip({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    String label;
    if (diff == 0) {
      label = "Aujourd'hui";
    } else if (diff == 1) {
      label = 'Hier';
    } else {
      const months = ['jan', 'fév', 'mar', 'avr', 'mai', 'jun', 'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'];
      label = '${d.day} ${months[d.month - 1]}';
    }
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: FanZoneColors.cream,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w800, color: FanZoneColors.textSecondary)),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  final bool mine;
  final Color accent;
  const _Bubble({required this.msg, required this.mine, required this.accent});

  @override
  Widget build(BuildContext context) {
    final h = msg.sentAt.hour.toString().padLeft(2, '0');
    final mn = msg.sentAt.minute.toString().padLeft(2, '0');
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: mine ? accent : FanZoneColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 4),
            bottomRight: Radius.circular(mine ? 4 : 14),
          ),
          border: Border.all(color: FanZoneColors.dark, width: 2),
          boxShadow: const [BoxShadow(color: Color(0x22000000), offset: Offset(2, 2), blurRadius: 0)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              Text(
                msg.authorName,
                style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w900, color: accent),
              ),
            Text(
              msg.text,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: mine ? Colors.white : FanZoneColors.dark,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$h:$mn',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: mine ? Colors.white70 : FanZoneColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
