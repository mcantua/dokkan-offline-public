// Node stand-in for the native query bridge (same filters/ids/search semantics as CreatorActivity).
const { DatabaseSync } = require("node:sqlite");
const path = require("path");
const ASSETS = "/home/claude/work/apk/assets";
function open(name = "reference.db") {
  const db = new DatabaseSync(path.join(ASSETS, name), { readOnly: true });
  const schema = {};
  for (const { name: t } of db.prepare("SELECT name FROM sqlite_master WHERE type='table'").all()) {
    if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(t)) continue;
    schema[t] = db.prepare('PRAGMA table_info("' + t + '")').all().map((r) => ({ ...r }));
  }
  async function query(a) {
    const table = a.table;
    if (!schema[table]) throw new Error("Table is not in this database.");
    const where = [], params = [];
    for (const [k, v] of Object.entries(a.filters || {})) {
      if (v === null) where.push('"' + k + '" IS NULL');
      else { where.push('"' + k + '" = ?'); params.push(typeof v === "boolean" ? String(v) : v); }
    }
    if (a.ids) { if (!a.ids.length) return []; where.push('"id" IN (' + a.ids.map(() => "?").join(",") + ")"); params.push(...a.ids.map(Number)); }
    if (a.search && a.search.text) { where.push('"' + a.search.column + '" LIKE ?'); params.push("%" + a.search.text + "%"); }
    const limit = Math.max(1, Math.min(5000, Number(a.limit || 100))), offset = Math.max(0, Number(a.offset || 0));
    const sql = 'SELECT * FROM "' + table + '"' + (where.length ? " WHERE " + where.join(" AND ") : "") + ' ORDER BY "' + (a.order || "id") + '" LIMIT ' + limit + " OFFSET " + offset;
    return db.prepare(sql).all(...params).map((r) => ({ ...r }));
  }
  return { db, schema, query };
}
module.exports = { open };
