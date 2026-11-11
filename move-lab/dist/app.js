import {seed,STORAGE_KEY,duration,repeat,schedule,validateState} from './core.js';
const $=id=>document.getElementById(id);
const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
let state=seed(),storageOK=true,toastTimer;
try{const saved=localStorage.getItem(STORAGE_KEY);if(saved)state=validateState(JSON.parse(saved));}catch{storageOK=false;}
const selected=()=>state.moves.find(m=>m.id===state.selectedId);
const fixed=(v,n=2)=>Number(v.toFixed(n)).toString();
const time=v=>state.unit==='frames'?`${fixed(v*60,1)}f`:`${v.toFixed(2)}s`;
const fmt=v=>Number.isInteger(v)?String(v):fixed(v,1);
function toast(message){$('toast').textContent=message;$('toast').classList.add('show');clearTimeout(toastTimer);toastTimer=setTimeout(()=>$('toast').classList.remove('show'),3200);}
function save(){try{localStorage.setItem(STORAGE_KEY,JSON.stringify(state));storageOK=true;}catch{storageOK=false;} $('save-status').innerHTML=`<span class="dot" style="${storageOK?'':'background:#eaa89f'}"></span> ${storageOK?'Saved in this browser':'Not saved · export a backup'}`;}
function library(){
  const q=$('search').value.toLowerCase();
  const moves=state.moves.filter(m=>m.name.toLowerCase().includes(q));
  $('move-count').textContent=String(state.moves.length).padStart(2,'0');$('compare-count').textContent=state.moves.length;
  $('move-list').innerHTML=moves.length?moves.map((m,i)=>`<button class="move-card ${m.id===state.selectedId?'selected':''}" data-select="${esc(m.id)}" aria-pressed="${m.id===state.selectedId}"><span class="move-icon">${m.source==='current'?'Ⅰ':String(state.moves.indexOf(m)+1).padStart(2,'0')}</span><span><span class="move-card-name">${esc(m.name)}</span><span class="move-card-meta"><b>${fmt(m.damage)} DMG</b> <span> / </span> ${time(duration(m))}</span></span></button>`).join(''):'<div class="empty-state">No matching moves.</div>';
  $('move-list').querySelectorAll('[data-select]').forEach(b=>b.onclick=()=>{state.selectedId=b.dataset.select;save();render();});
  $('new-move').disabled=state.moves.length>=40;
}
function linkOptions(){
  const m=selected();
  $('link-options').innerHTML=state.moves.map(n=>`<label class="link-chip"><input type="checkbox" data-link="${esc(n.id)}" ${m.links.includes(n.id)?'checked':''}><span>${esc(n.name)}</span></label>`).join('');
  $('link-options').querySelectorAll('input').forEach(el=>el.onchange=()=>{m.links=el.checked?[...m.links,el.dataset.link]:m.links.filter(id=>id!==el.dataset.link);save();derived();});
}
function editor(){
  const m=selected(); $('move-name').value=m.name;
  for(const k of ['damage','windup','active','recovery','cooldown'])$(k).value=m[k];
  $('source-badge').textContent=m.source==='current'?'CURRENT MOVE':'DESIGN EXAMPLE';$('source-badge').classList.toggle('example',m.source!=='current');
  $('seed-note').textContent=m.source==='current'?'Seeded from your 0.08s windup, 0.10s active & 0.4s cooldown. Damage (10 HP) and recovery (0.18s) start as editable estimates.':'An editable design example. Tune these values to explore your combat system.';
  $('delete').disabled=state.moves.length===1;$('duplicate').disabled=state.moves.length>=40;$('field-error').textContent='';
  linkOptions();
}
function preview(){
  const m=selected(),d=duration(m),r=repeat(m),scale=Math.max(d,m.cooldown,.01);
  $('cycle-time').innerHTML=state.unit==='frames'?`${fixed(d*60,1)}<span>f</span>`:`${d.toFixed(2)}<span>s</span>`;
  $('first-hit').textContent=time(m.windup);$('repeat-time').textContent=time(r);
  $('single-timeline').innerHTML=`<div class="single-axis"><span>${time(0)}</span><span>${time(scale)}</span></div><div class="single-bar">${['windup','active','recovery'].map(k=>`<div class="phase ${k}" style="width:${m[k]/scale*100}%" title="${k}: ${time(m[k])}">${m[k]/scale>.15?time(m[k]):''}</div>`).join('')}<div class="cooldown-marker" style="left:${m.cooldown/scale*100}%" title="Cooldown ready: ${time(m.cooldown)}"></div></div><div class="single-cooldown">↳ cooldown ready at ${time(m.cooldown)}</div>`;
  const gap=Math.max(0,m.cooldown-d);
  $('move-insight').innerHTML=gap>1e-8?`Cooldown adds <b>${time(gap)}</b> after recovery before this move can repeat.`:d>0?`Recovery ends at <b>${time(d)}</b>. Cooldown is ready by then.`:'Set timing above zero to compare move speed.';
  $('add-selected').disabled=state.combo.length>=20;
}
function comparison(){
  const max=Math.max(.01,...state.moves.map(duration));
  $('comparison-body').innerHTML=state.moves.map(m=>`<tr><td><button data-edit="${esc(m.id)}">${esc(m.name)} <span style="color:#777084">↗</span></button></td><td>${fmt(m.damage)} HP</td><td>${time(m.windup)}</td><td>${time(m.active)}</td><td>${time(m.recovery)}</td><td>${time(m.cooldown)}</td><td>${time(duration(m))}</td><td>${time(repeat(m))}</td><td><div class="table-bar" aria-label="${esc(m.name)} timing: windup ${time(m.windup)}, active ${time(m.active)}, recovery ${time(m.recovery)}">${['windup','active','recovery'].map(k=>`<span class="phase ${k}" style="width:${m[k]/max*100}%" title="${k}: ${time(m[k])}"></span>`).join('')}</div></td></tr>`).join('');
  $('comparison-body').querySelectorAll('[data-edit]').forEach(b=>b.onclick=()=>{state.selectedId=b.dataset.edit;setTab('studio');save();render();$('move-name').focus();});
}
function combo(){
  const result=schedule(state.moves,state.combo,state.useLinks);const plain=schedule(state.moves,state.combo,false);
  const previous=$('combo-select').value;
  $('combo-select').innerHTML=state.moves.map(m=>`<option value="${esc(m.id)}">${esc(m.name)}</option>`).join('');if(state.moves.some(m=>m.id===previous))$('combo-select').value=previous;
  $('use-links').checked=state.useLinks;
  $('combo-chain').innerHTML=result.rows.length?result.rows.map((r,i)=>`<div class="combo-step"><div class="combo-step-top"><span class="step-number">${String(i+1).padStart(2,'0')} ${r.canceled?'· LINK':''}</span><button class="step-remove" data-remove="${i}" aria-label="Remove step ${i+1}: ${esc(r.move.name)}">×</button></div><strong title="${esc(r.move.name)}">${esc(r.move.name)}</strong><div class="step-bottom"><span class="step-damage">${fmt(r.move.damage)} HP</span><div class="step-controls"><button data-left="${i}" ${i===0?'disabled':''} aria-label="Move step ${i+1} earlier">←</button><button data-right="${i}" ${i===result.rows.length-1?'disabled':''} aria-label="Move step ${i+1} later">→</button></div></div></div>`).join(''):'<div class="empty-state">Your next combo starts here. Add a move below.</div>';
  $('combo-chain').querySelectorAll('[data-remove]').forEach(b=>b.onclick=()=>{state.combo.splice(+b.dataset.remove,1);save();combo();});
  const reorder=(i,j)=>{[state.combo[i],state.combo[j]]=[state.combo[j],state.combo[i]];save();combo();};
  $('combo-chain').querySelectorAll('[data-left]').forEach(b=>b.onclick=()=>reorder(+b.dataset.left,+b.dataset.left-1));
  $('combo-chain').querySelectorAll('[data-right]').forEach(b=>b.onclick=()=>reorder(+b.dataset.right,+b.dataset.right+1));
  $('combo-damage').innerHTML=`${fmt(result.damage)}<span>HP</span>`;$('combo-duration').textContent=time(result.total);$('combo-dps').textContent=fixed(result.dps,1);
  const full=state.combo.length>=20;$('append-combo').disabled=full;$('add-selected').disabled=full;$('clear-combo').disabled=!state.combo.length;$('combo-limit').textContent=`${state.combo.length} / 20 steps`;
  const savings=plain.total-result.total;
  $('combo-feedback').textContent=[savings>1e-8?`Links save ${time(savings)}`:state.useLinks?'Links enabled':'Links disabled',result.wait>1e-8?`${time(result.wait)} cooldown wait`:'No cooldown wait'].join(' · ');
  if(!result.rows.length){$('combo-timeline').innerHTML='<div class="empty-state">Add a move to see its timing.</div>';return;}
  const scale=Math.max(.01,result.total);
  const segment=(start,len,cls,title,label='')=>len>1e-9?`<span class="timeline-segment ${cls}" style="left:${start/scale*100}%;width:${len/scale*100}%" title="${esc(title)}">${label}</span>`:'';
  $('combo-timeline').innerHTML=`<div class="timeline-grid"><div class="time-axis">${[0,.25,.5,.75,1].map(v=>`<span style="left:${v*100}%">${time(v*scale)}</span>`).join('')}</div>${result.rows.map((r,i)=>{
    const next=result.rows[i+1];const recoveryEnd=r.canceled?Math.min(r.end,next.start):r.end;
    const prev=result.rows[i-1];const waitStart=prev?Math.min(r.start,prev.end):0;
    return `<div class="timeline-row"><span class="timeline-name" title="${esc(r.move.name)}"><span>${String(i+1).padStart(2,'0')}</span>${esc(r.move.name)}</span><div class="timeline-track">${r.wait>0?segment(waitStart,r.start-waitStart,'wait',`Cooldown wait until ${time(r.start)}`):''}${segment(r.start,r.move.windup,'windup',`Windup: ${time(r.start)}–${time(r.hit)}`)}${segment(r.hit,r.move.active,'active',`Active: ${time(r.hit)}–${time(r.hit+r.move.active)} · ${fmt(r.move.damage)} HP`,r.move.active/scale>.055?fmt(r.move.damage):'')}${segment(r.hit+r.move.active,recoveryEnd-r.hit-r.move.active,'recovery',`Recovery${r.canceled?' partially canceled by link':''}`)}<span class="timeline-hit" style="left:${r.hit/scale*100}%" title="First hit at ${time(r.hit)}"></span></div></div>`;
  }).join('')}</div>`;
}
function units(){document.querySelectorAll('[data-unit]').forEach(b=>b.setAttribute('aria-pressed',b.dataset.unit===state.unit));}
function derived(){preview();combo();comparison();units();}
function render(){library();editor();derived();}
function append(id){if(state.combo.length>=20)return;state.combo.push(id);save();combo();}
function setTab(name){for(const n of ['studio','compare']){const active=n===name;$(n+'-tab').setAttribute('aria-selected',active);$(n+'-tab').tabIndex=active?0:-1;$(n+'-panel').hidden=!active;}}
async function confirmAction(title,message,action='Confirm'){
  $('confirm-title').textContent=title;$('confirm-message').textContent=message;$('confirm-action').textContent=action;
  const dlg=$('confirm-dialog');dlg.returnValue='cancel';dlg.showModal();
  return new Promise(resolve=>dlg.addEventListener('close',()=>resolve(dlg.returnValue==='confirm'),{once:true}));
}
for(const k of ['damage','windup','active','recovery','cooldown'])$(k).addEventListener('input',e=>{
  const input=e.target;
  if(!input.checkValidity() || !Number.isFinite(input.valueAsNumber)){$('field-error').textContent=k==='damage'?'Damage: 0–1000 HP.':'Timing: 0–10 seconds.';return;}
  selected()[k]=input.valueAsNumber;$('field-error').textContent='';save();library();derived();
});
$('move-name').oninput=e=>{if(!e.target.value.trim()){$('field-error').textContent='Give this move a name.';return;}selected().name=e.target.value.trim();$('field-error').textContent='';save();library();linkOptions();combo();comparison();};
$('move-name').onblur=()=>{$('move-name').value=selected().name;};
for(const k of ['damage','windup','active','recovery','cooldown'])$(k).addEventListener('blur',e=>{if(!e.target.checkValidity()){e.target.value=selected()[k];$('field-error').textContent='Invalid value reverted.';}});
$('search').oninput=library;
$('new-move').onclick=()=>{if(state.moves.length>=40)return;const m={id:'move_'+crypto.randomUUID(),name:'New move',damage:10,windup:.1,active:.1,recovery:.2,cooldown:.4,links:[],source:'example'};state.moves.push(m);state.selectedId=m.id;$('search').value='';setTab('studio');save();render();$('move-name').focus();$('move-name').select();};
$('duplicate').onclick=()=>{if(state.moves.length>=40)return;const m={...selected(),id:'move_'+crypto.randomUUID(),name:(selected().name.slice(0,34)+' copy'),links:[...selected().links],source:'example'};state.moves.push(m);state.selectedId=m.id;$('search').value='';save();render();toast('Move duplicated.');};
$('delete').onclick=async()=>{if(state.moves.length===1)return;const id=state.selectedId,name=selected().name;if(!await confirmAction('Delete move?',`Delete “${name}” from the library, combo steps, and follow-up links?`,'Delete move'))return;state.moves=state.moves.filter(m=>m.id!==id);state.moves.forEach(m=>m.links=m.links.filter(x=>x!==id));state.combo=state.combo.filter(x=>x!==id);state.selectedId=state.moves[0].id;save();render();toast('Move deleted.');};
$('add-selected').onclick=()=>{append(state.selectedId);toast('Added to combo.');};$('append-combo').onclick=()=>append($('combo-select').value);
$('clear-combo').onclick=()=>{state.combo=[];save();combo();};
$('use-links').onchange=e=>{state.useLinks=e.target.checked;save();combo();};
document.querySelectorAll('[data-unit]').forEach(b=>b.onclick=()=>{state.unit=b.dataset.unit;save();library();derived();});
for(const n of ['studio','compare'])$(n+'-tab').onclick=()=>setTab(n);
document.querySelector('.tabs').onkeydown=e=>{if(['ArrowLeft','ArrowRight','Home','End'].includes(e.key)){e.preventDefault();const next=e.key==='Home'?'studio':e.key==='End'?'compare':$('studio-tab').getAttribute('aria-selected')==='true'?'compare':'studio';setTab(next);$(next+'-tab').focus();}};
$('export').onclick=()=>{const blob=new Blob([JSON.stringify(state,null,2)],{type:'application/json'}),url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download='veilbound-move-lab.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);toast('Lab data exported.');};
$('import').onclick=()=>$('import-file').click();
$('import-file').onchange=async e=>{const file=e.target.files[0];e.target.value='';if(!file)return;try{if(file.size>250000)throw Error('File is too large. Use a lab JSON smaller than 250 KB.');const incoming=validateState(JSON.parse(await file.text()));if(!await confirmAction('Import lab data?',`Replace this browser’s current moves and combo with ${incoming.moves.length} imported moves? Export first if you want a backup.`,'Import data'))return;state=incoming;$('search').value='';save();render();toast('Lab data imported.');}catch(err){toast('Import failed: '+err.message);}};
$('reset').onclick=async()=>{if(!await confirmAction('Reset example data?','This replaces your current moves and combo with the original examples. Export first to keep a backup.','Reset data'))return;state=seed();$('search').value='';save();render();toast('Original examples restored.');};
render();save();
