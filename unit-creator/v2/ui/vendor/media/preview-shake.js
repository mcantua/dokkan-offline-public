import {nativeTaskClock} from './preview-task-clock.js';
// Original implementation of the observed Eclipse ActionBankDmg shake semantics.
// Native evidence: docs/animation-shake-evidence.json. No upstream code copied.
const f32 = Math.fround;
function nativeInt(value) {
  const n = Number(value);
  return Number.isNaN(n) ? 0 : Math.max(-2147483648, Math.min(2147483647, Math.trunc(n)));
}
export function shakeOffsetFromRand(power, xRand, yRand) {
  const amplitude = nativeInt(f32(Number(power)));
  // Original ARM64 uses SCVTF to float32, a float32 2^-31 multiply, then
  // a float32 amplitude multiply. Its ActionBankDmg shake is not centered.
  const axis = value => f32(f32(f32(nativeInt(value)) * f32(1 / 2147483648)) * amplitude);
  return { x: axis(xRand), y: axis(yRand) };
}
// Native background XY offsets are centered discrete samples with linear decay.
// Its opposing offset is applied only to a clipping stencil, not the artwork.
export function backgroundShakeOffsetFromBins(powerX, powerY, elapsed, duration, xBin, yBin) {
  if (duration <= 0 || elapsed < 0 || elapsed > duration) return { x: 0, y: 0 };
  const decay = f32(1 - f32(f32(elapsed) / f32(duration)));
  const axis = (power, bin) => {
    // Original FMLA is one float32 rounding after the product+sum.
    const centered = f32(f32(0.5 + f32(-0.009999999776482582) * bin) * 2);
    return f32(0 + f32(f32(power) * centered) * decay);
  };
  return { x: axis(powerX, xBin), y: axis(powerY, yBin) };
}
export class ShakeCommands {
  constructor(runner, options = {}) {
    this.runner = runner;
    this.random = options.random || Math.random;
    this.tasks = new Map();
    this.world = null;
    this.worldStyles = new Map();
  }
  execute(cmd) {
    if (cmd.type === 'removeAllEffect') {
      for (const [wrap, task] of this.tasks) if (task.kind === 'effect') {
        this.restore(wrap, task); this.tasks.delete(wrap);
      }
      return false; // The original runner still releases its actual effects.
    }
    if (cmd.type === 'setShakeXY') {
      const args = cmd.args || [];
      this.world = { start: nativeInt(cmd.frame), duration: nativeInt(args[1]),
        powerX: f32(Number(args[2]) || 0), powerY: f32(Number(args[3]) || 0),
        sampledFrame: null, offset: null };
      return true;
    }
    if (cmd.type !== 'setEffShake' && cmd.type !== 'setShakeChara') return false;
    const args = cmd.args || [];
    const duration = nativeInt(cmd.type === 'setEffShake' ? (cmd.a ?? args[2]) : args[2]);
    // The actual native setter returns immediately for duration zero. It
    // does not cancel an earlier shake; negative duration replaces then ends.
    if (duration === 0) return true;
    const target = cmd.type === 'setEffShake'
      ? this.runner.lwf?._findByWorkId?.(cmd.workId ?? args[1])
      : this.runner.chara?.chars?.get?.(nativeInt(cmd.chara ?? args[1]));
    if (!target?.wrap?.style) return true;
    const wrap = target.wrap, previous = this.tasks.get(wrap);
    const style = wrap.style;
    this.tasks.set(wrap, {
      command:cmd, kind: cmd.type === 'setEffShake' ? 'effect' : 'character',
      start: nativeInt(cmd.frame), duration,
      power: nativeInt(f32(Number(cmd.type === 'setEffShake' ? (cmd.b ?? args[3]) : args[3]))),
      original: previous ? previous.original : style.getPropertyValue('translate'),
      priority: previous ? previous.priority : style.getPropertyPriority('translate'),
      lastValue: previous ? previous.lastValue : null,
      sampledFrame: null, offset: null, nativeCount: 0,
    });
    return true;
  }
  update(frame, context) {
    const at = nativeInt(frame), native = context?.nativeExecution === true;
    this.updateWorld(at, native);
    // Current production seeks reconstruct target-update counts in seek();
    // a phase-only estimate must not retire a still-live fast/paused task.
    if (!native && this.runner.forgeVisual) return;
    for (const [wrap, task] of this.tasks) {
      if (native && task.kind === 'character' && context.updateCharacters === false) continue;
      const elapsed = native ? task.nativeCount : at - task.start;
      if (at < task.start || elapsed > task.duration) {
        this.restore(wrap, task); this.tasks.delete(wrap); continue;
      }
      if (native || task.sampledFrame !== at) {
        const rand = () => Math.floor(this.random() * 2147483648);
        task.offset = shakeOffsetFromRand(task.power, rand(), rand());
        task.sampledFrame = at;
        if (native) task.nativeCount += 1;
      }
      // Individual translation preserves the original transform's position,
      // rotation, scale and parent-follow updates. Game Y grows upward.
      task.lastValue = `${task.offset.x}px ${-task.offset.y}px`;
      wrap.style.setProperty('translate', task.lastValue);
      task.lastValue = wrap.style.getPropertyValue('translate');
    }
  }
  updateWorld(frame, native = false) {
    const task = this.world;
    if (!task) return;
    const elapsed = frame - task.start;
    if (elapsed < 0 || task.duration <= 0 || elapsed >= task.duration) {
      for (const [wrap, state] of this.worldStyles) this.restore(wrap, state);
      this.worldStyles.clear(); this.world = null; return;
    }
    if (native || task.sampledFrame !== frame) {
      task.offset = backgroundShakeOffsetFromBins(task.powerX, task.powerY, elapsed,
        task.duration, Math.floor(this.random() * 100), Math.floor(this.random() * 100));
      task.sampledFrame = frame;
    }
    for (const layer of [this.runner.bg, this.runner.chara, this.runner.lwf, this.runner.usm]) {
      const wrap = layer?.host;
      if (!wrap?.style || this.worldStyles.has(wrap)) continue;
      this.worldStyles.set(wrap, { original: wrap.style.getPropertyValue('translate'),
        priority: wrap.style.getPropertyPriority('translate'), lastValue: null });
    }
    for (const [wrap, state] of this.worldStyles) {
      state.lastValue = `${task.offset.x}px ${-task.offset.y}px`;
      wrap.style.setProperty('translate', state.lastValue);
      state.lastValue = wrap.style.getPropertyValue('translate');
    }
  }
  seek(target) {
    for(const[wrap,task]of this.tasks){
      const clock=nativeTaskClock(this.runner,task.start,target,Math.trunc(Number(task.command.forgePhase??0))),calls=task.kind==='character'?clock.characterUpdates:clock.executingCalls;
      if(calls>task.duration+1){this.restore(wrap,task);this.tasks.delete(wrap);continue;}
      task.nativeCount=calls;
      if(calls===0){this.restore(wrap,task);continue;}
      const rand=()=>Math.floor(this.random()*2147483648);task.offset=shakeOffsetFromRand(task.power,rand(),rand());task.sampledFrame=target;
      task.lastValue=`${task.offset.x}px ${-task.offset.y}px`;wrap.style.setProperty('translate',task.lastValue);task.lastValue=wrap.style.getPropertyValue('translate');
    }
  }
  restore(wrap, task) {
    if (task.lastValue != null && wrap.style.getPropertyValue('translate') !== task.lastValue) return;
    if (task.original) wrap.style.setProperty('translate', task.original, task.priority);
    else wrap.style.removeProperty('translate');
  }
  clear() {
    for (const [wrap, task] of this.tasks) this.restore(wrap, task);
    this.tasks.clear();
    for (const [wrap, task] of this.worldStyles) this.restore(wrap, task);
    this.worldStyles.clear(); this.world = null;
  }
}
