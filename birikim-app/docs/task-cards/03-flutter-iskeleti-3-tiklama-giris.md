# Görev 1.4 — Flutter İskeleti + 3-Tıklama Harcama Girişi
*(Antigravity'ye doğrudan yapıştırılacak görev metni)*

## Bağlam

Backend'de API sözleşmesi ve kural motoru entegrasyonu tamamlandı (`docs/api-contract.md`,
`POST /transactions/`, `POST /pending-purchases/{id}/resolve`). Şimdi mobile tarafını kuruyoruz.
Projenin vizyonu "günde 2 dakika, en fazla 3 dokunuş" — bu görevde hem bu akışı hem de gerçek
hayatta kaçınılmaz olan "zayıf sinyalde harcama girme" senaryosunu (offline-first) kuruyoruz.

## Görev

1. `mobile/` altında Flutter proje iskeletini kur:
   ```
   mobile/lib/
   ├── screens/
   │   ├── expense_entry/
   │   └── waiting_room/
   ├── widgets/
   ├── services/       # API client + local queue
   └── models/          # docs/api-contract.md'deki şekillerle birebir
   ```
2. **API client:** `docs/api-contract.md`'deki `TransactionCreate`, `TransactionOut`,
   `PendingPurchaseOut` şekillerine birebir uyan tipli Dart modelleri yaz. Kategori/goal ID'leri
   `schema.sql`'de UUID — Dart tarafında da `String` olarak tut, sayısal ID varsayma.
3. **3-tıklamalık harcama giriş akışı:** Ana ekrandan itibaren tam olarak şu adımlar:
   - Dokunuş 1: `+` butonuna dokun (quick-add açılır)
   - Dokunuş 2: kategori grid'inden tek dokunuşla kategori seç
   - Dokunuş 3: tutarı gir, "Kaydet"e bas
   (Tutar girerken rakam tuşlarına basmak ayrı "dokunuş" sayılmaz — sayılan sadece ekran/adım
   geçişleridir.) Tutarı `double` olarak tutup görüntüleme anında yuvarlama yapma; kullanıcının
   girdiği string'i backend'e olduğu gibi gönder, kuruş hassasiyeti backend'de zaten `Decimal`
   ile korunuyor.
4. **Yanıt ayrımı:** `POST /transactions/` `202` (Bekleme Odası) dönerse, kullanıcıya bunun
   normal bir "kaydedildi" onayından **görsel olarak farklı** olduğunu göster (örn. "Bu harcama
   24 saat bekleme odasında, vazgeçersen doğrudan birikime eklenir"). `201` sessizce/hafif bir
   onayla geçebilir.
5. **Offline-first queue:** `sqflite` veya `drift` ile yerel bir tablo kur. API çağrısı
   başarısız olursa (bağlantı yok veya 5xx) harcamayı bu tabloya yaz, kullanıcıya normal
   "kaydedildi" hissini ver (queue'da beklediğini ayrıca belirtmene gerek yok — sürtünmesiz UI
   ilkesi). Bağlantı geri geldiğinde (`connectivity_plus` ile dinle) queue'yu otomatik
   senkronize et; başarılı senkron sonrası yerel kaydı temizle/işaretle.
6. **Ortam bazlı base URL config:** localhost'u hardcode etme. Android emulator'da backend'e
   ulaşmak için `10.0.2.2` gerekiyor (127.0.0.1 emulator'ın kendisini işaret eder) — bunu
   `--dart-define` veya bir config dosyasıyla ortam bazlı yönet, kodun içine gömme.

## Kısıtlar

- Karmaşık grafik/dashboard ekleme — sadece PDF'teki "büyük, tatmin edici görsel" ilkesi (bu
  görevde henüz hedef ilerleme çubuğu yok, o Görev 1.5'te).
- Gerçek banka/kart entegrasyonu yok.
- Backend'deki `rule_engine.py`/router mantığına dokunma — bu görev sadece mobile.

## Referans Dosyalar

- `docs/api-contract.md`
- `docs/architecture.md`
- `backend/schema.sql` (ID tipleri ve alan adları için)

## Kabul Kriterleri

- [ ] Flutter proje `mobile/` altında, önerilen klasör yapısıyla kuruldu
- [ ] API client modelleri `docs/api-contract.md` ile birebir uyuyor
- [ ] Ana ekrandan harcama kaydına kadar 3 ekran-geçişi dokunuşu (tutar rakamları hariç)
- [ ] 202 (bekleme odası) yanıtı 201'den görsel olarak ayrışıyor
- [ ] API'ye ulaşılamadığında harcama yerel queue'ya yazılıyor, kullanıcı deneyimi bozulmuyor
- [ ] Bağlantı geri gelince queue senkronize oluyor, senkron sonrası yerel kayıt temizleniyor
- [ ] Base URL ortam bazlı config'den geliyor, hardcode `localhost`/`127.0.0.1` yok
- [ ] Offline queue için en az bir test var (API mock'lanarak: başarısız çağrı → queue'ya yazma → flush)

## Beklenen Walkthrough

- Oluşturulan dosya/klasör yapısı
- 3-tıklamalık akışın ekran görüntüleri (her adım)
- 202 ve 201 yanıtlarının farklı gösterildiğine dair ekran görüntüsü
- Offline queue testinin çıktısı
