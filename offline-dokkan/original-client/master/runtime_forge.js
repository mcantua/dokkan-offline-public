/* Trusted native/cloud compiler. The real Creator performs materialization. */
(function(root,factory) {
  if (typeof module === 'object' && module.exports) {
    const api=factory(require('../../../unit-creator/v2/ui/core.js'));
    module.exports=api;
    if (require.main === module) {
      try { process.stdout.write(JSON.stringify(api.compile(JSON.parse(require('fs').readFileSync(0,'utf8'))))); }
      catch (_) { process.stderr.write('RUNTIME_FORGE_REJECTED\n'); process.exitCode=1; }
    }
  } else root.ODRuntimeForge=factory(root.Forge);
})(typeof globalThis!=='undefined'?globalThis:this,function(Forge) {
  'use strict';
  function compile(input) {
try {
  const project = Forge.clone(input.project);
  const members = [project, ...(project.formProjects || [])];
  if (members.length !== input.runtimeIds.length) throw Error('RUNTIME_MEMBER_COUNT');
  const changed = new Map(members.map((p, i) => [Number(p.targetId), input.runtimeIds[i]]));
  // Current strict Finish admits a single card. Multi-form admission must supply
  // an accepted immutable full bundle before this compiler can accept forms.
  if (members.length !== 1) throw Error('RUNTIME_FULL_BUNDLE_ADMISSION_REQUIRED');
  if ((project.movieBindings || []).length || (project.assets || []).length ||
      (project.generatedFiles || []).length || (project.packedAssets || []).length || project.sourceDependencies ||
      Object.keys(project.animationAssignments || {}).length || project.actionHooks)
    throw Error('RUNTIME_RESOURCE_ADMISSION_REQUIRED');
  for (const member of members) member.targetId = changed.get(Number(member.targetId));
  const check = Forge.validate(project);
  if (check.errors.length) throw Error('RUNTIME_FORGE_VALIDATION_FAILED');
  const tables = Forge.materializeAll(project);
  const next = Forge.nextUnitId(input.reservations, 'runtime-next', input.floor);
  return {tables, runtimeIds: input.runtimeIds,
    next, foreign: Forge.foreign, warnings: check.warnings.length};
} catch (_) { throw Error('RUNTIME_FORGE_REJECTED'); }
  }
  return Object.freeze({compile});
});
