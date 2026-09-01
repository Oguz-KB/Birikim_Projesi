-- ============================================================
-- Birikim Uygulaması — Veritabanı Şeması (PostgreSQL)
-- Tasarım ilkesi: TRANSACTIONS tablosu immutable bir defterdir.
-- Bakiyeler ve hedef ilerlemesi bu deftere göre hesaplanır,
-- doğrudan bir "balance" kolonu UPDATE edilmez. Böylece:
--   - kullanıcı vergi oranını değiştirse geçmiş bozulmaz
--   - iptal/düzeltme = ters kayıt (reversal), silme değil
--   - denetim (audit) ve "neden bu tutar birikti" sorusu her
--     zaman cevaplanabilir
-- ============================================================

CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           TEXT UNIQUE NOT NULL,
    display_name    TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Kullanıcının kural motoru ayarları (Öz-Vergi oranı, yuvarlama vb.)
-- Ayrı tabloda tutuluyor ki geçmişi de saklanabilsin (bkz. valid_from/to).
CREATE TABLE user_rule_settings (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL REFERENCES users(id),
    self_tax_rate           NUMERIC(5,4) NOT NULL DEFAULT 0.10,   -- %10
    roundup_enabled         BOOLEAN NOT NULL DEFAULT true,
    roundup_unit            NUMERIC(10,2) NOT NULL DEFAULT 10.00, -- en yakın 10'a tamamla
    waiting_room_hours      INTEGER NOT NULL DEFAULT 24,
    waiting_room_threshold  NUMERIC(12,2) NOT NULL DEFAULT 200.00, -- bu tutarın üstü "dürtüsel" sayılır
    valid_from              TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_to                TIMESTAMPTZ            -- NULL = hâlâ geçerli
);

CREATE TABLE categories (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                    TEXT NOT NULL,
    is_guilty_pleasure      BOOLEAN NOT NULL DEFAULT false,
    penalty_multiplier      NUMERIC(4,2) NOT NULL DEFAULT 1.00   -- 3.00 = "Zaaf Çarpanı" 3x
);

CREATE TABLE goals (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id   UUID NOT NULL REFERENCES users(id),
    name            TEXT NOT NULL,
    target_amount   NUMERIC(12,2) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- ANA DEFTER: her satır, gerçekleşmiş ve değiştirilemez bir olaydır.
-- ============================================================
CREATE TABLE transactions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id),
    category_id         UUID NOT NULL REFERENCES categories(id),
    raw_amount          NUMERIC(12,2) NOT NULL,   -- gerçek harcama tutarı
    self_tax_amount     NUMERIC(12,2) NOT NULL,   -- Kendine vergi kesintisi
    roundup_amount      NUMERIC(12,2) NOT NULL DEFAULT 0, -- Yuvarlama kesintisi
    total_diverted      NUMERIC(12,2) NOT NULL,   -- self_tax_amount + roundup_amount
    source              TEXT NOT NULL DEFAULT 'self_tax' CHECK (source IN ('self_tax', 'abandoned_purchase')), -- İşlemin kaynağı
    rule_settings_id    UUID NOT NULL REFERENCES user_rule_settings(id), -- Hangi kuralla hesaplandı
    goal_id             UUID REFERENCES goals(id), -- Eğer belirli bir hedefe aktarıldıysa
    reversal_of         UUID REFERENCES transactions(id), -- İade işlemiyse, orijinal işlemin ID'sini gösterir
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Ortak Hedefler (Co-op): bir hedefe birden çok kullanıcı katkı verebilir.
CREATE TABLE goal_members (
    goal_id     UUID NOT NULL REFERENCES goals(id),
    user_id     UUID NOT NULL REFERENCES users(id),
    joined_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (goal_id, user_id)
);

-- Bekleme Odası (24 Saat Kuralı): dürtüsel harcama adayları burada bekler.
CREATE TABLE pending_purchases (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    category_id     UUID NOT NULL REFERENCES categories(id),
    amount          NUMERIC(12,2) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at      TIMESTAMPTZ NOT NULL,
    resolution       TEXT CHECK (resolution IN ('purchased', 'abandoned', 'pending')) DEFAULT 'pending',
    resolved_at     TIMESTAMPTZ,
    -- vazgeçilirse bu tutar doğrudan birikime eklenir; hangi transactions
    -- kaydına dönüştüğünü izlemek için:
    resulting_transaction_id UUID REFERENCES transactions(id)
);

-- Hızlı okunan görünüm: kullanıcı başına toplam birikim
CREATE VIEW user_savings_totals AS
SELECT
    user_id,
    SUM(total_diverted) AS total_saved
FROM transactions
GROUP BY user_id;

-- Hedef ilerlemesi (goal_id NULL olanlar genel birikime sayılır, hedefe bağlı değildir)
CREATE VIEW goal_progress AS
SELECT
    goal_id,
    SUM(total_diverted) AS current_amount
FROM transactions
WHERE goal_id IS NOT NULL
GROUP BY goal_id;

CREATE INDEX idx_transactions_user_created ON transactions (user_id, created_at DESC);
CREATE INDEX idx_pending_purchases_expiry ON pending_purchases (expires_at) WHERE resolution = 'pending';
