# Icône et visuels FanZone

`scarf.py` reproduit en Python l'écharpe de `lib/widgets/scarf.dart` (rayures crème, mailles, franges).
`icon.py` croise deux écharpes (braise et soleil) sur fond brun nuit et produit `icon-1024.png`
(et la variante « maskable » avec marge de sécurité).

Pour régénérer : installer Pillow et la police Bricolage Grotesque (Google Fonts), puis
`python3 icon.py`, et redimensionner vers `web/icons/`, `web/favicon.png` et
`android/app/src/main/res/mipmap-*/ic_launcher.png` (48, 72, 96, 144, 192 px).
