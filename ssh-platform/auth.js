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
