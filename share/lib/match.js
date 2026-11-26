// Lecture d'un match dans Supabase (lecture publique) et mise en forme française.
export const SUPABASE_URL = 'https://lizbzscnskvsszoiszlt.supabase.co';
export const SUPABASE_KEY = 'sb_publishable_KGqY-LB3tStz_GIsInz3lA_rJmU9kEl';
export const APP_URL = 'https://delattr-t.github.io/Fanzone/';

const DAYS = ['dimanche', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi'];
const MONTHS = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];

export async function fetchMatch(id) {
  if (!/^\d+$/.test(String(id))) return null;
  const url = `${SUPABASE_URL}/rest/v1/events?id=eq.${id}&select=id,match,level,date,time,venue,color,capacity,supporters_base,free,price,sport,clubs(name,short_name),event_members(count)`;
  const res = await fetch(url, { headers: { apikey: SUPABASE_KEY, Authorization: `Bearer ${SUPABASE_KEY}` } });
  if (!res.ok) return null;
  const rows = await res.json();
  const e = rows[0];
  if (!e) return null;
  const members = Array.isArray(e.event_members) && e.event_members[0] ? e.event_members[0].count : 0;
  return {
    id: e.id,
    title: e.match,
    level: e.level || '',
    date: e.date,
    time: e.time,
    venue: e.venue,
    color: argbToHex(e.color),
    capacity: e.capacity || 0,
    supporters: (e.supporters_base || 0) + (members || 0),
    free: e.free,
    price: e.price,
    sport: e.sport,
    club: e.clubs ? e.clubs.name : '',
    clubShort: e.clubs ? e.clubs.short_name : '',
  };
}

export function argbToHex(v) {
  const n = Number(v);
  if (!Number.isFinite(n)) return '#E2462B';
  return '#' + (n % 0x1000000).toString(16).padStart(6, '0');
}

export function frenchWhen(date, time) {
  const [y, m, d] = String(date).split('-').map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  const [h, min] = String(time || '').split(':');
  const hour = !h ? '' : (min && min !== '00' ? `${Number(h)} h ${min}` : `${Number(h)} h`);
  return `${DAYS[dt.getUTCDay()]} ${d} ${MONTHS[m - 1]}${hour ? ` à ${hour}` : ''}`;
}

export function supportersLine(m) {
  if (m.supporters <= 0) return 'Les premiers supporters donnent le ton.';
  return m.supporters === 1 ? '1 supporter déjà annoncé.' : `${m.supporters} supporters déjà annoncés.`;
}

export function appLink(id) {
  return `${APP_URL}#/match/${id}`;
}
