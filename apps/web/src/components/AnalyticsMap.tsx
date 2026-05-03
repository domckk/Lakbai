'use client';

import { useState, useEffect } from 'react';
import { MapContainer, TileLayer, Marker, CircleMarker, Tooltip, useMap, useMapEvents } from 'react-leaflet';
import L from 'leaflet'; // used for createProvinceIcon DivIcon
import 'leaflet/dist/leaflet.css';
import type { ApiDestination, ApiQuest } from '@/lib/store';

interface Props {
  destinations: ApiDestination[];
  quests: ApiQuest[];
  onSelect?: (dest: ApiDestination) => void;
}

const ILOCOS_NORTE: [number, number] = [18.1647, 120.7116];
const ZOOM_THRESHOLD = 11;

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
  // Tourist attractions
  'kapurpurawan':           [18.5082, 120.6470],
  'bangui windmills':       [18.5303, 120.7666],
  'bangui wind farm':       [18.5303, 120.7666],
  'paoay church':           [17.9060, 120.4982],
  'paoay lake':             [17.9060, 120.4982],
  'paoay sand dunes':       [17.9060, 120.4982],
  'laoag sand dunes':       [18.0553, 120.5651],
  'sand dunes':             [18.0553, 120.5651],
  'pagudpud beach':         [18.5626, 120.7955],
  'saud beach':             [18.5626, 120.7955],
  'fort ilocandia':         [18.1979, 120.5936],
  'sinking bell tower':     [18.1979, 120.5936],
  'laoag cathedral':        [18.1979, 120.5936],
  'batac riverside':        [18.0553, 120.5651],
  'vintar dam':             [18.2315, 120.6539],
  'patapat viaduct':        [18.5626, 120.7955],
  'ilocos norte capitol':   [18.1979, 120.5936],
  'luna legacy':            [18.1979, 120.5936],
  'capitol':                [18.1979, 120.5936],
};

function resolveCoordsFor(dest: ApiDestination): { lat: number; lng: number; approximate: boolean } | null {
  if (dest.lat != null && dest.lng != null) {
    return { lat: dest.lat, lng: dest.lng, approximate: false };
  }
  const candidates = [dest.name, dest.region ?? ''];
  for (const text of candidates) {
    const key = text.toLowerCase().trim();
    // Exact match
    if (MUNICIPALITY_COORDS[key]) {
      const [lat, lng] = MUNICIPALITY_COORDS[key]!;
      return { lat, lng, approximate: true };
    }
    // Substring match
    const substringMatch = Object.keys(MUNICIPALITY_COORDS).find(
      (k) => key.includes(k) || k.includes(key),
    );
    if (substringMatch) {
      const [lat, lng] = MUNICIPALITY_COORDS[substringMatch]!;
      return { lat, lng, approximate: true };
    }
    // Word-level match — any single word in the name matches a municipality key
    for (const word of key.split(/\s+/)) {
      if (word.length > 3 && MUNICIPALITY_COORDS[word]) {
        const [lat, lng] = MUNICIPALITY_COORDS[word]!;
        return { lat, lng, approximate: true };
      }
    }
  }
  return null;
}

// Offset destinations that share the same coordinates so they don't stack
function applyOffsets(
  items: { dest: ApiDestination; coords: { lat: number; lng: number; approximate: boolean } }[],
) {
  const seen = new Map<string, number>();
  return items.map((item) => {
    const key = `${item.coords.lat.toFixed(4)},${item.coords.lng.toFixed(4)}`;
    const count = seen.get(key) ?? 0;
    seen.set(key, count + 1);
    if (count === 0) return item;
    const angle = (count * 137.5 * Math.PI) / 180; // golden angle spread
    const r = 0.012 * Math.ceil(count / 6);
    return {
      ...item,
      coords: {
        ...item.coords,
        lat: item.coords.lat + r * Math.cos(angle),
        lng: item.coords.lng + r * Math.sin(angle),
      },
    };
  });
}


function createProvinceIcon(count: number) {
  return L.divIcon({
    html: `<div style="pointer-events:none;width:48px;height:48px;background:#f97316;border:3px solid #c2410c;border-radius:50%;display:flex;flex-direction:column;align-items:center;justify-content:center;box-shadow:0 3px 12px rgba(0,0,0,0.4);font-family:-apple-system,sans-serif;">
      <span style="font-size:15px;font-weight:800;color:white;line-height:1;">${count}</span>
      <span style="font-size:8px;color:rgba(255,255,255,0.85);font-weight:600;line-height:1;margin-top:1px;">spots</span>
    </div>`,
    className: 'leaflet-pin-marker',
    iconSize: [48, 48],
    iconAnchor: [24, 24],
  });
}

function LocationMarker() {
  const [position, setPosition] = useState<[number, number] | null>(null);
  const map = useMap();

  useEffect(() => {
    map.locate({ watch: false, enableHighAccuracy: true });
  }, [map]);

  useMapEvents({
    locationfound: (e) => setPosition([e.latlng.lat, e.latlng.lng]),
  });

  if (!position) return null;

  return (
    <CircleMarker
      center={position}
      radius={10}
      pathOptions={{ color: '#2563eb', fillColor: '#3b82f6', fillOpacity: 0.9, weight: 2.5 }}
    >
      <Tooltip direction="top" offset={[0, -12]} opacity={0.95} permanent={false}>
        <span style={{ fontFamily: 'sans-serif', fontSize: 12, fontWeight: 600 }}>You are here</span>
      </Tooltip>
    </CircleMarker>
  );
}

interface MarkersProps {
  resolved: ReturnType<typeof applyOffsets>;
  questCountById: Record<string, number>;
  onSelect?: (dest: ApiDestination) => void;
}

function ZoomAwareMarkers({ resolved, questCountById, onSelect }: MarkersProps) {
  const map = useMap();
  const [zoom, setZoom] = useState(map.getZoom());

  useMapEvents({ zoom: () => setZoom(map.getZoom()) });

  if (zoom < ZOOM_THRESHOLD) {
    return (
      <Marker
        position={ILOCOS_NORTE}
        icon={createProvinceIcon(resolved.length)}
        eventHandlers={{
          click: () => map.flyTo(ILOCOS_NORTE, ZOOM_THRESHOLD + 1, { duration: 1 }),
        }}
      >
        <Tooltip direction="top" offset={[0, -28]} opacity={0.95}>
          <span style={{ fontFamily: 'sans-serif', fontSize: 12, fontWeight: 600 }}>
            Ilocos Norte · {resolved.length} destination{resolved.length !== 1 ? 's' : ''} — tap to explore
          </span>
        </Tooltip>
      </Marker>
    );
  }

  return (
    <>
      {resolved.map(({ dest, coords }, index) => {
        const count = questCountById[dest.id] ?? 0;
        return (
          <CircleMarker
            key={dest.id}
            center={[coords.lat, coords.lng]}
            radius={16}
            pathOptions={{
              color: coords.approximate ? '#c2410c44' : '#c2410c',
              fillColor: coords.approximate ? '#fb923c' : '#f97316',
              fillOpacity: 0.92,
              weight: 2.5,
              dashArray: coords.approximate ? '4 3' : undefined,
            }}
            eventHandlers={{ click: () => onSelect?.(dest) }}
          >
            <Tooltip direction="top" offset={[0, -18]} opacity={0.95} permanent={false}>
              <div style={{ fontFamily: 'sans-serif' }} className="text-xs leading-tight">
                <span className="font-bold text-trail-orange">{index + 1}.</span>{' '}
                <span className="font-semibold">{dest.name}</span>
                {coords.approximate && (
                  <span className="ml-1 font-normal text-gray-400">(approx.)</span>
                )}
                <br />
                <span className="text-gray-500">{count} quest{count !== 1 ? 's' : ''}</span>
              </div>
            </Tooltip>
          </CircleMarker>
        );
      })}
    </>
  );
}

export function AnalyticsMap({ destinations, quests, onSelect }: Props) {
  const [mounted, setMounted] = useState(false);
  useEffect(() => { setMounted(true); }, []);

  const questCountById = quests.reduce<Record<string, number>>((acc, q) => {
    acc[q.destinationId] = (acc[q.destinationId] ?? 0) + 1;
    return acc;
  }, {});

  const raw = destinations
    .map((d) => ({ dest: d, coords: resolveCoordsFor(d) }))
    .filter((x): x is { dest: ApiDestination; coords: NonNullable<ReturnType<typeof resolveCoordsFor>> } =>
      x.coords !== null,
    );

  const resolved = applyOffsets(raw);

  if (!mounted) return <div className="w-full rounded-2xl bg-trail-cream animate-pulse" style={{ height: 320 }} />;

  return (
    <MapContainer
      center={ILOCOS_NORTE}
      zoom={10}
      scrollWheelZoom
      className="w-full rounded-2xl overflow-hidden"
      style={{ height: 320, zIndex: 0 }}
    >
      <TileLayer
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution='&copy; <a href="https://openstreetmap.org">OpenStreetMap</a>'
      />
      <ZoomAwareMarkers
        resolved={resolved}
        questCountById={questCountById}
        onSelect={onSelect}
      />
      <LocationMarker />
    </MapContainer>
  );
}
