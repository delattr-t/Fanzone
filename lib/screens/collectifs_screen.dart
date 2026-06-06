import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Collectif {
  final String id;
  final String name;
  final String club;
  final String emoji;
  final Color color;
  final Color bgColor;
  final String description;
  int members;
  bool joined;

  Collectif({
    required this.id, required this.name, required this.club,
    required this.emoji, required this.color, required this.bgColor,
    required this.description, required this.members, required this.joined,
  });
}

final sampleCollectifs = [
  Collectif(id:'col1', name:'Les Irréductibles',       club:'AS Ménilmontant',  emoji:'🔴', color:const Color(0xFFFF4D4D), bgColor:const Color(0xFFFFF0F0), description:"Le kop historique du terrain Émile Anthoine. Tambours, drapeaux, et bonne humeur depuis 2008.", members:34, joined:false),
  Collectif(id:'col2', name:'North Side Crew',          club:'BC Saint-Denis',   emoji:'🧡', color:const Color(0xFFFF8C00), bgColor:const Color(0xFFFFF5E0), description:"On occupe le côté Nord du gymnase. Spécialistes du clapping syncopé et du chant collectif.", members:22, joined:true),
  Collectif(id:'col3', name:'Les Coureurs du Dimanche', club:'Course locale',    emoji:'🏃', color:const Color(0xFF00A86B), bgColor:const Color(0xFFE0FFF4), description:"On encourage tous les participants du départ à l'arrivée — du premier au dernier !", members:18, joined:false),
  Collectif(id:'col4', name:'Velo Squad 93',            club:'Cyclisme amateur', emoji:'🚴', color:const Color(0xFF0096FF), bgColor:const Color(0xFFE8F4FF), description:"On se poste aux cols et virages pour faire du bruit. Klaxons, sifflets et cris garantis !", members:12, joined:false),
];

class CollectifsScreen extends StatefulWidget {
  const CollectifsScreen({super.key});

  @override
  State<CollectifsScreen> createState() => _CollectifsScreenState();
}

class _CollectifsScreenState extends State<CollectifsScreen> {
  final List<Collectif> _collectifs = sampleCollectifs;

  void _toggle(Collectif col) {
    setState(() {
      col.joined = !col.joined;
      col.members += col.joined ? 1 : -1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(col.joined ? '🎊 Tu rejoins ${col.name} !' : 'Tu as quitté le collectif'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: FanZoneColors.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myCollectifs = _collectifs.where((c) => c.joined).toList();

    return Scaffold(
      backgroundColor: FanZoneColors.background,
      appBar: AppBar(title: const Text('🎊 Collectifs'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          // Mes collectifs recap
          if (myCollectifs.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: FanZoneColors.warningBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: FanZoneColors.yellow, width: 2.5),
                  boxShadow: const [BoxShadow(color: Color(0xFFFFD166), offset: Offset(2,2), blurRadius: 0)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✨ Mes collectifs', style: TextStyle(fontFamily:'Nunito', fontSize:11, fontWeight:FontWeight.w900, color:Color(0xFFB8860B), letterSpacing:1)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: myCollectifs.map((c) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: FanZoneColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: c.color, width: 2.5),
                        ),
                        child: Text('${c.emoji} ${c.name}', style: TextStyle(fontFamily:'Nunito', fontSize:13, fontWeight:FontWeight.w900, color:c.color)),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Text(
              'Rejoins un collectif pour recevoir les convocations et organiser les déplacements !',
              style: const TextStyle(fontFamily:'Nunito', fontSize:13, fontWeight:FontWeight.w600, color:FanZoneColors.textSecondary, height:1.5),
            ),
          ),

          ..._collectifs.map((col) => _CollectifCard(col: col, onToggle: () => _toggle(col))),
        ],
      ),
    );
  }
}

class _CollectifCard extends StatelessWidget {
  final Collectif col;
  final VoidCallback onToggle;
  const _CollectifCard({required this.col, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: FanZoneColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: col.joined ? col.color : FanZoneColors.dark, width: 2.5),
        boxShadow: [BoxShadow(
          color: (col.joined ? col.color : FanZoneColors.dark).withOpacity(0.15),
          offset: const Offset(3,3), blurRadius: 0,
        )],
      ),
      child: Column(
        children: [
          // Bande couleur
          Container(height: 6, decoration: BoxDecoration(
            color: col.color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          )),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(col.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(col.name, style: TextStyle(fontFamily:'Nunito', fontSize:17, fontWeight:FontWeight.w900, color: col.joined ? col.color : FanZoneColors.dark)),
                          Text(col.club, style: const TextStyle(fontFamily:'Nunito', fontSize:11, fontWeight:FontWeight.w700, color:FanZoneColors.textLight)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onToggle,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: col.joined ? FanZoneColors.successBg : col.color,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: col.joined ? FanZoneColors.success : col.color, width: 2),
                          boxShadow: [BoxShadow(
                            color: (col.joined ? FanZoneColors.success : col.color).withOpacity(0.25),
                            offset: const Offset(2,2), blurRadius: 0,
                          )],
                        ),
                        child: Text(
                          col.joined ? '✓ Rejoint' : 'Rejoindre',
                          style: TextStyle(fontFamily:'Nunito', fontSize:12, fontWeight:FontWeight.w900, color: col.joined ? FanZoneColors.success : Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(col.description, style: const TextStyle(fontFamily:'Nunito', fontSize:12, fontWeight:FontWeight.w600, color:FanZoneColors.textSecondary, height:1.5)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('👥 ${col.members} membre${col.members>1?"s":""}', style: const TextStyle(fontFamily:'Nunito', fontSize:12, fontWeight:FontWeight.w800, color:FanZoneColors.textLight)),
                    if (col.joined) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: FanZoneColors.successBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: FanZoneColors.success, width: 2),
                        ),
                        child: const Text('🎊 Tu en es !', style: TextStyle(fontFamily:'Nunito', fontSize:11, fontWeight:FontWeight.w900, color:FanZoneColors.success)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
