/* Vértice Design System: comportamento comum a todos os apps (decisão 60 + estudo de padrões, 05/10/2026).
   Orbs: esfera de pontos em canvas (técnica estudada no thinking-orbs, MIT; código escrito do zero aqui).
   Regra: toda ação responde no mesmo quadro do clique; espera > 300 ms mostra orb + texto; > 10 s mostra progresso e cancelar. */
(() => {
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];

  /* ── Tema ── */
  const root = document.documentElement;
  const saved = (() => { try { return localStorage.getItem('vt-theme'); } catch (e) { return null; } })();
  if (saved) root.dataset.theme = saved;
  $$('.ds-theme button').forEach(b => {
    b.setAttribute('aria-pressed', String((b.dataset.set || '') === (root.dataset.theme || '')));
    b.addEventListener('click', () => {
      const v = b.dataset.set;
      if (v) root.dataset.theme = v; else delete root.dataset.theme;
      try { v ? localStorage.setItem('vt-theme', v) : localStorage.removeItem('vt-theme'); } catch (e) {}
      $$('.ds-theme button').forEach(x => x.setAttribute('aria-pressed', String(x === b)));
      Orb.all.forEach(o => o.recolor());
    });
  });

  /* ── Entrada com desfoque, em cascata dentro de cada grupo ── */
  $$('[data-reveal-group]').forEach(g => $$(':scope > [data-reveal]', g).forEach((el, i) => el.style.setProperty('--i', Math.min(i, 8))));
  const io = new IntersectionObserver(es => es.forEach(e => { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); } }),
    { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });
  $$('[data-reveal]').forEach(el => io.observe(el));

  /* ── Orb ── */
  const MODES = {
    respirando: { speed: .22, breathe: .035, wave: 0, sweep: 0, ring: 0, ribbon: 0, flat: 0, jitter: 0, tone: 'accent' },
    pensando:   { speed: 1.05, breathe: .015, wave: .10, sweep: 0, ring: 0, ribbon: 0, flat: 0, jitter: 0, tone: 'accent' },
    buscando:   { speed: .45, breathe: .01, wave: 0, sweep: 1, ring: 0, ribbon: 0, flat: 0, jitter: 0, tone: 'accent' },
    ouvindo:    { speed: .30, breathe: .01, wave: 0, sweep: 0, ring: .16, ribbon: 0, flat: 0, jitter: 0, tone: 'accent' },
    compondo:   { speed: .40, breathe: .01, wave: 0, sweep: 0, ring: 0, ribbon: .22, flat: 0, jitter: 0, tone: 'accent' },
    pronto:     { speed: .18, breathe: .02, wave: 0, sweep: 0, ring: 0, ribbon: 0, flat: .82, jitter: 0, tone: 'ok' },
    erro:       { speed: .12, breathe: 0, wave: 0, sweep: 0, ring: 0, ribbon: 0, flat: 0, jitter: .05, tone: 'error' },
  };
  const KEYS = ['speed', 'breathe', 'wave', 'sweep', 'ring', 'ribbon', 'flat', 'jitter'];
  class Orb {
    constructor(cv, mode) {
      this.cv = cv; this.ctx = cv.getContext('2d'); this.t = Math.random() * 10; this.rot = 0;
      this.p = { ...MODES[mode] || MODES.respirando }; this.target = { ...this.p }; this.mode = mode;
      this.visible = true; this.resize(); this.recolor(); this.build();
      Orb.all.push(this);
      Orb.vis.observe(cv);
      if (reduce) this.draw(); else this.loop();
    }
    resize() {
      const r = this.cv.getBoundingClientRect(), d = Math.min(devicePixelRatio || 1, 2);
      this.w = Math.max(16, r.width); this.cv.width = this.w * d; this.cv.height = this.w * d; this.ctx.setTransform(d, 0, 0, d, 0, 0);
    }
    build() {
      const n = +this.cv.dataset.n || Math.round(Math.min(900, Math.max(48, this.w < 140 ? this.w * 1.4 : this.w * this.w / 95)));
      const g = Math.PI * (3 - Math.sqrt(5)); this.pts = [];
      for (let i = 0; i < n; i++) { const y = 1 - (i / (n - 1)) * 2, r = Math.sqrt(1 - y * y), th = g * i; this.pts.push([Math.cos(th) * r, y, Math.sin(th) * r]); }
      buffers(this, n);
    }
    recolor() {
      const cs = getComputedStyle(this.cv);
      this.colors = { accent: cs.color, ok: cs.getPropertyValue('--vt-ok').trim() || '#2bb673', error: cs.getPropertyValue('--vt-error').trim() || '#e5484d' };
      if (reduce && this.pts) this.draw();   // no construtor a cor vem antes dos pontos (06/10/2026: com menos movimento dava erro)
    }
    set(mode) { if (!MODES[mode]) return; this.mode = mode; this.target = { ...MODES[mode] }; if (reduce) { this.p = { ...this.target }; this.draw(); } }
    loop() {
      const step = now => {
        if (this.cv.isConnected) this.seen = true;
        else if (this.seen) { Orb.all.splice(Orb.all.indexOf(this), 1); Orb.vis.unobserve(this.cv); return; }   // saiu da página: para
        if (this.visible && !document.hidden) {
          const dt = Math.min(.05, (now - (this.last || now)) / 1000); this.last = now; this.t += dt;
          KEYS.forEach(k => { this.p[k] += (this.target[k] - this.p[k]) * Math.min(1, dt * 5); });
          this.p.tone = this.target.tone; this.rot += this.p.speed * dt;
          if (now - (this.drawn || 0) >= passo(this)) { this.drawn = now; this.draw(); }
        } else this.last = now;
        requestAnimationFrame(step);
      };
      requestAnimationFrame(step);
    }
    draw() {
      const { ctx, w, p, t } = this, R = w * .42, c = w / 2, cr = Math.cos(this.rot), sr = Math.sin(this.rot), tilt = .38, ct = Math.cos(tilt), st = Math.sin(tilt);
      const sweepAt = Math.sin(t * 1.4) * .95, { X, Y, R: RR, A } = this, pts = this.pts, n = pts.length;
      const small = w < 140, base = small ? Math.max(1.25, w / 62) : Math.max(1.05, w / 120), floor = small ? .34 : .16;
      ctx.clearRect(0, 0, w, w);
      for (let i = 0; i < n; i++) {
        const q = pts[i], x0 = q[0], y0 = q[1], z0 = q[2];
        let x = x0 * cr + z0 * sr, z = -x0 * sr + z0 * cr, y = y0;
        let k = 1 + p.breathe * Math.sin(t * 1.3);
        k += p.wave * Math.sin(y0 * 5 + t * 3.2) * Math.cos(x0 * 3 + t * 1.7);
        k += p.ring * Math.sin(y0 * 9 - t * 6) * (.6 + .4 * Math.sin(t * 2.3));
        if (p.jitter) k += (Math.random() - .5) * p.jitter;
        x *= k; y *= k; z *= k;
        y += p.ribbon * Math.sin(x * 3 + t * 2.2); y *= 1 - p.flat;
        const yy = y * ct - z * st, zz = y * st + z * ct;
        let glow = 0; if (p.sweep) glow = p.sweep * Math.max(0, 1 - Math.abs(x0 * cr + z0 * sr - sweepAt) * 6) * (z > 0 ? 1 : .3);
        const d = (zz + 1) / 2;
        X[i] = c + x * R; Y[i] = c + yy * R; A[i] = Math.min(1, floor + (1 - floor) * d * d + glow * .8); RR[i] = base * (.45 + .75 * d + glow * .9);
      }
      ctx.fillStyle = this.colors[p.tone] || this.colors.accent;
      dots(ctx, this, n);
    }
  }
  Orb.all = [];
  Orb.vis = new IntersectionObserver(es => es.forEach(e => { const o = Orb.all.find(x => x.cv === e.target); if (o) o.visible = e.isIntersecting; }));
  window.VtOrb = Orb;
  /* Desenho em lote (05/10/2026, desempenho): os pontos são agrupados em 12 faixas de transparência e cada faixa vira
     UM preenchimento (antes: um por ponto, ~900 por quadro no orb grande, e a GPU do Cockpit ficava em 100%). As faixas
     vão da mais clara (fundo) à mais forte (frente), o que substitui a ordenação por profundidade. Sem alocação por quadro. */
  const FAIXAS = 12;
  function buffers(o, n) { o.X = new Float32Array(n); o.Y = new Float32Array(n); o.R = new Float32Array(n); o.A = new Float32Array(n); o.F = new Uint8Array(n); o.O = new Uint16Array(n); o.C = new Uint32Array(FAIXAS); }
  function dots(ctx, o, n) {
    const { X, Y, R, A, F, O, C } = o; C.fill(0);
    for (let i = 0; i < n; i++) { const f = Math.min(FAIXAS - 1, (A[i] * FAIXAS) | 0); F[i] = f; C[f]++; }
    for (let f = 0, ini = 0; f < FAIXAS; f++) { const c = C[f]; C[f] = ini; ini += c; }
    for (let i = 0; i < n; i++) O[C[F[i]]++] = i;
    for (let f = 0, ini = 0; f < FAIXAS; f++) {
      const fim = C[f]; if (fim > ini) {
        ctx.globalAlpha = (f + .5) / FAIXAS; ctx.beginPath();
        for (let k = ini; k < fim; k++) { const i = O[k], x = X[i], y = Y[i], r = R[i]; ctx.moveTo(x + r, y); ctx.arc(x, y, r, 0, 6.283); }
        ctx.fill();
      }
      ini = fim;
    }
    ctx.globalAlpha = 1;
  }
  // orb pequeno (< 140 px) a 30 quadros por segundo: o olho não vê diferença e a GPU agradece
  const passo = o => (o.w < 140 ? 1000 / 30 : 1000 / 60) - 2;

  const initOrbs = (scope = document) => $$('canvas[data-orb]', scope).forEach(cv => { if (!cv._orb) cv._orb = new Orb(cv, cv.dataset.orb); });
  initOrbs();
  addEventListener('resize', () => Orb.all.forEach(o => { o.resize(); if (reduce) o.draw(); }));
  matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => Orb.all.forEach(o => o.recolor()));   // cor guardada: relê só quando o tema do sistema muda

  /* ── Marca viva: os pontos da marca se soltam e viram o orb enquanto a IA trabalha ──
     <canvas data-mark-live="projetos" [data-cycle]>; precisa de dist/vertice-marks.js. el._live.think(true|false). */
  const ease3 = x => x < .5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2;
  class LiveMark {
    constructor(cv) {
      this.cv = cv; this.ctx = cv.getContext('2d'); this.pts = (window.VT_MARKS || {})[cv.dataset.markLive] || [];
      const n = this.pts.length, g = Math.PI * (3 - Math.sqrt(5));
      this.sph = this.pts.map((_, i) => { const y = 1 - (i / Math.max(1, n - 1)) * 2, r = Math.sqrt(1 - y * y), th = g * i; return [Math.cos(th) * r, y, Math.sin(th) * r]; });
      this.t = 0; this.k = 0; this.goal = 0; this.rot = 0; this.visible = true; buffers(this, n); this.size(); this.color = getComputedStyle(cv).color;
      Orb.vis.observe(cv); Orb.all.push(this);
      if (reduce) this.draw(); else requestAnimationFrame(n2 => this.frame(n2));
    }
    size() { const d = Math.min(devicePixelRatio || 1, 2), r = this.cv.getBoundingClientRect(); this.w = Math.max(16, r.width); this.cv.width = this.w * d; this.cv.height = this.w * d; this.ctx.setTransform(d, 0, 0, d, 0, 0); }
    resize() { this.size(); } recolor() { this.color = getComputedStyle(this.cv).color; if (reduce) this.draw(); }
    think(on) { this.goal = on ? 1 : 0; if (reduce) { this.k = this.goal; this.draw(); } }
    get thinking() { return this.goal === 1; }
    frame(now) {
      if (this.cv.isConnected) this.seen = true;
      else if (this.seen) { Orb.all.splice(Orb.all.indexOf(this), 1); Orb.vis.unobserve(this.cv); return; }
      const dt = Math.min(.05, (now - (this.last || now)) / 1000); this.last = now;
      if (this.visible && !document.hidden) { this.t += dt; const d = this.goal - this.k; this.k += Math.sign(d) * Math.min(Math.abs(d), dt / .9); this.rot += dt * (.25 + 1.1 * ease3(this.k));
        if (now - (this.drawn || 0) >= passo(this)) { this.drawn = now; this.draw(); } }
      requestAnimationFrame(n2 => this.frame(n2));
    }
    draw() {
      const { ctx, w, pts, sph, X, Y, R: RR, A } = this, s = w / 176, R = w * .36, c = w / 2, e = ease3(this.k), cr = Math.cos(this.rot), sr = Math.sin(this.rot);
      for (let i = 0; i < pts.length; i++) {
        const [mx, my] = pts[i], [x0, y0, z0] = sph[i], x = x0 * cr + z0 * sr, z = -x0 * sr + z0 * cr, br = 1 + .03 * Math.sin(this.t * 1.3 + i * .2);
        const ax = (mx - 40) * s, ay = (my - 40) * s, bx = c + x * R * br, by = c + (y0 * .94 - z * .34) * R * br;
        const wob = (1 - e) * Math.sin(this.t * 1.6 + mx * .08 + my * .05) * .6 * s;
        const dd = (e * (y0 * .34 + z * .94) + 1) / 2;
        X[i] = ax + (bx - ax) * e; Y[i] = ay + (by - ay) * e + wob; A[i] = 1 - e * (1 - (.2 + .8 * dd)); RR[i] = 4.1 * s * (1 - e * .45 + e * .5 * dd);
      }
      ctx.clearRect(0, 0, w, w); ctx.fillStyle = this.color;
      dots(ctx, this, pts.length);
    }
  }
  window.VtLiveMark = LiveMark;
  $$('canvas[data-mark-live]').forEach(cv => {
    const L = cv._live = new LiveMark(cv);
    if (cv.hasAttribute('data-cycle') && !reduce) {
      const say = cv.parentElement.querySelector('[data-live-text]'), idle = say ? say.textContent : '';
      setInterval(() => { L.think(!L.thinking); if (say) say.textContent = L.thinking ? (cv.dataset.say || 'Pensando…') : idle; }, 3400);
    }
  });

  /* troca de estado: [data-orb-set] dentro de [data-orb-scope] */
  $$('[data-orb-scope]').forEach(scope => {
    const big = scope.querySelector('canvas[data-orb]'), lbl = scope.querySelector('[data-orb-text]'), mini = scope.querySelector('.ds-orb-label canvas');
    $$('[data-orb-set]', scope).forEach(b => b.addEventListener('click', () => {
      $$('[data-orb-set]', scope).forEach(x => x.setAttribute('aria-pressed', String(x === b)));
      const m = b.dataset.orbSet; big && big._orb && big._orb.set(m); mini && mini._orb && mini._orb.set(m);
      if (lbl) lbl.textContent = b.dataset.say || m;
    }));
  });

  /* ── Botão assíncrono: reação no mesmo quadro ── */
  const toastZone = document.createElement('div'); toastZone.className = 'toast-zone'; toastZone.setAttribute('aria-live', 'polite'); document.body.appendChild(toastZone);
  const toast = (msg, undo) => {
    const t = document.createElement('div'); t.className = 'toast'; t.textContent = msg;
    if (undo) { const b = document.createElement('button'); b.textContent = 'Desfazer'; b.onclick = () => { undo(); close(); }; t.appendChild(b); }
    toastZone.appendChild(t);
    const close = () => { t.classList.add('out'); setTimeout(() => t.remove(), 300); };
    setTimeout(close, undo ? 6000 : 3200);
  };
  window.vtToast = toast;
  $$('[data-async]').forEach(btn => {
    const lbl = btn.querySelector('.btn-lbl'), idle = lbl ? lbl.textContent : '';
    const cv = document.createElement('canvas'); cv.className = 'btn-orb orb'; cv.dataset.orb = 'pensando'; cv.dataset.n = '70';
    btn.prepend(cv);
    btn.addEventListener('click', () => {
      if (btn.classList.contains('is-busy')) return;
      btn.classList.add('is-busy'); btn.setAttribute('aria-busy', 'true');
      if (!cv._orb) cv._orb = new Orb(cv, 'pensando');
      if (lbl) { lbl.textContent = btn.dataset.busy || 'Trabalhando…'; lbl.classList.add('shimmer'); }
      setTimeout(() => {
        const fail = btn.dataset.async === 'fail';
        btn.classList.remove('is-busy'); btn.removeAttribute('aria-busy'); btn.classList.add(fail ? 'is-fail' : 'is-done');
        if (lbl) { lbl.classList.remove('shimmer'); lbl.textContent = fail ? (btn.dataset.fail || 'Falhou. Tentar de novo') : (btn.dataset.done || 'Pronto'); }
        if (btn.dataset.toast) toast(btn.dataset.toast);
        setTimeout(() => { btn.classList.remove('is-done', 'is-fail'); if (lbl) lbl.textContent = idle; }, fail ? 2600 : 1800);
      }, +btn.dataset.ms || 1600);
    });
  });

  /* ── Progresso com cancelar (> 10 s) ── */
  $$('[data-progress-demo]').forEach(box => {
    const bar = box.querySelector('.progress i'), txt = box.querySelector('[data-pct]'), go = box.querySelector('[data-go]'), stop = box.querySelector('[data-stop]');
    let timer = null, v = 0;
    const reset = () => { clearInterval(timer); timer = null; v = 0; bar.style.width = '0'; txt.textContent = '0%'; go.hidden = false; stop.hidden = true; };
    go.addEventListener('click', () => {
      go.hidden = true; stop.hidden = false; v = 2; bar.style.width = '2%'; txt.textContent = 'falta ~12 s';
      timer = setInterval(() => {
        v = Math.min(100, v + 4 + Math.random() * 6); bar.style.width = v + '%';
        txt.textContent = v >= 100 ? 'pronto' : Math.round(v) + '% · falta ~' + Math.max(1, Math.round((100 - v) / 8)) + ' s';
        if (v >= 100) { clearInterval(timer); toast(box.dataset.done || 'Pronto'); setTimeout(reset, 1600); }
      }, 600);
    });
    stop.addEventListener('click', () => { reset(); toast('Cancelado. Nada foi gasto.'); });
  });

  /* ── Esqueleto que vira conteúdo ── */
  $$('[data-skel-demo]').forEach(box => {
    const sk = box.querySelector('.skel'), ct = box.querySelector('[data-content]'), b = box.querySelector('button');
    b.addEventListener('click', () => {
      ct.hidden = true; sk.hidden = false; b.disabled = true;
      setTimeout(() => { sk.hidden = true; ct.hidden = false; ct.style.animation = 'vt-enter .6s var(--vt-ease-out) both'; b.disabled = false; }, 1100);
    });
  });

  /* ── Otimista: muda antes da resposta, desfaz se falhar ── */
  $$('.like').forEach(b => b.addEventListener('click', () => {
    const on = b.getAttribute('aria-pressed') !== 'true'; b.setAttribute('aria-pressed', String(on));
    const n = b.querySelector('[data-n]'); if (n) n.textContent = (+n.textContent + (on ? 1 : -1));
  }));
  $$('.toggle').forEach(b => b.addEventListener('click', () => b.setAttribute('aria-checked', String(b.getAttribute('aria-checked') !== 'true'))));
  $$('[data-toast-undo]').forEach(b => b.addEventListener('click', () => {
    const item = document.getElementById(b.dataset.toastUndo); if (!item) return;
    item.style.transition = 'opacity .24s, transform .24s var(--vt-ease-out)'; item.style.opacity = '0'; item.style.transform = 'translateX(16px)';
    setTimeout(() => { item.hidden = true; }, 240);
    toast('Item arquivado', () => { item.hidden = false; requestAnimationFrame(() => { item.style.opacity = '1'; item.style.transform = 'none'; }); });
  }));

  /* ── Luz que segue o cursor ── */
  $$('.card-flash').forEach(c => c.addEventListener('pointermove', e => {
    const r = c.getBoundingClientRect(); c.style.setProperty('--mx', (e.clientX - r.left) + 'px'); c.style.setProperty('--my', (e.clientY - r.top) + 'px');
  }));

  /* ── Demos de movimento: tocar ao entrar e ao clicar ── */
  const mvio = new IntersectionObserver(es => es.forEach(e => { if (e.isIntersecting) { e.target.classList.add('play'); mvio.unobserve(e.target); } }), { threshold: .5 });
  $$('.mv[data-play]').forEach(m => {
    mvio.observe(m);
    m.addEventListener('click', () => { m.classList.remove('play'); void m.offsetWidth; requestAnimationFrame(() => m.classList.add('play')); });
  });

  /* ── Números que contam ── */
  const cio = new IntersectionObserver(es => es.forEach(e => {
    if (!e.isIntersecting) return; cio.unobserve(e.target);
    const el = e.target, to = +el.dataset.count, dec = +(el.dataset.dec || 0), pre = el.dataset.pre || '', suf = el.dataset.suf || '', t0 = performance.now();
    const f = now => { const k = Math.min(1, (now - t0) / 1100), v = to * (1 - Math.pow(1 - k, 3));
      el.textContent = pre + v.toLocaleString('pt-BR', { minimumFractionDigits: dec, maximumFractionDigits: dec }) + suf; if (k < 1) requestAnimationFrame(f); };
    reduce ? (el.textContent = pre + to.toLocaleString('pt-BR', { minimumFractionDigits: dec, maximumFractionDigits: dec }) + suf) : requestAnimationFrame(f);
  }), { threshold: .6 });
  $$('[data-count]').forEach(el => cio.observe(el));

  /* ── Copiar cor ── */
  $$('.swatch[data-hex]').forEach(s => s.addEventListener('click', () => {
    const hex = s.dataset.hex; (navigator.clipboard ? navigator.clipboard.writeText(hex) : Promise.reject()).then(() => toast('Copiado ' + hex), () => toast(hex));
  }));

  /* ── Ação dentro do campo (vitrine): liga e desliga na hora ── */
  $$('[data-show-pass]').forEach(b => b.addEventListener('click', () => { const i = b.parentElement.querySelector('input'); const ver = i.type === 'password'; i.type = ver ? 'text' : 'password'; b.classList.toggle('on', ver); b.setAttribute('aria-label', ver ? 'Esconder senha' : 'Mostrar senha'); }));
  $$('[data-clear]').forEach(b => b.addEventListener('click', () => { const i = b.parentElement.querySelector('input'); i.value = ''; i.focus(); }));

  /* ── Seção atual no menu de seções ── */
  const links = $$('.ds-sec-nav a'), map = new Map(links.map(a => [a.getAttribute('href').slice(1), a]));
  const sio = new IntersectionObserver(es => es.forEach(e => { if (e.isIntersecting) { links.forEach(a => a.classList.remove('on')); const a = map.get(e.target.id); a && a.classList.add('on'); } }),
    { rootMargin: '-45% 0px -50% 0px' });
  $$('section[id]').forEach(s => map.has(s.id) && sio.observe(s));
})();
