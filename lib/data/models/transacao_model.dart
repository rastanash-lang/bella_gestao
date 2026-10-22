class Transacao {
  final int? id;
  final String descricao;
  final String? cliente;
  final double valor;
  final String tipo;
  final String ambito;
  final String categoria;
  final String formaPagamento;
  final String status;
  final String? tipoCusto;
  final String? tipoReceita;
  final int parcelaAtual;
  final int totalParcelas;
  final int? agendamentoId; // Vínculo com o agendamento de origem
  final DateTime data;

  Transacao({
    this.id,
    required this.descricao,
    this.cliente,
    required this.valor,
    required this.tipo,
    required this.ambito,
    required this.categoria,
    required this.formaPagamento,
    required this.status,
    this.tipoCusto,
    this.tipoReceita,
    this.parcelaAtual = 1,
    this.totalParcelas = 1,
    this.agendamentoId,
    required this.data,
  });

  Transacao copyWith({
    int? id,
    String? descricao,
    String? cliente,
    double? valor,
    String? tipo,
    String? ambito,
    String? categoria,
    String? formaPagamento,
    String? status,
    String? tipoCusto,
    String? tipoReceita,
    int? parcelaAtual,
    int? totalParcelas,
    int? agendamentoId,
    DateTime? data,
  }) {
    return Transacao(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      cliente: cliente ?? this.cliente,
      valor: valor ?? this.valor,
      tipo: tipo ?? this.tipo,
      ambito: ambito ?? this.ambito,
      categoria: categoria ?? this.categoria,
      formaPagamento: formaPagamento ?? this.formaPagamento,
      status: status ?? this.status,
      tipoCusto: tipoCusto ?? this.tipoCusto,
      tipoReceita: tipoReceita ?? this.tipoReceita,
      parcelaAtual: parcelaAtual ?? this.parcelaAtual,
      totalParcelas: totalParcelas ?? this.totalParcelas,
      agendamentoId: agendamentoId ?? this.agendamentoId,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'cliente': cliente,
      'valor': valor,
      'tipo': tipo,
      'ambito': ambito,
      'categoria': categoria,
      'formaPagamento': formaPagamento,
      'status': status,
      'tipoCusto': tipoCusto,
      'tipoReceita': tipoReceita,
      'parcelaAtual': parcelaAtual,
      'totalParcelas': totalParcelas,
      'agendamento_id': agendamentoId,
      'data': data.toIso8601String(),
    };
  }

  factory Transacao.fromMap(Map<String, dynamic> map) {
    return Transacao(
      id: map['id'] as int?,
      descricao: map['descricao'] as String,
      cliente: map['cliente'] as String?,
      valor: (map['valor'] as num).toDouble(),
      tipo: map['tipo'] as String,
      ambito: map['ambito'] as String,
      categoria: map['categoria'] as String,
      formaPagamento: map['formaPagamento'] as String,
      status: map['status'] as String,
      tipoCusto: map['tipoCusto'] as String?,
      tipoReceita: map['tipoReceita'] as String?,
      parcelaAtual: map['parcelaAtual'] as int? ?? 1,
      totalParcelas: map['totalParcelas'] as int? ?? 1,
      agendamentoId: map['agendamento_id'] as int?,
      data: DateTime.parse(map['data'] as String),
    );
  }
}
