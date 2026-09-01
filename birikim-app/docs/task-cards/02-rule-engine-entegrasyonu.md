# Görev 1.2 — rule_engine.py'yi Gerçek Endpoint'lere Bağlama
*(Antigravity'ye doğrudan yapıştırılacak görev metni)*

## Bağlam

Görev 1.1'de API sözleşmesi ve backend iskeleti kuruldu; tüm router'lar `501 Not Implemented`
dönüyor, gerçek Postgres'e karşı doğrulanmış migration'lar var. Bu görevde `app/rule_engine.py`
içindeki saf fonksiyonları (`apply_rules`, `should_enter_waiting_room`,
`resolve_abandoned_purchase`) gerçek endpoint'lere bağlıyoruz. `rule_engine.py`'nin **içeriğine
dokunmuyoruz** — sadece bir servis katmanından çağırıyoruz.

## Görev

1. **`POST /transactions/`'ı doldur:**
   - Kullanıcının güncel `user_rule_settings` kaydını çek (`valid_to IS NULL` olan).
   - Kategori bilgisini (`is_guilty_pleasure`, `penalty_multiplier`) çek.
   - `should_enter_waiting_room(raw_amount, settings)` kontrolü yap:
     - **True ise:** `transactions`'a yazma — bunun yerine `pending_purchases`'a
       `resolution='pending'`, `expires_at = waiting_room_expiry()` ile bir satır ekle,
       `PendingPurchaseOut` dön (HTTP 202 — "bekleme odasına girdi").
     - **False ise:** `apply_rules()` çağır, sonucu `transactions`'a **INSERT** et
       (UPDATE yok), `TransactionOut` dön (HTTP 201).

2. **`POST /pending-purchases/{purchase_id}/resolve`'u doldur:**
   - Request body: `{ "decision": "purchased" | "abandoned" }`
   - Zaten `resolution != 'pending'` olan bir kayıt tekrar resolve edilmeye çalışılırsa
     **409 Conflict** dön.
   - `"purchased"`: `apply_rules()` ile normal harcama akışını çalıştır, sonucu
     `transactions`'a yaz, `pending_purchases.resolution='purchased'` ve
     `resulting_transaction_id` set et.
   - `"abandoned"`: `resolve_abandoned_purchase(amount)` çağır — dönen tutarın **tamamı**
     `transactions`'a ayrı bir satır olarak yazılır (`self_tax_amount=0`,
     `roundup_amount=0`, `total_diverted=amount`), `resolution='abandoned'` ve
     `resulting_transaction_id` set et.

3. **Süresi dolan bekleme odası kayıtları için arka plan işi ekle:** `expires_at`'i geçmiş,
   hâlâ `resolution='pending'` olan kayıtları otomatik `'abandoned'` yapıp
   `resolve_abandoned_purchase()` akışını uygulayan bir fonksiyon yaz. Gerçek bir zamanlayıcı
   (cron/APScheduler) şart değil bu aşamada — fonksiyon izole ve test edilebilir olsun, FastAPI
   `startup` event'inde tetiklenen basit bir `asyncio` task yeterli.

4. **`GET /transactions/` ve `GET /pending-purchases/`'ı doldur:** kullanıcının kayıtlarını
   `limit`/`offset` query parametreleriyle sayfalayarak dön.

5. **`PUT /users/{user_id}/settings`'i doldur:** eski `user_rule_settings` kaydını **UPDATE
   etme** — yeni bir satır ekle, eski kaydın `valid_to`'sunu şimdiki zamana çek. Bu, Görev
   1.1'de tasarlanan "ayar geçmişi kaybolmasın" ilkesinin uygulanması.

## Kısıtlar

- `rule_engine.py`'nin içeriğine dokunma.
- `transactions` tablosuna hiçbir yerde `UPDATE` atma — sadece `INSERT`.
- Tüm parasal hesaplar `Decimal` (grep ile `float` kalmadığını doğrula).
- Gerçek banka/dış ödeme entegrasyonu yok (Faz 1 ilkesi — `schema.sql` yorumlarına bak).

## Referans Dosyalar

- `backend/app/rule_engine.py`
- `backend/schema.sql`
- `docs/api-contract.md`
- `docs/task-cards/01-api-sozlesmesi-backend-iskeleti.md`

## Kabul Kriterleri

- [ ] Normal harcama `POST /transactions/` ile doğru breakdown'la 201 dönüyor, DB'de satır var
- [ ] Eşik üstü harcama `pending_purchases`'a düşüyor (202), `transactions`'a yazılmıyor
- [ ] `resolve` hem `purchased` hem `abandoned` için doğru çalışıyor, `resulting_transaction_id` set ediliyor
- [ ] Zaten resolve edilmiş bir kayda tekrar resolve denemesi 409 dönüyor
- [ ] Süresi dolan pending kayıtlar otomatik abandoned oluyor (test edilebilir fonksiyon)
- [ ] `GET` endpoint'leri sayfalama ile çalışıyor
- [ ] `PUT /users/{id}/settings` eski kaydı silmiyor/güncellemiyor, `valid_to` ile kapatıyor
- [ ] pytest: normal harcama, eşik üstü → bekleme odası, purchased resolve, abandoned resolve, 409 senaryosu test edilmiş
- [ ] Kod tabanında `float` kullanımı yok

## Beklenen Walkthrough

- Değişen/eklenen dosyaların listesi
- pytest çıktısı (yeşil, yukarıdaki senaryolar dahil)
- Swagger üzerinden iki örnek `POST /transactions/` çağrısı (normal + eşik üstü) ekran görüntüsü
- `resolve` öncesi/sonrası `pending_purchases` ve `transactions` tablolarının psql çıktısı
