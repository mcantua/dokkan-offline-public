"use strict";
// Shared visual trim control for clips and movie scenes.
// Shows the whole source as a bar, the kept part highlighted, two big draggable handles,
// and the Start / End times in large text with − / + buttons. Tap a time to type it.
// CSP-safe: no inline style attributes (positions are set through element.style).
window.ForgeTrim = (() => {
  let sequence = 0;
  const clockText = (seconds, decimals = 1) => {
    const value = Math.max(0, Number(seconds) || 0), scale = 10 ** decimals, total = Math.round(value * scale), whole = Math.floor(total / scale);
    return Math.floor(whole / 60) + ":" + String(whole % 60).padStart(2, "0") + (decimals ? "." + String(total % scale).padStart(decimals, "0") : "");
  };
  function el(tag, cls, text) {
    const e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    return e;
  }
  /**
   * mount(container, {total, from, to, step, minLength, decimals, markers, snap, label,
   *                   onInput(from,to), onCommit(from,to) -> false|Promise to reject, disabledStart, note})
   */
  function mount(container, options) {
    const id = "trim-" + ++sequence;
    const o = Object.assign({ step: 0.1, minLength: 0.1, decimals: 1, markers: [], snap: [], label: "clip" }, options);
    let total = Math.max(o.minLength, Number(o.total) || 0), from = Number(o.from) || 0, to = Number(o.to) || total, busy = false;
    const round = (v) => Math.round(v / o.step) * o.step;
    const clamp = () => {
      from = Math.max(0, Math.min(from, total - o.minLength));
      to = Math.max(from + o.minLength, Math.min(to, total));
    };
    clamp();
    const root = el("div", "trim trim-d" + o.decimals);
    root.id = id;
    const times = el("div", "trim-times");
    const side = (key, caption) => {
      const box = el("div", "trim-time trim-" + key);
      const cap = el("span", "trim-cap", caption);
      const minus = el("button", "trim-nudge", "−"), plus = el("button", "trim-nudge", "+");
      minus.type = plus.type = "button";
      minus.setAttribute("aria-label", caption + " " + o.step + " seconds earlier");
      plus.setAttribute("aria-label", caption + " " + o.step + " seconds later");
      const value = el("button", "trim-value");
      value.type = "button";
      value.setAttribute("aria-label", caption + " time. Tap to type an exact time");
      const row = el("div", "trim-row");
      row.append(minus, value, plus);
      box.append(cap, row);
      minus.onclick = () => nudge(key, -1);
      plus.onclick = () => nudge(key, 1);
      value.onclick = () => edit(key, value);
      return { box, value, minus, plus };
    };
    const start = side("from", "Start"), end = side("to", "End");
    const kept = el("div", "trim-kept");
    kept.setAttribute("aria-live", "polite");
    times.append(start.box, end.box);
    const track = el("div", "trim-track");
    const cutL = el("div", "trim-cut"), keep = el("div", "trim-keep"), cutR = el("div", "trim-cut");
    const ticks = el("div", "trim-ticks");
    const hStart = el("button", "trim-handle trim-handle-start"), hEnd = el("button", "trim-handle trim-handle-end");
    for (const [h, name] of [[hStart, "Start"], [hEnd, "End"]]) {
      h.type = "button";
      h.setAttribute("role", "slider");
      h.setAttribute("aria-label", name + " of the part to keep");
      h.append(el("span", "trim-grip"));
    }
    track.append(cutL, keep, cutR, ticks, hStart, hEnd);
    const scale = el("div", "trim-scale");
    const s0 = el("span", null, clockText(0, o.decimals)), s1 = el("span", null, clockText(total, o.decimals));
    scale.append(s0, kept, s1);
    root.append(times, track, scale);
    if (o.note) root.append(el("p", "trim-note", o.note));
    container.append(root);

    function drawTicks() {
      ticks.textContent = "";
      const points = [...new Set((o.markers || []).filter((m) => m > 0 && m < total).map((m) => Math.round(m * 100) / 100))].slice(0, 120);
      for (const m of points) {
        const t = el("span", "trim-tick");
        t.style.left = (m / total * 100) + "%";
        ticks.append(t);
      }
    }
    function draw() {
      const a = from / total * 100, b = to / total * 100;
      cutL.style.left = "0%";
      cutL.style.width = a + "%";
      keep.style.left = a + "%";
      keep.style.width = (b - a) + "%";
      cutR.style.left = b + "%";
      cutR.style.width = (100 - b) + "%";
      hStart.style.left = a + "%";
      hEnd.style.left = b + "%";
      start.value.textContent = clockText(from, o.decimals);
      end.value.textContent = clockText(to, o.decimals);
      kept.textContent = "Keeps " + (to - from).toFixed(o.decimals) + " s";
      hStart.setAttribute("aria-valuemin", "0");
      hStart.setAttribute("aria-valuemax", String(+(to - o.minLength).toFixed(3)));
      hStart.setAttribute("aria-valuenow", String(+from.toFixed(3)));
      hStart.setAttribute("aria-valuetext", "Start " + clockText(from, o.decimals));
      hEnd.setAttribute("aria-valuemin", String(+(from + o.minLength).toFixed(3)));
      hEnd.setAttribute("aria-valuemax", String(+total.toFixed(3)));
      hEnd.setAttribute("aria-valuenow", String(+to.toFixed(3)));
      hEnd.setAttribute("aria-valuetext", "End " + clockText(to, o.decimals));
      start.minus.disabled = busy || o.disabledStart || from <= 0;
      start.plus.disabled = busy || o.disabledStart || from + o.minLength >= to - 1e-9;
      end.minus.disabled = busy || to - o.minLength <= from + 1e-9;
      end.plus.disabled = busy || to >= total;
      start.value.disabled = busy || Boolean(o.disabledStart);
      end.value.disabled = busy;
      hStart.disabled = busy || Boolean(o.disabledStart);
      hEnd.disabled = busy;
      root.classList.toggle("trim-busy", busy);
    }
    async function commit(previous) {
      if (!o.onCommit) return;
      busy = true;
      draw();
      try {
        const result = await o.onCommit(from, to);
        if (result === false) [from, to] = previous;
      } catch {
        [from, to] = previous;
      } finally {
        busy = false;
        draw();
      }
    }
    function nudge(key, direction) {
      if (busy) return;
      const previous = [from, to];
      if (key === "from") from = round(from + direction * o.step);
      else to = round(to + direction * o.step);
      clamp();
      if (from === previous[0] && to === previous[1]) return;
      draw();
      o.onInput && o.onInput(from, to);
      commit(previous);
    }
    function edit(key, button) {
      if (busy) return;
      const input = el("input", "trim-input");
      input.type = "number";
      input.inputMode = "decimal";
      input.step = String(o.step);
      input.min = "0";
      input.max = String(total);
      input.value = (key === "from" ? from : to).toFixed(o.decimals);
      input.setAttribute("aria-label", (key === "from" ? "Start" : "End") + " in seconds");
      input.dataset.clip = o.dataClip ? o.dataClip + ":" + key : "";
      button.replaceWith(input);
      input.focus();
      input.select();
      let done = false;
      const finish = (save) => {
        if (done) return;
        done = true;
        input.replaceWith(button);
        if (!save) return;
        const value = Number(input.value);
        if (input.value.trim() === "" || !Number.isFinite(value)) return;
        const previous = [from, to], wanted = round(value);
        const say = (message) => (o.onInvalid || window.toast || (() => {}))(message, true);
        if (wanted < 0 || wanted > total + 1e-9) return say("Choose a time between " + clockText(0, o.decimals) + " and " + clockText(total, o.decimals) + ".");
        if (key === "from" && wanted > to - o.minLength + 1e-9) return say("Start must be before End (" + clockText(to, o.decimals) + ").");
        if (key === "to" && wanted < from + o.minLength - 1e-9) return say("End must be after Start (" + clockText(from, o.decimals) + ").");
        if (key === "from") from = wanted; else to = wanted;
        clamp();
        draw();
        if (from !== previous[0] || to !== previous[1]) {
          o.onInput && o.onInput(from, to);
          commit(previous);
        }
        button.focus();
      };
      input.onkeydown = (e) => {
        if (e.key === "Enter") { e.preventDefault(); finish(true); }
        if (e.key === "Escape") { e.preventDefault(); finish(false); }
      };
      input.onblur = () => finish(true);
      input.onchange = () => finish(true);
    }
    // Dragging: the handle you grab moves; tapping the bar moves the nearest handle.
    let drag = null;
    const valueAt = (clientX) => {
      const r = track.getBoundingClientRect();
      return Math.max(0, Math.min(total, (clientX - r.left) / Math.max(1, r.width) * total));
    };
    const snapped = (v) => {
      const near = total * 0.015;
      let best = null;
      for (const m of o.snap || []) if (Math.abs(m - v) <= near && (best === null || Math.abs(m - v) < Math.abs(best - v))) best = m;
      return best === null ? round(v) : best;
    };
    function begin(event, key) {
      if (busy || event.button > 0) return;
      if (key === "from" && o.disabledStart) key = "to";
      event.preventDefault();
      drag = { key, previous: [from, to], pointer: event.pointerId };
      root.classList.add("trim-dragging");
      try { track.setPointerCapture(event.pointerId); } catch {}
      move(event);
    }
    function move(event) {
      if (!drag || event.pointerId !== drag.pointer) return;
      const v = snapped(valueAt(event.clientX));
      if (drag.key === "from") from = Math.min(v, to - o.minLength); else to = Math.max(v, from + o.minLength);
      clamp();
      draw();
      o.onInput && o.onInput(from, to);
    }
    function release(event) {
      if (!drag || event.pointerId !== drag.pointer) return;
      const previous = drag.previous;
      drag = null;
      root.classList.remove("trim-dragging");
      if (from !== previous[0] || to !== previous[1]) commit(previous);
    }
    hStart.addEventListener("pointerdown", (e) => { e.stopPropagation(); begin(e, "from"); });
    hEnd.addEventListener("pointerdown", (e) => { e.stopPropagation(); begin(e, "to"); });
    track.addEventListener("pointerdown", (e) => {
      const v = valueAt(e.clientX);
      begin(e, Math.abs(v - from) <= Math.abs(v - to) ? "from" : "to");
    });
    track.addEventListener("pointermove", move);
    track.addEventListener("pointerup", release);
    track.addEventListener("pointercancel", release);
    for (const [h, key] of [[hStart, "from"], [hEnd, "to"]]) {
      h.addEventListener("keydown", (e) => {
        const dir = { ArrowLeft: -1, ArrowDown: -1, ArrowRight: 1, ArrowUp: 1 }[e.key];
        if (!dir) return;
        e.preventDefault();
        nudge(key, dir);
      });
    }
    drawTicks();
    draw();
    return {
      element: root,
      get: () => ({ from, to }),
      set(next) {
        if (next.total != null) { total = Math.max(o.minLength, Number(next.total)); s1.textContent = clockText(total, o.decimals); drawTicks(); }
        if (next.from != null) from = Number(next.from);
        if (next.to != null) to = Number(next.to);
        clamp();
        draw();
      },
      busy(value) { busy = Boolean(value); draw(); }
    };
  }
  return { mount, clock: clockText };
})();
