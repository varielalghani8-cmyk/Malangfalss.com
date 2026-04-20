<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Waterfall Malang — Sistem Informasi Air Terjun Malang Raya</title>
<link rel="stylesheet" href="https://unpkg.com/leaflet/dist/leaflet.css"/>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&family=Nunito:wght@300;400;500;600;700&family=Crimson+Text:ital,wght@0,400;0,600;1,400&display=swap" rel="stylesheet">
<style>

:root {
  --bg:#1a1612;
  --bg2:#201c17;
  --bg3:#27221c;
  --surface:#2e2820;
  --surface2:#362f26;
  --border:rgba(200,170,120,.1);
  --border2:rgba(200,170,120,.2);
  --ink:#ede5d8;
  --ink2:#b8a990;
  --ink3:#7a6e5a;
  --cyan:#c4955a;
  --cyan2:#a87840;
  --cyan3:rgba(196,149,90,.12);
  --cyan4:rgba(196,149,90,.06);
  --green:#c4955a;
  --green2:rgba(196,149,90,.12);
  --amber:#d4a843;
  --amber2:rgba(212,168,67,.12);
  --red:#c96060;
  --red2:rgba(201,96,96,.12);
  --purple:#b89fcc;
  --r:8px;
  --r2:12px;
  --r3:16px;
  --font-display:'Playfair Display',Georgia,serif;
  --font-body:'Nunito',system-ui,sans-serif;
  --font-mono:'Crimson Text',Georgia,serif;
}
*,*::before,*::after {
  box-sizing:border-box;
  margin:0;
  padding:0;
}
html{scroll-behavior:smooth}
body {
  font-family:'Nunito',sans-serif;
  background:var(--bg);
  color:var(--ink);
  overflow-x:hidden;
  min-height:100vh;
}

/* ── LOADER ── */
#loader {
  position:fixed;
  inset:0;
  z-index:9999;
  background:var(--bg);
  display:flex;
  flex-direction:column;
  align-items:center;
  justify-content:center;
  gap:24px;
  transition:opacity .6s,visibility .6s;
}
#loader.out { opacity:0; visibility:hidden; }

.ld-drop-scene {
  position:relative;
  width:80px;
  height:90px;
  display:flex;
  align-items:flex-end;
  justify-content:center;
}
.ld-drop {
  width:16px;
  height:22px;
  background:#29b6d8;
  border-radius:50% 50% 50% 50%/30% 30% 70% 70%;
  position:absolute;
  top:0;
  left:50%;
  transform:translateX(-50%);
  opacity:0;
  box-shadow:0 0 14px rgba(41,182,216,.6);
  animation:dropFall 1.8s ease-in infinite;
}
.ld-drop:nth-child(2){animation-delay:.6s}
.ld-drop:nth-child(3){animation-delay:1.2s}
.ld-ripple {
  position:absolute;
  bottom:0;
  left:50%;
  transform:translateX(-50%);
  width:0;height:0;
  border:2px solid rgba(41,182,216,.7);
  border-radius:50%;
  opacity:0;
  animation:rippleOut 1.8s ease-out infinite;
}
.ld-ripple:nth-child(4){animation-delay:.25s}
.ld-ripple:nth-child(5){animation-delay:.5s}
@keyframes dropFall{
  0%{top:0;opacity:0;transform:translateX(-50%) scaleY(1)}
  8%{opacity:1}
  72%{top:66px;opacity:1;transform:translateX(-50%) scaleY(1)}
  80%{top:70px;opacity:0;transform:translateX(-50%) scaleY(.25) scaleX(1.8)}
  100%{top:70px;opacity:0}
}
@keyframes rippleOut{
  0%{width:0;height:0;opacity:.9;bottom:4px}
  100%{width:72px;height:18px;opacity:0;bottom:0}
}

.ld-logo {
  font-family:'Playfair Display',Georgia,serif;
  font-size:2rem;
  font-weight:700;
  color:#29b6d8;
  letter-spacing:.08em;
  text-align:center;
}
.ld-logo-chars { display:flex; gap:1px; justify-content:center; }
.ld-logo-chars .ch {
  display:inline-block;
  opacity:0;
  transform:translateY(-18px);
  animation:charDrop .5s cubic-bezier(.22,1,.36,1) forwards;
}
.ld-logo span {
  color:var(--ink3);
  font-weight:400;
  font-size:.8rem;
  display:block;
  letter-spacing:.16em;
  margin-top:3px;
  opacity:0;
  animation:fadeUp .6s ease .9s forwards;
}
@keyframes charDrop{
  from{opacity:0;transform:translateY(-18px)}
  to{opacity:1;transform:translateY(0)}
}
@keyframes fadeUp{
  from{opacity:0;transform:translateY(8px)}
  to{opacity:1;transform:translateY(0)}
}

.ld-bar {
  width:160px;height:2px;
  background:rgba(255,255,255,.06);
  border-radius:2px;overflow:hidden;
}
.ld-fill {
  height:100%;
  background:linear-gradient(90deg,#1a9dbf,#29b6d8);
  border-radius:2px;
  animation:ldFill 1.8s ease forwards;
}
@keyframes ldFill{from{width:0}to{width:100%}}
.ld-sub {
  font-size:.68rem;color:var(--ink3);
  letter-spacing:.14em;text-transform:uppercase;
  font-family:'Crimson Text',Georgia,serif;
  opacity:0;animation:fadeUp .6s ease 1s forwards;
}

/* ── LAYOUT ── */
.app-shell {
  display:flex;
  min-height:100vh;
}

/* ── SIDEBAR ── */
.sidebar {
  width:220px;
  flex-shrink:0;
  background:var(--bg2);
  border-right:1px solid var(--border);
  display:flex;
  flex-direction:column;
  position:sticky;
  top:0;
  height:100vh;
  overflow-y:auto;
  z-index:200;
}
.sb-brand {
  padding:20px 16px 16px;
  border-bottom:1px solid var(--border);
}
.sb-logo {
  font-family:'Playfair Display',Georgia,serif;
  font-size:1.25rem;
  font-weight:700;
  color:var(--cyan);
  letter-spacing:.06em;
  line-height:1.1;
}
.sb-logo span {
  color:var(--ink3);
  font-weight:400;
  font-size:.75rem;
  display:block;
  letter-spacing:.1em;
  margin-top:1px;
}
.sb-status {
  display:flex;
  align-items:center;
  gap:6px;
  margin-top:8px;
  font-size:.65rem;
  color:var(--ink3);
  font-family:'Crimson Text',Georgia,serif;
}
.sb-dot {
  width:6px;
  height:6px;
  border-radius:50%;
  background:var(--cyan);
  animation:sbPulse 2s infinite;
}
@keyframes sbPulse{0%,100%{opacity:1}50%{opacity:.35}}

.sb-section-label {
  padding:16px 16px 6px;
  font-size:.6rem;
  font-weight:600;
  color:var(--ink3);
  letter-spacing:.14em;
  text-transform:uppercase;
  font-family:'Crimson Text',Georgia,serif;
}
.sb-nav {
  list-style:none;
  padding:0 8px;
}
.sb-nav li{margin-bottom:2px}
.sb-nav a {
  display:flex;
  align-items:center;
  gap:10px;
  padding:8px 10px;
  border-radius:var(--r);
  font-size:.82rem;
  font-weight:500;
  color:var(--ink2);
  cursor:pointer;
  transition:all .15s;
  text-decoration:none;
}
.sb-nav a:hover {
  background:var(--surface);
  color:var(--ink);
}
.sb-nav a.active {
  background:var(--cyan3);
  color:var(--cyan);
  border:1px solid rgba(196,149,90,.2);
}
#sbf-mudah.active {
  background:rgba(34,197,94,.1);
  color:#22c55e;
  border:1px solid rgba(34,197,94,.25);
}
.sb-nav a .sb-icon {
  font-size:.9rem;
  width:16px;
  text-align:center;
  flex-shrink:0;
}
.sb-nav a .sb-badge {
  margin-left:auto;
  background:var(--surface2);
  color:var(--ink3);
  padding:1px 6px;
  border-radius:4px;
  font-size:.6rem;
  font-family:'Crimson Text',Georgia,serif;
}
.sb-nav a.active .sb-badge {
  background:rgba(196,149,90,.2);
  color:var(--cyan);
}

.sb-alert-box {
  margin:8px;
  background:var(--red2);
  border:1px solid rgba(255,77,77,.25);
  border-radius:var(--r);
  padding:10px 12px;
  cursor:pointer;
}
.sb-alert-title {
  font-size:.68rem;
  font-weight:600;
  color:var(--red);
  letter-spacing:.06em;
  margin-bottom:3px;
  display:flex;
  align-items:center;
  gap:5px;
}
.sb-alert-body {
  font-size:.65rem;
  color:var(--ink2);
  line-height:1.5;
}
.sb-alert-box.amber {
  background:var(--amber2);
  border-color:rgba(255,176,32,.25);
}
.sb-alert-box.amber .sb-alert-title{color:var(--amber)}
.sb-alert-box.green {
  background:var(--cyan3);
  border-color:rgba(196,149,90,.25);
}
.sb-alert-box.green .sb-alert-title{color:var(--cyan)}

.sb-footer {
  margin-top:auto;
  padding:12px 16px;
  border-top:1px solid var(--border);
  font-size:.6rem;
  color:var(--ink3);
  font-family:'Crimson Text',Georgia,serif;
}

@media(max-width:768px){
  .sidebar{display:none}
  .mobile-topbar{display:flex}
}

/* ── MOBILE TOPBAR ── */
.mobile-topbar {
  display:none;
  position:sticky;
  top:0;
  z-index:300;
  background:var(--bg2);
  border-bottom:1px solid var(--border);
  padding:12px 16px;
  align-items:center;
  justify-content:space-between;
}
.mob-brand {
  font-family:'Playfair Display',Georgia,serif;
  font-size:1rem;
  font-weight:700;
  color:var(--cyan);
}
.mob-tabs {
  display:flex;
  gap:4px;
  overflow-x:auto;
}
.mob-tab {
  padding:5px 12px;
  border-radius:20px;
  font-size:.7rem;
  font-weight:600;
  border:1px solid var(--border);
  background:transparent;
  color:var(--ink2);
  cursor:pointer;
  transition:all .15s;
  white-space:nowrap;
}
.mob-tab.active {
  background:var(--cyan3);
  color:var(--cyan);
  border-color:rgba(196,149,90,.3);
}

/* ── MAIN CONTENT ── */
.main-content {
  flex:1;
  min-width:0;
}

/* ── PAGES ── */
.page{display:none}.page.active{display:block}

/* ═══════════ EXPLORE PAGE ═══════════ */
/* Hero */
.hero {
  position:relative;
  min-height:340px;
  background:linear-gradient(160deg,#1a1208 0%,#1e170a 40%,#251d0d 70%,#180f07 100%);
  overflow:hidden;
  display:flex;
  align-items:flex-end;
}
.hero-grid-lines {
  position:absolute;
  inset:0;
  background-image:linear-gradient(rgba(126,201,126,.04) 1px,transparent 1px),linear-gradient(90deg,rgba(126,201,126,.04) 1px,transparent 1px);
  background-size:40px 40px;
  pointer-events:none;
}
.hero-glow {
  position:absolute;
  top:-80px;
  right:5%;
  width:400px;
  height:400px;
  background:radial-gradient(circle,rgba(196,149,90,.08) 0%,transparent 70%);
  pointer-events:none;
}
.hero-content {
  position:relative;
  z-index:2;
  padding:40px clamp(20px,4vw,48px) 36px;
  max-width:700px;
}
.hero-eyebrow {
  display:flex;
  align-items:center;
  gap:8px;
  margin-bottom:14px;
  font-family:'Crimson Text',Georgia,serif;
  font-size:.65rem;
  color:var(--cyan);
  letter-spacing:.12em;
  text-transform:uppercase;
}
.hero-eyebrow::before {
  content:'';
  width:18px;
  height:1px;
  background:var(--cyan);
  opacity:.5;
}
.hero-title {
  font-family:'Playfair Display',Georgia,serif;
  font-size:clamp(2.2rem,5vw,3.6rem);
  font-weight:700;
  line-height:1;
  color:#fff;
  margin-bottom:10px;
  letter-spacing:.02em;
}
.hero-title .accent{color:var(--cyan)}
.hero-desc {
  font-size:.88rem;
  line-height:1.7;
  color:var(--ink2);
  max-width:480px;
  margin-bottom:24px;
}
.hero-stats {
  display:flex;
  gap:24px;
  flex-wrap:wrap;
}
.hstat {
  display:flex;
  flex-direction:column;
  gap:2px;
}
.hstat-val {
  font-family:'Playfair Display',Georgia,serif;
  font-size:1.6rem;
  font-weight:700;
  color:var(--cyan);
  line-height:1;
}
.hstat-lbl {
  font-size:.62rem;
  color:var(--ink3);
  text-transform:uppercase;
  letter-spacing:.1em;
  font-family:'Crimson Text',Georgia,serif;
}

/* Filter bar */
.filter-bar {
  background:var(--bg2);
  border-bottom:1px solid var(--border);
  padding:12px clamp(16px,4vw,48px);
  display:flex;
  gap:8px;
  flex-wrap:wrap;
  align-items:center;
  position:sticky;
  top:0;
  z-index:100;
}
.fsw {
  flex:1;
  min-width:180px;
  position:relative;
}
.fsw-ico {
  position:absolute;
  left:11px;
  top:50%;
  transform:translateY(-50%);
  font-size:.8rem;
  color:var(--ink3);
  pointer-events:none;
}
.fsw input {
  width:100%;
  padding:8px 12px 8px 32px;
  border:1px solid var(--border2);
  border-radius:var(--r);
  background:var(--surface);
  color:var(--ink);
  font-family:'Nunito',sans-serif;
  font-size:.82rem;
  outline:none;
  transition:border-color .15s;
}
.fsw input:focus {
  border-color:var(--cyan2);
  box-shadow:0 0 0 2px rgba(196,149,90,.08);
}
.fsw input::placeholder{color:var(--ink3)}
.tag-btn {
  padding:6px 14px;
  border-radius:var(--r);
  border:1px solid var(--border2);
  background:transparent;
  color:var(--ink2);
  font-family:'Nunito',sans-serif;
  font-size:.75rem;
  font-weight:500;
  cursor:pointer;
  transition:all .15s;
  white-space:nowrap;
}
.tag-btn:hover {
  border-color:var(--border2);
  color:var(--ink);
  background:var(--surface);
}
.tag-btn.on {
  background:var(--surface2);
  border-color:var(--border2);
  color:var(--ink);
}
.tag-btn.on.t-mudah {
  border-color:rgba(34,197,94,.45);
  color:#22c55e;
  background:rgba(34,197,94,.1);
}
.tag-btn.on.t-sedang {
  border-color:rgba(255,176,32,.4);
  color:var(--amber);
  background:var(--amber2);
}
.tag-btn.on.t-sulit {
  border-color:rgba(255,77,77,.4);
  color:var(--red);
  background:var(--red2);
}
.tag-btn.on.t-fav {
  border-color:rgba(167,139,250,.4);
  color:var(--purple);
  background:rgba(167,139,250,.1);
}
.fc-count {
  margin-left:auto;
  font-family:'Crimson Text',Georgia,serif;
  font-size:.65rem;
  color:var(--ink3);
  white-space:nowrap;
}
.fc-count b{color:var(--cyan)}

/* Grid */
.grid-wrap {
  max-width:1400px;
  padding:28px clamp(16px,4vw,48px) 60px;
}
.gsec-hd {
  display:flex;
  align-items:center;
  gap:12px;
  margin-bottom:20px;
}
.gsec-title {
  font-family:'Playfair Display',Georgia,serif;
  font-size:1.3rem;
  font-weight:700;
  color:var(--ink);
}
.gsec-line {
  flex:1;
  height:1px;
  background:var(--border);
}
.cgrid {
  display:grid;
  grid-template-columns:repeat(auto-fill,minmax(280px,1fr));
  gap:16px;
}

/* Card */
.card {
  background:var(--surface);
  border-radius:var(--r2);
  border:1px solid var(--border);
  overflow:hidden;
  cursor:pointer;
  transition:transform .25s,border-color .2s,box-shadow .25s;
  animation:cardIn .35s ease both;
}
@keyframes cardIn{from {
  opacity:0;
  transform:translateY(12px);
}to {
  opacity:1;
  transform:none;
}}
.card:hover {
  transform:translateY(-4px);
  box-shadow:0 12px 40px rgba(0,0,0,.4);
  border-color:var(--border2);
}
.card.diff-mudah:hover{border-color:rgba(34,197,94,.35)}
.card.diff-sedang:hover{border-color:rgba(255,176,32,.3)}
.card.diff-sulit:hover{border-color:rgba(255,77,77,.3)}

.cimg-wrap {
  position:relative;
  height:180px;
  overflow:hidden;
  background:#1a1c14;
}
.cimg {
  width:100%;
  height:100%;
  object-fit:cover;
  display:block;
  transition:transform .4s;
  filter:brightness(.85);
}
.card:hover .cimg {
  transform:scale(1.05);
  filter:brightness(.95);
}
.cimg-overlay {
  position:absolute;
  inset:0;
  background:linear-gradient(to top,rgba(26,28,20,.92) 0%,transparent 60%);
}

/* Hazard badge - NEW */
.c-hazard {
  position:absolute;
  top:10px;
  left:10px;
  display:flex;
  align-items:center;
  gap:5px;
  padding:3px 9px;
  border-radius:4px;
  font-size:.62rem;
  font-weight:600;
  letter-spacing:.06em;
  font-family:'Crimson Text',Georgia,serif;
  backdrop-filter:blur(8px);
}
.hz-aman {
  background:rgba(196,149,90,.15);
  border:1px solid rgba(196,149,90,.4);
  color:var(--cyan);
}
.hz-waspada {
  background:rgba(255,176,32,.15);
  border:1px solid rgba(255,176,32,.4);
  color:var(--amber);
}
.hz-bahaya {
  background:rgba(255,77,77,.15);
  border:1px solid rgba(255,77,77,.4);
  color:var(--red);
}
.hz-dot {
  width:5px;
  height:5px;
  border-radius:50%;
  background:currentColor;
  animation:sbPulse 1.5s infinite;
}

.cdiff {
  position:absolute;
  top:10px;
  right:10px;
  padding:3px 9px;
  border-radius:4px;
  font-size:.6rem;
  font-weight:700;
  letter-spacing:.08em;
  text-transform:uppercase;
  backdrop-filter:blur(8px);
}
.d-mudah {
  background:rgba(34,197,94,.15);
  border:1px solid rgba(34,197,94,.3);
  color:#22c55e;
}
.d-sedang {
  background:rgba(255,176,32,.15);
  border:1px solid rgba(255,176,32,.3);
  color:var(--amber);
}
.d-sulit {
  background:rgba(255,77,77,.15);
  border:1px solid rgba(255,77,77,.3);
  color:var(--red);
}

.cfave {
  position:absolute;
  bottom:10px;
  right:10px;
  width:28px;
  height:28px;
  border-radius:6px;
  background:rgba(26,28,20,.75);
  border:1px solid var(--border2);
  display:flex;
  align-items:center;
  justify-content:center;
  font-size:.78rem;
  cursor:pointer;
  transition:transform .2s,background .15s;
}
.cfave:hover {
  transform:scale(1.15);
  background:rgba(167,139,250,.2);
}

.cbody{padding:14px 16px 16px}
.cname {
  font-family:'Playfair Display',Georgia,serif;
  font-size:1.05rem;
  font-weight:700;
  color:var(--ink);
  margin-bottom:2px;
  letter-spacing:.02em;
}
.cloc {
  font-size:.7rem;
  color:var(--ink3);
  display:flex;
  align-items:center;
  gap:4px;
  margin-bottom:10px;
  font-family:'Crimson Text',Georgia,serif;
}
.cdesc {
  font-size:.78rem;
  line-height:1.6;
  color:var(--ink2);
  margin-bottom:10px;
  display:-webkit-box;
  -webkit-line-clamp:2;
  -webkit-box-orient:vertical;
  overflow:hidden;
}

/* Difficulty bar — NEW visual indicator */
.diff-bar-wrap {
  display:flex;
  align-items:center;
  gap:6px;
  margin-bottom:10px;
}
.diff-bar-label {
  font-size:.62rem;
  color:var(--ink3);
  font-family:'Crimson Text',Georgia,serif;
  width:38px;
}
.diff-bar {
  flex:1;
  height:3px;
  background:rgba(255,255,255,.07);
  border-radius:2px;
  overflow:hidden;
}
.diff-bar-fill {
  height:100%;
  border-radius:2px;
  transition:width .5s;
}
.diff-fill-mudah {
  background:#22c55e;
  width:30%;
}
.diff-fill-sedang {
  background:var(--amber);
  width:60%;
}
.diff-fill-sulit {
  background:var(--red);
  width:100%;
}

.cmeta {
  display:flex;
  gap:6px;
  flex-wrap:wrap;
  margin-bottom:12px;
}
.mpill {
  background:var(--bg3);
  border:1px solid var(--border);
  padding:2px 8px;
  border-radius:4px;
  font-size:.67rem;
  color:var(--ink2);
  font-family:'Crimson Text',Georgia,serif;
}
.cfoot {
  display:flex;
  align-items:center;
  justify-content:space-between;
  padding-top:10px;
  border-top:1px solid var(--border);
}
.cprice {
  font-family:'Playfair Display',Georgia,serif;
  font-size:.95rem;
  font-weight:700;
  color:var(--cyan);
}
.cprice sub {
  font-size:.6rem;
  font-weight:400;
  color:var(--ink3);
  font-family:'Nunito',sans-serif;
}
.cdetail-btn {
  font-size:.72rem;
  font-weight:600;
  color:var(--cyan);
  background:none;
  border:none;
  cursor:pointer;
  display:flex;
  align-items:center;
  gap:4px;
  transition:gap .15s;
  font-family:'Nunito',sans-serif;
}
.cdetail-btn:hover{gap:8px}
.empty {
  text-align:center;
  padding:60px 20px;
  color:var(--ink3);
}
.empty-ico {
  font-size:2.5rem;
  margin-bottom:12px;
}
.empty-ttl {
  font-family:'Playfair Display',Georgia,serif;
  font-size:1.2rem;
  color:var(--ink2);
  margin-bottom:4px;
}
.empty-sub{font-size:.8rem}

/* ═══════════ DETAIL PAGE ═══════════ */
.det-hero {
  position:relative;
  height:300px;
  overflow:hidden;
}
.det-hero img {
  width:100%;
  height:100%;
  object-fit:cover;
  filter:brightness(.65);
  display:block;
}
.det-hero-overlay {
  position:absolute;
  inset:0;
  background:linear-gradient(to top,rgba(26,28,20,.97) 0%,rgba(26,28,20,.3) 60%,transparent 100%);
}
.det-back {
  position:absolute;
  top:16px;
  left:clamp(16px,4vw,48px);
  z-index:2;
  background:rgba(26,28,20,.75);
  backdrop-filter:blur(10px);
  border:1px solid var(--border2);
  border-radius:var(--r);
  padding:6px 14px;
  font-size:.75rem;
  font-weight:600;
  color:var(--ink);
  cursor:pointer;
  display:flex;
  align-items:center;
  gap:6px;
  transition:background .15s;
}
.det-back:hover{background:rgba(30,34,48,.9)}
.det-hero-info {
  position:absolute;
  bottom:0;
  left:0;
  right:0;
  padding:24px clamp(16px,4vw,48px);
  z-index:2;
}
.det-name {
  font-family:'Playfair Display',Georgia,serif;
  font-size:clamp(1.8rem,4vw,2.6rem);
  font-weight:700;
  color:#fff;
  line-height:1.1;
  margin-bottom:6px;
  letter-spacing:.02em;
}
.det-loc {
  font-size:.75rem;
  color:rgba(255,255,255,.5);
  display:flex;
  align-items:center;
  gap:5px;
  font-family:'Crimson Text',Georgia,serif;
}
.det-badges {
  display:flex;
  gap:8px;
  margin-bottom:8px;
  flex-wrap:wrap;
}

/* NEW: Large hazard indicator in detail */
.det-hazard-banner {
  margin:20px clamp(16px,4vw,48px) 0;
  padding:12px 16px;
  border-radius:var(--r2);
  display:flex;
  align-items:center;
  gap:12px;
  border:1px solid;
}
.det-hazard-banner.hz-aman {
  background:var(--cyan3);
  border-color:rgba(196,149,90,.3);
}
.det-hazard-banner.hz-waspada {
  background:var(--amber2);
  border-color:rgba(255,176,32,.3);
}
.det-hazard-banner.hz-bahaya {
  background:var(--red2);
  border-color:rgba(255,77,77,.3);
}
.dhb-icon {
  font-size:1.6rem;
  flex-shrink:0;
}
.dhb-text{flex:1}
.dhb-title {
  font-family:'Playfair Display',Georgia,serif;
  font-size:1rem;
  font-weight:700;
  color:var(--ink);
  margin-bottom:1px;
}
.dhb-sub {
  font-size:.75rem;
  color:var(--ink2);
}
.dhb-level {
  font-family:'Crimson Text',Georgia,serif;
  font-size:.7rem;
  padding:3px 9px;
  border-radius:4px;
  font-weight:600;
}
.dhb-level.lv-aman {
  background:rgba(196,149,90,.2);
  color:var(--cyan);
}
.dhb-level.lv-waspada {
  background:rgba(255,176,32,.2);
  color:var(--amber);
}
.dhb-level.lv-bahaya {
  background:rgba(255,77,77,.2);
  color:var(--red);
}

.det-body {
  max-width:1200px;
  padding:20px clamp(16px,4vw,48px) 60px;
  display:grid;
  grid-template-columns:1fr 300px;
  gap:20px;
  align-items:start;
}
@media(max-width:860px){.det-body{grid-template-columns:1fr}}
.det-main {
  display:flex;
  flex-direction:column;
  gap:16px;
}
.det-sidebar {
  display:flex;
  flex-direction:column;
  gap:14px;
}

/* Detail sections */
.det-sec {
  background:var(--surface);
  border:1px solid var(--border);
  border-radius:var(--r2);
  overflow:hidden;
}
.det-sec-head {
  padding:12px 16px;
  border-bottom:1px solid var(--border);
  display:flex;
  align-items:center;
  gap:8px;
  background:var(--bg3);
}
.det-sec-title {
  font-family:'Playfair Display',Georgia,serif;
  font-size:.9rem;
  font-weight:700;
  color:var(--ink);
  letter-spacing:.04em;
  text-transform:uppercase;
}
.det-sec-body{padding:16px}
.det-sec p {
  font-size:.85rem;
  line-height:1.8;
  color:var(--ink2);
}

/* Tag cloud */
.tag-cloud {
  display:flex;
  flex-wrap:wrap;
  gap:6px;
  margin-top:12px;
}
.tag {
  background:var(--bg3);
  border:1px solid var(--border);
  padding:3px 10px;
  border-radius:4px;
  font-size:.68rem;
  color:var(--ink2);
  font-family:'Crimson Text',Georgia,serif;
}

/* Weather card in detail */
.dw-main {
  background:linear-gradient(135deg,#130e07 0%,#1a1309 50%,#21190c 100%);
  border-radius:var(--r2);
  padding:18px;
  margin-bottom:14px;
  position:relative;
  overflow:hidden;
  border:1px solid rgba(196,149,90,.12);
}
.dw-main::before {
  content:'';
  position:absolute;
  top:-40px;
  right:-40px;
  width:140px;
  height:140px;
  background:radial-gradient(circle,rgba(196,149,90,.08) 0%,transparent 70%);
  pointer-events:none;
}
.dw-row {
  display:flex;
  justify-content:space-between;
  align-items:flex-start;
  margin-bottom:14px;
}
.dw-temp {
  font-family:'Playfair Display',Georgia,serif;
  font-size:2.8rem;
  font-weight:700;
  line-height:1;
  color:#fff;
}
.dw-temp sup {
  font-size:1rem;
  vertical-align:super;
}
.dw-cond {
  font-size:.78rem;
  opacity:.6;
  margin-top:2px;
}
.dw-status-mini {
  display:inline-flex;
  align-items:center;
  gap:5px;
  padding:4px 10px;
  border-radius:4px;
  font-size:.68rem;
  font-weight:600;
  font-family:'Crimson Text',Georgia,serif;
}
.dws-aman {
  background:rgba(196,149,90,.12);
  color:var(--cyan);
  border:1px solid rgba(196,149,90,.25);
}
.dws-waspada {
  background:rgba(255,176,32,.12);
  color:var(--amber);
  border:1px solid rgba(255,176,32,.25);
}
.dws-bahaya {
  background:rgba(255,77,77,.12);
  color:var(--red);
  border:1px solid rgba(255,77,77,.25);
}
.dw-grid {
  display:grid;
  grid-template-columns:1fr 1fr;
  gap:7px;
}
.dw-cell {
  background:rgba(255,255,255,.04);
  border:1px solid rgba(255,255,255,.06);
  border-radius:var(--r);
  padding:9px 11px;
}
.dw-cell-lbl {
  font-size:.58rem;
  opacity:.45;
  letter-spacing:.12em;
  text-transform:uppercase;
  margin-bottom:2px;
  font-family:'Crimson Text',Georgia,serif;
}
.dw-cell-val {
  font-family:'Playfair Display',Georgia,serif;
  font-size:.92rem;
  font-weight:700;
  color:var(--ink);
}
.dw-forecast {
  display:flex;
  gap:7px;
  overflow-x:auto;
  padding-bottom:4px;
  scrollbar-width:none;
}
.dw-forecast::-webkit-scrollbar{display:none}
.dwfc {
  flex:0 0 72px;
  background:var(--surface2);
  border:1px solid var(--border);
  border-radius:var(--r);
  padding:9px 7px;
  text-align:center;
}
.dwfc-day {
  font-size:.58rem;
  font-weight:600;
  color:var(--cyan);
  letter-spacing:.06em;
  text-transform:uppercase;
  margin-bottom:3px;
  font-family:'Crimson Text',Georgia,serif;
}
.dwfc-ico {
  font-size:1.1rem;
  margin:2px 0;
}
.dwfc-t {
  font-family:'Playfair Display',Georgia,serif;
  font-size:.85rem;
  font-weight:700;
  color:var(--ink);
}

/* info rows */
.info-row {
  display:flex;
  justify-content:space-between;
  align-items:flex-start;
  padding:8px 0;
  border-bottom:1px solid var(--border);
  font-size:.8rem;
}
.info-row:last-child{border-bottom:none}
.info-row-lbl {
  color:var(--ink3);
  font-family:'Crimson Text',Georgia,serif;
  font-size:.72rem;
}
.info-row-val {
  font-weight:500;
  color:var(--ink);
  text-align:right;
  max-width:55%;
}

/* tiket */
.tkt-table {
  width:100%;
  border-collapse:collapse;
  font-size:.8rem;
}
.tkt-table tr{border-bottom:1px solid var(--border)}
.tkt-table tr:last-child{border-bottom:none}
.tkt-table td{padding:8px 0}
.tkt-table td:first-child{color:var(--ink2)}
.tkt-table td:last-child {
  text-align:right;
  font-family:'Playfair Display',Georgia,serif;
  font-weight:700;
  color:var(--cyan);
  font-size:.88rem;
}
.tkt-note {
  font-size:.72rem;
  color:var(--ink3);
  margin-top:10px;
  padding:9px 12px;
  background:var(--bg3);
  border-radius:var(--r);
  border:1px solid var(--border);
  line-height:1.6;
}

/* fasilitas */
.fac-grid {
  display:grid;
  grid-template-columns:1fr 1fr;
  gap:7px;
}
.fac-item {
  display:flex;
  align-items:center;
  gap:8px;
  padding:7px 9px;
  background:var(--bg3);
  border:1px solid var(--border);
  border-radius:var(--r);
  font-size:.76rem;
  color:var(--ink2);
}
.fac-ico {
  font-size:.95rem;
  flex-shrink:0;
}

/* tips */
.tips-list {
  list-style:none;
  display:flex;
  flex-direction:column;
  gap:7px;
}
.tips-list li {
  display:flex;
  align-items:flex-start;
  gap:9px;
  font-size:.8rem;
  color:var(--ink2);
  line-height:1.5;
}
.tips-list li::before {
  content:'//';
  color:var(--cyan);
  flex-shrink:0;
  font-family:'Crimson Text',Georgia,serif;
  font-size:.65rem;
  margin-top:3px;
  opacity:.7;
}

/* Offline map button - NEW */
.offline-map-btn {
  display:flex;
  align-items:center;
  gap:8px;
  width:100%;
  padding:10px 14px;
  background:var(--bg3);
  border:1px solid var(--border2);
  border-radius:var(--r);
  font-size:.8rem;
  color:var(--ink);
  cursor:pointer;
  transition:all .15s;
  font-family:'Nunito',sans-serif;
  margin-bottom:7px;
}
.offline-map-btn:hover {
  background:var(--surface2);
  border-color:rgba(196,149,90,.3);
  color:var(--cyan);
}
.offline-map-btn .omico{font-size:1rem}
.offline-map-btn .om-lbl {
  flex:1;
  text-align:left;
}
.offline-map-btn .om-size {
  font-family:'Crimson Text',Georgia,serif;
  font-size:.62rem;
  color:var(--ink3);
  background:var(--surface2);
  padding:2px 6px;
  border-radius:4px;
}

/* Share button - NEW Social-Nav */
.share-bar {
  display:flex;
  gap:8px;
  flex-wrap:wrap;
}
.share-btn {
  flex:1;
  min-width:80px;
  display:flex;
  align-items:center;
  justify-content:center;
  gap:6px;
  padding:8px 10px;
  background:var(--bg3);
  border:1px solid var(--border);
  border-radius:var(--r);
  font-size:.75rem;
  color:var(--ink2);
  cursor:pointer;
  transition:all .15s;
  font-family:'Nunito',sans-serif;
}
.share-btn:hover {
  background:var(--surface2);
  color:var(--ink);
  border-color:var(--border2);
}
.share-btn.copy-coords:hover {
  color:var(--cyan);
  border-color:rgba(196,149,90,.3);
}
.share-btn.wa-share:hover {
  color:#25D366;
  border-color:rgba(37,211,102,.3);
}

/* ═══════════ CUACA PAGE ═══════════ */
.pw {
  max-width:1100px;
  padding:32px clamp(16px,4vw,48px) 60px;
}
.pw-hd{margin-bottom:24px}
.pw-title {
  font-family:'Playfair Display',Georgia,serif;
  font-size:clamp(1.6rem,3vw,2.2rem);
  font-weight:700;
  color:var(--ink);
  margin-bottom:4px;
  letter-spacing:.02em;
}
.pw-sub {
  font-size:.8rem;
  color:var(--ink3);
  font-family:'Crimson Text',Georgia,serif;
}

/* Hazard map grid — NEW FEATURE */
.hazard-grid {
  display:grid;
  grid-template-columns:repeat(auto-fill,minmax(200px,1fr));
  gap:10px;
  margin-bottom:28px;
}
.hazard-card {
  background:var(--surface);
  border:1px solid var(--border);
  border-radius:var(--r2);
  padding:14px;
  cursor:pointer;
  transition:all .2s;
}
.hazard-card:hover {
  border-color:var(--border2);
  transform:translateY(-2px);
}
.hazard-card.hz-aman{border-left:3px solid var(--cyan)}
.hazard-card.hz-waspada{border-left:3px solid var(--amber)}
.hazard-card.hz-bahaya{border-left:3px solid var(--red)}
.hzc-name {
  font-family:'Playfair Display',Georgia,serif;
  font-size:.9rem;
  font-weight:700;
  color:var(--ink);
  margin-bottom:4px;
}
.hzc-loc {
  font-size:.62rem;
  color:var(--ink3);
  margin-bottom:8px;
  font-family:'Crimson Text',Georgia,serif;
}
.hzc-badges {
  display:flex;
  gap:5px;
  align-items:center;
  flex-wrap:wrap;
}
.hzc-status {
  font-size:.65rem;
  font-weight:600;
  padding:2px 7px;
  border-radius:3px;
  font-family:'Crimson Text',Georgia,serif;
}
.hzc-diff {
  font-size:.6rem;
  padding:2px 7px;
  border-radius:3px;
  background:var(--bg3);
  border:1px solid var(--border);
  color:var(--ink2);
  font-family:'Crimson Text',Georgia,serif;
}

.wm-card {
  background:linear-gradient(135deg,#130e07 0%,#1a1309 50%,#21190c 100%);
  border-radius:var(--r3);
  padding:24px;
  color:#fff;
  margin-bottom:16px;
  position:relative;
  overflow:hidden;
  border:1px solid rgba(196,149,90,.1);
}
.wm-card::before {
  content:'';
  position:absolute;
  top:-60px;
  right:-60px;
  width:220px;
  height:220px;
  background:radial-gradient(circle,rgba(196,149,90,.07) 0%,transparent 70%);
  pointer-events:none;
}
.wm-top {
  display:flex;
  justify-content:space-between;
  align-items:flex-start;
  flex-wrap:wrap;
  gap:14px;
  margin-bottom:18px;
}
.wm-temp {
  font-family:'Playfair Display',Georgia,serif;
  font-size:4rem;
  font-weight:700;
  line-height:1;
  color:#fff;
}
.wm-temp sup {
  font-size:1.4rem;
  vertical-align:super;
}
.wm-cond {
  font-size:.82rem;
  opacity:.6;
  margin-top:2px;
}
.wm-loc-name {
  font-family:'Playfair Display',Georgia,serif;
  font-size:1rem;
  font-weight:700;
  text-align:right;
  letter-spacing:.04em;
}
.wm-loc-sub {
  font-size:.65rem;
  opacity:.4;
  letter-spacing:.06em;
  text-align:right;
  font-family:'Crimson Text',Georgia,serif;
}
.wm-time {
  font-size:.6rem;
  opacity:.3;
  font-family:'Crimson Text',Georgia,serif;
  text-align:right;
  margin-top:4px;
}
.wm-grid {
  display:grid;
  grid-template-columns:repeat(auto-fit,minmax(110px,1fr));
  gap:8px;
}
.wm-cell {
  background:rgba(255,255,255,.06);
  border:1px solid rgba(255,255,255,.08);
  border-radius:var(--r);
  padding:10px 12px;
}
.wm-cell-lbl {
  font-size:.58rem;
  opacity:.45;
  letter-spacing:.12em;
  text-transform:uppercase;
  margin-bottom:2px;
  font-family:'Crimson Text',Georgia,serif;
}
.wm-cell-val {
  font-family:'Playfair Display',Georgia,serif;
  font-size:1rem;
  font-weight:700;
}

.w-status {
  display:inline-flex;
  align-items:center;
  gap:8px;
  padding:8px 16px;
  border-radius:var(--r);
  font-size:.78rem;
  font-weight:600;
  margin-bottom:20px;
  border:1px solid;
  font-family:'Crimson Text',Georgia,serif;
}
.ws-a {
  background:var(--cyan3);
  color:var(--cyan);
  border-color:rgba(196,149,90,.25);
}
.ws-w {
  background:var(--amber2);
  color:var(--amber);
  border-color:rgba(255,176,32,.25);
}
.ws-b {
  background:var(--red2);
  color:var(--red);
  border-color:rgba(255,77,77,.25);
}

.fc-strip {
  display:flex;
  gap:8px;
  overflow-x:auto;
  padding-bottom:6px;
  scrollbar-width:none;
  margin-bottom:24px;
}
.fc-strip::-webkit-scrollbar{display:none}
.fcrd {
  flex:0 0 90px;
  background:var(--surface);
  border:1px solid var(--border);
  border-radius:var(--r);
  padding:11px 8px;
  text-align:center;
  transition:transform .2s,border-color .2s;
}
.fcrd:hover {
  transform:translateY(-3px);
  border-color:var(--border2);
}
.fcrd-day {
  font-size:.6rem;
  font-weight:600;
  color:var(--cyan);
  letter-spacing:.06em;
  text-transform:uppercase;
  margin-bottom:4px;
  font-family:'Crimson Text',Georgia,serif;
}
.fcrd-ico {
  font-size:1.3rem;
  margin:3px 0;
}
.fcrd-t {
  font-family:'Playfair Display',Georgia,serif;
  font-size:.95rem;
  font-weight:700;
  color:var(--ink);
}
.fcrd-cond {
  font-size:.6rem;
  color:var(--ink3);
  margin-top:2px;
}

.klas-sec-title {
  font-family:'Playfair Display',Georgia,serif;
  font-size:1.1rem;
  font-weight:700;
  color:var(--ink);
  margin-bottom:12px;
  letter-spacing:.04em;
  text-transform:uppercase;
}
.ktable {
  width:100%;
  border-collapse:collapse;
  background:var(--surface);
  border-radius:var(--r2);
  overflow:hidden;
  border:1px solid var(--border);
  font-size:.78rem;
}
.ktable th {
  background:var(--bg3);
  color:var(--ink2);
  padding:10px 14px;
  text-align:left;
  font-size:.62rem;
  font-weight:600;
  letter-spacing:.1em;
  text-transform:uppercase;
  font-family:'Crimson Text',Georgia,serif;
  border-bottom:1px solid var(--border);
}
.ktable td {
  padding:10px 14px;
  border-bottom:1px solid var(--border);
  color:var(--ink2);
}
.ktable tr:last-child td{border-bottom:none}
.ktable tr:hover td{background:rgba(255,255,255,.02)}
.chip {
  padding:2px 8px;
  border-radius:3px;
  font-size:.65rem;
  font-weight:600;
  display:inline-flex;
  align-items:center;
  gap:4px;
  font-family:'Crimson Text',Georgia,serif;
}
.ch-a {
  background:var(--cyan3);
  color:var(--cyan);
}.ch-w {
  background:var(--amber2);
  color:var(--amber);
}.ch-b {
  background:var(--red2);
  color:var(--red);
}.ch-r {
  background:rgba(196,149,90,.1);
  color:var(--cyan);
}

/* ═══════════ PETA PAGE ═══════════ */
.peta-layout {
  display:grid;
  grid-template-columns:260px 1fr;
  gap:14px;
  min-height:520px;
  align-items:start;
}
@media(max-width:700px){.peta-layout{grid-template-columns:1fr}}
.peta-sidebar {
  background:var(--surface);
  border:1px solid var(--border);
  border-radius:var(--r2);
  padding:14px;
  display:flex;
  flex-direction:column;
  gap:8px;
  max-height:560px;
  overflow-y:auto;
}
.peta-sidebar-title {
  font-family:'Playfair Display',Georgia,serif;
  font-size:.85rem;
  font-weight:700;
  color:var(--ink);
  padding-bottom:10px;
  border-bottom:1px solid var(--border);
  letter-spacing:.06em;
  text-transform:uppercase;
}
.peta-dest-item {
  display:flex;
  align-items:center;
  gap:10px;
  padding:8px 9px;
  border-radius:var(--r);
  cursor:pointer;
  transition:background .12s;
  border:1px solid transparent;
}
.peta-dest-item:hover{background:var(--bg3)}
.peta-dest-item.active {
  background:var(--cyan4);
  border-color:rgba(196,149,90,.15);
}
.pdi-dot {
  width:8px;
  height:8px;
  border-radius:50%;
  flex-shrink:0;
}
.pdi-name {
  font-size:.78rem;
  font-weight:500;
  color:var(--ink);
}
.peta-dest-item.active .pdi-name{color:var(--cyan)}
.pdi-loc {
  font-size:.62rem;
  color:var(--ink3);
  font-family:'Crimson Text',Georgia,serif;
}
.peta-map-wrap {
  border-radius:var(--r2);
  overflow:hidden;
  border:1px solid var(--border);
}
#map{height:560px}
.route-info {
  background:var(--surface);
  border:1px solid var(--border);
  border-radius:var(--r2);
  padding:12px 16px;
  margin-bottom:14px;
  display:flex;
  gap:20px;
  flex-wrap:wrap;
  align-items:center;
}
.ri-item {
  display:flex;
  flex-direction:column;
  gap:2px;
}
.ri-lbl {
  font-size:.58rem;
  text-transform:uppercase;
  letter-spacing:.1em;
  color:var(--ink3);
  font-family:'Crimson Text',Georgia,serif;
}
.ri-val {
  font-family:'Playfair Display',Georgia,serif;
  font-size:1rem;
  font-weight:700;
  color:var(--cyan);
}
.ri-status {
  margin-left:auto;
  font-size:.72rem;
  color:var(--ink3);
  font-family:'Crimson Text',Georgia,serif;
}

/* BUTTONS */
.btn {
  display:inline-flex;
  align-items:center;
  gap:7px;
  padding:9px 20px;
  border-radius:var(--r);
  font-family:'Nunito',sans-serif;
  font-size:.8rem;
  font-weight:600;
  cursor:pointer;
  border:none;
  text-decoration:none;
  transition:all .18s;
  white-space:nowrap;
}
.btn-cyan {
  background:var(--cyan2);
  color:#fff;
}.btn-cyan:hover {
  background:var(--cyan);
  color:#fff;
  transform:translateY(-1px);
}
.btn-ghost {
  background:transparent;
  border:1px solid var(--border2);
  color:var(--ink2);
}.btn-ghost:hover {
  background:var(--surface);
  color:var(--ink);
}

/* FOOTER */
footer {
  background:var(--bg2);
  border-top:1px solid var(--border);
  padding:36px clamp(16px,4vw,48px) 24px;
}
.ft-inner {
  max-width:1100px;
  margin:0 auto;
  display:flex;
  justify-content:space-between;
  flex-wrap:wrap;
  gap:28px;
  margin-bottom:28px;
}
.ft-brand {
  font-family:'Playfair Display',Georgia,serif;
  font-size:1.1rem;
  font-weight:700;
  color:var(--cyan);
  letter-spacing:.06em;
  margin-bottom:4px;
}
.ft-tagline {
  font-size:.72rem;
  color:var(--ink3);
  max-width:180px;
  line-height:1.6;
  font-family:'Crimson Text',Georgia,serif;
}
.ft-col-title {
  font-size:.6rem;
  font-weight:600;
  letter-spacing:.14em;
  text-transform:uppercase;
  color:var(--ink3);
  margin-bottom:10px;
  font-family:'Crimson Text',Georgia,serif;
}
.ft-links {
  list-style:none;
  display:flex;
  flex-direction:column;
  gap:6px;
}
.ft-links a {
  color:var(--ink3);
  font-size:.78rem;
  text-decoration:none;
  cursor:pointer;
  transition:color .12s;
}
.ft-links a:hover{color:var(--ink)}
.ft-copy {
  max-width:1100px;
  margin:0 auto;
  border-top:1px solid var(--border);
  padding-top:18px;
  font-size:.65rem;
  color:var(--ink3);
  text-align:center;
  font-family:'Crimson Text',Georgia,serif;
}

::-webkit-scrollbar{width:4px}
::-webkit-scrollbar-track{background:transparent}
::-webkit-scrollbar-thumb {
  background:rgba(255,255,255,.08);
  border-radius:2px;
}

/* Notification toast */
.toast {
  position:fixed;
  bottom:24px;
  right:24px;
  z-index:9000;
  background:var(--surface2);
  border:1px solid var(--border2);
  border-radius:var(--r2);
  padding:10px 16px;
  font-size:.78rem;
  color:var(--ink);
  display:flex;
  align-items:center;
  gap:8px;
  box-shadow:0 8px 32px rgba(0,0,0,.4);
  transform:translateY(80px);
  opacity:0;
  transition:all .3s;
}
.toast.show {
  transform:translateY(0);
  opacity:1;
}
.toast-dot {
  width:7px;
  height:7px;
  border-radius:50%;
  background:var(--cyan);
  flex-shrink:0;
}

</style>
</head>
<body>

<div id="loader">
  <div class="ld-drop-scene">
    <div class="ld-drop"></div>
    <div class="ld-drop"></div>
    <div class="ld-drop"></div>
    <div class="ld-ripple"></div>
    <div class="ld-ripple"></div>
  </div>
  <div class="ld-logo">
    <div class="ld-logo-chars" id="ld-chars"></div>
    <span>Malang</span>
  </div>
  <div class="ld-bar"><div class="ld-fill"></div></div>
  <div class="ld-sub">Memuat Waterfall Malang…</div>
</div>

<div class="toast" id="toast"><span class="toast-dot"></span><span id="toast-msg"></span></div>

<div class="app-shell">
  <!-- SIDEBAR -->
  <aside class="sidebar">
    <div class="sb-brand">
      <div class="sb-logo">Waterfall<span>Malang</span></div>
      <div class="sb-status"><span class="sb-dot"></span> Live · Malang Raya</div>
    </div>

    <div class="sb-section-label">Navigasi</div>
    <ul class="sb-nav">
      <li><a id="nav-explore" class="active" onclick="showPage('explore')"><span class="sb-icon">🏞</span> Jelajahi Coban<span class="sb-badge" id="sb-count">15</span></a></li>
      <li><a id="nav-peta" onclick="showPage('peta')"><span class="sb-icon">🗺</span> Peta Interaktif</a></li>
      <li><a id="nav-hazard" onclick="showPage('hazard')"><span class="sb-icon">🔴</span> Level Risiko</a></li>
    </ul>

    <div class="sb-section-label">Filter Kesulitan</div>
    <ul class="sb-nav">
      <li><a onclick="showPage('explore');setSbFilter('all')" id="sbf-all" class="active"><span class="sb-icon">◉</span> Semua</a></li>
      <li><a onclick="showPage('explore');setSbFilter('Mudah')" id="sbf-mudah"><span class="sb-icon" style="color:#22c55e">▲</span> Mudah</a></li>
      <li><a onclick="showPage('explore');setSbFilter('Sedang')" id="sbf-sedang"><span class="sb-icon" style="color:var(--amber)">▲</span> Sedang</a></li>
      <li><a onclick="showPage('explore');setSbFilter('Sulit')" id="sbf-sulit"><span class="sb-icon" style="color:var(--red)">▲</span> Sulit</a></li>
      <li><a onclick="showPage('explore');setSbFilter('fav')" id="sbf-fav"><span class="sb-icon">♥</span> Favorit</a></li>
    </ul>

    <div class="sb-footer">v4.0 · Waterfall Malang &copy; 2026<br>Data: OpenWeatherMap, OSM</div>
  </aside>

  <!-- MOBILE TOPBAR -->
  <div class="mobile-topbar">
    <div class="mob-brand">Waterfall Malang</div>
    <div class="mob-tabs">
      <button class="mob-tab active" onclick="showPage('explore')">Jelajahi</button>
      <button class="mob-tab" onclick="showPage('peta')">Peta</button>
      <button class="mob-tab" onclick="showPage('hazard')">Risiko</button>
    </div>
  </div>

  <div class="main-content">

    <!-- ════ PAGE: EXPLORE ════ -->
    <div class="page active" id="page-explore">
      <section class="hero">
        <div class="hero-grid-lines"></div>
        <div class="hero-glow"></div>
        <div class="hero-content">
          <div class="hero-eyebrow">Malang Raya · 15 Coban</div>
          <h1 class="hero-title">Eksplorasi <span class="accent">Coban</span><br>Malang Raya</h1>
          <p class="hero-desc">Platform informasi lengkap dengan data keamanan real-time, level risiko bencana, dan navigasi rute untuk semua air terjun di Malang Raya.</p>
          <div class="hero-stats">
            <div class="hstat"><div class="hstat-val">15</div><div class="hstat-lbl">Destinasi</div></div>
            <div class="hstat"><div class="hstat-val">87%</div><div class="hstat-lbl">Prioritas Keamanan</div></div>
            <div class="hstat"><div class="hstat-val">84m</div><div class="hstat-lbl">Tertinggi</div></div>
            <div class="hstat"><div class="hstat-val">3</div><div class="hstat-lbl">Wilayah</div></div>
          </div>
        </div>
      </section>

      <div class="filter-bar">
        <div class="fsw">
          <span class="fsw-ico">⌕</span>
          <input type="text" id="searchInput" placeholder="Cari nama atau lokasi coban…" oninput="applyFilters()">
        </div>
      </div>

      <div class="grid-wrap">
        <div class="gsec-hd">
          <div class="gsec-title">Semua Destinasi</div>
          <div class="gsec-line"></div>
        </div>
        <div class="cgrid" id="cobanGrid"></div>
        <div class="empty" id="emptyState" style="display:none">
          <div class="empty-ico">🏞</div>
          <div class="empty-ttl">Tidak ditemukan</div>
          <div class="empty-sub">Coba kata kunci atau filter lain.</div>
        </div>
      </div>
    </div>

    <!-- ════ PAGE: DETAIL ════ -->
    <div class="page" id="page-detail">
      <div class="det-hero">
        <img id="det-img" src="" alt="">
        <div class="det-hero-overlay"></div>
        <button class="det-back" onclick="showPage('explore')">← Kembali</button>
        <div class="det-hero-info">
          <div class="det-badges">
            <div id="det-diff-badge" class="cdiff"></div>
          </div>
          <h1 class="det-name" id="det-name"></h1>
          <div class="det-loc" id="det-loc">📍</div>
        </div>
      </div>

      <!-- DYNAMIC HAZARD BANNER — new feature -->
      <div id="det-hazard-banner" class="det-hazard-banner hz-aman">
        <div class="dhb-icon" id="dhb-icon">⏳</div>
        <div class="dhb-text">
          <div class="dhb-title" id="dhb-title">Memuat status bahaya…</div>
          <div class="dhb-sub" id="dhb-sub">Mengambil data cuaca real-time lokasi ini</div>
        </div>
        <div class="dhb-level lv-aman" id="dhb-level">—</div>
      </div>

      <div class="det-body">
        <div class="det-main">
          <!-- Deskripsi -->
          <div class="det-sec">
            <div class="det-sec-head"><span>📖</span><div class="det-sec-title">Tentang Destinasi</div></div>
            <div class="det-sec-body">
              <p id="det-desc"></p>
              <div class="tag-cloud" id="det-tags"></div>
            </div>
          </div>

          <!-- Difficulty Rating — enhanced -->
          <div class="det-sec">
            <div class="det-sec-head"><span>🥾</span><div class="det-sec-title">Difficulty Rating</div></div>
            <div class="det-sec-body" id="det-diff-body"></div>
          </div>

          <!-- Cuaca -->
          <div class="det-sec">
            <div class="det-sec-head"><span>⛈</span><div class="det-sec-title">Cuaca Real-time Lokasi</div></div>
            <div class="det-sec-body">
              <div class="dw-main">
                <div class="dw-row">
                  <div>
                    <div class="dw-temp" id="dw-temp">--<sup>°C</sup></div>
                    <div class="dw-cond" id="dw-cond">Memuat…</div>
                  </div>
                  <div id="dw-status-mini" class="dw-status-mini dws-aman">⏳ Memuat</div>
                </div>
                <div class="dw-grid">
                  <div class="dw-cell"><div class="dw-cell-lbl">Curah Hujan</div><div class="dw-cell-val" id="dw-rain">—</div></div>
                  <div class="dw-cell"><div class="dw-cell-lbl">Angin</div><div class="dw-cell-val" id="dw-wind">—</div></div>
                  <div class="dw-cell"><div class="dw-cell-lbl">Kelembapan</div><div class="dw-cell-val" id="dw-hum">—</div></div>
                  <div class="dw-cell"><div class="dw-cell-lbl">Elevasi</div><div class="dw-cell-val" id="dw-elev">—</div></div>
                </div>
              </div>
              <div class="dw-forecast" id="dw-forecast"></div>
            </div>
          </div>

          <!-- Fasilitas -->
          <div class="det-sec">
            <div class="det-sec-head"><span>🏕</span><div class="det-sec-title">Fasilitas</div></div>
            <div class="det-sec-body"><div class="fac-grid" id="det-fac"></div></div>
          </div>

          <!-- Tips -->
          <div class="det-sec">
            <div class="det-sec-head"><span>//</span><div class="det-sec-title">Tips Berkunjung</div></div>
            <div class="det-sec-body"><ul class="tips-list" id="det-tips"></ul></div>
          </div>
        </div>

        <div class="det-sidebar">
          <!-- Info Umum -->
          <div class="det-sec">
            <div class="det-sec-head"><span>ℹ</span><div class="det-sec-title">Info Umum</div></div>
            <div class="det-sec-body" style="padding:0"><div id="det-info" style="padding:0 16px"></div></div>
          </div>

          <!-- Tiket -->
          <div class="det-sec">
            <div class="det-sec-head" style="background:rgba(196,149,90,.08);border-color:rgba(196,149,90,.15)">
              <span>🎫</span><div class="det-sec-title" style="color:var(--cyan)">Harga Tiket</div>
            </div>
            <div class="det-sec-body">
              <table class="tkt-table" id="det-tiket"></table>
              <div class="tkt-note" id="det-tiket-note"></div>
            </div>
          </div>

          <!-- Offline Map — NEW FEATURE -->
          <div class="det-sec">
            <div class="det-sec-head"><span>📥</span><div class="det-sec-title">Peta Offline</div></div>
            <div class="det-sec-body">
              <button class="offline-map-btn" id="offline-map-btn" onclick="downloadOfflineMap()">
                <span class="omico">🗺</span>
                <span class="om-lbl">Unduh Peta Jalur</span>
                <span class="om-size" id="om-size">~2.1 MB</span>
              </button>
              <p style="font-size:.68rem;color:var(--ink3);line-height:1.6;font-family:'Crimson Text',Georgia,serif">Simpan peta area ini untuk diakses tanpa sinyal internet di lokasi coban.</p>
            </div>
          </div>

          <!-- Social Nav -->
          <div class="det-sec">
            <div class="det-sec-head"><span>📡</span><div class="det-sec-title">Social-Nav / Bagikan</div></div>
            <div class="det-sec-body">
              <div class="share-bar">
                <button class="share-btn copy-coords" onclick="copyCoords()">📌 Salin Koordinat</button>
                <button class="share-btn wa-share" onclick="shareWhatsApp()">📲 WhatsApp</button>
              </div>
            </div>
          </div>

          <!-- Navigasi -->
          <div class="det-sec">
            <div class="det-sec-head"><span>🗺</span><div class="det-sec-title">Navigasi</div></div>
            <div class="det-sec-body">
              <button class="btn btn-cyan" style="width:100%;justify-content:center" id="det-peta-btn">Lihat di Peta & Rute →</button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ════ PAGE: CUACA ════ -->
    <div class="page" id="page-cuaca">
      <div class="pw">
        <div class="pw-hd">
          <h1 class="pw-title">Cuaca & Peringatan</h1>
          <p class="pw-sub">// Data real-time OpenWeatherMap · Referensi: Coban Rais, Kota Batu</p>
        </div>
        <div class="wm-card">
          <div class="wm-top">
            <div>
              <div class="wm-temp" id="wm-temp">--<sup>°C</sup></div>
              <div class="wm-cond" id="wm-cond">Memuat…</div>
            </div>
            <div>
              <div class="wm-loc-name">Coban Rais</div>
              <div class="wm-loc-sub">ORO-ORO OMBO · KOTA BATU</div>
              <div class="wm-time" id="wm-time">—</div>
            </div>
          </div>
          <div class="wm-grid">
            <div class="wm-cell"><div class="wm-cell-lbl">Curah Hujan</div><div class="wm-cell-val" id="wm-rain">—</div></div>
            <div class="wm-cell"><div class="wm-cell-lbl">Kec. Angin</div><div class="wm-cell-val" id="wm-wind">—</div></div>
            <div class="wm-cell"><div class="wm-cell-lbl">Kelembapan</div><div class="wm-cell-val" id="wm-hum">—</div></div>
            <div class="wm-cell"><div class="wm-cell-lbl">Elevasi</div><div class="wm-cell-val">±1025 mdpl</div></div>
          </div>
        </div>
        <div id="wm-status" class="w-status ws-a">⏳ Memuat status…</div>
        <h2 class="klas-sec-title">Prakiraan 7 Hari</h2>
        <div class="fc-strip" id="fc-strip"><div style="color:var(--ink3);font-size:.78rem;padding:14px;font-family:'Crimson Text',Georgia,serif">// Memuat…</div></div>
        <h2 class="klas-sec-title">Tabel Klasifikasi Bahaya</h2>
        <div style="overflow-x:auto;margin-bottom:28px">
          <table class="ktable">
            <thead><tr><th>Kondisi</th><th>Curah Hujan</th><th>Kec. Angin</th><th>Kelembapan</th><th>Status</th></tr></thead>
            <tbody>
              <tr><td>☀️ Cerah</td><td>—</td><td>&lt;5 m/s</td><td>40–70%</td><td><span class="chip ch-a">✓ Aman</span></td></tr>
              <tr><td>🌥 Berawan</td><td>—</td><td>&lt;8 m/s</td><td>60–80%</td><td><span class="chip ch-a">✓ Aman</span></td></tr>
              <tr><td>🌦 Gerimis</td><td>&lt;2.5 mm/j</td><td>&lt;8 m/s</td><td>—</td><td><span class="chip ch-r">⚠ Waspada Ringan</span></td></tr>
              <tr><td>🌫 Berkabut</td><td>—</td><td>—</td><td>—</td><td><span class="chip ch-w">⚠ Waspada</span></td></tr>
              <tr><td>🌧 Hujan Sedang</td><td>2.5–10 mm/j</td><td>5–10 m/s</td><td>&gt;80%</td><td><span class="chip ch-w">⚠ Waspada</span></td></tr>
              <tr><td>⛈ Hujan Lebat</td><td>10–20 mm/j</td><td>8–15 m/s</td><td>—</td><td><span class="chip ch-b">✕ Bahaya</span></td></tr>
              <tr><td>🌪 Badai/Ekstrem</td><td>—</td><td>&gt;15 m/s</td><td>—</td><td><span class="chip ch-b">✕ Bahaya</span></td></tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- ════ PAGE: PETA ════ -->
    <div class="page" id="page-peta">
      <div class="pw">
        <div class="pw-hd">
          <h1 class="pw-title">Peta Interaktif</h1>
          <p class="pw-sub">// Klik destinasi untuk rute otomatis dari lokasi Anda</p>
        </div>
        <div id="route-info-bar" class="route-info" style="display:none">
          <div class="ri-item"><div class="ri-lbl">Tujuan</div><div class="ri-val" id="ri-dest">—</div></div>
          <div class="ri-item"><div class="ri-lbl">Jarak</div><div class="ri-val" id="ri-dist">—</div></div>
          <div class="ri-item"><div class="ri-lbl">Est. Waktu</div><div class="ri-val" id="ri-dur">—</div></div>
          <div class="ri-status" id="ri-status"></div>
        </div>
        <div class="peta-layout">
          <div class="peta-sidebar">
            <div class="peta-sidebar-title">📍 Pilih Destinasi</div>
            <div id="peta-dest-list"></div>
          </div>
          <div class="peta-map-wrap"><div id="map"></div></div>
        </div>
      </div>
    </div>

    <!-- ════ PAGE: HAZARD LEVEL ════ (NEW) -->
    <div class="page" id="page-hazard">
      <div class="pw">
        <div class="pw-hd">
          <h1 class="pw-title">Dynamic Hazard Level</h1>
          <p class="pw-sub">// Level risiko real-time untuk semua 15 destinasi berdasarkan data cuaca OpenWeatherMap</p>
        </div>
        <div id="wm-status-hazard" class="w-status ws-a" style="margin-bottom:20px">⏳ Memuat data bahaya…</div>
        <h2 class="klas-sec-title">Status Semua Destinasi</h2>
        <div class="hazard-grid" id="hazard-grid">
          <div style="color:var(--ink3);font-family:'Crimson Text',Georgia,serif;font-size:.75rem;padding:20px;grid-column:1/-1">// Memuat data hazard level…</div>
        </div>
        <h2 class="klas-sec-title" style="margin-top:8px">Panduan Difficulty Rating</h2>
        <div style="overflow-x:auto">
          <table class="ktable">
            <thead><tr><th>Level</th><th>Durasi Trekking</th><th>Kondisi Jalur</th><th>Rekomendasi</th><th>Difficulty</th></tr></thead>
            <tbody>
              <tr><td><span class="chip ch-a">Mudah</span></td><td>&lt;30 menit</td><td>Landai, terawat</td><td>Semua usia, keluarga</td><td style="font-family:var(--font-mono)">0–3/10</td></tr>
              <tr><td><span class="chip ch-w">Sedang</span></td><td>30–90 menit</td><td>Terjal sebagian, mungkin licin</td><td>Remaja & dewasa aktif</td><td>4–6/10</td></tr>
              <tr><td><span class="chip ch-b">Sulit</span></td><td>&gt;90 menit</td><td>Sangat terjal, berbatu, tanpa panduan</td><td>Pendaki berpengalaman</td><td>7–10/10</td></tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <footer>
      <div class="ft-inner">
        <div>
          <div class="ft-brand">Waterfall Malang</div>
          <div class="ft-tagline">// Informasi Lengkap Air Terjun Malang Raya</div>
        </div>
        <div>
          <div class="ft-col-title">Halaman</div>
          <ul class="ft-links">
            <li><a onclick="showPage('explore')">Jelajahi Coban</a></li>
            <li><a onclick="showPage('peta')">Peta Interaktif</a></li>
            <li><a onclick="showPage('hazard')">Dynamic Hazard Level</a></li>
          </ul>
        </div>
        <div>
          <div class="ft-col-title">Fitur Utama</div>
          <ul class="ft-links">
            <li><a>Dynamic Hazard Level</a></li>
            <li><a>Difficulty Rating</a></li>
            <li><a>Peta Offline</a></li>
            <li><a>Social-Nav / Share</a></li>
          </ul>
        </div>
        <div>
          <div class="ft-col-title">Data Sumber</div>
          <ul class="ft-links">
            <li><a>OpenWeatherMap API</a></li>
            <li><a>OpenStreetMap</a></li>
            <li><a>OSRM Routing Engine</a></li>
          </ul>
        </div>
      </div>
      <div class="ft-copy">© 2026 Waterfall Malang · Analisis Kebutuhan Pengguna: 23 Responden · 96% User Acceptance</div>
    </footer>

  </div><!-- end main-content -->
</div><!-- end app-shell -->

<script src="https://unpkg.com/leaflet/dist/leaflet.js"></script>
<script>

  // ══════════════════════════════════════════
  // DATA
  // ══════════════════════════════════════════
  const cobans = [
  { id:1, name:"Coban Rondo", difficulty:"Mudah", diffScore:2,
  desc:"Air Terjun Coban Rondo merupakan air terjun yang sarat akan legenda. Secara harfiah, coban memiliki arti air terjun sedangkan rondo berarti janda. Penamaan tersebut tak lepas dari legenda tentang kisah Dewi Anjarwati dari Gunung Kawi dengan Raden Baron Kusuma dari Gunung Anjasmoro. Air terjun dengan tinggi 84 meter ini bersumber dari Mata Air Cemoro Mudo di lereng Gunung Kawi, pertama diresmikan tahun 1980.",
  location:"Jl. Coban Rondo No.30, Krajan, Pandesari, Kec. Pujon, Kabupaten Malang, Jawa Timur 65391", lat:-7.8423, lng:112.5068,
  height:"84 m", duration:"15 menit", jam:"08.00–16.00 WIB", elev:"±1.134 mdpl",
  fasilitas:[{ico:"🌊",name:"Air Terjun Utama"},{ico:"🌀",name:"Taman Labirin"},{ico:"🚵",name:"Sepeda Gunung"},{ico:"🎯",name:"Memanah"},{ico:"🏕",name:"Camping Ground"},{ico:"🚻",name:"Toilet & Mushola"}],
  tiket:[{lbl:"Tiket (Weekday)",val:"Rp 35.000"},{lbl:"Tiket (Weekend)",val:"Rp 40.000"},{lbl:"Parkir Motor",val:"Rp 5.000"},{lbl:"Parkir Mobil",val:"Rp 10.000"}],
  tiketNote:"Tiket sudah termasuk akses ke Taman Labirin, Shooting Target, Panahan, dan Bersepeda.",
  tips:["Datang sebelum pukul 09.00 untuk menghindari keramaian weekend","Bawa jaket tipis, suhu pagi sangat sejuk di ketinggian 1.134 mdpl","Coba Fun Tubing untuk pengalaman jelajah sungai yang seru"],
  tags:["Keluarga","Outbound","Taman Labirin","Hutan Pinus"],
  img:"https://asset.kompas.com/crops/DELgpewLf7Dli7oVBR7OzzY7nwk=/0x0:1149x766/1200x800/data/photo/2021/08/25/6126168e3be6b.jpg" },
  { id:2, name:"Coban Talun", difficulty:"Mudah", diffScore:2,
  desc:"Air terjun bertingkat di dalam kawasan Apache Camp. Tersedia taman bunga warna-warni, camping ground bergaya Indian yang ikonik, dan berbagai spot foto instagramable di tengah hutan tropis Bumiaji, serta mitos Jembatan Asmara (pertemuan Pangeran Jaya Nalendra dan Dewi Seruni)",
  location:"Jl. Coban Talun, Dusun Wonorejo, Tulungrejo, Kec. Bumiaji, Kota Batu, Jawa Timur 65336", lat:-7.8756, lng:112.5234,
  height:"75 m", duration:"20 menit", jam:"07.00–17.00 WIB", elev:"±1100 mdpl",
  fasilitas:[{ico:"🌊",name:"Air Terjun"},{ico:"🏕",name:"Apache Camp"},{ico:"🏕",name:"Pagupon Camp"},{ico:"🌸",name:"Taman Bunga"},{ico:"📸",name:"Spot Foto"},{ico:"🚻",name:"Toilet & Mushola"}],
  tiket:[{lbl:"Tiket Masuk",val:"Rp 15.000-20.000"},{lbl:"Parkir Motor",val:"Rp 5.000"},{lbl:"Parkir Mobil",val:"Rp 10.000"},{lbl:"Sewa Tenda Camping",val:"Rp 75.000"}],
  tiketNote:"Harga dapat berubah di hari libur nasional dan musim liburan sekolah.",
  tips:["Apache Camp tersedia untuk menginap dengan konsep tenda bergaya Indian","Bawa baju ganti dan jas hujan di musim penghujan","Taman bunga paling indah di pagi hari saat bunga sedang mekar"],
  tags:["Keluarga","Camping","Apache Camp","Taman Bunga"],
  img:"https://travelspromo.com/wp-content/uploads/2019/05/air-terjun-coban-talun-Hamzah-Saefudin.jpg" },
  { id:3, name:"Coban Rais", difficulty:"Sedang", diffScore:6,
  desc:"Permata wisata Kota Batu di ketinggian 1.025 mdpl. Terkenal dengan jalur trekking 3 km melalui hutan pinus, flying fox, hammock bertingkat, dan Batu Flower Garden.",
  location:"Jalur Lkr. Bar. No.8, Oro-Oro Ombo, Kec. Batu, Kota Batu, Jawa Timur 65316", lat:-7.9012, lng:112.5156,
  height:"70 m", duration:"1 jam 30 menit", jam:"07.00–15.00 WIB", elev:"±1.025 mdpl",
  fasilitas:[{ico:"🌊",name:"Air Terjun"},{ico:"🚡",name:"Flying Fox"},{ico:"😴",name:"Hammock Bertingkat"},{ico:"🌸",name:"Batu Flower Garden"},{ico:"🛤",name:"Jalur Trekking"},{ico:"🍽",name:"Warung Makan"}],
  tiket:[{lbl:"Tiket Masuk",val:"Rp 10.000-15.000"},{lbl:"Batu Flower Garden",val:"Rp 25.000"},{lbl:"Parkir Motor",val:"Rp 5.000"},{lbl:"Per Spot Foto",val:"Rp 10.000"}],
  tiketNote:"Batu Flower Garden termasuk akses ke Bukit Bulu dan satu sesi foto. Bawa uang tunai.",
  tips:["Datang pagi karena tutup pukul 15.00","Gunakan sepatu yang nyaman untuk trekking 3 km","Cuaca bisa berubah cepat, selalu cek status sebelum berangkat"],
  tags:["Flying Fox","Hammock","Flower Garden","Trekking"],
  img:"https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRil1XMUrT-_BKZTEZGB8Hu9j0SdXW_d5BEMw&s" },
  { id:4, name:"Coban Pelangi", difficulty:"Sedang", diffScore:5,
  desc:"Dijuluki 'Pelangi' karena fenomena busur pelangi alami saat sinar matahari menerpa percikan airnya di ketinggian 1.299 mdpl di kawasan TNBTS, kaki Gunung Semeru.",
  location:"Jl. Raya Gubugklakah, Dusun Ngadas, Ngadas, Kec. Poncokusumo, Kabupaten Malang, Jawa Timur 65157", lat:-8.0234, lng:112.8012,
  height:"110 m", duration:"30-45menit", jam:"08.00–16.00 WIB", elev:"±1.299 mdpl",
  fasilitas:[{ico:"🌊",name:"Air Terjun 110m"},{ico:"🐴",name:"Naik Kuda"},{ico:"🏕",name:"Camping Ground"},{ico:"🌉",name:"Jembatan Kayu"},{ico:"🧗",name:"River Tubing"}],
  tiket:[{lbl:"Tiket (Weekday)",val:"Rp 10.000"},{lbl:"Tiket (Weekend)",val:"Rp 15.000"},{lbl:"Parkir Motor",val:"Rp 3.000"},{lbl:"Parkir Mobil",val:"Rp 5.000"},{lbl:"Naik Kuda (30 mnt)",val:"Rp 50.000"}],
  tiketNote:"Pelangi biasanya terlihat antara pukul 09.00–11.00 WIB saat matahari cukup tinggi.",
  tips:["Datang sekitar pukul 09.00 untuk melihat fenomena pelangi","Jalur TNBTS, patuhi peraturan taman nasional","Bawa bekal karena warung terbatas di kawasan"],
  tags:["Pelangi Alami","TNBTS","Kuda","Camping"],
  img:"https://nahwatour.com/wp-content/uploads/2022/03/Coban-Pelangi.jpeg" },
  { id:5, name:"Coban Jahe", difficulty:"Mudah", diffScore:2,
  desc:"Hidden gem di Jabung — parkir hanya 100 meter dari air terjun. Cocok untuk semua kalangan termasuk lansia dan anak-anak. Airnya mengalir jernih di antara bebatuan alami yang masih sangat perawan. Terdapat Taman Makam Pahlawan Kali Jahe yang berjarak sekitar 400 meter dari air terjun.",
  location:"Jl. Begawan No.ds, Dusun Krajan, Taji, Kec. Jabung, Kabupaten Malang, Jawa Timur 65155", lat:-8.0345, lng:112.7890,
  height:"±25-30 m", duration:"10 menit", jam:"08.00–16.00 WIB", elev:"±450 mdpl",
  fasilitas:[{ico:"🌊",name:"Air Terjun"},{ico:"🅿",name:"Parkir Dekat"},{ico:"🍽",name:"Warung"},{ico:"🚻",name:"Toilet Sederhana"}],
  tiket:[{lbl:"Tiket Masuk",val:"Rp 12.000"},{lbl:"Parkir Motor",val:"Rp 5.000"},{lbl:"Parkir Mobil",val:"Rp 10.000"}],
  tiketNote:"Dikelola masyarakat lokal. Harga sangat terjangkau.",
  tips:["Cocok untuk wisata keluarga dengan anak kecil","Hindari kunjungan saat musim hujan lebat","Bawa alas piknik untuk bersantai di tepi sungai"],
  tags:["Hidden Gem","Mudah Diakses","Keluarga","Ramah Anak"],
  img:"https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTSbm4gbTQdeGKqxQtqIJVRaqtOAA2tFi-YEA&s" },
  { id:6, name:"Coban Nirwana", difficulty:"Sedang", diffScore:4,
  desc:"Dijuluki 'Green Canyon Malang Selatan', memiliki dua aliran air besar dengan dinding tebing tegak. Kolam alaminya berwarna hijau tosca jernih sedalam 3 meter.",
  location:"Krajan Lor Gedangan, Gedangan, Malang Regency, East Java 65178", lat:-8.0789, lng:112.5678,
  height:"±10-15 m", duration:"10-15menit", jam:"06.00-17.30", elev:"±150 mdpl",
  fasilitas:[{ico:"🌊",name:"Dua Aliran Air"},{ico:"🏊",name:"Kolam 3m Tosca"},{ico:"🅿",name:"Parkir Tepi Jalan"},{ico:"📸",name:"Spot Foto Viral"}],
  tiket:[{lbl:"Tiket Masuk",val:"Tidak ada"},{lbl:"Parkir Motor",val:"Rp 2.000"},{lbl:"Parkir Mobil",val:"Rp 5.000"} ],
  tiketNote:"Kolam sedalam 3 meter, tidak disarankan masuk jika tidak bisa berenang.",
  tips:["Jalan kaki 200m dari parkir","Kolam sangat dalam (3m), jaga keselamatan","Kunjungi musim hujan untuk debit lebih deras"],
  tags:["Green Canyon","Kolam Tosca","Dua Aliran","Foto Viral"],
  img:"https://media-cdn.tripadvisor.com/media/photo-s/1c/e1/89/8f/indahnya-coban-nirwana.jpg" },
  { id:7, name:"Coban Cinde", difficulty:"Sulit", diffScore:8,
  desc:"Hidden gem Malang Selatan dengan dua tingkatan. Masih sangat asri, sepi, dan alami dengan suasana primitif yang memberikan ketenangan jiwa.",
  location:"Benjor, Kec. Tumpang, Kabupaten Malang, Jawa Timur 65156", lat:-8.1234, lng:112.6789,
  height:"50 m", duration:"90 menit", jam:"24 Jam", elev:"±80 mdpl",
  fasilitas:[{ico:"🌊",name:"Air Terjun 2 Tingkat"},{ico:"🌲",name:"Hutan Asri"},{ico:"🅿",name:"Parkir Sederhana"}],
  tiket:[{lbl:"Tiket Masuk",val:"Rp 10.000"},{lbl:"Parkir Motor",val:"Rp 3.000"},{lbl:"Parkir Mobil",val:"Rp 5.000"}],
  tiketNote:"Jalur sangat terjal dan licin. Wajib membawa tongkat pendakian.",
  tips:["Wajib membawa tongkat pendakian","Jangan berkunjung sendirian, minimal 2 orang","Bawa persediaan air minum yang cukup"],
  tags:["Dua Tingkat","Hidden Gem","Asri","Petualangan"],
  img:"https://nahwatour.com/wp-content/uploads/2022/03/Coban-Cinde.jpg" },
  { id:8, name:"Coban Kethak", difficulty:"Sedang", diffScore:5,
  desc:"Air terjun tersembunyi di cerukan tebing batu yang membentuk amphiteater alam dramatis. Dipercaya memiliki energi spiritual, sering dikunjungi untuk meditasi dan kontemplasi.",
  location:"Desa, Pait Utara, Pait, Kec. Kasembon, Kabupaten Malang, Jawa Timur 65393", lat:-7.8567, lng:112.4890,
  height:"15 m", duration:"20-30 menit", jam:"07.30–16.00 WIB", elev:"597 mdpl",
  fasilitas:[{ico:"🌊",name:"Air Terjun"},{ico:"🧘",name:"Area Meditasi"},{ico:"🌲",name:"Hutan Pinus"},{ico:"🅿",name:"Parkir"},{ico:"🚻",name:"Toilet"}],
  tiket:[{lbl:"Tiket Masuk",val:"Rp 10.000"},{lbl:"Parkir Motor",val:"Rp 3.000"}],
  tiketNote:"Kawasan kelolaan Perhutani. Menjaga ketenangan sangat dianjurkan.",
  tips:["Tempat ideal untuk meditasi dan menenangkan pikiran","Jalur hutan pinus memberikan nuansa berbeda","Rentan kabut tebal di pagi hari"],
  tags:["Spiritual","Amphiteater Alam","Perhutani","Meditasi"],
  img:"https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTsEREg03tjGNn7bw7t484GyKTNnlBh8pk8xw&s" },
  { id:9, name:"Coban Bidadari", difficulty:"sedang", diffScore:5,
  desc:"Terpencil di hutan perawan Karangploso, kolam alaminya berwarna biru jernih dengan dasar berbatu berlumut zamrud. Legenda menyebut bidadari turun mandi setiap purnama.",
  location:"Dusun Gubugklakah, Kecamatan Poncokusumo, Kabupaten Malang, Jawa Timur", lat:-7.9345, lng:112.5923,
  height:"±50 m", duration:"20-40 menit", jam:"07.00-18.00", elev:"±700 mdpl",
  fasilitas:[{ico:"🌊",name:"Air Terjun"},{ico:"💧",name:"Kolam Biru Jernih"},{ico:"🌲",name:"Hutan Perawan"},{ico:"🅿",name:"Parkir Terbatas"}],
  tiket:[{lbl:"Tiket Masuk",val:"Rp 10.000–15.000"},{lbl:"Parkir",val:"Rp 3.000–5.000"}],
  tiketNote:"Medan berat, disarankan menggunakan pemandu lokal.",
  tips:["Gunakan jasa pemandu lokal untuk pertama kali","Bawa perlengkapan lengkap: senter, makanan, obat","Hormati kepercayaan lokal"],
  tags:["Kolam Biru","Mistis","Hutan Perawan","Petualangan"],
  img:"https://travelspromo.com/wp-content/uploads/2020/11/keasrian-air-terjun-di-coban-bidadari-e1606467621967.jpg" },
   { id:10, name:"Coban Glotak", difficulty:"Sedang", diffScore:4,
  desc:"Berlokasi di perbukitan berbatu vulkanik Pagak, air terjunnya mengalir di atas batuan basalt hitam yang dramatis. Namanya 'Glotak' karena suara gemuruh airnya yang khas.",
  location:"Jalan Raya Coban Glothak, Area Hutan, Dalisodo, Wagir, Kabupaten Malang, Jawa Timur", lat:-8.2012, lng:112.5012,
  height:"20-25 m", duration:"15-30 menit", jam:"07.00–17.00 WIB", elev:"±200 mdpl",
  fasilitas:[{ico:"🌊",name:"Air Terjun"},{ico:"🪨",name:"Batuan Basalt Unik"},{ico:"📸",name:"Spot Foto"},{ico:"🅿",name:"Parkir"},{ico:"🍽",name:"Warung"}],
  tiket:[{lbl:"Tiket Masuk",val:"Rp 5.000–10.000"},{lbl:"Parkir",val:"Rp 3.000–5.000"}],
  tiketNote:"Batuan vulkanik basalt memberikan tekstur lanskap unik untuk fotografi.",
  tips:["Terbaik di pagi hari untuk pencahayaan foto","Batu basalt bisa licin, pakai sepatu kokoh","Suara air sangat menenangkan"],
  tags:["Basalt Vulkanik","Malang Selatan","Unik","Fotografi"],
  img:"https://nahwatour.com/wp-content/uploads/2022/03/Coban-Glotak.jpg" },
  { id:11, name:"Coban Parang Tejo", difficulty:"Mudah", diffScore:3,
  desc:"Coban Parang Tejo merupakan air terjun eksotis yang terletak di lereng Gunung Arjuno, tepatnya di kawasan hutan Perhutani wilayah Pujon, Kabupaten Malang. Nama “Parang Tejo” berasal dari bahasa Jawa, di mana parang berarti tebing atau lereng curam, dan tejo berarti cahaya, menggambarkan pantulan cahaya air yang jatuh di antara tebing batu.",
  location:"Princi Gading Kulon, Godehan, Kucur, Kec. Dau, Kabupaten Malang, Jawa Timur 65151", lat:-7.9445, lng:112.5200,
  height:"40-50 m", duration:"15-25 menit", jam:"07.00–17.00 WIB", elev:"±900 mdpl",
  fasilitas:[{"ico":"🌊","name":"Air Terjun"},{"ico":"🌲","name":"Hutan Pinus"},{"ico":"📸","name":"Spot Foto"},{"ico":"🅿","name":"Area Parkir"},{"ico":"🚻","name":"Toilet Sederhana"},{"ico":"🍽","name":"Warung"}],
  tiket:[{lbl:"Tiket Masuk",val:"Rp 10.000–15.000"},{lbl:"Parkir Motor",val:"Rp 3.000"}],
  tiketNote: "Dikelola masyarakat lokal, fasilitas sederhana namun cukup memadai.",
  tips:"Datang pagi untuk suasana lebih sejuk dan sepi","Gunakan alas kaki yang nyaman karena jalur tanah":"Cocok untuk piknik santai di area sekitar air terjun"
  ,tags:["Hutan Pinus","Santai","Keluarga","Akses Mudah"],
  img:"https://nahwatour.com/wp-content/uploads/2022/03/Panorama-Coban-Parang-Tejo.jpg" },
 { id:12, name:"Coban Tundo", difficulty:"Sulit", diffScore:9, 
 desc:"Air terjun tujuh tingkat epik — masing-masing memiliki kolam renang alaminya sendiri. Mendaki setiap tingkat adalah petualangan tersendiri.", 
 location:"Kec. Sumbermanjing Wetan, Kabupaten Malang, Jawa Timur 65181", lat:-8.1890, lng:112.8456, 
 height:"±80–100 meter", duration:"±2 jam", jam:"07.00–16.00 WIB", elev:"±100 mdpl", 
 fasilitas:[{ico:"🌊",name:"Air Terjun"},{"ico":"🏊","name":"Kolam Alami"},{"ico":"🧗","name":"Trekking Ekstrem"},{ico:"🅿",name:"Parkir"}], 
 tiket:[{lbl:"Tiket Masuk",val:"Rp 10.000"},{lbl:"Parkir",val:"Rp 5.000"}], 
 tiketNote:"Perjalanan 7 tingkat membutuhkan 3–4 jam. Pemandu sangat disarankan.", 
 tips:["Wajib kondisi fisik prima","Gunakan sepatu trekking anti slip","Bawa logistik lengkap (air, makanan, P3K)","Jangan berangkat siang, mulai pagi hari","Disarankan menggunakan pemandu lokal"], 
 tags:["7 Tingkat","Kolam Alami","Epic Trekking"],
  img:"https://nativeindonesia.com/foto/2020/09/Coban-Tundo-Malang.jpg" },
  { id:13, name:"Coban Putri", difficulty:"Mudah", diffScore:3,
  desc:"Air terjun yang menawan di Pujon dengan akses mudah dan suasana sejuk pegunungan. Populer di kalangan wisatawan keluarga karena trek yang tidak terlalu menantang.",
  location:"Jalur Lkr. Bar., Oro-Oro Ombo, Kec. Batu, Kota Batu, Jawa Timur 65316", lat:-7.8901, lng:112.4567,
  height:"30 m", duration:"20 menit", jam:"07.00–16.00 WIB", elev:"±950 mdpl",
  fasilitas:[{ico:"🌊",name:"Air Terjun"},{ico:"🏞",name:"Area Piknik"},{ico:"🅿",name:"Parkir"},{ico:"🚻",name:"Toilet"},{ico:"🍽",name:"Warung"}],
  tiket:[{lbl:"Tiket Masuk",val:"Rp 10.000"},{lbl:"Parkir Motor",val:"Rp 3.000"}],
  tiketNote:"Kawasan sejuk dengan suhu rata-rata 18–22°C sepanjang tahun.",
  tips:["Cocok untuk piknik keluarga","Bawa jaket karena suhu bisa sangat sejuk","Kunjungi pagi untuk kabut romantis yang indah"],
  tags:["Keluarga","Pujon","Sejuk","Mudah"],
  img:"https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRgZrTfG6fEUjO-ZwkG9Ok61B_WJ8t6mk9FSA&s" },
  { id:14, name:"Coban Siuk", difficulty:"Sulit", diffScore:7,
  desc:"Air terjun misterius di celah tebing sempit yang menciptakan cahaya keemasan dramatis saat golden hour. Fenomena cahaya yang terbentuk sangat langka dan sangat fotogenik.",
  location:"Dusun Krajan, Taji, Kec. Jabung, Kabupaten Malang, Jawa Timur 65155", lat:-7.96, lng:112.82,
  height:"±20–30 meter", duration:"80 menit", jam:"24 jam", elev:"±550 mdpl",
  fasilitas:[{ico:"🌊",name:"Air Terjun"},{ico:"🌅",name:"Spot Golden Hour"},{ico:"🅿",name:"Parkir Terbatas"}],
  tiket:[{lbl:"Tiket Masuk",val:"Rp 10.000"},{lbl:"Parkir",val:"Rp 5.000"}],
  tiketNote:"Waktu terbaik adalah sore hari pukul 15.00–16.00 untuk golden hour.",
  tips:["Datang menjelang sore untuk cahaya golden hour","Dengarkan konser katak alami saat senja","Bawa tripod untuk foto long exposure"],
  tags:["Golden Hour","Fotografi","Celah Tebing","Sunset"],
  img:"https://ik.imagekit.io/tvlk/dam/i/01k5fznc03mqe6p24ckvvj48bc.jpeg?tr=q-70,c-at_max,w-1000,h-600" },
  { id:15, name:"Coban Sumber Pitu (Tumpang)", difficulty:"Sulit", diffScore:8,
  desc:"Versi lebih liar dan tinggi di kaki Gunung Semeru. Pada hari yang sangat cerah pengunjung dapat melihat siluet Gunung Bromo di kejauhan.",
  location:"Krajan, Duwet Krajan, Tumpang, Malang Regency, East Java 65156", lat:-8.0456, lng:112.7678,
  height:"60 m", duration:"120 menit", jam:"07.00–16.00 WIB", elev:"±750 mdpl",
  fasilitas:[{ico:"🌊",name:"Air Terjun"},{ico:"🏔",name:"View Gunung Bromo"},{ico:"🌲",name:"Hutan Semeru"},{ico:"🅿",name:"Parkir"}],
  tiket:[{lbl:"Tiket Masuk",val:"Rp 5.000–10.000"},{lbl:"Parkir",val:"Rp 5.000"}],
  tiketNote:"Gunung Bromo terlihat di hari cerah tanpa kabut, biasanya musim kemarau.",
  tips:["Musim kemarau (Juni–Agustus) terbaik untuk view Bromo","Mulai sepagi mungkin sebelum kabut turun","Bawa perlengkapan mendaki lengkap"],
  tags:["pemandangan perbukitan dan lembah luas","Trekking Berat","kawasan hutan lereng Semeru"],
  img:"https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR1BCApRpoWmCC2WKk484e3GokmyABbp8FAlg&s" }
  ];
  
  
  // ══════════════════════════════════════════
  // STATE
  // ══════════════════════════════════════════
  let weatherMainLoaded = false;
  let mapInit = false;
  let activeFilter = 'all';
  const favs = new Set();
  let currentCoban = null;
  const OWM = "c1ae602588babefeee9b94b25f019e9f";

  // Store weather hazard data per coban
  const hazardCache = {};

  // ══════════════════════════════════════════
  // UTILS
  // ══════════════════════════════════════════
  function wIcon(m) {
  const s = (m||'').toLowerCase();
  if(s.includes('clear')) return '☀️';
  if(s.includes('cloud')) return '🌥';
  if(s.includes('rain')) return '🌧';
  if(s.includes('drizzle')) return '🌦';
  if(s.includes('thunder')) return '⛈';
  if(s.includes('fog')||s.includes('mist')) return '🌫';
  return '🌤';
  }

  function riskLevel(rain, wind, hum) {
  if(wind>15||rain>20) return 'bahaya';
  if(rain>10||wind>10) return 'tidak_disarankan';
  if(rain>2.5||wind>8||hum>80) return 'waspada';
  if(rain>0||wind>5) return 'waspada_ringan';
  return 'aman';
  }

  const RISK_MAP = {
  aman:            { cls:'ws-a', hzCls:'hz-aman', hzLevel:'lv-aman', icon:'✅', label:'Kondisi Aman — Silakan Berkunjung', short:'AMAN', dhbIcon:'✅', dhbTitle:'Kondisi Aman', dhbSub:'Cuaca mendukung aktivitas wisata hari ini.' },
  waspada_ringan:  { cls:'ws-w', hzCls:'hz-waspada', hzLevel:'lv-waspada', icon:'⚠️', label:'Waspada Ringan — Siapkan Jas Hujan', short:'WASPADA', dhbIcon:'⚠️', dhbTitle:'Waspada Ringan', dhbSub:'Bawa jas hujan, pantau cuaca sebelum berangkat.' },
  waspada:         { cls:'ws-w', hzCls:'hz-waspada', hzLevel:'lv-waspada', icon:'⚠️', label:'Waspada — Pantau Cuaca Sebelum Berangkat', short:'WASPADA', dhbIcon:'⚠️', dhbTitle:'Waspada', dhbSub:'Pantau kondisi cuaca dengan cermat sebelum berkunjung.' },
  tidak_disarankan:{ cls:'ws-b', hzCls:'hz-bahaya', hzLevel:'lv-bahaya', icon:'🔴', label:'Tidak Disarankan — Cuaca Buruk', short:'BAHAYA', dhbIcon:'🔴', dhbTitle:'Tidak Disarankan', dhbSub:'Cuaca buruk, risiko banjir/longsor meningkat signifikan.' },
  bahaya:          { cls:'ws-b', hzCls:'hz-bahaya', hzLevel:'lv-bahaya', icon:'🚨', label:'BAHAYA — Jangan Berkunjung Saat Ini!', short:'BAHAYA', dhbIcon:'🚨', dhbTitle:'BAHAYA — Jangan Berkunjung!', dhbSub:'Cuaca ekstrem — risiko bencana sangat tinggi saat ini.' }
  };

  function diffClass(d) { return d==='Mudah'?'d-mudah':d==='Sedang'?'d-sedang':'d-sulit'; }
  function diffColor(d) { return d==='Mudah'?'#22c55e':d==='Sedang'?'var(--amber)':'var(--red)'; }

  function showToast(msg) {
  const t = document.getElementById('toast');
  document.getElementById('toast-msg').textContent = msg;
  t.classList.add('show');
  setTimeout(() => t.classList.remove('show'), 2800);
  }

  // ══════════════════════════════════════════
  // PAGE SYSTEM
  // ══════════════════════════════════════════
  function showPage(id, cobanId) {
  const pageEl = document.getElementById('page-' + id);
  if(!pageEl) return;
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.sb-nav a').forEach(a => a.classList.remove('active'));
  document.querySelectorAll('.mob-tab').forEach(b => b.classList.remove('active'));
  pageEl.classList.add('active');
  const navEl = document.getElementById('nav-' + id);
  if(navEl) navEl.classList.add('active');
  const mTabs = document.querySelectorAll('.mob-tab');
  const pageIdx = ['explore','peta','hazard'].indexOf(id);
  if(pageIdx>=0 && mTabs[pageIdx]) mTabs[pageIdx].classList.add('active');
  window.scrollTo({top:0, behavior:'smooth'});
  if(id==='cuaca' && !weatherMainLoaded){ loadMainWeather(); weatherMainLoaded=true; }
  if(id==='peta'){ if(!mapInit){initMap();mapInit=true;} if(cobanId) selectMapDest(cobanId); }
  if(id==='detail' && cobanId) loadDetail(cobanId);
  if(id==='hazard') loadHazardPage();
  }

  // Sidebar filter
  function setSbFilter(f) {
  activeFilter = f;
  document.querySelectorAll('[id^="sbf-"]').forEach(a => a.classList.remove('active'));
  const key = f==='all'?'all':f==='fav'?'fav':f.toLowerCase();
  const el = document.getElementById('sbf-' + key);
  if(el) el.classList.add('active');
  applyFilters();
  }

  // ══════════════════════════════════════════
  // WEATHER
  // ══════════════════════════════════════════
  function loadMainWeather() {
  const lat=-7.8846, lon=112.5206;
  fetch(`https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${OWM}&units=metric`)
  .then(r=>r.json()).then(d=>{
  const temp=Math.round(d.main?.temp??0),hum=d.main?.humidity??0,
  wind=+(d.wind?.speed??0).toFixed(1),rain=+(d.rain?.['1h']??0).toFixed(1),
  cond=d.weather?.[0]?.main??'—';
  const setEl=(id,html,txt)=>{ const e=document.getElementById(id); if(!e) return; txt?e.textContent=html:e.innerHTML=html; };
  setEl('wm-temp',`${temp}<sup>°C</sup>`);
  setEl('wm-cond',`${wIcon(cond)} ${cond}`,true);
  setEl('wm-rain',`${rain} mm/jam`,true);
  setEl('wm-wind',`${wind} m/s`,true);
  setEl('wm-hum',`${hum}%`,true);
  setEl('wm-time',new Date().toLocaleString('id-ID',{weekday:'long',day:'numeric',month:'long',hour:'2-digit',minute:'2-digit'}),true);
  const lv=riskLevel(rain,wind,hum), rd=RISK_MAP[lv]||RISK_MAP.aman;
  const el=document.getElementById('wm-status'); if(el){ el.className='w-status '+rd.cls; el.textContent=rd.icon+' '+rd.label; }
  const sbDot=document.querySelector('.sb-dot'); if(sbDot) sbDot.style.background = lv==='aman'?'var(--cyan)':lv.includes('waspada')?'var(--amber)':'var(--red)';
  }).catch(()=>{});
  fetch(`https://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lon}&appid=${OWM}&units=metric`)
  .then(r=>r.json()).then(data=>{
  const strip=document.getElementById('fc-strip'); if(!strip) return;
  strip.innerHTML='';
  for(let i=0;i<data.list.length;i+=8){
  const d=data.list[i];
  const el=document.createElement('div');
  el.className='fcrd';
  el.innerHTML=`<div class="fcrd-day">${new Date(d.dt_txt).toLocaleDateString('id-ID',{weekday:'short',day:'numeric'})}</div><div class="fcrd-ico">${wIcon(d.weather[0].main)}</div><div class="fcrd-t">${Math.round(d.main.temp)}°C</div><div class="fcrd-cond">${d.weather[0].main}</div>`;
  strip.appendChild(el);
  }
  }).catch(()=>{ const s=document.getElementById('fc-strip'); if(s) s.innerHTML='<div style="color:var(--ink3);font-size:.72rem;padding:14px">// Prakiraan tidak tersedia.</div>'; });
  }

  function loadCobanWeather(lat, lon, elev, cobanId) {
  ['dw-temp','dw-cond','dw-rain','dw-wind','dw-hum'].forEach(id=>{ document.getElementById(id).innerHTML = id==='dw-temp'?'--<sup>°C</sup>':'—'; });
  document.getElementById('dw-elev').textContent = elev;
  document.getElementById('dw-forecast').innerHTML='';
  document.getElementById('dw-cond').textContent='Memuat…';

  fetch(`https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${OWM}&units=metric`)
  .then(r=>r.json()).then(d=>{
  const temp=Math.round(d.main?.temp??0),hum=d.main?.humidity??0,
  wind=+(d.wind?.speed??0).toFixed(1),rain=+(d.rain?.['1h']??0).toFixed(1),
  cond=d.weather?.[0]?.main??'—';
  document.getElementById('dw-temp').innerHTML=`${temp}<sup>°C</sup>`;
  document.getElementById('dw-cond').textContent=`${wIcon(cond)} ${cond}`;
  document.getElementById('dw-rain').textContent=`${rain} mm/jam`;
  document.getElementById('dw-wind').textContent=`${wind} m/s`;
  document.getElementById('dw-hum').textContent=`${hum}%`;
  const lv=riskLevel(rain,wind,hum), rd=RISK_MAP[lv]||RISK_MAP.aman;
  const sm=document.getElementById('dw-status-mini');
  sm.className='dw-status-mini '+(lv==='aman'||lv==='waspada_ringan'?'dws-aman':lv==='waspada'?'dws-waspada':'dws-bahaya');
  sm.textContent=rd.icon+' '+rd.short;
  // Update hazard banner
  const banner=document.getElementById('det-hazard-banner');
  banner.className='det-hazard-banner '+rd.hzCls;
  document.getElementById('dhb-icon').textContent=rd.dhbIcon;
  document.getElementById('dhb-title').textContent=rd.dhbTitle;
  document.getElementById('dhb-sub').textContent=rd.dhbSub;
  const lvEl=document.getElementById('dhb-level');
  lvEl.className='dhb-level '+rd.hzLevel;
  lvEl.textContent=rd.short;
  // cache
  if(cobanId) hazardCache[cobanId]={lv,rd,temp,cond};
  }).catch(()=>{ document.getElementById('dw-cond').textContent='Gagal memuat data cuaca.'; });

  fetch(`https://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lon}&appid=${OWM}&units=metric`)
  .then(r=>r.json()).then(data=>{
  const fc=document.getElementById('dw-forecast');
  fc.innerHTML='';
  for(let i=0;i<data.list.length;i+=8){
  const d=data.list[i];
  const el=document.createElement('div');
  el.className='dwfc';
  el.innerHTML=`<div class="dwfc-day">${new Date(d.dt_txt).toLocaleDateString('id-ID',{weekday:'short',day:'numeric'})}</div><div class="dwfc-ico">${wIcon(d.weather[0].main)}</div><div class="dwfc-t">${Math.round(d.main.temp)}°C</div>`;
  fc.appendChild(el);
  }
  }).catch(()=>{});
  }

  // ══════════════════════════════════════════
  // HAZARD PAGE — NEW FEATURE
  // ══════════════════════════════════════════
  async function loadHazardPage() {
  const grid = document.getElementById('hazard-grid');
  grid.innerHTML = cobans.map(c => `
  <div class="hazard-card hz-aman" id="hzc-${c.id}" onclick="showPage('detail',${c.id})">
    <div class="hzc-name">${c.name}</div>
    <div class="hzc-loc">${c.location}</div>
    <div class="hzc-badges">
      <span class="hzc-status" id="hzc-status-${c.id}" style="background:rgba(196,149,90,.15);color:var(--cyan)">⏳ Memuat</span>
      <span class="hzc-diff ${diffClass(c.difficulty)}">${c.difficulty}</span>
    </div>
  </div>`).join('');

  // Fetch weather for a sample of cobans (use Rais as reference for similar areas)
  const referenceCoban = cobans.find(c=>c.id===3);
  try {
  const resp = await fetch(`https://api.openweathermap.org/data/2.5/weather?lat=${referenceCoban.lat}&lon=${referenceCoban.lng}&appid=${OWM}&units=metric`);
  const d = await resp.json();
  const rain=+(d.rain?.['1h']??0).toFixed(1), wind=+(d.wind?.speed??0).toFixed(1), hum=d.main?.humidity??0;
  const baseLv = riskLevel(rain,wind,hum);
  const baseRd = RISK_MAP[baseLv]||RISK_MAP.aman;

  // Update global status bar
  const statusBar = document.getElementById('wm-status-hazard');
  statusBar.className='w-status '+baseRd.cls;
  statusBar.textContent=baseRd.icon+' '+baseRd.label+' · '+Math.round(d.main?.temp??0)+'°C';

  cobans.forEach(c => {
  // Apply slight variance per difficulty
  let lv = baseLv;
  if(c.difficulty==='Sulit' && (baseLv==='waspada_ringan'||baseLv==='aman')) lv='waspada_ringan';
  if(c.difficulty==='Sulit' && baseLv==='waspada') lv='tidak_disarankan';
  const rd = RISK_MAP[lv]||RISK_MAP.aman;
  const card = document.getElementById('hzc-'+c.id);
  const statusEl = document.getElementById('hzc-status-'+c.id);
  if(card){ card.className='hazard-card '+rd.hzCls; }
  if(statusEl){
  const col = lv==='aman'?'var(--cyan)':lv.includes('waspada')?'var(--amber)':'var(--red)';
  const bg = lv==='aman'?'rgba(196,149,90,.15)':lv.includes('waspada')?'rgba(255,176,32,.15)':'rgba(255,77,77,.15)';
  statusEl.style.background=bg; statusEl.style.color=col;
  statusEl.textContent=rd.icon+' '+rd.short;
  }
  });
  } catch(e) {
  document.getElementById('wm-status-hazard').textContent='Gagal memuat data cuaca.';
  }
  }

  // ══════════════════════════════════════════
  // DETAIL PAGE
  // ══════════════════════════════════════════
  function loadDetail(id) {
  const c = cobans.find(x=>x.id===id);
  if(!c) return;
  currentCoban = c;

  document.getElementById('det-img').src = c.img;
  const diffBadge = document.getElementById('det-diff-badge');
  diffBadge.textContent = c.difficulty;
  diffBadge.className = 'cdiff '+diffClass(c.difficulty);
  document.getElementById('det-name').textContent = c.name;
  document.getElementById('det-loc').innerHTML = '📍 '+c.location;
  document.getElementById('det-desc').textContent = c.desc;
  document.getElementById('det-tags').innerHTML = c.tags.map(t=>`<span class="tag">${t}</span>`).join('');

  // Difficulty rating visual
  const dScore = c.diffScore || 5;
  const bars = Array.from({length:10},(_,i)=>
  `<div style="flex:1;height:8px;border-radius:2px;background:${i<dScore?diffColor(c.difficulty):'rgba(255,255,255,.07)'};transition:background .3s"></div>`
  ).join('');
  document.getElementById('det-diff-body').innerHTML = `
  <div style="display:flex;align-items:center;gap:20px;padding:4px 0">
    <div style="text-align:center;min-width:72px">
      <div style="font-family:'Playfair Display',Georgia,serif;font-size:3.2rem;font-weight:700;color:${diffColor(c.difficulty)};line-height:1">${dScore}</div>
      <div style="font-size:.72rem;color:var(--ink3);margin-top:2px;letter-spacing:.06em">/ 10</div>
    </div>
    <div style="flex:1">
      <div style="display:flex;gap:3px;margin-bottom:10px">${bars}</div>
      <span class="cdiff ${diffClass(c.difficulty)}" style="font-size:.8rem;position:static;padding:4px 12px">${c.difficulty}</span>
    </div>
    <div style="text-align:center;background:var(--bg3);border:1px solid var(--border2);border-radius:var(--r2);padding:14px 18px;min-width:100px">
      <div style="font-size:.58rem;color:var(--ink3);letter-spacing:.12em;text-transform:uppercase;margin-bottom:6px">Estimasi Trekking</div>
      <div style="font-family:'Playfair Display',Georgia,serif;font-size:1.25rem;font-weight:700;color:var(--ink)">${c.duration}</div>
    </div>
  </div>`;

  loadCobanWeather(c.lat, c.lng, c.elev, c.id);
  document.getElementById('det-fac').innerHTML = c.fasilitas.map(f=>`<div class="fac-item"><span class="fac-ico">${f.ico}</span>${f.name}</div>`).join('');
  document.getElementById('det-tips').innerHTML = c.tips.map(t=>`<li>${t}</li>`).join('');
  document.getElementById('det-info').innerHTML = `
  <div class="info-row"><span class="info-row-lbl">⛰ Ketinggian Air Terjun</span><span class="info-row-val">${c.height}</span></div>
  <div class="info-row"><span class="info-row-lbl">📍 Elevasi</span><span class="info-row-val">${c.elev}</span></div>
  <div class="info-row"><span class="info-row-lbl">🥾 Durasi Trekking</span><span class="info-row-val">${c.duration}</span></div>
  <div class="info-row"><span class="info-row-lbl">⏰ Jam Operasional</span><span class="info-row-val">${c.jam}</span></div>
  <div class="info-row" style="border:none"><span class="info-row-lbl">🌐 Koordinat</span><span class="info-row-val" style="font-family:'Crimson Text',Georgia,serif;font-size:.68rem">${c.lat}, ${c.lng}</span></div>`;
  document.getElementById('det-tiket').innerHTML = c.tiket.map(t=>`<tr><td>${t.lbl}</td><td>${t.val}</td></tr>`).join('');
  document.getElementById('det-tiket-note').textContent = c.tiketNote;
  document.getElementById('det-peta-btn').onclick = ()=>showPage('peta',c.id);

  // offline map size varies
  const sizes = ['1.8 MB','2.1 MB','2.4 MB','1.6 MB','2.8 MB'];
  document.getElementById('om-size').textContent = '~'+sizes[c.id%5];
  }

  // ── Offline Map Download (simulated — opens OSM)
  function downloadOfflineMap() {
  if(!currentCoban) return;
  const c = currentCoban;
  const url = `https://www.openstreetmap.org/?mlat=${c.lat}&mlon=${c.lng}#map=14/${c.lat}/${c.lng}`;
  window.open(url,'_blank');
  showToast('Membuka peta area '+c.name+'…');
  }

  // ── Social Nav: Copy Coordinates
  function copyCoords() {
  if(!currentCoban) return;
  const text = `${currentCoban.name}\nKoordinat: ${currentCoban.lat}, ${currentCoban.lng}\nhttps://maps.google.com/?q=${currentCoban.lat},${currentCoban.lng}`;
  navigator.clipboard.writeText(text).then(()=>showToast('Koordinat disalin ke clipboard!')).catch(()=>showToast('Gagal menyalin koordinat'));
  }

  // ── Social Nav: WhatsApp Share
  function shareWhatsApp() {
  if(!currentCoban) return;
  const c = currentCoban;
  const msg = encodeURIComponent(`Yuk ke ${c.name}! 🌊\n📍 ${c.location}\n⛰ Ketinggian: ${c.height} | 🥾 ${c.duration}\nKoordinat: https://maps.google.com/?q=${c.lat},${c.lng}\n\nCek info lengkap di Waterfall Malang!`);
  window.open(`https://wa.me/?text=${msg}`,'_blank');
  }

  // ══════════════════════════════════════════
  // EXPLORER / GRID
  // ══════════════════════════════════════════
  function renderGrid(list) {
  const grid=document.getElementById('cobanGrid'), empty=document.getElementById('emptyState');
  const fcountEl=document.getElementById('fcount'); if(fcountEl) fcountEl.innerHTML=`<b>${list.length}</b> coban`;
  const sbCount=document.getElementById('sb-count'); if(sbCount) sbCount.textContent=list.length;
  if(!list.length){ grid.innerHTML=''; empty.style.display='block'; return; }
  empty.style.display='none';

  // Use cached hazard if available
  grid.innerHTML = list.map((c,i) => {
  const hcache = hazardCache[c.id];
  const hzCls = hcache ? RISK_MAP[hcache.lv]?.hzCls||'hz-aman' : 'hz-aman';
  const hzShort = hcache ? RISK_MAP[hcache.lv]?.short||'—' : '—';
  return `
  <div class="card diff-${c.difficulty.toLowerCase()}" style="animation-delay:${i*.04}s" onclick="showPage('detail',${c.id})">
    <div class="cimg-wrap">
      <img class="cimg" src="${c.img}" alt="${c.name}" loading="lazy">
      <div class="cimg-overlay"></div>
      <div class="c-hazard ${hzCls}"><span class="hz-dot"></span>${hzShort}</div>
      <span class="cdiff ${diffClass(c.difficulty)}">${c.difficulty}</span>
      <button class="cfave" onclick="toggleFav(event,${c.id})">${favs.has(c.id)?'❤️':'🤍'}</button>
    </div>
    <div class="cbody">
      <div class="cname">${c.name}</div>
      <div class="cloc">📍 ${c.location}</div>
      <div class="diff-bar-wrap">
        <span class="diff-bar-label">${c.diffScore}/10</span>
        <div class="diff-bar"><div class="diff-bar-fill diff-fill-${c.difficulty.toLowerCase()}" style="width:${c.diffScore*10}%"></div></div>
      </div>
      <div class="cdesc">${c.desc}</div>
      <div class="cmeta">
        <span class="mpill">⛰ ${c.height}</span>
        <span class="mpill">🥾 ${c.duration}</span>
      </div>
      <div class="cfoot">
        <div class="cprice">${c.tiket[0].val}<sub>/orang</sub></div>
        <button class="cdetail-btn" onclick="showPage('detail',${c.id});event.stopPropagation()">Detail →</button>
      </div>
    </div>
  </div>`;
  }).join('');
  }

  function applyFilters() {
  const q = document.getElementById('searchInput').value.toLowerCase();
  renderGrid(cobans.filter(c => {
  const mq = c.name.toLowerCase().includes(q)||c.location.toLowerCase().includes(q)||c.tags.some(t=>t.toLowerCase().includes(q));
  const mf = activeFilter==='all'||activeFilter==='fav'?true:c.difficulty===activeFilter;
  const mfav = activeFilter!=='fav'||favs.has(c.id);
  return mq && mf && mfav;
  }));
  }

  function setFilter(btn, f) {
  activeFilter = f;
  document.querySelectorAll('.tag-btn').forEach(b=>b.classList.remove('on'));
  btn.classList.add('on');
  applyFilters();
  }

  function toggleFav(e, id) {
  e.stopPropagation();
  favs.has(id)?favs.delete(id):favs.add(id);
  applyFilters();
  showToast(favs.has(id)?'Ditambahkan ke favorit ❤️':'Dihapus dari favorit');
  }

  // ══════════════════════════════════════════
  // MAP + ROUTING
  // ══════════════════════════════════════════
  let leafMap=null, userLat=null, userLng=null, routeLayer=null;
  const allMarkers={};

  function initMap() {
  leafMap = L.map('map',{zoomControl:true}).setView([-7.98,112.62],10);
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{attribution:'© OpenStreetMap',maxZoom:18}).addTo(leafMap);

  cobans.forEach(c=>{
  const col = c.difficulty==='Mudah'?'#22c55e':c.difficulty==='Sedang'?'#d4a843':'#c96060';
  const icon = L.divIcon({
  html:`<div style="background:${col};color:#000;padding:2px 7px;border-radius:4px;font-size:10px;font-weight:700;white-space:nowrap;box-shadow:0 2px 10px rgba(0,0,0,.4);font-family:'Playfair Display',Georgia,serif">${c.name}</div>`,
  className:'',iconAnchor:[40,12]
  });
  allMarkers[c.id]=L.marker([c.lat,c.lng],{icon}).addTo(leafMap)
  .bindPopup(`<b style="font-family:'Playfair Display',Georgia,serif">${c.name}</b><br><small>${c.location}</small><br><small>⛰ ${c.height} · 🥾 ${c.duration}</small>`);
  });

  const list=document.getElementById('peta-dest-list');
  cobans.forEach(c=>{
  const col = c.difficulty==='Mudah'?'#22c55e':c.difficulty==='Sedang'?'var(--amber)':'var(--red)';
  const item=document.createElement('div');
  item.className='peta-dest-item'; item.id='pdi-'+c.id;
  item.innerHTML=`<div class="pdi-dot" style="background:${col}"></div><div><div class="pdi-name">${c.name}</div><div class="pdi-loc">${c.location}</div></div>`;
  item.onclick=()=>selectMapDest(c.id);
  list.appendChild(item);
  });

  if(navigator.geolocation){
  navigator.geolocation.getCurrentPosition(pos=>{
  userLat=pos.coords.latitude; userLng=pos.coords.longitude;
  const uIco=L.divIcon({html:`<div style="background:#a87840;color:#fff;padding:2px 7px;border-radius:4px;font-size:10px;font-weight:700;box-shadow:0 2px 10px rgba(0,0,0,.4)">📍 Anda</div>`,className:'',iconAnchor:[28,12]});
  L.marker([userLat,userLng],{icon:uIco}).addTo(leafMap).bindPopup('Lokasi Anda saat ini');
  },()=>{document.getElementById('ri-status').textContent='GPS tidak tersedia';});
  }
  }

  function selectMapDest(id) {
  const c=cobans.find(x=>x.id===id); if(!c) return;
  document.querySelectorAll('.peta-dest-item').forEach(el=>el.classList.remove('active'));
  const item=document.getElementById('pdi-'+id);
  if(item){item.classList.add('active');item.scrollIntoView({behavior:'smooth',block:'nearest'});}
  leafMap.flyTo([c.lat,c.lng],13,{duration:1.2});
  allMarkers[id].openPopup();
  const bar=document.getElementById('route-info-bar');
  document.getElementById('ri-dest').textContent=c.name;
  if(!userLat||!userLng){
  bar.style.display='flex';
  document.getElementById('ri-dist').textContent='—';
  document.getElementById('ri-dur').textContent='—';
  document.getElementById('ri-status').textContent='Aktifkan GPS untuk melihat rute';
  return;
  }
  const osrmUrl=`https://router.project-osrm.org/route/v1/driving/${userLng},${userLat};${c.lng},${c.lat}?overview=full&geometries=geojson`;
  document.getElementById('ri-dist').textContent='…';
  document.getElementById('ri-dur').textContent='…';
  document.getElementById('ri-status').textContent='Menghitung rute…';
  bar.style.display='flex';
  fetch(osrmUrl).then(r=>r.json()).then(data=>{
  if(data.code!=='Ok'||!data.routes?.length) throw new Error('no route');
  const route=data.routes[0];
  const distKm=(route.distance/1000).toFixed(1), durMin=Math.round(route.duration/60);
  const durStr=durMin>=60?`${Math.floor(durMin/60)} jam ${durMin%60} mnt`:`${durMin} menit`;
  document.getElementById('ri-dist').textContent=`${distKm} km`;
  document.getElementById('ri-dur').textContent=durStr;
  document.getElementById('ri-status').textContent=`Via jalan terdekat`;
  if(routeLayer) leafMap.removeLayer(routeLayer);
  routeLayer=L.geoJSON(route.geometry,{style:{color:'#c4955a',weight:4,opacity:.85}}).addTo(leafMap);
  const coords=route.geometry.coordinates;
  leafMap.fitBounds(L.latLngBounds(coords.map(c2=>[c2[1],c2[0]])),{padding:[40,40]});
  }).catch(()=>{
  if(routeLayer) leafMap.removeLayer(routeLayer);
  routeLayer=L.polyline([[userLat,userLng],[c.lat,c.lng]],{color:'#c4955a',weight:3,dashArray:'8 6',opacity:.7}).addTo(leafMap);
  const dist=haversine(userLat,userLng,c.lat,c.lng);
  document.getElementById('ri-dist').textContent=`~${dist.toFixed(1)} km`;
  document.getElementById('ri-dur').textContent=`~${Math.round(dist/40*60)} menit`;
  document.getElementById('ri-status').textContent='Estimasi garis lurus';
  leafMap.fitBounds([[userLat,userLng],[c.lat,c.lng]],{padding:[40,40]});
  });
  }

  function haversine(lat1,lon1,lat2,lon2){
  const R=6371, dLat=(lat2-lat1)*Math.PI/180, dLon=(lon2-lon1)*Math.PI/180;
  const a=Math.sin(dLat/2)**2+Math.cos(lat1*Math.PI/180)*Math.cos(lat2*Math.PI/180)*Math.sin(dLon/2)**2;
  return R*2*Math.atan2(Math.sqrt(a),Math.sqrt(1-a));
  }

  // ══════════════════════════════════════════
  // INIT
  // ══════════════════════════════════════════
  window.addEventListener('load', ()=>{
  // Animate loader logo chars (water drop effect per letter)
  const word = 'Waterfall';
  const charsEl = document.getElementById('ld-chars');
  if(charsEl){
    charsEl.innerHTML = word.split('').map((ch,i)=>
      `<span class="ch" style="animation-delay:${.05+i*.07}s">${ch}</span>`
    ).join('');
  }
  renderGrid(cobans);
  setTimeout(()=>document.getElementById('loader').classList.add('out'), 2000);
  });

</script>
</body>
</html>
