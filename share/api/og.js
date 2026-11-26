import { ImageResponse } from '@vercel/og';
import { fetchMatch } from '../lib/match.js';
import { matchCard, fallbackCard, loadFont } from '../lib/card.js';

export const config = { runtime: 'edge' };

export default async function handler(req) {
  const id = new URL(req.url).searchParams.get('id');
  const [match, bold, regular] = await Promise.all([fetchMatch(id), loadFont(800), loadFont(500)]);
  return new ImageResponse(match ? matchCard(match) : fallbackCard(), {
    width: 1200,
    height: 630,
    fonts: [
      { name: 'Bricolage', data: bold, weight: 800, style: 'normal' },
      { name: 'Bricolage', data: regular, weight: 500, style: 'normal' },
    ],
    headers: { 'Cache-Control': 'public, max-age=300, s-maxage=600, stale-while-revalidate=86400' },
  });
}
