/**
 * رمز اللاعب: أرقام فريدة يبحث فيها الناس عنه ويضيفونه صديق.
 * الرمز العادي ٨ أرقام عشوائية بدون نمط، وينعطى لكل لاعب ببلاش.
 * الرموز المميزة (أقصر، أو فيها نمط مثل ٧٧٧٧ و١٢٣٤٥) تنشرى بالجواهر، وسعرها من طولها ونمطها.
 */

/** سعر الرمز حسب عدد أرقامه (قبل النمط). */
const BASE: Record<number, number> = { 3: 1000, 4: 500, 5: 250, 6: 120, 7: 60, 8: 30 };

/** درجات الرموز (للشكل في التطبيق): ٠ عادي، ١ مميز، ٢ نادر، ٣ ملحمي، ٤ أسطوري. */
const TIER_FROM = [0, 31, 120, 300, 1000];

/** أرقام بس، من ٣ إلى ٨، وما يبدأ بصفر. */
export function validPid(pid: unknown): pid is string {
  return typeof pid === 'string' && /^[1-9][0-9]{2,7}$/.test(pid);
}

/** كم يتضاعف سعر الرمز من نمطه (أعلى نمط فيه). ١ = بدون نمط. */
export function pidBonus(pid: string): number {
  const d = [...pid].map(Number);
  if (d.every((x) => x === d[0])) return 3; // ٧٧٧٧
  if (/^[1-9]0+$/.test(pid)) return 2.5; // ١٠٠٠٠
  const steps = d.slice(1).map((x, i) => x - d[i]);
  if (steps.every((s) => s === 1) || steps.every((s) => s === -1)) return 2; // ١٢٣٤٥ أو ٥٤٣٢١
  const block = [1, 2, 3, 4].some((n) => n < pid.length && pid.length % n === 0 && pid === pid.slice(0, n).repeat(pid.length / n));
  const pairs = pid.length % 2 === 0 && /^((\d)\2)+$/.test(pid); // ١١٢٢٣٣
  if (block || pairs || /^[1-9]\d0{3,}$/.test(pid)) return 1.5; // ١٢١٢، ١١٢٢٣٣، ٢٥٠٠٠
  if (/(\d)\1{3}/.test(pid)) return 1.4; // فيه ٤ أرقام نفس الشي ورا بعض
  if (pid.length >= 4 && pid === [...pid].reverse().join('')) return 1.3; // ١٢٣٣٢١
  return 1;
}

/** سعر الرمز بالجواهر. */
export function pidPrice(pid: string): number {
  return Math.max(BASE[8], Math.round((BASE[pid.length] * pidBonus(pid)) / 10) * 10);
}

export function pidTier(pid: string): number {
  const price = pidPrice(pid);
  return TIER_FROM.filter((t) => price >= t).length - 1;
}

/** رمز عادي ينعطى ببلاش: ٨ أرقام بدون نمط (الأنماط للبيع). */
export function randomPid(rand: () => number = Math.random): string {
  for (;;) {
    const pid = String(10_000_000 + Math.floor(rand() * 90_000_000));
    if (pidBonus(pid) === 1) return pid;
  }
}

/** اقتراحات رموز مميزة من كل الدرجات (بعدها السيرفر يشيل المحجوز منها). */
export function suggestPids(rand: () => number = Math.random): string[] {
  const digit = (from = 1) => from + Math.floor(rand() * (10 - from));
  const num = (len: number) => String(digit()) + Array.from({ length: len - 1 }, () => digit(0)).join('');
  const seq = (len: number) => {
    const up = rand() < 0.6;
    const start = up ? 1 + Math.floor(rand() * (10 - len)) : len - 1 + Math.floor(rand() * (10 - len + 1));
    return Array.from({ length: len }, (_, i) => String(up ? start + i : start - i)).join('');
  };
  const out = new Set<string>([
    String(digit()).repeat(4),
    num(3),
    String(digit()) + '0'.repeat(4 + Math.floor(rand() * 3)),
    String(digit()).repeat(5 + Math.floor(rand() * 2)),
    seq(5 + Math.floor(rand() * 3)),
    num(4),
    num(2).repeat(2 + Math.floor(rand() * 2)),
    num(5),
    [digit(), digit(0), digit(0)].map((x) => String(x).repeat(2)).join(''),
    num(6),
    num(7),
    String(digit()).repeat(8),
  ]);
  return [...out].filter((p) => validPid(p));
}
