/* Mounts actual battle state supplied by our game host. No fabricated roster/stage. */
(function (root) {
  'use strict';
  const escape = v => String(v).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  function mount(node, host) {
    if (!node || !host || typeof host.load !== 'function' || typeof host.dispatch !== 'function') throw Error('BATTLE_HOST_REQUIRED');
    let current = null, path = [], busy = false, closed = false, notice = '', commands = 0, pendingRequest = null;
    const prefix = typeof crypto !== 'undefined' && crypto.randomUUID ? crypto.randomUUID() : Date.now().toString(36) + '-' + Math.random().toString(36).slice(2);
    function render() {
      if (closed || !current) return;
      const s = current, actor = s.roster.find(c => c.instanceId === s.order[s.pending.length]);
      node.innerHTML = '<section class="od-battle"><header><h1>Battle · Turn ' + s.turn + '</h1><button type="button" data-exit>Return to game</button></header><div class="od-battle-enemy"><h2>' + escape(s.enemy.name) + '</h2><progress max="' + s.enemy.hp + '" value="' + s.enemyHp + '"></progress><span>' + s.enemyHp.toLocaleString() + ' HP</span></div><div class="od-battle-team"><label>Team HP <strong>' + s.hp.toLocaleString() + ' / ' + s.maxHp.toLocaleString() + '</strong></label><progress max="' + s.maxHp + '" value="' + s.hp + '"></progress></div><div class="od-battle-rotation">' + s.order.map((key, i) => { const unit = s.roster.find(c => c.instanceId === key), picked = s.pending[i]; return '<article class="' + (i === s.pending.length ? 'active' : '') + '"><strong>' + escape(unit.name) + '</strong><span>' + (picked ? picked.ki + ' Ki' : i === s.pending.length ? 'Choose Ki Spheres' : 'Waiting') + '</span></article>'; }).join('') + '</div>' + (s.phase === 'playing' ? '<p>' + (actor ? 'Collect connected Ki Spheres for ' + escape(actor.name) + '. Start on the bottom row.' : 'Ready to attack.') + '</p><div class="od-spheres" role="group" aria-label="Ki Spheres">' + s.board.flatMap((row, y) => row.map((color, x) => '<button type="button" class="od-sphere c' + color + (path.some(p => p[0] === x && p[1] === y) ? ' selected' : '') + '" data-cell="' + x + ',' + y + '" aria-label="' + root.OfflineDokkanBattle.colors[color] + ' Ki Sphere, row ' + (y + 1) + ', column ' + (x + 1) + '" aria-pressed="' + path.some(p => p[0] === x && p[1] === y) + '">' + (color === 5 ? '✦' : '') + '</button>')).join('') + '</div><div class="od-battle-actions"><button type="button" data-clear' + (!path.length ? ' disabled' : '') + '>Clear selection</button><button type="button" data-collect' + (!path.length || !actor ? ' disabled' : '') + '>Collect ' + path.length + ' Ki Spheres</button><button type="button" data-order' + (s.pending.length ? ' disabled' : '') + '>Change attack order</button><button type="button" data-attack' + (s.pending.length !== 3 ? ' disabled' : '') + '>Attack</button></div>' : '<h2 class="od-battle-result">' + (s.phase === 'victory' ? 'Victory' : s.phase === 'defeat' ? 'K.O.' : 'Battle turn limit reached') + '</h2>') + '<p class="od-battle-notice" role="status">' + escape(notice) + '</p></section>';
      node.querySelectorAll('button').forEach(b => { if (busy) b.disabled = true; });
      if (pendingRequest && !busy) {
        node.querySelectorAll('button').forEach(b => { b.disabled = true; });
        const retry = document.createElement('button'); retry.type = 'button'; retry.textContent = 'Retry saving battle'; retry.onclick = () => send(null); node.querySelector('.od-battle-notice').after(retry);
      }
      node.querySelector('[data-exit]').onclick = () => { if (!busy && typeof host.onExit === 'function') host.onExit(); };
      const bind = (selector, callback) => { const el = node.querySelector(selector); if (el) el.onclick = callback; };
      bind('[data-clear]', () => { path = []; notice = ''; render(); });
      bind('[data-collect]', () => send({kind: 'collect', path: path.map(p => p.slice())}));
      bind('[data-order]', () => send({kind: 'order', order: s.order.slice(1).concat(s.order[0])}));
      bind('[data-attack]', () => send({kind: 'resolve'}));
      node.querySelectorAll('[data-cell]').forEach(b => { b.onclick = () => {
        if (!actor || busy) return;
        const p = b.dataset.cell.split(',').map(Number), old = path.findIndex(c => c[0] === p[0] && c[1] === p[1]);
        if (old !== -1) path = path.slice(0, old); else path.push(p);
        notice = ''; render();
      }; });
    }
    async function send(command) {
      if (busy || closed) return; busy = true; notice = 'Saving battle…'; render();
      const request = pendingRequest || {id: prefix + ':' + ++commands, revision: current.revision, ...command};
      pendingRequest = request;
      try {
        // Host commits the state before exposing attack/animation events. It retains
        // this intent ID on transport retries; the view never awards rewards.
        const reply = await host.dispatch(request);
        if (closed) return;
        root.OfflineDokkanBattle.validate(reply.state); current = reply.state; path = []; pendingRequest = null;
        notice = reply.events.filter(e => e.type === 'player-attack' || e.type === 'enemy-attack').map(e => (e.type === 'player-attack' ? 'Damage dealt: ' : 'Damage received: ') + e.damage.toLocaleString()).join(' · ');
        if (typeof host.onEvents === 'function') await host.onEvents(reply.events, current);
      } catch (e) {
        notice = e && e.message || 'Battle could not be saved. Try again.';
        // The host load is serialized behind dispatch. It can distinguish a
        // rejected command from a committed command whose response was lost.
        try {
          const saved = root.OfflineDokkanBattle.validate(await host.load());
          if (!closed) { current = saved; if (saved.commands.some(c => c.id === request.id)) path = []; pendingRequest = null; }
        } catch { /* Keep the exact intent for retry; never mint another ID. */ }
      }
      finally { busy = false; render(); }
    }
    const ready = Promise.resolve().then(() => host.load()).then(s => { if (!closed) { current = root.OfflineDokkanBattle.validate(s); render(); } });
    ready.catch(e => { if (!closed) node.textContent = e.message || 'Battle could not be opened.'; });
    return {ready, close() { closed = true; node.replaceChildren(); }};
  }
  root.OfflineDokkanBattleView = Object.freeze({mount});
})(typeof globalThis !== 'undefined' ? globalThis : this);
