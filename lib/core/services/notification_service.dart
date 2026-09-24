import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import '../../data/models/agendamento_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);

    // Solicita permissão no Android 13+
    final androidImpl =
        _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
      await androidImpl.requestExactAlarmsPermission();
    }
  }

  // Agenda o alarme prévio para a hora exata configurada
  static Future<void> agendarLembreteAgendamento(Agendamento a) async {
    if (a.id == null || a.antecedenciaLembreteMinutos <= 0) return;

    final dataAlerta = a.dataHoraInicio.subtract(Duration(minutes: a.antecedenciaLembreteMinutos));
    if (dataAlerta.isBefore(DateTime.now())) return; // Não agenda horários passados

    final tzDataAlerta = tz.TZDateTime.from(dataAlerta, tz.local);
    final horaFormatada = DateFormat('HH:mm').format(a.dataHoraInicio);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'bella_gestao_alarmes',
      'Lembretes da Agenda',
      channelDescription: 'Avisos e alarmes prévios de atendimentos agendados',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      a.id!,
      '⏰ Próximo Atendimento em ${a.antecedenciaLembreteMinutos} min!',
      '${a.cliente} às $horaFormatada (${a.servico})',
      tzDataAlerta,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelarLembrete(int id) async {
    await _notifications.cancel(id);
  }
}
