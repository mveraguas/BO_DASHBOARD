const $ = id => document.getElementById(id);
let all = [], filtered = [], page = 0, loaded = false;
const size = 8;
const number = value => new Intl.NumberFormat('es-CL', {maximumFractionDigits: 2}).format(value);
const escapeHtml = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function statusClass(status) {
  return ({PENDING_MATCH:'pending', REJECTED:'rejected', MATCH:'matched', LOADED:'loaded'})[status] || 'unknown';
}
function renderMessagePie(rows) {
  const counts = new Map();
  rows.forEach(row => {
    const type = row.tipoMensaje || 'Sin tipo';
    const status = row.estadoMensaje || 'Sin estado';
    const key = JSON.stringify([type, status]);
    if (!counts.has(key)) counts.set(key, {type, status, count: 0});
    counts.get(key).count++;
  });
  const entries = [...counts.values()].sort((a,b) => a.type.localeCompare(b.type) || a.status.localeCompare(b.status));
  const palette = ['#2f7fc1','#dfaa3c','#cf6470','#2e9c80','#866bc2','#4c9fac','#bf8149','#a16ca1'];
  const percent = new Intl.NumberFormat('es-CL', {maximumFractionDigits: 1});
  let offset = 0;
  const stops = [];
  const labels = [];
  const legend = [];
  entries.forEach((entry,index) => {
    const share = entry.count / rows.length * 100;
    const color = index < palette.length ? palette[index] : `hsl(${index*137.508%360} 50% 45%)`;
    const end = index === entries.length-1 ? 100 : offset+share;
    stops.push(`${color} ${offset}% ${end}%`);
    offset = end;
    const label = `${entry.type} · ${entry.status}`;
    const value = `${percent.format(share)}%`;
    labels.push(`${label}: ${value}, ${number(entry.count)} mensajes`);
    legend.push(`<li><span class="pie-key" style="background:${color}"></span><span class="pie-label">${escapeHtml(label)}<small>${number(entry.count)} mensajes</small></span><strong>${value}</strong></li>`);
  });
  $('message-pie').style.background = rows.length ? `conic-gradient(${stops.join(',')})` : '#e8eef1';
  $('message-pie').setAttribute('aria-label', rows.length ? labels.join('; ') : 'Sin mensajes para las fechas seleccionadas');
  $('message-pie').title = labels.join('\n');
  $('pie-legend').innerHTML = legend.join('');
  $('pie-summary').textContent = rows.length ? `${number(rows.length)} mensajes · ${entries.length} combinaciones de tipo y estado. Porcentajes redondeados.` : 'Sin mensajes para las fechas seleccionadas.';
}
function render() {
  const from = $('from').value, to = $('to').value;
  if(from && to && from > to) { $('error').textContent='La fecha Desde debe ser anterior o igual a Hasta.'; $('error').hidden=false; return; }
  $('error').hidden=true;
  filtered = all.filter(r => (!from || r.fechaHoraIngreso.slice(0,10)>=from) && (!to || r.fechaHoraIngreso.slice(0,10)<=to));
  const countState = state => filtered.filter(row => row.estadoMensaje === state).length;
  $('messages').textContent=number(filtered.length);
  $('rejected').textContent=number(countState('REJECTED'));
  $('pending').textContent=number(countState('PENDING_MATCH'));
  $('matched').textContent=number(countState('MATCH'));
  renderMessagePie(filtered);
  page=Math.min(page,Math.max(0,Math.ceil(filtered.length/size)-1));
  $('count').textContent=`${number(filtered.length)} mensajes · ordenados por ingreso más reciente`;
  $('rows').innerHTML=filtered.slice(page*size,(page+1)*size).map(r=>`<tr><td>${escapeHtml(r.messageID)}<small>${escapeHtml(r.tradeID)} · ${escapeHtml(r.tipoMensaje)}</small></td><td>${escapeHtml(r.fechaHoraIngreso.slice(11,19))}<small>${escapeHtml(r.fechaHoraIngreso.slice(0,10))}</small></td><td>${escapeHtml(r.bancoEmisor)} → ${escapeHtml(r.bancoReceptor)}</td><td>${number(r.nominalCompra)} <small>${escapeHtml(r.monedaCompra)}</small></td><td>${number(r.nominalVenta)} <small>${escapeHtml(r.monedaVenta)}</small></td><td>${number(r.tipoCambio)}<small>${escapeHtml(r.convencionTipoCambio)}</small></td><td>${escapeHtml(r.fechaLiquidacion)}<small>Plazo: ${r.plazoDias} días corridos</small></td><td><span class="badge ${statusClass(r.estadoMensaje)}">${escapeHtml(r.estadoMensaje)}</span></td></tr>`).join('') || '<tr><td colspan="8">No hay mensajes para los filtros seleccionados.</td></tr>';
  $('page-info').textContent=`Página ${page+1} de ${Math.max(1,Math.ceil(filtered.length/size))}`;
  $('prev').disabled=page===0; $('next').disabled=(page+1)*size>=filtered.length;
  $('export').disabled=!filtered.length;
}
let tradesData=null;
function renderTrades() {
  if(!tradesData) return;
  const data=tradesData;
  for(const unit of ['USD','CLF']) {
    const slug=unit.toLowerCase(),rows=data.bancos.filter(b=>b.moneda===`${unit}/CLP`);
    const rawMax=Math.max(...rows.map(b=>Number(b.nocionalAbsoluto)),1);
    const scale=10**Math.floor(Math.log10(rawMax)),max=Math.ceil(rawMax/scale)*scale;
    const minRaw=Math.min(...rows.map(b=>Number(b.nocionalNeto)),0);
    const min=minRaw<0?-Math.ceil(Math.abs(minRaw)/scale)*scale:0;
    const left=90,right=590,top=30,bottom=225,width=right-left,height=bottom-top;
    const y=value=>bottom-(value-min)/(max-min)*height;
    const zero=y(0),step=width/Math.max(rows.length,1),barWidth=Math.min(28,step/4);
    const colors=unit==='USD'?['#327eaf','#93c4e1']:['#d99b36','#f0cf8b'];
    $(`trades-date-${slug}`).textContent=`Ingresadas hoy · ${data.fecha} · ${data.zonaHoraria}`;
    let svg=`<svg viewBox="0 0 620 275" role="img" aria-label="Nocional bruto y neto en ${unit} por banco"><text x="${left}" y="12" class="svg-axis">Nocional (${unit})</text>`;
    for(let i=0;i<=4;i++) {
      const value=min+(max-min)*i/4,position=y(value);
      svg+=`<line x1="${left}" x2="${right}" y1="${position}" y2="${position}" stroke="#e1e9ed"/><text x="${left-8}" y="${position+3}" text-anchor="end" class="svg-axis">${number(value)}</text>`;
    }
    svg+=`<line x1="${left}" x2="${right}" y1="${zero}" y2="${zero}" stroke="#637e8e" stroke-width="1.5"/>`;
    rows.forEach((row,index)=>{
      const center=left+step*(index+.5);
      for(const [series,value] of [Number(row.nocionalAbsoluto),Number(row.nocionalNeto)].entries()) {
        const x=center+(series===0?-barWidth-2:2),position=y(value),barTop=Math.min(position,zero),barHeight=Math.abs(position-zero);
        svg+=`<rect x="${x}" y="${barTop}" width="${barWidth}" height="${barHeight}" fill="${colors[series]}" stroke="${colors[0]}" stroke-width=".5"><title>${escapeHtml(row.banco)} · ${series===0?'Bruto':'Neto'}: ${number(value)} ${unit}</title></rect><text x="${x+barWidth/2}" y="${value<0?position+13:position-6}" text-anchor="middle" class="svg-value">${number(value)}</text>`;
      }
      svg+=`<text x="${center}" y="252" text-anchor="middle" class="svg-bank">${escapeHtml(row.banco)}</text>`;
    });
    svg+='<text x="340" y="272" text-anchor="middle" class="svg-axis">Banco emisor</text></svg>';
    $(`chart-${slug}`).innerHTML=`<div class="currency-legend"><span><i style="background:${colors[0]}"></i>Bruto · Σ |nocional|</span><span><i style="background:${colors[1]}"></i>Neto · Σ nocional</span></div>${svg}`;
    const bruto=rows.reduce((sum,row)=>sum+Number(row.nocionalAbsoluto),0),neto=rows.reduce((sum,row)=>sum+Number(row.nocionalNeto),0),count=rows.reduce((sum,row)=>sum+row.cantidad,0);
    $(`trades-summary-${slug}`).textContent=`Bruto: ${number(bruto)} ${unit} · Neto: ${number(neto)} ${unit} · ${number(count)} operaciones${data.origen==='demo'?' · Datos de ejemplo':''}`;
  }
  const groups=new Map(), hrc=new Map();
  for(const row of data.detalles) {
    const key=JSON.stringify([row.banco,row.contraparte,row.moneda]);
    if(!groups.has(key)) groups.set(key,{...row,nocionalAbsoluto:0});
    groups.get(key).nocionalAbsoluto+=Number(row.nocionalAbsoluto);
    if(row.estado==='REJECTED_HRC') hrc.set(row.contraparte,(hrc.get(row.contraparte)||0)+row.cantidad);
  }
  for(const unit of ['USD','CLF']) {
    const rows=[...groups.values()].filter(r=>r.moneda===`${unit}/CLP`).sort((a,b)=>a.banco.localeCompare(b.banco)||a.contraparte.localeCompare(b.contraparte));
    $(`counterpart-rows-${unit.toLowerCase()}`).innerHTML=rows.map(r=>`<tr><td>${escapeHtml(r.banco)}</td><td>${escapeHtml(r.contraparte)}</td><td>${number(r.nocionalAbsoluto)} ${unit}</td></tr>`).join('')||`<tr><td colspan="3">Sin operaciones en ${unit} ingresadas hoy.</td></tr>`;
  }
  const rejected=[...hrc].sort((a,b)=>b[1]-a[1]||a[0].localeCompare(b[0])), hrcMax=Math.max(...rejected.map(r=>r[1]),1);
  $('hrc-chart').innerHTML=rejected.map(([bank,count])=>`<div class="bank-bar-row"><span>${escapeHtml(bank)}</span><div class="bank-bar-track"><div class="bank-bar hrc-bar" style="width:${count/hrcMax*100}%"></div></div><strong>${number(count)}</strong></div>`).join('');
  $('hrc-summary').textContent=rejected.length?`${number(rejected.reduce((sum,r)=>sum+r[1],0))} operaciones rechazadas por HRC`:'Sin operaciones rechazadas por HRC ingresadas hoy.';
}
async function loadTrades() {
  for(const slug of ['usd','clf']) {
    $(`chart-${slug}`).setAttribute('aria-busy','true');
    $(`trades-summary-${slug}`).textContent='Consultando operaciones…';
  }
  try {
    const response=await fetch('/api/trades/cleared-hoy', {signal:AbortSignal.timeout(20000), cache:'no-store'});
    if(!response.ok) throw new Error('No fue posible consultar Trades. Revisa la conexión y la tabla dbo.Trades.');
    const data=await response.json();
    tradesData=data;
    renderTrades();
    return true;
  } catch(error) {
    tradesData=null;
    for(const slug of ['usd','clf']) {
      $(`chart-${slug}`).replaceChildren();
      $(`trades-summary-${slug}`).textContent=error.message;
      $(`counterpart-rows-${slug}`).innerHTML='<tr><td colspan="3">No fue posible consultar Trades.</td></tr>';
    }
    $('hrc-chart').replaceChildren();
    $('hrc-summary').textContent='No fue posible consultar Trades.';
    return false;
  } finally { for(const slug of ['usd','clf']) $(`chart-${slug}`).setAttribute('aria-busy','false'); }
}
async function load() {
  $('refresh').disabled=true;
  $('source').className='connection checking';
  $('source').textContent='Comprobando conexión…';
  const tradesRequest=loadTrades();
  try {
    const response=await fetch('/api/mensajeria', {signal: AbortSignal.timeout(20000), cache: 'no-store'});
    if(!response.ok) throw new Error('No se pudieron consultar los mensajes. Revisa la conexión SQL Server y la configuración del proyecto.');
    const data=await response.json();
    all=data.mensajes.sort((a,b)=>b.fechaHoraIngreso.localeCompare(a.fechaHoraIngreso)||b.idMensaje-a.idMensaje);
    $('source').className=`connection ${data.origen==='demo'?'demo':'connected'}`;
    $('source').textContent=data.origen==='demo'?'Modo de ejemplo · Sin conexión a SQL Server':'SQL Server conectado · DashboardOperaciones';
    const tradesOk=await tradesRequest;
    if(!tradesOk && data.origen!=='demo') {
      $('source').className='connection disconnected';
      $('source').textContent='SQL Server · Mensajería disponible; error al consultar Trades';
    }
    loaded=true; render(); $('updated').textContent=`Última consulta correcta: ${new Date().toLocaleTimeString('es-CL')}`;
  } catch(error) {
    $('source').className='connection disconnected';
    $('error').textContent=error.message; $('error').hidden=false;
    $('source').textContent=loaded?'Sin conexión verificada · Se conservan los últimos datos.':'Sin conexión verificada · No hay datos disponibles.';
    $('export').disabled=true;
  } finally { await tradesRequest; $('refresh').disabled=false; }
}
$('filters').addEventListener('submit',e=>e.preventDefault());
$('filters').addEventListener('input',()=>{page=0;render();});
$('filters').addEventListener('reset',()=>setTimeout(()=>{page=0;render();},0));
$('refresh').onclick=load; $('prev').onclick=()=>{page--;render();}; $('next').onclick=()=>{page++;render();};
$('export').onclick=()=>{
  const keys=['messageID','tradeID','tipoMensaje','fechaHoraIngreso','bancoEmisor','bancoReceptor','monedaCompra','nominalCompra','monedaVenta','nominalVenta','tipoCambio','convencionTipoCambio','fechaOperacion','fechaLiquidacion','plazoDias','estadoMensaje'];
  const cell=value=>'"'+String(value??'').replace(/^[=+@\-\t\r]/,"'$&").replaceAll('"','""')+'"';
  const csv='\uFEFF'+[keys,...filtered.map(r=>keys.map(k=>r[k]))].map(row=>row.map(cell).join(';')).join('\r\n');
  const url=URL.createObjectURL(new Blob([csv],{type:'text/csv;charset=utf-8;'})); const a=document.createElement('a'); a.href=url;a.download='mensajeria.csv';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
};
load();

function setMenuOpen(open) {
  $('side-menu').hidden=!open;
  document.body.classList.toggle('menu-open',open);
  $('menu-toggle').setAttribute('aria-expanded',String(open));
  $('menu-toggle').setAttribute('aria-label',open?'Cerrar menú':'Abrir menú');
  $('menu-toggle').textContent=open?'×':'☰';
}
$('menu-toggle').addEventListener('click',()=>setMenuOpen($('side-menu').hidden));
document.addEventListener('keydown',event=>{
  if(event.key==='Escape' && !$('side-menu').hidden) {
    setMenuOpen(false);
    $('menu-toggle').focus();
  }
});
