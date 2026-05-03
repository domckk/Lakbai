'use client';

import { useState, useEffect } from 'react';
import { MapContainer, TileLayer, CircleMarker, Tooltip } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';

interface MarkerData {
  id: string;
  name: string;
  lat: number;
  lng: number;
  earned: boolean;
  rarity: string | null;
}

interface Props {
  markers: MarkerData[];
}

const RARITY_COLOR: Record<string, string> = {
  common: '#9ca3af',
  uncommon: '#22c55e',
  rare: '#3b82f6',
  epic: '#a855f7',
  legendary: '#eab308',
};

export function PassportMap({ markers }: Props) {
  const [mounted, setMounted] = useState(false);
  useEffect(() => { setMounted(true); }, []);

  const valid = markers.filter((m) => m.lat != null && m.lng != null);
  if (valid.length === 0) return null;
  if (!mounted) return <div className="w-full rounded-2xl bg-trail-cream animate-pulse" style={{ height: 220 }} />;

  const lats = valid.map((m) => m.lat);
  const lngs = valid.map((m) => m.lng);
  const center: [number, number] = [
    (Math.min(...lats) + Math.max(...lats)) / 2,
    (Math.min(...lngs) + Math.max(...lngs)) / 2,
  ];

  return (
    <MapContainer
      center={center}
      zoom={14}
      scrollWheelZoom={false}
      className="w-full rounded-2xl overflow-hidden"
      style={{ height: 220, zIndex: 0 }}
    >
      <TileLayer
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution='&copy; <a href="https://openstreetmap.org">OpenStreetMap</a>'
      />
      {valid.map((m) => (
        <CircleMarker
          key={m.id}
          center={[m.lat, m.lng]}
          radius={m.earned ? 10 : 7}
          pathOptions={{
            color: m.earned ? (RARITY_COLOR[m.rarity ?? 'common'] ?? '#f97316') : '#d1d5db',
            fillColor: m.earned ? (RARITY_COLOR[m.rarity ?? 'common'] ?? '#f97316') : '#f3f4f6',
            fillOpacity: m.earned ? 0.85 : 0.5,
            weight: 2,
          }}
        >
          <Tooltip direction="top" offset={[0, -8]} opacity={0.95}>
            <span className="text-xs font-semibold">{m.name}</span>
          </Tooltip>
        </CircleMarker>
      ))}
    </MapContainer>
  );
}
