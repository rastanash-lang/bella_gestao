import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import '../../data/models/agendamento_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Inicializa o canal e solicita permissões nativas no Android 13+
  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings: initSettings);

    // Permissões em tempo de execução para Android 13+ (API 33+)
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
      await androidImpl.requestExactAlarmsPermission();
    }
  }

  // Programa o alarme no sistema operacional com antecedência configurada
  static Future<void> agendarLembreteAgendamento(Agendamento a) async {
    if (a.id == null || a.antecedenciaLembreteMinutos <= 0) return;

    final dataAlerta =
        a.dataHoraInicio.subtract(Duration(minutes: a.antecedenciaLembreteMinutos));
    
    // Não programa se a data calculada já tiver passado
    if (dataAlerta.isBefore(DateTime.now())) return;

    final tzDataAlerta = tz.TZDateTime.from(dataAlerta, tz.local);
    final horaFormatada = DateFormat('HH:mm').format(a.dataHoraInicio);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'bella_gestao_alarmes',
      'Lembretes da Agenda',
      channelDescription: 'Avisos prévios de atendimentos agendados',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id: a.id!,
      title: '⏰ Atendimento em ${a.antecedenciaLembreteMinutos} min!',
      body: '${a.cliente} às $horaFormatada (${a.servico})',
      scheduledDate: tzDataAlerta,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Dispara com tela bloqueada/app fechado
    );
  }

  // Cancela a notificação programada no SO Android pelo ID
  static Future<void> cancelarLembrete(int id) async {
    await _notifications.cancel(id: id);
  }
}
