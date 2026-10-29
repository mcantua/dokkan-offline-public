(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory();
  else root.ForgeMotion = factory();
})(typeof globalThis !== "undefined" ? globalThis : this, function() {
  "use strict";
  const kinds = { all: "All character animations", super: "Super Attack", ultra: "Ultra Super Attack", ex: "EX / Extra Super Attack", fullpower: "Full-power attack", active: "Active Skill", ultimate: "Ultimate", standby: "Standby", finish: "Finish Skill", intro: "Intro / appearance", transform: "Transformation", counter: "Counterattack", nullify: "Nullify / absorb an attack", giant: "Giant form", revival: "Revival", normal: "Normal attack", dodge: "Dodge", dash: "Dash", launcher: "Launcher", combo: "Combo", victory: "Victory", other: "Other sequence" };
  const folders = { a: "attack_low", ak: "attack_low_kidan", b: "attack_high", bk: "attack_high_kidan", sp: "attack_sp", bs: "active_skill", ut: "ultimate_special", st: "standby_skill", fi: "finish_skill", tf: "active_skill", pse: "passive_skill_effect", c: "attack_counter", as: "ab_sys", trs: "transformation", rv: "revival", rev: "revival", enl: "enlarge" };
  function pathFor(script, files = []) {
    var _a;
    if (typeof script !== "string" || !/^\w+$/.test(script)) throw new Error("This animation has no readable game reference.");
    const prefix = Object.keys(folders).sort((a, b) => b.length - a.length).find((key) => script.toLowerCase().startsWith(key));
    const guess = folders[prefix] ? "ab_script/" + folders[prefix] + "/" + script + ".lua" : null;
    // The folder named by the prefix wins when it exists (a0001 is in four folders); otherwise
    // trust the published file list over the guess.
    if (guess && files.includes(guess)) return guess;
    const match = files.find((p) => p.endsWith("/" + script + ".lua"));
    return match || guess;
  }
  function kindForPath(path) {
    const f = path.split("/")[1];
    // Shared system scripts also include position resets and no-attack messages.
    // Only the verified Dodge entry point belongs in the Dodge picker.
    if (f === "ab_sys") return path === "ab_script/ab_sys/dg0001.lua" ? "dodge" : "other";
    return { attack_sp: "super", active_skill: "active", ultimate_special: "ultimate", standby_skill: "standby", finish_skill: "finish", passive_skill_effect: "intro", transformation: "transform", revival: "revival", enlarge: "giant", attack_counter: "counter", attack_low: "normal", attack_high: "normal", attack_low_kidan: "normal", attack_high_kidan: "normal" }[f] || "other";
  }
  const timed = "onDodgeExecuted wipeIn wipeOut wipeInOut setBgBlendColor setBgMoveKey setBgRotateKey setBgScaleKey setBgScroll setQuake setScreenOffset setShake setShakeXY setShakeKey startBgScroll stopBgScroll setMoveKey setScaleKey setRotateKey setLastPosKey setGaussBlurKey setDisp setDrawFront setEnableAura changeAnime setAnimeLoop changeAnimeAndStop setDamage setShakeChara setZanzou setZanzouSpeed setZanzouColor setBlendColor setAlphaKey entryCharaView entryEffect entryEffectUnpausable entryEffectLife entryEffectTraining entryEffectAwaken setEffMoveKey setEffScaleKey setEffRotateKey setEffColorKey setEffAlphaKey setEffShake removeAllEffect setEffBlendColor entryKakimoji setupMovie stopMovie pauseMovie visibleMovie scaleMovie setPhase endPhase gotoPhase pauseChara delayChara pauseAll delayAll dealDamage recover setVisibleUI setTriggerGaugeVisible setTriggerGaugeVisibie showCountdownLabel hideCountdownLabel showMessageLabel showMessageLabelFlexible hideMessageLabel showEfficacyCutinLabel hideEfficacyCutinLabel adjustAttackerLabel adjustEnemyLabel hideKoScreen fadeKoLabel skipFrame flipAttackerSide showAttackBreakEffects entryFlash entryFlashBg entryFade entryFadeBg removeAllFade removeAllFadeBg playSe playSeLife playSeVer2 playSeNotStoppable stopAndCancelAllSe stopAndCancelAllVoice stopSe stopSeQueueId stopSeIfDoubleSpeed setSeVolume setSeVolumeByWorkId playVoice stopVoice setVoiceVolume changeBgm setEnvZoomEnable setPitch".split(" ");
  const getters = "setStartTimeMs setTimeStretch setBandpassFilter getEfficacyCutInCount getEfficacyCutInPath getEfficacyCutInFramePath setEffReplaceTexture setEffReplaceTextureByCardId setEffReplaceTextureByFilename setEnableAutoXFlip getEnvZoom getGameScreenWidth getGameScreenHeight".split(" ");
  function numeric(expression, values = {}) {
    const raw = String(expression).trim(), tokens = raw.match(/0x[\da-f]+|\d*\.?\d+|[a-z_]\w*|[()+\-*/%]/ig) || [];
    if (tokens.join("") !== raw.replace(/\s/g, "")) return null;
    let p = 0;
    function atom() {
      const t = tokens[p++];
      if (t === "-") return -atom();
      if (t === "+") return atom();
      if (t === "(") {
        const x = add();
        if (tokens[p++] !== ")") throw 0;
        return x;
      }
      if (/^(?:0x[\da-f]+|\d*\.?\d+)$/i.test(t || "")) return Number(t);
      if (Object.prototype.hasOwnProperty.call(values, t)) return values[t];
      throw 0;
    }
    function mul() {
      let v = atom();
      while (["*", "/", "%"].includes(tokens[p])) {
        const op = tokens[p++], rhs = atom();
        v = op === "*" ? v * rhs : op === "/" ? v / rhs : v % rhs;
      }
      return v;
    }
    function add() {
      let v = mul();
      while (["+", "-"].includes(tokens[p])) {
        const op = tokens[p++], rhs = mul();
        v = op === "+" ? v + rhs : v - rhs;
      }
      return v;
    }
    try {
      const v = add();
      return p === tokens.length && Number.isFinite(v) ? v : null;
    } catch {
      return null;
    }
  }
  const commonNames = ["showCardCutin", "showCardCutinEx", "showCardCutinOffset", "changeAnimeBySide"];
  const commonRuntime = `
local function cutin(frame,dynamic,variant,offsetY)
 local level=tonumber(env._SPECIAL_SKILL_LEVEL_) or 0
 local cardId=variant==1 and 1514 or variant==2 and 1513 or 1507
 local nameId=1512
 if level==1 then cardId=variant==1 and 1127 or variant==2 and 3248 or 1120;nameId=3246
 elseif level==2 then cardId=variant==1 and 1128 or variant==2 and 3252 or 1121;nameId=3250 end
 local card=env.entryEffectLife(frame,cardId,90,0x100,-1,0,0,0)
 local function face(handle)
  if env._IS_PLAYER_SIDE_==0 then env.setEffScaleKey(frame,handle,-1,1);env.setEffScaleKey(frame+90,handle,-1,1) end
 end
 if variant==2 then env.speff2=card;face(card) end
 env.setEffReplaceTexture(card,1,1);env.setEffReplaceTexture(card,2,0);env.setEffReplaceTexture(card,5,4)
 local function lines(effect,scale,shake,attr)
  local h=env.entryEffectLife(frame,effect,90,attr or 0x100,-1,0,0,0)
  if shake then env.setEffShake(frame,h,90,20) end
  env.setEffMoveKey(frame,h,0,0,0);env.setEffMoveKey(frame+90,h,0,0,0)
  env.setEffScaleKey(frame,h,scale,scale);env.setEffScaleKey(frame+90,h,scale,scale)
  env.setEffRotateKey(frame,h,0);env.setEffRotateKey(frame+90,h,0)
  env.setEffAlphaKey(frame,h,255);env.setEffAlphaKey(frame+90,h,255)
  return h
 end
 if variant==2 then env.housha=lines(1511,1,false) end
 local focus=lines(906,1.6,true)
 if variant==2 then
  env.shuchusen=focus
  if level>0 then env.kaminari=lines(level==2 and 3251 or 3247,1,false);env.haikei=lines(level==2 and 3253 or 3249,1,false,0x80) end
  env.spname=env.entryEffectLife(frame,nameId,90,0x100,-1,0,0,offsetY);face(env.spname);env.setEffReplaceTexture(env.spname,5,4)
 end
 env.SE_CUTIN=env.playSe(frame,1035)
 env.entryFadeBg(frame,0,dynamic==1 and 94 or 96,0,env.fcolor_r,env.fcolor_g,env.fcolor_b,255)
 env.entryFade(frame,0,2,4,env.fcolor_r,env.fcolor_g,env.fcolor_b,255)
 env.entryFade(frame+80,6,8,0,env.fcolor_r,env.fcolor_g,env.fcolor_b,255)
 return frame+94
end
local function changeBySide(frame,actor,anime)
 if env._IS_PLAYER_SIDE_==0 then if anime>=100 then anime=anime-100 else anime=anime+100 end end
 env.changeAnime(frame,actor,anime)
end
`;
  function helperRuntime(used) {
    if (!used.length) return "";
    let output = commonRuntime;
    for (const name of used) {
      if (name === "changeAnimeBySide") output += "env.changeAnimeBySide=changeBySide\n";
      else output += "env." + name + "=function(frame,dynamic,offsetY) return cutin(frame,dynamic," + (name === "showCardCutinEx" ? 1 : name === "showCardCutinOffset" ? 2 : 0) + ",offsetY) end\n";
    }
    return output;
  }
  // analyze() scans a whole Lua script with many regular expressions. Editing calls it for every
  // clip on every change, so results are remembered per script text (small, bounded cache).
  const analyzed = new Map();
  function analyze(text) {
    if (typeof text === "string" && analyzed.has(text)) {
      const hit = analyzed.get(text);
      analyzed.delete(text);
      analyzed.set(text, hit);
      return { ...hit, markers: hit.markers.slice(), helpers: hit.helpers.slice(), unknown: hit.unknown.slice() };
    }
    const result = analyzeText(text);
    analyzed.set(text, result);
    if (analyzed.size > 48) analyzed.delete(analyzed.keys().next().value);
    return { ...result, markers: result.markers.slice(), helpers: result.helpers.slice(), unknown: result.unknown.slice() };
  }
  function analyzeText(text) {
    if (typeof text !== "string" || text.length > 2 * 1024 ** 2) throw new Error("Animation source exceeds 2 MB.");
    const clean = text.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, "").replace(/--[^\r\n]*/g, "");
    const values = {}, markers = [], calls = new Set([...clean.matchAll(/\b([A-Za-z_]\w*)\s*\(/g)].map((m) => m[1]));
    let max = 0, end = null;
    for (const line of clean.split(/[\r\n;]/)) {
      const assignment = line.match(/^\s*(?:local\s+)?([A-Za-z_]\w*)\s*=\s*([^=].*)$/);
      if (assignment) {
        let n = numeric(assignment[2], values);
        const helper = assignment[2].match(/^showCardCutin(?:Ex|Offset)?\s*\(\s*([^,]+),/);
        if (n === null && helper) {
          const start = numeric(helper[1], values);
          if (start !== null) n = start + 94;
        }
        if (n !== null) values[assignment[1]] = n;
      }
      for (const m of line.matchAll(/\b([A-Za-z_]\w*)\s*\(\s*([^,)]*(?:\([^)]*\)[^,)]*)?)/g)) {
        calls.add(m[1]);
        if (!timed.includes(m[1]) && !commonNames.includes(m[1])) continue;
        const frame = numeric(m[2], values);
        if (frame !== null && frame >= 0 && frame < 36e3) {
          max = Math.max(max, frame);
          if (m[1] === "endPhase") end = Math.max(end || 0, frame);
          if (m[1].startsWith("showCardCutin")) {
            markers.push(Math.round(frame));
            max = Math.max(max, frame + 94);
          }
          if (m[1].startsWith("entryEffect")) markers.push(Math.round(frame));
        }
      }
    }
    const own = new Set([...clean.matchAll(/function\s+([A-Za-z_]\w*)/g)].map((m) => m[1]));
    const unknown = [...calls].filter((n) => /^(set|entry|change|play|pause|remove|stop|show|hide|delay)/.test(n) && !timed.includes(n) && !getters.includes(n) && !commonNames.includes(n) && !own.has(n));
    return { training: /\bentryEffectTraining\s*\(/.test(clean), awakening: /\bentryEffectAwaken\s*\(/.test(clean), video: /\bsetupMovie\s*\(/.test(clean), phaseJump: /\bgotoPhase\s*\(/.test(clean), frames: Math.max(60, Math.round(end || max || 900)), estimated: end === null, phaseEnd: end, markers: [.../* @__PURE__ */ new Set([0, ...markers])].sort((a, b) => a - b), helpers: commonNames.filter((n) => calls.has(n)), unknown };
  }
  function createClip(source) {
    var _a;
    const report = analyze(source.text);
    return { key: "clip-" + Math.random().toString(36).slice(2), label: source.label || ((_a = source.catalog) == null ? void 0 : _a.moveName) || "Animation section", source, from: 0, to: report.frames / 60, x: 0, y: 0, zoom: 100, rotation: 0, opacity: 100, mirror: false, mute: false, actor: "unit", report };
  }
  function validate(clips, { context = "battle" } = {}) {
    var _a, _b, _c, _d;
    const errors = [];
    if (!Array.isArray(clips) || !clips.length) return ["Add at least one animation section."];
    if (clips.length > 24) errors.push("Use up to 24 sections in one animation.");
    let duration = 0;
    for (const c of clips) {
      if (!((_a = c.source) == null ? void 0 : _a.text)) errors.push("A section is missing its original animation.");
      for (const k of ["from", "to", "x", "y", "zoom", "rotation", "opacity"]) if (!Number.isFinite(Number(c[k]))) errors.push("Choose a valid " + k + " value.");
      if (c.from < 0 || c.to <= c.from || c.to > 600) errors.push("A section must end after it starts, within ten minutes.");
      if (c.zoom < 10 || c.zoom > 400 || c.opacity < 0 || c.opacity > 100 || Math.abs(c.x) > 2e3 || Math.abs(c.y) > 2e3 || Math.abs(c.rotation) > 360) errors.push("Keep size, placement, rotation, and opacity inside the editor ranges.");
      if (!["unit", "opponent"].includes(c.actor || "unit")) errors.push("Choose which fighter performs this section.");
      duration += c.to - c.from;
      const report = analyze(((_b = c.source) == null ? void 0 : _b.text) || "");
      if (c.from > 0 && (report.video || ((_c = c.source) == null ? void 0 : _c.movieBindingKey)) && !(c.source.sequenceMovieTrim?.from === c.from && c.source.sequenceMovieTrim?.to === c.to)) errors.push("A section starts inside a video. Reuse that video from its beginning; its end can be trimmed.");
      if ((report.video || ((_d = c.source) == null ? void 0 : _d.movieBindingKey)) && (c.zoom !== 100 || c.x !== 0 || c.y !== 0 || c.rotation !== 0 || c.opacity !== 100 || c.mirror)) errors.push("Video scenes keep their encoded framing. Use their original size, placement, rotation, and opacity.");
      if ((report.training || report.awakening) && context !== "training") errors.push("This scene uses the training or awakening screen. Preview it with chosen items; choose a combat sequence for a battle move.");
      if ((report.training || report.awakening) && context === "training" && (c.zoom !== 100 || c.x !== 0 || c.y !== 0 || c.rotation !== 0 || c.opacity !== 100 || c.mirror)) errors.push("Training items and awakening medals keep their original screen placement.");
      if (report.phaseJump) errors.push("This animation uses phase jumps. Preview or reuse it whole; its sections cannot be safely retimed.");
      const unknown = report.unknown;
      if (unknown.length) errors.push("This section uses animation commands the composer cannot safely retime: " + unknown.join(", ") + ". You can still preview and reuse the original move.");
    }
    if (duration > 180) errors.push("Keep a combined animation within three minutes.");
    return [...new Set(errors)];
  }
  const luaQuote = (s) => '"' + String(s).replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\r/g, "\\r").replace(/\n/g, "\\n") + '"';
  function compile(clips, { damage = true, recover = false, role = "attacker", context = "battle", music = null } = {}) {
    var _a;
    const sequenceMusic = music ? (typeof ForgeSequence !== "undefined" ? ForgeSequence : require("./sequence-model")).music(music) : null;
    if (!["battle", "training"].includes(context)) throw new Error("Unknown animation screen context.");
    if (context === "training" && damage) throw new Error("Training screen animations cannot deal battle damage.");
    if (!["attacker", "defender"].includes(role)) throw new Error("Unknown gameplay actor role.");
    const errors = validate(clips, { context });
    if (errors.length) throw new Error(errors.join("\n"));
    let base = 0;
    let output = "-- Dokkan Unit Creator: generated animation sequence. Original scene scripts retain their owners.\nlocal __uf_global=_G\nlocal __uf_real={}\nlocal __uf_unpack=unpack or table.unpack\nlocal __uf_dodge_frame,__uf_dodge_end\nlocal __uf_damage=" + String(Boolean(damage)) + "\n";
    if(sequenceMusic) output = "-- FORGE_SEQUENCE_MUSIC " + encodeURIComponent(JSON.stringify(sequenceMusic)) + "\n" + output;
    output += "local __uf_names={" + timed.map(luaQuote).join(",") + "}\nfor _,name in ipairs(__uf_names) do __uf_real[name]=__uf_global[name] end\n";
    if(sequenceMusic && sequenceMusic.kind !== "none") output += "if __uf_real.changeBgm then __uf_real.changeBgm(0,0) end\n";
    output += "local __uf_selected_music=" + String(!!sequenceMusic) + "\n";
    for (const clip of clips) {
      const cutIn = Math.round(clip.from * 60), cutOut = Math.round(clip.to * 60), length = cutOut - cutIn;
      output += "if not __uf_dodge_frame and not __uf_dodge_end then\ndo\nlocal base,first,last=" + base + "," + cutIn + "," + cutOut + "\nlocal dx,dy,zoom,rotation,opacity,mirror=" + [clip.x, clip.y, clip.zoom / 100, clip.rotation, clip.opacity / 100, clip.mirror ? -1 : 1].join(",") + "\nlocal mute=" + String(Boolean(clip.mute)) + "\nlocal handles={}\nlocal sourceLast=" + JSON.stringify((_a = analyze(clip.source.text).phaseEnd) != null ? _a : analyze(clip.source.text).frames) + "\nlocal sourceDodgeRead=false\nlocal swapActors=" + String(role === "defender" !== (clip.actor === "opponent")) + '\nlocal actorCalls={setMoveKey=true,setScaleKey=true,setRotateKey=true,setLastPosKey=true,setDisp=true,setDrawFront=true,setEnableAura=true,changeAnime=true,setAnimeLoop=true,changeAnimeAndStop=true,setDamage=true,setShakeChara=true,setZanzou=true,setZanzouSpeed=true,setZanzouColor=true,setBlendColor=true,setAlphaKey=true}\nlocal env=setmetatable({}, {__index=function(_,key) local value=__uf_global[key];if key=="_IS_DODGE_" and value==1 then sourceDodgeRead=true end;return value end})\nenv._G=env\nif swapActors then\n env._ATTACKER_CARD_ID_=__uf_global._DEFENDER_CARD_ID_\n env._DEFENDER_CARD_ID_=__uf_global._ATTACKER_CARD_ID_\n if type(__uf_global._IS_PLAYER_SIDE_)=="number" then env._IS_PLAYER_SIDE_=1-__uf_global._IS_PLAYER_SIDE_ end\n env._IS_DODGE_=0\nend\n';
      output += `local function point(x,y) local r=rotation*math.pi/180; x=(tonumber(x) or 0)*zoom*mirror; y=(tonumber(y) or 0)*zoom; return x*math.cos(r)-y*math.sin(r)+dx,x*math.sin(r)+y*math.cos(r)+dy end
local function wrap(name)
 return function(...)
  local a={...}; local f=tonumber(a[1]); local original=__uf_real[name]
  if not original then return -1 end
  if not f or (name=='setPitch' and #a<3) then return original(__uf_unpack(a)) end
  if name=='onDodgeExecuted' then
   if __uf_damage and __uf_global._IS_DODGE_==1 and not __uf_dodge_frame then __uf_dodge_frame=base+math.max(0,math.min(f,last)-first) end
   return 0
  end
  if name=='endPhase' then
   if __uf_dodge_frame or (not swapActors and sourceDodgeRead and env._IS_DODGE_==1 and f<sourceLast) then local at=base+math.max(0,math.min(f,last)-first);__uf_dodge_end=math.min(__uf_dodge_end or at,at) end
   return 0
  end
  if name=='setPhase' or name=='gotoPhase' or name=='dealDamage' or name=='recover' then return 0 end
  if swapActors and actorCalls[name] and (a[2]==0 or a[2]==1) then a[2]=1-a[2] end
  if f>=last then return -1 end
  if name=='changeBgm' and __uf_selected_music then return -1 end
  if (name:match('^play') or name=='changeBgm') and (mute or f<first) then return -1 end
  if name=='entryEffectTraining' or name=='entryEffectAwaken' then
   a[1]=base+math.max(0,f-first)
   return original(__uf_unpack(a))
  end
  if name:match('^entryEffect') then
   if swapActors then local slot=name=='entryEffectLife' and 5 or 4;if a[slot]==0 or a[slot]==1 then a[slot]=1-a[slot] end end
   local at=base+f-first; local id
   if name=='entryEffect' then
    if __uf_real.entryEffectLife then id=__uf_real.entryEffectLife(at,a[2],last-f,a[3],a[4],a[5],a[6],a[7],a[8]) else a[1]=at;id=original(__uf_unpack(a)) end
   else
    a[1]=at;if name=='entryEffectLife' then local life=tonumber(a[3]) or 0;a[3]=life>0 and math.min(life,last-f) or last-f end;id=original(__uf_unpack(a))
   end
   if id and id>=0 then
    handles[#handles+1]=id
    if __uf_real.setEffScaleKey then __uf_real.setEffScaleKey(at,id,zoom*mirror,zoom) end
    if __uf_real.setEffMoveKey then local x,y;if name=='entryEffectLife' then x,y=point(a[7],a[8]) else x,y=point(a[6],a[7]) end;__uf_real.setEffMoveKey(at,id,x,y,0) end
    if __uf_real.setEffRotateKey then __uf_real.setEffRotateKey(at,id,rotation) end
    if __uf_real.setEffAlphaKey then
     __uf_real.setEffAlphaKey(at,id,f<first and 0 or 255*opacity)
     if f<first then __uf_real.setEffAlphaKey(base,id,255*opacity) end
     __uf_real.setEffAlphaKey(base+last-first,id,0)
    end
   end
   return id or -1
  end
  a[1]=base+math.max(0,f-first)
  if name=='removeAllEffect' then if __uf_real.setEffAlphaKey then for _,id in ipairs(handles) do __uf_real.setEffAlphaKey(a[1],id,0) end end;return 0 end
  if name=='setMoveKey' or name=='setEffMoveKey' then a[3],a[4]=point(a[3],a[4]) end
  if name=='setScaleKey' or name=='setEffScaleKey' then a[3]=(tonumber(a[3]) or 1)*zoom*mirror;a[4]=(tonumber(a[4]) or 1)*zoom end
  if name=='setRotateKey' or name=='setEffRotateKey' then a[3]=(tonumber(a[3]) or 0)*mirror+rotation end
  if name=='setAlphaKey' or name=='setEffAlphaKey' then a[3]=(tonumber(a[3]) or 255)*opacity end
  if name=='entryFade' or name=='entryFadeBg' then
   if f<first then return 0 end
   local remaining=last-f; for i=2,4 do a[i]=math.max(0,math.min(tonumber(a[i]) or 0,remaining));remaining=remaining-a[i] end
  end
  return original(__uf_unpack(a))
 end
end
for _,name in ipairs(__uf_names) do env[name]=wrap(name);__uf_global[name]=env[name] end
if swapActors and __uf_global.setEffReplaceTextureByCardId and tonumber(env._ATTACKER_CARD_ID_) then
 env.setEffReplaceTexture=function(handle,slot,kind) return __uf_global.setEffReplaceTextureByCardId(handle,slot,env._ATTACKER_CARD_ID_,kind) end
end
` + helperRuntime(analyze(clip.source.text).helpers) + `local function scene()
 local source,name=` + luaQuote(clip.source.text) + `,` + luaQuote("@" + (clip.source.path || "Dokkan Unit Creator animation section")) + `
 local fn,problem
 if __uf_global.setfenv then
  if __uf_global.loadstring then fn,problem=__uf_global.loadstring(source,name)
  else local sent=false;fn,problem=__uf_global.load(function() if sent then return nil end;sent=true;return source end,name) end
  if fn then __uf_global.setfenv(fn,env) end
 else fn,problem=__uf_global.load(source,name,"t",env) end
 if not fn then error(problem) end
 return fn()
end
local ok,problem=pcall(scene)
for _,name in ipairs(__uf_names) do __uf_global[name]=__uf_real[name] end
if not ok then error(problem) end
end
`;
      if (/\bsetupMovie\s*\(/.test(clip.source.text)) output += "if __uf_real.stopMovie then __uf_real.stopMovie(" + (base + length) + ") end\n";
      output += "end\n";
      base += length;
    }
    if (recover) output += "if not __uf_dodge_frame and not __uf_dodge_end and __uf_real.recover then __uf_real.recover(" + Math.max(0, base - 2) + ") end\n";
    output += "local __uf_finish=__uf_dodge_end or " + (base + 2) + "\n";
    if (damage) output += "if __uf_global._IS_DODGE_ == 1 then\n __uf_finish=__uf_dodge_end or __uf_finish\n if (__uf_dodge_frame or not __uf_dodge_end) and __uf_real.onDodgeExecuted then __uf_real.onDodgeExecuted(__uf_dodge_frame or " + Math.max(0, base - 2) + ") end\nelseif __uf_real.dealDamage then __uf_real.dealDamage(" + Math.max(0, base - 2) + ") end\n";
    output += "if __uf_real.endPhase then __uf_real.endPhase(__uf_finish) end\n";
    if (output.length > 2 * 1024 ** 2) throw new Error("The combined animation exceeds 2 MB. Use fewer sections.");
    return output;
  }
  return { kinds, pathFor, kindForPath, numeric, analyze, createClip, validate, compile, timed };
});
