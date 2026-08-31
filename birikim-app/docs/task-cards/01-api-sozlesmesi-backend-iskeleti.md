# Görev 1.1 — API Sözleşmesi + Backend İskeleti
*(Antigravity'ye doğrudan yapıştırılacak görev metni)*

## Bağlam

`birikim-app` adlı bir gamified savings/spending uygulamasının backend'ini kuruyoruz.
Veritabanı şeması (`backend/schema.sql`) ve kural motoru (`backend/app/rule_engine.py`) zaten
yazıldı ve test edildi — bu görevde onlara **dokunmuyoruz**, üzerlerine FastAPI iskeletini
ve API sözleşmesini kuruyoruz. Amaç: mobile ekibinin (Görev 1.4) beklemeden ilerleyebilmesi
için endpoint'lerin request/response şekillerini şimdi kilitlemek — iş mantığının tamamı
(vergi hesaplama, ledger yazma) Görev 1.2'de bağlanacak.

## Görev

1. Aşağıdaki klasör yapısını oluştur:
   ```
   backend/
   ├── app/
   │   ├── main.py
   │   ├── db.py
   │   ├── models/          # SQLAlchemy — schema.sql'deki tablolarla birebir
   │   ├── schemas/          # Pydantic request/response modelleri
   │   ├── routers/
   │   │   ├── transactions.py
   │   │   ├── pending_purchases.py
   │   │   ├── goals.py
   │   │   └── users.py
   │   └── rule_engine.py    # zaten var, taşı/kopyala, İÇERİĞİNİ DEĞİŞTİRME
   ├── alembic/
   ├── tests/
   ├── docker-compose.yml    # yerel Postgres için
   └── pyproject.toml
   ```
2. `docker-compose.yml` ile yerel bir Postgres servisi tanımla (dev ortamı ayağa kalksın).
3. `backend/schema.sql`'deki her tablo için birebir karşılık gelen SQLAlchemy modeli yaz
   (`users`, `user_rule_settings`, `categories`, `transactions`, `goals`, `goal_members`,
   `pending_purchases`). Alan adları ve tipleri şemayla aynı olsun (NUMERIC → `Numeric`,
   asla `Float` değil).
4. Alembic'i kur, ilk migration'ı bu modellerden üret, `alembic upgrade head` ile
   yerel Postgres'e uygula.
5. Şu Pydantic şemalarını tanımla (sadece şekil — mantık yok):
   - `TransactionCreate` (raw_amount, category_id) / `TransactionOut` (breakdown dahil tüm alanlar)
   - `GoalCreate` / `GoalOut`
   - `PendingPurchaseOut`
   - `UserRuleSettingsOut` / `UserRuleSettingsUpdate`
6. Router'ları stub olarak bağla — endpoint'ler doğru request/response tipini kabul/dönsün
   ama gövdede `raise HTTPException(status_code=501, detail="not implemented yet")` olsun
   (transactions POST hariç değil, hepsi 501 — Görev 1.2'de dolduracağız).
7. `GET /health` endpoint'i ekle, gerçek bir kontrol yapsın (DB bağlantısı çalışıyor mu).
8. Uygulamayı `uvicorn` ile ayağa kaldır, otomatik üretilen OpenAPI şemasını
   (`/openapi.json`) al ve **insan tarafından okunabilir özetini** `docs/api-contract.md`'ye yaz
   (her endpoint için: metod, yol, request şekli, response şekli — mobile ekibi Swagger'a
   girmeden buradan çalışabilsin).
9. `tests/test_health.py` içinde en az bir smoke test yaz: app import ediliyor mu,
   `/health` 200 dönüyor mu.

## Kısıtlar

- Tüm parasal alanlar `Decimal`/`NUMERIC` — asla `float` kullanma.
- `transactions` tablosuna hiçbir yerde `UPDATE` atma; bu görevde zaten yazma mantığı yok
  ama modelde de bunu ima eden bir yapı kurma (örn. "editable" alan ekleme).
- `rule_engine.py`'nin içeriğini değiştirme — sadece doğru klasöre taşı/kopyala.
- `schema.sql`'deki tablo/alan isimlerinden sapma; sapman gerekiyorsa önce bana sor, tahmin yürütme.

## Referans Dosyalar

- `backend/schema.sql`
- `backend/app/rule_engine.py`
- `docs/architecture.md` (genel proje mimarisi)

## Kabul Kriterleri

- [ ] `docker-compose up` ile Postgres ayağa kalkıyor
- [ ] `alembic upgrade head` hatasız çalışıyor, tablolar `schema.sql` ile birebir örtüşüyor
- [ ] `uvicorn app.main:app` ile sunucu ayağa kalkıyor, `/docs` (Swagger UI) açılıyor
- [ ] `docs/api-contract.md` üretildi ve her endpoint'in request/response şekli net
- [ ] `pytest` yeşil dönüyor
- [ ] Hiçbir router'da gerçek iş mantığı yok (hepsi 501 dönüyor, `/health` hariç)

## Beklenen Walkthrough

- Oluşturulan/değiştirilen dosyaların listesi
- `/docs` (Swagger UI) sayfasının ekran görüntüsü
- `alembic upgrade head` ve `pytest` komutlarının terminal çıktısı
