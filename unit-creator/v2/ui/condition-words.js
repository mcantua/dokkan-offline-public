"use strict";
// Every activation condition the game has, written the way Dokkan Battle writes it
// ("When HP is 50% or less", "As the 3rd attacker in a turn", "When there is an ally whose name includes "Goku" on the team"…),
// so copied abilities never show "An inherited condition". Combined rules read "when X and Y", "when X or Y", "unless X".
window.ForgeConditionWords = (() => {
  const ord = (n) => { n = Number(n); const s = ["th", "st", "nd", "rd"], v = n % 100; return n + (s[(v - 20) % 10] || s[v] || s[0]); };
  const TYPE_BITS = [[1, "AGL"], [2, "TEQ"], [4, "INT"], [8, "STR"], [16, "PHY"], [32, "Super Class"], [64, "Extreme Class"], [4096, "Super AGL"], [8192, "Super TEQ"], [16384, "Super INT"], [32768, "Super STR"], [65536, "Super PHY"], [131072, "Extreme AGL"], [262144, "Extreme TEQ"], [524288, "Extreme INT"], [1048576, "Extreme STR"], [2097152, "Extreme PHY"]];
  const SPHERES = [[1, "AGL"], [2, "TEQ"], [4, "INT"], [8, "STR"], [16, "PHY"], [32, "Rainbow"]];
  const STATUS = [[16, "{passiveImg:atk_down}"], [32, "{passiveImg:def_down}"], [256, "{passiveImg:stun}"], [1024, "{passiveImg:astute}"]];
  const bitNames = (v, list) => list.filter(([b]) => Number(v) & b).map(([, n]) => n);
  const orList = (a, w = "or") => a.length <= 1 ? a.join("") : a.slice(0, -1).join(", ") + " " + w + " " + a[a.length - 1];
  const article = (w) => /^[AEIOU]/i.test(w) ? "an " + w : "a " + w;
  const typeWord = (v) => { const n = bitNames(v, TYPE_BITS); return n.length ? orList(n.map((x) => /Class$/.test(x) ? x : x + " Type")) : "chosen Type"; };
  const sphereWord = (v) => { v = Number(v); if ((v & 31) === 31 && (v & 32)) return ""; if ((v & 31) === 31) return "Type "; const n = bitNames(v, SPHERES); return n.length ? orList(n) + " " : ""; };
  const CMP = { 1: "fewer than", 2: "or fewer", 3: "exactly", 4: "or more", 5: "more than", 6: "other than" };
  let domains = null;
  function loadDomains() {
    if (domains || typeof Native === "undefined") return;
    domains = {};
    Native.call("query", { table: "dokkan_fields", limit: 500 }).then((rows) => { for (const r of rows || []) domains[r.id] = r.name; }).catch(() => {});
  }

  // one condition row → Dokkan wording (lowercase start)
  function phrase(row, names, timing) {
    const t = Number(row.causality_type), a = Number(row.cau_val1), b = Number(row.cau_val2), c = Number(row.cau_val3);
    const cat = (id) => '"' + ((names.category && names.category(id)) || "chosen") + '"';
    const who = (id) => '"' + ((names.nameSet && names.nameSet(id)) || (names.unique && names.unique(id)) || "chosen character") + '"';
    const ki = (v) => (names.kiOf ? names.kiOf(v) : Math.round(v / 25));
    const receiving = [6, 7].includes(Number(timing));
    switch (t) {
      case 0: return "";
      case 1: return "when HP is " + a + "% or more";
      case 2: return "when HP is " + a + "% or less";
      case 3: return receiving ? "when receiving an attack with " + ki(a) + " or more Ki" : ki(a) >= 24 ? "when activating the Active Skill or when attacking with 24 Ki" : "when attacking with " + ki(a) + " or more Ki";
      case 4: return (receiving ? "when receiving an attack with " : "when attacking with ") + ki(a) + " or less Ki";
      case 5: return "starting from the " + ord(a + 1) + " turn from the start of battle";
      case 6: return "when all allies have the Link Skill \"" + ((names.link && names.link(a)) || "chosen") + "\"";
      case 7: return "when the enemy has the Link Skill \"" + ((names.link && names.link(a)) || "chosen") + "\"";
      case 8: return "when ATK is " + a + " or more and DEF is " + b + " or more";
      case 9: return "when ATK is " + a + " or less and DEF is " + b + " or less";
      case 10: return "when HP is " + a + "% or more and Ki is " + b + " or more";
      case 11: return "when HP is " + a + "% or more and Ki is " + b + " or less";
      case 12: return "when HP is " + a + "% or less and Ki is " + b + " or more";
      case 13: return "when HP is " + a + "% or less and Ki is " + b + " or less";
      case 14: return "as the 1st attacker in a turn";
      case 15: return "when facing " + a + " or more enemies";
      case 16: return a <= 2 ? "when facing only 1 enemy" : "when facing " + (a - 1) + " or fewer enemies";
      case 17: return "when the target enemy's HP is " + a + "% or more";
      case 18: return "when the target enemy's HP is " + a + "% or less";
      case 19: return "as the " + ord(a + 1) + " attacker in a turn";
      case 20: case 21: return "when attacking with " + (t === 20 ? "high" : "low") + " Ki against an enemy in a special status";
      case 22: return "when " + ((names.unique && names.unique(a)) || "the chosen character") + " is on the team";
      case 23: return "when " + a + " or more Link Skills are active";
      case 24: return "after receiving an attack";
      case 25: return "after delivering a final blow";
      case 26: return "when HP is " + a + "% or more and Ki is enough for a Super Attack";
      case 27: return "when HP is " + a + "% or less and Ki is enough for a Super Attack";
      case 28: return "when there is " + article(typeWord(1 << a)) + " ally in the rotation";
      case 29: return "when facing " + ((names.unique && names.unique(a)) || "the chosen character");
      case 30: return "after guard is activated";
      case 31: return "when the enemy performs a combination attack";
      case 32: return "when there are " + (sphereWord(a) || "") + "Ki Spheres on the board";
      case 33: return "when HP is between " + a + "% and " + b + "%";
      case 34: {
        const g = cat(b) + " Category";
        if (a === 1) return c > 1 ? "when there are " + c + " or more " + g + " enemies" : "when there is " + article(g) + " enemy";
        if (a === 2) return c > 1 ? "when there are " + c + " or more " + g + " allies attacking in the same turn" : "when there is " + article(g) + " ally attacking in the same turn";
        return c > 1 ? "when there are " + c + " or more " + g + " allies on the team" : "when there is " + article(g) + " ally on the team";
      }
      case 35: return "when there are " + typeWord(a).replace(/ or /g, ", ") + " allies on the team";
      case 36: return "when HP is " + a + "% or more starting from the " + ord(b + 1) + " turn from the start of battle";
      case 37: return "when HP is " + a + "% or less starting from the " + ord(b + 1) + " turn from the start of battle";
      case 38: { const s = bitNames(a, STATUS); return "when the target enemy is in the following status: " + (s.length ? (b === 1 || s.length === 1 ? orList(s) : orList(s, "&")) : "a negative status"); }
      case 39: return "when attacking " + article(typeWord(a)) + " enemy";
      case 40: return [6, 7].includes(Number(timing)) ? "when receiving a Super Attack" : [4, 5, 11, 3, 8].includes(Number(timing)) ? "when performing a Super Attack" : "when performing or receiving a Super Attack";
      case 41: {
        const n = 'an ally whose name includes ' + who(b);
        if (a === 1) return "when there is an enemy whose name includes " + who(b);
        if (a === 2) return "when there is " + n + " attacking in the same turn";
        return c > 1 ? "when there are " + c + " or more allies whose names include " + who(b) + " on the team" : "when there is " + n + " on the team";
      }
      case 42: return "with " + b + " or more " + sphereWord(a) + "Ki Spheres obtained";
      case 43: return "after evading an attack";
      case 44: return a === 1 ? "after performing " + b + " Super Attack" + (b === 1 ? "" : "s") + " in battle" : a === 2 ? "after performing " + b + " or more attacks in battle" : a === 3 ? "after receiving " + b + " or more attacks in battle" : a === 4 ? "after guard is activated " + b + " time" + (b === 1 ? "" : "s") + " in battle" : "after evading " + b + " attack" + (b === 1 ? "" : "s") + " in battle";
      case 45: {
        const g = cat(b) + " Category", w = who(c);
        return a === 1 ? "when there is " + article(g) + " enemy whose name includes " + w : a === 2 ? "when there is " + article(g) + " ally whose name includes " + w + " attacking in the same turn" : "when there is " + article(g) + " ally whose name includes " + w + " on the team";
      }
      case 46: {
        const g = typeWord(b);
        if (a === 1) return "when there is " + article(g) + " enemy";
        if (a === 2) return c > 1 ? "when there are " + c + " " + g + " allies attacking in the same turn" : "when there is " + article(g) + " ally attacking in the same turn";
        return c > 1 ? "when there are " + c + " or more " + g + " allies on the team" : "when there is " + article(g) + " ally on the team";
      }
      case 47: return "after the character's Revival Skill is activated";
      case 48: return "when receiving an attack from an enemy who is hit by the character's " + (["Super Attack", "Super Attack", "Ultra Super Attack", "Active Skill or Finish Skill", "Super Attack"][a] || "Super Attack");
      case 49: return "when receiving " + ({ 1: "a Ki Blast", 2: "an Unarmed", 4: "a Physical" }[a] || "a") + " Super Attack";
      case 50: return "after a passive effect activates";
      case 51: return "for " + a + " turn" + (a === 1 ? "" : "s") + " from the character's entry turn";
      case 52: return "while charging the Standby Skill";
      case 53: return "while in Standby Mode";
      case 54: return "after an ally's Revival Skill is activated";
      case 55: return "starting from the " + ord(a + 1) + " turn from the character's entry turn";
      case 56: return "when receiving a normal attack";
      case 57: { loadDomains(); return 'when the Domain "' + ((domains && domains[a]) || "chosen") + '" is active'; }
      case 58: return a ? "when a Domain is active" : "when no Domain is active";
      case 59: return a === 2 ? "as an Extreme Class character" : "as a Super Class character";
      case 60: return (names.subGroup && names.subGroup(a)) ? "as " + names.subGroup(a) + " character" : "when the character is in the chosen group";
      case 61: return "after receiving an attack in the turn";
      case 62: return "when attacked by " + article(typeWord(a)) + " enemy";
      case 63: return "starting from a later turn of the round";
      case 64: return "when " + (a === 3 ? "exactly " + b : CMP[a] && /^(fewer|more|exactly|other)/.test(CMP[a]) ? CMP[a] + " " + b : b + " " + (CMP[a] || "or more")) + " Dragon Balls are obtained";
      case 65: return "when " + (CMP[a] && /^(fewer|more|exactly|other)/.test(CMP[a]) ? CMP[a] + " " + b : b + " " + (CMP[a] || "or more")) + " allies have a Giant Form";
      case 66: return "after activating the Active Skill" + (a > 1 ? " " + a + " times" : "");
      case 67: return a === 0 ? "when all allies are " + cat(b) + " Category characters" : a === 1 ? "when all allies' names include " + who(b) : "when all allies are " + typeWord(b) + " characters";
      case 9001: return "when performing a critical hit";
      default: return "under a special condition";
    }
  }
  const strip = (p) => p.replace(/^when /, "");
  // compiled expression → wording; returns null when some condition rows are not loaded yet
  function text(compiled, lookup, names = {}, timing) {
    let missing = false;
    const walk = (n) => {
      if (typeof n === "number") { const r = lookup(n); if (r === undefined) { missing = true; return ""; } return r ? phrase(r, names, timing) : "under a special condition"; }
      if (!Array.isArray(n)) return "";
      const op = n[0], parts = n.slice(1).map(walk).filter(Boolean);
      if (op === "!") return parts.length ? "unless " + strip(parts[0]).replace(/^(starting|after|as|for|while|with)/, "$1") : "";
      if (!parts.length) return "";
      // "when X and Y": later "when …" lose their "when"
      return parts.map((p, i) => (i && /^when /.test(p) && /^when /.test(parts[0]) ? strip(p) : p)).join(op === "|" ? " or " : " and ");
    };
    const out = walk(compiled);
    return missing ? null : out;
  }
  function missingIds(compiled, lookup) {
    const out = [];
    const walk = (n) => { if (typeof n === "number") { if (lookup(n) === undefined) out.push(n); } else if (Array.isArray(n)) n.slice(1).forEach(walk); };
    walk(compiled);
    return out;
  }
  return { phrase, text, missingIds, ord };
})();
