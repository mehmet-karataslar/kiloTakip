# Kilo Takip

Türkçe, tamamen çevrimdışı çalışan kişisel kilo takip mobil uygulaması. Sabah ve akşam ölçümleri cihazdaki SQLite veritabanında ayrı kayıtlar olarak saklanır; internet bağlantısı, sunucu veya üyelik gerektirmez.

## Android kurulumu

Android 7.0 (API 24) veya üstü gerekir. Hazır APK, derlemeden sonra `build/app/outputs/flutter-apk/app-release.apk` konumundadır. APK’yı telefona kopyalayıp açabilir veya USB hata ayıklaması açık bir cihaza aşağıdaki komutla yükleyebilirsin.

```sh
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Yerel kurulum APK’sı Flutter şablonunun geliştirme anahtarıyla imzalanır. Mağaza yayını için ayrı bir yayın imzası gerekir.

## Kaynak koddan çalıştırma

Flutter 3.47.4, Dart 3.13.3, JDK 21 ve Android SDK 36 ile geliştirilmiştir. Bir Android telefon bağla veya bir Android emülatörü başlat. `flutter devices` çıktısındaki Android cihaz kimliğini kullan.

```sh
flutter pub get
flutter devices
flutter run -d CIHAZ_KIMLIGI
flutter build apk --release
```

Tarayıcı ve masaüstü açılışında mobil kullanım bilgisi gösterilir. Ölçüm saklama ve yerel hatırlatmalar Android ile iOS içindir. iOS projesini derlemek için macOS ve Xcode gerekir.

## Ekranlar ve Kullanım

1. **Ana Sayfa**: Günün sabah ve akşam kilo kartlarını, günlük farkı (`Akşam Kilosu - Sabah Kilosu`), son 7 gün değişimini, haftalık ortalamayı, toplam kayıt sayısını, son 7 günlük mini grafiği ve **+ Kilo Ekle** butonunu içerir.
2. **Grafikler**: `7 Gün`, `14 Gün`, `Aylık` ve `Tüm Zamanlar` filtreleriyle `Sabah`, `Akşam` ve `Karşılaştır` modlarında etkileşimli çizgi grafik (**Kilo Değişim Grafiği**), gruplandırılmış sütun grafik (**Sabah – Akşam Karşılaştırması**) ve alt istatistik kartlarını (`En Düşük`, `En Yüksek`, `Ortalama`, `Toplam Değişim`) sunar.
3. **Geçmiş**: Toplam ve aylık kayıt özetlerini, Türkçe takvim görünümünü (`Pzt`–`Paz`), `Tümü / Sadece Sabah / Sadece Akşam` filtrelerini, tarih/not aramasını ve geçmiş kayıt satırlarında düzenleme/onaylı silme işlemlerini sağlar.
4. **Raporlar**: `Günlük`, `Haftalık`, `Aylık` ve `Genel` dönemlerinde değişim istatistiklerini, isteğe bağlı hedef kilo ilerlemesini (**Genel İstatistikler**) ve veriye dayalı kural tabanlı **Özet** mesajlarını gösterir.
5. **Ayarlar**: Sağ üstteki ayarlar ikonundan açılır. Sabah (`09:00`) ve akşam (`22:30`) yerel bildirimlerini, `Açık / Koyu / Sistem` tema seçimini, isteğe bağlı başlangıç/hedef kilo ayarlarını, **Excel Dışa Aktar (.xlsx)** işlemini ve uygulama sürüm/çevrimdışı çalışma bilgilerini içerir.
6. **Kilo Kaydetme Paneli**: Alt panel (`ModalBottomSheet`) olarak açılır; **Tarih**, **Saat** (`HH:mm`, 24 saat formatı), **Kayıt Türü** (`Sabah` / `Akşam`), **Kilo (kg)** (`136,6` veya `136.6`) ve opsiyonel **Not** alanlarını barındırır. Aynı tarih ve kayıt türünde mevcut kayıt varsa üzerine yazma onayı sunar.

## Doğrulama

```sh
flutter analyze
flutter test
flutter test integration_test/android_test.dart -d CIHAZ_KIMLIGI
```
