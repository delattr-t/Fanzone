// Carte d'aperçu 1200x630 décrite en objets (pas de JSX) pour @vercel/og.
import { frenchWhen, supportersLine } from './match.js';

const NIGHT = '#2B1A12', CREAM = '#FFF3E0', SUN = '#FFB420', SAND = '#D6BEA8';

const h = (type, style, children) => ({ type, props: { style, children } });

function scarf(color, label, width, height) {
  const fringe = Math.round(height * 0.34);
  const bars = Array.from({ length: 5 }, () =>
    h('div', { width: fringe, height: Math.max(4, Math.round(height * 0.08)), background: color, opacity: 0.85, borderRadius: 3 }));
  const fringeCol = h('div', { display: 'flex', flexDirection: 'column', justifyContent: 'space-around', height }, bars);
  const stripe = (w) => h('div', { width: w, height, background: CREAM });
  const gap = (w) => h('div', { width: w, height });
  const end = [gap(height * 0.22), stripe(height * 0.16), gap(height * 0.12), stripe(height * 0.08)];
  const body = h('div', {
    display: 'flex', alignItems: 'center', width: width - 2 * fringe, height, background: color,
    borderRadius: Math.round(height * 0.14),
    backgroundImage: 'repeating-linear-gradient(90deg, rgba(0,0,0,0.05) 0px, rgba(0,0,0,0.05) 2px, transparent 2px, transparent 9px)',
  }, [
    ...end,
    h('div', {
      display: 'flex', flex: 1, justifyContent: 'center', color: CREAM, fontSize: Math.round(height * 0.36),
      fontWeight: 800, letterSpacing: Math.round(height * 0.05), textTransform: 'uppercase',
    }, label),
    ...end.slice().reverse(),
  ]);
  return h('div', { display: 'flex', alignItems: 'center' }, [fringeCol, body, fringeCol]);
}

export function matchCard(m) {
  const title = m.title.length > 60 ? m.title.slice(0, 58) + '…' : m.title;
  const titleSize = title.length > 34 ? 60 : 74;
  const pct = m.capacity > 0 ? Math.max(0.03, Math.min(1, m.supporters / m.capacity)) : 0;
  return h('div', {
    width: 1200, height: 630, display: 'flex', flexDirection: 'column', background: NIGHT, fontFamily: 'Bricolage',
  }, [
    h('div', { display: 'flex', justifyContent: 'center', marginTop: 40 }, [scarf(m.color, m.clubShort || m.club || 'FanZone', 1100, 92)]),
    h('div', { display: 'flex', flexDirection: 'column', padding: '36px 80px 0 80px', flex: 1 }, [
      h('div', { display: 'flex', color: CREAM, fontSize: titleSize, fontWeight: 800, lineHeight: 1.05, letterSpacing: -1 }, title),
      h('div', { display: 'flex', color: SUN, fontSize: 38, fontWeight: 800, marginTop: 24 }, frenchWhen(m.date, m.time)),
      h('div', { display: 'flex', color: SAND, fontSize: 34, fontWeight: 500, marginTop: 8 }, m.venue),
    ]),
    h('div', { display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', padding: '0 80px 46px 80px' }, [
      h('div', { display: 'flex', flexDirection: 'column' }, [
        h('div', { display: 'flex', color: CREAM, fontSize: 30, fontWeight: 500, marginBottom: 12 }, supportersLine(m)),
        h('div', { display: 'flex', width: 420, height: 14, borderRadius: 7, background: 'rgba(255,243,224,0.16)' }, [
          h('div', { display: 'flex', width: Math.round(420 * pct), height: 14, borderRadius: 7, background: SUN }),
        ]),
      ]),
      h('div', { display: 'flex', color: CREAM, fontSize: 40, fontWeight: 800 }, 'FanZone'),
    ]),
  ]);
}

export function fallbackCard() {
  return h('div', {
    width: 1200, height: 630, display: 'flex', flexDirection: 'column', justifyContent: 'center',
    background: NIGHT, fontFamily: 'Bricolage', padding: '0 80px',
  }, [
    h('div', { display: 'flex', color: CREAM, fontSize: 120, fontWeight: 800 }, 'FanZone'),
    h('div', { display: 'flex', color: SAND, fontSize: 40, fontWeight: 500, marginTop: 12 }, 'Les matchs du coin, et les collectifs pour y aller ensemble.'),
  ]);
}

// Google Fonts sert un .ttf quand on ne présente pas de navigateur moderne.
export async function loadFont(weight) {
  const css = await (await fetch(`https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:wght@${weight}`)).text();
  const src = css.match(/src: url\((.+?)\) format/);
  if (!src) throw new Error('police introuvable');
  return (await fetch(src[1])).arrayBuffer();
}
