/* Original adapter, MIT. Native evidence: tests/fixtures/native-preview-phase.json.
 * Every endPhase invocation is frame-zero phase metadata. Later callbacks
 * overwrite its bound. No endPhase is an executable timeline command.
 */
const preparedArrays = new WeakMap();
export function prepareNativePhaseEnds(runner) {
  const commands = runner?.commands;
  if (!Array.isArray(commands)) return;
  const selected = new Map(), ends = [];
  for (let index = 0; index < commands.length; index++) {
    const command = commands[index];
    if (command?.type !== 'endPhase') continue;
    const phase = Number.isInteger(command.forgePhase) ? command.forgePhase : 0;
    if (!Number.isSafeInteger(command.forgeOrder) || command.forgeOrder < 0) command.forgeOrder = index;
    const candidate = {command, phase, order: command.forgeOrder, index};
    const prior = selected.get(phase);
    if (!prior || candidate.order > prior.order || (candidate.order === prior.order && candidate.index > prior.index)) selected.set(phase, candidate);
    ends.push(candidate);
  }
  // The same prepared array can be sorted/prepared repeatedly. A different
  // array must never inherit a previous scene's duration by accident.
  const previous = preparedArrays.get(commands);
  if (!ends.length && previous) {runner.forgePhaseEnds = previous; return previous;}
  const evidence = candidate => ({phase:candidate.phase, order:candidate.order, frame:candidate.command.frame});
  const discarded = ends.filter(candidate => selected.get(candidate.phase) !== candidate);
  if (ends.length) {
    const remove = new Set(ends.map(candidate => candidate.command));
    let write = 0;
    for (const command of commands) if (!remove.has(command)) commands[write++] = command;
    commands.length = write;
  }
  const metadata = {
    semantics:'last-native-invocation-per-phase-metadata-only',
    selected:[...selected.values()].map(evidence),
    discarded:discarded.map(evidence)
  };
  preparedArrays.set(commands, metadata);runner.forgePhaseEnds = metadata;
  if (!(nativePhaseDuration(runner) > 0)) runner.log?.('This scene has no single verified native ending; its viewing range is a preview estimate.');
  return metadata;
}
export function nativePhaseDuration(runner) {
  const selected = runner?.forgePhaseEnds?.selected;
  // Native multi-phase orchestration requires its own actual engine context.
  // This scalar is deliberately limited to one known phase.
  if (!Array.isArray(selected) || selected.length !== 1 || !Number.isSafeInteger(selected[0].phase) || selected[0].phase < 0) return null;
  const duration = Number(selected[0].frame);
  return Number.isSafeInteger(duration) && duration >= 0 ? duration : null;
}
