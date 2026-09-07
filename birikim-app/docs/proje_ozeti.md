# Birikim Uygulaması - Proje Rehberi

Bu belge, "Birikim Uygulaması" projesinin amacını, işleyiş mantığını, kullanım senaryolarını ve teknik altyapısını A'dan Z'ye özetlemektedir. Başka bir yapay zeka veya geliştirici ile projeyi tartışırken bu dosyayı temel bağlam (context) olarak kullanabilirsiniz.

---

## 1. Projenin Amacı ve Vizyonu
Geleneksel "bütçe takibi" uygulamaları kullanıcılara sadece ne kadar harcadıklarını gösterir. Bu proje ise **davranışsal psikoloji ve oyunlaştırma** tekniklerini kullanarak harcama anında otomatik birikim yapmayı hedefler. Kullanıcı harcama yaptıkça sistem ondan küçük, hissettirmeyen kesintiler yapar ve bunları birikim hedeflerine yönlendirir. Amacı, dürtüsel harcamaları azaltmak ve birikimi çaba gerektirmeyen otomatik bir sürece dönüştürmektir.

---

## 2. Temel Proje Mantığı ve İş Kuralları

Sistemin kalbinde, her harcamayı değerlendiren bir "Kural Motoru" yatar. 

- **Kendine Vergi (Self-Tax):** Kullanıcının yaptığı her harcamadan belirlenen bir oranda (örn. %10) ek kesinti yapılarak birikime aktarılır.
- **Yuvarlama (Round-up):** Harcama tutarı üst bir birime (örn. en yakın 10 TL'ye) yuvarlanır. Aradaki küsurat farkı birikim hesabına gider.
- **Zaaf Çarpanı (Guilty Pleasure Multiplier):** Kullanıcının dayanamadığı (zaafı olduğu) kategoriler (örn. fast-food, oyun) belirlenir. Bu kategorilerde harcama yapıldığında kesilen vergi/ceza tutarı 2x veya 3x gibi bir çarpanla katlanarak birikime gider.
- **Bekleme Odası (24 Saat Kuralı):** Belirlenen tutarın (eşik değerin) üzerindeki büyük harcama planları anında onaylanmaz, "Bekleme Odası"na alınır. Kullanıcı 24 saat boyunca bu harcamayı bekletmek zorundadır. Süre sonunda kullanıcı harcamadan vazgeçerse, harcanmayan o büyük tutar doğrudan "Kurtarılmış Birikim" olarak hedefe eklenir.
- **Ortak Hedefler (Co-op):** Kullanıcılar arkadaşları veya aileleriyle ortak birikim havuzları ("Hedefler") oluşturabilir. Herkesin harcamalarından kesilen otomatik vergiler bu ortak hedefe akar.
- **Değiştirilemez Kayıt Defteri (Immutable Ledger):** Veritabanı (backend) mimarisinde hiçbir zaman bakiye doğrudan güncellenmez. Tüm işlemler, kesintiler ve iptaller değiştirilemez yeni satırlar (işlemler/transactions) olarak eklenir. İptaller ise silme işlemiyle değil, ters kayıt (reversal) girilerek çözülür.

---

## 3. Kullanım Senaryoları (Use Cases)

**Senaryo 1: Standart Harcama ve Yuvarlama**
- **Olay:** Kullanıcı marketten 83 TL'lik alışveriş yapar.
- **Sistem İşlemi:** Yuvarlama kuralı (en yakın 10'a) devreye girer ve 7 TL kesilir. Kendine vergi (%10) kuralıyla da 8.3 TL kesilir. Toplam harcama 98.3 TL olarak hesaba yansır; 15.3 TL'si doğrudan seçili hedefe gönderilir.

**Senaryo 2: Dürtüsel Alışverişten Korunma**
- **Olay:** Kullanıcı gece yarısı 3.000 TL'ye bir akıllı saat almak için uygulamaya girer.
- **Sistem İşlemi:** Harcama limiti (örn. 1.000 TL) aşıldığı için işlem bloke edilir ve "Bekleme Odası"na atılır. Sistem kullanıcıya: *"Bunu almak istediğinden emin misin? 24 saat bekle."* der. Ertesi gün kullanıcı vazgeç butonuna basarsa, 3.000 TL "Harcamadığım için kazandığım para" olarak hedefe yansıtılır.

**Senaryo 3: Zaaf Cezası**
- **Olay:** Kullanıcı önceden 'zaafım' dediği fast-food kategorisinde 200 TL harcar.
- **Sistem İşlemi:** Normalde %10 olan kesinti, 3x zaaf çarpanı yediği için %30'a (60 TL) çıkar.

---

## 4. Teknik Altyapı ve Mimari (A'dan Z'ye)

Proje modern, ölçeklenebilir ve **Monorepo** (tek depo) mimarisinde yapılandırılmıştır. İçerisinde `backend` ve `mobile` klasörlerini barındırır.

### Backend (Sunucu Tarafı)
- **Programlama Dili:** Python (3.9+)
- **Web Framework:** FastAPI (Yüksek performans, asenkron destek, otomatik Swagger/OpenAPI dokümantasyonu)
- **Veritabanı:** PostgreSQL (Güvenilir ilişkisel veritabanı)
- **ORM & Göç Yönetimi:** SQLAlchemy 2.0 (Veritabanı modelleri) ve Alembic (Migration işlemleri için)
- **Veri Validasyonu:** Pydantic
- **Sunucu:** Uvicorn / Gunicorn
- **Mimari Odak:** Backend sadece CRUD (Oluştur, Oku, Güncelle, Sil) yapmaz, karmaşık "Kural Motoru" (`rule_engine.py`) üzerinden işlemlerin doğruluğunu (immutable ledger tablosuna yazılmasını) sağlar.

### Mobile (Kullanıcı Uygulaması)
- **Programlama Dili:** Dart
- **Mobil Framework:** Flutter (iOS ve Android için tek kod tabanından doğal çıktı)
- **Lokal Veritabanı:** sqflite (Çevrimdışı/offline destek. Kullanıcı interneti yokken de harcama girebilir, veri sonradan backend ile senkronize olur)
- **Görselleştirme:** fl_chart (Birikim ilerleme grafikleri, hedeflerin pasta/çubuk grafikleri)
- **Diğer Bileşenler:** Bildirimler için `flutter_local_notifications` (Bekleme odası süre bitim uyarıları) ve HTTP istekleri için `http` paketi.

---

## 5. İlerleyiş ve Geliştirme Yol Haritası

Projeyi başka bir yapay zekaya devredecekseniz veya onunla çalışacaksanız şu sıralamayı takip etmesini isteyebilirsiniz:

1. **Faz 1 (Temel Çatı ve API):** Backend'deki `schema.sql`'in Alembic migration'larına dökülmesi, FastAPI router'larının ve "Kural Motoru"nun aktif edilmesi. (Bu süreçte Backend ve Mobil için bir API Sözleşmesi - Contract kilitlenmelidir).
2. **Faz 2 (Mobil MVP):** Flutter uygulamasının "3 tıklamada harcama girme" ve çevrimdışı çalışma özelliklerinin oturtulması.
3. **Faz 3 (Sosyal & Gelişmiş Özellikler):** Ortak hedeflerin (Co-op) entegre edilmesi, kullanıcıların başarı rozetleri (Achievements) kazanması.
4. **Faz 4 (Otomasyon):** İlerleyen aşamalarda kameradan fiş okutarak otomatik kategori ve fiyat tespiti yapan Yapay Zeka servisinin bağlanması.

Bu belgeyi okuyan bir Yapay Zeka; uygulamanın amacını, arka plandaki psikolojik kural motorunu, veritabanının değiştirilemez (immutable) yapısını ve kullanılacak dillerle kütüphaneleri eksiksiz anlayacaktır.
