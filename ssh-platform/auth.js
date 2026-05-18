// ============================================================
// auth.js — Giriş Kontrolü ve Rol Yönetimi
// Her sayfanın <head> bölümüne supabase.js'den SONRA ekleyin.
// ============================================================

// Mevcut kullanıcı ve profilini bellekte tut
let currentUser   = null;
let currentProfile = null;

// ── Sayfa koruma fonksiyonları ────────────────────────────────

// Giriş zorunlu — giriş yapılmamışsa login'e at
async function requireAuth() {
    const { data: { session } } = await sb.auth.getSession();
    if (!session) {
        window.location.href = '/login.html';
        return null;
    }
    currentUser = session.user;
    currentProfile = await fetchProfile();
    return currentProfile;
}

// Admin zorunlu — admin değilse dashboard'a at
async function requireAdmin() {
    const profile = await requireAuth();
    if (!profile) return null;
    if (!['superadmin','admin'].includes(profile.role)) {
        window.location.href = '/dashboard.html';
        return null;
    }
    return profile;
}

// Giriş yapılmışsa dashboard/admin'e yönlendir (login sayfası için)
async function redirectIfLoggedIn() {
    const { data: { session } } = await sb.auth.getSession();
    if (!session) return;
    const profile = await fetchProfile(session.user.id);
    if (!profile) return;
    if (['superadmin','admin'].includes(profile.role)) {
        window.location.href = '/admin.html';
    } else {
        window.location.href = '/dashboard.html';
    }
}

// ── Profil ───────────────────────────────────────────────────

async function fetchProfile(userId = null) {
    const id = userId || currentUser?.id;
    if (!id) return null;
    const { data, error } = await sb
        .from('profiles')
        .select('*, brands(id, code, name, segment)')
        .eq('id', id)
        .single();
    if (error) {
        console.error('Profil alınamadı:', error.message);
        return null;
    }
    currentProfile = data;
    return data;
}

// ── Oturum Kapatma ───────────────────────────────────────────

async function logout() {
    await sb.auth.signOut();
    window.location.href = '/login.html';
}

// ── UI Yardımcıları ──────────────────────────────────────────

// Kullanıcı adını ve rolünü topbar'a yaz
function renderTopbarUser(profile) {
    const el = document.getElementById('topbar-user');
    if (!el || !profile) return;
    const roleLabel = {
        superadmin: 'Süper Admin',
        admin:      'Admin',
        analyst:    'Analist',
        viewer:     'İzleyici',
    }[profile.role] || profile.role;

    el.innerHTML = `
        <div class="user-info">
            <span class="user-name">${profile.full_name}</span>
            <span class="user-role role-${profile.role}">${roleLabel}</span>
            ${profile.brands ? `<span class="user-brand">${profile.brands.name}</span>` : ''}
        </div>
        <button class="btn-ghost" onclick="logout()">Çıkış</button>
    `;
}

// Toast bildirimi göster
function toast(msg, type = 'info') {
    const colors = {
        success: '#10b981', error: '#ef4444', info: '#3b82f6', warn: '#f59e0b'
    };
    const t = document.createElement('div');
    t.style.cssText = `
        position:fixed;bottom:24px;right:24px;z-index:9999;
        background:${colors[type]};color:#fff;
        padding:12px 20px;border-radius:10px;font-size:13px;font-weight:500;
        box-shadow:0 4px 20px rgba(0,0,0,.25);
        animation:slideUp .2s ease;max-width:320px;line-height:1.4;
    `;
    t.textContent = msg;
    document.body.appendChild(t);
    setTimeout(() => t.remove(), 3500);
}

// Yükleniyor göster/gizle
function setLoading(selector, loading, text = 'Kaydediliyor...') {
    const el = document.querySelector(selector);
    if (!el) return;
    el.disabled = loading;
    el.textContent = loading ? text : el.dataset.originalText || 'Kaydet';
    if (!el.dataset.originalText && !loading) el.dataset.originalText = text;
}

// Modal aç/kapat
function openModal(id) {
    const m = document.getElementById(id);
    if (m) { m.style.display = 'flex'; m.classList.add('active'); }
}
function closeModal(id) {
    const m = document.getElementById(id);
    if (m) { m.style.display = 'none'; m.classList.remove('active'); }
}

// Tablo satırı seçili → düzenleme için ID sakla
let editingId = null;
function setEditing(id) { editingId = id; }
function getEditing() { return editingId; }
function clearEditing() { editingId = null; }

// ── Tema Yönetimi ─────────────────────────────────────────────

function initTheme() {
    const saved = localStorage.getItem('ssh-theme') || 'dark';
    applyTheme(saved);
}

function applyTheme(theme) {
    if (theme === 'light') {
        document.body.classList.add('light');
    } else {
        document.body.classList.remove('light');
    }
    localStorage.setItem('ssh-theme', theme);
    // Tüm tema butonlarını güncelle
    document.querySelectorAll('.theme-btn').forEach(btn => {
        btn.innerHTML = theme === 'light' ? iconMoon() : iconSun();
        btn.title = theme === 'light' ? 'Koyu temaya geç' : 'Açık temaya geç';
    });
}

function toggleTheme() {
    const current = localStorage.getItem('ssh-theme') || 'dark';
    applyTheme(current === 'dark' ? 'light' : 'dark');
}

function iconSun() {
    return `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <circle cx="12" cy="12" r="5"/>
        <line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/>
        <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/>
        <line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/>
        <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>
    </svg>`;
}

function iconMoon() {
    return `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
    </svg>`;
}

// Geri Navigasyon
function goBack() {
    if (window.history.length > 1) {
        window.history.back();
    } else {
        window.location.href = '/dashboard.html';
    }
}

// Sayfa yüklenince temayı uygula
document.addEventListener('DOMContentLoaded', initTheme);
