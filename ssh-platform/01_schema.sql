-- ============================================================
-- SSH KPI Platformu — Adım 1: Tablo Yapısı
-- Supabase SQL Editor'a yapıştırın, "Run" tuşuna basın.
--
-- DÜZELTME: Tablo sırası referans bağımlılıklarına göre
-- yeniden düzenlendi.
-- ============================================================

-- ── 1. Markalar (profiles'dan önce gelmeli) ──────────────────
CREATE TABLE IF NOT EXISTS public.brands (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code        TEXT NOT NULL UNIQUE,
    name        TEXT NOT NULL,
    segment     TEXT NOT NULL CHECK (segment IN ('Premium','Mass','EV')),
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 2. Kullanıcı Profilleri (brands'a referans verir) ─────────
CREATE TABLE IF NOT EXISTS public.profiles (
    id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name   TEXT NOT NULL DEFAULT '',
    role        TEXT NOT NULL DEFAULT 'viewer'
                CHECK (role IN ('superadmin','admin','analyst','viewer')),
    brand_id    UUID REFERENCES public.brands(id) ON DELETE SET NULL,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 3. TR Bölgeleri ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.regions (
    id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE
);

-- ── 4. İller (regions'a referans verir) ──────────────────────
CREATE TABLE IF NOT EXISTS public.provinces (
    id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name      TEXT NOT NULL UNIQUE,
    region_id UUID NOT NULL REFERENCES public.regions(id) ON DELETE RESTRICT
);

-- ── 5. Servis Noktaları ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.service_centers (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand_id    UUID NOT NULL REFERENCES public.brands(id) ON DELETE CASCADE,
    province_id UUID NOT NULL REFERENCES public.provinces(id) ON DELETE RESTRICT,
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    address     TEXT,
    phone       TEXT,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (brand_id, code)
);

-- ── 6. Dönemler ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.periods (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    year        INTEGER NOT NULL,
    quarter     TEXT NOT NULL CHECK (quarter IN ('Q1','Q2','Q3','Q4')),
    start_date  DATE NOT NULL,
    end_date    DATE NOT NULL,
    is_locked   BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (year, quarter)
);

-- ── 7. Ham KPI Gönderileri ────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.kpi_submissions (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand_id                UUID NOT NULL REFERENCES public.brands(id) ON DELETE CASCADE,
    service_center_id       UUID REFERENCES public.service_centers(id) ON DELETE SET NULL,
    period_id               UUID NOT NULL REFERENCES public.periods(id) ON DELETE RESTRICT,
    vehicle_age_group       TEXT NOT NULL CHECK (vehicle_age_group IN ('0-3','3-7','7+')),
    work_order_duration     NUMERIC,
    work_order_volume       NUMERIC,
    active_customer_base    NUMERIC,
    labor_hours_per_wo      NUMERIC,
    customer_retention      NUMERIC,
    service_usage           NUMERIC,
    periodic_maintenance    NUMERIC,
    wo_per_service          NUMERIC,
    customer_per_service    NUMERIC,
    parts_revenue_per_cust  NUMERIC,
    warranty_coverage       NUMERIC,
    status          TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending','approved','rejected')),
    submitted_by    UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    approved_by     UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    submitted_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    approved_at     TIMESTAMPTZ,
    notes           TEXT,
    UNIQUE (brand_id, service_center_id, period_id, vehicle_age_group)
);

-- ── 8. Hesaplanmış KPI Skorları ───────────────────────────────
CREATE TABLE IF NOT EXISTS public.kpi_scores (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand_id                    UUID NOT NULL REFERENCES public.brands(id) ON DELETE CASCADE,
    period_id                   UUID NOT NULL REFERENCES public.periods(id) ON DELETE RESTRICT,
    region_id                   UUID REFERENCES public.regions(id) ON DELETE SET NULL,
    vehicle_age_group           TEXT NOT NULL DEFAULT 'ALL',
    segment                     TEXT NOT NULL DEFAULT 'ALL',
    idx_work_order_duration     NUMERIC,
    idx_work_order_volume       NUMERIC,
    idx_active_customer_base    NUMERIC,
    idx_labor_hours_per_wo      NUMERIC,
    idx_customer_retention      NUMERIC,
    idx_service_usage           NUMERIC,
    idx_periodic_maintenance    NUMERIC,
    idx_wo_per_service          NUMERIC,
    idx_customer_per_service    NUMERIC,
    idx_parts_revenue_per_cust  NUMERIC,
    idx_warranty_coverage       NUMERIC,
    score_operational           NUMERIC,
    score_customer              NUMERIC,
    score_service_capacity      NUMERIC,
    score_coverage              NUMERIC,
    score_overall               NUMERIC,
    participant_count           INTEGER,
    is_masked                   BOOLEAN NOT NULL DEFAULT FALSE,
    computed_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (brand_id, period_id, region_id, vehicle_age_group, segment)
);

-- ── 9. Sistem Logları ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.audit_log (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action      TEXT NOT NULL,
    entity      TEXT,
    entity_id   UUID,
    details     JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── İndeksler ─────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_profiles_brand ON public.profiles(brand_id);
CREATE INDEX IF NOT EXISTS idx_sc_brand       ON public.service_centers(brand_id);
CREATE INDEX IF NOT EXISTS idx_sc_province    ON public.service_centers(province_id);
CREATE INDEX IF NOT EXISTS idx_sub_brand      ON public.kpi_submissions(brand_id);
CREATE INDEX IF NOT EXISTS idx_sub_period     ON public.kpi_submissions(period_id);
CREATE INDEX IF NOT EXISTS idx_sub_status     ON public.kpi_submissions(status);
CREATE INDEX IF NOT EXISTS idx_scores_brand   ON public.kpi_scores(brand_id);
CREATE INDEX IF NOT EXISTS idx_scores_period  ON public.kpi_scores(period_id);
CREATE INDEX IF NOT EXISTS idx_audit_user     ON public.audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_time     ON public.audit_log(created_at);

-- ── Trigger: Yeni kullanıcı → profiles satırı ────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email,'@',1)),
        COALESCE(NEW.raw_user_meta_data->>'role', 'viewer')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ── Trigger: updated_at otomatik güncelle ─────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS profiles_updated_at ON public.profiles;
CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
