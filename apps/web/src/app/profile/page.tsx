'use client';

import { useEffect, useRef, useState } from 'react';
import { Sidebar } from '@/components/Sidebar';
import { MobileNav } from '@/components/MobileNav';
import { PageHeader } from '@/components/PageHeader';
import { AuthGuard } from '@/components/AuthGuard';
import { useStore } from '@/lib/store';
import { apiClient } from '@/lib/api-client';

type RoleMeta = { label: string; color: string; bg: string };

type BadgeRow = {
  id: string;
  key: string;
  name: string;
  description: string | null;
  icon: string;
  tier: string;
  earned_at: string | null;
};

const TIER_STYLE = {
  bronze:    { ring: 'ring-amber-300  bg-amber-50',   label: 'Bronze',    labelColor: 'text-amber-600' },
  silver:    { ring: 'ring-slate-300  bg-slate-50',   label: 'Silver',    labelColor: 'text-slate-500' },
  gold:      { ring: 'ring-yellow-300 bg-yellow-50',  label: 'Gold',      labelColor: 'text-yellow-600' },
  legendary: { ring: 'ring-purple-300 bg-purple-50',  label: 'Legendary', labelColor: 'text-purple-600' },
};

const DEFAULT_ROLE: RoleMeta = { label: 'Tourist', color: 'text-blue-700', bg: 'bg-blue-100' };

const ROLE_BADGE: Record<string, RoleMeta> = {
  tourist:   DEFAULT_ROLE,
  partner:   { label: 'Partner',   color: 'text-purple-700', bg: 'bg-purple-100' },
  lgu_admin: { label: 'LGU Admin', color: 'text-red-700',    bg: 'bg-red-100' },
  staff:     { label: 'Staff',     color: 'text-orange-700', bg: 'bg-orange-100' },
};

function xpForNextLevel(level: number): number {
  return Math.floor(100 * Math.pow(level, 1.5));
}

const _rawOriginUrl = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:4000/v1';
const _normalizedOriginUrl = /^https?:\/\//i.test(_rawOriginUrl) ? _rawOriginUrl : `https://${_rawOriginUrl}`;
const API_ORIGIN = _normalizedOriginUrl.replace(/\/v1$/, '');

function resolveAvatarUrl(url: string): string {
  if (!url) return '';
  if (url.startsWith('http')) return url;
  return `${API_ORIGIN}${url}`;
}

export default function ProfilePage() {
  const { user, setUser } = useStore();

  const [displayName,    setDisplayName]    = useState('');
  const [homeRegion,     setHomeRegion]     = useState('');
  const [avatarUrl,      setAvatarUrl]      = useState('');
  const [uploading,      setUploading]      = useState(false);
  const [saving,         setSaving]         = useState(false);
  const [loadingProfile, setLoadingProfile] = useState(true);
  const [toast,          setToast]          = useState<string | null>(null);
  const [error,          setError]          = useState<string | null>(null);
  const [badgeList,      setBadgeList]      = useState<BadgeRow[]>([]);
  const [loadingBadges,  setLoadingBadges]  = useState(true);

  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    apiClient.get('/me')
      .then((r) => {
        setUser(r.data);
        setDisplayName(r.data.displayName ?? '');
        setHomeRegion(r.data.homeRegion ?? '');
        setAvatarUrl(r.data.avatarUrl ?? '');
      })
      .catch(() => setError('Failed to load profile data.'))
      .finally(() => setLoadingProfile(false));

    apiClient.get('/me/badges')
      .then((r) => setBadgeList(r.data))
      .catch(() => {})
      .finally(() => setLoadingBadges(false));
  }, []);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(null), 3000);
  };

  const handleAvatarClick = () => {
    fileInputRef.current?.click();
  };

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploading(true);
    setError(null);
    try {
      const form = new FormData();
      form.append('file', file);
      const res = await apiClient.post('/me/avatar', form, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      setUser(res.data);
      setAvatarUrl(res.data.avatarUrl ?? '');
      showToast('Photo updated!');
    } catch (e: any) {
      setError(e.response?.data?.message ?? 'Failed to upload photo.');
    } finally {
      setUploading(false);
      // reset so same file can be re-selected
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  };

  const handleSave = async () => {
    setSaving(true);
    setError(null);
    try {
      const res = await apiClient.patch('/me', {
        displayName: displayName.trim() || undefined,
        homeRegion:  homeRegion.trim()  || undefined,
      });
      setUser(res.data);
      showToast('Profile updated!');
    } catch (e: any) {
      setError(e.response?.data?.message ?? 'Failed to save profile.');
    } finally {
      setSaving(false);
    }
  };

  const level    = user?.level   ?? 1;
  const xpTotal  = user?.xpTotal ?? 0;
  const xpNext   = xpForNextLevel(level);
  const xpPct    = Math.min(100, Math.round((xpTotal / Math.max(xpNext, 1)) * 100));
  const roleMeta: RoleMeta = ROLE_BADGE[user?.role ?? 'tourist'] ?? DEFAULT_ROLE;
  const initial   = user?.username?.[0]?.toUpperCase() ?? '?';
  const photoUrl  = resolveAvatarUrl(avatarUrl);

  return (
    <AuthGuard>
      {/* Hidden file input */}
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={handleFileChange}
      />

      {toast && (
        <div className="fixed top-4 left-1/2 -translate-x-1/2 z-[200] bg-trail-brown text-white text-sm
                        px-5 py-3 rounded-2xl shadow-xl flex items-center gap-2 whitespace-nowrap">
          <span className="text-green-400 text-base">✓</span> {toast}
        </div>
      )}

      <div className="flex bg-trail-cream min-h-screen">
        <Sidebar />

        <main className="flex-1 min-w-0 flex flex-col">
          <PageHeader title="My Profile" subtitle="Account settings & progress" />

          <div className="flex-1 overflow-y-auto">
            <div className="px-4 md:px-8 py-4 md:py-6 pb-24 md:pb-6 max-w-2xl mx-auto space-y-4">

              {/* ── Hero card ── */}
              <div className="bg-trail-brown rounded-2xl shadow-sm px-4 md:px-6 py-5">
                <div className="flex items-center gap-4 mb-4">

                  {/* Clickable avatar */}
                  <button
                    onClick={handleAvatarClick}
                    disabled={uploading}
                    className="relative shrink-0 group"
                    aria-label="Change profile photo"
                  >
                    {photoUrl ? (
                      <img
                        src={photoUrl}
                        alt="Profile photo"
                        className="w-16 h-16 md:w-20 md:h-20 rounded-full object-cover shadow-lg"
                      />
                    ) : (
                      <div className="w-16 h-16 md:w-20 md:h-20 rounded-full
                                      bg-gradient-to-br from-amber-400 to-orange-500
                                      flex items-center justify-center
                                      text-white text-2xl md:text-3xl font-bold shadow-lg">
                        {initial}
                      </div>
                    )}

                    {/* Camera / spinner overlay */}
                    <div className={`absolute inset-0 rounded-full flex items-center justify-center
                                     transition-opacity
                                     ${uploading
                                       ? 'bg-black/50 opacity-100'
                                       : 'bg-black/40 opacity-0 group-hover:opacity-100 group-active:opacity-100'}`}>
                      {uploading
                        ? <span className="text-white text-lg animate-spin">⟳</span>
                        : <span className="text-white text-xl">📷</span>}
                    </div>
                  </button>

                  <div className="flex-1 min-w-0">
                    {loadingProfile ? (
                      <div className="space-y-2 animate-pulse">
                        <div className="h-5 bg-trail-brown-mid rounded w-36" />
                        <div className="h-3 bg-trail-brown-mid rounded w-24 opacity-60" />
                      </div>
                    ) : (
                      <>
                        <h2 className="text-lg md:text-xl font-bold text-white leading-tight truncate">
                          {user?.displayName ?? user?.username ?? '—'}
                        </h2>
                        <p className="text-trail-peach text-sm">@{user?.username}</p>
                        <p className="text-trail-peach text-xs opacity-60 mt-0.5 truncate">
                          {user?.email}
                        </p>
                      </>
                    )}
                  </div>

                  <span className={`text-xs font-semibold px-3 py-1 rounded-full shrink-0 self-start ${roleMeta.bg} ${roleMeta.color}`}>
                    {roleMeta.label}
                  </span>
                </div>

                <div className="pt-4 border-t border-trail-brown-mid">
                  <div className="flex justify-between items-center mb-1.5">
                    <span className="text-xs font-semibold text-trail-peach">Level {level} Explorer</span>
                    <span className="text-xs text-trail-peach opacity-70">
                      {xpTotal.toLocaleString()} / {xpNext.toLocaleString()} XP
                    </span>
                  </div>
                  <div className="w-full bg-trail-brown-mid rounded-full h-2">
                    <div
                      className="bg-trail-orange h-2 rounded-full transition-all duration-700"
                      style={{ width: `${xpPct}%` }}
                    />
                  </div>
                  <p className="text-[11px] text-trail-peach opacity-50 mt-1">
                    {xpPct}% to Level {level + 1}
                  </p>
                </div>
              </div>

              {/* ── Stat chips ── */}
              <div className="grid grid-cols-3 gap-2 md:gap-3">
                {[
                  { icon: '🏅', label: 'Level',   value: String(level) },
                  { icon: '⭐', label: 'Total XP', value: xpTotal.toLocaleString() },
                  { icon: '📅', label: 'Since',    value: user?.createdAt
                      ? new Date(user.createdAt).toLocaleDateString('en-PH', { month: 'short', year: 'numeric' })
                      : '—' },
                ].map((s) => (
                  <div key={s.label}
                    className="bg-white rounded-xl border border-gray-100 shadow-sm p-3 md:p-4 text-center">
                    <p className="text-xl md:text-2xl mb-1">{s.icon}</p>
                    <p className="text-sm md:text-lg font-bold text-trail-brown leading-tight">{s.value}</p>
                    <p className="text-[10px] md:text-[11px] text-gray-400 mt-0.5">{s.label}</p>
                  </div>
                ))}
              </div>

              {/* ── Badges ── */}
              <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
                <div className="px-4 md:px-6 py-3 md:py-4 border-b border-gray-100 flex items-center justify-between">
                  <h3 className="font-bold text-trail-brown text-sm">My Badges</h3>
                  {!loadingBadges && (
                    <span className="text-xs text-gray-400">
                      {badgeList.filter((b) => b.earned_at).length} / {badgeList.length} earned
                    </span>
                  )}
                </div>

                <div className="px-4 md:px-6 py-4">
                  {loadingBadges ? (
                    <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                      {[...Array(6)].map((_, i) => (
                        <div key={i} className="animate-pulse rounded-xl bg-gray-100 h-24" />
                      ))}
                    </div>
                  ) : badgeList.length === 0 ? (
                    <p className="text-sm text-gray-400 text-center py-4">No badges available yet.</p>
                  ) : (
                    <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                      {badgeList.map((badge) => {
                        const tier = TIER_STYLE[badge.tier as keyof typeof TIER_STYLE] ?? TIER_STYLE.bronze;
                        const earned = !!badge.earned_at;
                        return (
                          <div
                            key={badge.id}
                            className={`relative rounded-xl ring-2 p-3 flex flex-col items-center text-center gap-1 transition
                              ${earned ? tier.ring : 'ring-gray-200 bg-gray-50 opacity-50'}`}
                          >
                            <span className="text-3xl leading-none">{earned ? badge.icon : '🔒'}</span>
                            <p className={`text-xs font-bold leading-tight ${earned ? 'text-trail-brown' : 'text-gray-400'}`}>
                              {badge.name}
                            </p>
                            {earned ? (
                              <span className={`text-[10px] font-semibold uppercase tracking-wide ${tier.labelColor}`}>
                                {tier.label}
                              </span>
                            ) : (
                              <p className="text-[10px] text-gray-400 leading-tight line-clamp-2">{badge.description}</p>
                            )}
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>
              </div>

              {/* ── Edit form ── */}
              <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
                <div className="px-4 md:px-6 py-3 md:py-4 border-b border-gray-100">
                  <h3 className="font-bold text-trail-brown text-sm">Edit Profile</h3>
                </div>

                <div className="px-4 md:px-6 py-4 md:py-5 space-y-4">
                  {error && (
                    <div className="bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3">
                      {error}
                    </div>
                  )}

                  {/* Display Name */}
                  <div>
                    <label className="block text-xs font-semibold text-gray-500 mb-1.5 uppercase tracking-wide">
                      Display Name
                    </label>
                    <input
                      type="text"
                      value={displayName}
                      onChange={(e) => setDisplayName(e.target.value)}
                      placeholder={user?.username ?? 'Your display name'}
                      maxLength={64}
                      className="w-full px-4 py-3 border border-gray-200 rounded-xl text-base
                                 focus:outline-none focus:ring-2 focus:ring-trail-orange
                                 focus:border-transparent text-trail-brown placeholder-gray-300 transition"
                    />
                    <p className="text-[11px] text-gray-400 mt-1">
                      Shown on leaderboards and public profiles.
                    </p>
                  </div>

                  {/* Home Region */}
                  <div>
                    <label className="block text-xs font-semibold text-gray-500 mb-1.5 uppercase tracking-wide">
                      Home Region
                    </label>
                    <input
                      type="text"
                      value={homeRegion}
                      onChange={(e) => setHomeRegion(e.target.value)}
                      placeholder="e.g. Ilocos Norte, NCR"
                      maxLength={64}
                      className="w-full px-4 py-3 border border-gray-200 rounded-xl text-base
                                 focus:outline-none focus:ring-2 focus:ring-trail-orange
                                 focus:border-transparent text-trail-brown placeholder-gray-300 transition"
                    />
                  </div>

                  {/* Read-only fields */}
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-1">
                    <div>
                      <label className="block text-xs font-semibold text-gray-400 mb-1.5 uppercase tracking-wide">
                        Email
                      </label>
                      <input
                        type="email"
                        value={user?.email ?? ''}
                        disabled
                        className="w-full px-4 py-3 border border-gray-100 rounded-xl text-base
                                   bg-gray-50 text-gray-400 cursor-not-allowed truncate"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-semibold text-gray-400 mb-1.5 uppercase tracking-wide">
                        Username
                      </label>
                      <input
                        type="text"
                        value={user?.username ?? ''}
                        disabled
                        className="w-full px-4 py-3 border border-gray-100 rounded-xl text-base
                                   bg-gray-50 text-gray-400 cursor-not-allowed font-mono"
                      />
                    </div>
                  </div>
                  <p className="text-[11px] text-gray-400">
                    Email and username cannot be changed after registration.
                  </p>
                </div>

                <div className="px-4 md:px-6 py-4 bg-gray-50 border-t border-gray-100
                                flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                  <span className="text-xs text-gray-400 text-center sm:text-left">
                    Role:{' '}
                    <span className={`font-semibold ${roleMeta.color}`}>{roleMeta.label}</span>
                  </span>
                  <button
                    onClick={handleSave}
                    disabled={saving || loadingProfile}
                    className="w-full sm:w-auto bg-trail-orange text-white px-6 py-3 sm:py-2
                               rounded-xl text-base sm:text-sm font-semibold
                               hover:bg-trail-orange-dark disabled:opacity-50
                               transition-all active:scale-95"
                  >
                    {saving ? 'Saving…' : 'Save Changes'}
                  </button>
                </div>
              </div>

            </div>
          </div>

          <MobileNav />
        </main>
      </div>
    </AuthGuard>
  );
}
