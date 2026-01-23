import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/supabase_service.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifs = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notifs.initialize(initSettings);

    final androidPlugin = _notifs.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> maybeNotifyLimit({
    required int year,
    required double limitAnual,
    required double totalReceitasAno,
    required String settingsId,
    required SupabaseService supabaseService,
  }) async {
    if (limitAnual <= 0) return;
    final ratio = totalReceitasAno / limitAnual;
    int level = 0;
    if (ratio >= 0.95) level = 95;
    else if (ratio >= 0.80) level = 80;
    else return;

    // Timing DB update handled by SupabaseService
    // Show notification
    final pct = (ratio * 100).clamp(0, 999).toStringAsFixed(0);
    final title = level == 95 ? 'Atenção: limite MEI quase estourando' : 'Aviso: perto do limite MEI';
    final body = 'Você já usou $pct% do limite anual. Receitas no ano: R\$ ${totalReceitasAno.toStringAsFixed(2)}';

    const androidDetails = AndroidNotificationDetails('limite_mei_alerts', 'Alertas de Limite MEI', channelDescription: 'Avisos quando próximo do limite anual', importance: Importance.high, priority: Priority.high);
    const details = NotificationDetails(android: androidDetails);
    await _notifs.show(1001, title, body, details);

    // atualizar DB via serviço
    await supabaseService.updateAlertMetadata(settingsId, year, level);
  }
}