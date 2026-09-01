# Görev 1.2b — Abandoned Transaction Kayıtlarına `source` ve Gerçek Tutar Ekleme
*(Antigravity'ye doğrudan yapıştırılacak görev metni)*

## Bağlam

Görev 1.2'de "abandoned" (Bekleme Odası'ndan vazgeçilen) harcamalar `transactions`'a
`raw_amount=0` ile yazılıyor. Bu iki sorun yaratıyor:
1. Self-tax satırlarında her zaman geçerli olan `total_diverted = self_tax_amount +
   roundup_amount` invariant'ı, abandoned satırlarında sessizce bozuluyor.
2. Vazgeçilen harcamanın gerçek tutarı hiçbir yerde saklanmıyor — Faz 2'deki
   motivasyon/rozet özellikleri için değerli bir veri kayboluyor.

## Görev

1. `transactions` tablosuna `source` kolonu ekle: `TEXT NOT NULL DEFAULT 'self_tax'`,
   CHECK constraint ile sadece `'self_tax'` veya `'abandoned_purchase'` kabul etsin.
2. Bunun için **yeni bir Alembic revizyonu** oluştur — mevcut migration'ı değiştirme,
   üstüne ekle (geriye dönük uyumluluk).
3. `backend/schema.sql`'i de güncelle (referans doküman tutarlı kalsın).
4. Abandoned akışını yazan iki kod yolunu (hem `POST /pending-purchases/{id}/resolve`'daki
   abandoned dalı hem `background_jobs.py`'daki `process_expired_pending_purchases`)
   **tek bir paylaşılan fonksiyona** taşı — örn. `app/services/pending_purchases.py` içinde
   `write_abandoned_transaction(db, pending_purchase) -> Transaction`:
   - `raw_amount = pending_purchase.amount` (0 değil — gerçek vazgeçilen tutar)
   - `self_tax_amount = 0`, `roundup_amount = 0`
   - `total_diverted = pending_purchase.amount`
   - `source = 'abandoned_purchase'`
5. Normal self-tax akışının yazdığı satırlara `source='self_tax'` set et.
6. Mevcut testleri güncelle: `test_resolve_abandoned` ve `test_background_job`'daki
   `assert tx.raw_amount == 0` satırlarını gerçek tutara çevir (350.00 / 500.00),
   `assert tx.source == "abandoned_purchase"` ekle.

## Kısıtlar

- Mevcut Alembic revizyonunu değiştirme, yeni revizyon ekle.
- `rule_engine.py`'ye dokunma — değişiklik tamamen servis/router katmanında.
- İki ayrı yerde aynı yazma mantığını kopyalama; paylaşılan fonksiyon şart.

## Referans Dosyalar

- `backend/schema.sql`
- `backend/app/routers/pending_purchases.py`
- `backend/app/background_jobs.py`
- `tests/test_rule_engine_integration.py`

## Kabul Kriterleri

- [ ] Yeni Alembic revizyonu `alembic upgrade head` ile sorunsuz uygulanıyor
- [ ] `source` kolonu CHECK constraint ile kısıtlı
- [ ] Abandoned satırlarında `raw_amount` gerçek tutarı gösteriyor, `total_diverted == raw_amount`
- [ ] Resolve endpoint'i ve background job aynı paylaşılan fonksiyonu çağırıyor (kod tekrarı yok)
- [ ] Güncellenmiş testler (raw_amount ve source kontrolleri dahil) yeşil
- [ ] Var olan self-tax satırlarında `source='self_tax'` doğrulanmış

## Beklenen Walkthrough

- Migration diff'i
- Güncellenen test dosyasının ilgili kısımları + pytest çıktısı
- Bir abandoned satırının tam içeriğini gösteren psql çıktısı (`raw_amount`, `source` dahil)
