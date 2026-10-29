/* Web version adjustments, loaded after the app's own scripts:
 * - Native device actions are kept separate from supported browser resource tools.
 * - Animation selection and sequence editing use the shared app controllers.
 * - Offline support and "Add to Home Screen" for supported browsers. */
(function () {
  "use strict";
  if (!window.forgeNative || !window.forgeNative.web) return;
  const hosted = !!window.__forgeArtifact;
  document.documentElement.classList.toggle("web-hosted", hosted);
  if (hosted) { const pill = document.querySelector(".local-pill"); if (pill) pill.lastChild.textContent = window.__forgeStandaloneBase ? " Saved in this browser" : " Saved to your Claude account"; }
  // the iPhone app (.ipa) has everything built in: no service worker, no "Add to Home Screen" tip
  const iosApp = !!(window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.ForgeFiles);
  document.documentElement.classList.toggle("web-ios-app", iosApp);
  if (iosApp) { const pill = document.querySelector(".local-pill"); if (pill) pill.lastChild.textContent = " Saved on this iPhone"; }
  // offline support (not available inside Claude)
  if (!hosted && !iosApp && "serviceWorker" in navigator) addEventListener("load", () => navigator.serviceWorker.register("sw.js").catch(() => {}));
  const standalone = iosApp || matchMedia("(display-mode: standalone)").matches || navigator.standalone === true;
  document.documentElement.classList.toggle("web-standalone", standalone);

  // The original imported-file browser, backed by real IndexedDB resource bytes.
  if (typeof renderAssets === "function") renderAssets = async function () {
    main('<div class="section-heading"><div><h1>Game data &amp; files</h1><p>Import artwork, animation instructions, movies, and resource packs for your units.</p></div><button class="button" data-action="import">Import files or resource pack</button></div><section class="panel"><h2>' + number(state.info.count) + ' source cards</h2><p>' + esc(state.info.meta.source) + '</p><p class="hint">This page includes its character databases. Imported resources stay in this browser. Export ZIP or ECLP to include their actual files when moving a unit to another device. APK database replacement and game-folder installation require the phone app.</p><p class="hint">ZIP, ECLP, and CPK resource imports support up to 64 MiB of expanded files. Existing units and saved versions are kept.</p></section><div class="tabs"><button data-action="asset-local" class="' + (state.assetTab === "local" ? 'active' : '') + '">Imported assets</button><button data-action="asset-online" class="' + (state.assetTab === "online" ? 'active' : '') + '">Browse Eclipse</button></div><div id="asset-results"><p class="hint">Loading resources…</p></div>');
    if (state.assetTab === "local") await renderImportedAssets(); else await loadOnlineAssetListing();
  };

  // Keep the real sequence editor: browsing, trimming, composing, assigning and saving
  // use the same controllers as the phone app. Describe the renderer's exact limits.
  if (window.ForgePreviewStorage) ForgePreviewStorage.mount = async function (container) {
    if (!container) return;
    const draw = async () => {
      const cache = await Native.call("previewCache");
      if (!container.isConnected) return;
      container.innerHTML = '<div class="browser-preview-storage"><p class="hint">Edit and assign real Lua sequences here. Imported LWF visual packs have local pose previews in Game data &amp; files. Full scripted battles require the phone app’s Dokkan player.</p><label class="check-item"><input type="checkbox" data-browser-offline' + (cache.offline ? ' checked' : '') + '>Read saved animation sources only</label><p class="hint">' + number(cache.count) + ' downloaded source files · ' + (cache.bytes / 1048576).toFixed(1) + ' MiB. Imported resources and saved unit versions are kept when clearing downloaded sources.</p><button type="button" class="button ghost small" data-browser-clear>Clear unused downloaded sources</button><p data-browser-preview-message role="status"></p></div>';
      container.querySelector('[data-browser-offline]').onchange = async e => { try { await Native.call("previewCache", { offline: e.target.checked }); } catch (error) { e.target.checked = !e.target.checked; container.querySelector('[data-browser-preview-message]').textContent = error.message; } };
      container.querySelector('[data-browser-clear]').onclick = async e => { e.target.disabled = true; try { await Native.call("previewCache", { clear: true }); await draw(); } catch (error) { e.target.disabled = false; container.querySelector('[data-browser-preview-message]').textContent = error.message; } };
    };
    try { await draw(); } catch (error) { container.textContent = error.message; }
  };
  const importedAssets = typeof renderImportedAssets === "function" ? renderImportedAssets : null;
  if (importedAssets) renderImportedAssets = async function () {
    await importedAssets.apply(this, arguments);
    document.querySelectorAll('.asset-item [data-attach-asset]').forEach(button => {
      const path = button.dataset.gamePath;
      if (!/\.lwf$/i.test(path)) return;
      const preview = document.createElement('button'); preview.type = 'button'; preview.className = 'button subtle small'; preview.textContent = 'Preview poses';
      preview.onclick = () => Native.call('previewAnimation', { mode: 'pack', resourcePath: path, assetKey: button.dataset.attachAsset, name: path.split('/').pop() }).catch(error => toast(error.message, true));
      button.parentNode.append(preview);
    });
  };
  const browserStudio = typeof renderStudio === 'function' ? renderStudio : null;
  if (browserStudio) renderStudio = async function () {
    await browserStudio.apply(this, arguments);
    if (state.view !== 'animations') return;
    const container = document.getElementById('tl') || document.getElementById('main');
    const notice = document.createElement('section'); notice.className = 'notice browser-animation-tools';
    notice.innerHTML = '<p>Scripted battle playback needs the phone app’s Dokkan player. You can edit, save, and assign sequences here. Imported LWF artwork has pose previews in Game data &amp; files.</p><div class="row"><button type="button" class="button ghost small" data-browser-timing>Edit section timing and appearance</button><button type="button" class="button ghost small" data-browser-visuals>Open visual packs</button></div>';
    container.prepend(notice);
    notice.querySelector('[data-browser-visuals]').onclick = () => navigate('assets').catch(error => toast(error.message, true));
    notice.querySelector('[data-browser-timing]').onclick = () => {
      const owner = studioOwner(), sequence = studioProject();
      if (!owner || !sequence?.clips.length) return toast('Add an animation section first.', true);
      const baseline = JSON.stringify(sequence.clips), clips = JSON.parse(baseline);
      const fields = [['from','Start (seconds)',0,600],['to','End (seconds)',0.1,600],['zoom','Size (%)',10,400],['x','Left / right',-800,800],['y','Up / down',-800,800],['rotation','Rotation (degrees)',-180,180],['opacity','Opacity (%)',0,100]];
      dialog('Edit animation sections', '<label class="field">Section<select id="browser-clip-choice">' + clips.map((c, i) => '<option value="' + i + '">' + esc((i + 1) + ' · ' + c.label) + '</option>').join('') + '</select></label><div id="browser-clip-fields"></div><p id="browser-clip-error" role="alert"></p><button type="button" class="button" id="browser-clip-save">Save section changes</button>');
      const form = document.getElementById('browser-clip-fields'); let index = 0;
      const draw = () => {
        const clip = clips[index];
        form.innerHTML = '<div class="field-grid">' + fields.map(([key, label, min, max]) => '<label class="field">' + label + '<input type="number" step="0.1" min="' + min + '" max="' + max + '" data-browser-clip="' + key + '" value="' + clip[key] + '"></label>').join('') + '</div><div class="row">' + ['mirror','mute'].map(key => '<label class="check-item"><input type="checkbox" data-browser-clip="' + key + '"' + (clip[key] ? ' checked' : '') + '>' + (key === 'mirror' ? 'Mirror left and right' : 'Mute this section') + '</label>').join('') + '</div>';
        form.querySelectorAll('[data-browser-clip]').forEach(input => input.oninput = () => { clip[input.dataset.browserClip] = input.type === 'checkbox' ? input.checked : Number(input.value); });
      };
      document.getElementById('browser-clip-choice').onchange = e => { index = Number(e.target.value); draw(); };
      document.getElementById('browser-clip-save').onclick = async e => {
        e.target.disabled = true;
        try {
          if (studioOwner() !== owner || JSON.stringify(sequence.clips) !== baseline) throw Error('This animation changed while you were editing. Open its sections again.');
          const errors = ForgeMotion.validate(clips); if (errors.length) throw Error(errors[0]);
          ForgeMotion.compile(clips, { damage: false, music: sequence.music });
          sequence.clips = clips; studioChange(); await flushSave(); document.getElementById('dialog').close(); await renderStudio();
        } catch (error) { document.getElementById('browser-clip-error').textContent = error.message; e.target.disabled = false; }
      };
      draw();
    };
  };

  // Official assistant websites and the existing reviewed recipe flow need no API keys.
  renderAI = async function () {
    const providers = await Native.call('ai');
    main('<div class="section-heading"><div><h1>AI creation studio</h1><p>Use your existing AI subscription. Copy a prompt, send it in your chosen assistant, then paste its reply here to review changes.</p></div></div><section class="panel"><h2>Create and review</h2><p class="hint">Your AI account stays in its official app or website. This page uses copy and paste and does not ask for or store API keys. Review every suggested change before applying it.</p><div class="row"><button type="button" class="button" data-browser-ai="card">Create or edit a card</button><button type="button" class="button ghost" data-browser-ai="animation">Edit an animation</button><button type="button" class="button ghost" data-browser-ai="art">Create artwork</button></div></section><section class="panel"><h2>Open your assistant</h2><div class="ai-grid">' + providers.map(p => '<article class="ai-card"><h3>' + esc(p.name) + '</h3><p>Open its official website, sign in there, and paste your prompt.</p><button type="button" class="button ghost" data-ai="' + esc(p.id) + '">Open ' + esc(p.name) + '</button></article>').join('') + '</div></section>');
    document.querySelectorAll('[data-browser-ai]').forEach(button => button.onclick = () => ForgeAssistant.open({ task: button.dataset.browserAi }));
  };

  if (window.ForgeMovies) {
    const movieBrowser = ForgeMovies.mount;
    ForgeMovies.mount = async function (container) {
      await movieBrowser.apply(this, arguments);
      if (!container?.isConnected) return;
      const intro = container.querySelector('.movie-intro > p');
      if (intro) intro.textContent = 'Play VP9 movies directly. AV1 uses this browser’s native codecs when available; older movies and public HCA sound use the bundled local compatibility decoder when needed. Edit, trim, join, and export game movies here. Original files stay unchanged. Lossless quality verifies every edited YUV420 frame after decoding the encoded result. Encrypted sound requiring a game key reports its limit.';
      const refresh = container.querySelector('#movie-local-refresh'); if (refresh) refresh.hidden = false;
    };
  }

  // iPhone: suggest Add to Home Screen once (it also keeps your units from being cleared by Safari)
  const ios = /iPhone|iPad|iPod/.test(navigator.userAgent) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
  let told = false;
  try { told = localStorage.getItem("web-install-told") === "1"; } catch (e) {}
  if (!hosted && ios && !standalone && !told) {
    addEventListener("load", () => setTimeout(() => {
      const box = document.createElement("div");
      box.id = "web-install";
      box.setAttribute("role", "note");
      box.innerHTML = '<strong>Add it to your Home Screen</strong><p>Tap <b>Share</b> <span aria-hidden="true">⬆︎</span> then <b>Add to Home Screen</b>. It opens like an app and keeps an offline copy. Export your units to keep a portable copy of your work.</p><button type="button" class="button small">Got it</button>';
      document.body.append(box);
      box.querySelector("button").onclick = () => { try { localStorage.setItem("web-install-told", "1"); } catch (e) {} box.remove(); };
    }, 2500));
  }
})();
