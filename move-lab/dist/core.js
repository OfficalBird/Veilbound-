export const STORAGE_KEY = 'veilbound-move-lab-v1';
export const seed = () => ({
  version: 1, unit: 'seconds', useLinks: true,
  selectedId: 'light', combo: ['light','light','heavy'],
  moves: [
    {id:'light',name:'Light attack',damage:10,windup:0.08,active:0.10,recovery:0.18,cooldown:0.4,links:['light','heavy'],source:'current'},
    {id:'heavy',name:'Heavy slash',damage:18,windup:0.16,active:0.12,recovery:0.28,cooldown:0.65,links:['rising'],source:'example'},
    {id:'rising',name:'Rising cut',damage:14,windup:0.12,active:0.15,recovery:0.30,cooldown:0.60,links:[],source:'example'}
  ]
});
export const duration = m => m.windup+m.active+m.recovery;
export const repeat = m => Math.max(duration(m),m.cooldown);
export function schedule(moves,ids,useLinks=true) {
  const byId=new Map(moves.map(m=>[m.id,m]));
  const starts=new Map(); const rows=[];
  for (const id of ids) {
    const move=byId.get(id); if(!move) continue;
    const prev=rows.at(-1);
    const linked=!!(prev && useLinks && prev.move.links.includes(id));
    const earliest=prev ? prev.start+(linked?prev.move.windup+prev.move.active:duration(prev.move)) : 0;
    const ready=starts.has(id)?starts.get(id)+move.cooldown:0;
    const start=Math.max(earliest,ready);
    const row={move,start,hit:start+move.windup,end:start+duration(move),wait:Math.max(0,start-(prev?prev.end:0)),linked};
    if(prev) prev.canceled=linked && start<prev.end-1e-9;
    rows.push(row);starts.set(id,start);
  }
  const damage=rows.reduce((s,r)=>s+r.move.damage,0);
  const total=rows.at(-1)?.end||0;
  return {rows,damage,total,dps:total?damage/total:0,wait:rows.reduce((s,r)=>s+r.wait,0)};
}
export function validateState(input) {
  if(!input || input.version!==1 || !Array.isArray(input.moves) || input.moves.length<1 || input.moves.length>40) throw Error('Use a Veilbound lab JSON with 1–40 moves.');
  const ids=new Set();
  const moves=input.moves.map(m=>{
    if(!m || typeof m.id!=='string' || !/^[a-zA-Z0-9_-]{1,80}$/.test(m.id) || ids.has(m.id)) throw Error('Move IDs must be unique.');
    ids.add(m.id);
    if(typeof m.name!=='string' || !m.name.trim() || m.name.length>40) throw Error('Move names need 1–40 characters.');
    for(const k of ['damage','windup','active','recovery','cooldown']) if(typeof m[k]!=='number' || !Number.isFinite(m[k]) || m[k]<0 || m[k]>(k==='damage'?1000:10)) throw Error('Damage must be 0–1000; timing must be 0–10 seconds.');
    if(!Array.isArray(m.links) || m.links.some(x=>typeof x!=='string')) throw Error('Invalid combo links.');
    return {id:m.id,name:m.name.trim(),damage:m.damage,windup:m.windup,active:m.active,recovery:m.recovery,cooldown:m.cooldown,links:[...new Set(m.links)],source:m.source==='current'?'current':'example'};
  });
  moves.forEach(m=>m.links=m.links.filter(id=>ids.has(id)));
  if(!Array.isArray(input.combo) || input.combo.length>20 || input.combo.some(id=>!ids.has(id))) throw Error('Combo must contain at most 20 existing moves.');
  return {version:1,moves,combo:[...input.combo],unit:input.unit==='frames'?'frames':'seconds',useLinks:input.useLinks!==false,selectedId:ids.has(input.selectedId)?input.selectedId:moves[0].id};
}
