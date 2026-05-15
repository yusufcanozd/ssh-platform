# SSH KPI Platformu — Kurulum Rehberi

Yazılım bilgisi gerektirmez. Her adımı sırayla takip edin.

---

## Adım 1 — Supabase Hesabı Açın (5 dakika)

1. [supabase.com](https://supabase.com) adresine gidin
2. **"Start your project"** butonuna tıklayın
3. GitHub hesabınızla giriş yapın (GitHub yoksa e-posta ile de olur)
4. **"New project"** tıklayın:
   - **Organization:** kişisel hesabınız
   - **Name:** `ssh-kpi-platform`
   - **Database Password:** güçlü bir şifre yazın (not edin!)
   - **Region:** `Central EU (Frankfurt)` seçin (Türkiye'ye en yakın)
5. **"Create new project"** tıklayın → ~2 dakika bekleyin

---

## Adım 2 — Veritabanını Kurun (10 dakika)

Supabase dashboard'unda sol menüden **SQL Editor**'e girin.

### 2a. Tabloları oluşturun
- Sol üstte **"New query"** tıklayın
- `db/01_schema.sql` dosyasının tüm içeriğini yapıştırın
- **"Run"** butonuna basın (yeşil ok)
- Alt kısımda "Success" yazısı görmelisiniz

### 2b. Güvenlik kurallarını ekleyin
- Tekrar **"New query"** tıklayın
- `db/02_rls.sql` dosyasının tüm içeriğini yapıştırın
- **"Run"** butonuna basın

### 2c. Başlangıç verilerini ekleyin
- Tekrar **"New query"** tıklayın
- `db/03_seed.sql` dosyasının tüm içeriğini yapıştırın
- **"Run"** butonuna basın
- 55 marka, 7 bölge, 44 il ve 12 dönem eklenmiş olacak

---

## Adım 3 — İlk Admin Kullanıcısını Oluşturun

1. Sol menüden **Authentication** → **Users** gidin
2. **"Add user"** → **"Create new user"** tıklayın:
   - Email: `admin@sshplatform.com`
   - Password: `Admin1234!` (sonra değiştirin)
   - ✅ **"Auto Confirm User"** seçili olsun
3. **"Create user"** tıklayın
4. Oluşan kullanıcının yanındaki **UUID**'yi kopyalayın
   (örnek: `123e4567-e89b-12d3-a456-426614174000`)

5. SQL Editor'e gidin, yeni query açın, şunu yapıştırın
   (UUID'yi kendinizinkiyle değiştirin):

```sql
UPDATE public.profiles
SET role = 'superadmin', full_name = 'Platform Admin'
WHERE id = 'BURAYA_UUID_GIRIN';
```

6. **"Run"** tıklayın

---

## Adım 4 — Supabase Bağlantı Bilgilerini Alın

1. Sol menüden **Settings** → **API** gidin
2. Şunları not edin:
   - **Project URL** → `https://xxxxx.supabase.co`
   - **anon public key** → uzun bir kod

---

## Adım 5 — supabase.js Dosyasını Güncelleyin

`frontend/supabase.js` dosyasını bir metin editörüyle açın.
(Windows'ta Notepad, Mac'te TextEdit)

Şu iki satırı bulun:
```javascript
const SUPABASE_URL  = 'https://PROJE_KODUNUZ.supabase.co';
const SUPABASE_ANON = 'BURAYA_ANON_KEY_GIRIN';
```

Kendi bilgilerinizle değiştirin:
```javascript
const SUPABASE_URL  = 'https://abcdefghijklm.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

Kaydedin.

---

## Adım 6 — Vercel'e Yükleyin (5 dakika)

### Seçenek A: Sürükle-Bırak (En Kolay)

1. [vercel.com](https://vercel.com) adresine gidin
2. GitHub ile giriş yapın
3. Dashboard'da **"Add New"** → **"Project"** tıklayın
4. **"Browse"** tıklayın, `ssh-platform` klasörünü seçin
   (veya klasörü Vercel sayfasına sürükleyin)
5. **Framework Preset:** `Other` seçin
6. **Root Directory:** `frontend` yazın
7. **"Deploy"** tıklayın

~1 dakika sonra siteniz yayında! Size bir adres verir:
`https://ssh-kpi-platform.vercel.app`

### Seçenek B: GitHub Üzerinden (Otomatik Güncelleme)

1. [github.com](https://github.com) adresinde yeni bir repo açın
2. `ssh-platform` klasörünün tüm içeriğini yükleyin
3. Vercel'e gidin → **"Import Git Repository"**
4. GitHub reponuzu seçin → Deploy
5. Artık her GitHub'a yüklemenizde otomatik güncellenir

---

## Adım 7 — Supabase Auth'da E-posta Ayarı

Yeni kullanıcı davet edebilmek için:

1. Supabase → **Authentication** → **Settings**
2. **Email** bölümünde **"Confirm email"** KAPATIN
   (platform erişimi kontrollü olduğu için onay gerektirmesin)
3. **"Save"** tıklayın

---

## Kullanım

### Giriş
- Siteye gidin → `login.html` otomatik açılır
- `admin@sshplatform.com` / `Admin1234!` ile giriş yapın
- Admin olduğunuz için doğrudan admin paneline yönlendirilirsiniz

### Yeni Kullanıcı Ekleme
1. Supabase → Authentication → Users → Add user
2. E-posta ve şifre girin
3. SQL Editor'da rolü ve markayı atayın:

```sql
UPDATE public.profiles
SET role = 'analyst',
    brand_id = (SELECT id FROM brands WHERE code = 'TOYOTA'),
    full_name = 'Ahmet Yılmaz'
WHERE id = 'KULLANICI_UUID';
```

### KPI Veri Girişi
1. Admin paneli → **KPI Veri Girişi** bölümü
2. Markayı, dönemi ve araç yaş grubunu seçin
3. 11 KPI değerini girin → **Gönder**
4. **Gönderiler** bölümünden onaylayın

---

## Sık Sorulan Sorular

**S: Veriler nerede saklanıyor?**
Supabase'in Frankfurt sunucularında. Türkiye'den hızlı erişilir.

**S: Ücretsiz mi?**
Supabase'in ücretsiz planı bu proje için yeterli (500MB veritabanı, 50.000 kullanıcı).
Vercel de ücretsiz plan sunar.

**S: Eski HTML dashboard ne olacak?**
`SSH_KPI_Dashboard.html` dosyası hâlâ çalışır. Yeni sistem veriler girdikçe
onları Supabase'den çeker ve gösterir.

**S: Şifremi unuttum?**
Supabase → Authentication → Users → ilgili kullanıcı → "Reset Password"

---

## Destek

Bir sorunla karşılaşırsanız:
1. Tarayıcıda F12 → Console sekmesine bakın (kırmızı hata mesajı var mı?)
2. Supabase Dashboard → Logs bölümünü inceleyin
