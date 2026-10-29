"""For many source cards, render every editor step and report inputs that are invalid before the user touches anything."""
import json, sys, random, sqlite3
from harness import Session
N = int(sys.argv[1]); seed = int(sys.argv[2])
ref = sqlite3.connect("file:/home/claude/work/apk/assets/sparking-reference.db?mode=ro", uri=True)
ids = [r[0] for r in ref.execute("select id from cards where id % 10 = 1 and hp_max > 300 and id < 9000000")]
extra = [int(x) for x in sys.argv[3].split(",")] if len(sys.argv) > 3 else []
pick = sorted(set(random.Random(seed).sample(ids, N) + extra))
s = Session().open(); s.page.wait_for_timeout(2500)
res = s.page.evaluate("""async (ids) => {
  const q = o => Native.call('querySparking', o), out = {}; const sinfo = await Native.call('sparkingInfo');
  for (const simple of [true, false]) {
    state.simple = simple;
    for (const id of ids) {
      let p;
      try { p = await Forge.loadTemplate(q, sinfo.schema, id, 1950000001); p.source.database = 'sparking'; } catch (e) { out['load ' + id] = String(e); continue; }
      state.project = p; state.view = 'editor';
      for (const step of [0, 1, 2, 3, 4, 5, 6, 8]) {
        state.step = step;
        try { renderEditor(); } catch (e) { (out['render ' + step] = out['render ' + step] || []).push(id + ': ' + e.message); continue; }
        await new Promise(r => setTimeout(r, 0));
        const stageSel = [...document.querySelectorAll('#main select')].find(e => /Editing abilities for/.test(e.closest('label')?.innerText || ''));
        const stages = stageSel ? [...stageSel.options].map(o => o.value) : [null];
        for (const stage of stages) {
        if (stage !== null) { const sel = [...document.querySelectorAll('#main select')].find(e => /Editing abilities for/.test(e.closest('label')?.innerText || '')); if (sel && sel.value !== stage) { sel.value = stage; sel.dispatchEvent(new Event('change', {bubbles: true})); await new Promise(r => setTimeout(r, 30)); } }
        document.querySelectorAll('#main details').forEach(d => d.open = true);
        for (const el of document.querySelectorAll('#main input, #main select, #main textarea')) {
          if (el.checkValidity()) continue;
          const label = (el.closest('label')?.innerText || el.getAttribute('aria-label') || '').split('\\n')[0].slice(0, 50);
          const key = (simple ? 'simple' : 'full') + ' step ' + step + ' | ' + label + ' | ' + el.validationMessage.replace(/\\d+/g, 'N');
          (out[key] = out[key] || []).push(id + ' value=' + el.value + ' [' + el.min + ',' + el.max + '] ' + (el.dataset.guideValue || el.dataset.bind || '') + ' stage=' + stage);
        }
        }
      }
    }
  }
  state.project = null; state.simple = true;
  return out;
}""", pick)
for k, v in sorted(res.items(), key=lambda kv: -len(kv[1]) if isinstance(kv[1], list) else 0):
    print(f"{len(v) if isinstance(v, list) else 1:4d}  {k}\n        {v[:4] if isinstance(v, list) else v}")
s.report("scan")
