/* Original Forge controller-clock adapter, MIT.
 * Native ordering/bounds: native-preview-phase-end-order.py.
 * Normal/fast controller calls advance one/two logical frames per Exec; both
 * modes execute twice per nominal 30fps stage update. Phase metadata is a
 * count, checked after queues, camera, character and effect updates.
 */
import { nativePhaseDuration } from './preview-phase.js';
export function finishNativePreview(runner) {
  // The last native update is still a real video frame. Wait for the existing
  // recorder's acknowledgement before onDone can release its scene or mux it.
  if (typeof runner.onRecordFrame === 'function') runner._forgeFinishAfterRecord = true;
  else runner._finish();
}
export function advanceNativePreview(runner, budget = 1) {
  const count = Number(budget);
  if (!Number.isSafeInteger(count) || count < 0 || count > 10000) throw Error('Invalid preview update budget.');
  const stride = runner.highSpeed ? 2 : 1;
  const duration = nativePhaseDuration(runner);
  for (let spent = 0; spent < count; spent += stride) {
    if (runner._usmStartGate || runner._forgeFinishAfterRecord) return;
    if (runner.frame > runner.maxFrame) { finishNativePreview(runner); return; }
    const visual = runner.forgeVisual;
    if (visual?.beforeGlobalStep) {
      if (visual.beforeGlobalStep(runner.frame, stride)?.execute === false) {
        if (duration > 0 && runner.frame + 1 >= duration) { finishNativePreview(runner); return; }
        continue;
      }
    } else if (runner.pauseRemain > 0) {
      // Compatibility fallback for callers without the private visual adapter.
      runner.pauseRemain -= stride;
      if (runner.pauseRemain > 0) continue;
    }
    runner._fireAt(runner.frame);
    if (!runner.playing || runner._usmStartGate) return;
    const sampledFrame = runner.frame;
    const gate = {...(visual?.beforeCharacterStep(sampledFrame, stride) || {updateCharacters:true, advancePhaseClock:true}), nativeExecution:true, executionStride:stride};
    if (gate.updateCharacters !== false) {
      runner.chara?.evalAllAtFrame?.(sampledFrame);
      // Character LWF progress has its own native scheduled layer. Sampling a
      // pose must not invent an extra LWF time update before native afterimage
      // capture. Keep the hosted layer's existing outer scheduler separately.
      if (visual?.needsRenderedPose) runner.chara?.renderOnly?.();
      visual?.afterPose?.(sampledFrame, stride);
    }
    visual?.update(sampledFrame, gate);
    runner.lwf?.syncFollowParents?.(runner.chara);
    if (!runner.playing || runner._usmStartGate) return;
    // Native end checks run even when a character-only gate holds phase time.
    // Zero-duration entries are skipped by the earlier native phase-table scan.
    if (duration > 0 && sampledFrame + 1 >= duration) { finishNativePreview(runner); return; }
    if (gate.advancePhaseClock !== false) runner.frame += stride;
    if (!(duration > 0) && runner.frame > runner.maxFrame) { finishNativePreview(runner); return; }
  }
}
