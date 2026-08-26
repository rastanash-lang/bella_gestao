class Transacao {
  final int? id;
  final String descricao;
  final double valor;
  final String tipo;
  final String ambito;
  final String categoria;
  final String formaPagamento;
  final String status;
  final String? tipoCusto;
  final String? tipoReceita;
  final DateTime data;

  Transacao({
    this.id,
    required this.descricao,
    required this.valor,
    required this.tipo,
    required this.ambito,
    required this.categoria,
    required this.formaPagamento,
    required this.status,
    this.tipoCusto,
    this.tipoReceita,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'valor': valor,
      'tipo': tipo,
      'ambito': ambito,
      'categoria': categoria,
      'formaPagamento': formaPagamento,
      'status': status,
      'tipoCusto': tipoCusto,
      'tipoReceita': tipoReceita,
      'data': data.toIso8601String(),
    };
  }

  factory Transacao.fromMap(Map<String, dynamic> map) {
    return Transacao(
      id: map['id'] as int?,
      descricao: map['descricao'] as String,
      valor: (map['valor'] as num).toDouble(),
      tipo: map['tipo'] as String,
      ambito: map['ambito'] as String,
      categoria: map['categoria'] as String,
      formaPagamento: map['formaPagamento'] as String,
      status: map['status'] as String,
      tipoCusto: map['tipoCusto'] as String?,
      tipoReceita: map['tipoReceita'] as String?,
      data: DateTime.parse(map['data'] as String),
    );
  }
}
