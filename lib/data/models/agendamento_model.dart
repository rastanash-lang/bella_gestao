class Agendamento {
  final int? id;
  final String cliente;
  final String servico;
  final double valor;
  final DateTime dataHoraInicio;
  final int duracaoMinutos; // Ex: 30, 45, 60, 90, 120
  final String status; // 'Agendado', 'Concluido', 'Cancelado'
  final String? observacoes;

  Agendamento({
    this.id,
    required this.cliente,
    required this.servico,
    required this.valor,
    required this.dataHoraInicio,
    required this.duracaoMinutos,
    this.status = 'Agendado',
    this.observacoes,
  });

  DateTime get dataHoraFim => dataHoraInicio.add(Duration(minutes: duracaoMinutos));

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente': cliente,
      'servico': servico,
      'valor': valor,
      'dataHoraInicio': dataHoraInicio.toIso8601String(),
      'duracaoMinutos': duracaoMinutos,
      'status': status,
      'observacoes': observacoes,
    };
  }

  factory Agendamento.fromMap(Map<String, dynamic> map) {
    return Agendamento(
      id: map['id'] as int?,
      cliente: map['cliente'] as String,
      servico: map['servico'] as String,
      valor: (map['valor'] as num).toDouble(),
      dataHoraInicio: DateTime.parse(map['dataHoraInicio'] as String),
      duracaoMinutos: map['duracaoMinutos'] as int,
      status: map['status'] as String? ?? 'Agendado',
      observacoes: map['observacoes'] as String?,
    );
  }
}
