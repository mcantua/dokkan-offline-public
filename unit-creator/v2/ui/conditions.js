(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory();
  else root.ForgeConditions = factory();
})(typeof globalThis !== "undefined" ? globalThis : this, function() {
  "use strict";
  const number = (index, label2, min = 0, max = 999, value = 1) => ({ index, label: label2, kind: "number", min, max, value });
  const choice = (index, label2, options, value = options[0][0]) => ({ index, label: label2, kind: "choice", options, value });
  const lookup = (index, label2, source2) => ({ index, label: label2, kind: "lookup", source: source2, min: 1, max: 2147483647 });
  const hp = () => number(0, "HP percentage", 0, 100, 50), turn = (index) => number(index, "Turn number", 0, 999, 3);
  const compare = [[1, "Less than"], [2, "At most"], [3, "Exactly"], [4, "At least"], [5, "More than"], [6, "Different from"]];
  const scope = [[0, "Your whole team"], [1, "Enemies"], [2, "Allies attacking this turn"]];
  const counts = [[1, "Super Attacks performed"], [2, "Attacks performed"], [3, "Attacks received"], [4, "Successful guards"], [5, "Successful dodges"]];
  const supers = [[0, "Any Super Attack"], [1, "Normal Super Attack"], [2, "Ultra Super Attack"], [3, "Active Skill or Finish Skill"], [4, "Unit Super Attack"]];
  const definitions = [
    [0, "Always", []],
    [1, "HP above a percentage", [hp()]],
    [2, "HP below a percentage", [hp()]],
    [5, "After a battle turn", [turn(0)]],
    [6, "Every team card has a Link Skill", [lookup(0, "Link Skill", "links")]],
    [7, "Enemy has a Link Skill", [lookup(0, "Link Skill", "links")]],
    [8, "ATK and DEF above values", [number(0, "Attack power", 0, 1e9, 1e4), number(1, "Defense", 0, 1e9, 1e4)]],
    [9, "ATK and DEF below values", [number(0, "Attack power", 0, 1e9, 1e4), number(1, "Defense", 0, 1e9, 1e4)]],
    [14, "Attacking in the first slot", []],
    [15, "More than a number of enemies", [number(0, "Number of enemies", 0, 7, 1)]],
    [16, "Fewer than a number of enemies", [number(0, "Number of enemies", 0, 7, 2)]],
    [17, "Enemy HP above a percentage", [hp()]],
    [18, "Enemy HP below a percentage", [hp()]],
    [19, "Attacking in a chosen slot", [choice(0, "Attack slot", [[0, "First slot"], [1, "Second slot"], [2, "Third slot"]])]],
    [22, "Team includes a named character", [lookup(0, "Character name", "characters")]],
    [23, "A number of Link Skills are active", [number(0, "Minimum active links", 0, 7, 3)]],
    [24, "After receiving an attack", []],
    [25, "After defeating an enemy", []],
    [26, "HP above a percentage and ready to Super Attack", [hp()]],
    [27, "HP below a percentage and ready to Super Attack", [hp()]],
    [29, "Enemy includes a named character", [lookup(0, "Character name", "characters")]],
    [30, "After a successful guard", []],
    [33, "HP between two percentages", [number(0, "Lowest HP percentage", 0, 100, 25), number(1, "Highest HP percentage", 0, 100, 75)]],
    [34, "A number of characters belong to a category", [choice(0, "Whose characters?", scope), lookup(1, "Category", "categories"), number(2, "Minimum number of characters", 1, 7, 1)]],
    [36, "HP above a percentage after a turn", [hp(), turn(1)]],
    [37, "HP below a percentage after a turn", [hp(), turn(1)]],
    [40, "Performing or receiving a Super Attack", []],
    [43, "After a successful dodge", []],
    [44, "After an action happens a number of times", [choice(0, "Which action?", counts), number(1, "Number of times", 1, 999, 3)]],
    [47, "After this character revives", []],
    [48, "Enemy hit by a chosen special move", [choice(0, "Move type", supers)]],
    [49, "Receiving a chosen Super Attack type", [choice(0, "Super Attack type", [[1, "Ki blast"], [2, "Unarmed"], [4, "Physical"]])]],
    [51, "During the first turns after appearance", [number(0, "Number of turns", 1, 999, 3)]],
    [55, "After turns from first appearance", [number(0, "Number of turns", 0, 999, 3)]],
    [56, "Receiving a normal attack", []],
    [57, "A chosen Domain is active", [lookup(0, "Domain", "domains")]],
    [58, "Whether any Domain is active", [choice(0, "Domain state", [[0, "No Domain is active"], [1, "A Domain is active"]])]],
    [59, "Character has a chosen class", [choice(0, "Class", [[1, "Super class"], [2, "Extreme class"]])]],
    [61, "After receiving an attack this turn", []],
    [64, "Dragon Balls obtained", [choice(0, "Comparison", compare, 3), number(1, "Number of Dragon Balls", 0, 7, 7)]],
    [65, "Number of cards with a giant form", [choice(0, "Comparison", compare, 4), number(1, "Number of cards", 0, 7, 1)]],
    [67, "Every team member belongs to a category", [lookup(1, "Category", "categories")]]
  ].map(([type, label2, fields]) => ({ type, label: label2, fields }));
  function values(rule) {
    var _a, _b, _c;
    const input = Array.isArray(rule.values) ? rule.values : [(_a = rule.value) != null ? _a : 0, (_b = rule.value2) != null ? _b : 0, (_c = rule.value3) != null ? _c : 0];
    if (input.length !== 3 || input.some((value) => !Number.isSafeInteger(Number(value)) || Number(value) < -2147483648 || Number(value) > 2147483647)) throw Error("Choose valid whole numbers for every condition setting.");
    return input.map(Number);
  }
  function expression(input) {
    let nodes = 0;
    const visit = (node, depth) => {
      if (++nodes > 512 || depth > 32) throw Error("This condition group is too complex to edit safely.");
      if (Number.isSafeInteger(node) && node >= -2147483648 && node <= 2147483647) return node;
      if (!Array.isArray(node) || !["!", "&", "|"].includes(node[0]) || (node[0] === "!" ? node.length !== 2 : node.length < 3)) throw Error("This inherited condition group is incompatible.");
      return [node[0], ...node.slice(1).map((child) => visit(child, depth + 1))];
    };
    return visit(input, 0);
  }
  function source(node) {
    return typeof node === "number" ? String(node) : node[0] === "!" ? "!(" + source(node[1]) + ")" : "(" + node.slice(1).map(source).join(node[0]) + ")";
  }
  function makeRule(type, input) {
    var _a, _b;
    const def = definitions.find((row) => row.type === Number(type));
    if (!def) throw Error("Choose a supported named rule, or keep an inherited condition.");
    const result = [0, 0, 0];
    for (const field of def.fields) {
      const raw = input[field.index];
      if (raw === "" || raw == null) throw Error("Choose " + field.label.toLowerCase() + ".");
      const value = Number(raw);
      if (!Number.isSafeInteger(value) || value < ((_a = field.min) != null ? _a : -2147483648) || value > ((_b = field.max) != null ? _b : 2147483647) || field.options && !field.options.some(([key]) => Number(key) === value)) throw Error("Choose a valid " + field.label.toLowerCase() + ".");
      result[field.index] = value;
    }
    if (def.type === 33 && result[0] > result[1]) throw Error("The lowest HP percentage must not exceed the highest.");
    return { type: def.type, values: result };
  }
  function label(row, refs = {}) {
    var _a, _b, _c, _d;
    const type = Number(row.causality_type), v = [row.cau_val1, row.cau_val2, row.cau_val3].map(Number), [a, b, c] = v, named = (group, id, fallback) => {
      var _a2;
      return ((_a2 = refs[group]) == null ? void 0 : _a2[id]) || fallback;
    }, comparison = ((_a = compare.find(([key]) => key === a)) == null ? void 0 : _a[1].toLowerCase()) || "matches";
    const labels = { 0: "Always", 1: "HP above " + a + "%", 2: "HP below " + a + "%", 5: "After turn " + a, 6: "Every team card has " + named("links", a, "the chosen Link Skill"), 7: "Enemy has " + named("links", a, "the chosen Link Skill"), 8: "ATK above " + a + " and DEF above " + b, 9: "ATK below " + a + " and DEF below " + b, 14: "Attacking in the first slot", 15: "More than " + a + " enemies", 16: "Fewer than " + a + " enemies", 17: "Enemy HP above " + a + "%", 18: "Enemy HP below " + a + "%", 19: "Attacking in slot " + (a + 1), 22: "Team includes " + named("characters", a, "the chosen character"), 23: a + " or more active Link Skills", 24: "After being attacked", 25: "After defeating an enemy", 26: "HP above " + a + "% and ready to Super Attack", 27: "HP below " + a + "% and ready to Super Attack", 29: "Enemy includes " + named("characters", a, "the chosen character"), 30: "Successfully guarding", 33: "HP between " + a + "% and " + b + "%", 34: (((_b = scope.find(([key]) => key === a)) == null ? void 0 : _b[1]) || "The source group") + " includes at least " + c + " in " + named("categories", b, "the chosen category"), 36: "HP above " + a + "% after turn " + b, 37: "HP below " + a + "% after turn " + b, 40: "Performing or receiving a Super Attack", 43: "After successfully dodging", 44: "After " + b + " " + (((_c = counts.find(([key]) => key === a)) == null ? void 0 : _c[1].toLowerCase()) || "source actions"), 47: "After this character revives", 48: "Enemy hit by " + (((_d = supers.find(([key]) => key === a)) == null ? void 0 : _d[1]) || "the source move"), 49: "Receiving a " + ({ 1: "Ki blast", 2: "unarmed", 4: "physical" }[a] || "source") + " Super Attack", 51: "During the first " + a + " turns after appearance", 55: "After " + a + " turns from first appearance", 56: "Receiving a normal attack", 57: "While " + named("domains", a, "the chosen Domain") + " is active", 58: a ? "While a Domain is active" : "While no Domain is active", 59: a === 1 ? "Character is Super class" : "Character is Extreme class", 61: "After receiving an attack this turn", 64: "Dragon Balls obtained: " + comparison + " " + b, 65: "Cards with a giant form: " + comparison + " " + b };
    if (type === 67 && a === 0) return "Every team member belongs to " + named("categories", b, "the chosen category");
    return labels[type] || null;
  }
  return { definitions, values, makeRule, label, expression, source };
});
