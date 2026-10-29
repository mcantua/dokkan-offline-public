/* Default task-focused interface. Existing editor/data/export controllers remain authoritative. */
(function(root) {
  'use strict';
  const previous = {renderHome, renderSource, renderEditor, renderPreview, updateNav, navigate, action, updateBinding, createUnit, exportProject, importFile, toast};
  const route = [0, 1, 4, 8], names = ['Name', 'Power', 'Moves', 'Save'];
  let returning = 0, creating = null, exporting = null, importing = null;
  try { state.simple = localStorage.getItem('forge-layout') !== 'full'; } catch { state.simple = true; }
  if(state.simple)state.expert=false;
  const h = esc;
  function button(text, fn, kind='ghost') { const e=document.createElement('button'); e.type='button';e.className='button '+kind;e.textContent=text;e.onclick=()=>Promise.resolve().then(fn).catch(report);return e; }
  function report(error) { const message=error?.message||String(error);toast(message,true);const e=document.getElementById('simple-error');if(e){e.hidden=false;e.textContent=message;e.focus();} }
  function status() { return '<p class="simple-error" id="simple-error" role="alert" tabindex="-1" hidden></p>'; }
  function validFields() {
    const e=document.querySelector('#main [aria-invalid="true"], #main input:invalid');
    if(e){for(let p=e.parentElement;p;p=p.parentElement)if(p.tagName==='DETAILS')p.open=true;e.scrollIntoView({block:'center'});e.focus();e.reportValidity?.();throw Error(e.validationMessage||'Finish the highlighted field before continuing.');}
  }
  async function step(value) { validFields();await flushSave();state.step=value;renderEditor();window.scrollTo(0,0);document.querySelector('#simple-title')?.focus({preventScroll:true}); }
  function optional(label, value) {return button(label,()=>{returning=route.includes(state.step)?state.step:returning;return step(value);});}
  async function mode(simple) {
    validFields();await flushSave();state.simple=simple;
    if(simple){state.expert=false;localStorage.setItem('forge-expert','false');}
    localStorage.setItem('forge-layout',simple?'simple':'full');updateNav();
    if(state.view==='editor')renderEditor();else await navigate(state.view);
  }
  function tools() {
    dialog('What would you like to do?', '<p>You can create and save a unit without using these tools.</p><div id="simple-tools" class="simple-tool-grid"></div>');
    const area=document.getElementById('simple-tools');
    const items=[['Your saved units and imported patches','library'],['Animation editor','animations'],['Card art and battle poses',6],['Import or update game data','assets'],['Game movie browser','movies'],['Local practice combat','combat'],['AI assistants','ai']];
    for(const [label,view] of items)area.append(button(label,async()=>{
      if(view===6&&!state.project)throw Error('Create or open a unit first so your changes have somewhere to save.');
      document.getElementById('dialog').close();
      if(typeof view==='number'){state.view='editor';returning=0;await step(view);updateNav();}else await navigate(view);
    }));
    area.append(button('Show the full workspace',async()=>{document.getElementById('dialog').close();await mode(false);}));
  }
  function navigation() {
    document.documentElement.dataset.layout=state.simple?'simple':'full';document.documentElement.dataset.view=state.view;
    document.querySelectorAll('.simple-tools-nav').forEach(e=>e.hidden=!state.simple);
    if(!document.getElementById('simple-layout-toggle')){
      const e=button('',()=>mode(!state.simple),'ghost small');e.id='simple-layout-toggle';document.querySelector('.top-actions')?.prepend(e);
      document.querySelectorAll('.sidebar nav, .mobile-nav').forEach(nav=>{const b=button('More tools',tools);b.className='simple-tools-nav';nav.append(b);});
    }
    const toggle=document.getElementById('simple-layout-toggle');toggle.textContent=state.simple?'All tools':'Simple view';toggle.setAttribute('aria-label',state.simple?'Show all tools':'Return to the simple creator');
    document.querySelectorAll('.simple-tools-nav').forEach(e=>e.hidden=!state.simple);
    const help=document.getElementById('help');
    if(help){help.textContent=state.simple?'How to create a unit':'Eclipse documentation';if(!help.dataset.simpleHelp){help.dataset.simpleHelp='true';help.addEventListener('click',e=>{if(state.simple){e.preventDefault();e.stopImmediatePropagation();helpDialog();}},true);}}

  }
  function helpDialog(){dialog('Create your first unit','<ol class="simple-help"><li><strong>Choose a character.</strong> Its moves, abilities, and artwork give you a working starting point.</li><li><strong>Name it.</strong> Keep everything else if you want.</li><li><strong>Choose its power.</strong> Keep the original values or choose a preset. Extra abilities are optional.</li><li><strong>Choose its moves.</strong> Preview a move before changing it. The original moves stay assigned until you replace them.</li><li><strong>Save the game file.</strong> Export an Eclipse patch, then import that file in Dokkan Eclipse.</li></ol><p>Your editable design saves on this device. Exporting a patch is a separate step. You never need to enter game IDs or write scripts in this view.</p>');}
  updateNav=function(){previous.updateNav();navigation();if(state.simple)document.getElementById('breadcrumb').textContent=state.view==='editor'?'Your unit':state.view==='source'?'Choose a character':'Dokkan Unit Creator';};
  renderHome=function(){if(!state.simple)return previous.renderHome();navigation();
    main('<section class="simple-start"><p class="eyebrow">DOKKAN UNIT CREATOR</p><h1>What would you like to do?</h1><p>Create a new character from an existing unit. Its moves and abilities are already set up.</p><div class="simple-start-actions"><button class="button" data-action="new">Create a unit</button><button class="button ghost" data-action="import">Open a unit file</button></div></section>'+status()+'<section class="simple-saved"><h2>Your saved units</h2><p class="hint">Tap a unit to continue editing it.</p>'+(state.projects.length?'<div class="unit-grid">'+state.projects.map(p=>'<button class="unit-tile" data-open="'+h(p.key)+'"><div class="tile-body"><h3>'+h(p.name||'Your unit')+'</h3><p>'+h(Forge.rarities[p.rarity]||'Custom unit')+' · '+h(Forge.elements[p.element]||'')+'</p><span class="simple-open">Continue editing →</span></div></button>').join('')+'</div>':'<div class="simple-empty"><p>No saved units yet. Start with <strong>Create a unit</strong> above.</p></div>')+'</section><div class="simple-reassurance">New here? <button class="text-button" id="simple-getting-started">Show me how it works</button></div>');
    document.getElementById('simple-getting-started').onclick=helpDialog;
  };
  renderSource=function(){if(!state.simple)return previous.renderSource();navigation();
    main('<section class="simple-heading"><h1>Or pick a character</h1><p>Your unit starts as a copy of this character, with its moves and animations. You can change everything afterwards; the original card is never touched.</p></section><div class="source-controls"><label class="field simple-search">Character name<input id="source-query" type="search" placeholder="For example: Goku, Vegeta, Broly" value="'+h(state.sourceQuery)+'" autocomplete="off"></label><label class="field">Rarity<select id="source-rarity">'+selection([['','Any rarity'],...Forge.rarities.map((n,i)=>[i,n])],state.sourceRarity)+'</select></label></div>'+status()+'<p class="hint">Tap a character to start. (Pictures need Internet; everything else works offline.)</p><div id="source-results"><p role="status">Finding characters…</p></div><div class="row row-end" id="source-pages"></div>');
  };
  function fold(node,label,open=false){const d=document.createElement('details'),s=document.createElement('summary');d.className='simple-fold';d.open=open;s.textContent=label;node.before(d);d.append(s,node);return d;}
  function moveCards(form){let opened=false;form.querySelectorAll('article.effect-card').forEach(article=>{
    const title=article.querySelector('h3')?.textContent||'Move';
    article.querySelectorAll(':scope > .field-grid').forEach(e=>fold(e,'Change move name, power, or activation settings'));
    const first=!opened&&/Super Attack/i.test(title);if(first)opened=true;fold(article,title,first);
  });}
  renderEditor=function(){
    if(!state.simple)return previous.renderEditor();if(!state.project)return navigate('home');
    previous.renderEditor();navigation();const form=document.getElementById('editor-form');if(!form)return;
    const main=document.getElementById('main');main.classList.add('simple-editor');
    const index=route.indexOf(state.step),title=index>=0?names[index]:({2:'Team leader bonus',3:'Battle abilities',5:'Teams and links',6:'Appearance'}[state.step]||'Optional changes');
    const heading=main.querySelector('.section-heading');heading.querySelector('h1').textContent=index>=0?['Name your unit','Choose its power','Choose its moves','Save your unit'][index]:title;
    heading.querySelector('h1').id='simple-title';heading.querySelector('h1').tabIndex=-1;
    const description=heading.querySelector('p:not(.eyebrow)');if(description)description.textContent=index<0?'Optional: keep the original settings or change only what you want.':['Give your copy a name. Its original moves, art, and abilities are already included.','Keep the original power or choose a preset. You do not need to set up every ability.','These moves are already assigned. Preview them, or choose a different animation.','Save the file below, then import it in Dokkan Eclipse.'][index];
    const undo=Array.from(heading.querySelectorAll('[data-guide=undo],[data-guide=redo],[data-action=project-versions]'));heading.querySelectorAll('.row').forEach(e=>e.remove());const history=document.createElement('div');history.className='row';history.append(...undo);history.append(button('Help',helpDialog,'ghost small'),button('My units',()=>navigate('home'),'ghost small'));heading.append(history);
    const rail=main.querySelector('.stepper');rail.textContent='';rail.className='simple-steps';rail.setAttribute('aria-label','Creation steps');route.forEach((v,i)=>{const b=button((i+1)+'. '+names[i],()=>step(v));b.className='simple-step'+(state.step===v?' active':'');if(state.step===v)b.setAttribute('aria-current','step');rail.append(b);});
    const feedback=document.createElement('div');feedback.innerHTML=status()+'<p id="simple-feedback" role="status" class="notice" hidden></p>';rail.after(feedback);
    main.querySelectorAll('.guide-history').forEach(e=>e.remove());const preview=document.getElementById('unit-preview');if(preview)fold(preview,'See your unit',false);
    const sourcePanel=main.querySelector('#sparking-project-resources');if(sourcePanel)fold(sourcePanel,'Additional Sparking resources');
    const optionArea=document.createElement('section');optionArea.className='simple-options';
    if(state.step===0){form.querySelector('.panel > h2')?.remove();form.querySelector('.panel > .hint')?.remove();const name=form.querySelector('[data-bind="card:name"]');if(name)name.required=true;const notes=form.querySelector('[data-bind="notes"]')?.closest('label');if(notes)fold(notes,'Design notes (optional)');const hint=form.querySelector('.panel > .hint');if(hint)hint.textContent='Choose a name for your new unit. Everything else can stay as it is.';form.querySelector('[data-guide="help"]')?.remove();optionArea.append(optional('Change artwork or aura (optional)',6));}
    if(state.step===1){
      form.querySelectorAll(':scope > .panel > .field-grid').forEach(e=>fold(e,'Choose exact stats, rarity, and type'));
      const c=Forge.card(state.project),stats=document.createElement('p');stats.className='simple-stat-summary';stats.textContent='Health '+number(c.hp_max)+' · Attack '+number(c.atk_max)+' · Defense '+number(c.def_max);form.prepend(stats);
      optionArea.innerHTML='<h2>Extra changes (optional)</h2><p class="hint">Your character already has these settings. Only open a section if you want to change it.</p>';
      optionArea.append(optional('Team leader bonus',2),optional('Battle abilities',3),optional('Teams and links',5));
    }
    if(state.step===4)moveCards(form);
    if(state.step===3){form.querySelectorAll('article.effect-card').forEach(e=>fold(e,e.querySelector('h3')?.textContent||'Ability'));}
    if(state.step===6){form.querySelectorAll('details').forEach(e=>e.open=false);}
    if(state.step===8){
      const panel=form.querySelector('.panel'),grid=panel?.querySelector(':scope > .field-grid');if(grid)fold(grid,'File name, author, and description (optional)');
      const cards=form.querySelectorAll('.export-option');cards.forEach((e,i)=>{if(i===0){const b=e.querySelector('[data-export="eclp"]');if(b)b.textContent=state.project.actionHooks?.dodge?'Save Eclipse game files':'Save game file (.eclp)';const title=e.querySelector('h3');if(title)title.textContent='Save for Dokkan Eclipse';const text=e.querySelector('p');if(text)text.textContent='Includes your unit and its attached files. Import the saved file in Dokkan Eclipse to use it.';}else fold(e,'Save an editable backup (optional)');});
      const exportGrid=panel?.querySelector('.export-grid');if(exportGrid){const intro=panel.querySelector(':scope > .hint');if(intro)intro.after(exportGrid);}
      const success=panel?.querySelector('.notice.success');if(success)success.innerHTML='<strong>Basic settings look good.</strong><p>Saving also checks the active game database for conflicts.</p>';
      const warning=panel?.querySelector('.notice.error');if(warning){exportGrid?.before(warning);const fixes=document.createElement('div');fixes.className='row';const issues=Forge.validate(state.project).errors;if(issues.some(x=>/name/i.test(x)))fixes.append(button('Check the name',()=>step(0)));if(issues.some(x=>/HP|ATK|DEF|level|rarity|type/i.test(x)))fixes.append(button('Check power settings',()=>step(1)));if(fixes.childNodes.length)warning.append(fixes);}
      const how=document.createElement('section');how.className='simple-after-save';how.innerHTML='<h3>What happens next?</h3><ol><li>Tap <strong>Save game file</strong> and choose a folder on your phone.</li><li>Open <strong>Dokkan Eclipse</strong> and use its patch import option to select the saved file.</li><li>Return to <strong>My units</strong> whenever you want to edit this design again.</li></ol><p class="hint">Saving a design here does not install it in the game.</p>';if(state.project.actionHooks?.dodge||state.project.sharedActionsUpdateRequired){const note=document.createElement('p');note.className='hint';note.textContent='Custom Dodge can require a shared-actions file. Follow the export instructions for both files.';how.append(note);}form.append(how);
    }
    if(optionArea.childNodes.length)form.append(optionArea);if(exporting)main.querySelectorAll('[data-export]').forEach(e=>e.disabled=true);
    const footer=main.querySelector('.step-footer');footer.textContent='';
    if(state.step===0&&optionArea.childNodes.length)footer.after(optionArea);
    if(index<0){footer.append(button('Done — return to '+names[route.indexOf(returning)] ,()=>step(returning),'') );}
    else {footer.append(button(index?'Back':'My units',()=>index?step(route[index-1]):navigate('home')));const count=document.createElement('span');count.textContent=(index+1)+' of 4';footer.append(count);if(index<3)footer.append(button('Next: '+names[index+1],()=>step(route[index+1]),''));else footer.append(button('Back to my units',()=>navigate('home')));}
  };
  renderPreview=function(){previous.renderPreview();if(state.simple){const summary=document.querySelector('.simple-stat-summary');if(summary&&state.project){const c=Forge.card(state.project);summary.textContent='Health '+number(c.hp_max)+' · Attack '+number(c.atk_max)+' · Defense '+number(c.def_max);}const e=document.querySelector('#unit-preview .preview-body p');if(e&&state.project)e.textContent='Based on '+state.project.source.name;}};
  navigate=async function(view){await previous.navigate(view);navigation();if(state.simple&&state.project&&!['home','source','editor','animations'].includes(view)){
    // Only a way back to the unit you were editing; the bottom bar already reaches every screen.
    const main=document.getElementById('main'),bar=document.createElement('div');bar.className='simple-tool-return';bar.append(button('← Back to '+(Forge.card(state.project).name||'my unit'),()=>navigate('editor')));main.prepend(bar);
  }};
  action=async function(name){if(state.simple&&state.view==='editor'&&['step-next','step-prev'].includes(name)){const i=route.indexOf(state.step);return i<0?step(returning):name==='step-next'?step(route[Math.min(i+1,3)]):i?step(route[i-1]):navigate('home');}return previous.action(name);};
  updateBinding=function(el,type){
    if(state.simple&&el.type==='number'){
      el.setCustomValidity('');
      if(el.value.trim()===''||!Number.isFinite(Number(el.value))||!Number.isInteger(Number(el.value))||!el.validity.valid){el.setAttribute('aria-invalid','true');el.setCustomValidity('Enter a whole number within the shown range.');return;}
      el.setCustomValidity('');el.removeAttribute('aria-invalid');
    }
    const oldName=state.project&&Forge.card(state.project).name;
    if(el.dataset.bind==='card:name'&&state.project?.patch){const p=state.project;if(p.patch.name===oldName+' — Custom Unit'||p.patch.name===oldName)p.patch.name=el.value+' — Custom Unit';}
    const match=el.dataset.bind?.match(/^card:(hp|atk|def)_max$/);let adjusted=false;
    if(match&&state.project&&el.value.trim()!==''&&Number.isInteger(Number(el.value))&&Number(el.value)>=0){const stat=match[1],c=Forge.card(state.project);if(Number(c[stat+'_init'])>Number(el.value)){state.project.cardOverrides[stat+'_init']=Number(el.value);adjusted=true;}}
    previous.updateBinding(el,type);
    if(adjusted)toast('The starting '+match[1].toUpperCase()+' was also lowered so it does not exceed the maximum.');
  };
  createUnit=function(id){if(creating)return creating;creating=(async()=>{await flushSave();return previous.createUnit(id);})().finally(()=>creating=null);return creating;};
  importFile=function(...args){if(importing)return importing;importing=(async()=>{await flushSave();return previous.importFile(...args);})().finally(()=>importing=null);return importing;};
  exportProject=function(kind){if(exporting)return exporting;exporting=Promise.resolve().then(()=>{if(kind!=='json')validFields();return previous.exportProject(kind);}).catch(report).finally(()=>{exporting=null;document.querySelectorAll('[data-export]').forEach(e=>e.disabled=false);});document.querySelectorAll('[data-export]').forEach(e=>e.disabled=true);return exporting;};
  toast=function(message,error=false){previous.toast(message,error);if(state.simple&&state.view==='editor'){const node=document.getElementById('simple-feedback');if(node){node.hidden=false;node.textContent=message;node.className='notice'+(error?' error':'');}}};
  // The native activity starts boot after all deferred scripts load.
  navigation();
})(window);
