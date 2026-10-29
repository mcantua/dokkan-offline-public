/* Trusted native plan preparation: actual owned team + source encounter, no reward authority. */
(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory(require('./battle.js'), require('./source-roster.js'), require('./stage-plan.js'), require('node:crypto').webcrypto);
  else root.OfflineDokkanRunPlanner = factory(root.OfflineDokkanBattle, root.OfflineDokkanSourceRoster, root.OfflineDokkanStagePlan, root.crypto);
})(typeof globalThis !== 'undefined' ? globalThis : this, function (Battle, Roster, Stage, crypto) {
  'use strict';
  const record = x => x && typeof x === 'object' && !Array.isArray(x);
  const integer = (x, minimum = 0, maximum = Number.MAX_SAFE_INTEGER) => Number.isSafeInteger(x) && x >= minimum && x <= maximum;
  const copy = x => JSON.parse(JSON.stringify(x));
  const stable = x => Array.isArray(x) ? '[' + x.map(stable).join(',') + ']' : record(x) ? '{' + Object.keys(x).sort().map(k => JSON.stringify(k) + ':' + stable(x[k])).join(',') + '}' : JSON.stringify(x);
  const id = x => typeof x === 'string' && /^[A-Za-z0-9_.:-]{1,127}$/.test(x);
  const fail = (code, field) => { const error = new Error(code); error.code = code; error.field = field; throw error; };
  function freeze(value) {
    if (value && typeof value === 'object' && !Object.isFrozen(value)) { for (const item of Object.values(value)) freeze(item); Object.freeze(value); }
    return value;
  }
  function safeCode(error, fallback) { return error && /^[A-Z0-9_]{1,100}$/.test(error.code) ? error.code : fallback; }
  async function sha256(value) {
    if (!crypto?.subtle) fail('RUN_PLAN_HASH_UNAVAILABLE', 'crypto');
    return Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(value))), byte => byte.toString(16).padStart(2, '0')).join('');
  }
  function definitionFor(profile, owned) {
    const types = [owned.created_definition, owned.official_upgrade, owned.tournament_definition].filter(Boolean);
    if (types.length > 1) fail('RUN_OWNED_DEFINITION_AMBIGUOUS', 'profile.cards[' + owned.instance_id + ']');
    let entries, field;
    if (owned.created_definition) {
      field = 'created_definitions'; const ref = owned.created_definition;
      entries = Array.isArray(profile[field]) ? profile[field].filter(row => record(row) && row.definition_id === ref.definition_id && row.version === ref.version) : null;
    } else if (owned.official_upgrade) {
      field = 'official_upgrades'; const ref = owned.official_upgrade;
      entries = Array.isArray(profile[field]) ? profile[field].filter(row => record(row) && row.master_id === owned.master_id && row.version === ref.version) : null;
    } else if (owned.tournament_definition) {
      // This immutable definition shape still requires translator support. Never
      // pretend the source master alone represents an exclusive owned character.
      fail('RUN_TOURNAMENT_DEFINITION_UNSUPPORTED', 'profile.tournament_definitions');
    } else return null;
    if (!Array.isArray(entries) || entries.length !== 1 || !record(entries[0].document)) fail('RUN_EFFECTIVE_DEFINITION_MISSING_OR_AMBIGUOUS', 'profile.' + field);
    return copy(entries[0].document);
  }
  async function prepareEncounter(input) {
    const unsupported = [], provenance = {format: 'offline-dokkan-prepared-encounter', version: 1}, rosterResults = [];
    let stage = null, admission = null;
    function issue(field, code, details) { unsupported.push({field, code, ...(details === undefined ? {} : {details: copy(details)})}); }
    function result(configuration = null) {
      return freeze({supported: unsupported.length === 0 && configuration !== null, configuration: unsupported.length ? null : configuration, unsupported, provenance, roster: rosterResults, stage, admission, rewards: null, requiresTrustedRunValidation: true, requiresNativeRevisionCheck: true, authorizesRunStart: false, grantsRewards: false});
    }
    try {
      const keys = ['source', 'profile', 'teamSlot', 'supporterInstanceId', 'coreStats', 'nativeStats', 'assetManifest', 'battlePolicy', 'rosterPolicy', 'encounterPolicy', 'mapId', 'battleIndex', 'roundNo', 'battleId', 'seed'];
      if (!record(input) || Object.keys(input).some(key => !keys.includes(key))) fail('RUN_PLAN_ARGUMENT_INVALID', 'arguments');
      if (!Battle || !Roster || !Stage) fail('RUN_PLAN_MODULES_REQUIRED', 'modules');
      const source = input.source, originalProfile = input.profile, statsCallback = input.coreStats, nativeStatsCallback = input.nativeStats, manifest = input.assetManifest;
      if (!record(source) || !['eclipse', 'sparking'].includes(source.provider) || !id(source.contentId) || typeof source.query !== 'function') fail('RUN_SOURCE_CONTEXT_INVALID', 'source');
      const contentId = source.contentId, provider = source.provider, query = source.query;
      const sourceHash = /(?:^|:)sha256:([a-f0-9]{64})$/.exec(contentId)?.[1];
      if (!sourceHash) fail('RUN_VERIFIED_SOURCE_HASH_REQUIRED', 'source.contentId');
      if (!record(originalProfile) || originalProfile.content_id !== contentId || !id(originalProfile.profile_id) || !integer(originalProfile.revision) || !integer(originalProfile.stamina) || !Array.isArray(originalProfile.cards) || originalProfile.cards.length > 250000 || !Array.isArray(originalProfile.teams) || originalProfile.teams.length > 20) fail('RUN_PROFILE_SNAPSHOT_INVALID', 'profile');
      if (!integer(input.teamSlot, 0, 19) || !integer(input.supporterInstanceId, 1) || !integer(input.mapId, 1) || !integer(input.battleIndex, 0, 1000) || !integer(input.roundNo, 1, 1000) || !id(input.battleId) || !integer(input.seed, 1, 4294967295)) fail('RUN_SELECTION_INVALID', 'selection');
      if (typeof statsCallback !== 'function' || typeof nativeStatsCallback !== 'function') fail('RUN_NATIVE_STATS_REQUIRED', 'coreStats/nativeStats');
      const snapshotText = JSON.stringify(originalProfile);
      if (new TextEncoder().encode(snapshotText).length > 64 * 1024 * 1024) fail('RUN_PROFILE_SNAPSHOT_TOO_LARGE', 'profile');
      // Freeze caller data before the first await; source/native callbacks remain
      // narrow captured capabilities, never deserialized page-supplied functions.
      const profile = JSON.parse(snapshotText), selection = copy({teamSlot: input.teamSlot, supporterInstanceId: input.supporterInstanceId, mapId: input.mapId, battleIndex: input.battleIndex, roundNo: input.roundNo, battleId: input.battleId, seed: input.seed, battlePolicy: input.battlePolicy, rosterPolicy: input.rosterPolicy, encounterPolicy: input.encounterPolicy});
      if (!record(selection.battlePolicy) || selection.battlePolicy.id !== Battle.sourcePolicyId || selection.rosterPolicy !== Roster.policyId) fail('RUN_EXPLICIT_POLICY_REQUIRED', 'battlePolicy/rosterPolicy');
      const manifestJSON = manifest?.json, manifestHash = manifest?.sha256, resolver = manifest?.resolve;
      const profileId = profile.profile_id, profileRevision = profile.revision;
      const pin = () => {
        if (input.source !== source || source.provider !== provider || source.contentId !== contentId || source.query !== query || input.profile !== originalProfile || originalProfile.profile_id !== profileId || originalProfile.revision !== profileRevision || originalProfile.content_id !== contentId || input.coreStats !== statsCallback || input.nativeStats !== nativeStatsCallback || input.assetManifest !== manifest || manifest?.json !== manifestJSON || manifest?.sha256 !== manifestHash || manifest?.resolve !== resolver) fail('RUN_PREPARATION_CONTEXT_CHANGED', 'source/profile/nativeCapabilities');
      };
      const owned = new Map();
      for (const card of profile.cards) {
        if (!record(card) || !integer(card.instance_id, 1) || !integer(card.master_id, 1) || owned.has(card.instance_id)) fail('RUN_OWNED_COLLECTION_INVALID', 'profile.cards');
        owned.set(card.instance_id, card);
      }
      if (profile.teams.some(team => !record(team) || !integer(team.slot, 0, 19)) || new Set(profile.teams.map(team => team.slot)).size !== profile.teams.length) fail('RUN_TEAM_COLLECTION_INVALID', 'profile.teams');
      const teams = profile.teams.filter(team => record(team) && team.slot === selection.teamSlot);
      if (teams.length !== 1 || !Array.isArray(teams[0].members) || teams[0].members.length !== 6 || teams[0].members.some(member => !integer(member, 1)) || new Set(teams[0].members).size !== 6) fail('RUN_ACTUAL_SIX_UNIT_TEAM_REQUIRED', 'profile.teams');
      const members = teams[0].members.slice();
      if (members.includes(selection.supporterInstanceId)) fail('RUN_SUPPORTER_MUST_BE_DISTINCT', 'supporterInstanceId');
      const instances = members.concat(selection.supporterInstanceId);
      if (instances.some(instance => !owned.has(instance))) fail('RUN_CHARACTER_NOT_OWNED', 'profile.teams/supporterInstanceId');
      const bindings = instances.map(instance => ({owned: copy(owned.get(instance)), definition: definitionFor(profile, owned.get(instance))}));
      provenance.provider = provider; provenance.contentId = contentId; provenance.sourceMasterSha256 = sourceHash;
      provenance.profileId = profileId; provenance.profileRevision = profileRevision; provenance.teamSlot = selection.teamSlot;
      provenance.team = members; provenance.supporterInstanceId = selection.supporterInstanceId;
      provenance.leaderInstanceIds = [members[0], selection.supporterInstanceId];
      provenance.snapshotSha256 = await sha256(stable(profile)); pin();
      const callbackProofs = [];
      for (const binding of bindings) {
        const request = {contentId, profileId, profileRevision, instanceId: binding.owned.instance_id};
        let response;
        try { pin(); response = await statsCallback(freeze(copy(request))); pin(); }
        catch (error) { if (error.code === 'RUN_PREPARATION_CONTEXT_CHANGED') throw error; issue('coreStats[' + binding.owned.instance_id + ']', safeCode(error, 'RUN_CORE_STATS_UNAVAILABLE')); continue; }
        // A native callback may explicitly attest its serialized revision. Raw
        // card.stats output is also accepted, but still requires native revision
        // validation before run start; this preparer is not a save authority.
        if (record(response) && Object.prototype.hasOwnProperty.call(response, 'stats')) {
          if (response.contentId !== contentId || response.profileId !== profileId || response.profileRevision !== profileRevision || response.instanceId !== binding.owned.instance_id || !record(response.stats)) { issue('coreStats[' + binding.owned.instance_id + ']', 'RUN_CORE_STATS_REVISION_BINDING_INVALID'); continue; }
          binding.stats = copy(response.stats); callbackProofs.push({instanceId: binding.owned.instance_id, nativeRevisionAttested: true});
        } else {
          if (!record(response)) { issue('coreStats[' + binding.owned.instance_id + ']', 'RUN_CORE_STATS_REPLY_INVALID'); continue; }
          binding.stats = copy(response); callbackProofs.push({instanceId: binding.owned.instance_id, nativeRevisionAttested: false});
        }
      }
      provenance.coreStatsBindings = callbackProofs;
      if (unsupported.length) return result();
      const leaders = [bindings[0], bindings[6]];
      for (const binding of bindings) {
        let normalized;
        try {
          pin(); normalized = await Roster.normalizeOwnedCard({...binding, contentId, source, policy: selection.rosterPolicy, battlePolicy: selection.battlePolicy, leaders}); pin();
        } catch (error) { if (error.code === 'RUN_PREPARATION_CONTEXT_CHANGED') throw error; issue('roster[' + binding.owned.instance_id + ']', safeCode(error, 'RUN_ROSTER_TRANSLATION_FAILED')); continue; }
        rosterResults.push({instanceId: binding.owned.instance_id, supported: normalized.supported, provenance: normalized.provenance});
        if (!normalized.supported || !normalized.fighter) {
          for (const gap of normalized.unsupported) issue('roster[' + binding.owned.instance_id + '].' + gap.field, gap.code, gap.value);
        } else binding.fighter = copy(normalized.fighter);
      }
      const wrappedSource = {provider, contentId, query: async (sql, params) => { pin(); const rows = await query(sql, params); pin(); return rows; }};
      const wrappedManifest = {json: manifestJSON, sha256: manifestHash, resolve: typeof resolver === 'function' ? async ref => { pin(); const verified = await resolver(ref); pin(); return verified; } : undefined};
      try {
        pin(); stage = await Stage.planEncounter({source: wrappedSource, mapId: selection.mapId, battleIndex: selection.battleIndex, roundNo: selection.roundNo, assetManifest: wrappedManifest, authoredPolicy: selection.encounterPolicy, nativeStats: async request => { pin(); const stats = await nativeStatsCallback(freeze(copy(request))); pin(); return stats; }}); pin();
      } catch (error) { if (error.code === 'RUN_PREPARATION_CONTEXT_CHANGED') throw error; issue('stage', safeCode(error, 'RUN_STAGE_PREPARATION_FAILED')); }
      if (stage) {
        for (const gap of stage.unsupported) issue('stage.' + gap.field, gap.code, gap.details);
        if (stage.provenance.requiredBattlePolicy && stage.provenance.requiredBattlePolicy !== selection.battlePolicy.id) issue('battlePolicy.id', 'RUN_STAGE_BATTLE_POLICY_MISMATCH');
        const map = stage.facts.map;
        if (map) admission = {state: 'requires-native-validation', actCost: map.act, sourceEventKeyCount: map.eventkagi_num, snapshotStamina: profile.stamina, actAffordable: integer(map.act) ? profile.stamina >= map.act : null, previousQuestId: stage.facts.quest?.prev_quest_id ?? null, reasons: []};
        if (admission) {
          if (admission.actAffordable === false) admission.reasons.push({code: 'INSUFFICIENT_STAMINA', field: 'profile.stamina'});
          if (admission.sourceEventKeyCount > 0) admission.reasons.push({code: 'EVENT_KEY_BINDING_REQUIRES_NATIVE_VALIDATION', field: 'stage.map.eventkagi_num'});
          // A snapshot does not expose the core's authoritative quest-progress
          // table. Neither zero nor nonzero prerequisites imply admission here.
          admission.reasons.push({code: 'RUN_UNLOCK_COST_REWARD_VALIDATION_REQUIRED', field: 'nativeRunCoordinator'});
        }
      }
      if (unsupported.length || !stage?.supported || !stage.enemy || bindings.some(binding => !binding.fighter)) {
        if (!unsupported.length) issue('configuration', 'RUN_CONFIGURATION_INCOMPLETE');
        return result();
      }
      const configuration = {battleId: selection.battleId, contentId, policy: selection.battlePolicy, roster: bindings.map(binding => binding.fighter), enemy: copy(stage.enemy), seed: selection.seed};
      try { Battle.create(configuration); }
      catch (error) { issue('configuration', safeCode(error, 'RUN_BATTLE_CONFIGURATION_UNSUPPORTED')); return result(); }
      provenance.mapId = selection.mapId; provenance.battleIndex = selection.battleIndex; provenance.roundNo = selection.roundNo;
      provenance.configurationSha256 = await sha256(stable(configuration)); pin();
      provenance.rosterSha256 = await sha256(stable(bindings.map(binding => ({owned: binding.owned, stats: binding.stats, definition: binding.definition})))); pin();
      provenance.stage = copy(stage.provenance); provenance.originalGameParityVerified = false;
      return result(configuration);
    } catch (error) {
      issue(error.field || 'preparation', safeCode(error, 'RUN_PREPARATION_FAILED'));
      return result();
    }
  }
  return Object.freeze({prepareEncounter});
});
