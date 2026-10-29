import { turnKey, type GameState } from '../../engine/src/index.js';

export interface Note {
  uid: string;
  title: string;
  body: string;
}

const name = (s: GameState, id: string | null) => s.players.find((p) => p.id === id)?.name ?? '';

/**
 * مين نرسل له إشعار بعد تغيير في اللعبة. بس اللي عليهم دور، عشان ما نزعج الباقين.
 * ما نكشف أي سر في الإشعار (لا أدوار ولا كروت).
 * اللي طلع من اللعبة (والبوت يكمل عنه) ما يوصله شي عنها: ما يقدر يلعب فيها، ويمكن الحين في لعبة ثانية.
 */
export function whoToNotify(prev: GameState | null, next: GameState): Note[] {
  const left = new Set(next.autopilot ?? []);
  return notesFor(prev, next).filter((n) => !left.has(n.uid));
}

function notesFor(prev: GameState | null, next: GameState): Note[] {
  const alive = next.players.filter((p) => p.alive);
  if (next.phase === 'gameOver') {
    if (prev?.phase === 'gameOver') return [];
    const body = next.winner === 'loyal' ? 'فاز الأوفياء' : 'فاز الخونة';
    return next.players.map((p) => ({ uid: p.id, title: 'انتهت اللعبة', body }));
  }
  if (!prev) {
    return next.players.map((p) => ({ uid: p.id, title: 'اللعبة بدأت!', body: 'ادخل واعرف دورك السري' }));
  }
  if (turnKey(prev) === turnKey(next)) return [];

  const pres = next.presidentId;
  switch (next.phase) {
    case 'nomination':
      return [{ uid: pres, title: 'أنت الرئيس!', body: 'اختر وزير قبل ما يخلص الوقت' }];
    case 'election':
      return alive.map((p) => ({
        uid: p.id,
        title: 'وقت التصويت',
        body: `حكومة ${name(next, pres)} + ${name(next, next.nomineeId)}: موافق ولا رافض؟`,
      }));
    case 'presidentDiscard':
      return [{ uid: pres, title: 'دورك', body: 'اختر الكرت اللي بترميه' }];
    case 'chancellorEnact':
      return [{ uid: next.nomineeId!, title: 'دورك', body: 'اختر القرار اللي بتمرره' }];
    case 'vetoResponse':
      return [{ uid: pres, title: 'الوزير طلب النقض', body: 'توافق ولا ترفض؟' }];
    case 'power':
      return [{ uid: pres, title: 'عندك قدرة', body: 'استخدمها قبل ما يخلص الوقت' }];
    default:
      return [];
  }
}
