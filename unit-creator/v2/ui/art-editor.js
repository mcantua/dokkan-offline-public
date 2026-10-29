"use strict";
window.ForgeArtEditor = (() => {
  const MAX_EDGE = 4096, MAX_PIXELS = 16e6, MAX_BYTES = 12 * 1024 * 1024;
  function label(role) {
    if (role.id.startsWith("animated:")) {
      const value = role.id.slice(9);
      if (/Images_card_\d+_character\.png$/.test(value)) return "Animated card · character layer";
      const index = /lwf_image(\d+)\.png$/.exec(value);
      return index ? "Animated card · image layer " + (Number(index[1]) + 1) : "Animated card · extra picture";
    }
    if (role.id.startsWith("extra:")) {
      const value = role.id.slice(6), language = value.startsWith("en/") ? " · English" : "";
      if (/sp(?:02)?_name/.test(value)) return "Super Attack name picture" + (/sp02/.test(value) ? " · second move" : "") + language;
      if (/sp(?:02)?_phrase/.test(value)) return "Super Attack phrase picture" + (/sp02/.test(value) ? " · second move" : "") + language;
      if (/_piece/.test(value)) return "Extra portrait layer";
      return "Extra card picture";
    }
    return role.label;
  }
  function bounds(width, height) {
    if (!Number.isInteger(width) || !Number.isInteger(height) || width < 1 || height < 1 || width > MAX_EDGE || height > MAX_EDGE || width * height > MAX_PIXELS) throw Error("Choose a picture up to 4096 pixels on each side and 16 million pixels in total.");
  }
  function bytes(base64) {
    if (typeof base64 !== "string" || base64.length > Math.ceil(MAX_BYTES / 3) * 4) throw Error("Choose an image of 12 MB or less.");
    const text = atob(base64), data = new Uint8Array(text.length);
    if (data.length > MAX_BYTES) throw Error("Choose an image of 12 MB or less.");
    for (let i = 0; i < text.length; i++) data[i] = text.charCodeAt(i);
    return data;
  }
  async function image(record) {
    bounds(record.width, record.height);
    const data = bytes(record.base64);
    if (!/^image\/(?:png|jpeg|webp|gif|bmp)$/.test(record.mime)) throw Error("Choose a PNG, JPEG, WebP, GIF, or BMP picture.");
    const picture = new Image();
    picture.src = "data:" + record.mime + ";base64," + record.base64;
    await new Promise((resolve, reject) => {
      picture.onload = resolve;
      picture.onerror = () => reject(Error("This picture could not be decoded. Try a different image."));
    });
    bounds(picture.naturalWidth, picture.naturalHeight);
    if (record.mime === "image/gif") {
      const still = document.createElement("canvas");
      still.width = picture.naturalWidth;
      still.height = picture.naturalHeight;
      still.getContext("2d").drawImage(picture, 0, 0);
      return { picture: still, data };
    }
    return { picture, data };
  }
  function fit(canvas, picture, width, height, { mode = "contain", x = 0.5, y = 0.5 } = {}) {
    bounds(width, height);
    const pictureWidth = picture.naturalWidth || picture.width, pictureHeight = picture.naturalHeight || picture.height;
    bounds(pictureWidth, pictureHeight);
    if (!["contain", "cover", "stretch"].includes(mode) || ![x, y].every((n) => typeof n === "number" && Number.isFinite(n) && n >= 0 && n <= 1)) throw Error("Choose valid picture fitting options.");
    canvas.width = width;
    canvas.height = height;
    const context = canvas.getContext("2d");
    if (!context) throw Error("Image editing is unavailable on this device.");
    context.clearRect(0, 0, width, height);
    context.imageSmoothingEnabled = true;
    context.imageSmoothingQuality = "high";
    let w = width, h = height;
    if (mode !== "stretch") {
      const scale = Math[mode === "cover" ? "max" : "min"](width / pictureWidth, height / pictureHeight);
      w = pictureWidth * scale;
      h = pictureHeight * scale;
    }
    context.drawImage(picture, (width - w) * x, (height - h) * y, w, h);
    return canvas;
  }
  function fitPortrait(canvas, picture, width, height) {
    const portrait = document.createElement('canvas');
    portrait.width = picture.naturalWidth || picture.width;
    portrait.height = Math.ceil((picture.naturalHeight || picture.height) * 0.5);
    portrait.getContext('2d').drawImage(picture, 0, 0);
    return fit(canvas, portrait, width, height, { mode: 'cover', x: 0.5, y: 0.2 });
  }
  async function open() {
    if (!state.project) throw Error("Create or open a unit first.");
    const project = state.project, key = project.key;
    let catalog = [], info, selection = null, source = null, selectedRole = "", offset = 0, query = "", request = 0, renderRequest = 0, working = false, editorBody = null;
    const connected = () => {
      var _a, _b, _c;
      return ((_a = state.project) == null ? void 0 : _a.key) === key && ((_b = editorBody) == null ? void 0 : _b.isConnected) && editorBody === document.querySelector("#game-art-body") && ((_c = document.querySelector("#dialog")) == null ? void 0 : _c.hasAttribute("open"));
    };
    dialog("Customize in-game artwork", '<div id="game-art-body"><p role="status">Finding the original character’s imported artwork…</p></div>');
    editorBody = document.querySelector("#game-art-body");
    const body = () => editorBody, read = (assetKey) => Native.call("readAsset", { key: assetKey, maxBytes: MAX_BYTES }), message = (text, error = false) => {
      if (connected()) {
        const node = body().querySelector("#game-art-status");
        if (node) {
          node.textContent = text;
          node.setAttribute("role", error ? "alert" : "status");
        }
      }
    };
    async function sourceFiles() {
      const result = [], sourceInfo = ForgeArt.inspect(project, []), ids = [...new Set([sourceInfo.sourceId, sourceInfo.bgSourceId].filter(Boolean))];
      for (const id of ids) {
        let complete = false;
        for (let page = 0; page < 200; page++) {
          const rows = await Native.call("assets", { query: String(id), offset: page * 500, limit: 500 });
          if (!connected()) return [];
          for (const row of rows) if (!result.some((existing) => existing.key === row.key)) result.push(row);
          if (rows.length < 500) {
            complete = true;
            break;
          }
        }
        if (!complete) throw Error("This artwork search reached 100,000 matching files. Use a smaller resource collection.");
      }
      return result;
    }
    function render() {
      var _a, _b, _c, _d;
      if (!connected()) return;
      ++renderRequest;
      body().innerHTML = '<p>Replace artwork used by your custom card in the game. The app copies the complete original art pack into your unit’s private namespace, keeping other characters unchanged.</p><p class="hint">This uses the original template’s artwork layout. Animation movies and baked character art keep their original contents. Eclipse gameplay and device rendering still require verification.</p><label class="field">Imported source artwork<select id="game-art-group">' + (info.groups.length > 1 ? '<option value="">Choose an imported build</option>' : "") + info.groups.map((value, i) => '<option value="' + esc(value) + '"' + (value === info.group ? " selected" : "") + ">" + esc(value === "saved-custom-artwork" ? "Saved unit artwork" : "Imported artwork pack " + (i + 1)) + "</option>").join("") + "</select></label>" + (info.missing.length ? '<div class="notice"><strong>More original resources are needed</strong><p>' + esc(info.group ? "Missing: " + info.missing.join(", ") : info.groups.length ? "Choose one complete imported build above." : "Import an Eclipse or resource build containing this character’s complete card, team portrait, and animated background assets.") + '</p><button type="button" class="button ghost" id="game-art-import-pack">Import source resources</button><button type="button" class="button ghost" id="game-art-get-originals">Get original artwork online</button></div>' : "") + '<p id="game-art-status" role="status" aria-live="polite"></p>' + (info.group && !info.missing.length ? '<label class="field">Artwork to change<select id="game-art-role">' + info.roles.map((role) => '<option value="' + esc(role.id) + '">' + esc(label(role)) + "</option>").join("") + '</select></label><div id="game-art-workspace"><p role="status">Loading the source frame…</p></div>' : "") + (project.artBinding ? '<p class="hint">Your current custom artwork is saved in this project. Restoring the original removes only the app’s private artwork attachments.</p><button type="button" class="button subtle" id="game-art-restore">Restore original game artwork</button>' : "");
      const group = body().querySelector("#game-art-group");
      if (!info.groups.length) group.disabled = true;
      group.onchange = () => {
        try {
          info = ForgeArt.inspect(project, catalog, { group: group.value || void 0 });
          selection = null;
          render();
        } catch (error) {
          message(error.message, true);
        }
      };
      (_a = body().querySelector("#game-art-import-pack")) == null ? void 0 : _a.addEventListener("click", () => run(async () => {
        var _a2;
        const result = await Native.call("import");
        if (!result || !result.kind) return;
        rememberImportResult(result);
        catalog = await sourceFiles();
        info = ForgeArt.inspect(project, catalog, { group: info.group || void 0 });
        render();
        if ((_a2 = result.warnings) == null ? void 0 : _a2.length) message("Some source archives could not be opened. Review Last import results in Game content.", true);
      }));
      (_b = body().querySelector("#game-art-get-originals")) == null ? void 0 : _b.addEventListener("click", () => run(getOriginals));
      (_c = body().querySelector("#game-art-role")) == null ? void 0 : _c.addEventListener("change", (event) => {
        selectedRole = event.target.value;
        renderRole().catch((error) => message(error.message, true));
      });
      (_d = body().querySelector("#game-art-restore")) == null ? void 0 : _d.addEventListener("click", () => run(async () => {
        ForgeArt.restore(project);
        scheduleSave();
        state.previewUrl = await projectPreviewUrl(project);
        await flushSave();
        renderEditor();
        document.querySelector("#dialog").close();
        toast("Original game artwork restored. Your imported pictures were kept.");
      }));
      if (info.group && !info.missing.length) {
        if (!info.roles.some((role) => role.id === selectedRole)) selectedRole = info.roles[0].id;
        body().querySelector("#game-art-role").value = selectedRole;
        renderRole().catch((error) => message(error.message, true));
      }
    }
    async function run(work) {
      if (working) return;
      working = true;
      body().querySelectorAll("button,select,input").forEach((e) => e.disabled = true);
      try {
        await work();
      } catch (error) {
        message(error.message || "Artwork could not be updated.", true);
      } finally {
        working = false;
        if (connected()) {
          body().querySelectorAll("button,select,input").forEach((e) => e.disabled = false);
          const apply2 = body().querySelector("#game-art-apply");
          if (apply2) apply2.disabled = !selection;
          const previous = body().querySelector("#game-art-prev"), next = body().querySelector("#game-art-next");
          if (previous) previous.disabled = offset === 0;
          if (next) next.disabled = next.dataset.more !== "true";
        }
      }
    }
    async function renderRole() {
      const token = ++renderRequest, role = info.roles.find((value) => value.id === selectedRole);
      ++request;
      selection = null;
      source = null;
      const pendingWorkspace = body().querySelector("#game-art-workspace");
      pendingWorkspace.removeAttribute('data-role');
      pendingWorkspace.innerHTML = '<p role="status">Loading this artwork layer…</p>';
      const original = await read(role.key), decoded = await image(original);
      if (!connected() || token !== renderRequest) return;
      source = { role, width: original.width, height: original.height };
      const workspace = body().querySelector("#game-art-workspace");
      workspace.dataset.role = role.id;
      workspace.innerHTML = '<p class="hint">' + esc(label(role)) + " · " + original.width + " × " + original.height + ' pixels. Your picture will be fitted automatically. Animated cards use separate layers; choose their animated layers as well when changing that artwork.</p><div class="game-art-frames"><figure><figcaption>Original frame</figcaption><img class="game-art-original" alt="Original ' + esc(label(role).toLowerCase()) + '" src="' + decoded.picture.src + '"></figure><figure><figcaption>Your fitted picture</figcaption><canvas id="game-art-canvas" role="img" aria-label="Preview of your fitted artwork"></canvas><p id="game-art-picture-name" class="hint">Choose a picture below.</p></figure></div><div class="field-grid"><label class="field">Picture fit<select id="game-art-fit"><option value="contain">Fit the whole picture · transparent margins</option><option value="cover">Fill the frame · crop edges</option><option value="stretch">Stretch to the frame</option></select></label><label class="field">Horizontal placement · <output id="game-art-x-value">Center</output><input id="game-art-x" type="range" min="0" max="1" step="0.01" value="0.5"><span class="hint">Left ↔ Right</span></label><label class="field">Vertical placement · <output id="game-art-y-value">Center</output><input id="game-art-y" type="range" min="0" max="1" step="0.01" value="0.5"><span class="hint">Top ↔ Bottom</span></label></div><div class="row"><button type="button" class="button ghost" id="game-art-import-picture">Import a picture</button><button type="button" class="button ghost" id="game-art-browse-toggle" aria-expanded="false">Choose an imported picture</button></div><p class="hint">Pictures up to 12 MB and 4096 pixels per side. GIF uses its first decoded frame. The fitted result is saved as PNG.</p><section id="game-art-browse" hidden><label class="field">Find an imported picture<input id="game-art-search" type="search" placeholder="Picture filename…"></label><button type="button" class="button ghost small" id="game-art-search-button">Find pictures</button><p id="game-art-picture-status" role="status"></p><div id="game-art-pictures"></div><div class="row"><button type="button" class="button ghost small" id="game-art-prev">Previous files</button><button type="button" class="button ghost small" id="game-art-next">Next files</button></div></section><label class="check-item"><input id="game-art-all-portraits" type="checkbox"' + (role.id === "character" ? " checked" : "") + '>Also update the character, team portrait and attack cut-ins</label><p class="hint">Portraits and cut-ins use a close crop of the upper half of your picture. Your selected layer keeps the fit shown above. You can adjust any portrait separately afterward.</p>' + (info.bgSourceId ? '<label class="check-item"><input id="game-art-static" type="checkbox" checked>Use my new still artwork instead of the inherited animated card background</label><p class="hint">This changes card artwork, not battle animations. Uncheck to keep the original animated card background.</p>' : '') + '<button type="button" class="button" id="game-art-apply" disabled>Apply artwork</button>';
      for (const id of ["fit", "x", "y"]) {
        const control = workspace.querySelector("#game-art-" + id);
        control.onchange = redraw;
        control.oninput = redraw;
      }
      workspace.querySelector("#game-art-browse-toggle").onclick = async (event) => {
        const section = workspace.querySelector("#game-art-browse");
        section.hidden = !section.hidden;
        event.target.setAttribute("aria-expanded", String(!section.hidden));
        if (!section.hidden) try {
          await browse();
        } catch (error) {
          message(error.message, true);
        }
      };
      workspace.querySelector("#game-art-search-button").onclick = () => {
        query = workspace.querySelector("#game-art-search").value;
        offset = 0;
        browse().catch((error) => message(error.message, true));
      };
      workspace.querySelector("#game-art-search").onkeydown = (event) => {
        if (event.key === "Enter") {
          event.preventDefault();
          workspace.querySelector("#game-art-search-button").click();
        }
      };
      workspace.querySelector("#game-art-prev").onclick = () => {
        offset = Math.max(0, offset - 40);
        browse().catch((error) => message(error.message, true));
      };
      workspace.querySelector("#game-art-next").onclick = () => {
        offset += 40;
        browse().catch((error) => message(error.message, true));
      };
      workspace.querySelector("#game-art-import-picture").onclick = () => run(async () => {
        var _a;
        const result = await Native.call("import");
        if (!(result == null ? void 0 : result.kind)) return;
        rememberImportResult(result);
        if ((_a = result.asset) == null ? void 0 : _a.image) await choose(result.asset);
        else {
          workspace.querySelector("#game-art-browse").hidden = false;
          workspace.querySelector("#game-art-browse-toggle").setAttribute("aria-expanded", "true");
          offset = 0;
          await browse();
          message("Files imported. Find and choose your picture below.");
        }
      });
      workspace.querySelector("#game-art-apply").onclick = () => run(apply);
      redraw();
    }
    function redraw() {
      if (!source || !connected()) return;
      const canvas = body().querySelector("#game-art-canvas");
      if (!canvas) return;
      for (const axis of ['x', 'y']) {
        const control=body().querySelector('#game-art-'+axis),output=body().querySelector('#game-art-'+axis+'-value'),percent=Math.round(Number(control.value)*100);
        if(output)output.textContent=percent===50?'Center':percent+'%';
        control.setAttribute('aria-valuetext',percent+'% from '+(axis==='x'?'left':'top'));
      }
      canvas.width = source.width;
      canvas.height = source.height;
      if (selection) {
        fit(canvas, selection.picture, source.width, source.height, { mode: body().querySelector("#game-art-fit").value, x: Number(body().querySelector("#game-art-x").value), y: Number(body().querySelector("#game-art-y").value) });
        body().querySelector("#game-art-picture-name").textContent = selection.name;
      }
      body().querySelector("#game-art-apply").disabled = !selection;
    }
    async function choose(asset) {
      selection = null;
      redraw();
      const loaded = await read(asset.key), decoded = await image(loaded);
      if (!connected()) return;
      selection = { ...decoded, key: asset.key, name: asset.name || "Imported picture" };
      redraw();
      message("Picture ready. Check its fit before applying it.");
    }
    async function browse() {
      const token = ++request, pending = body().querySelector("#game-art-browse");
      if (!pending) return;
      pending.querySelector("#game-art-picture-status").textContent = "Finding pictures…";
      pending.querySelector("#game-art-pictures").innerHTML = "";
      pending.querySelectorAll("#game-art-prev,#game-art-next").forEach(button => button.disabled = true);
      const rows = await Native.call("assets", { query, offset, limit: 41 });
      if (!connected() || token !== request) return;
      const pane = body().querySelector("#game-art-browse");
      if (!pane) return;
      const shown = rows.slice(0, 40), images = shown.filter((asset) => asset.image);
      pane.querySelector("#game-art-picture-status").textContent = (rows.length ? "Files " + (offset + 1) + "–" + (offset + shown.length) : "No matching files") + " · " + images.length + " pictures on this page";
      pane.querySelector("#game-art-pictures").innerHTML = images.length ? images.map((asset, i) => '<button type="button" class="button ghost small" data-art-picture="' + i + '" data-art-key="' + esc(asset.key) + '">' + esc(asset.name) + "</button>").join("") : '<p class="hint">Try a picture filename, import an image, or check the next page.</p>';
      pane.querySelector("#game-art-prev").disabled = !offset;
      pane.querySelector("#game-art-next").disabled = rows.length <= 40;
      pane.querySelector("#game-art-next").dataset.more = String(rows.length > 40);
      pane.querySelectorAll("[data-art-picture]").forEach((button) => button.onclick = () => run(() => choose(images[Number(button.dataset.artPicture)])));
    }
    async function getOriginals() {
      var _a;
      const original = ForgeArt.inspect(project, []), roots = [original.cardRoot.replace(/\/$/, ""), original.thumbRoot.replace(/\/$/, "")];
      if (original.bgSourceId) roots.push(original.bgRoot.replace(/\/$/, ""));
      const files = /* @__PURE__ */ new Map();
      let directories = 0, total = 0;
      for (const root of roots) {
        const queue = [root];
        while (queue.length) {
          const folder = queue.shift();
          if (++directories > 32) throw Error("This artwork pack has too many folders. Import a verified resource build instead.");
          message("Finding the original artwork…");
          const listing = await Native.call("browseAssets", { path: folder });
          if (!connected()) return;
          if (listing.error || !Array.isArray(listing.items) || !listing.items.length) throw Error("The original artwork is not available online. Import a complete authorized resource build instead.");
          for (const item of listing.items) {
            if (!Forge.safePath(item.path) || !item.path.startsWith(root + "/")) throw Error("The artwork listing contains an unexpected file location.");
            if (item.type === "directory") {
              queue.push(item.path);
              continue;
            }
            if (!/\.(png|lwf|json|fnt|txt|plist|bin|fsh|vsh)$/i.test(item.path)) continue;
            const size = Number(item.size);
            if (!Number.isSafeInteger(size) || size < 1 || size > MAX_BYTES) throw Error("An original artwork file exceeds the 12 MB editor limit. Import a verified resource build to keep its original files.");
            if (!files.has(item.path)) {
              total += size;
              files.set(item.path, item);
              if (files.size > 200 || total > 128 * 1024 * 1024) throw Error("This artwork pack exceeds the download limit. Import a verified resource build instead.");
            }
          }
        }
      }
      if (!files.size) throw Error("No complete original artwork was found. Import a verified resource build instead.");
      const group = "art-download-" + Date.now() + "-" + Math.random().toString(36).slice(2, 14).padEnd(8, "0");
      let completed = 0;
      for (const item of files.values()) {
        if (!connected()) return;
        message("Downloading original artwork: " + ++completed + " of " + files.size + " files.");
        const saved = await Native.call("downloadAsset", { path: item.path, group });
        if (!((_a = saved.key) == null ? void 0 : _a.startsWith(group + "/"))) throw Error("Update this app to save original artwork in its own protected collection.");
        if (Number(saved.size) !== Number(item.size)) throw Error("An original artwork file changed while downloading. Try again.");
      }
      catalog = await sourceFiles();
      if (!connected()) return;
      info = ForgeArt.inspect(project, catalog, { group });
      selection = null;
      render();
      message("Original artwork downloaded into a separate collection. Choose a layer and import your picture.");
    }
    async function apply() {
      if (!selection || !source) return;
      const chosen=selection, chosenSource=source, allPortraits=body().querySelector('#game-art-all-portraits').checked, staticBackground=body().querySelector('#game-art-static')?.checked === true;
      const primaryData = body().querySelector('#game-art-canvas').toDataURL('image/png').split(',')[1];
      bytes(primaryData);
      const roles=allPortraits?[chosenSource.role,...info.roles.filter(role=>role.id!==chosenSource.role.id&&['character','circle','cutin','sp_cutin','thumb'].includes(role.id))]:[chosenSource.role];
      const updates=[];
      for(const role of roles){
        if(!connected())throw Error('The unit changed. Reopen artwork editing.');
        const original=ForgeArt.pngInfo(bytes((await read(role.key)).base64));
        let data = primaryData;
        if (role.id !== chosenSource.role.id) {
          const canvas=document.createElement('canvas');
          const automaticPortrait = allPortraits && ['circle','cutin','sp_cutin','thumb'].includes(role.id);
          if (automaticPortrait) fitPortrait(canvas, chosen.picture, original.width, original.height);
          else fit(canvas,chosen.picture,original.width,original.height,{mode:body().querySelector('#game-art-fit').value,x:Number(body().querySelector('#game-art-x').value),y:Number(body().querySelector('#game-art-y').value)});
          data=canvas.toDataURL('image/png').split(',')[1];
        }
        bytes(data);
        const stored=await Native.call('storeAsset',{name:'custom-'+role.id+'.png',data});updates.push({role:role.id,key:stored.key});
      }
      const replaced=new Set(updates.map(value=>value.role)),replacements=[...ForgeArt.replacements(project).filter(value=>!replaced.has(value.role)),...updates], all=[...catalog,...replacements.map(value=>({key:value.key}))];
      const occupied = [];
      for (let page = 0; page < 200; page++) {
        const rows = await Native.call("query", { table: "cards", filters: { resource_id: info.resourceId }, offset: page * 5e3, limit: 5e3 });
        occupied.push(...rows.map((row) => row.resource_id));
        if (rows.length < 5e3) break;
      }
      for (const other of await Native.call("projects")) if (other.key !== key && !(window.ForgeFormsUI?.active() && other.key === window.ForgeFormsUI.root().key)) {
        if (Math.floor(Number(other.targetId) / 10) * 10 === info.resourceId) occupied.push(info.resourceId);
      }
      const plan = await ForgeArt.plan(project, all, { group: info.group, replacements, readAsset: async (assetKey) => bytes((await read(assetKey)).base64), storeDecoration: text => Native.call("storeDecoration", { text }), occupiedResourceIds: occupied });
      if (!connected()) throw Error("The selected unit changed. Reopen its artwork editor.");
      const previousPreview=project.artBinding&&Object.prototype.hasOwnProperty.call(project.artBinding,'previousPreviewKey')?project.artBinding.previousPreviewKey:(project.previewKey||null);
      ForgeArt.apply(project, plan);
      project.artBinding.previousPreviewKey=previousPreview;
      if(staticBackground){project.cardOverrides.bg_effect_id=null;project.artBinding.staticBackground=true;}
      const portrait=project.assets.find(a=>a.owner==='forge-card-art'&&a.path==='character/thumb/card_'+project.artBinding.resourceId+'_thumb.png');if(portrait)project.previewKey=portrait.key;
      scheduleSave();
      await flushSave();
      state.previewUrl = await projectPreviewUrl(project);
      renderEditor();
      document.querySelector("#dialog").close();
      toast(label(source.role) + " saved as private in-game artwork. Test the exported patch in Eclipse.");
    }
    try {
      catalog = await sourceFiles();
      if (!connected()) return;
      info = ForgeArt.inspect(project, catalog);
      render();
    } catch (error) {
      if (connected()) body().innerHTML = '<p class="notice" role="alert">' + esc(error.message) + "</p>";
    }
  }
  async function preview() {
    const project=state.project;
    if (!project?.artBinding) throw Error('Apply your in-game artwork first.');
    const assets=(project.assets||[]).filter(a=>a.owner==='forge-card-art');
    const animated=project.artBinding.staticBackground!==true && Number(Forge.card(project).bg_effect_id)>0;
    const file=(animated && assets.find(a=>a.path.startsWith('character/card_bg/') && a.path.endsWith('.lwf'))) || assets.find(a=>a.path.startsWith('character/card/') && a.path.endsWith('.lwf'));
    if (file) return Native.call('previewAnimation',{mode:'pack',resourcePath:file.path,assets,name:'My custom game card'});
    const info=ForgeArt.inspect(project,[],{group:'saved-custom-artwork'}),roles=['bg','effect','character'].map(id=>info.roles.find(role=>role.id===id));
    if (roles.some(role=>!role)) throw Error('Some card layers are missing. Open artwork editing to import the complete card artwork.');
    dialog('My custom card','<div id="game-art-preview"><p role="status">Preparing your artwork…</p></div>');
    const body=document.querySelector('#game-art-preview'),key=project.key;
    const connected=()=>body.isConnected && document.querySelector('#dialog').open && state.project?.key===key;
    try {
      const layers=await Promise.all(roles.map(async role=>{const record=await Native.call('readAsset',{key:role.key,maxBytes:MAX_BYTES});return {role:role.id,record,...await image(record)};}));
      if (!connected()) return;
      body.innerHTML='<canvas id="game-art-preview-canvas" role="img" aria-label="Your custom card artwork" style="display:block;width:100%;max-width:426px;height:auto;margin:0 auto"></canvas><label class="check-item"><input id="game-art-preview-effects" type="checkbox" checked>Show card effects</label><p class="hint">Your fitted artwork layers. Check the card frame and battle appearance in Eclipse.</p><button id="game-art-preview-edit" type="button" class="button ghost">Edit artwork</button>';
      const canvas=body.querySelector('canvas');canvas.width=layers[0].record.width;canvas.height=layers[0].record.height;
      // Cache the two still compositions. Repainting alpha layers after a
      // readback can change GPU/CPU rounding on older Android WebView.
      const context=canvas.getContext('2d');
      const snapshot=effects=>{context.clearRect(0,0,canvas.width,canvas.height);for(const layer of layers)if(layer.role!=='effect'||effects)context.drawImage(layer.picture,0,0,canvas.width,canvas.height);return context.getImageData(0,0,canvas.width,canvas.height);};
      const withEffects=snapshot(true),withoutEffects=snapshot(false);
      const draw=()=>context.putImageData(body.querySelector('#game-art-preview-effects').checked?withEffects:withoutEffects,0,0);
      body.querySelector('#game-art-preview-effects').onchange=draw;
      body.querySelector('#game-art-preview-edit').onclick=()=>{document.querySelector('#dialog').close();open().catch(error=>toast(error.message));};
      draw();
    } catch(error) {
      if (!connected()) return;
      body.innerHTML='<p role="alert"></p><button type="button" class="button">Try again</button>';
      body.querySelector('p').textContent=error.message||'Your artwork could not be loaded.';
      body.querySelector('button').onclick=()=>preview().catch(error=>toast(error.message));
    }
  }
  return { open, preview, fit, fitPortrait, bounds, bytes, image };
})();
