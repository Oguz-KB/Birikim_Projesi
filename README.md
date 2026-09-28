# Birikim Uygulaması 🚀

![Python](https://img.shields.io/badge/backend-FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![Flutter](https://img.shields.io/badge/mobile-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/database-PostgreSQL-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![Dart](https://img.shields.io/badge/language-Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

Geleneksel "bütçe takibi" uygulamalarının ötesine geçerek **davranışsal psikoloji ve oyunlaştırma** teknikleriyle kullanıcılarına çaba sarf ettirmeden birikim yaptıran yenilikçi bir mobil uygulama projesidir.

## 🎯 Projenin Amacı ve Vizyonu
Bu proje, harcama anında otomatik birikim yapmayı hedefler. Kullanıcı harcama yaptıkça sistem ondan küçük, hissettirmeyen kesintiler yapar ve bunları önceden belirlenmiş hedeflere yönlendirir. Temel vizyon, dürtüsel harcamaları kontrol altına almak ve birikimi hayatın otomatik bir parçası haline getirmektir.

## ⚙️ Temel Özellikler ve Kural Motoru

Sistemin kalbinde her harcamayı değerlendiren zeki bir **Kural Motoru** yatar:
* **Kendine Vergi (Self-Tax):** Yapılan her harcamadan belirlenen oranda (örn. %10) kesinti yapılır ve birikime aktarılır.
* **Yuvarlama (Round-up):** Harcamalar en yakın üst birime (örn. 10 TL'ye) yuvarlanır; aradaki küsurat birikime gider.
* **Zaaf Çarpanı (Guilty Pleasure):** Belirlenen zaaf kategorilerindeki (örn. fast-food, oyun) harcamalar için kesintiler 2x veya 3x çarpanla uygulanır.
* **Bekleme Odası (24 Saat Kuralı):** Büyük ve planlanmamış harcamalar anında onaylanmaz, 24 saat "Bekleme Odası"na alınır. Dürtüsel harcamaların önüne geçilir.
* **Değiştirilemez Kayıt Defteri (Immutable Ledger):** Veritabanında hiçbir bakiye doğrudan güncellenmez. Tüm işlemler, yeni satırlar olarak eklenerek mutlak veri güvenliği sağlanır.

## 🏗️ Teknik Mimari

Proje modern ve ölçeklenebilir bir **Monorepo** yapısı kullanmaktadır.

### Backend (Sunucu Tarafı)
* **Dil & Framework:** Python 3.9+, FastAPI
* **Veritabanı:** PostgreSQL
* **ORM:** SQLAlchemy 2.0 & Alembic (Migration)
* **Validasyon:** Pydantic

### Mobile (Kullanıcı Uygulaması)
* **Dil & Framework:** Dart, Flutter
* **Lokal Veritabanı:** sqflite (Çevrimdışı kullanım desteği)
* **Veri Görselleştirme:** fl_chart

## 📂 Klasör Yapısı
```
📦 Birikim_Projem
 ┣ 📂 birikim-app
 ┃ ┣ 📂 backend       # Python / FastAPI sunucu kodları
 ┃ ┣ 📂 mobile        # Dart / Flutter mobil uygulama kodları
 ┃ ┗ 📂 docs          # Proje dokümantasyonu ve mimari notları
 ┗ 📜 README.md       # Proje tanıtım dosyası (Bu dosya)
```

## 🚀 Proje Durumu
Şu anda proje, MVP (Minimum Viable Product) aşamasını başarıyla tamamlamıştır:
- **Backend:** FastAPI ile kural motoru ve veri yönetimi aktif olarak çalışmaktadır.
- **Mobil Uygulama:** Flutter ile geliştirilen arayüz, harcama girişi ve çevrimdışı çalışma (sqflite) yeteneklerine sahiptir.
- **Gelecek Planları:** İlerleyen süreçte ortak hedefler (Co-op) ve oyunlaştırma (Rozetler) gibi sosyal özelliklerin eklenmesi planlanmaktadır.

---
*Bu proje modern yazılım geliştirme pratikleri, temiz mimari (clean architecture) ve davranışsal psikoloji kurallarını bir araya getiren bir ürün olarak tasarlanmıştır.*
