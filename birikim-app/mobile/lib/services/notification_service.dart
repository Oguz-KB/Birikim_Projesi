import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final String currentTimeZone = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
    } catch (e) {
      // Varsayılan olarak UTC'de kalır, hatayı yoksayabiliriz
    }

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();

    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosImplementation?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleDailySummary() async {
    // Akşam 20:30 için
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 30);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: 0,
      title: 'Günün Özeti 📊',
      body: 'Bugün ne kadar harcama yaptın? Harcamalarını girmeyi unutma!',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_summary',
          'Günlük Özet',
          channelDescription: 'Günlük harcama hatırlatmaları',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Her gün tekrarlar
    );
  }

  Future<void> scheduleWeeklyProjection(String projectionText) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    // Sonraki Pazar saat 10:00'a kur
    int daysUntilSunday = DateTime.sunday - now.weekday;
    if (daysUntilSunday <= 0) {
      daysUntilSunday += 7;
    }
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 10, 0).add(Duration(days: daysUntilSunday));

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: 2,
      title: 'Haftalık Analiz 📈',
      body: projectionText,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'projection',
          'Projeksiyon',
          channelDescription: 'Haftalık hedefe ulaşma analizi',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // Her hafta Pazar 10:00
    );
  }

  Future<void> scheduleWaitingRoomExpiry(int pendingId, String itemName, DateTime expiryDate) async {
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(expiryDate, tz.local);
    
    // Geçmişteki bir tarihe alarm kurulamaz
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: pendingId,
      title: 'Karar Vakti! ⏳',
      body: 'Bekleme odasındaki "$itemName" ürünü için bekleme süren doldu. Kararın nedir?',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'waiting_room',
          'Bekleme Odası',
          channelDescription: 'Bekleme süresi dolan ürün bildirimleri',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> showMilestoneNotification(int progressPercentage) async {
    String message = 'Harika gidiyorsun!';
    if (progressPercentage == 100) {
      message = 'İnanılmaz! Hedefine ulaştın! Satın alabilirsin 🎉';
    } else if (progressPercentage == 75) {
      message = 'Hedefinin %75\'ine ulaştın! Çok az kaldı, dayan! 💪';
    } else if (progressPercentage == 50) {
      message = 'Hedefini yarıladın! Böyle devam et! 🔥';
    } else if (progressPercentage == 25) {
      message = 'Hedefinin ilk %25\'ini tamamladın, güzel başlangıç! 🚀';
    } else {
      return; // Diğer yüzdelerde atmayacağız
    }

    await _flutterLocalNotificationsPlugin.show(
      id: 1,
      title: 'Kilometre Taşı! 🎯',
      body: message,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'milestone',
          'Kilometre Taşı',
          channelDescription: 'Hedefe ulaşma yüzdesi tebrikleri',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
