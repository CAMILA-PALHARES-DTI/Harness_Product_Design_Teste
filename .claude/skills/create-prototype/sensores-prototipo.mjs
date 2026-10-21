#!/usr/bin/env node
// Sensores computacionais do create-prototype (SC-01 a SC-09).
// Uso:  node .claude/skills/create-prototype/sensores-prototipo.mjs <prototipo.html>
//         [--screens SCR-01,SCR-02] [--lang pt-BR] [--platform web-responsive|web-desktop|app] [--no-runtime]
//       node .claude/skills/create-prototype/sensores-prototipo.mjs --check
// Dependência: Puppeteer, já instalado por `npm install` em scripts/ (o mesmo do validar-mermaid.ps1).
// Saída: relatório por sensor. Exit 0 = APROVADO | 1 = REPROVADO | 2 = APROVADO PARCIAL / ambiente incompleto.
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath, pathToFileURL } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, '..', '..', '..');
const INSTALL = 'cd scripts && npm install';
const STATES = new Set(['default', 'loading', 'empty', 'error', 'success']);
const RUNTIME = ['SC-06', 'SC-07', 'SC-08', 'SC-09'];
// plataforma -> [largura principal, largura de reflow ou null, alvo mínimo em px]
const PLATFORMS = { 'web-responsive': [1280, 320, 24], 'web-desktop': [1280, null, 24], app: [390, 320, 44] };
const NAMES = {
  'SC-01': 'Estrutura e arquivo único', 'SC-02': 'Cobertura de telas e navegação', 'SC-03': 'Estados',
  'SC-04': 'Acessibilidade estática', 'SC-05': 'Conteúdo e idioma', 'SC-06': 'Reflow (telas estreitas)',
  'SC-07': 'Contraste', 'SC-08': 'Tamanho de alvo', 'SC-09': 'Foco por teclado',
};

const findings = []; // [sensor, severidade, mensagem]
const add = (s, sev, msg) => findings.push([s, sev, msg]);
let runtimeSkipped = null;

// ---------------------------------------------------------------- argumentos
function parseArgs(argv) {
  const a = { file: null, screens: null, lang: null, platform: 'web-responsive', noRuntime: false, check: false };
  for (let i = 0; i < argv.length; i++) {
    const v = argv[i];
    if (v === '--screens') a.screens = argv[++i];
    else if (v === '--lang') a.lang = argv[++i];
    else if (v === '--platform') a.platform = argv[++i];
    else if (v === '--no-runtime') a.noRuntime = true;
    else if (v === '--check') a.check = true;
    else if (!v.startsWith('--')) a.file = v;
  }
  return a;
}

// ---------------------------------------------------------------- puppeteer
function loadPuppeteer() {
  try {
    return createRequire(path.join(ROOT, 'scripts', 'package.json'))('puppeteer');
  } catch {
    return null;
  }
}

async function launch(puppeteer) {
  try {
    return { browser: await puppeteer.launch({ headless: true, args: ['--allow-file-access-from-files'] }) };
  } catch (e) {
    return { error: `Puppeteer instalado, mas o Chromium não abriu (${String(e.message).split('\n')[0].slice(0, 100)})` };
  }
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ---------------------------------------------------------------- coleta estática (roda no navegador, com JS desligado)
function collectStatic() {
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];
  const ext = (u) => /^(https?:)?\/\//.test(u || '');
  const out = {};
  out.doctype = !!document.doctype;
  out.lang = document.documentElement.getAttribute('lang');
  out.viewport = !!document.querySelector('meta[name=viewport]');
  out.title = (document.title || '').trim();
  out.extScripts = $$('script[src]').map((s) => s.getAttribute('src')).filter(ext);
  out.extCss = $$('link[rel~=stylesheet]').map((l) => l.getAttribute('href')).filter(ext);
  out.extImgs = $$('img[src]').map((i) => i.getAttribute('src')).filter(ext);
  out.js = $$('script:not([src])').map((s) => s.textContent).join('\n');
  out.css = $$('style').map((s) => s.textContent).join('\n');
  const clone = document.body.cloneNode(true);
  clone.querySelectorAll('script,style').forEach((n) => n.remove());
  out.text = clone.textContent;

  const sectionOf = (el) => el.closest('section.screen');
  out.screens = $$('section.screen').map((s) => {
    const heads = $$('h1,h2,h3,h4,h5,h6', s).map((h) => +h.tagName[1]);
    return {
      id: s.id,
      validId: /^SCR-\d+$/.test(s.id),
      h1: heads.filter((h) => h === 1).length,
      headings: heads,
      hasForm: !!s.querySelector('form, button[type=submit]'),
    };
  });
  out.states = {}; // tela -> [estados]
  out.badStates = [];
  $$('[data-state]').forEach((el) => {
    const sec = sectionOf(el);
    const owner = el.getAttribute('data-screen') || (sec && sec.id);
    const st = el.getAttribute('data-state');
    if (owner) (out.states[owner] = out.states[owner] || []).push(st);
    out.badStates.push([owner, st]);
  });
  out.nav = {}; // tela -> destinos de navigateTo() em atributos on*
  out.navAll = [];
  $$('*').forEach((el) => {
    for (const at of el.attributes) {
      if (!at.name.startsWith('on')) continue;
      for (const m of at.value.matchAll(/navigateTo\(\s*['"]([^'"]+)['"]/g)) {
        const sec = sectionOf(el);
        const k = sec ? sec.id : '_fora';
        (out.nav[k] = out.nav[k] || []).push(m[1]);
        out.navAll.push(m[1]);
      }
    }
  });
  const sid = (el) => { const s = sectionOf(el); return s ? s.id : '-'; };
  const labelFor = new Set($$('label[for]').map((l) => l.getAttribute('for')));
  out.unlabeled = $$('input,select,textarea')
    .filter((el) => !['hidden', 'submit', 'button', 'reset', 'image'].includes(el.getAttribute('type') || ''))
    .filter((el) => !(el.getAttribute('aria-label') || el.getAttribute('aria-labelledby') || el.closest('label') || (el.id && labelFor.has(el.id))))
    .map((el) => `${sid(el)} <${el.tagName.toLowerCase()} name=${el.getAttribute('name') || ''} id=${el.id || ''}>`);
  out.noAutocomplete = $$('input[type=email],input[type=tel]').filter((el) => !el.getAttribute('autocomplete'))
    .map((el) => `${sid(el)}: campo ${el.getAttribute('type')}`);
  out.imgNoAlt = $$('img:not([alt])').map((el) => `${sid(el)}: <img src=${(el.getAttribute('src') || '').slice(0, 40)}>`);
  out.noName = $$('button,a,[role=button]').filter((el) => {
    if (el.getAttribute('aria-label') || el.getAttribute('aria-labelledby') || el.getAttribute('title')) return false;
    if ((el.textContent || '').trim()) return false;
    return !$$('img[alt]', el).some((i) => i.getAttribute('alt'));
  }).map((el) => `${sid(el)} <${el.tagName.toLowerCase()} class=${(el.className || '').toString().slice(0, 30)}>`);
  out.fakeButtons = $$('div[onclick],span[onclick],li[onclick],td[onclick],img[onclick]')
    .filter((el) => !(['button', 'link'].includes(el.getAttribute('role')) && el.hasAttribute('tabindex')))
    .map((el) => `${sid(el)}: <${el.tagName.toLowerCase()} onclick>`);
  out.posTabindex = $$('[tabindex]').filter((el) => +el.getAttribute('tabindex') > 0)
    .map((el) => `${sid(el)}: tabindex=${el.getAttribute('tabindex')}`);
  out.badDialogs = $$('[role=dialog]').filter((el) => !(el.getAttribute('aria-modal') === 'true' && (el.getAttribute('aria-labelledby') || el.getAttribute('aria-label'))))
    .map((el) => el.id || 'dialog');
  out.live = !!document.querySelector('[aria-live],[role=alert],[role=status]');
  const skip = document.querySelector('a[href^="#"]');
  const main = document.querySelector('main');
  out.skipLink = !!skip && (!main || !!(skip.compareDocumentPosition(main) & Node.DOCUMENT_POSITION_FOLLOWING));
  return out;
}

function staticChecks(d, args) {
  // SC-01
  if (!d.doctype) add('SC-01', 'BLOQUEANTE', 'falta <!DOCTYPE html>');
  if (!d.lang) add('SC-01', 'BLOQUEANTE', 'falta o atributo lang em <html>');
  else if (args.lang && d.lang !== args.lang) add('SC-01', 'BLOQUEANTE', `lang=${d.lang}, mas o idioma do protótipo é ${args.lang}`);
  if (!d.viewport) add('SC-01', 'BLOQUEANTE', 'falta <meta name=viewport>');
  if (!d.title) add('SC-01', 'BLOQUEANTE', 'falta <title>');
  d.extScripts.forEach((u) => add('SC-01', 'BLOQUEANTE', `script externo: ${u}`));
  d.extCss.forEach((u) => add('SC-01', 'BLOQUEANTE', `CSS externo: ${u}`));
  d.extImgs.forEach((u) => add('SC-01', 'ALERTA', `imagem externa (não abre offline): ${u.slice(0, 60)}`));
  if (/\b(localStorage|sessionStorage|indexedDB)\b/.test(d.js)) add('SC-01', 'ALERTA', 'usa armazenamento do navegador (regra técnica 8)');
  if (/\bfetch\(|XMLHttpRequest/.test(d.js)) add('SC-01', 'ALERTA', 'faz requisição de rede (protótipo deve ser offline)');
  // SC-02
  const ids = d.screens.map((s) => s.id);
  if (!ids.length) add('SC-02', 'BLOQUEANTE', 'nenhuma <section class="screen" id="SCR-XX"> encontrada');
  d.screens.filter((s) => !s.validId).forEach((s) => add('SC-02', 'BLOQUEANTE', `ID de tela fora do padrão SCR-NN: "${s.id}"`));
  if (args.screens) {
    const exp = args.screens.split(',').map((s) => s.trim()).filter(Boolean);
    exp.filter((s) => !ids.includes(s)).forEach((s) => add('SC-02', 'BLOQUEANTE', `tela confirmada ${s} não existe no HTML`));
    ids.filter((s) => !exp.includes(s)).forEach((s) => add('SC-02', 'ALERTA', `tela ${s} não estava na lista confirmada`));
  }
  [...new Set(ids.filter((s, i) => ids.indexOf(s) !== i))].forEach((s) => add('SC-02', 'BLOQUEANTE', `ID duplicado: ${s}`));
  const jsTargets = [...d.js.matchAll(/navigateTo\(\s*['"](SCR-\d+)['"]/g)].map((m) => m[1]);
  [...new Set([...d.navAll, ...jsTargets])].sort().filter((t) => !ids.includes(t))
    .forEach((t) => add('SC-02', 'BLOQUEANTE', `navigateTo('${t}') aponta para tela inexistente`));
  if (ids.length) {
    const seen = new Set([ids[0]]); const todo = [ids[0]];
    while (todo.length) for (const t of d.nav[todo.pop()] || []) if (ids.includes(t) && !seen.has(t)) { seen.add(t); todo.push(t); }
    ids.filter((s) => !seen.has(s) && !jsTargets.includes(s))
      .forEach((s) => add('SC-02', 'ALERTA', `${s} não é alcançável a partir de ${ids[0]} pela navegação das telas (só pela barra de debug?)`));
  }
  // SC-03
  d.badStates.filter(([, st]) => !STATES.has(st)).forEach(([o, st]) => add('SC-03', 'ALERTA', `${o}: estado desconhecido '${st}'`));
  for (const s of d.screens) {
    const st = new Set(d.states[s.id] || []);
    if (st.size && !st.has('default')) add('SC-03', 'BLOQUEANTE', `${s.id}: tem estados [${[...st]}] mas não tem 'default'`);
    if (s.hasForm && !st.has('error')) add('SC-03', 'ALERTA', `${s.id}: tem envio/formulário mas não tem estado 'error' (Nielsen H9)`);
    if (s.hasForm && !st.has('loading')) add('SC-03', 'ALERTA', `${s.id}: tem envio/formulário mas não tem estado 'loading' (Nielsen H1)`);
  }
  // SC-04
  for (const s of d.screens) {
    if (s.h1 !== 1) add('SC-04', 'BLOQUEANTE', `${s.id}: tem ${s.h1} <h1> (esperado 1) (WCAG 1.3.1)`);
    for (let i = 1; i < s.headings.length; i++) {
      if (s.headings[i] > s.headings[i - 1] + 1) { add('SC-04', 'ALERTA', `${s.id}: salto de h${s.headings[i - 1]} para h${s.headings[i]} (WCAG 1.3.1)`); break; }
    }
  }
  d.imgNoAlt.forEach((m) => add('SC-04', 'BLOQUEANTE', `${m} sem alt (WCAG 1.1.1)`));
  d.noName.forEach((m) => add('SC-04', 'BLOQUEANTE', `${m} sem nome acessível (texto ou aria-label) (WCAG 4.1.2)`));
  d.unlabeled.forEach((m) => add('SC-04', 'BLOQUEANTE', `${m} sem label associado (WCAG 3.3.2 / 1.3.1)`));
  d.fakeButtons.forEach((m) => add('SC-04', 'BLOQUEANTE', `${m} sem role/tabindex — use <button> (WCAG 2.1.1)`));
  d.posTabindex.forEach((m) => add('SC-04', 'ALERTA', `${m} positivo (WCAG 2.4.3)`));
  d.badDialogs.forEach((m) => add('SC-04', 'BLOQUEANTE', `${m}: role=dialog sem aria-modal=true + aria-labelledby (WCAG 4.1.2)`));
  d.noAutocomplete.forEach((m) => add('SC-04', 'ALERTA', `${m} sem autocomplete (WCAG 1.3.5)`));
  if (!d.live) add('SC-04', 'ALERTA', 'nenhuma região aria-live / role=status|alert para mensagens de status (WCAG 4.1.3)');
  if (!d.skipLink) add('SC-04', 'ALERTA', "sem link 'pular para o conteúdo' antes do conteúdo (WCAG 2.4.1)");
  if (/outline\s*:\s*(none|0)\b/.test(d.css) && !d.css.includes(':focus-visible')) add('SC-04', 'BLOQUEANTE', 'outline removido sem estilo de :focus/:focus-visible substituto (WCAG 2.4.7)');
  if (/\b(animation|transition)\s*:/.test(d.css) && !d.css.includes('prefers-reduced-motion')) add('SC-04', 'ALERTA', 'usa animação/transição sem @media (prefers-reduced-motion) (WCAG 2.3.3)');
  // SC-05
  if (/lorem ipsum|dolor sit amet/i.test(d.text)) add('SC-05', 'BLOQUEANTE', 'contém lorem ipsum — use copy real');
  if (/\[to be confirmed\]/i.test(d.text)) add('SC-05', 'ALERTA', "marcador '[to be confirmed]' — o marcador do harness é '[a confirmar]'");
  const n = (d.text.match(/\[a confirmar\]/g) || []).length;
  const ns = (d.text.match(/\[sugest/g) || []).length;
  const na = (d.text.match(/\[a11y/g) || []).length;
  add('SC-05', 'INFO', `${n} marcações [a confirmar]; ${ns} sugestões; ${na} pontos a11y`);
}

// ---------------------------------------------------------------- runtime (funções serializadas para o navegador)
function runtimeProbe(minTarget) {
  const out = { contrast: [], targets: [] };
  const lum = (c) => {
    const m = c.match(/[\d.]+/g); if (!m) return null;
    const [r, g, b] = m.slice(0, 3).map((v) => { v = v / 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); });
    return { L: 0.2126 * r + 0.7152 * g + 0.0722 * b, a: m[3] === undefined ? 1 : +m[3] };
  };
  const bgOf = (el) => {
    for (let e = el; e; e = e.parentElement) {
      const s = getComputedStyle(e); if (s.backgroundImage !== 'none') return null;
      const l = lum(s.backgroundColor); if (l && l.a > 0.5) return l;
    }
    return { L: 1, a: 1 };
  };
  const vis = (el) => {
    const r = el.getBoundingClientRect(); const s = getComputedStyle(el);
    return r.width > 0 && r.height > 0 && s.visibility !== 'hidden' && s.display !== 'none' && +s.opacity > 0.1 && !el.closest('[hidden],#debug-nav,.sr-only');
  };
  const scope = document.querySelector('.screen.active') || document.body;
  scope.querySelectorAll('*').forEach((el) => {
    if (!vis(el)) return;
    const own = [...el.childNodes].some((n) => n.nodeType === 3 && n.textContent.trim());
    if (own && !el.disabled) {
      const s = getComputedStyle(el); const fg = lum(s.color); const bg = bgOf(el);
      if (fg && bg) {
        const ratio = (Math.max(fg.L, bg.L) + 0.05) / (Math.min(fg.L, bg.L) + 0.05);
        const px = parseFloat(s.fontSize); const bold = +s.fontWeight >= 700;
        const large = px >= 24 || (bold && px >= 18.66); const min = large ? 3 : 4.5;
        if (ratio < min) out.contrast.push(`"${el.textContent.trim().slice(0, 30)}" ${ratio.toFixed(2)}:1 (mín ${min})`);
      }
    }
    if (el.matches('button, a[href], input[type=checkbox], input[type=radio], [role=button]')) {
      const r = el.getBoundingClientRect();
      if (r.width < minTarget || r.height < minTarget) out.targets.push(`<${el.tagName.toLowerCase()}> "${(el.textContent || el.getAttribute('aria-label') || '').trim().slice(0, 25)}" ${Math.round(r.width)}x${Math.round(r.height)}px`);
    }
  });
  out.overflow = document.documentElement.scrollWidth > document.documentElement.clientWidth + 1;
  return out;
}

function focusProbe() {
  const el = document.activeElement;
  if (!el || el === document.body) return null;
  if (el.closest('#debug-nav')) return 'debug';
  const s = getComputedStyle(el);
  const ok = (s.outlineStyle !== 'none' && parseFloat(s.outlineWidth) > 0) || s.boxShadow !== 'none';
  const r = el.getBoundingClientRect();
  const top = document.elementFromPoint(r.left + r.width / 2, r.top + Math.min(r.height / 2, 5));
  const hidden = top && !el.contains(top) && !top.contains(el) && top.closest('#debug-nav, header, [style*=fixed]');
  return { ok, hidden: !!hidden, desc: `<${el.tagName.toLowerCase()}> "${(el.textContent || el.getAttribute('aria-label') || '').trim().slice(0, 25)}"` };
}

async function runtimeChecks(browser, url, screens, platform) {
  const errors = [];
  const [mainW, reflowW, minTarget] = PLATFORMS[platform];
  for (const width of [mainW, reflowW].filter(Boolean)) {
    const pg = await browser.newPage();
    await pg.setViewport({ width, height: 800 });
    pg.on('pageerror', (e) => errors.push(String(e.message || e)));
    await pg.goto(url); await sleep(200);
    const hasNav = await pg.evaluate(() => typeof navigateTo === 'function');
    const hasState = await pg.evaluate(() => typeof setState === 'function');
    if (!hasNav) { add('SC-02', 'BLOQUEANTE', 'função navigateTo() não existe'); await pg.close(); break; }
    for (const s of screens) {
      await pg.evaluate((id) => navigateTo(id), s); await sleep(50);
      const states = (await pg.evaluate((id) => [...new Set([...document.querySelectorAll(`[data-screen="${id}"][data-state]`)].map((e) => e.dataset.state))], s));
      for (const st of states.length ? states : ['default']) {
        if (hasState) { await pg.evaluate((id, x) => setState(id, x), s, st); await sleep(30); }
        const r = await pg.evaluate(runtimeProbe, minTarget);
        if (width === reflowW && r.overflow) add('SC-06', 'BLOQUEANTE', `${s}/${st}: rolagem horizontal a ${reflowW}px (WCAG 1.4.10)`);
        if (width === mainW) {
          [...new Set(r.contrast)].sort().slice(0, 5).forEach((c) => add('SC-07', 'BLOQUEANTE', `${s}/${st}: contraste ${c} (WCAG 1.4.3)`));
          const ref = platform === 'app' ? 'mínimo de toque para app (44px iOS / 48dp Android)' : 'WCAG 2.5.8 — ok se houver espaçamento';
          [...new Set(r.targets)].sort().slice(0, 5).forEach((t) => add('SC-08', 'ALERTA', `${s}/${st}: alvo menor que ${minTarget}x${minTarget} ${t} (${ref})`));
        }
      }
      if (hasState && states.length > 1) await pg.evaluate((id) => setState(id, 'default'), s);
      if (width === mainW) { // SC-09 foco por teclado
        await pg.evaluate((id) => navigateTo(id), s); await pg.mouse.move(0, 0);
        const bad = []; const hid = [];
        for (let i = 0; i < 30; i++) {
          await pg.keyboard.press('Tab');
          const f = await pg.evaluate(focusProbe);
          if (f === null || f === 'debug') continue;
          if (!f.ok) bad.push(f.desc);
          if (f.hidden) hid.push(f.desc);
        }
        [...new Set(bad)].sort().slice(0, 5).forEach((x) => add('SC-09', 'BLOQUEANTE', `${s}: ${x} recebe foco sem indicador visível (WCAG 2.4.7)`));
        [...new Set(hid)].sort().slice(0, 3).forEach((x) => add('SC-09', 'BLOQUEANTE', `${s}: ${x} focado mas coberto por elemento fixo (WCAG 2.4.11)`));
      }
    }
    await pg.close();
  }
  [...new Set(errors)].slice(0, 5).forEach((e) => add('SC-01', 'BLOQUEANTE', `erro de JavaScript: ${e.slice(0, 120)}`));
}

// ---------------------------------------------------------------- main
async function main() {
  const args = parseArgs(process.argv.slice(2));
  const puppeteer = loadPuppeteer();
  if (args.check) {
    if (!puppeteer) { console.log(`AMBIENTE INCOMPLETO: Puppeteer não está instalado.\nSem ele nenhum sensor computacional roda.\nPara instalar: ${INSTALL}`); process.exit(2); }
    const { browser, error } = await launch(puppeteer);
    if (!browser) { console.log(`AMBIENTE INCOMPLETO: ${error}.\nPara reinstalar: ${INSTALL}`); process.exit(2); }
    await browser.close();
    console.log('AMBIENTE OK: Puppeteer + Chromium prontos. Todos os sensores computacionais podem rodar.');
    process.exit(0);
  }
  if (!args.file) { console.error('informe o arquivo HTML do protótipo (ou use --check)'); process.exit(2); }
  if (!PLATFORMS[args.platform]) { console.error(`--platform inválida: ${args.platform} (web-responsive | web-desktop | app)`); process.exit(2); }
  if (!fs.existsSync(args.file)) { console.error(`arquivo não encontrado: ${args.file}`); process.exit(2); }
  if (!puppeteer) { console.log(`AMBIENTE INCOMPLETO: Puppeteer não está instalado — nenhum sensor rodou.\nPara instalar: ${INSTALL}`); process.exit(2); }
  const { browser, error } = await launch(puppeteer);
  if (!browser) { console.log(`AMBIENTE INCOMPLETO: ${error} — nenhum sensor rodou.\nPara reinstalar: ${INSTALL}`); process.exit(2); }

  const url = pathToFileURL(path.resolve(args.file)).href;
  // passada estática: JS desligado, DOM = o que está escrito no arquivo
  const sp = await browser.newPage();
  await sp.setJavaScriptEnabled(false);
  await sp.goto(url);
  const data = await sp.evaluate(collectStatic);
  await sp.close();
  staticChecks(data, args);

  if (args.noRuntime) runtimeSkipped = 'executado com --no-runtime';
  else if (data.screens.length) await runtimeChecks(browser, url, data.screens.map((s) => s.id), args.platform);
  await browser.close();

  if (args.platform === 'web-desktop') add('SC-06', 'INFO', 'plataforma web não responsiva: reflow a 320px não testado — WCAG 1.4.10 fica não atendido por decisão de plataforma; registre como exceção no relatório');

  const blk = findings.filter((f) => f[1] === 'BLOQUEANTE').length;
  const alr = findings.filter((f) => f[1] === 'ALERTA').length;
  const resultado = blk ? 'REPROVADO' : runtimeSkipped ? 'APROVADO PARCIAL' : 'APROVADO';
  console.log(`SENSORES create-prototype — ${args.file}\nPlataforma: ${args.platform}\nResultado: ${resultado} | ${blk} bloqueante(s) | ${alr} alerta(s)`);
  if (runtimeSkipped) {
    console.log('\n!!! ATENÇÃO: os sensores SC-06 a SC-09 (reflow 320px, contraste, tamanho de alvo, foco por teclado) NÃO RODARAM.');
    console.log(`!!! Motivo: ${runtimeSkipped}.\n!!! Esses 4 pontos NÃO foram verificados e precisam de checagem manual.`);
  }
  console.log();
  for (const sid of Object.keys(NAMES)) {
    const fs_ = findings.filter((f) => f[0] === sid);
    let status;
    if (RUNTIME.includes(sid) && runtimeSkipped) status = 'NÃO RODOU';
    else if (sid === 'SC-06' && args.platform === 'web-desktop') status = 'NÃO SE APLICA';
    else status = fs_.some((f) => f[1] === 'BLOQUEANTE') ? 'FALHOU' : fs_.some((f) => f[1] === 'ALERTA') ? 'ALERTA' : 'OK';
    console.log(`[${status}] ${sid} ${NAMES[sid]}`);
    fs_.forEach(([, sev, msg]) => console.log(`    ${sev}: ${msg}`));
  }
  process.exit(blk ? 1 : runtimeSkipped ? 2 : 0);
}

main().catch((e) => { console.error(`erro inesperado nos sensores: ${e.stack || e}`); process.exit(2); });
