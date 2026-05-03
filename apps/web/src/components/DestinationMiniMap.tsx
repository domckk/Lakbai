'use client';

import { useState, useEffect } from 'react';
import { MapContainer, TileLayer, CircleMarker } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';

interface Props {
  name: string;
  region: string | null;
  lat: number | null;
  lng: number | null;
}

const MUNICIPALITY_COORDS: Record<string, [number, number]> = {
  'adams':        [18.4533, 120.8944],
  'bacarra':      [18.2537, 120.6123],
  'badoc':        [17.9211, 120.4797],
  'bangui':       [18.5303, 120.7666],
  'banna':        [18.1388, 120.6530],
  'espiritu':     [18.1388, 120.6530],
  'batac':        [18.0553, 120.5651],
  'batac city':   [18.0553, 120.5651],
  'burgos':       [18.5082, 120.6470],
  'carasi':       [17.9862, 120.9094],
  'currimao':     [17.9967, 120.4777],
  'dingras':      [18.1017, 120.6963],
  'dumalneg':     [18.4050, 120.9239],
  'laoag':        [18.1979, 120.5936],
  'laoag city':   [18.1979, 120.5936],
  'marcos':       [18.1689, 120.6903],
  'nueva era':    [17.9581, 120.8358],
  'pagudpud':     [18.5626, 120.7955],
  'paoay':        [17.9060, 120.4982],
  'pasuquin':     [18.3311, 120.6257],
  'piddig':       [18.1693, 120.8021],
  'pinili':       [17.9748, 120.5612],
  'san nicolas':  [18.1732, 120.5970],
  'sarrat':       [18.1546, 120.6312],
  'solsona':      [18.0542, 120.7796],
  'vintar':       [18.2315, 120.6539],
};

function resolveCoords(
  name: string,
  region: string | null,
  lat: number | null,
  lng: number | null,
): { lat: number; lng: number; approximate: boolean } | null {
  if (lat != null && lng != null) return { lat, lng, approximate: false };
  for (const text of [name, region ?? '']) {
    const key = text.toLowerCase().trim();
    if (MUNICIPALITY_COORDS[key]) {
      const [la, ln] = MUNICIPALITY_COORDS[key];
      return { lat: la, lng: ln, approximate: true };
    }
    const match = Object.keys(MUNICIPALITY_COORDS).find(
      (k) => key.includes(k) || k.includes(key),
    );
    if (match) {
      const [la, ln] = MUNICIPALITY_COORDS[match]!;
      return { lat: la, lng: ln, approximate: true };
    }
  }
  return null;
}

export function DestinationMiniMap({ name, region, lat, lng }: Props) {
  const [mounted, setMounted] = useState(false);
  useEffect(() => { setMounted(true); }, []);

  const coords = resolveCoords(name, region, lat, lng);
  if (!coords) return null;
  if (!mounted) return <div className="w-full rounded-xl bg-gray-100 animate-pulse" style={{ height: 160 }} />;

  return (
    <div>
      <MapContainer
        center={[coords.lat, coords.lng]}
        zoom={13}
        scrollWheelZoom={false}
        dragging={false}
        zoomControl={false}
        attributionControl={false}
        className="w-full rounded-xl overflow-hidden"
        style={{ height: 160, zIndex: 0 }}
      >
        <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
        <CircleMarker
          center={[coords.lat, coords.lng]}
          radius={10}
          pathOptions={{ color: '#c2410c', fillColor: '#f97316', fillOpacity: 0.9, weight: 2.5 }}
        />
      </MapContainer>
      <div className="flex items-center gap-1.5 mt-2 text-xs text-gray-500">
        <span>📍</span>
        <span>
          {Math.abs(coords.lat).toFixed(4)}°&nbsp;{coords.lat >= 0 ? 'N' : 'S'},&nbsp;
          {Math.abs(coords.lng).toFixed(4)}°&nbsp;{coords.lng >= 0 ? 'E' : 'W'}
        </span>
        {coords.approximate && (
          <span className="text-gray-400 ml-1">(approximate)</span>
        )}
      </div>
    </div>
  );
}
