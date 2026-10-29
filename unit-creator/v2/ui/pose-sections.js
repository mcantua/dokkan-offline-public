(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory(require("./motion"));
  else root.ForgePoses = factory(root.ForgeMotion);
})(typeof globalThis !== "undefined" ? globalThis : this, function(Motion) {
  "use strict";
  const definitions = [
    ["idle-front", "Ready · facing forward", 0, 100, "c00_idl_front"],
    ["idle-side", "Ready · facing sideways", 1, 101, "c01_idl_side"],
    ["idle-back", "Ready · facing away", 2, 102, "c02_idl_back"],
    ["dash", "Dash", 3, 103, "c03_dash"],
    ["guard", "Guard", 4, 104, "c04_guard"],
    ["hurt-back", "Hit · from behind", 5, 105, "c05_dam_back"],
    ["hurt-side", "Hit · from the side", 6, 106, "c06_dam_side"],
    ["hurt-front", "Hit · from the front", 7, 107, "c07_dam_front"],
    ["roll", "Tumble", 8, 108, "c08_dam_roll"],
    ["punch-one", "Punch · first variation", 9, 109, "c09_01_atc_punch"],
    ["punch-two", "Punch · second variation", 10, 110, "c09_02_atc_punch"],
    ["punch-three", "Punch · third variation", 11, 111, "c09_03_atc_punch"],
    ["kick-one", "Kick · first variation", 12, 112, "c10_01_atc_kick"],
    ["kick-two", "Kick · second variation", 13, 113, "c10_02_atc_kick"],
    ["kick-three", "Kick · third variation", 14, 114, "c10_03_atc_kick"],
    ["downward-attack", "Downward strike", 15, 115, "c13_atc_down"],
    ["forward-attack", "Forward strike", 16, 116, "c12_atc_front"],
    ["charge", "Power up · facing forward", 17, 117, "c15_heapup"],
    ["charge-back", "Power up · facing away", 18, 118, "c16_heapup_back"],
    ["ki-blast", "Ki blast", 19, 119, "c17_atc_energyball"]
  ].map(([key, label, player, enemy, scene]) => Object.freeze({ key, label, player, enemy, playerScene: scene + "_p", enemyScene: scene + "_e" }));
  function create(key, { seconds = 1, travelX = 0, travelY = 0, loop = false } = {}) {
    const pose = definitions.find((p) => p.key === key);
    if (!pose) throw new Error("Choose a named character pose.");
    if (!Number.isFinite(seconds) || seconds < 0.1 || seconds > 30) throw new Error("Choose a pose duration between 0.1 and 30 seconds.");
    if (!Number.isFinite(travelX) || !Number.isFinite(travelY) || Math.abs(travelX) > 1600 || Math.abs(travelY) > 1600) throw new Error("Keep pose movement within the editor range.");
    const frames = Math.round(seconds * 60), end = Math.max(0, frames - 1), x = travelX / 2, y = travelY / 2;
    const text = "-- Dokkan Unit Creator named character pose; the selected gameplay action supplies its trigger.\nlocal pose=" + pose.player + "\nif _IS_PLAYER_SIDE_ == 0 then pose=" + pose.enemy + " end\nsetDisp(0,0,1)\nchangeAnime(0,0,pose)\nsetAnimeLoop(0,0," + (loop ? 1 : 0) + ")\nsetScaleKey(0,0,1,1)\nsetMoveKey(0,0," + -x + "," + -y + ",0)\nsetMoveKey(" + end + ",0," + x + "," + y + ",0)\nendPhase(" + frames + ")\n";
    const clip = Motion.createClip({ kind: "forge-character-pose", pose: key, path: "forge/character_poses/" + key, label: pose.label + " · your character", text, catalog: { unitName: "Your selected character artwork", moveName: pose.label } });
    clip.to = frames / 60;
    clip.pose = { key, seconds, travelX, travelY, loop: Boolean(loop) };
    return clip;
  }
  return { definitions, create };
});
