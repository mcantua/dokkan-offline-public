/* Read-only source encounter planner; source facts and authored balance stay distinct. */
(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory(require('node:crypto').webcrypto);
  else root.OfflineDokkanStagePlan = factory(root.crypto);
})(typeof globalThis !== 'undefined' ? globalThis : this, function (crypto) {
  'use strict';
  const record = x => x && typeof x === 'object' && !Array.isArray(x);
  const safe = (x, low = 0, high = Number.MAX_SAFE_INTEGER) => Number.isSafeInteger(x) && x >= low && x <= high;
  const clone = x => JSON.parse(JSON.stringify(x));
  const stable = x => Array.isArray(x) ? '[' + x.map(stable).join(',') + ']' : record(x) ? '{' + Object.keys(x).sort().map(k => JSON.stringify(k) + ':' + stable(x[k])).join(',') + '}' : JSON.stringify(x);
  const fail = code => { const error = new Error(code); error.code = code; throw error; };
  async function digest(text) {
    if (!crypto || !crypto.subtle) fail('STAGE_HASH_UNAVAILABLE');
    return Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text))), v => v.toString(16).padStart(2, '0')).join('');
  }
  function exact(value, keys, code) { if (!record(value) || Object.keys(value).some(k => !keys.includes(k))) fail(code); }
  function parse(text, limit, code) {
    if (typeof text !== 'string' || new TextEncoder().encode(text).length > limit) fail(code);
    let value; try { value = JSON.parse(text); } catch { fail(code); }
    // JSON.parse otherwise accepts duplicate object keys. A small token walk
    // rejects ambiguity while JSON.parse remains the syntax authority.
    const tokens = text.match(/"(?:[^"\\]|\\[\s\S])*"|-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?|true|false|null|[{}\[\],:]/g) || [], stack = [];
    for (const token of tokens) {
      if (token === '{') stack.push({kind: 'object', keys: new Set(), key: true});
      else if (token === '[') stack.push({kind: 'array'});
      else if (token === '}' || token === ']') stack.pop();
      else if (token === ',' && stack.length && stack[stack.length - 1].kind === 'object') stack[stack.length - 1].key = true;
      else if (token === ':') { if (stack.length) stack[stack.length - 1].key = false; }
      else if (token[0] === '"' && stack.length) {
        const top = stack[stack.length - 1];
        if (top.kind === 'object' && top.key) {
          const key = JSON.parse(token); if (top.keys.has(key) || ['__proto__', 'constructor', 'prototype'].includes(key)) fail(code);
          top.keys.add(key); top.key = false;
        }
      }
    }
    return value;
  }
  function authored(input) {
    if (input === undefined || input === null) return null;
    exact(input, ['id', 'version', 'level', 'hpScalePpm', 'atkScalePpm', 'defScalePpm', 'hpBudget', 'attacks', 'kiBoardPolicy', 'classPolicy', 'presentation'], 'STAGE_AUTHORED_POLICY_INVALID');
    if (input.id !== 'offline-static-encounter-v1' || input.version !== 1 || !safe(input.level, 1, 10000) || input.kiBoardPolicy !== 'uniform-six-v1' || input.classPolicy !== 'preserve-source-class-v1' || !['verified-source-assets-v1', 'authored-minimal-v1'].includes(input.presentation)) fail('STAGE_AUTHORED_POLICY_INVALID');
    for (const k of ['hpScalePpm', 'atkScalePpm', 'defScalePpm']) if (!safe(input[k], 1, 10000000)) fail('STAGE_AUTHORED_POLICY_INVALID');
    if (input.hpBudget !== undefined && !safe(input.hpBudget, 1, 2147483647)) fail('STAGE_AUTHORED_POLICY_INVALID');
    if (!Array.isArray(input.attacks) || input.attacks.length < 1 || input.attacks.length > 20) fail('STAGE_AUTHORED_POLICY_INVALID');
    for (const attack of input.attacks) { exact(attack, ['slot', 'multiplierPpm'], 'STAGE_AUTHORED_POLICY_INVALID'); if (!safe(attack.slot, 0, 3) || !safe(attack.multiplierPpm, 1, 30000000)) fail('STAGE_AUTHORED_POLICY_INVALID'); }
    return clone(input);
  }
  function scale(value, ppm) {
    if (!safe(value, 0, 2147483647)) fail('STAGE_NATIVE_STATS_INVALID');
    const result = BigInt(value) * BigInt(ppm) / BigInt(1000000);
    if (result > BigInt(2147483647)) fail('STAGE_SCALED_STATS_OVERFLOW');
    return Number(result);
  }
  async function planEncounter(input) {
    exact(input, ['source', 'mapId', 'battleIndex', 'roundNo', 'assetManifest', 'authoredPolicy', 'nativeStats'], 'STAGE_ARGUMENT_INVALID');
    const source = input.source, contentId = source && source.contentId, query = source && source.query;
    if (!source || !['eclipse', 'sparking'].includes(source.provider) || typeof contentId !== 'string' || !/^[A-Za-z0-9_.:-]{1,127}$/.test(contentId) || typeof query !== 'function' || !safe(input.mapId, 1) || !safe(input.battleIndex, 0, 1000) || !safe(input.roundNo, 1, 1000)) fail('STAGE_ARGUMENT_INVALID');
    const own = authored(input.authoredPolicy), gaps = [], facts = {}, provenance = {provider: source.provider, contentId, mapId: input.mapId, battleIndex: input.battleIndex, roundNo: input.roundNo, sourceEncounterStatsPresent: false, originalEnemyAIResolved: false, originalGameParityVerified: false};
    const gap = (code, field, details) => gaps.push({code, field, ...(details === undefined ? {} : {details})});
    const pin = () => { if (source.contentId !== contentId || source.query !== query || source.provider !== provenance.provider) fail('STAGE_CONTENT_CHANGED'); };
    async function rows(sql, params) { pin(); const result = await query(sql, params); pin(); if (!Array.isArray(result) || result.some(r => !record(r))) fail('STAGE_SOURCE_RESULT_INVALID'); return result; }
    async function one(sql, params, field) { const found = await rows(sql, params); if (found.length !== 1) { gap('STAGE_SOURCE_REFERENCE_MISSING', field); return null; } return found[0]; }
    function result(enemy) { pin(); return {supported: gaps.length === 0 && !!enemy, enemy: gaps.length ? null : enemy || null, unsupported: gaps, facts, provenance, rewards: null, requiresTrustedRunValidation: true}; }
    facts.map = await one('SELECT id,quest_id,difficulty,battle_background_id,sugoroku_bgm_id,battle_bgm_id,boss_bgm_id,act,eventkagi_num,start_script_id,finish_script_id,sugoroku_map_puzzle_color_id FROM sugoroku_maps WHERE id=?', [input.mapId], 'map');
    if (!facts.map) return result();
    facts.quest = await one('SELECT id,area_id,name,prev_quest_id FROM quests WHERE id=?', [facts.map.quest_id], 'quest');
    if (facts.quest) facts.area = await one('SELECT id,name,type,category,prev_area_id FROM areas WHERE id=?', [facts.quest.area_id], 'area');
    if (!safe(facts.map.act) || !safe(facts.map.eventkagi_num)) gap('STAGE_ENTRY_COST_INVALID', 'map.act/eventkagi_num');
    if (facts.map.start_script_id !== 0 || facts.map.finish_script_id !== 0) gap('STAGE_SCRIPT_RUNTIME_UNSUPPORTED', 'map.start_script_id/finish_script_id');
    const information = await one('SELECT enemy_info FROM sugoroku_map_enemy_informations WHERE sugoroku_map_id=?', [input.mapId], 'enemyInformation');
    if (!information) return result();
    provenance.enemyInformationSha256 = await digest(information.enemy_info);
    let decoded;
    try { decoded = parse(information.enemy_info, 4 * 1024 * 1024, 'STAGE_ENEMY_INFORMATION_INVALID'); }
    catch (error) { gap(error.code || 'STAGE_ENEMY_INFORMATION_INVALID', 'enemyInformation'); return result(); }
    if (!record(decoded) || Object.keys(decoded).some(k => !['display_type', 'battles'].includes(k)) || !Array.isArray(decoded.battles)) { gap('STAGE_ENEMY_INFORMATION_UNSUPPORTED', 'enemyInformation'); return result(); }
    const selected = decoded.battles[input.battleIndex];
    if (!record(selected) || Object.keys(selected).some(k => k !== 'rounds') || !Array.isArray(selected.rounds)) { gap('STAGE_BATTLE_MISSING', 'enemyInformation.battles'); return result(); }
    const rounds = selected.rounds.filter(r => record(r) && r.round_no === input.roundNo);
    if (rounds.length !== 1) { gap('STAGE_ROUND_MISSING_OR_AMBIGUOUS', 'enemyInformation.rounds'); return result(); }
    const round = rounds[0]; facts.round = clone(round);
    if (Object.keys(round).some(k => !['round_id', 'round_no', 'comment', 'enemies'].includes(k)) || !Array.isArray(round.enemies) || !round.enemies.length || round.enemies.length > 20) { gap('STAGE_ROUND_UNSUPPORTED', 'round'); return result(); }
    if (round.enemies.length !== 1) gap('STAGE_MULTIPLE_ENEMIES_UNSUPPORTED', 'round.enemies', {count: round.enemies.length});
    facts.enemies = [];
    for (let i = 0; i < round.enemies.length; i++) {
      const entry = round.enemies[i], path = 'round.enemies[' + i + ']';
      if (!record(entry) || Object.keys(entry).some(k => !['card_id', 'enemy_skill_ids', 'enemy_round_skill_set_id'].includes(k)) || !safe(entry.card_id, 1) || !Array.isArray(entry.enemy_skill_ids) || entry.enemy_skill_ids.length > 128 || entry.enemy_skill_ids.some(k => !safe(k, 1)) || new Set(entry.enemy_skill_ids).size !== entry.enemy_skill_ids.length || entry.enemy_round_skill_set_id !== null && !safe(entry.enemy_round_skill_set_id, 1)) { gap('STAGE_ENEMY_REFERENCE_INVALID', path); continue; }
      const card = await one('SELECT id,name,element,lv_max,grow_type,hp_init,hp_max,atk_init,atk_max,def_init,def_max,character_id,resource_id FROM cards WHERE id=?', [entry.card_id], path + '.card');
      const resolved = {card, sourceSkillIds: entry.enemy_skill_ids.slice(), sourceRoundSkillSetId: entry.enemy_round_skill_set_id, skills: [], roundSkills: []}; facts.enemies.push(resolved);
      if (entry.enemy_skill_ids.length) {
        resolved.skills = await rows('SELECT id,exec_timing_type,calc_option,turn,is_once,probability,causality_conditions,target_type,efficacy_type,eff_value1,eff_value2,eff_value3 FROM enemy_skills WHERE id IN (' + entry.enemy_skill_ids.map(() => '?').join(',') + ') ORDER BY id', entry.enemy_skill_ids);
        gap('STAGE_ENEMY_SKILL_RUNTIME_UNSUPPORTED', path + '.enemy_skill_ids', {ids: entry.enemy_skill_ids});
        if (resolved.skills.length !== entry.enemy_skill_ids.length) gap('STAGE_ENEMY_SKILL_REFERENCE_MISSING', path + '.enemy_skill_ids');
      }
      if (entry.enemy_round_skill_set_id !== null) {
        resolved.roundSkills = await rows('SELECT s.id,s.exec_timing_type,s.calc_option,s.turn,s.probability,s.causality_conditions,s.efficacy_type,s.eff_value1,s.eff_value2,s.eff_value3 FROM enemy_round_skill_set_relations r JOIN enemy_round_skills s ON s.id=r.enemy_round_skill_id WHERE r.enemy_round_skill_set_id=? ORDER BY r.id', [entry.enemy_round_skill_set_id]);
        gap('STAGE_ROUND_SKILL_RUNTIME_UNSUPPORTED', path + '.enemy_round_skill_set_id', {id: entry.enemy_round_skill_set_id});
      }
      if (card && (card.id !== entry.card_id || typeof card.name !== 'string' || !card.name.trim() || card.name.length > 160 || !safe(card.lv_max, 1, 10000))) gap('STAGE_SOURCE_CARD_INVALID', path + '.card');
      if (card && (!safe(card.element, 0, 24) || ![0, 1, 2, 3, 4, 10, 11, 12, 13, 14, 20, 21, 22, 23, 24].includes(card.element))) gap('STAGE_SOURCE_TYPE_INVALID', path + '.card.element');
    }
    if (safe(facts.map.sugoroku_map_puzzle_color_id, 1)) facts.puzzleColors = await one('SELECT id,weight_blue,weight_green,weight_purple,weight_red,weight_yellow,weight_rainbow FROM sugoroku_map_puzzle_colors WHERE id=?', [facts.map.sugoroku_map_puzzle_color_id], 'puzzleColors');
    const ai = await rows('SELECT count(*) AS row_count FROM enemy_ai_conditions', []); facts.aiCatalogRows = ai.length === 1 ? ai[0].row_count : null;
    // Neither supplied snapshot binds these AI rows or encounter stats to the
    // enemy records. Do not substitute collectible maxima and call them boss stats.
    if (!own) {
      gap('STAGE_ENCOUNTER_STATS_POLICY_REQUIRED', 'authoredPolicy');
      gap('STAGE_ENEMY_AI_BINDING_UNAVAILABLE', 'enemyInformation');
      gap('STAGE_KI_BOARD_POLICY_REQUIRED', 'authoredPolicy.kiBoardPolicy');
    } else {
      provenance.authoredPolicy = own; provenance.authoredPolicySha256 = await digest(stable(own));
      provenance.enemyBalanceOrigin = 'native-source-card-stats-with-explicit-authored-scales';
      provenance.enemyAttackOrigin = 'explicit-authored-static-slots';
      provenance.requiredBattlePolicy = 'offline-turn-battle-source-v2';
    }
    const manifest = input.assetManifest;
    if (!manifest || typeof manifest.json !== 'string' || !/^[a-f0-9]{64}$/.test(manifest.sha256) || typeof manifest.resolve !== 'function') gap('STAGE_VERIFIED_DEPENDENCIES_REQUIRED', 'assetManifest');
    else {
      let parsed;
      try {
        if (await digest(manifest.json) !== manifest.sha256) fail('STAGE_MANIFEST_HASH_MISMATCH');
        parsed = parse(manifest.json, 4 * 1024 * 1024, 'STAGE_MANIFEST_INVALID');
        exact(parsed, ['format', 'version', 'contentId', 'encounters'], 'STAGE_MANIFEST_INVALID');
        if (parsed.format !== 'offline-dokkan-stage-dependencies' || parsed.version !== 1 || parsed.contentId !== contentId || !Array.isArray(parsed.encounters) || parsed.encounters.length > 10000) fail('STAGE_MANIFEST_INVALID');
        const matches = parsed.encounters.filter(r => record(r) && r.mapId === input.mapId && r.battleIndex === input.battleIndex && r.roundNo === input.roundNo);
        if (matches.length !== 1) fail('STAGE_DEPENDENCY_LIST_MISSING_OR_AMBIGUOUS');
        const match = matches[0]; exact(match, ['mapId', 'battleIndex', 'roundNo', 'presentation', 'dependencies'], 'STAGE_MANIFEST_INVALID');
        if (!Array.isArray(match.dependencies) || !match.dependencies.length || match.dependencies.length > 4096 || !own || match.presentation !== own.presentation) fail('STAGE_DEPENDENCY_LIST_INCOMPLETE');
        const paths = new Set(); facts.verifiedAssets = [];
        for (const ref of match.dependencies) {
          exact(ref, ['path', 'size', 'sha256'], 'STAGE_ASSET_REFERENCE_INVALID');
          if (typeof ref.path !== 'string' || ref.path.length > 500 || !/^[A-Za-z0-9_./-]+$/.test(ref.path) || ref.path.split('/').some(p => !p || p === '.' || p === '..') || paths.has(ref.path) || !safe(ref.size, 1, 2147483647) || !/^[a-f0-9]{64}$/.test(ref.sha256)) fail('STAGE_ASSET_REFERENCE_INVALID');
          paths.add(ref.path); pin(); const verified = await manifest.resolve(clone(ref)); pin();
          if (!record(verified) || verified.verified !== true || verified.size !== ref.size || verified.sha256 !== ref.sha256) fail('STAGE_ASSET_NOT_VERIFIED');
          facts.verifiedAssets.push(clone(ref));
        }
        provenance.dependencyManifestSha256 = manifest.sha256; provenance.presentation = match.presentation;
      } catch (error) { gap(error.code || 'STAGE_ASSET_RESOLUTION_FAILED', 'assetManifest'); }
    }
    if (!own || facts.enemies.length !== 1 || !facts.enemies[0].card) return result();
    if (typeof input.nativeStats !== 'function') { gap('STAGE_NATIVE_STATS_REQUIRED', 'nativeStats'); return result(); }
    const card = facts.enemies[0].card;
    if (own.level > card.lv_max) { gap('STAGE_AUTHORED_LEVEL_EXCEEDS_SOURCE_CAP', 'authoredPolicy.level'); return result(); }
    let stats;
    try { pin(); stats = await input.nativeStats({contentId, masterId: card.id, level: own.level}); pin(); }
    catch (error) { if (error.code === 'STAGE_CONTENT_CHANGED') throw error; gap('STAGE_NATIVE_STATS_UNAVAILABLE', 'nativeStats', {code: error.code || 'SOURCE_STATS_FAILED'}); return result(); }
    if (!record(stats) || stats.master_id !== card.id || stats.level !== own.level || stats.base_excludes_bonuses !== true || stats.policy !== 'master-coefficient-linear-floor-v1' || !safe(stats.hp, 1, 2147483647) || !safe(stats.atk, 0, 2147483647) || !safe(stats.def, 0, 2147483647)) { gap('STAGE_NATIVE_STATS_BINDING_INVALID', 'nativeStats'); return result(); }
    facts.nativeStats = clone(stats);
    let enemy;
    try {
      const hp = own.hpBudget === undefined ? scale(stats.hp, own.hpScalePpm) : own.hpBudget, atk = scale(stats.atk, own.atkScalePpm), def = scale(stats.def, own.defScalePpm);
      if (!hp) fail('STAGE_SCALED_STATS_INVALID');
      enemy = {id: 'stage-' + input.mapId + '-battle-' + input.battleIndex + '-round-' + input.roundNo + '-enemy-' + card.id, name: card.name, element: card.element % 10, classType: card.element >= 20 ? 'extreme' : card.element >= 10 ? 'super' : 'neutral', hp, def, attacks: own.attacks.map((a, i) => ({id: 'authored-attack-' + i, slot: a.slot, atk: scale(atk, a.multiplierPpm), kind: 'normal', animation: null}))};
    } catch (error) { gap(error.code || 'STAGE_SCALED_STATS_INVALID', 'authoredPolicy'); }
    pin(); return result(enemy);
  }
  return Object.freeze({planEncounter});
});
