import { create } from 'zustand';

export interface AuthUser {
  id: string;
  email: string;
  username: string;
  displayName: string | null;
  avatarUrl: string | null;
  xpTotal: number;
  level: number;
  xpForNextLevel: number;
  role: string;
  homeRegion: string | null;
  createdAt: string;
}

export interface ApiDestination {
  id: string;
  slug: string;
  name: string;
  region: string | null;
  countryCode: string;
  description: string | null;
  heroImageUrl: string | null;
  isActive: boolean;
  lat: number | null;
  lng: number | null;
}

export interface ApiQuest {
  id: string;
  destinationId: string;
  title: string;
  summary: string | null;
  difficulty: number;
  estDurationMin: number | null;
  xpReward: number;
  questType: string;
  isPremium: boolean;
  coverImageUrl: string | null;
  createdAt: string;
}

interface StoreState {
  user: AuthUser | null;
  isAuthenticated: boolean;
  destinations: ApiDestination[];
  quests: ApiQuest[];
  loading: boolean;
  error: string | null;
  qrScannerOpen: boolean;
  selectedDestinationId: string | null;

  setUser: (user: AuthUser | null) => void;
  logout: () => void;
  setDestinations: (destinations: ApiDestination[]) => void;
  setQuests: (quests: ApiQuest[]) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  setQrScannerOpen: (open: boolean) => void;
  setSelectedDestinationId: (id: string | null) => void;
}

export const useStore = create<StoreState>((set) => ({
  user: null,
  isAuthenticated: false,
  destinations: [],
  quests: [],
  loading: false,
  error: null,
  qrScannerOpen: false,
  selectedDestinationId: typeof window !== 'undefined'
    ? (localStorage.getItem('selectedDestinationId') ?? null)
    : null,

  setUser: (user) => set({ user, isAuthenticated: !!user }),
  logout: () => {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('access_token');
      localStorage.removeItem('refresh_token');
      localStorage.removeItem('selectedDestinationId');
    }
    set({ user: null, isAuthenticated: false, destinations: [], quests: [], selectedDestinationId: null });
  },
  setDestinations: (destinations) => set({ destinations }),
  setQuests: (quests) => set({ quests }),
  setLoading: (loading) => set({ loading }),
  setError: (error) => set({ error }),
  setQrScannerOpen: (open) => set({ qrScannerOpen: open }),
  setSelectedDestinationId: (id) => {
    if (typeof window !== 'undefined') {
      if (id) localStorage.setItem('selectedDestinationId', id);
      else localStorage.removeItem('selectedDestinationId');
    }
    set({ selectedDestinationId: id });
  },
}));
