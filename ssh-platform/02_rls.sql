-- ============================================================
-- SSH KPI Platformu — Adım 2: Güvenlik Kuralları (RLS)
-- 01_schema.sql'den SONRA çalıştırın.
-- ============================================================

-- RLS'yi her tabloda aç
ALTER TABLE public.profiles         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.brands           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regions          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provinces        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_centers  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.periods          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kpi_submissions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kpi_scores       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log        ENABLE ROW LEVEL SECURITY;

-- ── Yardımcı fonksiyonlar ─────────────────────────────────────

-- Mevcut kullanıcının rolünü döner
CREATE OR REPLACE FUNCTION public.my_role()
RETURNS TEXT AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Mevcut kullanıcının marka ID'sini döner
CREATE OR REPLACE FUNCTION public.my_brand_id()
RETURNS UUID AS $$
    SELECT brand_id FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Kullanıcı admin mi?
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
    SELECT my_role() IN ('superadmin','admin');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ── PROFILES ─────────────────────────────────────────────────
-- Herkes kendi profilini okur
CREATE POLICY "profiles_self_read" ON public.profiles
    FOR SELECT USING (id = auth.uid());

-- Admin herkesi okur
CREATE POLICY "profiles_admin_read" ON public.profiles
    FOR SELECT USING (is_admin());

-- Herkes kendi profilini günceller
CREATE POLICY "profiles_self_update" ON public.profiles
    FOR UPDATE USING (id = auth.uid());

-- Admin herkesi günceller
CREATE POLICY "profiles_admin_update" ON public.profiles
    FOR UPDATE USING (is_admin());

-- Sadece superadmin yeni profil ekler (trigger halleder normalde)
CREATE POLICY "profiles_superadmin_insert" ON public.profiles
    FOR INSERT WITH CHECK (my_role() = 'superadmin');

-- ── BRANDS ───────────────────────────────────────────────────
-- Herkes aktif markaları görür (filtreler için gerekli)
CREATE POLICY "brands_all_read" ON public.brands
    FOR SELECT USING (TRUE);

-- Sadece admin yazar
CREATE POLICY "brands_admin_write" ON public.brands
    FOR ALL USING (is_admin());

-- ── REGIONS / PROVINCES ──────────────────────────────────────
CREATE POLICY "regions_all_read" ON public.regions
    FOR SELECT USING (TRUE);

CREATE POLICY "provinces_all_read" ON public.provinces
    FOR SELECT USING (TRUE);

-- Admin yazabilir
CREATE POLICY "regions_admin_write" ON public.regions
    FOR ALL USING (is_admin());

CREATE POLICY "provinces_admin_write" ON public.provinces
    FOR ALL USING (is_admin());

-- ── SERVICE CENTERS ──────────────────────────────────────────
-- Herkes tüm aktif servisleri görür
CREATE POLICY "sc_all_read" ON public.service_centers
    FOR SELECT USING (is_active = TRUE);

-- Admin tümünü görür (pasif dahil)
CREATE POLICY "sc_admin_read" ON public.service_centers
    FOR SELECT USING (is_admin());

-- Admin veya kendi markasındaki analyst ekler/günceller
CREATE POLICY "sc_admin_write" ON public.service_centers
    FOR ALL USING (is_admin());

CREATE POLICY "sc_own_brand_write" ON public.service_centers
    FOR INSERT WITH CHECK (
        my_role() IN ('analyst') AND brand_id = my_brand_id()
    );

-- ── PERIODS ──────────────────────────────────────────────────
-- Herkes dönemleri görür
CREATE POLICY "periods_all_read" ON public.periods
    FOR SELECT USING (TRUE);

-- Sadece admin yazar/kilitler
CREATE POLICY "periods_admin_write" ON public.periods
    FOR ALL USING (is_admin());

-- ── KPI SUBMISSIONS ──────────────────────────────────────────
-- Kendi markasının verilerini herkes okur
CREATE POLICY "sub_own_read" ON public.kpi_submissions
    FOR SELECT USING (brand_id = my_brand_id());

-- Admin tümünü okur
CREATE POLICY "sub_admin_read" ON public.kpi_submissions
    FOR SELECT USING (is_admin());

-- Kendi markası için veri girebilir (dönem kilitli değilse)
CREATE POLICY "sub_own_insert" ON public.kpi_submissions
    FOR INSERT WITH CHECK (
        brand_id = my_brand_id()
        AND EXISTS (
            SELECT 1 FROM public.periods p
            WHERE p.id = period_id AND p.is_locked = FALSE
        )
    );

-- Kendi verisini güncelleyebilir (sadece pending iken)
CREATE POLICY "sub_own_update" ON public.kpi_submissions
    FOR UPDATE USING (
        brand_id = my_brand_id()
        AND status = 'pending'
    );

-- Admin her şeyi yazar
CREATE POLICY "sub_admin_write" ON public.kpi_submissions
    FOR ALL USING (is_admin());

-- ── KPI SCORES ───────────────────────────────────────────────
-- Kendi skoru + sektör ortalaması için genel okuma
-- ÖNEMLİ: restricted KPI'lar view layer'da gizlenir
CREATE POLICY "scores_all_read" ON public.kpi_scores
    FOR SELECT USING (is_masked = FALSE);

-- Admin tümünü okur (masked dahil)
CREATE POLICY "scores_admin_read" ON public.kpi_scores
    FOR SELECT USING (is_admin());

-- Sadece sistem (service role) yazar
CREATE POLICY "scores_system_write" ON public.kpi_scores
    FOR ALL USING (is_admin());

-- ── AUDIT LOG ────────────────────────────────────────────────
-- Sadece admin okur
CREATE POLICY "audit_admin_read" ON public.audit_log
    FOR SELECT USING (is_admin());

-- Herkes kendi logunu ekleyebilir (uygulama yazar)
CREATE POLICY "audit_insert" ON public.audit_log
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- ── RESTRICTED KPI VIEW (Rekabet hukuku) ─────────────────────
-- Marka sıralamalarında 3 KPI gizlenir.
-- Bu view'u admin paneli DIŞINDA kullanın.
CREATE OR REPLACE VIEW public.kpi_scores_public AS
SELECT
    s.id, s.brand_id, s.period_id, s.region_id,
    s.vehicle_age_group, s.segment,
    s.idx_work_order_duration,
    s.idx_work_order_volume,
    s.idx_active_customer_base,
    s.idx_labor_hours_per_wo,
    s.idx_service_usage,
    s.idx_periodic_maintenance,
    s.idx_wo_per_service,
    s.idx_customer_per_service,
    -- Restricted KPI'lar: sadece kendi markası görür
    CASE WHEN s.brand_id = my_brand_id() THEN s.idx_customer_retention   ELSE NULL END AS idx_customer_retention,
    CASE WHEN s.brand_id = my_brand_id() THEN s.idx_parts_revenue_per_cust ELSE NULL END AS idx_parts_revenue_per_cust,
    CASE WHEN s.brand_id = my_brand_id() THEN s.idx_warranty_coverage     ELSE NULL END AS idx_warranty_coverage,
    s.score_operational, s.score_customer,
    s.score_service_capacity, s.score_coverage,
    s.score_overall, s.participant_count, s.computed_at
FROM public.kpi_scores s
WHERE s.is_masked = FALSE;
