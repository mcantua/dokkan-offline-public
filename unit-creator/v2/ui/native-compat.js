/* Before an Eclipse export, add the game records Eclipse expects next to a unit's skills
 * (EZA routes, EX Super Attack options, transformation descriptions). Also upgrades units
 * that were saved by earlier versions of this app. */
(function() {
  "use strict";
  if (typeof exportProject !== "function" || !window.Forge || typeof Forge.hydrateNativeRecords !== "function") return;
  const prior = exportProject;
  exportProject = async function(kind, ...rest) {
    if (kind !== "json" && state.project && !state.project.awaken) {
      try {
        if (window.ForgeFormsUI && typeof ForgeFormsUI.active === "function" && ForgeFormsUI.active()) await ForgeFormsUI.leave("editor");
        const root = state.project, sparking = root.source && root.source.database === "sparking";
        const query = (options) => Native.call(sparking ? "querySparking" : "query", options);
        const schema = sparking ? (await Native.call("sparkingInfo")).schema || {} : state.info.schema;
        let changed = false;
        for (const member of [root, ...(root.formProjects || [])]) if (await Forge.hydrateNativeRecords(member, query, schema, { gameRecords: !sparking })) changed = true;
        if (changed && state.project === root) {
          scheduleSave();
          await flushSave();
        }
      } catch (error) {
        toast(error.message || String(error), true);
        return;
      }
    }
    return prior.call(this, kind, ...rest);
  };
})();
