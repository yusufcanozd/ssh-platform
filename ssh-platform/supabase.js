const SUPABASE_URL  = 'https://dqocqewqqzbzczukqnzi.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxb2NxZXdxcXpiemN6dWtxbnppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg4NDIyOTMsImV4cCI6MjA5NDQxODI5M30.0xC4aeScYrOmWlBHzKvwx2D2He1h-31JDHY2K_v9uYw';

const { createClient } = supabase;
const sb = createClient(SUPABASE_URL, SUPABASE_ANON);

const KPI_CONFIG = [
    { key:'idx_work_order_duration',    name:'İş Emri Süresi',        cat:'operational', weight:0.105, compliance:null },
    { key:'idx_work_order_volume',      name:'İş Emri Hacim',          cat:'operational', weight:0.105, compliance:null },
    { key:'idx_active_customer_base',   name:'Aktif Müşteri Bazı',     cat:'operational', weight:0.140, compliance:null },
    { key:'idx_labor_hours_per_wo',     name:'İşçilik Saati/İE',       cat:'customer',    weight:0.105, compliance:null },
    { key:'idx_customer_retention',     name:'Müşteri Tutundurma',     cat:'customer',    weight:0.105, compliance:'no_ranking' },
    { key:'idx_service_usage',          name:'Servis Kullanım',        cat:'customer',    weight:0.090, compliance:null },
    { key:'idx_periodic_maintenance',   name:'Periyodik Bakım',        cat:'service',     weight:0.080, compliance:null },
    { key:'idx_wo_per_service',         name:'Servis Başına İE',       cat:'service',     weight:0.070, compliance:null },
    { key:'idx_customer_per_service',   name:'Servis Başına Müşteri',  cat:'service',     weight:0.050, compliance:null },
    { key:'idx_parts_revenue_per_cust', name:'Müşteri Başına Parça',   cat:'coverage',    weight:0.075, compliance:'no_ranking' },
    { key:'idx_warranty_coverage',      name:'Garanti Kapsam',         cat:'coverage',    weight:0.075, compliance:'no_ranking' },
];

const CAT_WEIGHTS = { operational:0.35, customer:0.30, service:0.20, coverage:0.15 };

function scoreColor(v) {
    if (v >= 80) return '#10b981';
    if (v >= 70) return '#3b82f6';
    if (v >= 60) return '#f59e0b';
    return '#ef4444';
}

function scoreBg(v) {
    if (v >= 80) return 'rgba(16,185,129,.15)';
    if (v >= 70) return 'rgba(59,130,246,.12)';
    if (v >= 60) return 'rgba(245,158,11,.15)';
    return 'rgba(239,68,68,.12)';
}

function fmt(v, dec = 1) {
    if (v === null || v === undefined) return '—';
    return Number(v).toFixed(dec);
}