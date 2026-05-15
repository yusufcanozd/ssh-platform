-- ============================================================
-- SSH KPI Platformu — Adım 3: Başlangıç Verileri
-- 02_rls.sql'den SONRA çalıştırın.
-- ============================================================

-- ── Bölgeler ────────────────────────────────────────────────
INSERT INTO public.regions (name) VALUES
    ('Marmara'), ('Ege'), ('İç Anadolu'),
    ('Akdeniz'), ('Karadeniz'), ('Doğu Anadolu'), ('Güneydoğu Anadolu')
ON CONFLICT (name) DO NOTHING;

-- ── İller ────────────────────────────────────────────────────
INSERT INTO public.provinces (name, region_id)
SELECT p.name, r.id FROM (VALUES
    ('İstanbul',        'Marmara'),
    ('Bursa',           'Marmara'),
    ('Kocaeli',         'Marmara'),
    ('Tekirdağ',        'Marmara'),
    ('Edirne',          'Marmara'),
    ('Sakarya',         'Marmara'),
    ('Balıkesir',       'Marmara'),
    ('İzmir',           'Ege'),
    ('Manisa',          'Ege'),
    ('Aydın',           'Ege'),
    ('Denizli',         'Ege'),
    ('Muğla',           'Ege'),
    ('Uşak',            'Ege'),
    ('Ankara',          'İç Anadolu'),
    ('Konya',           'İç Anadolu'),
    ('Kayseri',         'İç Anadolu'),
    ('Eskişehir',       'İç Anadolu'),
    ('Sivas',           'İç Anadolu'),
    ('Aksaray',         'İç Anadolu'),
    ('Nevşehir',        'İç Anadolu'),
    ('Antalya',         'Akdeniz'),
    ('Mersin',          'Akdeniz'),
    ('Adana',           'Akdeniz'),
    ('Hatay',           'Akdeniz'),
    ('Isparta',         'Akdeniz'),
    ('Burdur',          'Akdeniz'),
    ('Trabzon',         'Karadeniz'),
    ('Samsun',          'Karadeniz'),
    ('Zonguldak',       'Karadeniz'),
    ('Giresun',         'Karadeniz'),
    ('Rize',            'Karadeniz'),
    ('Ordu',            'Karadeniz'),
    ('Erzurum',         'Doğu Anadolu'),
    ('Malatya',         'Doğu Anadolu'),
    ('Van',             'Doğu Anadolu'),
    ('Elazığ',          'Doğu Anadolu'),
    ('Kars',            'Doğu Anadolu'),
    ('Ağrı',            'Doğu Anadolu'),
    ('Gaziantep',       'Güneydoğu Anadolu'),
    ('Şanlıurfa',       'Güneydoğu Anadolu'),
    ('Diyarbakır',      'Güneydoğu Anadolu'),
    ('Mardin',          'Güneydoğu Anadolu'),
    ('Adıyaman',        'Güneydoğu Anadolu'),
    ('Batman',          'Güneydoğu Anadolu')
) AS p(name, region_name)
JOIN public.regions r ON r.name = p.region_name
ON CONFLICT (name) DO NOTHING;

-- ── Markalar (55 marka) ───────────────────────────────────────
INSERT INTO public.brands (code, name, segment) VALUES
    ('ALFA_ROMEO',   'Alfa Romeo',    'Premium'),
    ('ALPINE',       'Alpine',        'Premium'),
    ('ASTON_MARTIN', 'Aston Martin',  'Premium'),
    ('AUDI',         'Audi',          'Premium'),
    ('BENTLEY',      'Bentley',       'Premium'),
    ('BMW',          'BMW',           'Premium'),
    ('DS',           'DS',            'Premium'),
    ('FERRARI',      'Ferrari',       'Premium'),
    ('HONGQI',       'Hongqi',        'Premium'),
    ('JAGUAR',       'Jaguar',        'Premium'),
    ('LAMBORGHINI',  'Lamborghini',   'Premium'),
    ('LAND_ROVER',   'Land Rover',    'Premium'),
    ('LEXUS',        'Lexus',         'Premium'),
    ('MASERATI',     'Maserati',      'Premium'),
    ('MERCEDES',     'Mercedes-Benz', 'Premium'),
    ('MINI',         'MINI',          'Premium'),
    ('PORSCHE',      'Porsche',       'Premium'),
    ('VOLVO',        'Volvo',         'Premium'),
    ('BYD',          'BYD',           'EV'),
    ('LEAPMOTOR',    'Leapmotor',     'EV'),
    ('SKYWELL',      'Skywell',       'EV'),
    ('SMART',        'Smart',         'EV'),
    ('TESLA',        'Tesla',         'EV'),
    ('TOGG',         'TOGG',          'EV'),
    ('CHERY',        'Chery',         'Mass'),
    ('CITROEN',      'Citroën',       'Mass'),
    ('CUPRA',        'Cupra',         'Mass'),
    ('DACIA',        'Dacia',         'Mass'),
    ('DFSK',         'DFSK',          'Mass'),
    ('FARIZON',      'Farizon',       'Mass'),
    ('FIAT',         'Fiat',          'Mass'),
    ('FORD',         'Ford',          'Mass'),
    ('FOTON',        'Foton',         'Mass'),
    ('HONDA',        'Honda',         'Mass'),
    ('HYUNDAI',      'Hyundai',       'Mass'),
    ('ISUZU',        'Isuzu',         'Mass'),
    ('IVECO',        'Iveco',         'Mass'),
    ('JAECOO',       'Jaecoo',        'Mass'),
    ('JEEP',         'Jeep',          'Mass'),
    ('KARSAN',       'Karsan',        'Mass'),
    ('KG_MOBILITY',  'KG Mobility',   'Mass'),
    ('KIA',          'Kia',           'Mass'),
    ('MAXUS',        'Maxus',         'Mass'),
    ('MG',           'MG',            'Mass'),
    ('NISSAN',       'Nissan',        'Mass'),
    ('OPEL',         'Opel',          'Mass'),
    ('PEUGEOT',      'Peugeot',       'Mass'),
    ('RENAULT',      'Renault',       'Mass'),
    ('SEAT',         'SEAT',          'Mass'),
    ('SKODA',        'Škoda',         'Mass'),
    ('SUBARU',       'Subaru',        'Mass'),
    ('SUZUKI',       'Suzuki',        'Mass'),
    ('TENAX',        'Tenax',         'Mass'),
    ('TOYOTA',       'Toyota',        'Mass'),
    ('VOLKSWAGEN',   'Volkswagen',    'Mass')
ON CONFLICT (code) DO NOTHING;

-- ── Dönemler (2022–2024, 12 çeyrek) ──────────────────────────
INSERT INTO public.periods (year, quarter, start_date, end_date, is_locked) VALUES
    (2022,'Q1','2022-01-01','2022-03-31', TRUE),
    (2022,'Q2','2022-04-01','2022-06-30', TRUE),
    (2022,'Q3','2022-07-01','2022-09-30', TRUE),
    (2022,'Q4','2022-10-01','2022-12-31', TRUE),
    (2023,'Q1','2023-01-01','2023-03-31', TRUE),
    (2023,'Q2','2023-04-01','2023-06-30', TRUE),
    (2023,'Q3','2023-07-01','2023-09-30', TRUE),
    (2023,'Q4','2023-10-01','2023-12-31', TRUE),
    (2024,'Q1','2024-01-01','2024-03-31', TRUE),
    (2024,'Q2','2024-04-01','2024-06-30', TRUE),
    (2024,'Q3','2024-07-01','2024-09-30', TRUE),
    (2024,'Q4','2024-10-01','2024-12-31', FALSE)
ON CONFLICT (year, quarter) DO NOTHING;

-- ── İlk Superadmin ───────────────────────────────────────────
-- NOT: Bu profili Supabase Auth'da kullanıcı oluşturduktan
-- sonra o kullanıcının UUID'si ile güncelleyin.
-- Supabase Auth > Users > New User > admin@sshplatform.com / Admin1234!
-- Sonra aşağıdaki satırı o UUID ile çalıştırın:
--
-- UPDATE public.profiles
-- SET role = 'superadmin', full_name = 'Platform Admin'
-- WHERE id = '<BURAYA_UUID_GIRIN>';
