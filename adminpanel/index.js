require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');
const mongoose = require('mongoose');
const methodOverride = require('method-override');

const app = express();
const PORT = process.env.PORT || 3000;

// ─── Middleware ────────────────────────────────────────────────────────────────
app.use('/assets', express.static(path.join(__dirname, 'assets')));
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(methodOverride('_method'));

// ─── MongoDB ───────────────────────────────────────────────────────────────────
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/magicstory';
mongoose
  .connect(MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => console.log('✅ MongoDB connected'))
  .catch(err => console.log('❌ MongoDB connection error:', err));

// ─── Schemas ───────────────────────────────────────────────────────────────────
const userSchema = new mongoose.Schema({
  name: String,
  email: String,
  password: String,
  otp: Number,
  otpExpiry: Date,
  createdAt: { type: Date, default: Date.now },
});
const User = mongoose.model('User', userSchema);

const quizSchema = new mongoose.Schema({
  BasicQuiz: { type: Boolean, default: false },
  AdvanceQuiz: { type: Boolean, default: null },
  BasicQuizMarks: { type: Number, default: null },
  AdvanceQuizMarks: { type: Number, default: null },
  email: { type: String, required: true },
});
const Quiz = mongoose.model('Quiz', quizSchema);

// ─── Shared HTML Helpers ───────────────────────────────────────────────────────
const getShell = (title, bodyContent, activePage = 'home') => `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>${title} — Magic Story Admin</title>
  <link rel="icon" href="/assets/logo.png"/>
  <link rel="preconnect" href="https://fonts.googleapis.com"/>
  <link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:wght@300;400;500&display=swap" rel="stylesheet"/>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css"/>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <style>
    /* ── Reset & Tokens ─────────────────────────────── */
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    :root {
      --bg:        #0a0b10;
      --surface:   #111219;
      --surface2:  #181a24;
      --border:    rgba(255,255,255,0.07);
      --accent:    #7c5cfc;
      --accent2:   #e85d8a;
      --accent3:   #3ecfb0;
      --text:      #e8eaf0;
      --muted:     #6b7280;
      --danger:    #f43f5e;
      --success:   #10b981;
      --warning:   #f59e0b;
      --sidebar-w: 260px;
      --header-h:  64px;
      --radius:    14px;
      --font-head: 'Syne', sans-serif;
      --font-body: 'DM Sans', sans-serif;
    }

    html, body { height: 100%; font-family: var(--font-body); background: var(--bg); color: var(--text); overflow-x: hidden; }
    a { text-decoration: none; color: inherit; }
    button { cursor: pointer; font-family: var(--font-body); }

    /* ── Scrollbar ──────────────────────────────────── */
    ::-webkit-scrollbar { width: 5px; height: 5px; }
    ::-webkit-scrollbar-track { background: var(--surface); }
    ::-webkit-scrollbar-thumb { background: var(--accent); border-radius: 99px; }

    /* ── Layout ─────────────────────────────────────── */
    .layout { display: flex; height: 100vh; overflow: hidden; }

    /* ── Sidebar ────────────────────────────────────── */
    .sidebar {
      width: var(--sidebar-w);
      background: var(--surface);
      border-right: 1px solid var(--border);
      display: flex;
      flex-direction: column;
      flex-shrink: 0;
      overflow-y: auto;
      transition: transform .3s ease, width .3s ease;
      position: relative;
      z-index: 100;
    }
    .sidebar.collapsed { width: 72px; }
    .sidebar.collapsed .nav-label,
    .sidebar.collapsed .sidebar-logo-text,
    .sidebar.collapsed .nav-section-title { display: none; }
    .sidebar.collapsed .nav-item { justify-content: center; }
    .sidebar.collapsed .nav-item i { margin-right: 0; }

    .sidebar-brand {
      display: flex; align-items: center; gap: 12px;
      padding: 20px 22px 16px;
      border-bottom: 1px solid var(--border);
    }
    .sidebar-logo {
      width: 36px; height: 36px; border-radius: 10px;
      background: linear-gradient(135deg, var(--accent), var(--accent2));
      display: flex; align-items: center; justify-content: center;
      font-size: 18px; flex-shrink: 0;
    }
    .sidebar-logo-text { font-family: var(--font-head); font-size: 18px; font-weight: 800; }

    .sidebar-nav { flex: 1; padding: 14px 12px; }
    .nav-section-title {
      font-size: 10px; font-weight: 600; letter-spacing: .12em;
      color: var(--muted); text-transform: uppercase; padding: 12px 10px 6px;
    }
    .nav-item {
      display: flex; align-items: center; gap: 12px;
      padding: 10px 12px; border-radius: 10px; margin-bottom: 2px;
      font-size: 14px; font-weight: 500; color: var(--muted);
      transition: background .2s, color .2s;
    }
    .nav-item:hover { background: var(--surface2); color: var(--text); }
    .nav-item.active {
      background: linear-gradient(90deg, rgba(124,92,252,.18), rgba(232,93,138,.08));
      color: var(--text);
      border-left: 3px solid var(--accent);
    }
    .nav-item i { width: 18px; text-align: center; font-size: 15px; }

    .sidebar-footer {
      padding: 14px 12px;
      border-top: 1px solid var(--border);
    }
    .sidebar-user {
      display: flex; align-items: center; gap: 10px;
      padding: 10px 12px; border-radius: 10px;
      background: var(--surface2);
    }
    .sidebar-user-avatar {
      width: 34px; height: 34px; border-radius: 50%;
      background: linear-gradient(135deg, var(--accent), var(--accent2));
      display: flex; align-items: center; justify-content: center;
      font-size: 13px; font-weight: 700; flex-shrink: 0;
    }
    .sidebar-user-info .name { font-size: 13px; font-weight: 600; }
    .sidebar-user-info .role { font-size: 11px; color: var(--muted); }

    /* ── Main ───────────────────────────────────────── */
    .main { flex: 1; display: flex; flex-direction: column; overflow: hidden; }

    /* ── Header ─────────────────────────────────────── */
    .header {
      height: var(--header-h); display: flex; align-items: center;
      justify-content: space-between; padding: 0 28px;
      background: var(--surface); border-bottom: 1px solid var(--border);
      flex-shrink: 0;
    }
    .header-left { display: flex; align-items: center; gap: 14px; }
    .toggle-btn {
      background: var(--surface2); border: 1px solid var(--border);
      color: var(--muted); width: 36px; height: 36px; border-radius: 9px;
      display: flex; align-items: center; justify-content: center;
      transition: color .2s, border-color .2s;
    }
    .toggle-btn:hover { color: var(--text); border-color: var(--accent); }
    .breadcrumb { font-size: 13px; color: var(--muted); }
    .breadcrumb span { color: var(--text); font-weight: 600; }

    .header-right { display: flex; align-items: center; gap: 10px; }
    .header-icon-btn {
      position: relative;
      background: var(--surface2); border: 1px solid var(--border);
      color: var(--muted); width: 36px; height: 36px; border-radius: 9px;
      display: flex; align-items: center; justify-content: center;
      transition: color .2s;
    }
    .header-icon-btn:hover { color: var(--text); }
    .badge-dot {
      position: absolute; top: 7px; right: 7px;
      width: 7px; height: 7px; border-radius: 50%;
      background: var(--accent2); border: 1px solid var(--surface);
    }
    .logout-btn {
      display: flex; align-items: center; gap: 7px;
      background: linear-gradient(135deg, var(--danger), #c0392b);
      color: #fff; border: none; padding: 8px 16px;
      border-radius: 9px; font-size: 13px; font-weight: 600;
      transition: opacity .2s, transform .15s;
    }
    .logout-btn:hover { opacity: .88; transform: translateY(-1px); }

    /* ── Content ─────────────────────────────────────── */
    .content { flex: 1; overflow-y: auto; padding: 28px; }

    /* ── Page Title ──────────────────────────────────── */
    .page-title { font-family: var(--font-head); font-size: 26px; font-weight: 800; margin-bottom: 4px; }
    .page-subtitle { font-size: 13px; color: var(--muted); margin-bottom: 28px; }

    /* ── Stat Cards ──────────────────────────────────── */
    .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 18px; margin-bottom: 28px; }
    .stat-card {
      background: var(--surface); border: 1px solid var(--border);
      border-radius: var(--radius); padding: 22px 24px;
      position: relative; overflow: hidden;
      transition: transform .2s, box-shadow .2s;
    }
    .stat-card:hover { transform: translateY(-3px); box-shadow: 0 12px 40px rgba(0,0,0,.4); }
    .stat-card::before {
      content: ''; position: absolute; inset: 0;
      opacity: .06; border-radius: inherit;
    }
    .stat-card.purple::before { background: var(--accent); }
    .stat-card.pink::before   { background: var(--accent2); }
    .stat-card.teal::before   { background: var(--accent3); }
    .stat-card.amber::before  { background: var(--warning); }
    .stat-glow {
      position: absolute; top: -20px; right: -20px;
      width: 80px; height: 80px; border-radius: 50%; opacity: .15; filter: blur(20px);
    }
    .stat-card.purple .stat-glow { background: var(--accent); }
    .stat-card.pink   .stat-glow { background: var(--accent2); }
    .stat-card.teal   .stat-glow { background: var(--accent3); }
    .stat-card.amber  .stat-glow { background: var(--warning); }
    .stat-icon {
      width: 40px; height: 40px; border-radius: 10px;
      display: flex; align-items: center; justify-content: center;
      font-size: 17px; margin-bottom: 14px;
    }
    .stat-card.purple .stat-icon { background: rgba(124,92,252,.15); color: var(--accent); }
    .stat-card.pink   .stat-icon { background: rgba(232,93,138,.15); color: var(--accent2); }
    .stat-card.teal   .stat-icon { background: rgba(62,207,176,.15); color: var(--accent3); }
    .stat-card.amber  .stat-icon { background: rgba(245,158,11,.15); color: var(--warning); }
    .stat-value { font-family: var(--font-head); font-size: 32px; font-weight: 800; margin-bottom: 4px; }
    .stat-label { font-size: 12px; color: var(--muted); font-weight: 500; text-transform: uppercase; letter-spacing: .06em; }
    .stat-trend { font-size: 12px; margin-top: 8px; display: flex; align-items: center; gap: 4px; }
    .stat-trend.up   { color: var(--success); }
    .stat-trend.down { color: var(--danger); }

    /* ── Charts Row ──────────────────────────────────── */
    .charts-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 18px; margin-bottom: 28px; }
    @media (max-width: 900px) { .charts-grid { grid-template-columns: 1fr; } }

    /* ── Card ────────────────────────────────────────── */
    .card {
      background: var(--surface); border: 1px solid var(--border);
      border-radius: var(--radius); overflow: hidden;
    }
    .card-header {
      display: flex; align-items: center; justify-content: space-between;
      padding: 18px 22px; border-bottom: 1px solid var(--border);
    }
    .card-title { font-family: var(--font-head); font-size: 15px; font-weight: 700; display: flex; align-items: center; gap: 8px; }
    .card-title i { color: var(--accent); }
    .card-body { padding: 22px; }
    .card-body.no-pad { padding: 0; }

    /* ── Table ───────────────────────────────────────── */
    .table-wrap { overflow-x: auto; }
    table { width: 100%; border-collapse: collapse; font-size: 13.5px; }
    thead tr { border-bottom: 1px solid var(--border); }
    thead th {
      padding: 12px 16px; text-align: left;
      font-size: 11px; font-weight: 600; letter-spacing: .08em;
      text-transform: uppercase; color: var(--muted);
      white-space: nowrap;
    }
    tbody tr { border-bottom: 1px solid var(--border); transition: background .15s; }
    tbody tr:last-child { border-bottom: none; }
    tbody tr:hover { background: var(--surface2); }
    tbody td { padding: 13px 16px; vertical-align: middle; }

    .avatar-cell { display: flex; align-items: center; gap: 10px; }
    .avatar {
      width: 32px; height: 32px; border-radius: 50%; flex-shrink: 0;
      background: linear-gradient(135deg, var(--accent), var(--accent2));
      display: flex; align-items: center; justify-content: center;
      font-size: 12px; font-weight: 700;
    }
    .user-name { font-weight: 500; font-size: 13.5px; }
    .user-email { font-size: 12px; color: var(--muted); margin-top: 1px; }

    .pill {
      display: inline-flex; align-items: center; gap: 5px;
      padding: 3px 10px; border-radius: 99px;
      font-size: 11px; font-weight: 600;
    }
    .pill.active  { background: rgba(16,185,129,.15); color: var(--success); }
    .pill.yes     { background: rgba(124,92,252,.15);  color: var(--accent); }
    .pill.no      { background: rgba(255,255,255,.06); color: var(--muted); }

    .pass-cell { font-family: monospace; font-size: 12px; color: var(--muted); letter-spacing: .04em; }

    .btn-del {
      background: rgba(244,63,94,.1); color: var(--danger);
      border: 1px solid rgba(244,63,94,.25); padding: 5px 12px;
      border-radius: 7px; font-size: 12px; font-weight: 600;
      transition: background .2s, transform .15s;
    }
    .btn-del:hover { background: rgba(244,63,94,.22); transform: scale(1.04); }

    /* ── Search / Filter bar ─────────────────────────── */
    .table-toolbar {
      display: flex; align-items: center; justify-content: space-between;
      padding: 14px 22px; border-bottom: 1px solid var(--border); gap: 12px; flex-wrap: wrap;
    }
    .search-box {
      display: flex; align-items: center; gap: 8px;
      background: var(--surface2); border: 1px solid var(--border);
      border-radius: 9px; padding: 7px 14px; min-width: 220px;
    }
    .search-box i { color: var(--muted); font-size: 13px; }
    .search-box input {
      background: none; border: none; outline: none;
      color: var(--text); font-family: var(--font-body); font-size: 13px; flex: 1;
    }
    .search-box input::placeholder { color: var(--muted); }
    .table-count { font-size: 13px; color: var(--muted); }

    /* ── Server Progress ─────────────────────────────── */
    .prog-list { display: flex; flex-direction: column; gap: 16px; }
    .prog-row {}
    .prog-meta { display: flex; justify-content: space-between; margin-bottom: 6px; font-size: 13px; }
    .prog-label { font-weight: 500; }
    .prog-val { color: var(--muted); font-size: 12px; }
    .prog-bar { height: 6px; background: var(--surface2); border-radius: 99px; overflow: hidden; }
    .prog-fill { height: 100%; border-radius: 99px; transition: width 1s ease; }

    /* ── Quiz table ──────────────────────────────────── */
    .score-chip {
      font-family: var(--font-head); font-size: 13px; font-weight: 700;
      padding: 2px 9px; border-radius: 6px;
      background: rgba(62,207,176,.12); color: var(--accent3);
    }

    /* ── Toast ───────────────────────────────────────── */
    #toast {
      position: fixed; bottom: 28px; right: 28px; z-index: 9999;
      background: var(--surface); border: 1px solid var(--border);
      padding: 14px 20px; border-radius: 12px;
      font-size: 14px; display: flex; align-items: center; gap: 10px;
      box-shadow: 0 8px 32px rgba(0,0,0,.5);
      transform: translateY(80px); opacity: 0;
      transition: transform .35s cubic-bezier(.34,1.56,.64,1), opacity .3s;
      pointer-events: none;
    }
    #toast.show { transform: translateY(0); opacity: 1; }
    #toast i { color: var(--success); }

    /* ── Responsive ──────────────────────────────────── */
    @media (max-width: 768px) {
      .sidebar { position: fixed; left: 0; top: 0; height: 100%; transform: translateX(-100%); }
      .sidebar.mobile-open { transform: translateX(0); }
      .stats-grid { grid-template-columns: 1fr 1fr; }
      .content { padding: 18px; }
      .header { padding: 0 16px; }
    }
    @media (max-width: 480px) {
      .stats-grid { grid-template-columns: 1fr; }
      .breadcrumb { display: none; }
    }

    /* ── Mobile overlay ──────────────────────────────── */
    .overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,.5); z-index: 99; }
    .overlay.active { display: block; }

    /* ── Animations ──────────────────────────────────── */
    @keyframes fadeUp {
      from { opacity: 0; transform: translateY(18px); }
      to   { opacity: 1; transform: translateY(0); }
    }
    .fade-up { animation: fadeUp .45s ease both; }
    .delay-1 { animation-delay: .05s; }
    .delay-2 { animation-delay: .1s; }
    .delay-3 { animation-delay: .15s; }
    .delay-4 { animation-delay: .2s; }

    /* ── Login page ──────────────────────────────────── */
    .login-wrap {
      min-height: 100vh; display: flex; align-items: center; justify-content: center;
      background: var(--bg);
      background-image: radial-gradient(ellipse at 20% 50%, rgba(124,92,252,.12) 0%, transparent 60%),
                        radial-gradient(ellipse at 80% 20%, rgba(232,93,138,.1) 0%, transparent 55%);
    }
    .login-box {
      width: 100%; max-width: 420px; padding: 0 20px;
    }
    .login-card {
      background: var(--surface); border: 1px solid var(--border);
      border-radius: 20px; padding: 40px 36px;
      animation: fadeUp .5s ease both;
    }
    .login-logo {
      width: 52px; height: 52px; border-radius: 14px;
      background: linear-gradient(135deg, var(--accent), var(--accent2));
      display: flex; align-items: center; justify-content: center;
      font-size: 24px; margin-bottom: 22px;
    }
    .login-title { font-family: var(--font-head); font-size: 26px; font-weight: 800; margin-bottom: 6px; }
    .login-sub { font-size: 13px; color: var(--muted); margin-bottom: 28px; }
    .form-group { margin-bottom: 16px; }
    .form-label { font-size: 12px; font-weight: 600; color: var(--muted); text-transform: uppercase; letter-spacing: .06em; display: block; margin-bottom: 7px; }
    .form-input {
      width: 100%; padding: 11px 14px;
      background: var(--surface2); border: 1px solid var(--border);
      border-radius: 10px; color: var(--text);
      font-family: var(--font-body); font-size: 14px; outline: none;
      transition: border-color .2s, box-shadow .2s;
    }
    .form-input:focus { border-color: var(--accent); box-shadow: 0 0 0 3px rgba(124,92,252,.15); }
    .form-input::placeholder { color: var(--muted); }
    .submit-btn {
      width: 100%; padding: 13px;
      background: linear-gradient(135deg, var(--accent), var(--accent2));
      color: #fff; border: none; border-radius: 10px;
      font-family: var(--font-body); font-size: 15px; font-weight: 600;
      margin-top: 6px; transition: opacity .2s, transform .15s;
    }
    .submit-btn:hover { opacity: .9; transform: translateY(-1px); }
    .error-msg { color: var(--danger); font-size: 13px; margin-top: 12px; text-align: center; }
  </style>
</head>
<body>
${bodyContent}
<div id="toast"><i class="fas fa-check-circle"></i><span id="toast-msg"></span></div>
<script>
  // ── Sidebar toggle ────────────────────────────────
  const sidebar   = document.getElementById('sidebar');
  const overlay   = document.getElementById('overlay');
  const toggleBtn = document.getElementById('toggleBtn');
  if (toggleBtn && sidebar) {
    toggleBtn.addEventListener('click', () => {
      if (window.innerWidth <= 768) {
        sidebar.classList.toggle('mobile-open');
        overlay && overlay.classList.toggle('active');
      } else {
        sidebar.classList.toggle('collapsed');
      }
    });
    overlay && overlay.addEventListener('click', () => {
      sidebar.classList.remove('mobile-open');
      overlay.classList.remove('active');
    });
  }

  // ── Live search in user table ─────────────────────
  const searchInput = document.getElementById('userSearch');
  if (searchInput) {
    searchInput.addEventListener('input', function() {
      const q = this.value.toLowerCase();
      document.querySelectorAll('#usersBody tr').forEach(tr => {
        tr.style.display = tr.textContent.toLowerCase().includes(q) ? '' : 'none';
      });
      document.getElementById('tableCount').textContent =
        [...document.querySelectorAll('#usersBody tr')].filter(r => r.style.display !== 'none').length + ' users';
    });
  }

  // ── Toast ─────────────────────────────────────────
  function showToast(msg) {
    const t = document.getElementById('toast');
    document.getElementById('toast-msg').textContent = msg;
    t.classList.add('show');
    setTimeout(() => t.classList.remove('show'), 3000);
  }

  // ── Confirm delete ────────────────────────────────
  document.querySelectorAll('.del-form').forEach(f => {
    f.addEventListener('submit', e => {
      if (!confirm('Delete this user? This cannot be undone.')) e.preventDefault();
    });
  });
</script>
</body>
</html>`;

const sidebarNav = (active) => `
<div class="overlay" id="overlay"></div>
<div class="sidebar" id="sidebar">
  <div class="sidebar-brand">
    <div class="sidebar-logo" style="display: flex; align-items: center; justify-content: center; padding: 12px;">
  <img src="/assets/logo.png" alt="Logo" 
       style="width: 60px; height: 60px; object-fit: contain; border-radius: 12px; box-shadow: 0 4px 10px rgba(0,0,0,0.2);">
</div>
    <div class="sidebar-logo-text">Magic Story</div>
  </div>
  <nav class="sidebar-nav">
    <div class="nav-section-title">Main</div>
    <a href="/home" class="nav-item ${active === 'home' ? 'active' : ''}">
      <i class="fas fa-chart-pie"></i><span class="nav-label">Dashboard</span>
    </a>
    <a href="/users" class="nav-item ${active === 'users' ? 'active' : ''}">
      <i class="fas fa-users"></i><span class="nav-label">Users</span>
    </a>
    
    <div class="nav-section-title">System</div>
    <a href="/servers" class="nav-item ${active === 'servers' ? 'active' : ''}">
      <i class="fas fa-server"></i><span class="nav-label">Servers</span>
    </a>
    <a href="/logout" class="nav-item" onclick="return confirmLogout(event)">
  <i class="fas fa-sign-out-alt"></i>
  <span class="nav-label">Logout</span>
</a>
<script>
  function confirmLogout(event) {
    event.preventDefault(); // stop immediate redirect

    const confirmAction = confirm("Are you sure you want to logout?");

    if (confirmAction) {
      window.location.href = "/logout"; // proceed
    }

    return false;
  }
</script>
  </nav>
  <div class="sidebar-footer">
    <div class="sidebar-user">
      <div class="sidebar-user-avatar">A</div>
      <div class="sidebar-user-info">
        <div class="name">Admin</div>
        <div class="role">Super Admin</div>
      </div>
    </div>
  </div>
</div>`;

const header = (title, sub) => `
<div class="header">
  <div class="header-left">
    <button class="toggle-btn" id="toggleBtn"><i class="fas fa-bars"></i></button>
    <div class="breadcrumb">Magic Story &rsaquo; <span>${title}</span></div>
  </div>
  <div class="header-right">
    <button class="header-icon-btn"><i class="fas fa-bell"></i><span class="badge-dot"></span></button>
    <button class="header-icon-btn"><i class="fas fa-cog"></i></button>
    <a href="/logout" class="logout-btn"  onclick="return confirmLogout(event)"><i class="fas fa-sign-out-alt"></i>Logout</a>

  <i class="fas fa-sign-out-alt"></i>
  <span class="nav-label">Logout</span>
</a>
<script>
  function confirmLogout(event) {
    event.preventDefault(); // stop immediate redirect

    const confirmAction = confirm("Are you sure you want to logout?");

    if (confirmAction) {
      window.location.href = "/logout"; // proceed
    }

    return false;
  }
</script>
  </div>
</div>`;

// ─── Auth guard ────────────────────────────────────────────────────────────────
// Simple cookie-based session (no express-session dep; lightweight)
const sessions = new Set();
function requireAuth(req, res, next) {
  const cookie = req.headers.cookie || '';
  const sid = cookie.split(';').map(c => c.trim()).find(c => c.startsWith('sid='));
  if (sid && sessions.has(sid.split('=')[1])) return next();
  res.redirect('/');
}

// ─── Routes ────────────────────────────────────────────────────────────────────

// LOGIN PAGE
app.get('/', (req, res) => {
  const error = req.query.error ? '<p class="error-msg"><i class="fas fa-exclamation-circle"></i> Invalid username or password.</p>' : '';
  res.send(getShell('Login', `
    <div class="login-wrap">
      <div class="login-box">
        <div class="login-card">
          <div class="login-logo">✨</div>
          <div class="login-title">Welcome back</div>
          <div class="login-sub">Sign in to Magic Story Admin Panel</div>
          <form action="/login" method="POST">
            <div class="form-group">
              <label class="form-label">Username</label>
              <input class="form-input" type="text" name="username" placeholder="Enter username" required autofocus/>
            </div>
            <div class="form-group">
              <label class="form-label">Password</label>
              <input class="form-input" type="password" name="password" placeholder="Enter password" required/>
            </div>
            <button class="submit-btn" type="submit">Sign In</button>
            ${error}
          </form>
        </div>
      </div>
    </div>
  `));
});

// LOGIN POST
app.post('/login', (req, res) => {
  const { username, password } = req.body;
  if (username === (process.env.ADMIN_USERNAME || 'admin') &&
      password === (process.env.ADMIN_PASSWORD || 'admin123')) {
    const sid = Math.random().toString(36).slice(2) + Date.now().toString(36);
    sessions.add(sid);
    res.setHeader('Set-Cookie', `sid=${sid}; Path=/; HttpOnly; SameSite=Lax`);
    return res.redirect('/home');
  }
  res.redirect('/?error=1');
});

// LOGOUT
app.get('/logout', (req, res) => {
  const cookie = req.headers.cookie || '';
  const sid = cookie.split(';').map(c => c.trim()).find(c => c.startsWith('sid='));
  if (sid) sessions.delete(sid.split('=')[1]);
  res.setHeader('Set-Cookie', 'sid=; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT');
  res.redirect('/');
});

// ── DASHBOARD (HOME) ───────────────────────────────────────────────────────────
app.get('/home', requireAuth, async (req, res) => {
  try {
    const users         = await User.find();
    const totalUsers    = users.length;
    const basicCount    = await Quiz.countDocuments({ BasicQuiz: true });
    const advanceCount  = await Quiz.countDocuments({ AdvanceQuiz: { $ne: null } });

    const body = `
    <div class="layout">
      ${sidebarNav('home')}
      <div class="main">
        ${header('Dashboard', 'Overview')}
        <div class="content">
          <div class="page-title fade-up">Dashboard</div>
          <div class="page-subtitle fade-up delay-1">Welcome back, Admin — here's what's happening with Magic Story.</div>

          <!-- Stat Cards -->
          <div class="stats-grid">
            <div class="stat-card purple fade-up delay-1">
              <div class="stat-glow"></div>
              <div class="stat-icon"><i class="fas fa-users"></i></div>
              <div class="stat-value">${totalUsers}</div>
              <div class="stat-label">Total Users</div>
              <div class="stat-trend up"><i class="fas fa-arrow-up"></i> Live from DB</div>
            </div>
            <div class="stat-card pink fade-up delay-2">
              <div class="stat-glow"></div>
              <div class="stat-icon"><i class="fas fa-book-open"></i></div>
              <div class="stat-value">${basicCount}</div>
              <div class="stat-label">Basic Quizzes</div>
              <div class="stat-trend up"><i class="fas fa-arrow-up"></i> Completed</div>
            </div>
            <div class="stat-card teal fade-up delay-3">
              <div class="stat-glow"></div>
              <div class="stat-icon"><i class="fas fa-brain"></i></div>
              <div class="stat-value">${advanceCount}</div>
              <div class="stat-label">Advanced Quizzes</div>
              <div class="stat-trend up"><i class="fas fa-arrow-up"></i> Completed</div>
            </div>
            <div class="stat-card amber fade-up delay-4">
              <div class="stat-glow"></div>
              <div class="stat-icon"><i class="fas fa-server"></i></div>
              <div class="stat-value">3</div>
              <div class="stat-label">Active Servers</div>
              <div class="stat-trend up"><i class="fas fa-circle" style="font-size:7px"></i> All Online</div>
            </div>
          </div>

          <!-- Charts -->
          <div class="charts-grid">
            <div class="card fade-up delay-2">
              <div class="card-header">
                <div class="card-title"><i class="fas fa-chart-bar"></i>User Statistics</div>
              </div>
              <div class="card-body">
                <canvas id="barChart" height="220"></canvas>
              </div>
            </div>
            <div class="card fade-up delay-3">
              <div class="card-header">
                <div class="card-title"><i class="fas fa-chart-doughnut"></i>Quiz Distribution</div>
              </div>
              <div class="card-body">
                <canvas id="doughnutChart" height="220"></canvas>
              </div>
            </div>
          </div>

          <!-- Server Status -->
          <div class="card fade-up delay-4">
            <div class="card-header">
              <div class="card-title"><i class="fas fa-server"></i>Server Health</div>
            </div>
            <div class="card-body">
              <div class="prog-list">
                <div class="prog-row">
                  <div class="prog-meta"><span class="prog-label">Backup Ratio</span><span class="prog-val">92%</span></div>
                  <div class="prog-bar"><div class="prog-fill" style="width:92%;background:var(--success)"></div></div>
                </div>
                <div class="prog-row">
                  <div class="prog-meta"><span class="prog-label">Server Speed</span><span class="prog-val">95%</span></div>
                  <div class="prog-bar"><div class="prog-fill" style="width:95%;background:var(--accent)"></div></div>
                </div>
                <div class="prog-row">
                  <div class="prog-meta"><span class="prog-label">Average Uptime</span><span class="prog-val">60%</span></div>
                  <div class="prog-bar"><div class="prog-fill" style="width:60%;background:var(--warning)"></div></div>
                </div>
                <div class="prog-row">
                  <div class="prog-meta"><span class="prog-label">Shutdown Ratio</span><span class="prog-val">8%</span></div>
                  <div class="prog-bar"><div class="prog-fill" style="width:8%;background:var(--danger)"></div></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <script>
      // Bar Chart
      new Chart(document.getElementById('barChart'), {
        type: 'bar',
        data: {
          labels: ['Total Users','Basic Quiz','Advanced Quiz'],
          datasets: [{
            label: 'Count',
            data: [${totalUsers}, ${basicCount}, ${advanceCount}],
            backgroundColor: ['rgba(124,92,252,.7)','rgba(232,93,138,.7)','rgba(62,207,176,.7)'],
            borderColor:      ['#7c5cfc','#e85d8a','#3ecfb0'],
            borderWidth: 2, borderRadius: 8
          }]
        },
        options: {
          responsive: true, animation: { duration: 900, easing: 'easeOutQuart' },
          plugins: { legend: { display: false } },
          scales: {
            y: { beginAtZero: true, grid: { color: 'rgba(255,255,255,.05)' }, ticks: { color: '#6b7280' } },
            x: { grid: { display: false }, ticks: { color: '#6b7280' } }
          }
        }
      });
      // Doughnut Chart
      new Chart(document.getElementById('doughnutChart'), {
        type: 'doughnut',
        data: {
          labels: ['Basic Quiz','Advanced Quiz','No Quiz'],
          datasets: [{
            data: [${basicCount}, ${advanceCount}, Math.max(0, ${totalUsers} - ${basicCount})],
            backgroundColor: ['rgba(124,92,252,.8)','rgba(232,93,138,.8)','rgba(255,255,255,.08)'],
            borderColor: ['#7c5cfc','#e85d8a','transparent'],
            borderWidth: 2
          }]
        },
        options: {
          responsive: true, cutout: '68%',
          plugins: { legend: { labels: { color: '#6b7280', padding: 16 } } }
        }
      });
    </script>`;

    res.send(getShell('Dashboard', body, 'home'));
  } catch (err) {
    console.error(err);
    res.status(500).send('Error loading dashboard');
  }
});

// ── USERS PAGE ─────────────────────────────────────────────────────────────────
app.get('/users', requireAuth, async (req, res) => {
  try {
    const users = await User.find().sort({ createdAt: -1 });

    const rows = users.map((u, i) => {
      const initials = (u.name || 'U').split(' ').map(w => w[0]).join('').slice(0, 2).toUpperCase();
      const halfPass = u.password ? u.password.slice(0, Math.ceil(u.password.length / 2)) + '••••' : 'N/A';
      return `
      <tr>
        <td style="color:var(--muted);font-size:12px">${i + 1}</td>
        <td>
          <div class="avatar-cell">
            <div class="avatar">${initials}</div>
            <div>
              <div class="user-name">${u.name || '—'}</div>
              <div class="user-email">${u.email || '—'}</div>
            </div>
          </div>
        </td>
        <td class="pass-cell">${halfPass}</td>
        <td><span class="pill active"><i class="fas fa-circle" style="font-size:6px"></i>Active</span></td>
        <td>
          <form class="del-form" action="/delete-user/${u._id}" method="POST">
            <button class="btn-del" type="submit"><i class="fas fa-trash-alt"></i> Delete</button>
          </form>
        </td>
      </tr>`;
    }).join('');

    const body = `
    <div class="layout">
      ${sidebarNav('users')}
      <div class="main">
        ${header('Users', 'Manage')}
        <div class="content">
          <div class="page-title fade-up">Users</div>
          <div class="page-subtitle fade-up delay-1">Manage all registered Magic Story users.</div>
          <div class="card fade-up delay-2">
            <div class="table-toolbar">
              <div class="search-box">
                <i class="fas fa-search"></i>
                <input id="userSearch" type="text" placeholder="Search by name or email…"/>
              </div>
              <div class="table-count" id="tableCount">${users.length} users</div>
            </div>
            <div class="table-wrap card-body no-pad">
              <table>
                <thead>
                  <tr>
                    <th>#</th><th>User</th><th>Password (partial)</th><th>Status</th><th>Actions</th>
                  </tr>
                </thead>
                <tbody id="usersBody">${rows}</tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>`;

    res.send(getShell('Users', body, 'users'));
  } catch (err) {
    res.status(500).send('Error fetching users');
  }
});

// ── QUIZ PAGE ──────────────────────────────────────────────────────────────────
app.get('/quiz', requireAuth, async (req, res) => {
  try {
    const quizzes = await Quiz.find();

    const rows = quizzes.map((q, i) => `
      <tr>
        <td style="color:var(--muted);font-size:12px">${i + 1}</td>
        <td>${q.email}</td>
        <td><span class="pill ${q.BasicQuiz ? 'yes' : 'no'}">${q.BasicQuiz ? 'Yes' : 'No'}</span></td>
        <td>${q.BasicQuizMarks !== null ? `<span class="score-chip">${q.BasicQuizMarks}</span>` : '<span style="color:var(--muted)">—</span>'}</td>
        <td><span class="pill ${q.AdvanceQuiz ? 'yes' : 'no'}">${q.AdvanceQuiz ? 'Yes' : 'No'}</span></td>
        <td>${q.AdvanceQuizMarks !== null ? `<span class="score-chip">${q.AdvanceQuizMarks}</span>` : '<span style="color:var(--muted)">—</span>'}</td>
      </tr>`).join('');

    const body = `
    <div class="layout">
      ${sidebarNav('quiz')}
      <div class="main">
        ${header('Quiz Results', 'Review')}
        <div class="content">
          <div class="page-title fade-up">Quiz Results</div>
          <div class="page-subtitle fade-up delay-1">View all user quiz attempts and scores.</div>
          <div class="card fade-up delay-2">
            <div class="table-toolbar">
              <div class="search-box">
                <i class="fas fa-search"></i>
                <input id="userSearch" type="text" placeholder="Search by email…"/>
              </div>
              <div class="table-count" id="tableCount">${quizzes.length} records</div>
            </div>
            <div class="table-wrap card-body no-pad">
              <table>
                <thead>
                  <tr>
                    <th>#</th><th>Email</th><th>Basic Quiz</th><th>Basic Score</th><th>Advanced Quiz</th><th>Advanced Score</th>
                  </tr>
                </thead>
                <tbody id="usersBody">${rows}</tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>`;

    res.send(getShell('Quiz Results', body, 'quiz'));
  } catch (err) {
    res.status(500).send('Error fetching quiz data');
  }
});

// ── SERVERS PAGE ───────────────────────────────────────────────────────────────
app.get('/servers', requireAuth, (req, res) => {
  const servers = [
    { name: 'Production Server', region: 'US-East', status: 'online', uptime: '99.9%', load: '34%', latency: '18ms' },
    { name: 'Staging Server',    region: 'EU-West', status: 'online', uptime: '98.2%', load: '12%', latency: '42ms' },
    { name: 'Backup Server',     region: 'AP-South', status: 'online', uptime: '97.1%', load: '5%',  latency: '91ms' },
  ];

  const rows = servers.map((s, i) => `
    <tr>
      <td style="color:var(--muted);font-size:12px">${i + 1}</td>
      <td><strong>${s.name}</strong></td>
      <td><span style="color:var(--muted)">${s.region}</span></td>
      <td><span class="pill active"><i class="fas fa-circle" style="font-size:6px"></i>${s.status}</span></td>
      <td>${s.uptime}</td>
      <td>${s.load}</td>
      <td>${s.latency}</td>
    </tr>`).join('');

  const body = `
  <div class="layout">
    ${sidebarNav('servers')}
    <div class="main">
      ${header('Servers', 'Monitor')}
      <div class="content">
        <div class="page-title fade-up">Server Monitor</div>
        <div class="page-subtitle fade-up delay-1">Real-time overview of all Magic Story servers.</div>

        <div class="stats-grid fade-up delay-1">
          <div class="stat-card teal">
            <div class="stat-glow"></div>
            <div class="stat-icon"><i class="fas fa-check-circle"></i></div>
            <div class="stat-value">3/3</div>
            <div class="stat-label">Servers Online</div>
          </div>
          <div class="stat-card purple">
            <div class="stat-glow"></div>
            <div class="stat-icon"><i class="fas fa-tachometer-alt"></i></div>
            <div class="stat-value">18ms</div>
            <div class="stat-label">Best Latency</div>
          </div>
          <div class="stat-card amber">
            <div class="stat-glow"></div>
            <div class="stat-icon"><i class="fas fa-microchip"></i></div>
            <div class="stat-value">34%</div>
            <div class="stat-label">Peak CPU Load</div>
          </div>
        </div>

        <div class="card fade-up delay-2">
          <div class="card-header">
            <div class="card-title"><i class="fas fa-server"></i>All Servers</div>
          </div>
          <div class="table-wrap card-body no-pad">
            <table>
              <thead>
                <tr><th>#</th><th>Name</th><th>Region</th><th>Status</th><th>Uptime</th><th>CPU Load</th><th>Latency</th></tr>
              </thead>
              <tbody>${rows}</tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  </div>`;

  res.send(getShell('Servers', body, 'servers'));
});

// ── DELETE USER ────────────────────────────────────────────────────────────────
app.post('/delete-user/:id', requireAuth, async (req, res) => {
  try {
    await User.findByIdAndDelete(req.params.id);
    res.redirect('/users');
  } catch (err) {
    res.status(500).send('Failed to delete user');
  }
});

// ─── Start ─────────────────────────────────────────────────────────────────────
app.listen(PORT, () => console.log(`🚀 Magic Story Admin running on http://localhost:${PORT}`));