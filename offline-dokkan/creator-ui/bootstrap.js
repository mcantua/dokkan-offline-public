/* Load the unchanged shared screen controllers only after native master references
 * are ready. The staged app.js startup is deferred until every controller exists. */
(async function () {
  'use strict';
  try {
    const info = await window.OfflineCreatorHost.ready;
    const load = source => new Promise((resolve, reject) => { const script = document.createElement('script');script.src = source;script.async = false;script.onload = resolve;script.onerror = () => reject(Error('The Creator screen could not load: ' + source));document.head.append(script); });
    const fullTools = info.offlineCreator?.originalClientMode === true;
    if (fullTools && !window.webkit?.messageHandlers?.ForgeHost) throw Error('The complete same-save Creator tools were not admitted.');
    const response = await fetch('ui-scripts.json');
    if (!response.ok) throw Error('The shared Creator script manifest is unavailable.');
    const scripts = await response.json();
    if (!Array.isArray(scripts) || scripts.length > 200 || scripts.some(path => typeof path !== 'string' || !/^[a-zA-Z0-9_./-]+\.js$/.test(path) || path.split('/').some(part => !part || part === '.' || part === '..'))) throw Error('The shared Creator script manifest is invalid.');
    for (const source of scripts) {
      await load(source);
      if (source === 'compat.js' && fullTools) {
        const toolsResponse = await fetch('ios-tools-scripts.json');if (!toolsResponse.ok) throw Error('The native Creator tools manifest is unavailable.');
        const tools = await toolsResponse.json();
        if (!Array.isArray(tools) || tools.length > 32 || tools.some(path => !/^(web\/|data\/)?[a-z0-9-]+\.js$/.test(path))) throw Error('The native Creator tools manifest is invalid.');
        for (const path of tools) await load(path);
      }
    }
    if (fullTools) {
      await load('web/ios-ui.js');Native.canConvertOnline = () => false;
      const style = document.createElement('link');style.rel = 'stylesheet';style.href = 'web/ios.css';document.head.append(style);
    }
    await boot();
  } catch (error) {
    window.__forgeWorkspaceStartup = 'failed';
    const main = document.getElementById('main'); main.replaceChildren();
    const panel = document.createElement('section'), title = document.createElement('h1'), message = document.createElement('p'); panel.className = 'panel'; title.textContent = 'Could not open the Creator'; message.textContent = error.message || String(error); panel.append(title, message); main.append(panel);
  }
})();
