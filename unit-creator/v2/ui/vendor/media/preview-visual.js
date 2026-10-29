/* Forge's original visual-command lifecycle coordinator. MIT.
 * Plugins implement only source-backed commands; native gameplay/UI commands
 * remain distinct. Returning false preserves the original runner dispatch. */
import { ShakeCommands } from './preview-shake.js';
import { CompositorCommands } from './preview-compositor.js';
import { SceneUICommands } from './preview-scene-ui.js';
import { PositionCommands } from './preview-position.js';
import { FlashCommands } from './preview-flash.js';
import { CameraCommands } from './preview-camera.js';
import { WipeCommands } from './preview-wipe.js';
import { BgmCommands } from './preview-bgm.js';
import { BandpassCommands } from './preview-bandpass.js';
import { MovieAudioCommands } from './preview-movie-audio.js';
import { FlipCommands } from './preview-flip.js';
import { AfterimageCommands } from './preview-afterimage.js';
import { CharacterAlphaCommands } from './preview-character-alpha.js';
import { CharacterPauseCommands } from './preview-character-pause.js';
import { GlobalPauseCommands } from './preview-global-pause.js';
import { KakimojiCommands } from './preview-kakimoji.js';
import { EffectTracksCommands } from './preview-effect-tracks.js';

export class VisualCommands {
  constructor(runner, { plugins } = {}) {
    this.runner = runner;
    const flip = plugins ? null : new FlipCommands(runner);
    this.plugins = plugins || [new GlobalPauseCommands(runner), new EffectTracksCommands(runner, {initialSide:()=>flip.initialSide}), new ShakeCommands(runner), new CharacterAlphaCommands(runner), new CompositorCommands(runner), new SceneUICommands(runner), new PositionCommands(runner), flip, new CameraCommands(runner), new CharacterPauseCommands(runner), new AfterimageCommands(runner), new KakimojiCommands(runner), new FlashCommands(runner), new WipeCommands(runner), new BandpassCommands(runner), new MovieAudioCommands(runner), new BgmCommands(runner)];
    this.commands = [];
    this.frame = 0;
  }
  async preload(commands = this.runner.commands) {
    const planned = Array.isArray(commands) ? commands : [];
    await Promise.all(this.plugins.map(plugin => plugin.preload?.(planned)));
    // Auxiliary layers may create their LWF instances asynchronously. Inspect
    // those owned targets only after every layer has finished loading.
    await Promise.all(this.plugins.map(plugin => plugin.afterPreload?.(planned)));
  }
  characterCommands(commands = this.runner.commands) {
    return this.plugins.reduce((result, plugin) => plugin.characterCommands?.(result) ?? result, commands);
  }
  compositorTargets() {
    return this.plugins.flatMap(plugin => plugin.compositorTargets?.() || []);
  }
  effectCommand(command) {
    return this.plugins.reduce((result, plugin) => plugin.effectCommand?.(result) ?? result, command);
  }
  effectCommands(commands = this.runner.commands) {
    return this.plugins.reduce((result, plugin) => plugin.effectCommands?.(result) ?? result, commands);
  }
  prepare(commands = this.runner.commands) {
    this.clear({preservePreloadedAssets:true});
    this.commands = Array.isArray(commands) ? commands : [];
    for (const plugin of this.plugins) plugin.prepare?.(this.commands);
    const phases = new Set(this.commands.map(command => command.forgePhase ?? command.phase ?? 0));
    if (phases.size > 1) this.runner.log?.('This preview has not reconstructed transitions between multiple battle phases.');
    if (this.plugins.some(plugin => plugin instanceof AfterimageCommands && plugin.active)) this.runner.log?.('This preview has not reconstructed the original game timing for character afterimages.');
  }
  execute(command) {
    let handled = false;
    // Every plugin sees cleanup notifications, even if another owns a command.
    for (const plugin of this.plugins) {
      if (plugin.execute?.(command) === true) handled = true;
    }
    return handled;
  }
  beforeGlobalStep(frame, stride = 1) {
    let result = {execute:true};
    for (const plugin of this.plugins) {
      const gate = plugin.beforeGlobalStep?.(frame, stride);
      if (gate) result = {...result,...gate,execute:result.execute && gate.execute !== false};
    }
    return result;
  }
  get usesNativeCharacterClock() { return false; }
  get needsRenderedPose() { return this.plugins.some(plugin => plugin instanceof AfterimageCommands && plugin.active); }
  beforeCharacterStep(frame, stride = 1) {
    const context = {updateCharacters:true, advancePhaseClock:true};
    for (const plugin of this.plugins) {
      const gate = plugin.beforeCharacterStep?.(frame, stride);
      if (gate?.updateCharacters === false) context.updateCharacters = false;
      if (gate?.advancePhaseClock === false) context.advancePhaseClock = false;
    }
    return context;
  }
  afterPose(frame, stride) {
    for (const plugin of this.plugins) plugin.afterPose?.(frame, stride);
  }
  tick(seconds) {
    if (!Number.isFinite(seconds) || seconds < 0) throw Error('Invalid visual preview elapsed time.');
    for (const plugin of this.plugins) plugin.tick?.(seconds);
  }
  update(frame, context) {
    if (!Number.isFinite(Number(frame))) throw Error('Invalid visual preview frame.');
    this.frame = Math.max(0, Number(frame));
    for (const plugin of this.plugins) plugin.update?.(this.frame, context);
  }
  render() {
    // The public runner increments runner.frame after sampling character keys.
    // Use that sampled logical frame, not its following-frame counter.
    for (const plugin of this.plugins) plugin.render?.(this.frame);
  }
  seek(frame) {
    const value = Number(frame);
    if (!Number.isFinite(value)) throw Error('Invalid visual preview seek.');
    const target = Math.max(0, value);
    this.prepare(this.runner.commands);
    const previousSeeking = this.runner._forgeVisualSeeking;
    this.runner._forgeVisualSeeking = true;
    try {
      for (const command of this.commands) {
        const at = Number(command?.frame ?? 0);
        if (Number.isFinite(at) && at <= target) this.execute(command);
      }
      this.update(target);
      this.render();
    } finally {
      if (previousSeeking === undefined) delete this.runner._forgeVisualSeeking;
      else this.runner._forgeVisualSeeking = previousSeeking;
    }
    for (const plugin of this.plugins) {
      const clock = plugin.seek?.(target);
      if (clock && Number.isSafeInteger(clock.nextFrame) && Number.isSafeInteger(clock.elapsedExecutions)) this.seekClock = clock;
    }
    this.resumeClock = this.seekClock;
  }
  resume() {
    if (this.resumeClock) {
      this.runner.frame = this.resumeClock.nextFrame;
      this.resumeClock = null;
    }
    for (const plugin of this.plugins) plugin.resume?.();
  }
  clear(options) {
    for (const plugin of this.plugins) plugin.clear?.(options);
    this.frame = 0;
    this.commands = [];
    this.seekClock = null;
    this.resumeClock = null;
    this.runner._forgeFinishAfterRecord = false;
  }
}
