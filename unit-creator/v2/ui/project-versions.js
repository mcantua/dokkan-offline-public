/* Recovery reconstruction: backend integration must be restored before packaging. */
(function (global) {
  'use strict';
  const escape = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));

  let sessionOpen = false;
  async function open(options) {
    if (sessionOpen) return;
    sessionOpen = true;
    try { return await show(options); }
    catch (error) { sessionOpen = false; throw error; }
  }
  async function show(options) {
    const {key, call, dialog, getCurrentKey, onRestore} = options;
    if (!key || getCurrentKey() !== key) throw new Error('Open a saved unit first.');
    const previousFocus = document.activeElement;
    let listing = await call('listProjectVersions', {key});
    if (getCurrentKey() !== key) { sessionOpen = false; return; }
    let active = true, working = false, generation = 0;
    let modal, closeButton, savedCloseDisabled;
    const current = () => active && modal.open && getCurrentKey() === key;
    const content = () => document.querySelector('#dialog-content');
    const status = (message, error = false) => {
      const node = content().querySelector('[data-version-status]');
      if (node) { node.textContent = message; node.setAttribute('role', error ? 'alert' : 'status'); }
    };
    const guard = () => { if (!current()) throw new Error('This unit is no longer open.'); };
    const setWorking = value => {
      working = value;
      modal.setAttribute('aria-busy', String(value));
      content().querySelectorAll('button,input').forEach(node => { node.disabled = value; });
      closeButton.disabled = value || savedCloseDisabled;
    };
    async function task(message, operation) {
      if (working || !current()) return;
      const token = generation;
      setWorking(true); status(message);
      try { await operation(); }
      catch (error) { if (current() && token === generation) status(error.message, true); }
      finally { if (active) setWorking(false); }
    }
    function cleanup() {
      active = false; sessionOpen = false; generation++;
      modal.removeEventListener('cancel', preventBusyClose);
      modal.removeEventListener('close', cleanup);
      closeButton.removeEventListener('click', preventBusyClose, true);
      closeButton.disabled = savedCloseDisabled;
      modal.removeAttribute('aria-busy');
      const focusTarget = previousFocus?.isConnected ? previousFocus : document.querySelector('[data-action="project-versions"]');
      focusTarget?.focus();
    }
    function preventBusyClose(event) {
      if (working) { event.preventDefault(); event.stopImmediatePropagation(); }
    }
    const footer = '<p class="hint">Up to 10 saved versions and 40 MB per unit are kept on this device. Referenced files must remain on this device. Export your project for a portable backup.</p><p data-version-status role="status" aria-live="polite"></p>';
    function renderList() {
      generation++;
      const rows = Array.isArray(listing.versions) ? listing.versions : [];
      dialog('Saved versions', '<p>Keep named copies of your design, then review one before restoring it.</p><label class="field">Version name<input id="version-label" maxlength="80" placeholder="For example: Original design" autocomplete="off"></label><button class="button" id="save-named-version">Save this design</button>' + (rows.length ? '<ul class="version-list">' + rows.map((row, index) => '<li><strong>' + escape(row.label) + '</strong><p class="hint">' + escape(new Date(row.createdAt).toLocaleString()) + '</p><button class="button ghost small" data-version-review="' + index + '">Review version</button></li>').join('') + '</ul>' : '<p>No versions saved yet.</p>') + footer);
      document.querySelector('#version-label').focus();
      document.querySelector('#save-named-version').onclick = () => {
        const label = document.querySelector('#version-label').value.trim();
        if (!label) { status('Give this version a short name.', true); return; }
        task('Saving this version on your device…', async () => {
          guard();
          const result = await call('saveProjectVersion', {key, label, expectedCurrentRevision: listing.currentRevision});
          guard();
          if (result?.saved !== true) throw new Error('Saving this version could not be confirmed.');
          listing = await call('listProjectVersions', {key}); guard(); renderList();
          status('Version saved on this device.');
        });
      };
      content().querySelectorAll('[data-version-review]').forEach(button => {
        button.onclick = () => task('Opening this saved design…', async () => {
          const row = rows[Number(button.dataset.versionReview)];
          guard();
          const project = await call('loadProjectVersion', {key, versionKey:row.versionKey});
          guard(); renderReview(row, project);
        });
      });
    }
    function renderReview(row, project) {
      generation++;
      // Show the design's own name and stats (card overrides), not the untouched source card row.
      const base = project?.tables?.cards?.[0], card = base ? Object.assign({}, base, project.cardOverrides || {}) : null;
      if (!card || project.key !== key) throw new Error('This version does not belong to the open unit.');
      const stats = ['hp','atk','def'].map(stat => '<span>' + stat.toUpperCase() + ': ' + escape(card[stat + '_max']) + '</span>').join(' · ');
      dialog('Review saved version', '<h3 tabindex="-1" id="version-review-title">' + escape(row.label) + '</h3><p>' + escape(new Date(row.createdAt).toLocaleString()) + '</p><p><strong>' + escape(card.name) + '</strong></p><p>' + stats + '</p>' + (project.notes ? '<p class="version-notes">' + escape(String(project.notes).slice(0,1200)) + '</p>' : '') + '<p>Using this version replaces the open design. A safety copy of your current design will be saved first.</p><div class="row"><button class="button" id="restore-named-version">Use this version</button><button class="button ghost" id="versions-back">Back to versions</button></div>' + footer);
      document.querySelector('#version-review-title').focus();
      document.querySelector('#versions-back').onclick = () => { if (!working && current()) renderList(); };
      document.querySelector('#restore-named-version').onclick = () => task('Saving a safety copy and restoring your design…', async () => {
        guard();
        const result = await call('restoreProjectVersion', {key,versionKey:row.versionKey,expectedCurrentRevision:listing.currentRevision});
        guard();
        if (result?.saved !== true || !result.project) throw new Error('Restoring this version could not be confirmed.');
        // The native restore committed already: immediately adopt its returned project.
        await onRestore(result.project);
        modal.close();
      });
    }
    renderList();
    modal = document.querySelector('#dialog');
    closeButton = document.querySelector('#dialog-close');
    savedCloseDisabled = closeButton.disabled;
    modal.addEventListener('cancel', preventBusyClose);
    modal.addEventListener('close', cleanup);
    closeButton.addEventListener('click', preventBusyClose, true);
  }
  global.ForgeProjectVersions = Object.freeze({open});
})(window);
