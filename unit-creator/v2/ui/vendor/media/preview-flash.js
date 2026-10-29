import {nativeTaskClock} from './preview-task-clock.js';
/* Original Forge adapter, MIT. Numeric native proof: native-preview-flash.json.
 * This legacy command is a repeated 1-frame-in/3-frame-out flash, with total
 * life 4*the second argument. It is not a generic linear fade over that value.
 * Existing public front/background fade bands retain their original ordering.
 */
const integer = value => (Number(value) || 0) | 0;
const f = Math.fround;
export function nativeFlashPlan(command) {
  const args = command.args || [];
  const repetitions = integer(args[1]);
  const requestedAlpha = integer(args[5]);
  return {
    start: integer(command.frame ?? args[0]),
    life: repetitions === 0 ? 4 : repetitions << 2,
    color: [args[2], args[3], args[4]].map(value => integer(value) & 255),
    alpha: requestedAlpha >= 1 && requestedAlpha <= 255 ? requestedAlpha : 255,
    background: command.type === 'entryFlashBg'
  };
}
export function nativeFlashState(plan) {
  return { life: plan.life, alpha: plan.alpha, flags: 22, counter: 0, opacity: 0, dead: false };
}
export function advanceNativeFlash(state, step = 1) {
  if (state.dead) return 0;
  const count = Math.max(1, integer(step));
  state.life -= count;
  state.counter += count;
  if (state.flags & 4) {
    const factor = Math.min(1, f(state.counter));
    if (state.counter >= 1) { state.flags &= ~4; state.counter = 0; }
    state.opacity = Math.trunc(f(factor * state.alpha));
  } else if (state.flags & 16) {
    const factor = Math.max(0, Math.min(1, f(1 - f(state.counter / 3))));
    if (state.counter >= 3) { state.flags &= ~20; state.counter = 0; }
    state.opacity = Math.trunc(f(factor * state.alpha));
  } else {
    // Original interval is one tick; it re-arms the next fade-in without
    // changing the current layer opacity until that following update.
    state.counter = 0; state.flags |= 20;
  }
  if (state.life < 0) { state.dead = true; state.flags |= 0x10000020; }
  return state.dead ? 0 : state.opacity;
}
export function nativeFlashOpacity(plan, elapsed, step = 1) {
  if (!Number.isFinite(elapsed) || elapsed < 0 || elapsed >= plan.life) return 0;
  const count = Math.max(1, integer(step)), ticks = Math.floor(elapsed / count) + 1;
  const state = nativeFlashState(plan);
  for (let tick = 0; tick < ticks && !state.dead; tick++) advanceNativeFlash(state, count);
  return state.dead ? 0 : state.opacity;
}
export class FlashCommands {
  constructor(runner) { this.runner = runner; this.tasks = []; }
  execute(command) {
    if (command.type !== 'entryFlash' && command.type !== 'entryFlashBg') return false;
    const plan = nativeFlashPlan(command);
    this.tasks.push({ command, plan, state: nativeFlashState(plan), node: null, lastFrame: null });
    return true;
  }
  _host(plan) {
    // The native background/front variants choose separate scene parents. Use
    // the same hosts/bands as the public player's corresponding native fades:
    // BG z5; foreground z450, below its explicitly higher cutin band z480.
    return plan.background ? this.runner.bg?.host : this.runner.screenFade?.host || this.runner.lwf?.host;
  }
  update(frame, context) {
    const at = Number(frame), native = context?.nativeExecution === true;
    for (let i = this.tasks.length - 1; i >= 0; i--) {
      const task = this.tasks[i], elapsed = at - task.plan.start;
      const step = Math.max(1, integer(native ? context.executionStride : this.runner.step || 1));
      if (native) {
        if (elapsed < 0) continue;
        // ScreenEff.Update runs once per globally executing native call, even
        // when the character-only gate holds the phase clock at this frame.
        advanceNativeFlash(task.state, step); task.lastFrame = at;
      } else if (this.runner.forgeVisual && !this.runner._forgeVisualSeeking) {
        // Initial-pose painting must not consume a native execution tick.
        continue;
      } else if (this.runner._forgeVisualSeeking) {
        task.state = nativeFlashState(task.plan);
        for (let tick = 0; tick < Math.floor(Math.max(0, elapsed) / step) + 1 && !task.state.dead; tick++) advanceNativeFlash(task.state, step);
        task.lastFrame = at;
      } else if (task.lastFrame === null && elapsed >= 0) {
        const ticks = Math.floor(elapsed / step) + 1;
        for (let tick = 0; tick < ticks && !task.state.dead; tick++) advanceNativeFlash(task.state, step);
        task.lastFrame = task.plan.start + (ticks - 1) * step;
      } else if (task.lastFrame !== null && at > task.lastFrame) {
        for (let pending = task.lastFrame + step; pending <= at && !task.state.dead; pending += step) {
          advanceNativeFlash(task.state, step); task.lastFrame = pending;
        }
      }
      if (task.state.dead || (!native && elapsed >= task.plan.life)) { task.node?.remove(); this.tasks.splice(i, 1); continue; }
      this._paint(task);
    }
  }
  _paint(task) {
      const host = this._host(task.plan);
      if (!host) return;
      if (!task.node || !task.node.isConnected) {
        task.node = document.createElement('div');
        task.node.dataset.forgeNativeFlash = task.plan.background ? 'background' : 'front';
        task.node.style.cssText = 'position:absolute;inset:0;pointer-events:none;z-index:' + (task.plan.background ? '5' : '450') + ';';
        task.node.style.background = 'rgb(' + task.plan.color.join(',') + ')';
        host.appendChild(task.node);
      }
      task.node.style.opacity = String(task.state.opacity / 255);
  }
  seek(target) {
    for(let index=this.tasks.length-1;index>=0;index--){
      const task=this.tasks[index],clock=nativeTaskClock(this.runner,task.plan.start,target,Math.trunc(Number(task.command.forgePhase??0)));
      task.state=nativeFlashState(task.plan);
      for(let tick=0;tick<clock.executingCalls&&!task.state.dead;tick++)advanceNativeFlash(task.state,clock.stride);
      if(task.state.dead){task.node?.remove();this.tasks.splice(index,1);}else this._paint(task);
    }
  }
  clear() { for (const task of this.tasks) task.node?.remove(); this.tasks = []; }
}
