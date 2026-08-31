# Birikim Uygulaması — Yol Haritası ve Proje Mimarisi
*(Google Antigravity ile geliştirme süreci için hazırlandı)*

## 0. Antigravity'ye Neden Bu Şekilde Yaklaşıyoruz

Antigravity, tek satır tamamlama değil **görev devri** üzerine kurulu: Manager Surface'te
birden fazla agent'ı paralel workspace'lerde çalıştırabiliyorsun, her görev bir
**Walkthrough artifact**'ı (dosya değişiklikleri + ekran görüntüleri + özet) ile dönüyor,
sen onu kabul/düzelt/yeniden başlat diyorsun. Bunun verimli çalışması için üç şey gerekiyor:

1. **Küçük, doğrulanabilir görevler** — bir agent koşusu ~30 dakikalık iş kapsamalı, "kabul kriteri" net olmalı.
2. **Net arayüz sözleşmeleri** — backend ve mobile paralel ilerleyecekse, aralarındaki API şeması en başta sabitlenmeli.
3. **Referans verilebilir bağlam** — agent'a "şu dosyaya bak, şu kurallara uy" diyebilmek için proje içinde
   yazılı görev kartları ve mimari kararlar bulunmalı (agent her seferinde konuşmadan hatırlamaz).

Aşağıdaki yapı buna göre kuruldu.

---

## 1. Monorepo Mimarisi

```
birikim-app/
├── backend/
│   ├── app/
│   │   ├── main.py
│   │   ├── db.py                    # SQLAlchemy engine/session
│   │   ├── models/                  # ORM modelleri (schema.sql'e birebir karşılık gelir)
│   │   ├── schemas/                 # Pydantic request/response modelleri
│   │   ├── routers/
│   │   │   ├── transactions.py
│   │   │   ├── pending_purchases.py # Bekleme Odası
│   │   │   ├── goals.py             # Ortak Hedefler dahil
│   │   │   └── users.py
│   │   ├── rule_engine.py           # ✅ zaten yazıldı
│   │   └── services/                # rule_engine'i DB'ye bağlayan katman
│   ├── alembic/                     # migration'lar (schema.sql buradan üretilecek)
│   ├── tests/
│   └── schema.sql                   # ✅ zaten yazıldı
├── mobile/
│   ├── lib/
│   │   ├── screens/
│   │   │   ├── expense_entry/       # 3-tıklama akışı
│   │   │   ├── goal_progress/
│   │   │   └── waiting_room/
│   │   ├── widgets/
│   │   ├── services/                # API client (backend'deki OpenAPI şemasından üretilebilir)
│   │   └── models/
│   └── test/
└── docs/
    ├── architecture.md              # bu dosya
    ├── api-contract.md              # backend ⇄ mobile arayüz sözleşmesi (Görev 1.1'de üretilecek)
    ├── task-cards/                  # her görev ayrı .md — Antigravity'ye bunu referans göster
    └── adr/                         # mimari kararlar (ör. "neden immutable ledger")
```

**Neden monorepo:** Antigravity 2.0 proje/klasör bazlı çalışıyor; backend ve mobile agent'larının
aynı `docs/api-contract.md`'ye referans verebilmesi, iki ayrı repo arasında context kaybetmekten
daha güvenilir.

---

## 2. Antigravity Çalışma Modeli

- **Manager Surface'te iki workspace aç:** biri `backend/`, biri `mobile/` odaklı. API sözleşmesi
  sabitlendikten sonra (Görev 1.1) ikisi paralel ilerleyebilir.
- **Görev kartı şablonu** (`docs/task-cards/XX-isim.md`) — Antigravity'ye görev verirken bu dosyayı
  referans göster, sohbet geçmişine güvenme:
  ```
  ## Bağlam
  (Neden bu görev, hangi dosyalara bakması lazım)

  ## Kabul Kriterleri
  - [ ] ...
  - [ ] ...

  ## Referans Dosyalar
  - backend/schema.sql
  - backend/app/rule_engine.py

  ## Beklenen Walkthrough
  (UI görevi ise: hangi ekran görüntüsünü görmek istiyorsun; backend ise: hangi testin geçtiğini)
  ```
- **Junior/Senior agent ayrımı:** CRUD iskeleti, migration, boilerplate → Junior Agent arka planda;
  kural motoru mantığı, ledger tutarlılığı, güvenlik → Senior Agent ile birebir.
- **Browser-in-the-loop:** UI görevlerinde ("harcama girişi 3 tıklamada bitiyor mu") agent'tan
  Flutter web/otomatik test ile ekran görüntüsü doğrulaması iste — Walkthrough'ta bunu ara.

---

## 3. Faz 1 (MVP) — Görev Kartları

### Görev 1.1 — API Sözleşmesi + Backend İskeleti
**Kabul kriterleri:** `schema.sql` migration'a dönüşmüş (Alembic), FastAPI ayakta, OpenAPI şeması
`docs/api-contract.md`'ye export edilmiş.
**Referans:** `backend/schema.sql`

### Görev 1.2 — `rule_engine.py`'yi Servise Bağlama
**Kabul kriterleri:** `POST /transactions` çağrısı → `apply_rules()` çalışıyor → sonuç
`transactions` tablosuna immutable satır olarak yazılıyor (UPDATE yok).
**Referans:** `backend/app/rule_engine.py`

### Görev 1.3 — Kullanıcı Ayarları CRUD
**Kabul kriterleri:** `self_tax_rate`, `roundup_unit` vb. `user_rule_settings`'e yazılıyor;
geçmiş ayar geçersiz kılınıyor (`valid_to` set ediliyor), silinmiyor.

### Görev 1.4 — Flutter İskeleti + 3-Tıklama Harcama Girişi
**Kabul kriterleri:** Açılıştan harcama kaydına kadar ≤3 dokunuş; offline'da da (yerel queue)
kayıt alınabiliyor.
**Referans:** `docs/api-contract.md`

### Görev 1.5 — Basit Hedef İlerleme Çubuğu
**Kabul kriterleri:** Grafik yok, tek bir "hedefe ne kadar kaldı" görseli; `goal_progress` view'ından besleniyor.

---

## 4. Faz 2 — Sosyal & Oyunlaştırma

| Görev | Kabul Kriteri |
|---|---|
| Ortak Hedefler (Co-op) | `goal_members` üzerinden iki kullanıcı aynı hedefe katkı veriyor; "takım ilerlemesi" çerçevesi (rekabet değil) |
| Başarım rozetleri | Rozet kuralları backend'de, ayrı `achievements` tablosu |
| Push bildirim altyapısı | Bekleme Odası süresi dolmadan önce hatırlatma |

## 5. Faz 3 — Otomasyon

| Görev | Kabul Kriteri |
|---|---|
| Fiş okuma (kamera) | Flutter tarafında görüntü yakalama, backend'e yükleme |
| AI kategorizasyon | Ayrı bir servis — mevcut `rule_engine.py`'ye dokunmadan kategori önerisi döner |

---

## 6. Paralel Çalıştırma Planı

```
Görev 1.1 (API sözleşmesi)  ──┬──> Görev 1.2, 1.3 (backend, paralel)
                                └──> Görev 1.4, 1.5 (mobile, paralel — sözleşme sabitlenince başlar)
```

Görev 1.1 bitmeden mobile'a başlamak, agent'ların birbirini bozan varsayımlar üretmesine yol açar —
önce sözleşmeyi kilitle.

---

## 7. Sıradaki Adım

Görev 1.1'i Antigravity'de açıp `backend/schema.sql` ve bu dosyayı referans vererek başlayabilirsin.
İstersen Görev 1.1'in tam prompt metnini de birlikte yazalım.
