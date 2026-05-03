/**
 * Level curve: xp_for_level(n) = floor(100 * n^1.6)
 *   L1→L2: 100   L5→L6: 1318   L20→L21: 13182
 */
export function xpForNextLevel(currentLevel: number): number {
  return Math.floor(100 * Math.pow(currentLevel, 1.6));
}

export function levelFromXp(xpTotal: number): number {
  let level = 1;
  let cumulative = 0;
  while (true) {
    const need = xpForNextLevel(level);
    if (cumulative + need > xpTotal) return level;
    cumulative += need;
    level++;
    if (level > 100) return 100; // hard cap
  }
}
