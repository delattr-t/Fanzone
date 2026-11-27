# FanZone, aperçus de partage

Petit service Vercel qui donne à chaque match un lien partageable avec son propre aperçu.

- `/m/<id>` : page avec les balises Open Graph du match (titre, date, lieu, image), qui
  redirige aussitôt le visiteur vers l'app (`https://delattr-t.github.io/Fanzone/#/match/<id>`).
- `/og/<id>.png` : image 1200x630 générée à la volée (écharpe du club, date, lieu, supporters).

Les données viennent de Supabase en lecture publique (clé publishable). En ligne sur https://fanzone-share.vercel.app
(projet Vercel `fanzone-share`, importé depuis GitHub avec Root Directory `share`, redéployé à chaque push). Le lien GitHub Pages ne suffit pas pour les aperçus : la partie
après `#` n'est jamais envoyée au serveur, donc tous les liens y montraient la même carte.
