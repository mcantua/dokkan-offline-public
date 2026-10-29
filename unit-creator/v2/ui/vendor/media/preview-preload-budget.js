// Per-effect budgets: queue time never consumes active idle time. All limits are cumulative.
export function createEffectPreloadLease({
  label = 'effect preload', idleMs = 40000, queueMs = idleMs * 3,
  activeMs = idleMs * 3, now = () => performance.now(),
  setTimer = setTimeout, clearTimer = clearTimeout,
} = {}) {
  for (const value of [idleMs, queueMs, activeMs]) {
    if (!Number.isFinite(value) || value <= 0) throw new Error('finite positive preload budget required');
  }
  let phase = 'active';
  let last = now();
  let idle = 0;
  let active = 0;
  let queued = 0;
  let timer;
  let error = null;
  let finished = false;
  const completed = new Set();
  const cleanups = new Set();
  let rejectCancelled;
  const cancelled = new Promise((_, reject) => { rejectCancelled = reject; });
  cancelled.catch(() => {});
  function charge() {
    const stamp = now();
    const elapsed = Math.max(0, stamp - last);
    last = stamp;
    if (phase === 'queue') queued += elapsed;
    else { active += elapsed; idle += elapsed; }
  }
  function cancel(reason = new Error(`${label} cancelled`)) {
    if (error || finished) return;
    error = reason instanceof Error ? reason : new Error(String(reason));
    clearTimer(timer);
    for (const cleanup of cleanups) { try { cleanup(); } catch {} }
    cleanups.clear();
    rejectCancelled(error);
  }
  function check() {
    if (error) throw error;
    if (finished) throw new Error(`${label} lease finished`);
    charge();
    if (queued >= queueMs) cancel(new Error(`${label} queue timeout (${queueMs}ms cumulative)`));
    else if (active >= activeMs) cancel(new Error(`${label} active limit (${activeMs}ms cumulative)`));
    else if (idle >= idleMs) cancel(new Error(`${label} active idle timeout (${idleMs}ms)`));
    if (error) throw error;
  }
  function arm() {
    clearTimer(timer);
    const remaining = phase === 'queue'
      ? queueMs - queued
      : Math.min(idleMs - idle, activeMs - active);
    timer = setTimer(() => { try { check(); arm(); } catch {} }, Math.max(1, remaining));
  }
  const lease = {
    assertCurrent: check,
    queue() { check(); phase = 'queue'; arm(); },
    admit() { check(); phase = 'active'; arm(); },
    // Only call after a distinct atlas has actually finished. Repeated keys cannot extend idle.
    completedAtlas(key) {
      check();
      if (phase !== 'active' || completed.has(key)) return;
      completed.add(key);
      idle = 0;
      arm();
    },
    onCancel(cleanup) {
      if (error) { cleanup(); return () => {}; }
      cleanups.add(cleanup);
      return () => cleanups.delete(cleanup);
    },
    race(work) { check(); return Promise.race([work, cancelled]); },
    cancel,
    finish() { if (finished) return; finished = true; clearTimer(timer); cleanups.clear(); },
    get cancelled() { return !!error; },
  };
  arm();
  return lease;
}

export function createEffectPreloadScope() {
  let error = null;
  const leases = new Set();
  let rejectCancelled;
  const cancelled = new Promise((_, reject) => { rejectCancelled = reject; });
  cancelled.catch(() => {});
  return {
    assertCurrent() { if (error) throw error; },
    lease(options) {
      this.assertCurrent();
      const lease = createEffectPreloadLease(options);
      leases.add(lease);
      return lease;
    },
    release(lease) { leases.delete(lease); lease.finish(); },
    race(work) { this.assertCurrent(); return Promise.race([work, cancelled]); },
    cancel(reason = new Error('preload generation cancelled')) {
      if (error) return;
      error = reason;
      for (const lease of leases) lease.cancel(reason);
      leases.clear();
      rejectCancelled(reason);
    },
  };
}
